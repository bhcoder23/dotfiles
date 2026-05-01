set -g fish_greeting

if status is-interactive
    if command -q starship
        starship init fish | source
    end

    if command -q fzf
        fzf --fish | source
    end
end
