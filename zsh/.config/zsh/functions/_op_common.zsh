_op_run() {
  local tag="$1"
  shift

  local -a opencode_cmd
  opencode_cmd=(opencode "$@")

  local base_home="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
  local base_config="$base_home/opencode.json"

  setopt local_options null_glob

  local runtime_root="${XDG_CACHE_HOME:-$HOME/.cache}/opencode-runtime"
  local runtime_scope=""
  if [ -n "${TMUX_PANE:-}" ]; then
    runtime_scope="pane_${TMUX_PANE//[^A-Za-z0-9_]/_}"
  else
    local cwd_hash=""
    if command -v shasum >/dev/null 2>&1; then
      cwd_hash=$(print -nr -- "$PWD" | shasum -a 1 | awk '{print $1}')
    else
      cwd_hash=$(print -nr -- "$PWD" | cksum | awk '{print $1}')
    fi
    runtime_scope="cwd_${cwd_hash}"
  fi

  local tmp_home="${runtime_root}/${tag}_${runtime_scope}"
  if ! mkdir -p "$tmp_home"; then
    print -u2 "$tag: failed to create runtime dir $tmp_home"
    return 1
  fi
  if [ "${OPENCODE_RUNTIME_DEBUG:-0}" = "1" ]; then
    print -u2 "$tag: using runtime OPENCODE_CONFIG_DIR at $tmp_home"
  fi

  sync_optional_file() {
    local src="$1"
    local dest="${2:-$1}"
    local target_dir="$tmp_home"

    if [ "${dest:h}" != "$dest" ]; then
      target_dir="$tmp_home/${dest:h}"
      mkdir -p "$target_dir" || return 1
    fi

    if [ ! -f "$base_home/$src" ]; then
      rm -f "$tmp_home/$dest"
      return 0
    fi

    cp "$base_home/$src" "$tmp_home/$dest" >/dev/null 2>&1
  }

  sync_optional_tree() {
    local name="$1"

    rm -rf "$tmp_home/$name"
    if [ ! -d "$base_home/$name" ]; then
      return 0
    fi

    mkdir -p "$tmp_home/$name" || return 1
    cp -R "$base_home/$name/." "$tmp_home/$name/" >/dev/null 2>&1
  }

  if [ -f "$base_config" ]; then
    if ! cp "$base_config" "$tmp_home/opencode.json" >/dev/null 2>&1; then
      print -u2 "$tag: failed to copy $base_config"
      return 1
    fi
  else
    rm -f "$tmp_home/opencode.json"
  fi

  local base_agents="$base_home/AGENTS.md"
  if [ "$tag" = "se" ]; then
    local search_agents="$base_home/agent/search/AGENTS.md"
    if [ -f "$search_agents" ]; then
      base_agents="$search_agents"
    fi
  fi

  if [ -f "$base_agents" ]; then
    if ! cp "$base_agents" "$tmp_home/AGENTS.md" >/dev/null 2>&1; then
      print -u2 "$tag: failed to copy $base_agents"
      return 1
    fi
  else
    rm -f "$tmp_home/AGENTS.md"
  fi

  local optional_file
  for optional_file in package.json package-lock.json consult.json tui.json .gitignore; do
    if ! sync_optional_file "$optional_file"; then
      print -u2 "$tag: failed to copy $base_home/$optional_file"
      return 1
    fi
  done

  local -a to_link=(
    history
    sessions
    logs
    skill
  )

  local name
  for name in "${to_link[@]}"; do
    if [ -e "$base_home/$name" ]; then
      rm -rf "$tmp_home/$name"
      if ! ln -s "$base_home/$name" "$tmp_home/$name" 2>/dev/null; then
        print -u2 "$tag: failed to symlink $base_home/$name"
        return 1
      fi
    fi
  done

  if [ -d "$base_home/node_modules" ]; then
    rm -rf "$tmp_home/node_modules"
    if ! ln -s "$base_home/node_modules" "$tmp_home/node_modules" 2>/dev/null; then
      print -u2 "$tag: failed to symlink $base_home/node_modules"
      return 1
    fi
  fi

  rm -rf "$tmp_home/plugins"
  mkdir -p "$tmp_home/plugins"
  local plugin_file
  for plugin_file in "$base_home/plugins"/* "$base_home/tui-plugins"/*; do
    [ -e "$plugin_file" ] || continue
    cp -f "$plugin_file" "$tmp_home/plugins/" >/dev/null 2>&1 || return 1
  done

  local optional_tree
  for optional_tree in agents tool tools; do
    if ! sync_optional_tree "$optional_tree"; then
      print -u2 "$tag: failed to copy $base_home/$optional_tree"
      return 1
    fi
  done

  rm -rf "$tmp_home/command"
  if ! mkdir -p "$tmp_home/command"; then
    print -u2 "$tag: failed to create $tmp_home/command"
    return 1
  fi

  if [ -d "$base_home/command" ]; then
    local command_file
    for command_file in "$base_home/command"/*.md; do
      [ -f "$command_file" ] || continue
      cp "$command_file" "$tmp_home/command/"
    done
  fi

  local project_prompts_dir=""
  if [ -d "$PWD/.agent-prompts" ]; then
    project_prompts_dir="$PWD/.agent-prompts"
  fi

  if [ -n "$project_prompts_dir" ]; then
    local copied_any=0
    local prompt_file
    for prompt_file in "$project_prompts_dir"/*.md; do
      [ -f "$prompt_file" ] || continue
      copied_any=1
      local filename="${prompt_file:t}"
      if ! cp -f "$prompt_file" "$tmp_home/command/prompt_$filename" >/dev/null 2>&1; then
        print -u2 "$tag: failed to copy project prompt $prompt_file"
        return 1
      fi
    done
    if (( copied_any )); then
      print -u2 "$tag: added project prompts from $project_prompts_dir to commands"
    fi
  fi

  OPENCODE_CONFIG_DIR="$tmp_home" \
    OP_TRACKER_NOTIFY="${OP_TRACKER_NOTIFY:-0}" \
    RIPGREP_CONFIG_PATH="${RIPGREP_CONFIG_PATH:-$HOME/.ripgreprc}" \
    "${opencode_cmd[@]}"
  local exit_code=$?

  return $exit_code
}
