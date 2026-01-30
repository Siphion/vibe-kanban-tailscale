# vibe-kanban-tailscale

Setup to securely expose [Vibe Kanban](https://github.com/vibe-kanban/vibe-kanban) on your Tailscale network, with an authentication layer managed by Caddy.

## Architecture

```
Client (Tailscale) ──HTTPS:443──► Tailscale Serve ──► Caddy (:8443) ──► Vibe Kanban (:38100)
                                   TLS termination    Auth portal       Local app
```

- **Vibe Kanban** runs on `127.0.0.1:38100`, not directly exposed.
- **Caddy** (custom build with [caddy-security](https://github.com/greenpau/caddy-security)) adds an authentication portal with login/password and JWT sessions.
- **Tailscale Serve** terminates TLS and makes everything reachable only to devices on your tailnet, at `https://<hostname>.ts.net`.

The result: Vibe Kanban accessible only from your Tailscale LAN and protected by authentication.

## Prerequisites

- [Tailscale](https://tailscale.com/) installed and connected
- [Node.js](https://nodejs.org/) (recommended via nvm)
- Custom Caddy build with the `caddy-security` module:
  ```bash
  xcaddy build --with github.com/greenpau/caddy-security --output ./caddy
  ```

## Setup

1. Copy the config file and customize it:
   ```bash
   cp .env.example .env
   ```
   Set in `.env`:
   - `TS_HOSTNAME` — your Tailscale machine hostname (e.g. `my-machine.tail1234.ts.net`)
   - `JWT_SHARED_KEY` — key for signing JWT tokens (generate with `openssl rand -hex 32`)
   - `AUTHP_ADMIN_USER` / `AUTHP_ADMIN_EMAIL` / `AUTHP_ADMIN_SECRET` — initial admin credentials

3. Start:
   ```bash
   ./start.sh
   ```

4. Stop:
   ```bash
   ./stop.sh
   ```

## Modded version

The `start-modded.sh` script works like `start.sh` but launches a local, modified copy of Vibe Kanban (from `/Users/siphion/dev/vb-kanban-modded`) instead of the official version installed via npx. The `stop.sh` script is the same for both versions.

## Files

| File | Description |
|------|-------------|
| `start.sh` | Starts Vibe Kanban (official) + Caddy + Tailscale Serve |
| `start-modded.sh` | Starts Vibe Kanban (modded) + Caddy + Tailscale Serve |
| `stop.sh` | Stops all services |
| `Caddyfile` | Caddy config: reverse proxy + authentication |
| `.env` | Environment variables (not tracked) |
| `caddy` | Custom Caddy binary (not tracked) |
