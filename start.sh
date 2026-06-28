#!/bin/bash
set -e

DISPLAY_NUM=99
DISPLAY=":${DISPLAY_NUM}"
RESOLUTION="1280x720x24"
VNC_PORT=5900
NOVNC_PORT=5901
VNC_PASSWORD="${VNC_PASSWORD:-}"
NOVNC_DIR="$(dirname "$0")"
WORKSPACE_DIR="$(cd "$(dirname "$0")" && pwd)"
CHROME_PROFILE="${WORKSPACE_DIR}/chrome-profile"
EXT_DIR="${WORKSPACE_DIR}/extensions/violentmonkey"
ENABLER_DIR="${WORKSPACE_DIR}/extensions/enabler"
EXT_ID="ababaaaiajabagagaeacabamakajaoam"

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

# 3. Pre-seed Chrome profile (developer mode + extension pin)
echo "[3/6] Setting up Chrome profile..."
if [ ! -d "${CHROME_PROFILE}/Default" ]; then
    mkdir -p "${CHROME_PROFILE}/Default"
    python3 - "${CHROME_PROFILE}/Default/Preferences" "${EXT_ID}" << 'PYEOF'
import json, sys
prefs_path, ext_id = sys.argv[1], sys.argv[2]
prefs = {
    "extensions": {
        "ui": {"developer_mode": True},
        "settings": {
            ext_id: {
                "state": 1,
                "is_pinned": True,
                "location": 4
            }
        }
    }
}
with open(prefs_path, "w") as f:
    json.dump(prefs, f, indent=2)
print(f"Profile pre-seeded at {prefs_path}")
PYEOF
else
    # Ensure developer mode stays on in existing profile
    python3 - "${CHROME_PROFILE}/Default/Preferences" "${EXT_ID}" << 'PYEOF'
import json, sys
prefs_path, ext_id = sys.argv[1], sys.argv[2]
try:
    with open(prefs_path) as f:
        prefs = json.load(f)
except Exception:
    prefs = {}
prefs.setdefault("extensions", {}).setdefault("ui", {})["developer_mode"] = True
prefs["extensions"].setdefault("settings", {}).setdefault(ext_id, {})["is_pinned"] = True
with open(prefs_path, "w") as f:
    json.dump(prefs, f, indent=2)
print("Developer mode enforced in existing profile")
PYEOF
fi

# 4. Launch Chromium with the default URL
echo "[4/6] Launching Chromium..."
DEFAULT_URL="${BROWSER_URL:-https://www.google.com}"
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
    --user-data-dir="${CHROME_PROFILE}" \
    --load-extension="${EXT_DIR},${ENABLER_DIR}" \
    --allow-legacy-mv2-extensions \
    --enable-features=AllowLegacyMV2Extensions \
    --disable-features=ExtensionManifestV2Disabled,ExtensionManifestV2Unsupported \
    "${DEFAULT_URL}" &
sleep 5

# Force-enable the extension via xdotool if Chrome disables it
(
  sleep 6
  # Find the actual extension ID Chrome assigned
  ACTUAL_EXT_ID=$(python3 -c "
import json, glob, os
profile_dir = '${CHROME_PROFILE}/Default'
ext_dir = os.path.join(profile_dir, 'Extensions')
if os.path.exists(ext_dir):
    ids = [d for d in os.listdir(ext_dir) if len(d) == 32]
    # Filter to our loaded extension (not Chrome built-ins)
    for eid in ids:
        prefs_path = os.path.join(profile_dir, 'Preferences')
        try:
            with open(prefs_path) as f:
                p = json.load(f)
            s = p.get('extensions', {}).get('settings', {}).get(eid, {})
            name = s.get('manifest', {}).get('name', '')
            if 'monkey' in name.lower() or 'violent' in name.lower():
                print(eid)
                break
        except:
            pass
" 2>/dev/null)

  if [ -n "\$ACTUAL_EXT_ID" ]; then
    echo "Detected extension ID: \$ACTUAL_EXT_ID"
    # Navigate to chrome://extensions and enable the extension
    DISPLAY="${DISPLAY}" xdotool key ctrl+t
    sleep 1
    DISPLAY="${DISPLAY}" xdotool type --clearmodifiers "chrome://extensions/"
    DISPLAY="${DISPLAY}" xdotool key Return
    sleep 2
    # Re-write preferences to force-enable (Chrome reads on next restart)
    python3 - "${CHROME_PROFILE}/Default/Preferences" "\$ACTUAL_EXT_ID" << 'PYEOF'
import json, sys
prefs_path, ext_id = sys.argv[1], sys.argv[2]
try:
    with open(prefs_path) as f:
        prefs = json.load(f)
except:
    sys.exit(0)
s = prefs.get('extensions', {}).get('settings', {}).get(ext_id, {})
if s.get('state') == 0 or s.get('disable_reasons'):
    s['state'] = 1
    s['disable_reasons'] = 0
    s['is_pinned'] = True
    prefs['extensions']['settings'][ext_id] = s
    prefs.setdefault('extensions', {}).setdefault('ui', {})['developer_mode'] = True
    with open(prefs_path, 'w') as f:
        json.dump(prefs, f, indent=2)
    print(f"Force-enabled extension {ext_id} in preferences")
PYEOF
    # Close the tab we opened
    DISPLAY="${DISPLAY}" xdotool key ctrl+w
  else
    echo "Extension ID not detected in profile yet"
  fi
) &

# 5. Start VNC server
echo "[5/6] Starting x11vnc on port ${VNC_PORT}..."
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

# 6. Start noVNC/websockify on dedicated port
echo "[6/6] Starting noVNC websockify on port ${NOVNC_PORT}..."
websockify --web "${NOVNC_DIR}" "${NOVNC_PORT}" "localhost:${VNC_PORT}" &

echo ""
echo "=== Browser Desktop is ready! ==="
echo "noVNC WebSocket serving on port ${NOVNC_PORT}"
echo "Connect via the web app or at /novnc/vnc.html"

wait
