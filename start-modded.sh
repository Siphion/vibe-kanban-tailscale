#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
TAILSCALE_CLI="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
CADDY_BIN="$BASE_DIR/caddy"
LOGS_DIR="$BASE_DIR/logs"

VK_MODDED_DIR="/Users/siphion/dev/vb-kanban-modded"

# Load nvm (needed for non-interactive shells, e.g. via SSH)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Load environment variables
if [ -f "$BASE_DIR/.env" ]; then
    set -a
    source "$BASE_DIR/.env"
    set +a
else
    echo "[!] ERROR: .env file not found. Copy .env.example and configure it."
    exit 1
fi

TS_HOSTNAME="${TS_HOSTNAME:?ERROR: TS_HOSTNAME not set in .env}"

# Verify custom Caddy binary exists
if [ ! -x "$CADDY_BIN" ]; then
    echo "[!] ERROR: Custom Caddy binary not found at $CADDY_BIN"
    echo "    Build it with: xcaddy build --with github.com/greenpau/caddy-security --output $CADDY_BIN"
    exit 1
fi

# Verify modded vibe-kanban exists
if [ ! -f "$VK_MODDED_DIR/npx-cli/bin/cli.js" ]; then
    echo "[!] ERROR: Modded vibe-kanban not found at $VK_MODDED_DIR"
    exit 1
fi

mkdir -p "$LOGS_DIR"

# --- Vibe Kanban (modded) ---
if pgrep -f "vibe-kanban" > /dev/null 2>&1; then
    echo "[OK] Vibe Kanban already running (PID $(pgrep -f 'vibe-kanban' | head -1))"
else
    echo "[*] Starting Vibe Kanban (modded) on 127.0.0.1:38100..."
    HOST=127.0.0.1 \
    PORT=38100 \
    VK_ALLOWED_ORIGINS="https://$TS_HOSTNAME" \
        nohup node "$VK_MODDED_DIR/npx-cli/bin/cli.js" > "$LOGS_DIR/vibe-kanban.log" 2>&1 &
    VK_PID=$!
    sleep 2
    if kill -0 "$VK_PID" 2>/dev/null; then
        echo "[OK] Vibe Kanban (modded) started (PID $VK_PID)"
    else
        echo "[!] ERROR: Vibe Kanban (modded) failed to start. Check $LOGS_DIR/vibe-kanban.log"
        exit 1
    fi
fi

# --- Caddy (custom build with caddy-security) ---
if pgrep -f "$CADDY_BIN" > /dev/null 2>&1; then
    echo "[*] Caddy already running, reloading config..."
    "$CADDY_BIN" reload --config "$BASE_DIR/Caddyfile" --force 2>/dev/null
    echo "[OK] Caddy config reloaded"
else
    echo "[*] Starting Caddy on 127.0.0.1:8443..."
    "$CADDY_BIN" start --config "$BASE_DIR/Caddyfile"
    echo "[OK] Caddy started"
fi

# --- Tailscale Serve (TLS termination, HTTPS → Caddy) ---
echo "[*] Configuring Tailscale Serve..."
"$TAILSCALE_CLI" serve --bg --https=443 http://127.0.0.1:8443 2>/dev/null \
    || "$TAILSCALE_CLI" serve --https=443 http://127.0.0.1:8443
echo "[OK] Tailscale Serve configured (HTTPS:443 → 127.0.0.1:8443)"

echo ""
echo "=== Running (MODDED) ==="
echo "Vibe Kanban (mod) : http://127.0.0.1:38100 (local only)"
echo "Caddy (auth)      : http://127.0.0.1:8443  (local only)"
echo "Tailscale (TLS)   : https://$TS_HOSTNAME"
echo "Logs              : $LOGS_DIR/"
