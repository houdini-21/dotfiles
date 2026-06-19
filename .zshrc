# --- OPCIONES DE ZSH ---
# Historial de comandos
HISTFILE=~/.zsh_history
HISTSIZE=5000
SAVEHIST=5000
setopt SHARE_HISTORY      # Comparte historial entre terminales abiertas
setopt HIST_IGNORE_DUPS   # No guardes comandos duplicados

# Auto-completado avanzado
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select # Permite seleccionar con flechas

# --- PLUGINS (Si los instalaste por pacman) ---
#[[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
#source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
source /usr/share/zsh/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh

#bindkey '^[[A' history-substring-search-up
#bindkey '^[[B' history-substring-search-down

alias ls='eza --group-directories-first'
alias ll='eza -lh --group-directories-first'
alias la='eza -a --group-directories-first'
alias lt='eza --tree' # Ver carpetas como árbol
alias gcl='git clone'
alias gpu='git push'
alias gpl='git pull'
alias ga='git add'
alias gcsm="git commit -m"
alias fetch='fastfetch --logo-type kitty --logo ~/Images/terminal.jpg --structure Title:Separator:OS:Kernel:Uptime:Packages:WM:CPU:GPU:Memory --logo-width 35 --logo-height 15'

# --- STARSHIP ---
eval "$(starship init zsh)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


fastfetch
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export JAVA_HOME=/usr/lib/jvm/java-26-openjdk


# pnpm
export PNPM_HOME="/home/houdini/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end
