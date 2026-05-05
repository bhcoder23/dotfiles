import os
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path


PANE_TITLE_SCRIPT = Path(__file__).resolve().with_name("pane_starship_title.sh")


class PaneTitleTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.bin_dir = Path(self.tempdir.name)
        self.project_docs_dir = self.bin_dir / "project" / "docs"
        self.project_docs_dir.mkdir(parents=True)
        self._write_tmux_stub()
        self._write_starship_stub()

    def tearDown(self):
        self.tempdir.cleanup()

    def _write_tmux_stub(self):
        tmux_path = self.bin_dir / "tmux"
        tmux_path.write_text(
            """#!/usr/bin/env python3
import sys

args = sys.argv[1:]
mapping = {
    ("display-message", "-p", "-t", "%1", "#{@op_work_theme}"): "Config publish 学习",
    ("display-message", "-p", "-t", "%1", "#{@op_work_now}"): "开始 Config publish 费曼课",
    ("display-message", "-p", "-t", "%1", "#{@op_question_pending}"): "",
    ("display-message", "-p", "-t", "%1", "#{@pane_watching}"): "",
}
sys.stdout.write(mapping.get(tuple(args), ""))
"""
        )
        tmux_path.chmod(tmux_path.stat().st_mode | stat.S_IXUSR)

    def _write_starship_stub(self):
        starship_path = self.bin_dir / "starship"
        starship_path.write_text(
            """#!/usr/bin/env bash
printf 'get-config/docs feature/get-config'
"""
        )
        starship_path.chmod(starship_path.stat().st_mode | stat.S_IXUSR)

    def test_opencode_pane_ignores_work_summary_overlay(self):
        env = os.environ.copy()
        env["PATH"] = f"{self.bin_dir}:{env['PATH']}"

        result = subprocess.run(
            [
                str(PANE_TITLE_SCRIPT),
                "",
                "%1",
                "/dev/ttys001",
                "OC | Build",
                "120",
                str(self.project_docs_dir),
                "op",
            ],
            text=True,
            capture_output=True,
            env=env,
            check=False,
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "get-config/docs feature/get-config")


if __name__ == "__main__":
    unittest.main()
