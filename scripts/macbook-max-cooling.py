#!/usr/bin/env python3
"""
Maximum thermal throttling for Intel MacBooks with overheating issues.
Configuration optimized for minimal overhead and maximum cooling:
- Immediate reaction to CPU spikes (no EMA smoothing)
- Aggressive threshold (35%) to limit before heat builds up
- Longer interval (2s) to minimize monitor overhead
- Native ps subprocess (lowest overhead on macOS)
- No warmup = no startup CPU spike
- Simple logging with timestamps and levels
"""

import subprocess
import time
import os
import signal
import sys
import shutil
import platform

CPU_LIMIT = 85
CHECK_INTERVAL = 2
CPU_THRESHOLD = 35.0
NOTIFICATION_COOLDOWN = 30  # seconds

# Optional: LOG_LEVEL env var (DEBUG, INFO, WARN, ERROR)
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()
LEVELS = {"DEBUG": 0, "INFO": 1, "WARNING": 2, "ERROR": 3}
CURRENT_LEVEL = LEVELS.get(LOG_LEVEL, 1)

IGNORED_PROCESSES = {
    "kernel_task", "WindowServer", "root", "grep", "python", "python3",
    "loginwindow", "SystemUIServer", "Dock", "Finder", "cpulimit",
    "Terminal", "launchd", "coreaudiod"
}

_shutdown_requested = False


class Logger:
    @staticmethod
    def log(level, msg, *args):
        """Simple logger: timestamp + level + message"""
        if LEVELS.get(level, 1) < CURRENT_LEVEL:
            return
        timestamp = time.strftime("%H:%M:%S")
        if args:
            msg = msg % args
        print(f"[{timestamp}] [{level}] {msg}", flush=True)

    def info(self, msg, *args): self.log("INFO", msg, *args)

    def warning(self, msg, *args): self.log("WARNING", msg, *args)

    def error(self, msg, *args): self.log("ERROR", msg, *args)

    def debug(self, msg, *args): self.log("DEBUG", msg, *args)


logger = Logger()


def signal_handler(sig, frame):
    global _shutdown_requested
    logger.info("Interrupt detected (Ctrl + C). Shutting down...")
    global _shutdown_requested
    _shutdown_requested = True


def check_dependencies():
    missing = []

    # Check cpulimit with expanded PATH for Homebrew locations
    cpulimit_paths = [
        "/usr/local/bin/cpulimit",      # Intel Homebrew
        "/usr/bin/cpulimit",            # System
    ]
    cpulimit_found = False
    for path in cpulimit_paths:
        if os.path.exists(path) and os.access(path, os.X_OK):
            cpulimit_found = True
            break
    if not cpulimit_found and not shutil.which("cpulimit"):
        missing.append("cpulimit (brew install cpulimit)")

    if not shutil.which("ps"):
        missing.append("ps")
    if not shutil.which("pgrep"):
        missing.append("pgrep")

    if missing:
        logger.error("Missing dependencies:")
        for dep in missing:
            logger.error("   - %s", dep)
        return False

    logger.info("All dependencies found")
    logger.info("Using native ps for minimal overhead monitoring")
    return True


def check_sudo_access():
    try:
        cmd = ["sudo", "-n", "true"]
        result = subprocess.run(cmd, capture_output=True, timeout=2)
        if result.returncode == 0:
            logger.info("Sudo access available (passwordless)")
            return True
        logger.warning("Sudo requires password. Will prompt when needed.")
        test = subprocess.run(
            ["sudo", "echo", "Testing sudo..."],
            capture_output=True,
            timeout=10
        )
        if test.returncode == 0:
            logger.info("Sudo credentials cached")
            return True
        return False
    except Exception as error:
        logger.error("Sudo check failed: %s", error)
        return False


def is_cpulimit_active(pid):
    try:
        cmd = ["pgrep", "-f", f"cpulimit.*-p {pid}$"]
        result = subprocess.run(cmd, capture_output=True, text=True)
        return result.returncode == 0
    except Exception:
        return False


def get_top_processes():
    try:
        cmd = ["ps", "-axo", "pid,%cpu,comm", "-r"]
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=True
        )
        lines = result.stdout.strip().split("\n")[1:]

        processes = []
        for line in lines:
            parts = line.strip().split(maxsplit=2)
            if len(parts) < 3:
                continue
            pid_str, cpu_str, comm = parts
            try:
                pid = int(pid_str)
                cpu = float(cpu_str)
                base_comm = os.path.basename(comm)
                processes.append((pid, cpu, base_comm, comm))
            except (ValueError, IndexError):
                continue
        return processes
    except Exception as error:
        logger.error("Error getting processes: %s", error)
        return []


def apply_cpu_limit(pid, process_name):
    try:
        cmd = ["sudo", "cpulimit", "-l", str(CPU_LIMIT), "-p", str(pid), "-b"]
        subprocess.run(
            cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        return True
    except Exception as error:
        message = "Failed to apply limit to %s (PID: %d): %s"
        logger.error(message, process_name, pid, error)
        return False


def main():
    # Check for Apple Silicon (ARM) - not supported
    if platform.machine() == "arm64":
        logger.error("This tool is designed for Intel Macs (2016-2020) only")
        logger.error("Apple Silicon Macs (ARM) don't need this thermal control")
        logger.error("They manage thermals efficiently without external tools")
        sys.exit(1)

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    logger.info("=" * 55)
    logger.info("MacBook Max Cooling")
    logger.info("=" * 55)
    logger.info("CPU Limit:      %d%%", CPU_LIMIT)
    logger.info("Threshold:      %.1f%%", CPU_THRESHOLD)
    logger.info("Check Interval: %ds", CHECK_INTERVAL)
    logger.info("Monitor:        native ps")

    if not check_dependencies():
        logger.error("Install cpulimit with: brew install cpulimit")
        sys.exit(1)

    check_sudo_access()
    logger.info("Press Ctrl+C to exit")

    last_notification = {}

    while not _shutdown_requested:
        processes = get_top_processes()

        for pid, cpu, base_comm, full_comm in processes:
            if _shutdown_requested:
                break

            if any(ignored in full_comm for ignored in IGNORED_PROCESSES):
                continue

            if cpu > CPU_THRESHOLD:
                if not is_cpulimit_active(pid):
                    now = time.time()
                    if last_notification.get(pid, 0) < now - NOTIFICATION_COOLDOWN:
                        message = "Applying CPU limit to: %s (PID: %d) at %.1f%% CPU"
                        logger.info(message, base_comm, pid, cpu)
                        last_notification[pid] = now

                    apply_cpu_limit(pid, base_comm)

        for _ in range(CHECK_INTERVAL * 2):
            if _shutdown_requested:
                break
            time.sleep(0.5)

    logger.info("MacBook Max Cooling stopped.")


if __name__ == "__main__":
    main()
