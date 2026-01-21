# CLAUDE.md

Bash CLI for git worktree management.

## Key Conventions

- **stdout/stderr separation**: Output worktree path to stdout on success; all other messages to stderr. This enables the shell wrapper (`share/wt.sh`) to capture the path for auto-cd.
- **Version**: Update `VERSION` at top of `bin/wt` when releasing.
