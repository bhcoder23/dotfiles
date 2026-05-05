import json
import os
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path


WINDOW_ICON_SCRIPT = Path(__file__).resolve().parent.parent / "tmux-status" / "window_task_icon.sh"
CACHE_FILE = Path("/tmp/tmux-tracker-cache.json")


class WindowTaskIconTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.bin_dir = Path(self.tempdir.name)
        self._write_tmux_stub()
        self.cache_backup = CACHE_FILE.read_bytes() if CACHE_FILE.exists() else None

    def tearDown(self):
        if self.cache_backup is None:
            CACHE_FILE.unlink(missing_ok=True)
        else:
            CACHE_FILE.write_bytes(self.cache_backup)
        self.tempdir.cleanup()

    def _write_tmux_stub(self):
        tmux_path = self.bin_dir / "tmux"
        tmux_path.write_text(
            """#!/usr/bin/env python3
import sys

args = sys.argv[1:]
if args[:4] == ["list-panes", "-t", "@5", "-F"]:
    sys.stdout.write("0\\n")
elif args == ["display-message", "-p", "-t", "@5", "#{session_id}"]:
    sys.stdout.write("$1\\n")
else:
    raise SystemExit(f"unexpected tmux args: {args!r}")
"""
        )
        tmux_path.chmod(tmux_path.stat().st_mode | stat.S_IXUSR)

    def test_window_icon_ignores_stale_other_session_completion(self):
        CACHE_FILE.write_text(
            json.dumps(
                {
                    "tasks": [
                        {
                            "session_id": "$9",
                            "window_id": "@5",
                            "status": "completed",
                            "acknowledged": False,
                        },
                        {
                            "session_id": "$1",
                            "window_id": "@5",
                            "status": "in_progress",
                            "acknowledged": True,
                        },
                    ]
                }
            )
        )

        env = os.environ.copy()
        env["PATH"] = f"{self.bin_dir}:{env['PATH']}"
        result = subprocess.run(
            [str(WINDOW_ICON_SCRIPT), "@5", "0", "0"],
            text=True,
            capture_output=True,
            env=env,
            check=False,
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "⏳")


if __name__ == "__main__":
    unittest.main()
