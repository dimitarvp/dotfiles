git_default_branch() {
    (git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@') 2>/dev/null
}

git_current_branch() {
    git rev-parse --abbrev-ref HEAD
}
