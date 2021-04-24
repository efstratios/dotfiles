# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

declare -r __col_lgrey='\e[38;5;247m'
declare -r __ps1_col_red='\[\e[38;5;197m\]'
declare -r __ps1_col_green='\[\e[38;5;70m\]'
declare -r __ps1_col_lgreen='\[\e[38;5;46m\]'
declare -r __ps1_col_lgrey="\[$__col_lgrey\]"
# declare -r __ps1_col_cyan='\[\e[38;5;81m\]'
declare -r __ps1_col_reset='\[\e[m\]'

# append to the history file, don't overwrite it
shopt -s histappend

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=10000
HISTFILESIZE=25000
# don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoreboth:erasedups

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# helper for PS1 that prints the current virtualenv, if any
__ps_venv() {
	if [[ -n $VIRTUAL_ENV ]]; then
		printf "(%s) " "$(basename "$VIRTUAL_ENV")"
	fi
}

# helper for PS1 that prints the current dir's git info, if any
__ps_git() {
	local mark local remote behind ahead
	git for-each-ref --format="%(HEAD) %(refname:short) %(upstream:short) %(objectname:short)" refs/heads 2>/dev/null | \
		grep -m1 '^\*' | while IFS=' ' read -r mark local remote sha1
		do
			printf "%s (%s)" "$sha1" "$local"
			if ! git diff-index --quiet HEAD --; then
				printf "*"
			fi

			[[ -z $remote ]] && continue
			git rev-list --count --left-right "${remote}..${local}" -- | \
				while read -r behind ahead; do
					if [[ $behind -ne 0 ]]; then
						printf " ▾%d" "$behind"
					fi
					if [[ $ahead -ne 0 ]]; then
						printf " ▴%d" "$ahead"
					fi
				done
		done
}

__ps_time() {
	# shellcheck disable=SC2183
	printf '%(%H:%M)T'
}

__ps_widgets_array=( \
	__ps_time \
	__ps_git \
)

__ps_exit_code() {
	printf '^%d' "$__EXIT_CODE"
}

__ps_widgets_show() {
	for w in "${__ps_widgets_array[@]}"; do
		printf " "
		$w
	done
}

__ps_opt_hostname() {
	if [[ -n $SSH_CLIENT ]] || [[ -n $SSH_TTY ]]; then
		printf "%s " "$HOSTNAME"
	fi
}

PS1="\\n${__ps1_col_lgrey}\${debian_chroot:+(\$debian_chroot)}\\w${__ps1_col_reset}${__ps1_col_lgreen}\$(__ps_widgets_show)${__ps1_col_reset}\n\$(__ps_venv)${__ps1_col_lgreen}\$(__ps_opt_hostname)\\\$${__ps1_col_reset} "


# Title changing functionality {{{
case "$TERM" in
	xterm*|rxvt*)
		term_change_title() {
			echo -ne "\033]0;${1}\007"
		}
		;;
	screen*)
		term_change_title() {
			printf '\ek%s\e\\' "$1"
		}
		;;
	*)
		term_change_title() {
			:
		}
esac

# __short_path PATH
__short_path() {
	local path=$1

	if [[ "${#path}" -lt 12 ]]; then
		echo "$path"
		return
	fi

	local components=
	IFS='/' read -r -a components <<< "$path"

	for ((i=0; i<${#components[@]}; i++)); do
		local component="${components[$i]}"

		if [[ $i -eq 0 && ${component} = "" ]]; then
			continue
		fi

		if [[ $i -ne 0 ]]; then
			echo -n '/'
		fi

		if (($i >= ${#components[@]} - 2)); then
			echo -n "${component}"
		else
			echo -n "${component:0:1}"
		fi
	done

	echo
}

__change_title_postexec() {
	local unexpanded_pwd="${PWD}"
	unexpanded_pwd="${unexpanded_pwd/#${HOME}\/src/@}"
	unexpanded_pwd="${unexpanded_pwd/#${HOME}/\~}"

	term_change_title "\$ $(__short_path "${unexpanded_pwd}")"
}

PROMPT_COMMAND="__change_title_postexec; $PROMPT_COMMAND"

__change_title_preexec() {
    if [ -n "$COMP_LINE" ]; then
		# This happened during during autocompletion
		return
	fi

    if [ "$BASH_COMMAND" = "$PROMPT_COMMAND" ]; then
		return
	fi

    local exe=$(HISTTIMEFORMAT= history 1 | awk '{ print $2 }')
	term_change_title "$exe"

	if [[ "$exe" = "fg" ]]; then
		exe=$(jobs -s | tail -n1 | awk '{ print $3 }') || return
		term_change_title "$exe"
	fi
}

trap '__change_title_preexec "$_"' DEBUG

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ls='ls --group-directories-first --color=auto'
alias ll='ls -alF --group-directories-first --color=auto'
alias la='ls -A --group-directories-first --color=auto'
alias l='ls -CF --group-directories-first --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias grepip='grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b"' # Grep out a list of IPs from unstructured data with this alias.
alias cat='cat -v'

# my aliases 
alias g='git'
alias pwd_gen='< /dev/urandom tr -cd "[:print:]" | head -c 32; echo'
alias ud='sudo apt update; sudo apt upgrade -y'
alias cln='sudo apt autoremove -y;sudo apt autoclean'
alias log_off='sudo pkill -KILL -u "$USER"'
alias nse='ls /usr/share/nmap/scripts | grep'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

LS_COLORS=$LS_COLORS:'di=1;38;5;247' ; export LS_COLORS
