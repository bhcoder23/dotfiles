#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import shlex
import shutil
import subprocess
import sys
import tempfile
import time
from datetime import datetime, timezone
from pathlib import Path


REGISTRY_PATH = Path.home() / ".local" / "state" / "flow" / "registry.json"
FLOW_VERSION = 1
LAYOUT_RIGHT_PERCENT = 40
LAYOUT_BOTTOM_PERCENT = 50
SHELL_COMMAND = "exec ${SHELL:-/bin/zsh} -l"


class FlowError(RuntimeError):
    pass


def now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def print_stderr(message: str) -> None:
    print(message, file=sys.stderr)


def run(
    args: list[str],
    *,
    cwd: str | None = None,
    capture: bool = True,
    check: bool = True,
) -> str:
    completed = subprocess.run(
        args,
        cwd=cwd,
        text=True,
        capture_output=capture,
        env=os.environ.copy(),
    )
    if check and completed.returncode != 0:
        output = (completed.stderr or completed.stdout or "").strip()
        if output:
            raise FlowError(output)
        raise FlowError("command failed: " + " ".join(args))
    if not capture:
        return ""
    return (completed.stdout or "").strip()


def run_tmux(args: list[str], *, capture: bool = True, check: bool = True) -> str:
    socket_name = os.environ.get("FLOW_TMUX_SOCKET", "").strip()
    tmux_args = ["tmux"]
    if socket_name:
        tmux_args.extend(["-L", socket_name])
    tmux_args.extend(args)
    return run(tmux_args, capture=capture, check=check)


def run_git(args: list[str], *, cwd: str, capture: bool = True, check: bool = True) -> str:
    return run(["git", *args], cwd=cwd, capture=capture, check=check)


def shell_join(args: list[str]) -> str:
    return " ".join(shlex.quote(arg) for arg in args)


def registry_key(repo_root: str, branch: str) -> str:
    return f"{repo_root}::{branch}"


def default_registry() -> dict:
    return {"version": FLOW_VERSION, "workflows": {}}


def load_registry() -> dict:
    if not REGISTRY_PATH.exists():
        return default_registry()
    data = json.loads(REGISTRY_PATH.read_text())
    if not isinstance(data, dict):
        raise FlowError(f"invalid registry at {REGISTRY_PATH}")
    workflows = data.get("workflows")
    if not isinstance(workflows, dict):
        data["workflows"] = {}
    if "version" not in data:
        data["version"] = FLOW_VERSION
    return data


def save_registry(registry: dict) -> None:
    REGISTRY_PATH.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_name = tempfile.mkstemp(prefix="registry.", suffix=".json", dir=str(REGISTRY_PATH.parent))
    try:
      with os.fdopen(fd, "w", encoding="utf-8") as handle:
        json.dump(registry, handle, indent=2, sort_keys=True)
        handle.write("\n")
      os.replace(tmp_name, REGISTRY_PATH)
    finally:
      if os.path.exists(tmp_name):
        os.remove(tmp_name)


def git_common_root(source_path: str) -> str:
    common_dir = run_git(
        ["rev-parse", "--path-format=absolute", "--git-common-dir"],
        cwd=source_path,
    )
    common_path = Path(common_dir)
    if common_path.name == ".git":
        return str(common_path.parent)
    return run_git(["rev-parse", "--show-toplevel"], cwd=source_path)


def repo_name(repo_root: str) -> str:
    return Path(repo_root).name


def validate_branch(branch: str) -> None:
    try:
        run(["git", "check-ref-format", "--branch", branch], capture=True, check=True)
    except FlowError as exc:
        raise FlowError(f"flow: invalid branch name '{branch}'") from exc


def worktree_root() -> Path:
    return Path.home() / "worktrees"


def worktree_path(repo_root: str, branch: str) -> Path:
    return worktree_root() / repo_name(repo_root) / branch


def local_branch_exists(repo_root: str, branch: str) -> bool:
    try:
        run_git(["show-ref", "--verify", "--quiet", f"refs/heads/{branch}"], cwd=repo_root, capture=True, check=True)
        return True
    except FlowError:
        return False


def parse_worktree_branches(repo_root: str) -> list[tuple[str, str]]:
    output = run_git(["worktree", "list", "--porcelain"], cwd=repo_root)
    rows: list[tuple[str, str]] = []
    current_path = ""
    for line in output.splitlines():
        if line.startswith("worktree "):
            current_path = line[len("worktree ") :].strip()
        elif line.startswith("branch refs/heads/"):
            branch = line[len("branch refs/heads/") :].strip()
            if current_path and branch:
                rows.append((branch, current_path))
    return rows


def window_alive(window_id: str) -> bool:
    if not window_id.strip():
        return False
    try:
        output = run_tmux(["list-windows", "-a", "-F", "#{window_id}"])
    except FlowError:
        return False
    return window_id.strip() in [line.strip() for line in output.splitlines() if line.strip()]


def session_alive(session_target: str) -> bool:
    if not session_target.strip():
        return False
    try:
        run_tmux(["has-session", "-t", session_target], capture=True, check=True)
        return True
    except FlowError:
        return False


def pane_ids(window_id: str) -> list[str]:
    output = run_tmux(["list-panes", "-t", window_id, "-F", "#{pane_id}"])
    return [line.strip() for line in output.splitlines() if line.strip()]


def pane_alive(pane_id: str) -> bool:
    if not pane_id.strip():
        return False
    try:
        output = run_tmux(["list-panes", "-a", "-F", "#{pane_id}"])
    except FlowError:
        return False
    return pane_id.strip() in [line.strip() for line in output.splitlines() if line.strip()]


def current_tmux_value(fmt: str, target: str | None = None) -> str:
    args = ["display-message", "-p"]
    if target and target.strip():
        args.extend(["-t", target.strip()])
    args.append(fmt)
    try:
        return run_tmux(args)
    except FlowError:
        return ""


def current_window_id(explicit: str | None = None) -> str:
    if explicit and explicit.strip():
        return explicit.strip()
    value = current_tmux_value("#{window_id}")
    if value:
        return value
    raise FlowError("flow: unable to determine tmux window; run inside tmux")


def current_session_id(explicit: str | None = None) -> str:
    if explicit and explicit.strip():
        return explicit.strip()
    value = current_tmux_value("#{session_id}")
    if value:
        return value
    raise FlowError("flow: run inside tmux or pass a session target")


def current_session_name(target: str) -> str:
    return current_tmux_value("#{session_name}", target)


def window_option_get(window_id: str, option: str) -> str:
    try:
        return run_tmux(["show-options", "-wqv", "-t", window_id, option])
    except FlowError:
        return ""


def window_option_set(window_id: str, option: str, value: str) -> None:
    run_tmux(["set-option", "-wq", "-t", window_id, option, value], capture=True, check=True)


def pane_option_set(pane_id: str, option: str, value: str) -> None:
    run_tmux(["set-option", "-pq", "-t", pane_id, option, value], capture=True, check=True)


def session_and_name_for_window(window_id: str) -> tuple[str, str]:
    session_id = current_tmux_value("#{session_id}", window_id)
    session_name = current_tmux_value("#{session_name}", window_id)
    return session_id, session_name


def can_attach_tmux() -> bool:
    return os.environ.get("TMUX", "").strip() == "" and sys.stdin.isatty()


def attach_or_select(window_id: str, pane_id: str | None = None) -> None:
    if os.environ.get("TMUX", "").strip():
        run_tmux(["select-window", "-t", window_id], capture=True, check=True)
        if pane_id:
            run_tmux(["select-pane", "-t", pane_id], capture=True, check=True)
        return
    session_id, _ = session_and_name_for_window(window_id)
    if not session_id:
        return
    run_tmux(["select-window", "-t", window_id], capture=True, check=False)
    if can_attach_tmux():
        run_tmux(["attach-session", "-t", session_id], capture=False, check=True)


def start_shell_in_pane(pane_id: str, cwd: str) -> None:
    run_tmux(["respawn-pane", "-k", "-t", pane_id, "-c", cwd, SHELL_COMMAND], capture=True, check=True)


def split_shell(target_pane: str, cwd: str, direction: str) -> str:
    args = ["split-window", "-d", "-P", "-F", "#{pane_id}", "-t", target_pane, "-c", cwd]
    if direction == "right":
        args.extend(["-h", "-p", str(LAYOUT_RIGHT_PERCENT)])
    elif direction == "down":
        args.extend(["-v", "-p", str(LAYOUT_BOTTOM_PERCENT)])
    else:
        raise FlowError(f"flow: unknown split direction {direction}")
    args.append(SHELL_COMMAND)
    return run_tmux(args)


def send_start_commands(ai_pane: str, git_pane: str) -> None:
    run_tmux(
        [
            "send-keys",
            "-t",
            ai_pane,
            "-l",
            'if command -v op >/dev/null 2>&1; then op; else echo "flow: op unavailable"; fi',
        ],
        capture=True,
        check=True,
    )
    run_tmux(["send-keys", "-t", ai_pane, "Enter"], capture=True, check=True)
    run_tmux(
        [
            "send-keys",
            "-t",
            git_pane,
            "-l",
            'if command -v lazygit >/dev/null 2>&1; then lazygit; else echo "flow: lazygit unavailable"; fi',
        ],
        capture=True,
        check=True,
    )
    run_tmux(["send-keys", "-t", git_pane, "Enter"], capture=True, check=True)


def write_tmux_metadata(window_id: str, entry: dict) -> None:
    window_option_set(window_id, "@flow_branch", entry["branch"])
    window_option_set(window_id, "@flow_worktree", entry["worktree_path"])
    window_option_set(window_id, "@flow_repo_root", entry["repo_root"])
    window_option_set(window_id, "@flow_repo_name", entry["repo_name"])
    window_option_set(window_id, "@flow_role", "feature")
    window_option_set(window_id, "@flow_registry_key", entry["key"])


def rebuild_window_layout(window_id: str, entry: dict) -> dict:
    panes = pane_ids(window_id)
    if not panes:
        raise FlowError(f"flow: no panes found in {window_id}")
    base = panes[0]
    for pane in panes[1:]:
        run_tmux(["kill-pane", "-t", pane], capture=True, check=True)
    start_shell_in_pane(base, entry["worktree_path"])
    git_pane = split_shell(base, entry["worktree_path"], "right")
    run_pane = split_shell(git_pane, entry["worktree_path"], "down")
    run_tmux(["set-window-option", "-t", window_id, "automatic-rename", "off"], capture=True, check=True)
    run_tmux(["set-window-option", "-t", window_id, "allow-rename", "off"], capture=True, check=True)
    run_tmux(["rename-window", "-t", window_id, entry["branch"]], capture=True, check=True)
    write_tmux_metadata(window_id, entry)
    pane_option_set(base, "@flow_pane_role", "ai")
    pane_option_set(git_pane, "@flow_pane_role", "git")
    pane_option_set(run_pane, "@flow_pane_role", "run")
    run_tmux(["select-window", "-t", window_id], capture=True, check=False)
    run_tmux(["select-pane", "-t", base], capture=True, check=False)
    send_start_commands(base, git_pane)
    entry["pane_ai"] = base
    entry["pane_git"] = git_pane
    entry["pane_run"] = run_pane
    entry["updated_at"] = now_iso()
    return entry


def create_window_layout(session_id: str, entry: dict) -> dict:
    window_id = run_tmux(
        [
            "new-window",
            "-d",
            "-P",
            "-F",
            "#{window_id}",
            "-t",
            f"{session_id}:",
            "-n",
            entry["branch"],
            "-c",
            entry["worktree_path"],
            SHELL_COMMAND,
        ]
    )
    entry["tmux_window_id"] = window_id
    entry["tmux_session_id"], entry["tmux_session_name"] = session_and_name_for_window(window_id)
    return rebuild_window_layout(window_id, entry)


def ensure_worktree(repo_root: str, branch: str, target_path: Path) -> None:
    rows = parse_worktree_branches(repo_root)
    target = str(target_path)
    for existing_branch, existing_path in rows:
        if existing_branch == branch and existing_path != target:
            raise FlowError(f"flow: branch '{branch}' is already attached at '{existing_path}'")
    if target_path.exists():
        current_branch = run_git(["branch", "--show-current"], cwd=target)
        if current_branch.strip() != branch:
            raise FlowError(f"flow: '{target}' is on branch '{current_branch}'")
        return
    target_path.parent.mkdir(parents=True, exist_ok=True)
    if local_branch_exists(repo_root, branch):
        run_git(["worktree", "add", target, branch], cwd=repo_root, capture=True, check=True)
    else:
        run_git(["worktree", "add", target, "-b", branch], cwd=repo_root, capture=True, check=True)


def current_repo_root_or_none(source_path: str | None = None) -> str:
    source = source_path or os.getcwd()
    try:
        return git_common_root(source)
    except FlowError:
        return ""


def find_entry_by_window(registry: dict, window_id: str) -> dict | None:
    target = window_id.strip()
    if not target:
        return None
    for entry in registry.get("workflows", {}).values():
        if entry.get("tmux_window_id", "").strip() == target:
            return entry
    return None


def find_entry_by_repo_branch(registry: dict, repo_root: str, branch: str) -> dict | None:
    return registry.get("workflows", {}).get(registry_key(repo_root, branch))


def find_current_entry(registry: dict, explicit_window_id: str | None = None) -> dict:
    window_id = current_window_id(explicit_window_id)
    window_entry = find_entry_by_window(registry, window_id)
    if window_entry:
        return window_entry
    branch = window_option_get(window_id, "@flow_branch")
    repo_root = window_option_get(window_id, "@flow_repo_root")
    if branch and repo_root:
        entry = find_entry_by_repo_branch(registry, repo_root, branch)
        if entry:
            return entry
    raise FlowError("flow: current tmux window is not a managed workflow")


def workflow_status(entry: dict) -> str:
    worktree = entry.get("worktree_path", "").strip()
    window_id = entry.get("tmux_window_id", "").strip()
    if not worktree or not Path(worktree).exists():
        return "orphan"
    if window_id and window_alive(window_id):
        return "running"
    return "stopped"


def count_open_todos(window_id: str) -> int:
    path = Path.home() / ".cache" / "agent" / "todos.json"
    if not path.exists():
        return 0
    data = json.loads(path.read_text())
    windows = data.get("windows", {})
    items = windows.get(window_id, [])
    if not isinstance(items, list):
        return 0
    return sum(1 for item in items if not item.get("done"))


def worktree_dirty(worktree_path_value: str) -> bool:
    if not worktree_path_value.strip() or not Path(worktree_path_value).exists():
        return False
    output = run_git(["status", "--porcelain"], cwd=worktree_path_value)
    return bool(output.strip())


def build_entry(repo_root: str, branch: str) -> dict:
    target = worktree_path(repo_root, branch)
    return {
        "key": registry_key(repo_root, branch),
        "repo_root": repo_root,
        "repo_name": repo_name(repo_root),
        "branch": branch,
        "worktree_path": str(target),
        "tmux_session_id": "",
        "tmux_session_name": "",
        "tmux_window_id": "",
        "pane_ai": "",
        "pane_git": "",
        "pane_run": "",
        "created_at": now_iso(),
        "updated_at": now_iso(),
    }


def window_metadata_snapshot(window_id: str) -> dict:
    return {
        "branch": window_option_get(window_id, "@flow_branch").strip(),
        "repo_root": window_option_get(window_id, "@flow_repo_root").strip(),
        "worktree_path": window_option_get(window_id, "@flow_worktree").strip(),
    }


def doctor_issue(code: str, detail: str) -> dict:
    return {"code": code, "detail": detail}


def doctor_suggested_fix(entry: dict, issue_codes: list[str]) -> str:
    branch = entry.get("branch", "").strip()
    window_id = entry.get("tmux_window_id", "").strip()
    if "missing-worktree" in issue_codes and branch and (not window_id or "missing-window" in issue_codes):
        return f'flow destroy "{branch}"'
    if any(
        code in issue_codes
        for code in ("missing-window", "missing-pane-ai", "missing-pane-git", "missing-pane-run", "window-metadata-mismatch")
    ) and branch:
        return f'flow resume "{branch}"'
    if "missing-session" in issue_codes:
        return "resume from the target tmux session"
    if "missing-worktree" in issue_codes:
        return "restore worktree manually"
    if "dirty-worktree" in issue_codes:
        return "review changes manually"
    return "-"


def analyze_workflow_entry(entry: dict) -> dict:
    repo_root = entry.get("repo_root", "").strip()
    repo_name_value = entry.get("repo_name", "").strip() or repo_name(repo_root) if repo_root else "-"
    branch = entry.get("branch", "").strip() or "-"
    worktree_value = entry.get("worktree_path", "").strip()
    window_id = entry.get("tmux_window_id", "").strip()
    issues: list[dict] = []
    status = workflow_status(entry)
    window_is_alive = bool(window_id) and window_alive(window_id)
    worktree_exists = bool(worktree_value) and Path(worktree_value).exists()

    if not worktree_exists:
        issues.append(doctor_issue("missing-worktree", f"worktree missing: {worktree_value or '-'}"))

    if window_id and not window_is_alive:
        issues.append(doctor_issue("missing-window", f"tmux window missing: {window_id}"))

    session_id = entry.get("tmux_session_id", "").strip()
    session_name = entry.get("tmux_session_name", "").strip()
    if not window_is_alive and (session_id or session_name):
        session_ok = False
        if session_id and session_alive(session_id):
            session_ok = True
        if session_name and session_alive(session_name):
            session_ok = True
        if not session_ok:
            issues.append(doctor_issue("missing-session", "stored tmux session is unavailable for resume"))

    if window_is_alive:
        for pane_key, issue_code, detail in (
            ("pane_ai", "missing-pane-ai", "AI pane missing"),
            ("pane_git", "missing-pane-git", "Git pane missing"),
            ("pane_run", "missing-pane-run", "Run pane missing"),
        ):
            pane_id = entry.get(pane_key, "").strip()
            if pane_id and not pane_alive(pane_id):
                issues.append(doctor_issue(issue_code, f"{detail}: {pane_id}"))

        metadata = window_metadata_snapshot(window_id)
        if any(
            (
                metadata.get("branch", "") and metadata.get("branch", "") != branch,
                metadata.get("repo_root", "") and metadata.get("repo_root", "") != repo_root,
                metadata.get("worktree_path", "") and metadata.get("worktree_path", "") != worktree_value,
            )
        ):
            issues.append(doctor_issue("window-metadata-mismatch", "live tmux window metadata differs from registry"))

    if worktree_exists and worktree_dirty(worktree_value):
        issues.append(doctor_issue("dirty-worktree", "worktree has uncommitted changes"))

    issue_codes = [item["code"] for item in issues]
    health = "ok" if not issues else "warn"
    return {
        "repo": repo_name_value or "-",
        "repo_root": repo_root,
        "branch": branch,
        "status": status,
        "health": health,
        "issues": issues,
        "issue_codes": issue_codes,
        "suggested_fix": doctor_suggested_fix(entry, issue_codes),
        "entry": entry,
    }


def gc_candidates(entries: list[dict]) -> list[dict]:
    candidates: list[dict] = []
    for entry in entries:
        worktree_value = entry.get("worktree_path", "").strip()
        window_id = entry.get("tmux_window_id", "").strip()
        worktree_exists = bool(worktree_value) and Path(worktree_value).exists()
        window_is_alive = bool(window_id) and window_alive(window_id)
        if not worktree_exists and not window_is_alive:
            candidates.append(entry)
    return candidates


def record_entry(registry: dict, entry: dict) -> None:
    registry.setdefault("workflows", {})[entry["key"]] = entry


def remove_entry(registry: dict, entry: dict) -> None:
    registry.setdefault("workflows", {}).pop(entry["key"], None)


def session_target_for_resume(entry: dict) -> str:
    stored_session_id = entry.get("tmux_session_id", "").strip()
    stored_session_name = entry.get("tmux_session_name", "").strip()
    if stored_session_id and session_alive(stored_session_id):
        return stored_session_id
    if stored_session_name and session_alive(stored_session_name):
        return stored_session_name
    current_session = current_tmux_value("#{session_id}")
    if current_session:
        return current_session
    raise FlowError("flow: target tmux session is unavailable; resume from inside tmux")


def schedule_internal(command: list[str]) -> None:
    run_tmux(["run-shell", "-b", shell_join([sys.executable, str(Path(__file__)), *command])], capture=True, check=True)


def cmd_start(args: argparse.Namespace) -> int:
    branch = args.branch.strip()
    validate_branch(branch)
    repo_root = git_common_root(os.getcwd())
    session_id = current_session_id()
    registry = load_registry()
    entry = find_entry_by_repo_branch(registry, repo_root, branch)
    if entry is None:
        entry = build_entry(repo_root, branch)
    ensure_worktree(repo_root, branch, Path(entry["worktree_path"]))
    if entry.get("tmux_window_id") and window_alive(entry["tmux_window_id"]):
        attach_or_select(entry["tmux_window_id"], entry.get("pane_ai") or None)
        entry["updated_at"] = now_iso()
        record_entry(registry, entry)
        save_registry(registry)
        print(f"flow: switched to '{branch}'")
        return 0
    entry = create_window_layout(session_id, entry)
    record_entry(registry, entry)
    save_registry(registry)
    attach_or_select(entry["tmux_window_id"], entry.get("pane_ai") or None)
    print(f"flow: ready at {entry['worktree_path']}")
    return 0


def cmd_list(args: argparse.Namespace) -> int:
    registry = load_registry()
    workflows = list(registry.get("workflows", {}).values())
    repo_scope = ""
    if not args.all:
        repo_scope = current_repo_root_or_none()
        if not repo_scope:
            raise FlowError("flow: not in a git repo; use 'flow list --all'")
        workflows = [entry for entry in workflows if entry.get("repo_root") == repo_scope]
    workflows.sort(key=lambda entry: (entry.get("repo_name", ""), entry.get("branch", "")))
    if not workflows:
        print("No workflows found.")
        return 0
    headers = ["BRANCH", "STATUS", "SESSION", "WINDOW", "WORKTREE"]
    rows: list[list[str]] = []
    if args.all:
        headers.insert(0, "REPO")
    for entry in workflows:
        status = workflow_status(entry)
        row = [
            entry.get("branch", ""),
            status,
            entry.get("tmux_session_name") or entry.get("tmux_session_id") or "-",
            entry.get("tmux_window_id") or "-",
            entry.get("worktree_path") or "-",
        ]
        if args.all:
            row.insert(0, entry.get("repo_name", "-"))
        rows.append(row)
    widths = [len(header) for header in headers]
    for row in rows:
        for index, value in enumerate(row):
            widths[index] = max(widths[index], len(value))
    print("  ".join(header.ljust(widths[index]) for index, header in enumerate(headers)))
    for row in rows:
        print("  ".join(value.ljust(widths[index]) for index, value in enumerate(row)))
    return 0


def scoped_workflows(registry: dict, all_repos: bool) -> list[dict]:
    workflows = list(registry.get("workflows", {}).values())
    if all_repos:
        return workflows
    repo_scope = current_repo_root_or_none()
    if not repo_scope:
        raise FlowError("flow: not in a git repo; use '--all'")
    return [entry for entry in workflows if entry.get("repo_root") == repo_scope]


def print_table(headers: list[str], rows: list[list[str]]) -> None:
    widths = [len(header) for header in headers]
    for row in rows:
        for index, value in enumerate(row):
            widths[index] = max(widths[index], len(value))
    print("  ".join(header.ljust(widths[index]) for index, header in enumerate(headers)))
    for row in rows:
        print("  ".join(value.ljust(widths[index]) for index, value in enumerate(row)))


def cmd_doctor(args: argparse.Namespace) -> int:
    registry = load_registry()
    workflows = scoped_workflows(registry, args.all)
    if not workflows:
        print("No workflows found.")
        return 0
    analyses = [analyze_workflow_entry(entry) for entry in workflows]
    analyses.sort(key=lambda item: (item["repo"], item["branch"]))
    if args.json:
        payload = [
            {
                "repo": item["repo"],
                "repo_root": item["repo_root"],
                "branch": item["branch"],
                "status": item["status"],
                "health": item["health"],
                "issue_codes": item["issue_codes"],
                "issues": item["issues"],
                "suggested_fix": item["suggested_fix"],
            }
            for item in analyses
        ]
        print(json.dumps(payload, indent=2, sort_keys=True))
    else:
        headers = ["BRANCH", "STATUS", "HEALTH", "ISSUES", "SUGGESTED"]
        if args.all:
            headers.insert(0, "REPO")
        rows: list[list[str]] = []
        for item in analyses:
            issue_text = ",".join(item["issue_codes"]) if item["issue_codes"] else "-"
            row = [item["branch"], item["status"], item["health"], issue_text, item["suggested_fix"]]
            if args.all:
                row.insert(0, item["repo"])
            rows.append(row)
        print_table(headers, rows)
        issue_count = sum(1 for item in analyses if item["issue_codes"])
        print(f"\nSummary: {len(analyses)} workflows, {issue_count} with issues.")
    return 1 if any(item["issue_codes"] for item in analyses) else 0


def cmd_gc(args: argparse.Namespace) -> int:
    registry = load_registry()
    workflows = scoped_workflows(registry, args.all)
    candidates = gc_candidates(workflows)
    if not candidates:
        print("flow: no stale workflow registry entries to clean")
        return 0
    rows = [
        [
            entry.get("repo_name", "-"),
            entry.get("branch", "-"),
            entry.get("tmux_window_id", "-") or "-",
            entry.get("worktree_path", "-") or "-",
        ]
        for entry in sorted(candidates, key=lambda item: (item.get("repo_name", ""), item.get("branch", "")))
    ]
    print_table(["REPO", "BRANCH", "WINDOW", "WORKTREE"], rows)
    if not args.apply:
        print(f"\nflow: dry-run only; rerun with --apply to remove {len(candidates)} stale entr{'y' if len(candidates) == 1 else 'ies'}")
        return 0
    for entry in candidates:
        remove_entry(registry, entry)
    save_registry(registry)
    print(f"\nflow: removed {len(candidates)} stale entr{'y' if len(candidates) == 1 else 'ies'} from registry")
    return 0


def cmd_resume(args: argparse.Namespace) -> int:
    branch = args.branch.strip()
    repo_root = current_repo_root_or_none()
    if not repo_root:
        raise FlowError("flow: run 'flow resume' inside the target repo")
    registry = load_registry()
    entry = find_entry_by_repo_branch(registry, repo_root, branch)
    if entry is None:
        raise FlowError(f"flow: unknown workflow '{branch}'")
    if workflow_status(entry) == "orphan":
        raise FlowError(f"flow: worktree missing for '{branch}'")
    if entry.get("tmux_window_id") and window_alive(entry["tmux_window_id"]):
        entry["updated_at"] = now_iso()
        record_entry(registry, entry)
        save_registry(registry)
        attach_or_select(entry["tmux_window_id"], entry.get("pane_ai") or None)
        print(f"flow: resumed '{branch}'")
        return 0
    session_target = session_target_for_resume(entry)
    entry = create_window_layout(session_target, entry)
    record_entry(registry, entry)
    save_registry(registry)
    attach_or_select(entry["tmux_window_id"], entry.get("pane_ai") or None)
    print(f"flow: rebuilt '{branch}'")
    return 0


def destroy_entry(registry: dict, entry: dict) -> None:
    window_id = entry.get("tmux_window_id", "").strip()
    worktree_value = entry.get("worktree_path", "").strip()
    repo_root = entry.get("repo_root", "").strip()
    branch = entry.get("branch", "").strip()
    if window_id and window_alive(window_id):
        run_tmux(["kill-window", "-t", window_id], capture=True, check=False)
        time.sleep(0.2)
    if worktree_value and Path(worktree_value).exists():
        run_git(["worktree", "remove", worktree_value], cwd=repo_root, capture=True, check=True)
    if branch and local_branch_exists(repo_root, branch):
        run_git(["branch", "-D", branch], cwd=repo_root, capture=True, check=True)
    remove_entry(registry, entry)
    save_registry(registry)


def cmd_destroy(args: argparse.Namespace) -> int:
    registry = load_registry()
    entry: dict
    if args.branch:
        repo_root = current_repo_root_or_none()
        if not repo_root:
            raise FlowError("flow: run 'flow destroy <branch>' inside the target repo")
        entry = find_entry_by_repo_branch(registry, repo_root, args.branch.strip())
        if entry is None:
            raise FlowError(f"flow: unknown workflow '{args.branch.strip()}'")
    else:
        entry = find_current_entry(registry, args.window_id)
    if worktree_dirty(entry["worktree_path"]):
        raise FlowError("flow: worktree has uncommitted changes")
    open_todos = count_open_todos(entry.get("tmux_window_id", ""))
    if open_todos > 0:
        label = "todos" if open_todos != 1 else "todo"
        raise FlowError(f"flow: refusing to destroy workflow with {open_todos} open {label}")
    current_window = current_tmux_value("#{window_id}")
    if current_window and current_window == entry.get("tmux_window_id", ""):
        schedule_internal(["__destroy-cleanup", entry["key"]])
        print(f"flow: scheduled destroy for '{entry['branch']}'")
        return 0
    destroy_entry(registry, entry)
    print(f"flow: destroyed '{entry['branch']}'")
    return 0


def cmd_destroy_cleanup(args: argparse.Namespace) -> int:
    registry = load_registry()
    entry = registry.get("workflows", {}).get(args.key)
    if entry is None:
        raise FlowError(f"flow: unknown workflow key '{args.key}'")
    destroy_entry(registry, entry)
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="flow")
    subparsers = parser.add_subparsers(dest="command", required=True)

    start = subparsers.add_parser("start")
    start.add_argument("branch")
    start.set_defaults(func=cmd_start)

    list_parser = subparsers.add_parser("list")
    list_parser.add_argument("--all", action="store_true")
    list_parser.set_defaults(func=cmd_list)

    doctor = subparsers.add_parser("doctor")
    doctor.add_argument("--all", action="store_true")
    doctor.add_argument("--json", action="store_true")
    doctor.set_defaults(func=cmd_doctor)

    gc = subparsers.add_parser("gc")
    gc.add_argument("--all", action="store_true")
    gc.add_argument("--apply", action="store_true")
    gc.set_defaults(func=cmd_gc)

    resume = subparsers.add_parser("resume")
    resume.add_argument("branch")
    resume.set_defaults(func=cmd_resume)

    destroy = subparsers.add_parser("destroy")
    destroy.add_argument("branch", nargs="?")
    destroy.add_argument("--window-id", dest="window_id", default="")
    destroy.set_defaults(func=cmd_destroy)

    internal_destroy = subparsers.add_parser("__destroy-cleanup")
    internal_destroy.add_argument("key")
    internal_destroy.set_defaults(func=cmd_destroy_cleanup)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    try:
        return int(args.func(args))
    except FlowError as exc:
        print_stderr(str(exc))
        return 1


if __name__ == "__main__":
    sys.exit(main())
