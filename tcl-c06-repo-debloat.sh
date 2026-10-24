#!/usr/bin/env bash
# Git-ready Safe Debloat & Extraction Suite for TCL Android TV (C06, MediaTek Platform)
# Usage: ./tcl-c06-repo-debloat.sh <TV_IP> clean | restore

set -u
export MSYS_NO_PATHCONV=1 # Prevent Git Bash from converting paths to Windows format

IP="${1:-}"
MODE="${2:-clean}"

if [ -z "$IP" ]; then
    echo "Usage: ./tcl-c06-repo-debloat.sh <TV_IP> clean | restore"
    exit 1
fi

SER="$IP:5555"
echo "Connecting to target Android TV over ADB at $SER..."
adb connect "$SER" >/dev/null 2>&1

if ! adb -s "$SER" get-state >/dev/null 2>&1; then
    echo "Error: Device unreachable at $SER. Verify network or accept connection prompt on screen."
    exit 1
fi

# Safe Inventory: Bloatware, carrier apps, and non-essential vendor overlays
APPS=(
  au.com.stan.and                         # Stan (AU Carrier Bloat)
  tv.wuaki.apptv                          # Rakuten TV (EU Carrier Bloat)
  com.tcl.esticker                        # TCL Retail Store Demo Overlay
  com.tcl.movieark                        # TCL Movie Ark App
  com.tcl.gallery                         # TCL Native Gallery App
  com.tcl.browser                         # TCL Native WebView Browser
  com.tcl.usercenter                      # TCL Cloud Profile Framework
  com.tcl.smartalexa                      # TCL Alexa Listener Service
  com.tcl.messagebox                      # TCL Custom System Popup Interceptor
  com.google.android.play.games           # Google Play Games TV Package
  com.google.android.waterfall.overseas   # TCL Ambient Screen Overlay
  com.google.android.tvlauncher           # Stock Launcher (Keeps Custom Launchers Active)
)

# Core Architecture Lock: Enforce Leanback Framework Integrity
echo "[SECURITY] Enforcing Android TV Core Services (Bluetooth/Focus Fix)..."
adb -s "$SER" shell pm enable com.google.android.tvrecommendations >/dev/null 2>&1

# Setup workspace
mkdir -p backups
touch repo_execution.log

case "$MODE" in
  clean)
    echo "Executing permanent removal and local repository sync..."
    echo "--- SAFE DEBLOAT SESSION STARTED: $(date) ---" >> repo_execution.log
    
    for app in "${APPS[@]}"; do
        if adb -s "$SER" shell pm list packages | tr -d '\r' | grep -qx "package:$app"; then
            echo "Processing: $app"
            mkdir -p "backups/$app"
            
            for path in $(adb -s "$SER" shell pm path "$app" | tr -d '\r' | sed 's/^package://'); do
                adb -s "$SER" pull "$path" "backups/$app/" >/dev/null 2>&1
            done
            
            if ls "backups/$app"/*.apk >/dev/null 2>&1; then
                result=$(adb -s "$SER" shell pm uninstall --user 0 "$app" | tr -d '\r')
                echo "  [SUCCESS] -> Backed up and uninstalled ($result)"
                echo "[UNINSTALLED][$(date +'%Y-%m-%d %H:%M:%S')] -> $app ($result)" >> repo_execution.log
            else
                echo "  [ERROR] -> Backup extraction failed. Skipping uninstallation for safety."
                echo "[BACKUP_FAILED][$(date +'%Y-%m-%d %H:%M:%S')] -> $app" >> repo_execution.log
            fi
        else
            echo "  [SKIP] -> $app is not installed."
        fi
    done
    echo "Process complete. Logs saved to repo_execution.log."
    ;;

  restore)
    echo "Re-injecting vendor packages from local repository..."
    for app in "${APPS[@]}"; do
        if ls "backups/$app"/*.apk >/dev/null 2>&1; then
            echo "Restoring: $app"
            result=$(adb -s "$SER" install-multiple -r "backups/$app"/*.apk 2>&1 | tail -1 | tr -d '\r')
            echo "  [DEPLOYED] -> $result"
            echo "[RESTORED][$(date +'%Y-%m-%d %H:%M:%S')] -> $app ($result)" >> repo_execution.log
        else
            echo "  [SKIP] -> No backups found for $app"
        fi
    done
    ;;
  *)
    echo "Invalid argument. Use 'clean' or 'restore'."
    exit 1
    ;;
esac
