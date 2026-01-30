#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
TAILSCALE_CLI="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
CADDY_BIN="$BASE_DIR/caddy"

# --- Tailscale Serve ---
if "$TAILSCALE_CLI" serve status 2>/dev/null | grep -q "443"; then
    "$TAILSCALE_CLI" serve reset
    echo "[OK] Tailscale Serve reset"
else
    echo "[--] Tailscale Serve not configured"
fi

# --- Caddy ---
if pgrep -f "$CADDY_BIN" > /dev/null 2>&1; then
    "$CADDY_BIN" stop 2>/dev/null || pkill -f "$CADDY_BIN"
    echo "[OK] Caddy stopped"
else
    echo "[--] Caddy not running"
fi

# --- Vibe Kanban ---
if pgrep -f "vibe-kanban" > /dev/null 2>&1; then
    pkill -f "vibe-kanban"
    echo "[OK] Vibe Kanban stopped"
else
    echo "[--] Vibe Kanban not running"
fi
