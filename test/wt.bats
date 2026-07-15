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
  export WT_HOOKS_DIR="$TMP/hooks"

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

install_hook() { # <script-body>
  mkdir -p "$WT_HOOKS_DIR"
  { echo '#!/usr/bin/env bash'; echo "$1"; } >"$WT_HOOKS_DIR/post-create"
  chmod +x "$WT_HOOKS_DIR/post-create"
}

@test "the bare shorthand creates a worktree at the guessed path" {
  run wtout feat
  [ "$status" -eq 0 ]
  [ "$output" = "$TMP/repo-feat" ]
  [ -d "$TMP/repo-feat" ]
}

@test "creating an already-checked-out branch enters its worktree" {
  add_worktree feat "$TMP/repo-feat"
  run wtout feat
  [ "$status" -eq 0 ]
  [ "$output" = "$TMP/repo-feat" ]
}

@test "a slash in the branch name is slugified in the path" {
  run wtout feature/login
  [ "$status" -eq 0 ]
  [ "$output" = "$TMP/repo-feature-login" ]
}

@test "create runs the post-create hook with env vars" {
  install_hook 'echo "$WT_BRANCH:$WT_REPO_NAME" > "$WT_PATH/.hookran"'
  run wtout feat
  [ "$status" -eq 0 ]
  [ -f "$TMP/repo-feat/.hookran" ]
  [ "$(cat "$TMP/repo-feat/.hookran")" = "feat:repo" ]
}

@test "--no-hook skips the post-create hook" {
  install_hook 'touch "$WT_PATH/.hookran"'
  run wtout --no-hook feat
  [ "$status" -eq 0 ]
  [ ! -f "$TMP/repo-feat/.hookran" ]
}

@test "a failing post-create hook still creates the worktree and prints the path" {
  install_hook 'exit 3'
  run wtout feat
  [ "$status" -eq 0 ]
  [ "$output" = "$TMP/repo-feat" ]
  [ -d "$TMP/repo-feat" ]
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

@test "rm removes a worktree by branch name" {
  add_worktree feat "$TMP/repo-feat"
  run "$WT" rm feat
  [ "$status" -eq 0 ]
  [ ! -d "$TMP/repo-feat" ]
}

@test "rm of the current worktree returns the main path" {
  add_worktree feat "$TMP/repo-feat"
  cd "$TMP/repo-feat"
  run wtout rm feat
  [ "$status" -eq 0 ]
  [ "$output" = "$REPO" ]
}

@test "rm rejects a directory outside every worktree" {
  mkdir -p "$TMP/outside"
  run "$WT" rm "$TMP/outside"
  [ "$status" -ne 0 ]
}

@test "done removes the current worktree and returns main" {
  add_worktree feat "$TMP/repo-feat"
  cd "$TMP/repo-feat"
  run wtout done
  [ "$status" -eq 0 ]
  [ "$output" = "$REPO" ]
  [ ! -d "$TMP/repo-feat" ]
}

@test "done in the main worktree errors" {
  cd "$REPO"
  run "$WT" done
  [ "$status" -ne 0 ]
}

@test "an unknown option is rejected" {
  run "$WT" --frob
  [ "$status" -ne 0 ]
  [[ "$output" == *"unknown option"* ]]
}

@test "a leading create flag still routes to create (bare shorthand)" {
  run wtout --no-hook shorthand-branch
  [ "$status" -eq 0 ]
  [ "$output" = "$TMP/repo-shorthand-branch" ]
}

@test "create rejects an unknown option" {
  run "$WT" create --no-hok somebranch
  [ "$status" -ne 0 ]
}

@test "create rejects a stray second positional" {
  run "$WT" create somebranch extra-arg
  [ "$status" -ne 0 ]
}
