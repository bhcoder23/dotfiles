#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script="$script_dir/switch_session_by_index.sh"
tmpdir="$(mktemp -d)"
log="$tmpdir/tmux.log"
trap 'rm -rf "$tmpdir"' EXIT

cat > "$tmpdir/tmux" <<'FAKE_TMUX'
#!/usr/bin/env bash
set -euo pipefail

case "$1" in
  list-sessions)
    printf '$2\t2-beta\t200\n$1\t1-alpha\t100\n$3\t3-gamma\t300\n'
    ;;
  switch-client)
    printf '%s\n' "$*" >> "$TMUX_FAKE_LOG"
    ;;
  *)
    printf 'unexpected tmux command: %s\n' "$*" >&2
    exit 1
    ;;
esac
FAKE_TMUX
chmod +x "$tmpdir/tmux"

PATH="$tmpdir:$PATH" TMUX_FAKE_LOG="$log" "$script" 2 /dev/ttys000
grep -Fx 'switch-client -c /dev/ttys000 -t $2' "$log" >/dev/null

: > "$log"
PATH="$tmpdir:$PATH" TMUX_FAKE_LOG="$log" "$script" 3
grep -Fx 'switch-client -t $3' "$log" >/dev/null

: > "$log"
PATH="$tmpdir:$PATH" TMUX_FAKE_LOG="$log" "$script" 9 /dev/ttys000
[[ ! -s "$log" ]]
