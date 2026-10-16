# Git aliases
alias gl='git pull'
alias gd='git diff'
alias gp='git push'
alias gst='git status'
alias ga='git add .'
alias gc='git commit'
alias gca='git commit --amend --no-edit'
alias glog='git log'
alias gcp='git cherry-pick'
alias cleanup='git branch --merged | grep -Ev "(^\*|master|main|develop)" | xargs git branch -d'
alias grh='git reset --soft HEAD~1'

# Xcode aliases
alias spm='xcodebuild -resolvePackageDependencies -scmProvider system'

# ls improvements with eza
alias ls='eza --grid --color auto --icons --sort=type'
alias ll='eza --long --color always --icons --sort=type'
alias la='eza --grid --all --color auto --icons --sort=type'
alias lla='eza --long --all --color auto --icons --sort=type'


# Claude Code: cl = default (quality)


alias cl='CLAUDE_CODE_SUBAGENT_MODEL=sonnet claude \
    --model opus \
    --effort high \
    --advisor opus \
    --fallback-model sonnet'

# clx = hard work
# architecture / big refactors/ hard bugs
alias clx='CLAUDE_CODE_SUBAGENT_MODEL=opus claude --model opus --effort xhigh --advisor opus'

# clq = quick/cheap
# quick questions, read Slack/docs, explore
alias clq='CLAUDE_CODE_SUBAGENT_MODEL=haiku claude --model sonnet --effort medium'

# Custom scripts
alias dl="~/Developer/bin/deeplink.sh"
