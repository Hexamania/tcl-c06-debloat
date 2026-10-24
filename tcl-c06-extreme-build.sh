#!/usr/bin/env bash
# Extreme "Free My TV" Hard-Debloat Profile for TCL C06 / MediaTek Platform
# WARNING: This script purges Core Services. Screen mirror tools (scrcpy) are required for pairing.
# Usage: ./tcl-c06-extreme-build.sh <TV_IP> clean | restore

set -u
export MSYS_NO_PATHCONV=1

IP="${1:-}"
MODE="${2:-clean}"

if [ -z "$IP" ]; then
    echo "Usage: ./tcl-c06-extreme-build.sh <TV_IP> clean | restore"
    exit 1
fi

SER="$IP:5555"
echo "Connecting to TV at $SER..."
adb connect "$SER" >/dev/null 2>&1

if ! adb -s "$SER" get-state >/dev/null 2>&1; then
    echo "Error: Device unreachable."
    exit 1
fi

# The Nuclear List: Purges launchers, backdrops, and core framework overlays
APPS=(
  au.com.stan.and
  tv.wuaki.apptv
  com.tcl.esticker
  com.tcl.movieark
  com.tcl.gallery
  com.tcl.browser
  com.tcl.usercenter
  com.tcl.smartalexa
  com.tcl.messagebox
  com.google.android.play.games
  com.google.android.waterfall.overseas
  com.google.android.tvlauncher
  com.google.android.backdrop             # Google Daydream Screensavers (~150MB)
  com.google.android.tvrecommendations   # Android TV Core Services (Leanback Framework)
)

mkdir -p backups
touch repo_execution.log

case "$MODE" in
  clean)
    echo "--- EXTREME PURGE SESSION STARTED: $(date) ---" >> repo_execution.log
    echo "[WARNING] Purging system navigation frameworks. Maximum RAM configuration active."
    
    for app in "${APPS[@]}"; do
        if adb -s "$SER" shell pm list packages | tr -d '\r' | grep -qx "package:$app"; then
            echo "Purging: $app"
            mkdir -p "backups/$app"
            for path in $(adb -s "$SER" shell pm path "$app" | tr -d '\r' | sed 's/^package://'); do
                adb -s "$SER" pull "$path" "backups/$app/" >/dev/null 2>&1
            done
            
            if ls "backups/$app"/*.apk >/dev/null 2>&1; then
                result=$(adb -s "$SER" shell pm uninstall --user 0 "$app" | tr -d '\r')
                echo "  [PURGED] -> $app ($result)"
                echo "[EXTREME_PURGE][$(date +'%Y-%m-%d %H:%M:%S')] -> $app ($result)" >> repo_execution.log
            fi
        fi
    done
    ;;

  restore)
    echo "Restoring extreme purge modifications..."
    for app in "${APPS[@]}"; do
        if ls "backups/$app"/*.apk >/dev/null 2>&1; then
            echo "Restoring: $app"
            result=$(adb -s "$SER" install-multiple -r "backups/$app"/*.apk 2>&1 | tail -1 | tr -d '\r')
            echo "  [RESTORED] -> $result"
        fi
    done
    ;;
esac
