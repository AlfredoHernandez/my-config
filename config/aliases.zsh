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
alias grh='git reset --soft HEAD~1'

# Squash merges make merged branches look unmerged to `git branch --merged`, so this deletes the
# local branches whose remote branch is gone, as GitHub deletes it when the PR is merged.
# Branches checked out here or in another worktree have a worktree path, so they are kept.
# The unalias drops the old cleanup alias, which would win over this function on a re-source.
unalias cleanup 2>/dev/null
function cleanup {
    git fetch --prune --quiet || return
    local gone
    gone=$(git for-each-ref --format='%(refname:short) %(upstream:track) %(worktreepath)' refs/heads |
        awk '$2 == "[gone]" && NF == 2 {print $1}')
    if [[ -z $gone ]]; then
        echo "No local branches whose remote branch was deleted"
        return 0
    fi

    echo "Local branches whose remote branch was deleted:"
    print -r -- "$gone" | sed 's/^/  /'
    local reply
    read -r "reply?Delete them? [y/N] "
    [[ $reply == [yY]* ]] || return 0
    git branch -D -- ${(f)gone}
}

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
