# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.1]

### Changed

- `wt cleanup`'s gum picker now pre-checks merged worktrees, since a branch
  already in main is the safe default to remove. Toggle any off before
  confirming.

## [0.5.0]

### Added

- `wt cleanup` uses [`gum`](https://github.com/charmbracelet/gum) for an
  interactive multi-select picker when it is installed, falling back to the
  numbered prompt otherwise.
- `wt cleanup` now shows each worktree's staleness: how many commits it is
  ahead of / behind the main branch, and when it last changed.
- `wt doctor` reports whether `gum` is installed.

## [0.4.2]

### Fixed

- Shell wrapper recovers from a deleted current directory. When another
  tab removes the worktree a shell is sitting in (e.g. via `wt done`),
  the wrapper now cd's to the nearest existing ancestor before running
  `wt`, instead of failing with `getcwd` / git / mise errors.

## [0.4.1]

### Added

- `wt clean` is now an alias for `wt cleanup`.

### Changed

- README intro rewritten to highlight the CLI ergonomics, sane defaults,
  and hook system.

## [0.4.0]

### Added

- `wt done [-f]` removes the current worktree and returns to main.
- `wt cleanup` shows an interactive picker (with merged/unmerged status)
  for removing non-main worktrees.
- `wt nuke [-y]` force-removes every non-main worktree.
- `-f|--force` flag on `wt rm` for removing dirty worktrees.

## [0.3.0]

### Removed

- Per-worktree state (`wt state` subcommand, `<worktree>/.wt/state.json`,
  and the automatic `/.wt/` entry in `.git/info/exclude`). Hooks should
  manage their own scratch storage if they need it.
- `jq` is no longer a dependency.

### Changed

- `wt list` now delegates directly to `git worktree list`.

## [0.2.0]

### Added

- Hook system for worktree lifecycle events. Executable scripts in
  `~/.config/wt/hooks/` (override with `$WT_HOOKS_DIR`) are run with
  `WT_PATH`, `WT_BRANCH`, `WT_REPO_ROOT`, `WT_REPO_NAME` in env. Supported
  hooks: `pre-worktree-add`, `post-worktree-add`, `pre-worktree-remove`,
  `post-worktree-remove`, `post-worktree-enter`. Pre-hook failures abort;
  post-hook failures warn unless `--strict` is passed.
- Per-worktree state at `<worktree>/.wt/state.json`. `wt state get|set|unset|list`
  manipulate it from inside a worktree. Atomic writes via `jq` + `mv`.
- New commands: `create` (alias for `add`), `enter`, `run`, `state`, `doctor`,
  `run-hook`. `run-hook` invokes a hook with synthetic env vars for testing
  without going through `git worktree add`/`rm`.
- Global `--strict` flag: post-hook failures abort instead of warning.
- `--no-hook` flag on `create` to skip the post-worktree-add hook.
- First `wt create` in a repo appends `/.wt/` to `<main-repo>/.git/info/exclude`
  so per-worktree state files are git-ignored automatically.

### Fixed

- `.gitignore`-fallback copy no longer drags in directories like
  `node_modules/`, `dist/`, `.next/`. Only regular files are copied
  automatically. Directories must be opted in via `.worktreeinclude`.

### Changed

- The bare `wt <branch>` shorthand now dispatches to `create` (was `add`).
  Behavior is identical; `add` and `new` remain as aliases.

## [0.1.3] - 2025-01-22

### Added

- `wt back` command jumps to the main worktree (use with shell wrapper).

## [0.1.2]

### Fixed

- Auto-cd: redirect git output to stderr so the shell wrapper can capture
  the worktree path cleanly.

### Added

- `wtc` tip in README for launching Claude Code after `wt`.

## [0.1.1]

### Added

- Auto-cd shell wrapper.
- `--no-copy` flag.
- Auto-create branch when one doesn't exist.

## [0.1.0]

### Added

- Initial release: `wt <branch>`, `wt list`, `wt remove`, `wt prune`, and
  automatic copying of gitignored config files into new worktrees.

[Unreleased]: https://github.com/venables/wt/compare/v0.4.2...HEAD
[0.4.2]: https://github.com/venables/wt/compare/v0.4.1...v0.4.2
[0.4.1]: https://github.com/venables/wt/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/venables/wt/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/venables/wt/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/venables/wt/compare/v0.1.3...v0.2.0
[0.1.3]: https://github.com/venables/wt/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/venables/wt/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/venables/wt/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/venables/wt/releases/tag/v0.1.0
