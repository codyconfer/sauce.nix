"""Temporary COSMIC panel/dock colors for sauce-clamav-scan.service."""

import json
import os
import signal
import subprocess
import threading
from pathlib import Path

TINT = {"background": "Color([1.0, 0.35, 0.0])\n", "opacity": "1.0\n"}


def atomic_write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".sauce-tmp")
    temporary.write_text(text)
    temporary.replace(path)


class Indicator:
    def __init__(self, config_home, state_home):
        self.config_home = Path(config_home)
        self.state_file = (
            Path(state_home) / "sauce-cosmic-scan-indicator" / "original.json"
        )
        try:
            self.original = json.loads(self.state_file.read_text())
        except FileNotFoundError:
            self.original = {}
        except (OSError, ValueError) as error:
            raise RuntimeError(
                f"Cannot read background backup: {self.state_file}"
            ) from error
        allowed = {
            f"cosmic/com.system76.CosmicPanel.{name}/v1/{key}"
            for name in ("Panel", "Dock")
            for key in TINT
        }
        if not isinstance(self.original, dict) or any(
            key not in allowed or (value is not None and not isinstance(value, str))
            for key, value in self.original.items()
        ):
            raise RuntimeError(f"Invalid background backup: {self.state_file}")

    def tint(self):
        for name in ("Panel", "Dock"):
            directory = (
                self.config_home / "cosmic" / f"com.system76.CosmicPanel.{name}" / "v1"
            )
            # Do not replace backgrounds owned by declarative config symlinks.
            if any((directory / key).is_symlink() for key in TINT):
                continue
            for key, color in TINT.items():
                path = directory / key
                relative = str(path.relative_to(self.config_home))
                if relative in self.original:
                    continue
                self.original[relative] = path.read_text() if path.exists() else None
                # Persist the original before changing the live config. This also
                # allows recovery after SIGKILL, a crash, or a machine reboot.
                atomic_write(self.state_file, json.dumps(self.original))
                atomic_write(path, color)

    def restore(self):
        for relative, original in self.original.items():
            path = self.config_home / relative
            # Preserve settings the user changed while the scan was running.
            if (
                not path.is_symlink()
                and path.exists()
                and path.read_text() == TINT[path.name]
            ):
                if original is None:
                    path.unlink()
                else:
                    atomic_write(path, original)
        self.state_file.unlink(missing_ok=True)
        self.original.clear()


def scan_active():
    result = subprocess.run(
        [
            "systemctl",
            "--system",
            "show",
            "sauce-clamav-scan.service",
            "--property=ActiveState",
            "--value",
        ],
        capture_output=True,
        text=True,
        timeout=10,
        check=False,
    )
    if result.returncode:
        # A transient D-Bus failure must not be mistaken for a completed scan.
        return None
    state = result.stdout.strip()
    if state in {"activating", "active", "reloading", "deactivating"}:
        return True
    if state in {"inactive", "failed"}:
        return False
    return None


def main():
    home = Path.home()
    indicator = Indicator(
        os.environ.get("XDG_CONFIG_HOME", home / ".config"),
        os.environ.get("XDG_STATE_HOME", home / ".local/state"),
    )
    stopped = threading.Event()
    for sig in (signal.SIGTERM, signal.SIGINT):
        signal.signal(sig, lambda *_: stopped.set())
    try:
        while not stopped.is_set():
            try:
                active = scan_active()
            except (subprocess.TimeoutExpired, OSError):
                active = None
            if active is True:
                indicator.tint()
            elif active is False:
                indicator.restore()
            stopped.wait(2)
    finally:
        indicator.restore()


if __name__ == "__main__":
    main()
