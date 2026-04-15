set -ouex pipefail

shopt -s nullglob

KVER=$(ls /usr/lib/modules | head -n1)
KIMAGE="/usr/lib/modules/$KVER/vmlinuz"
SIGN_DIR="/secureboot"
KEY_FILE="$SIGN_DIR/MOK.key"
CERT_FILE="$SIGN_DIR/MOK.pem"

if [[ ! -f "$KEY_FILE" ]]; then
  echo "Secure Boot signing key not found at $KEY_FILE; skipping kernel and module signing."
  exit 0
fi

if [[ ! -f "$CERT_FILE" ]]; then
  echo "Secure Boot certificate not found at $CERT_FILE; skipping kernel and module signing."
  exit 0
fi

dnf5 -y install sbsigntools

sbsign \
  --key "$KEY_FILE" \
  --cert "$CERT_FILE" \
  --output "${KIMAGE}.signed" \
  "$KIMAGE"
mv "${KIMAGE}.signed" "$KIMAGE"

find "/lib/modules/$KVER" -type f -name '*.ko.xz' -print0 | while IFS= read -r -d '' comp; do
  uncompressed="${comp%.xz}"

  if xz -d --keep "$comp"; then
    echo "Decompressed $comp → $uncompressed"
  else
    echo "Warning: failed to decompress $comp, skipping"
    continue
  fi

  /usr/src/kernels/"$KVER"/scripts/sign-file \
    sha512 "$KEY_FILE" "$CERT_FILE" "$uncompressed" || true
  rm -f "$comp"

  if xz -z "$uncompressed"; then
    echo "Recompressed and signed $uncompressed - ${uncompressed}.xz"
  else
    echo "Warning: failed to recompress $uncompressed"
  fi
done

rm -f "$KEY_FILE"
