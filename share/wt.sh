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

  # Find the subcommand (first arg that isn't the global --strict flag). `wt run`
  # and `wt run-hook` forward a command/hook's stdout, which could itself look
  # like a path, so we never treat their output as a directory to cd into.
  local sub
  for sub in "$@"; do
    [[ "$sub" == "--strict" ]] && continue
    break
  done

  local output
  output=$(command wt "$@")
  local exit_code=$?

  # Relocate whenever wt printed an existing directory, regardless of exit code:
  # `wt rm`/`done` of the current worktree print the main path and may still exit
  # non-zero (e.g. a strict post-remove hook failed), and we must not leave the
  # shell sitting in the now-deleted worktree.
  if [[ "$sub" != "run" && "$sub" != "run-hook" && -d "$output" ]]; then
    cd "$output" || return 1
  elif [[ -n "$output" ]]; then
    echo "$output"
  fi

  return $exit_code
}
