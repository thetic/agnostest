# thetic's Theme
# An agnoster-inspired, Powerline-inspired theme for ZSH
# Requires a nerd-font patched font: https://nerdfonts.com/
# Optimized for gruvbox theme: https://github.com/morhetz/gruvbox-contrib/

export VIRTUAL_ENV_DISABLE_PROMPT=1

setopt promptsubst
autoload -Uz vcs_info

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'
RIGHT_CURRENT_BG=''

# Special Powerline characters
() {
    local LC_ALL="" LC_CTYPE="en_US.UTF-8"
    SEGMENT_SEPARATOR=$'\ue0b0'  # 
    SUB_SEPARATOR=$'\ue0b1'      # 
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
            echo -n "%{%K{$1}%F{$2}%} $RIGHT_SUB_SEPARATOR "
        fi
        RIGHT_CURRENT_BG=$1
    else
        if [[ $CURRENT_BG == 'NONE' ]]; then
            echo -n "%{%K{$1}%F{$2}%} "
        elif [[ $1 != $CURRENT_BG ]]; then
            echo -n " %{%K{$1}%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{%F{$2}%} "
        else
            echo -n "%{%K{$1}%F{$2}%} $SUB_SEPARATOR "
        fi
        CURRENT_BG=$1
    fi
    [[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
prompt_end() {
    if [[ $SIDE == right ]]; then
        echo -n " %{%f%k%}"
    else
        if [[ -n $CURRENT_BG ]]; then
            echo -n " %{%k%F{$CURRENT_BG}%}${SEGMENT_SEPARATOR}"
        else
            echo -n "%{%k%}"
        fi
        echo -n "%{%f%}"
        CURRENT_BG=''
    fi
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
    if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
        prompt_segment 208 235 "%(!.%{%K{124}%}.)$USER@%m" # orange
    fi
}

# Git: branch/detached head, dirty status
prompt_git() {
    (( $+commands[git] )) || return

    if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
        local git_bg=214 # yellow
        if $(git diff --exit-code --quiet --ignore-submodules); then
            git_bg=142 # green
        fi

        local git_sym
        () {
            local LC_ALL="" LC_CTYPE="en_US.UTF-8"
            git_sym=$'\ue0a0' # 
        }

        zstyle ':vcs_info:*' enable git
        zstyle ':vcs_info:*' get-revision      true
        zstyle ':vcs_info:*' check-for-changes true
        zstyle ':vcs_info:*' stagedstr   '✚'
        zstyle ':vcs_info:*' unstagedstr '●'
        zstyle ':vcs_info:*' formats       '%b %u%c'
        zstyle ':vcs_info:*' actionformats '%b %u%c'
        vcs_info
        prompt_segment $git_bg 235 "${git_sym} ${vcs_info_msg_0_}"
    fi
}

# Dir: current working directory
prompt_dir() {
    local cwd="${${${${PWD/$HOME/~}%\~}#/}%/*}"
    if [[ -n $cwd ]]; then
        local dir_separator=$SUB_SEPARATOR
        if [[ $SIDE == right ]]; then
            dir_separator=$RIGHT_SUB_SEPARATOR
        fi
        prompt_segment 239 246 "${cwd//\// $dir_separator }" # dark gray
    fi
    prompt_segment 246 235 '%c'
}

# Virtualenv: current working virtualenv
prompt_virtualenv() {
    local virtualenv_path="$VIRTUAL_ENV"
    local virtualenv_sym
    () {
        local LC_ALL="" LC_CTYPE="en_US.UTF-8"
        virtualenv_sym=$'\uf81f' # 
    }
    if [[ -n $virtualenv_path && -n $VIRTUAL_ENV_DISABLE_PROMPT ]]; then
        prompt_segment 108 235 "$virtualenv_sym $(basename $virtualenv_path)" # aqua
    fi
}

# Jobs: the number of background jobs
prompt_jobs() {
    local jobs=$(jobs -l | wc -l)
    local jobs_sym
    () {
        local LC_ALL="" LC_CTYPE="en_US.UTF-8"
        jobs_sym=$'\u2699' # ⚙
    }
    if [[ $jobs -gt 0 ]]; then
        prompt_segment 132 235 "$jobs_sym $jobs" # purple
    fi
}

# Return value: return code of the previous command
prompt_retval() {
    [[ $RETVAL -ne 0 ]] && prompt_segment 124 235 "$RETVAL" # red
}

# Vim mode: requires https://github.com/softmoth/zsh-vim-mode
prompt_vimode() {
    case $VIM_MODE_KEYMAP in
        vicmd)        prompt_segment 246 235 "N" ;; # gray
        isearch)      prompt_segment 214 235 "S" ;; # yellow
        replace)      prompt_segment 108 235 "R" ;; # aqua
        visual|vline) prompt_segment 208 235 "V" ;; # orange
        viins|main)   prompt_segment 109 235 "I" ;; # orange
    esac
}

# Parser status
prompt_continuation() {
    if [[ $SIDE == right ]]; then
        prompt_segment 246 235 '%_' # gray
    else
        prompt_segment 246 235 '%^' # gray
    fi
}

## Main prompt
build_prompt() {
    prompt_vimode
    prompt_context
    prompt_dir
    prompt_end
}

## Right prompt
build_rprompt() {
    RETVAL=$?
    SIDE=right

    prompt_retval
    prompt_jobs
    prompt_virtualenv
    prompt_git
    prompt_end
}

## Build continuation prompt
build_prompt2() {
    prompt_vimode
    prompt_continuation
    prompt_end
}

build_rprompt2() {
    SIDE=right
    prompt_end
}

PROMPT='%{%f%b%k%}$(build_prompt) '
RPROMPT='%{%f%b%k%}$(build_rprompt)'
PROMPT2='%{%f%b%k%}$(build_prompt2) '
RPROMPT2='%{%f%b%k%}$(build_rprompt2) '
