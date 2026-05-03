import importlib.util
import tempfile
import unittest
from pathlib import Path
from unittest import mock


FLOW_PATH = Path(__file__).with_name("flow.py")
FLOW_SPEC = importlib.util.spec_from_file_location("flow_script", FLOW_PATH)
flow = importlib.util.module_from_spec(FLOW_SPEC)
assert FLOW_SPEC.loader is not None
FLOW_SPEC.loader.exec_module(flow)


class FlowDoctorTests(unittest.TestCase):
    def test_analyze_workflow_entry_reports_missing_worktree(self):
        entry = {
            "repo_root": "/tmp/repo",
            "repo_name": "repo",
            "branch": "feature/orphan",
            "worktree_path": "/tmp/does-not-exist",
            "tmux_session_id": "",
            "tmux_session_name": "",
            "tmux_window_id": "",
            "pane_ai": "",
            "pane_git": "",
            "pane_run": "",
        }

        result = flow.analyze_workflow_entry(entry)

        self.assertEqual(result["status"], "orphan")
        self.assertIn("missing-worktree", result["issue_codes"])
        self.assertEqual(result["suggested_fix"], 'flow destroy "feature/orphan"')

    def test_analyze_workflow_entry_reports_missing_pane_resume_hint(self):
        with tempfile.TemporaryDirectory() as tempdir:
            worktree = Path(tempdir) / "feature-ui"
            worktree.mkdir()
            entry = {
                "repo_root": tempdir,
                "repo_name": "repo",
                "branch": "feature/ui",
                "worktree_path": str(worktree),
                "tmux_session_id": "$1",
                "tmux_session_name": "1-repo",
                "tmux_window_id": "@9",
                "pane_ai": "%1",
                "pane_git": "%2",
                "pane_run": "%3",
            }

            with mock.patch.object(flow, "window_alive", return_value=True), mock.patch.object(
                flow, "session_alive", return_value=True
            ), mock.patch.object(flow, "pane_alive", side_effect=lambda pane_id: pane_id != "%2"), mock.patch.object(
                flow, "window_metadata_snapshot",
                return_value={
                    "branch": "feature/ui",
                    "repo_root": tempdir,
                    "worktree_path": str(worktree),
                },
            ), mock.patch.object(flow, "worktree_dirty", return_value=False):
                result = flow.analyze_workflow_entry(entry)

        self.assertEqual(result["status"], "running")
        self.assertIn("missing-pane-git", result["issue_codes"])
        self.assertEqual(result["suggested_fix"], 'flow resume "feature/ui"')

    def test_gc_candidates_only_include_safe_stale_entries(self):
        with tempfile.TemporaryDirectory() as tempdir:
            healthy_worktree = Path(tempdir) / "healthy"
            healthy_worktree.mkdir()
            stopped_worktree = Path(tempdir) / "stopped"
            stopped_worktree.mkdir()
            entries = [
                {
                    "repo_root": tempdir,
                    "repo_name": "repo",
                    "branch": "feature/orphan",
                    "worktree_path": str(Path(tempdir) / "missing"),
                    "tmux_window_id": "@1",
                },
                {
                    "repo_root": tempdir,
                    "repo_name": "repo",
                    "branch": "feature/stopped",
                    "worktree_path": str(stopped_worktree),
                    "tmux_window_id": "@2",
                },
                {
                    "repo_root": tempdir,
                    "repo_name": "repo",
                    "branch": "feature/running",
                    "worktree_path": str(healthy_worktree),
                    "tmux_window_id": "@3",
                },
            ]

            with mock.patch.object(flow, "window_alive", side_effect=lambda window_id: window_id == "@3"):
                candidates = flow.gc_candidates(entries)

        self.assertEqual([entry["branch"] for entry in candidates], ["feature/orphan"])


class FlowControlPlaneTests(unittest.TestCase):
    def test_build_parser_rejects_note_subcommand(self):
        parser = flow.build_parser()

        with self.assertRaises(SystemExit):
            parser.parse_args(["note", "path"])

    def test_flow_module_does_not_expose_workflow_context_helpers(self):
        self.assertFalse(hasattr(flow, "ensure_context_files"))
        self.assertFalse(hasattr(flow, "cmd_note_path"))
        self.assertFalse(hasattr(flow, "cmd_note_show"))


if __name__ == "__main__":
    unittest.main()
