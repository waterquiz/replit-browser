#!/bin/bash
set -e

DISPLAY_NUM=99
DISPLAY=":${DISPLAY_NUM}"
RESOLUTION="1280x720x24"
VNC_PORT=5900
NOVNC_PORT=5901
VNC_PASSWORD="${VNC_PASSWORD:-}"
NOVNC_DIR="$(dirname "$0")"

echo "=== Starting Browser Desktop ==="
echo "VNC internal port: ${VNC_PORT}"
echo "noVNC web port: ${NOVNC_PORT}"
echo "Display: ${DISPLAY}"
echo "Resolution: ${RESOLUTION}"

cleanup() {
    echo "Cleaning up processes..."
    pkill -f "Xvfb :${DISPLAY_NUM}" 2>/dev/null || true
    pkill -f x11vnc 2>/dev/null || true
    pkill -f websockify 2>/dev/null || true
    pkill -f chromium 2>/dev/null || true
    pkill -f openbox 2>/dev/null || true
}

trap cleanup EXIT

# Kill any leftover processes from previous runs
pkill -f "Xvfb :${DISPLAY_NUM}" 2>/dev/null || true
sleep 1

# 1. Start the virtual display
echo "[1/5] Starting Xvfb on ${DISPLAY}..."
Xvfb "${DISPLAY}" -screen 0 "${RESOLUTION}" -ac +extension GLX +render -noreset &
sleep 3

# Wait for display to be ready
for i in 1 2 3 4 5; do
    if DISPLAY="${DISPLAY}" xdpyinfo >/dev/null 2>&1; then
        echo "X display ready!"
        break
    fi
    echo "Waiting for X display... attempt $i"
    sleep 2
done

export DISPLAY="${DISPLAY}"

# 2. Start window manager
echo "[2/5] Starting openbox..."
openbox &
sleep 1

# 3. Launch Chromium with the default URL
DEFAULT_URL="${BROWSER_URL:-https://www.google.com}"
echo "[3/5] Launching Chromium at ${DEFAULT_URL}..."
chromium \
    --no-sandbox \
    --test-type \
    --disable-infobars \
    --disable-dev-shm-usage \
    --disable-software-rasterizer \
    --start-maximized \
    --no-first-run \
    --disable-translate \
    --disable-notifications \
    --disable-default-apps \
    --window-size=1280,720 \
    "${DEFAULT_URL}" &
sleep 3

# 4. Start VNC server
echo "[4/5] Starting x11vnc on port ${VNC_PORT}..."
if [ -n "$VNC_PASSWORD" ]; then
    x11vnc -display "${DISPLAY}" -rfbport "${VNC_PORT}" \
        -passwd "${VNC_PASSWORD}" -forever -shared -bg \
        -o /tmp/x11vnc.log 2>/dev/null
else
    x11vnc -display "${DISPLAY}" -rfbport "${VNC_PORT}" \
        -nopw -forever -shared -bg \
        -o /tmp/x11vnc.log 2>/dev/null
fi
sleep 2

# 5. Start noVNC/websockify on dedicated port
echo "[5/5] Starting noVNC websockify on port ${NOVNC_PORT}..."
websockify --web "${NOVNC_DIR}" "${NOVNC_PORT}" "localhost:${VNC_PORT}" &

echo ""
echo "=== Browser Desktop is ready! ==="
echo "noVNC WebSocket serving on port ${NOVNC_PORT}"
echo "Connect via the web app or at /novnc/vnc.html"

wait
