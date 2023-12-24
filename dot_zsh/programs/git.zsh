git_default_branch() {
    (git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@') 2>/dev/null
}

git_current_branch() {
    git rev-parse --abbrev-ref HEAD
}

git_root() {
  git rev-parse --show-toplevel
}

git_current_dir() {
  realpath -m --relative-to $(git_root) .
}
