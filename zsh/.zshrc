export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

zsh_config_dir="${XDG_CONFIG_HOME}/zsh"

source "${zsh_config_dir}/env.zsh"
source "${zsh_config_dir}/aliases.zsh"
source "${zsh_config_dir}/plugins.zsh"
source "${zsh_config_dir}/vi.zsh"
source "${zsh_config_dir}/fzf.zsh"
source "${zsh_config_dir}/completion.zsh"
source "${zsh_config_dir}/mappings.zsh"

if [[ -f "$HOME/.sconfig/zsh/zshrc" ]]; then
  source "$HOME/.sconfig/zsh/zshrc"
fi

if typeset -f autopair-init >/dev/null 2>&1; then
  autopair-init
fi

source "${zsh_config_dir}/prompt.zsh"
source "${zsh_config_dir}/tmux.zsh"

for zsh_function in ${zsh_config_dir}/functions/*.zsh(N); do
  source "$zsh_function"
done

unset zsh_function
unset zsh_config_dir
