# MacBook Thermal Control

> Smart thermal throttling for Intel MacBooks (2016-2020) suffering from overheating.

## 🎯 What does it do?

- Monitors CPU in real-time using native `ps` (minimal overhead ~0.08% CPU)
- Applies `cpulimit` to processes exceeding a configurable threshold (default 35%)
- **No EMA, no psutil, no heavy dependencies** → overhead < 0.1% CPU
- Designed for Intel MacBooks with overheating issues
- Runs as a background service via launchd (auto-starts at login)
- Works with Macs Fan Control for optimal thermal management

##🚀 Quick Install (One Line)

**No git required — downloads via zip (no git needed):**

```bash
curl -fsSL https://raw.githubusercontent.com/hugofer93/macbook-thermal-control/main/bootstrap.sh | bash
```

**What the bootstrap does:**
1. Downloads the latest release as zip (no git required)
2. Extracts to `~/.local/share/macbook-thermal-control`
3. Runs the installer automatically

---

### Manual Install (Alternative)

```bash
# 1. Clone the repo
git clone https://github.com/hugofer93/macbook-thermal-control.git
cd macbook-thermal-control

# 2. Run installer (requires sudo, handles dependencies, launchd service, etc.)
sudo ./install.sh
```

---

## 🔧 What the Installer Does

The `install.sh` script handles everything:

1. **Checks system** — macOS, Intel CPU, Homebrew
2. **Installs dependencies** — `cpulimit` (required), Macs Fan Control (optional)
3. **Generates launchd plist** — with your actual install path
4. **Optionally installs launchd service** — auto-starts at login as root (for `cpulimit`)
4. **Configures Macs Fan Control** — shows recommended fan curve

**After install, the service runs automatically at login.**

---

## 🔧 Recommended: Use with Macs Fan Control

For best results, combine this script with **Macs Fan Control** to manage fan speeds:

```bash
# Install Macs Fan Control (optional but highly recommended)
brew install --cask macs-fan-control
```

Then configure Macs Fan Control with an aggressive fan curve:
- **Fan starts increasing at 35°C**
- **Maximum fan speed at 50°C**

This combination provides the best thermal management: the script limits CPU power intake, while Macs Fan Control maximizes heat dissipation.

---

## 📊 Typical Results (Intel MacBook with overheating)

| Metric | Before | After |
|--------|--------|-------|
| Idle temp | 55-60°C | 40-45°C |
| Sustained load temp | 95-100°C (throttling) | 70-80°C (no throttling) |
| Fan RPM | 6000+ constant | 3500-4500 variable |

---

## ⚙️ Configuration

Edit `scripts/macbook-max-cooling.py` to adjust:

```python
CPU_LIMIT = 85          # CPU limit applied by cpulimit (%)
CHECK_INTERVAL = 2      # Check interval in seconds
CPU_THRESHOLD = 35.0    # Threshold to trigger limiting (%)
NOTIFICATION_COOLDOWN = 30  # Seconds between notifications per process
```

| Parameter | Description |
|-----------|-------------|
| `CPU_LIMIT` | Max CPU % for limited processes (85% = leaves 15% headroom) |
| `CHECK_INTERVAL` | Seconds between process checks (2s = low overhead) |
| `CPU_THRESHOLD` | CPU % to trigger limiting (35% = aggressive/preventive) |
| `NOTIFICATION_COOLDOWN` | Seconds between notifications per PID (30s) |

Or use `config.example.yaml` as a reference for a `config.yaml`.

---

## 🛡️ Safety

- Only uses `cpulimit` (standard tool, no kernel modifications)
- Does not disable hardware thermal protections
- Critical processes ignored (kernel_task, WindowServer, etc.)
- Ctrl+C to stop gracefully
- Runs as root via launchd only for `cpulimit` access

---

## 📋 Requirements

- macOS (Intel, 2016-2020)
- Python 3.6+
- `cpulimit` (`brew install cpulimit`)
- sudo access (for `cpulimit`)
- **Macs Fan Control** (`brew install --cask macs-fan-control`) — *optional but highly recommended*

---

## 🗑️ Uninstall

```bash
sudo ~/.local/share/macbook-thermal-control/uninstall.sh
```

This removes:
- The launchd service (if installed)
- All running instances
- The installation directory

---

## 📋 Viewing Logs

The service writes logs to `/tmp/`. You can view them in real-time:

```bash
# Follow logs in real-time (stdout)
tail -f /tmp/macbook-thermal-control.log

# Follow error logs in real-time (stderr)
tail -f /tmp/macbook-thermal-control.err
```

You can also check the launchd service status:

```bash
# Check service status
sudo launchctl print system/com.user.macbook-thermal-control

# Check if service is loaded
sudo launchctl list | grep macbook-thermal-control

# View recent system logs for the service
log show --predicate 'process == "macbook-thermal-control"' --last 1h
```

---

## 🤝 Contributing

1. Fork → branch → PR
2. Test on your hardware
3. Document changes

---

## 📄 License

MIT License - See [LICENSE](LICENSE)
