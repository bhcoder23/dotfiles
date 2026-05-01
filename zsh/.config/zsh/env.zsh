export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export LOCALBIN="${XDG_CONFIG_HOME}/bin"
export LOCALPROG="$HOME/prog"
export GOPATH="${GOPATH:-$HOME/go}"
export EDITOR=nvim
export TERM_ITALICS=true
export ZSH_AUTOSUGGEST_USE_ASYNC=1
export ZSH_AUTOSUGGEST_MANUAL_REBIND=1
export HOMEBREW_DOWNLOAD_CONCURRENCY=auto

export PATH="$HOME/.local/bin:$PATH"
export PATH="$PATH:$LOCALBIN"
export PATH="$PATH:/Applications/Xcode.app/Contents/Developer/usr/bin/"
export PATH="$PATH:/usr/local/bin"
export PATH="$PATH:$HOME/go/bin"
export PATH="$PATH:/opt/homebrew/bin"
export PATH="$PATH:/opt/homebrew/sbin"
export PATH="$PATH:$HOME/.cargo/bin"
export PATH="$PATH:/opt/homebrew/opt/llvm/bin"
export PATH="$PATH:$HOME/Library/Python/3.9/bin"
export PATH="$PATH:$LOCALPROG/bin"
export PATH="$PATH:$HOME/.pub-cache/bin"
export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"

if [[ -d "$HOME/fvm/default/bin" ]]; then
  export PATH="$HOME/fvm/default/bin:$PATH"
fi

if [[ -d "$LOCALPROG/flutter/bin" ]]; then
  export PATH="$PATH:$LOCALPROG/flutter/bin:$LOCALPROG/flutter/bin/cache/dart-sdk/bin"
fi
export FLUTTER_ROOT="$LOCALPROG/flutter"

export PYENV_ROOT="$HOME/tools/pyenv"
if [[ -d $PYENV_ROOT/bin ]]; then
  export PATH="$PYENV_ROOT/bin:$PATH"
fi
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init - zsh --no-rehash)"
fi

export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  . "$NVM_DIR/nvm.sh"
fi

export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/sqlite/lib"
export CPPFLAGS="-I/opt/homebrew/opt/sqlite/include"
export PATH="/opt/homebrew/opt/sqlite/bin:$PATH"
export PKG_CONFIG_PATH="/opt/homebrew/opt/sqlite/lib/pkgconfig"
export PATH="$PATH:/usr/local/mysql/bin"
export PATH="/opt/homebrew/opt/openldap/bin:$PATH"
export PATH="/opt/homebrew/opt/openldap/sbin:$PATH"
export PATH="/opt/homebrew/opt/mysql-client@8.4/bin:$PATH"

if command -v mysql_config >/dev/null 2>&1; then
  export MYSQLCLIENT_CFLAGS="$(mysql_config --cflags)"
  export MYSQLCLIENT_LDFLAGS="$(mysql_config --libs)"
fi

export SCALA_HOME=/Library/Scala/scala-2.12.12
export PATH="$PATH:$SCALA_HOME/bin"

export MAVEN_HOME="$HOME/tools/maven-3.9.9"
export PATH="$PATH:$MAVEN_HOME/bin"

if /usr/libexec/java_home -v 17 >/dev/null 2>&1; then
  export JAVA_HOME="$("/usr/libexec/java_home" -v 17)"
  export PATH="$PATH:$JAVA_HOME/bin"
fi

export LUA_PATH="/usr/local/openresty/lualib/?.lua;;"

if [[ -f "$HOME/.local/bin/env" ]]; then
  . "$HOME/.local/bin/env"
fi

if [[ -f "$HOME/.cargo/env" ]]; then
  . "$HOME/.cargo/env"
fi
export PATH="$HOME/.local/bin:$PATH"

if command -v brew >/dev/null 2>&1; then
  export DYLD_FALLBACK_LIBRARY_PATH="$(brew --prefix)/lib:$DYLD_FALLBACK_LIBRARY_PATH"
fi

if [[ -d "$HOME/Github/mac-ctrl/bin" ]] && [[ ":$PATH:" != *":$HOME/Github/mac-ctrl/bin:"* ]]; then
  export PATH="$HOME/Github/mac-ctrl/bin:$PATH"
fi

alias emacs='open -a Emacs'

# rs-raap
# export KUBECONFIG=~/tools/k8s/rs/cls-mhb6ig5a-config
# a2-raap
export KUBECONFIG=~/tools/k8s/a2/cls-196cs1y0-config

# ks-dev
# export KUBECONFIG=~/tools/k8s/ks/dev-cls-3zn6c2wh-config

# ks-pre
# export KUBECONFIG=~/tools/k8s/ks/cls-qseynenn-config
