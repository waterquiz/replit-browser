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

# 2. Start window manager with no decorations / auto-maximize
echo "[2/5] Starting openbox..."
mkdir -p /tmp/ob-config
cat > /tmp/ob-config/rc.xml << 'OBEOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc"
                xmlns:xi="http://www.w3.org/2001/XInclude">
  <resistance><strength>10</strength><screen_edge_strength>20</screen_edge_strength></resistance>
  <focus><focusNew>yes</focusNew><followMouse>no</followMouse><focusLast>yes</focusLast><underMouse>no</underMouse><focusDelay>200</focusDelay><raiseOnFocus>no</raiseOnFocus></focus>
  <placement><policy>Smart</policy><center>yes</center><monitor>Primary</monitor><primaryMonitor>1</primaryMonitor></placement>
  <theme><name>Clearlooks</name><titleLayout>NLIMC</titleLayout><keepBorder>no</keepBorder><animateIconify>no</animateIconify><font place="ActiveWindow"><name>sans</name><size>8</size><weight>bold</weight><slant>normal</slant></font><font place="InactiveWindow"><name>sans</name><size>8</size><weight>bold</weight><slant>normal</slant></font><font place="MenuHeader"><name>sans</name><size>9</size><weight>normal</weight><slant>normal</slant></font><font place="MenuItem"><name>sans</name><size>9</size><weight>normal</weight><slant>normal</slant></font><font place="OnScreenDisplay"><name>sans</name><size>9</size><weight>bold</weight><slant>normal</slant></font></theme>
  <desktops><number>1</number><firstdesk>1</firstdesk><popupTime>875</popupTime></desktops>
  <resize><drawContents>yes</drawContents><popupShow>Nonpixel</popupShow><popupPosition>Center</popupPosition><popupFixedPosition><x>10</x><y>10</y></popupFixedPosition></resize>
  <keyboard></keyboard>
  <mouse></mouse>
  <menu><hideDelay>200</hideDelay><middle>no</middle><submenuShowDelay>100</submenuShowDelay><submenuHideDelay>400</submenuHideDelay><applicationIcons>yes</applicationIcons><manageDesktops>yes</manageDesktops></menu>
  <dock><position>Bottom</position><floatingX>0</floatingX><floatingY>0</floatingY><noStrut>no</noStrut><stacking>Above</stacking><direction>Vertical</direction><autoHide>no</autoHide><hideDelay>300</hideDelay><showDelay>300</showDelay><moveButton>Middle</moveButton></dock>
  <applications>
    <application name="*">
      <decor>no</decor>
      <maximized>true</maximized>
    </application>
  </applications>
</openbox_config>
OBEOF
openbox --config-file /tmp/ob-config/rc.xml &
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
