eval "$(/opt/homebrew/bin/brew shellenv)"

# Setting PATH for Python 3.12
# The original version is saved in .zprofile.pysave
PATH="/Library/Frameworks/Python.framework/Versions/3.12/bin:${PATH}"
export PATH

ZIM_HOME=${ZIM_HOME:-${ZDOTDIR:-${HOME}}/.zim}
if [[ -r ${ZIM_HOME}/login_init.zsh ]]; then
  source ${ZIM_HOME}/login_init.zsh
fi
