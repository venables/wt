# shellcheck shell=bash
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

  # Every command prints at most a worktree path to stdout. Capture the status
  # via `|| exit_code=$?` so the relocation still runs under `set -e` (a bare
  # `output=$(...)` would abort the function on failure).
  local output exit_code=0
  output=$(command wt "$@") || exit_code=$?

  # Relocate whenever wt printed an existing directory, regardless of exit code:
  # `wt rm`/`done` of the current worktree print the main path and may still exit
  # non-zero, and we must not leave the shell sitting in the now-deleted worktree.
  if [[ -d "$output" ]]; then
    cd "$output" || return 1
  elif [[ -n "$output" ]]; then
    echo "$output"
  fi

  return $exit_code
}
