# wt shell wrapper - source this file to enable auto-cd after worktree creation
# Add to your .bashrc or .zshrc:
#   source "$(brew --prefix)/share/wt/wt.sh"

wt() {
  # Recover from a deleted cwd. If another tab removed the worktree this shell
  # is sitting in (e.g. via `wt done`), getcwd() fails and git, bash, and mise
  # all error out. Walk up to the nearest existing ancestor and cd there first
  # so the command below runs from a valid directory.
  if [[ ! -d "$PWD" ]]; then
    local dir=$PWD
    while [[ -n "$dir" && ! -d "$dir" ]]; do
      dir=${dir%/*}
    done
    cd "${dir:-/}" 2>/dev/null || cd "$HOME" || return 1
  fi

  local output
  output=$(command wt "$@")
  local exit_code=$?

  if [[ $exit_code -eq 0 && -d "$output" ]]; then
    cd "$output"
  else
    [[ -n "$output" ]] && echo "$output"
  fi

  return $exit_code
}
