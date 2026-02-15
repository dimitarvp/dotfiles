git_current_branch() {
  git rev-parse --abbrev-ref HEAD
}

git_root() {
  git rev-parse --show-toplevel
}

git_current_dir() {
  realpath -m --relative-to $(git_root) .
}

git_changed() {
  git diff --name-only
  git ls-files --others --exclude-standard
}

