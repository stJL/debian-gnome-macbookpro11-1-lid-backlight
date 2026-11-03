# Debian GNOME MacBookPro11,1 Lid Backlight Control

**English** | [繁體中文](README.zh-TW.md)

A lid-backlight control solution for the **2013 13-inch Retina MacBook Pro (MacBookPro11,1)** running **Debian 13 with GNOME**.

This project automatically turns off the internal display backlight when the laptop lid is closed, restores the previous brightness when opened, and allows the system to remain running for remote access.

The goal is to make an older MacBook practical as a headless or closed-lid Linux machine without unnecessarily suspending the system.

## Features

- Automatically turn off the internal display backlight after the lid has remained closed for **1 second**.
- Restore the previously saved brightness when the lid is opened.
- Re-check the ACPI lid state before changing the backlight.
- Use a short delay when opening the lid to reduce unwanted changes caused by transient lid-state events.
- Keep Linux running with the appropriate `systemd-logind` configuration.
- Record diagnostic messages for troubleshooting.

## Tested Environment

| Component | Configuration |
|---|---|
| Laptop | 2013 13-inch Retina MacBook Pro |
| Model identifier | MacBookPro11,1 |
| Operating system | Debian 13 (Trixie) |
| Desktop environment | GNOME |
| Backlight interface | `/sys/class/backlight/acpi_video0` |
| Lid state interface | `/proc/acpi/button/lid/*/state` |
| Event handler | ACPID |
| Remote access | GNOME Remote Desktop (RDP) |

This project was developed and tested on the hardware and software listed above.

Other MacBook models or Linux distributions may work if they expose compatible ACPI lid-state and backlight interfaces, but they have not been verified.

## How It Works

The solution uses ACPID to detect lid events and a shell script to control the internal display backlight.

### When the lid is closed

1. Read and save the current brightness level.
2. Wait for 1 second.
3. Check the lid state again.
4. If the lid is still closed, set the backlight brightness to `0`.

### When the lid is opened

1. Wait for 0.3 seconds.
2. Check the lid state again.
3. Restore the previously saved brightness.
4. Remove the temporary brightness record.

The delays and state checks help avoid unnecessary backlight changes during lid movement.

The saved brightness is stored temporarily at:

```text
/run/lid-backlight-brightness
```

This file is automatically cleared when the system reboots.

## Requirements

- Debian 13 (Trixie) with GNOME (the tested configuration).
- `acpid`.
- A working ACPI lid-state interface.
- A writable Linux backlight interface.
- Root privileges for installation and configuration.

## Installation

### 1. Install ACPID

```bash
sudo apt update
sudo apt install acpid
sudo systemctl enable --now acpid
```

### 2. Check the backlight interface

List the available backlight devices:

```bash
ls -l /sys/class/backlight/
```

The tested MacBook exposes:

```text
/sys/class/backlight/acpi_video0
```

Check the current and maximum brightness:

```bash
cat /sys/class/backlight/acpi_video0/brightness
cat /sys/class/backlight/acpi_video0/max_brightness
```

If your system exposes a different backlight device, edit the `BACKLIGHT` variable in `lid-backlight.sh`.

### 3. Check the ACPI lid-state interface

```bash
cat /proc/acpi/button/lid/*/state
```

The output should indicate either:

```text
state: open
```

or:

```text
state: closed
```

### 4. Install the script

Clone this repository:

```bash
git clone https://github.com/YOUR_USERNAME/debian-gnome-macbookpro11-1-lid-backlight.git
cd debian-gnome-macbookpro11-1-lid-backlight
```

Install the script:

```bash
sudo install -m 755 lid-backlight.sh /etc/acpi/lid-backlight.sh
```

Install the ACPID event rule:

```bash
sudo install -m 644 lid-backlight.acpi /etc/acpi/events/lid-backlight
```

Restart ACPID:

```bash
sudo systemctl restart acpid
```

### 5. Configure systemd-logind to ignore lid closure

To prevent the system from suspending when the lid is closed, create:

`/etc/systemd/logind.conf.d/ignore-lid.conf`

```ini
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
```

Reboot to apply the configuration:

```bash
sudo reboot
```

**Important:** This configuration prevents systemd-logind from suspending the system due to lid closure. It does not turn off the display backlight by itself. The ACPID script handles that separately.

## Testing

After installation:

1. Open the lid and note the current brightness level.
2. Close the lid.
3. Wait approximately 3–5 seconds.
4. Confirm that the internal display backlight is off.
5. Connect to the machine using SSH or your configured remote desktop service.
6. Open the lid and confirm that the previous brightness is restored.

Try closing the lid at different speeds and repeat the test several times.

## Troubleshooting

### Check the lid state

```bash
cat /proc/acpi/button/lid/*/state
```

### Check the current brightness

```bash
cat /sys/class/backlight/acpi_video0/brightness
```

### Monitor ACPI events

```bash
sudo acpi_listen
```

### View the diagnostic log

The script writes diagnostic messages to:

```text
/run/lid-backlight-debug.log
```

View the log:

```bash
sudo cat /run/lid-backlight-debug.log
```

The log is stored in `/run`, so it will not persist across reboots.

## Uninstallation

Remove the ACPID event rule and script:

```bash
sudo rm -f /etc/acpi/events/lid-backlight
sudo rm -f /etc/acpi/lid-backlight.sh
sudo systemctl restart acpid
```

If you also want to restore the default lid-suspend behavior, remove the logind override:

```bash
sudo rm -f /etc/systemd/logind.conf.d/ignore-lid.conf
sudo reboot
```

## Limitations and Notes

- This project was tested on a MacBookPro11,1 running Debian 13 with GNOME.
- Backlight device names may differ between MacBook models.
- The ACPI lid-state interface may also differ between systems.
- The 1-second closing delay and 0.3-second opening delay are based on testing on the hardware listed above.
- This project does not install or configure SSH, RDP, networking, or remote access services.
- Keeping a laptop running with its lid closed may increase internal temperatures. Ensure adequate ventilation.

## Acknowledgements

This project was implemented and tested by the repository maintainer on their own hardware.

**ChatGPT by OpenAI** assisted with technical troubleshooting, shell-script development, debugging, documentation, and project organization throughout the process.

The final implementation and hardware testing were carried out by the repository maintainer, with AI assistance.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
