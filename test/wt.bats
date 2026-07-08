#!/usr/bin/env bats
#
# Behavioral tests for bin/wt. The scratch repo lives under a path that contains
# a space so any regression in worktree-path parsing fails loudly here.

setup() {
  WT="${BATS_TEST_DIRNAME}/../bin/wt"
  # Physical path (git canonicalizes worktree paths, e.g. macOS /var ->
  # /private/var), so expected values match what wt prints.
  local base
  base="$(mktemp -d "${BATS_TMPDIR:-/tmp}/wt spaces.XXXXXX")"
  TMP="$(cd "$base" && pwd -P)"
  REPO="$TMP/repo"
  # Isolate from any real hooks in ~/.config/wt/hooks.
  export WT_HOOKS_DIR="$TMP/no-hooks"

  # Isolate from the user's global git config (signing, hooks, aliases) so the
  # setup commit works regardless of commit.gpgsign etc.
  export GIT_CONFIG_GLOBAL="$TMP/gitconfig"
  export GIT_CONFIG_SYSTEM=/dev/null
  : >"$GIT_CONFIG_GLOBAL"

  mkdir -p "$REPO"
  cd "$REPO"
  git init -q -b main
  git -c user.email=t@t.co -c user.name=t commit -q --allow-empty -m init
}

teardown() {
  rm -rf "$TMP"
}

# Run wt capturing stdout only (wt writes messages to stderr, the path to stdout).
wtout() { "$WT" "$@" 2>/dev/null; }

add_worktree() { # <branch> <path>
  git worktree add -q -b "$1" "$2"
}

@test "back returns the main worktree path under a spaced parent" {
  add_worktree feat "$TMP/repo-feat"
  cd "$TMP/repo-feat"
  run wtout back
  [ "$status" -eq 0 ]
  [ "$output" = "$REPO" ]
}

@test "list emits both worktrees with a spaced path intact" {
  add_worktree feat "$TMP/repo-feat"
  run "$WT" ls
  [ "$status" -eq 0 ]
  [[ "$output" == *"$REPO"* ]]
  [[ "$output" == *"$TMP/repo-feat"* ]]
}

@test "enter resolves a branch name" {
  add_worktree feat "$TMP/repo-feat"
  run wtout enter feat
  [ "$status" -eq 0 ]
  [ "$output" = "$TMP/repo-feat" ]
}

@test "a subdirectory argument resolves to its worktree root" {
  add_worktree feat "$TMP/repo-feat"
  mkdir -p "$TMP/repo-feat/pkg/sub"
  run wtout enter "$TMP/repo-feat/pkg/sub"
  [ "$status" -eq 0 ]
  [ "$output" = "$TMP/repo-feat" ]
}

@test "a branch name wins over a same-named directory in the cwd" {
  add_worktree docs "$TMP/repo-docs"
  mkdir -p "$REPO/docs"
  cd "$REPO"
  run wtout enter docs
  [ "$status" -eq 0 ]
  [ "$output" = "$TMP/repo-docs" ]
}

@test "a branch literally named (detached) resolves to its own worktree" {
  git worktree add -q --detach "$TMP/repo-det"
  add_worktree '(detached)' "$TMP/repo-paren"
  run wtout enter '(detached)'
  [ "$status" -eq 0 ]
  [ "$output" = "$TMP/repo-paren" ]
}

@test "a directory outside every worktree is rejected" {
  mkdir -p "$TMP/outside"
  run "$WT" rm "$TMP/outside"
  [ "$status" -ne 0 ]
}

@test "rm of the current worktree returns the main path" {
  add_worktree feat "$TMP/repo-feat"
  cd "$TMP/repo-feat"
  run wtout rm feat
  [ "$status" -eq 0 ]
  [ "$output" = "$REPO" ]
}

@test "--strict is not stripped from a run payload" {
  add_worktree feat "$TMP/repo-feat"
  run wtout run feat -- printf '%s\n' --strict
  [ "$status" -eq 0 ]
  [ "$output" = "--strict" ]
}

@test "--strict survives a run payload even without the -- separator" {
  add_worktree feat "$TMP/repo-feat"
  run wtout run feat printf '%s\n' --strict
  [ "$status" -eq 0 ]
  [ "$output" = "--strict" ]
}

@test "an unknown top-level option is rejected" {
  run "$WT" --frob
  [ "$status" -ne 0 ]
  [[ "$output" == *"unknown option"* ]]
}

@test "create rejects an unknown option" {
  run "$WT" create --no-hok somebranch
  [ "$status" -ne 0 ]
}

@test "create rejects a stray second positional" {
  run "$WT" create somebranch extra-arg
  [ "$status" -ne 0 ]
}
