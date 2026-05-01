# Centralized shell helpers.

function y --description "Open yazi and jump to the last visited directory"
    set -l tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"

    if test -f "$tmp"
        set -l cwd (command cat -- "$tmp")
        if test -n "$cwd"
            if test "$cwd" != "$PWD"
                builtin cd -- "$cwd"
            end
        end
    end

    command rm -f -- "$tmp"
end

function nh --description "Run a command under nohup in the background"
    command nohup $argv >/dev/null 2>&1 &
end

function d --description "Print a compact timestamp"
    date "+%m-%d %A %T"
end

function ch --description "Query cheat.sh"
    if test (count $argv) -lt 1
        echo "usage: ch <topic>"
        return 1
    end

    command curl -fsSL "cheat.sh/$argv[1]"
end

alias v="nvim"
alias t="task"
alias 7z="7zz"
alias bt="btop"
alias we="open -a WeChat"
alias cl="open -a ClashX"

abbr --add -- yd "y ~/Downloads"
abbr --add -- yt "y ~/Desktop"
abbr --add -- yr "y ~/repo"

abbr --add -- tc "task calendar"
abbr --add -- ta "task add"
abbr --add -- tb "task burndown.weekly"
abbr --add -- tm "task modify"
abbr --add -- ts "task summary"

abbr --add -- gs "git status"
abbr --add -- gd "git difftool -y"
abbr --add -- ga "git add -A"
abbr --add -- gc --set-cursor 'git commit -m "%"'
abbr --add -- gp "git push"
abbr --add -- gl "git log"
