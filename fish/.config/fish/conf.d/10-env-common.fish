# Shared environment that is safe to keep in dotfiles.

if test -d /opt/homebrew/bin
    fish_add_path --move --path /opt/homebrew/bin
end

if test -d /opt/homebrew/sbin
    fish_add_path --move --path /opt/homebrew/sbin
end

if test -d /usr/local/bin
    fish_add_path --append --path /usr/local/bin
end

if test -d /usr/local/sbin
    fish_add_path --append --path /usr/local/sbin
end

if test -f "$HOME/.local/bin/env.fish"
    source "$HOME/.local/bin/env.fish"
end

set -gx EDITOR nvim
set -gx VISUAL nvim

if test -d "$HOME/.local/bin"
    fish_add_path --path "$HOME/.local/bin"
end

if test -d "$HOME/.cargo/bin"
    fish_add_path --path "$HOME/.cargo/bin"
end

set -gx PYENV_ROOT "$HOME/tools/pyenv"
if test -d "$PYENV_ROOT/bin"
    fish_add_path --path "$PYENV_ROOT/bin"
end

if command -q pyenv
    pyenv init --no-rehash - fish | source
end

if command -q fnm
    # Keep Node, Corepack, and pnpm on one fish-native path.
    set -gx FNM_COREPACK_ENABLED true
    set -gx FNM_VERSION_FILE_STRATEGY recursive

    fnm env --use-on-cd --shell fish | source

    if test -f .node-version
        or test -f .nvmrc
        or test -f package.json
        fnm use --install-if-missing --silent-if-unchanged >/dev/null 2>&1
    else
        set -l active_node ""
        if command -q node
            set active_node (command -v node)
        end

        if not string match -q "$FNM_MULTISHELL_PATH/bin/*" "$active_node"
            fnm use default --install-if-missing --silent-if-unchanged >/dev/null 2>&1
        end
    end

    if command -q corepack
        if not command -q pnpm
            corepack enable >/dev/null 2>&1
        end
    end
end

if test -d /opt/homebrew/opt/postgresql@16/bin
    fish_add_path --path /opt/homebrew/opt/postgresql@16/bin
end

if test -d /opt/homebrew/opt/sqlite/bin
    fish_add_path --path /opt/homebrew/opt/sqlite/bin
    set -gx LDFLAGS "-L/opt/homebrew/opt/sqlite/lib"
    set -gx CPPFLAGS "-I/opt/homebrew/opt/sqlite/include"
    set -gx PKG_CONFIG_PATH "/opt/homebrew/opt/sqlite/lib/pkgconfig"
end

if command -q mysql_config
    set -gx MYSQLCLIENT_CFLAGS (mysql_config --cflags)
    set -gx MYSQLCLIENT_LDFLAGS (mysql_config --libs)
end

if test -d /opt/homebrew/opt/openldap/bin
    fish_add_path --path /opt/homebrew/opt/openldap/bin
end

if test -d /opt/homebrew/opt/openldap/sbin
    fish_add_path --path /opt/homebrew/opt/openldap/sbin
end

if test -d /opt/homebrew/opt/mysql-client@8.4/bin
    fish_add_path --path /opt/homebrew/opt/mysql-client@8.4/bin
end

if test -d /usr/local/mysql/bin
    fish_add_path --append --path /usr/local/mysql/bin
end

set -l detected_java_home (/usr/libexec/java_home -v 17 2>/dev/null)
if test -n "$detected_java_home"
    set -gx JAVA_HOME "$detected_java_home"
    if test -d "$JAVA_HOME/bin"
        fish_add_path --append --path "$JAVA_HOME/bin"
    end
end

if test -d "$HOME/go/bin"
    fish_add_path --move --path "$HOME/go/bin"
end

if test -d /usr/local/openresty/lualib
    set -gx LUA_PATH "/usr/local/openresty/lualib/?.lua;;"
end

if command -q brew
    set -l brew_prefix (brew --prefix)
    if set -q DYLD_FALLBACK_LIBRARY_PATH
        set -gx DYLD_FALLBACK_LIBRARY_PATH "$brew_prefix/lib:$DYLD_FALLBACK_LIBRARY_PATH"
    else
        set -gx DYLD_FALLBACK_LIBRARY_PATH "$brew_prefix/lib"
    end
end
