ZIM_HOME="${ZIM_HOME:-${ZDOTDIR:-${HOME}}/.zim}"

if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
  if (( $+commands[curl] )); then
    curl -fsSL --create-dirs -o "${ZIM_HOME}/zimfw.zsh" \
      https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  elif (( $+commands[wget] )); then
    mkdir -p "${ZIM_HOME}" && wget -nv -O "${ZIM_HOME}/zimfw.zsh" \
      https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  else
    print -u2 "plugins: missing curl/wget, unable to bootstrap zimfw"
  fi
fi

if [[ -r ${ZIM_HOME}/zimfw.zsh ]] && [[ ! -r ${ZIM_HOME}/init.zsh || ! ${ZIM_HOME}/init.zsh -nt ${ZDOTDIR:-${HOME}}/.zimrc ]]; then
  source "${ZIM_HOME}/zimfw.zsh" init
fi

if [[ -r ${ZIM_HOME}/init.zsh ]]; then
  source "${ZIM_HOME}/init.zsh"
fi
