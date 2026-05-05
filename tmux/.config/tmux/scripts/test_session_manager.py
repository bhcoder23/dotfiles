import importlib.util
import unittest
from pathlib import Path
from unittest import mock


SESSION_MANAGER_PATH = Path(__file__).with_name("session_manager.py")
SESSION_MANAGER_SPEC = importlib.util.spec_from_file_location("session_manager_script", SESSION_MANAGER_PATH)
session_manager = importlib.util.module_from_spec(SESSION_MANAGER_SPEC)
assert SESSION_MANAGER_SPEC.loader is not None
SESSION_MANAGER_SPEC.loader.exec_module(session_manager)


class SessionManagerTests(unittest.TestCase):
    def test_main_focus_right_switches_to_next_session_in_order(self):
        sessions = [
            {"id": "$1", "name": "1-mini", "created": 1, "index": 1, "label": "mini"},
            {"id": "$2", "name": "2-raap", "created": 2, "index": 2, "label": "raap"},
            {"id": "$3", "name": "3-nacos", "created": 3, "index": 3, "label": "nacos"},
        ]

        with mock.patch.object(session_manager, "list_sessions", return_value=sessions), mock.patch.object(
            session_manager, "current_session_id", return_value="$2"
        ), mock.patch.object(session_manager, "run_tmux") as run_tmux:
            session_manager.main(["session_manager.py", "focus", "right"])

        run_tmux.assert_has_calls(
            [
                mock.call(["switch-client", "-t", "$3"], check=False),
                mock.call(["refresh-client", "-S"], check=False),
            ]
        )

    def test_main_focus_left_stops_at_left_edge_without_wrapping(self):
        sessions = [
            {"id": "$1", "name": "1-mini", "created": 1, "index": 1, "label": "mini"},
            {"id": "$2", "name": "2-raap", "created": 2, "index": 2, "label": "raap"},
        ]

        with mock.patch.object(session_manager, "list_sessions", return_value=sessions), mock.patch.object(
            session_manager, "current_session_id", return_value="$1"
        ), mock.patch.object(session_manager, "run_tmux") as run_tmux:
            session_manager.main(["session_manager.py", "focus", "left"])

        run_tmux.assert_not_called()


if __name__ == "__main__":
    unittest.main()
