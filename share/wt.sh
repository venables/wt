# wt shell wrapper - source this file to enable auto-cd after worktree creation
# Add to your .bashrc or .zshrc:
#   source "$(brew --prefix)/share/wt/wt.sh"

wt() {
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
