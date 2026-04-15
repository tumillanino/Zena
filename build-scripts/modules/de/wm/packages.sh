set -ouex pipefail

shopt -s nullglob

packages=(
  adw-gtk3-theme
  alacritty
  cava
  danksearch
  dgop
  dms
  dms-greeter
  glycin-thumbnailer
  ghostty
  kanshi
  khal
  kf6-kimageformats
  nautilus
  papirus-icon-theme
  quickshell
  xdg-desktop-portal-gtk
  xdg-desktop-portal-gnome
  wl-clipboard
)
dnf5 -y install "${packages[@]}" --exclude=matugen --exclude=noctalia-qs
dnf5 -y install nautilus-python matugen --releasever=44 --disablerepo='*copr*'

packages=(
  gnome-keyring
  gnome-keyring-pam
  mangowc
  pinentry-gnome3
  zenity
)

dnf5 -y install "${packages[@]}" --setopt=install_weak_deps=False

XDG_EXT_TMPDIR="$(mktemp -d)"
XDG_EXT_PY="${XDG_EXT_TMPDIR}/xdg-terminal-exec-nautilus.py"

for ref in main master; do
  if curl -fsSL \
    "https://raw.githubusercontent.com/tulilirockz/xdg-terminal-exec-nautilus/${ref}/xdg-terminal-exec-nautilus.py" \
    -o "${XDG_EXT_PY}"; then
    break
  fi
done

if [[ ! -s "${XDG_EXT_PY}" ]]; then
  echo "Failed to fetch xdg-terminal-exec-nautilus.py from GitHub" >&2
  exit 1
fi

install -Dpm0644 -t "/usr/share/nautilus-python/extensions/" "${XDG_EXT_PY}"
rm -rf "${XDG_EXT_TMPDIR}"

dconf update
systemctl set-default graphical.target
mv /usr/share/wayland-sessions/niri.desktop.disabled /usr/share/wayland-sessions/niri.desktop
sed -i 's|^Exec=.*|Exec=bash -c "niri-session > /dev/null 2>\&1"|' \
  /usr/share/wayland-sessions/niri.desktop

sed -i 's|^Exec=.*|Exec=bash -c "mango -s mango-session > /dev/null 2>\&1"|' \
  /usr/share/wayland-sessions/mango.desktop
