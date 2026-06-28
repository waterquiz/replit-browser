# Browser Desktop

A browser-in-a-browser: a full Chromium session running in a virtual display, streamed live to any browser tab via noVNC over WebSocket.

## Run & Operate

- **Web UI** — `pnpm --filter @workspace/browser-desktop run dev` (port 20788, preview path `/`)
- **Desktop backend** — `bash /home/runner/workspace/start.sh` (starts Xvfb → Openbox → Chromium → x11vnc → websockify on port 5901)
- Both services start automatically when the project runs (via `artifacts/browser-desktop: web` and `artifacts/browser-desktop: novnc` workflows)

## Architecture

```
Browser tab → / (React UI) → Connect → iframe: /novnc/vnc.html
                                                       │
Browser tab → /novnc (websockify on :5901)
                    │  WebSocket bridge
                    ▼
                x11vnc (:5900)
                    │  VNC protocol
                    ▼
              Xvfb :99  (1280×720 virtual display)
                ├── openbox  (window manager)
                └── chromium (browser)
```

## Customization

- **Default URL**: Set `BROWSER_URL` env var (default: `https://www.google.com`)
- **VNC password**: Set `VNC_PASSWORD` env var in Replit Secrets
- **Screen resolution**: Edit `RESOLUTION` in `start.sh`

## Stack

- React + Vite (web UI)
- noVNC v1.4.0 (browser VNC client, in `novnc/`)
- websockify (WebSocket → TCP VNC bridge)
- x11vnc + Xvfb (virtual display + VNC server)
- Chromium + Openbox (browser + window manager)

## Where things live

- `start.sh` — main desktop startup script
- `novnc/` — noVNC static web client
- `artifacts/browser-desktop/` — React web app (landing + iframe)
- `artifacts/api-server/` — Express API server (health check)

## Architecture decisions

- Two services in one artifact: `web` (React UI at `/`) and `novnc` (websockify at `/novnc`) — allows a polished landing page while the VNC client is served separately
- websockify port (5901) is internal; the Replit path proxy routes `/novnc` traffic to it
- noVNC `path=novnc/` param tells it to connect WebSocket to `/novnc/` — matches the proxy route
- dbus errors in logs are expected/harmless in Replit's NixOS sandbox

## Product

Users open the app, click "Connect to Desktop", and get an interactive Chromium browser running in their browser tab.

## Gotchas

- The `novnc` workflow must be running for the desktop to be accessible
- dbus/D-Bus errors in the novnc workflow logs are normal — Chromium still works
- `start.sh` uses absolute path in artifact.toml because the workflow working directory is the artifact folder, not the workspace root

## User preferences

_Populate as you build — explicit user instructions worth remembering across sessions._
