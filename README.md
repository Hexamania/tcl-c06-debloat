# TCL C06 Android TV Debloat Suite

An open-source automation utility designed to extract, back up, and permanently uninstall system bloatware from TCL Android 11 Smart TVs running on MediaTek SoC platforms (Target Profile: Device C06).

## 🛠️ The Architecture & The "Leanback" Focus Bug

Many generic Android TV debloating guides indiscriminately suggest removing `com.google.android.tvrecommendations` to block home screen advertisements. 

However, on TCL's MediaTek framework, **Android TV Core Services** handles vital components of the Leanback user interface infrastructure. Disabling it strips away the active focus tree and visual asset layering from system dialog overlays (such as `BluetoothPairingDialog`). 

As a result, connection request windows will pop up but completely ignore D-Pad remote control actions (`Unhandled key: keyCode 23`), rendering the TV unable to confirm input selection focus.

This suite provides two distinct pathways to navigate this dependency constraint.

## 📁 Repository Scripts

1. **`tcl-c06-repo-debloat.sh` (Safe Default):** Automatically extracts and uninstalls standard operator bloat, pre-installed user apps, and tracking configurations while explicitly locking **Core Services** to `enabled` to maintain flawless Bluetooth and dialogue navigation.
2. **`tcl-c06-extreme-build.sh` (Extreme "Free My TV" Configuration):** Completely strips the platform down to its absolute lowest footprint for max RAM overhead. **Warning:** This build purges Core Services. Users must control the display using a computer mirroring tool like `scrcpy` to confirm mouse-click coordinate presses for new Bluetooth pairings.

## 🚀 Execution Instructions

Ensure network ADB debugging is enabled inside your TV's developer settings, open Git Bash, and execute:

```bash
# Clone the repository workspace
cd tcl-c06-debloat-suite

# Run the Safe Debloat profile
./tcl-c06-repo-debloat.sh <YOUR_TV_IP> clean

# Run the Extreme Purge profile
./tcl-c06-extreme-build.sh <YOUR_TV_IP> clean
```

### 🔄 Recovery / Reinstallation
If you need to redeploy the original firmware binaries back to the device, pass the `restore` argument along with the script path:
```bash
./tcl-c06-repo-debloat.sh <YOUR_TV_IP> restore
```

## ⚠️ Disclaimer & Limitation of Liability

This software is provided **"AS IS"**, without warranty of any kind, express or implied. By running these execution layers on your consumer electronics, you accept full responsibility for any outcomes, including soft-bricks, localized user data dropouts, or voided hardware warranties. Proceed entirely at your own risk.
