"""Exercise the indicator without touching a real COSMIC session."""

import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("indicator", sys.argv.pop(1))
assert spec is not None and spec.loader is not None
indicator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(indicator)


class IndicatorTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.config = self.root / "config"
        self.state = self.root / "state"
        self.panel = self.config / "cosmic/com.system76.CosmicPanel.Panel/v1"
        self.panel.mkdir(parents=True)
        (self.panel / "background").write_text("ThemeDefault\n")
        (self.panel / "opacity").write_text("0.8\n")
        self.watcher = indicator.Indicator(self.config, self.state)

    def test_tint_and_restore(self):
        self.watcher.tint()
        self.watcher.tint()  # Must not back up orange over the original.
        self.assertEqual(
            (self.panel / "background").read_text(), indicator.TINT["background"]
        )
        self.assertEqual((self.panel / "opacity").read_text(), "1.0\n")
        self.watcher.restore()
        self.assertEqual((self.panel / "background").read_text(), "ThemeDefault\n")
        self.assertEqual((self.panel / "opacity").read_text(), "0.8\n")
        dock = self.config / "cosmic/com.system76.CosmicPanel.Dock/v1"
        self.assertFalse((dock / "background").exists())
        self.assertFalse((dock / "opacity").exists())
        self.assertFalse(self.watcher.state_file.exists())

    def test_restart_recovers_originals(self):
        self.watcher.tint()
        restarted = indicator.Indicator(self.config, self.state)
        restarted.tint()
        restarted.restore()
        self.assertEqual((self.panel / "background").read_text(), "ThemeDefault\n")

    def test_preserve_manual_changes(self):
        self.watcher.tint()
        (self.panel / "background").write_text("Dark\n")
        self.watcher.restore()
        self.assertEqual((self.panel / "background").read_text(), "Dark\n")

    def test_skip_declarative_symlinks(self):
        target = self.root / "managed-background"
        target.write_text("Light\n")
        (self.panel / "background").unlink()
        (self.panel / "background").symlink_to(target)
        self.watcher.tint()
        self.watcher.restore()
        self.assertTrue((self.panel / "background").is_symlink())
        self.assertEqual(target.read_text(), "Light\n")

    def test_reject_invalid_backup(self):
        indicator.atomic_write(self.watcher.state_file, '{"../../outside": "Dark"}')
        with self.assertRaises(RuntimeError):
            indicator.Indicator(self.config, self.state)

    def test_systemd_states(self):
        for state, expected in (
            ("activating", True),
            ("active", True),
            ("deactivating", True),
            ("inactive", False),
            ("failed", False),
            ("", None),
        ):
            with (
                self.subTest(state=state),
                patch.object(
                    indicator.subprocess,
                    "run",
                    return_value=subprocess.CompletedProcess([], 0, state + "\n", ""),
                ),
            ):
                self.assertIs(indicator.scan_active(), expected)
        with patch.object(
            indicator.subprocess,
            "run",
            return_value=subprocess.CompletedProcess([], 1, "", "D-Bus unavailable"),
        ):
            self.assertIsNone(indicator.scan_active())


unittest.main()
