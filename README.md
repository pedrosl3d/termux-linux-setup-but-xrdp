# termux-linux-setup

A unified script to easily set up native Linux desktop environments (XFCE4, LXQt, MATE, KDE) on Android via Termux. Includes GPU acceleration (Turnip/Zink), audio, Windows app support (Box64/Wine), and a comprehensive set of default tools.

Unlike the classic Termux-X11 setup, this version uses **XRDP**, so you connect to your phone's Linux desktop using Windows' **native Remote Desktop Connection (mstsc)** — no extra display-server APK to install or open on the phone.

## Prerequisites

Before running this script, you must install the correct version of Termux on your Android device.

1. **Termux Base App**: Do not download Termux from the Google Play Store, as that version is broken and no longer receives updates. You must download the official, updated version from F-Droid:
   * [Download Termux (F-Droid)](https://f-droid.org/en/packages/com.termux/)

That's it on the phone side — you do **not** need to install Termux-X11 or any other display-server app, since XRDP handles the connection over the network instead.

On the Windows side, you don't need to install anything either: **Remote Desktop Connection** (`mstsc`) is already built into Windows.

## How to Install

Open the **Termux** app and paste the following command to automatically download and run the setup script:

```bash
curl -O https://raw.githubusercontent.com/pedrosl3d/termux-linux-setup-but-xrdp/main/termux-linux-setup.sh && chmod +x termux-linux-setup.sh && ./termux-linux-setup.sh
```

During installation you'll be asked to:
1. Pick a Desktop Environment (XFCE4, LXQt, MATE, or KDE Plasma).
2. Set a Unix password with `passwd`. This is **not optional** — XRDP authenticates connections with a real username/password, the same way SSH does.

The script then installs the desktop, GPU drivers, audio, dev tools, Wine, and XRDP, and finishes by printing your connection details.

## How to Connect (XRDP)

1. Start the remote desktop server in Termux:
   ```bash
   ./start-xrdp.sh
   ```
   Keep Termux open (don't swipe it away from recent apps) while you're using the remote desktop — closing it kills the session.
2. The script prints your connection info, something like:
   ```
   Endereço/IP:  192.168.x.x
   Porta:        3389
   Usuário:      u0_a123
   Senha:        (the one you set with 'passwd')
   ```
3. On your **Windows PC**, open **Remote Desktop Connection** (search "mstsc" in the Start menu), and enter `IP:3389`.
4. Log in with the same username and password you set in Termux.

Your phone and PC need to be on the **same Wi-Fi network** for this to work.

To stop the desktop server:
```bash
./stop-xrdp.sh
```

If your phone's IP changes (e.g. you switched networks) and you need the connection details again, just run:
```bash
./rdp-info.sh
```

## Included Scripts

| Script | Purpose |
|---|---|
| `start-xrdp.sh` | Starts PulseAudio and the XRDP services (`xrdp-sesman` + `xrdp`), then prints connection info. The desktop itself launches automatically when you log in from Windows. |
| `stop-xrdp.sh` | Stops XRDP, the desktop session, and audio. |
| `rdp-info.sh` | Detects your current local IP and prints the address, port, and username needed to connect. Safe to re-run anytime. |

## Notes & Limitations

* **Same network required** — XRDP connects over local Wi-Fi; it won't work over mobile data or different networks without additional setup (e.g. a VPN).
* **No audio redirection** — app audio plays through the phone's speaker, not the PC, since this setup doesn't include a PulseAudio-over-RDP module.
* **Performance** — XRDP adds some overhead to encode the screen over the RDP protocol, so it can feel a bit slower or less smooth than the native Termux-X11 display, especially on weaker devices.
* **Keep Termux running** — the desktop session depends on the Termux process staying alive; closing the app fully ends the session.
