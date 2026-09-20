#!/data/data/com.termux/files/usr/bin/bash
#
# Set up code-server (VS Code in the browser) on an Android phone, inside Termux.
#
#   bash setup-code-server-android.sh
#
# Safe to re-run: every step is skipped if it is already done, and an existing
# password is never rotated.
#
# See docs/vscode-on-android.md for the full walkthrough.

set -euo pipefail

DISTRO="ubuntu"
PORT="${CODE_SERVER_PORT:-8080}"

log()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m    %s\033[0m\n' "$*"; }
die()  { printf '\n\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

# --- sanity checks ----------------------------------------------------------

[ -d /data/data/com.termux ] ||
  die "Not running inside Termux. Install Termux from F-Droid or GitHub (NOT the
       Play Store build, which is abandoned) and run this script there."

[ -n "${PREFIX:-}" ] || die "\$PREFIX is unset — this does not look like a Termux shell."

case "$(uname -m)" in
  aarch64|arm64) ;;
  *) warn "Architecture $(uname -m) has no prebuilt code-server binary."
     warn "Installation will compile from source and may take a long time." ;;
esac

ROOTFS="$PREFIX/var/lib/proot-distro/installed-rootfs/$DISTRO"

# --- Termux side ------------------------------------------------------------

log "Updating Termux packages"
pkg update -y
pkg upgrade -y

log "Installing proot-distro"
pkg install -y proot-distro

if [ -d "$ROOTFS" ]; then
  log "$DISTRO rootfs already present — skipping install"
else
  log "Installing $DISTRO rootfs (this is the slow part)"
  proot-distro install "$DISTRO"
fi

# Generate a password only if there is no config yet, so re-running this script
# does not lock the user out of a setup they already have.
CONFIG="$ROOTFS/root/.config/code-server/config.yaml"
if [ -f "$CONFIG" ]; then
  log "Existing code-server config found — keeping current password"
  PASSWORD=""
else
  PASSWORD="$(head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n')"
fi

# --- inside the distro ------------------------------------------------------

log "Installing code-server inside $DISTRO"

cat > "$ROOTFS/root/.code-server-setup.sh" <<'INNER'
#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y --no-install-recommends \
  ca-certificates curl git nano openssl sudo

if command -v code-server >/dev/null 2>&1; then
  echo "code-server already installed: $(code-server --version | head -n1)"
else
  curl -fsSL https://code-server.dev/install.sh | sh
fi

mkdir -p /root/.config/code-server

if [ -n "${CS_PASSWORD:-}" ]; then
  cat > /root/.config/code-server/config.yaml <<EOF
bind-addr: 127.0.0.1:${CS_PORT}
auth: password
password: ${CS_PASSWORD}
cert: false
EOF
  chmod 600 /root/.config/code-server/config.yaml
fi
INNER

chmod +x "$ROOTFS/root/.code-server-setup.sh"

proot-distro login "$DISTRO" -- env \
  CS_PASSWORD="$PASSWORD" \
  CS_PORT="$PORT" \
  bash /root/.code-server-setup.sh

# --- launcher ---------------------------------------------------------------

log "Creating the 'code-server-start' command"

cat > "$PREFIX/bin/code-server-start" <<'LAUNCHER'
#!/data/data/com.termux/files/usr/bin/bash
# Start code-server and keep the phone from suspending it.
set -euo pipefail

PORT="$(sed -n 's/^bind-addr: .*:\([0-9]*\)$/\1/p' \
  "$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu/root/.config/code-server/config.yaml" \
  2>/dev/null || true)"
PORT="${PORT:-8080}"

cleanup() { termux-wake-unlock >/dev/null 2>&1 || true; }
trap cleanup EXIT

termux-wake-lock >/dev/null 2>&1 || true

printf '\n\033[1;32mcode-server is starting.\033[0m\n'
printf 'Open \033[1;36mhttp://localhost:%s\033[0m in your browser.\n' "$PORT"
printf 'Press Ctrl+C here to stop it.\n\n'

proot-distro login ubuntu -- code-server
LAUNCHER

chmod +x "$PREFIX/bin/code-server-start"

# --- done -------------------------------------------------------------------

log "Done"

cat <<EOF

  Start it with:      code-server-start
  Then open:          http://localhost:$PORT

EOF

if [ -n "$PASSWORD" ]; then
  printf '  Your password:      \033[1;32m%s\033[0m\n\n' "$PASSWORD"
  echo "  Write it down. To see it again later:"
else
  echo "  To see your existing password:"
fi

cat <<EOF
      proot-distro login $DISTRO -- cat /root/.config/code-server/config.yaml

  If Android keeps killing the server, set Termux to "Unrestricted" under
  Settings -> Apps -> Termux -> Battery.

EOF
