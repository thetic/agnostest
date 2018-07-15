# vim:filetype=zsh
#
# thetic's Theme
# An agnoster-inspired, Powerline-inspired theme for ZSH
# Requires a nerd-font patched font: https://nerdfonts.com/
# Optimized for gruvbox theme: https://github.com/morhetz/gruvbox-contrib/

# Remove space after right prompt
ZLE_RPROMPT_INDENT=0

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

LEFT_CURRENT_BG='NONE'
RIGHT_CURRENT_BG='NONE'
DEFAULT_USER=$(whoami)

# Special Powerline characters
() {
    local LC_ALL="" LC_CTYPE="en_US.UTF-8"
    LEFT_SEGMENT_SEPARATOR=$'\ue0b0'  # 
    LEFT_SUB_SEPARATOR=$'\ue0b1'      # 
    RIGHT_SEGMENT_SEPARATOR=$'\ue0b2' # 
    RIGHT_SUB_SEPARATOR=$'\ue0b3'     # 
}

# Begin a segment
# Takes two arguments, background and foreground.
prompt_segment() {
    if [[ $SIDE == right ]]; then
        if [[ $1 != $RIGHT_CURRENT_BG ]]; then
            echo -n " %{%K{$RIGHT_CURRENT_BG}%F{$1}%}$RIGHT_SEGMENT_SEPARATOR%{%K{$1}%F{$2}%} "
        else
            echo -n "%{%K{$1}%}%{%F{$2}%} $RIGHT_SUB_SEPARATOR "
        fi
        RIGHT_CURRENT_BG=$1
    else
        if [[ $LEFT_CURRENT_BG == 'NONE' ]]; then
            echo -n "%{%K{$1}%}%{%F{$2}%} "
        elif [[ $1 != $LEFT_CURRENT_BG ]]; then
            echo -n " %{%K{$1}%F{$LEFT_CURRENT_BG}%}$LEFT_SEGMENT_SEPARATOR%{%F{$2}%} "
        else
            echo -n "%{%K{$1}%}%{%F{$2}%} $LEFT_SUB_SEPARATOR "
        fi
        LEFT_CURRENT_BG=$1
    fi
    [[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
prompt_end() {
    if [[ $SIDE == left ]]; then
        if [[ -n $LEFT_CURRENT_BG ]]; then
            echo -n " %{%k%F{$LEFT_CURRENT_BG}%}$LEFT_SEGMENT_SEPARATOR"
        else
            echo -n "%{%k%}"
        fi
        echo -n "%{%f%}"
        LEFT_CURRENT_BG=''
    elif [[ $SIDE == right ]]; then
        echo -n " %{%k%}"
    fi
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
    if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
        prompt_segment 109 black "%(!.%{%K{red}%}.)$USER@%m"
    fi
}

# Git: branch/detached head, dirty status
prompt_git() {
    (( $+commands[git] )) || return


    if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
        local repo_path=$(git rev-parse --git-dir 2>/dev/null)
        local dirty=$(parse_git_dirty)
        local ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git rev-parse --short HEAD 2> /dev/null)"

        local git_bg
        if [[ -n $dirty ]]; then
            git_bg=yellow
        else
            git_bg=green
        fi

        local git_sym merge_sym rebase_sym bisect_sym
        () {
            local LC_ALL="" LC_CTYPE="en_US.UTF-8"
            git_sym=$'\ue725'       # 
            bisect_sym=$'\ue729'    # 
            merge_sym=$'\ue727'     # 
            rebase_sym=$'\ue728'    # 
        }
        if [[ -e "${repo_path}/BISECT_LOG" ]]; then
            git_sym=$bisect_sym
        elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
            git_sym=$merge_sym
        elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
            git_sym=$rebase_sym
        fi

        setopt promptsubst
        autoload -Uz vcs_info

        zstyle ':vcs_info:*' enable git
        zstyle ':vcs_info:*' get-revision      true
        zstyle ':vcs_info:*' check-for-changes true
        zstyle ':vcs_info:*' stagedstr     '✚'
        zstyle ':vcs_info:*' unstagedstr   '●'
        zstyle ':vcs_info:*' formats       ' %u%c'
        zstyle ':vcs_info:*' actionformats ' %u%c'
        vcs_info
        prompt_segment $git_bg black "${ref/refs\/heads\//$git_sym }${vcs_info_msg_0_%% }"
    fi
}

# Dir: current working directory
prompt_dir() {
    prompt_segment white black '%~'
}

# Virtualenv: current working virtualenv
prompt_virtualenv() {
    local virtualenv_path="$VIRTUAL_ENV"
    if [[ -n $virtualenv_path && -n $VIRTUAL_ENV_DISABLE_PROMPT ]]; then
        prompt_segment blue black " $(basename $virtualenv_path)"
    fi
}

# Jobs: the number of background jobs
prompt_jobs() {
    local jobs=$(jobs -l | wc -l)
    if [[ $jobs -gt 0 ]]; then
        prompt_segment magenta black "⚙ $jobs" # orange
    fi
}

# Return value: return code of the previous command
prompt_retval() {
    [[ $RETVAL -ne 0 ]] && prompt_segment red black "$RETVAL"
}

# Vim mode: requires https://github.com/softmoth/zsh-vim-mode
prompt_vimode() {
    case "$VIM_MODE_KEYMAP" in
        "viins")    prompt_segment 109     black "I" ;;
        "main")     prompt_segment 109     black "I" ;;
        "vicmd")    prompt_segment white   black "N" ;;
        "isearch")  prompt_segment magenta black "S" ;;
        "replace")  prompt_segment 108     black "R";;
        "visual")   prompt_segment 208     black "V" ;;
        "vline")    prompt_segment 208     black "V" ;;
    esac
}

## Main prompt
right_prompt() {
    SIDE=left

    prompt_context
    prompt_dir
    prompt_vimode
    prompt_end
}

## Right prompt
build_rprompt() {
    RETVAL=$?
    SIDE=right

    prompt_retval
    prompt_jobs
    prompt_git
    prompt_virtualenv
    prompt_end
}

## Build continuation prompt
build_prompt2() {
    SIDE=left
    prompt_segment white black '%_'
    prompt_vimode
    prompt_end
}

PROMPT='%{%f%b%k%}$(right_prompt) '
RPROMPT='%{%f%b%k%}$(build_rprompt)'
PROMPT2='%{%f%b%k%}$(build_prompt2) '
