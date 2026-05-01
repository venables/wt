# wt

A better git worktree workflow. One command to create a worktree, copy your
`.env` files, and start coding.

```sh
wt feature/login    # creates ../myrepo-feature-login with your .env files
```

**Why wt?**

- **Auto-copies `.env` files** - No more manual copying of gitignored config
  files to new worktrees
- **Sensible defaults** - Creates worktrees at `../<repo>-<branch>`, branches
  from current
- **Minimal syntax** - Just `wt <branch>` instead of
  `git worktree add -b branch ../path branch`
- **Auto-cd** - Optional shell integration to cd into the new worktree

## Installation

### Homebrew

```sh
brew install venables/tap/wt
```

### Manual

```sh
curl -o /usr/local/bin/wt https://raw.githubusercontent.com/venables/wt/main/bin/wt
chmod +x /usr/local/bin/wt
```

## Shell Setup (auto-cd)

To automatically cd into new worktrees after creation, add to your `.bashrc` or
`.zshrc`:

```sh
# If installed via Homebrew:
source "$(brew --prefix)/share/wt/wt.sh"

# Or add this function directly:
wt() { local p; p=$(command wt "$@") && [[ -d "$p" ]] && cd "$p" || echo "$p"; }
```

### Bonus: Launch Claude Code after

Add a `wtc` function to your shell config to create a worktree and start coding
with Claude:

```sh
# In your .zshrc or .bashrc
wtc() { wt "$@" && claude; }
```

## Usage

```
wt <command> [args]

Worktree commands:
  <branch>                       Shorthand for 'wt create <branch>'
  create <branch> [opts]         Create a worktree, run post-worktree-add hook
  rm|remove <branch|path>        Remove worktree (runs pre-worktree-remove hook)
  list|ls                        List worktrees with state
  enter <branch|path>            Print worktree path (runs post-worktree-enter)
  run <branch|path> -- <cmd>     Run a command inside a worktree
  back                           Print main worktree path
  prune                          Run git worktree prune

State commands (run inside a worktree):
  state get <key>                Read a state value
  state set <key> <value>        Set a state value
  state unset <key>              Remove a state key
  state list                     Print full state json

Maintenance:
  doctor                         Sanity checks
  run-hook <name> [opts]         Test a hook with synthetic env

Options for create:
  -b, --base <branch>            Base branch (defaults to current)
  -p, --path <path>              Custom worktree path
  --no-copy                      Skip .worktreeinclude/.gitignore copying
  --no-hook                      Skip running post-worktree-add hook

Global flags:
  --strict                       post-* hook failures abort instead of warn
```

### Examples

```sh
# Create a worktree for an existing branch
wt feature/login

# Create a new branch from current branch and add worktree
wt feature/new-thing

# Create a new branch from main
wt -b main feature/new-thing

# Create worktree without copying files
wt --no-copy feature/quick-fix

# List all worktrees with their per-worktree state
wt list

# Run a command inside a worktree without cd
wt run feature/login -- pnpm test

# Read/write per-worktree state from a hook or your shell
wt state set db_name catena_test_login
wt state get db_name

# Remove a worktree by branch name
wt remove feature/login

# Go back to the main worktree
wt back
```

## Hooks

`wt` looks for executable scripts in `~/.config/wt/hooks/` (override with
`$WT_HOOKS_DIR`). Each hook can be written in any language as long as it's
executable.

| Hook                   | Fires                                  | On failure                        |
| ---------------------- | -------------------------------------- | --------------------------------- |
| `pre-worktree-add`     | Before `git worktree add` (validation) | Aborts the create                 |
| `post-worktree-add`    | After create, after file copy          | Warns (or aborts with `--strict`) |
| `pre-worktree-remove`  | Before `git worktree remove`           | Aborts the remove                 |
| `post-worktree-remove` | After successful remove                | Warns (or aborts with `--strict`) |
| `post-worktree-enter`  | When `wt enter` is run                 | Warns (or aborts with `--strict`) |

Each hook receives these env vars:

- `WT_PATH` — absolute path to the worktree
- `WT_BRANCH` — branch name
- `WT_REPO_ROOT` — main repo path
- `WT_REPO_NAME` — main repo basename

Hooks should be idempotent. If `post-worktree-add` fails, the worktree exists
but setup is incomplete; `wt` prints recovery instructions and you can re-run
the hook (`wt run-hook post-worktree-add --branch X --path Y`) or reset with
`wt rm <branch>`.

### Per-worktree state

`wt` stores state at `<worktree>/.wt/state.json`. Hooks use `wt state set/get`
to record what they allocated (db name, ports, tmux session, etc.) and
`pre-worktree-remove` reads it back to tear those resources down. The first
`wt create` in a repo adds `/.wt/` to the repo's `.git/info/exclude` so this
directory is git-ignored automatically.

### Example hook

```sh
# ~/.config/wt/hooks/post-worktree-add
#!/usr/bin/env bash
set -euo pipefail

# Per-repo branching: only run setup logic for repos that need it
case "$WT_REPO_NAME" in
  catena)
    # symlink env files
    ln -sf "$WT_REPO_ROOT/.env" "$WT_PATH/.env"
    # create db
    db="catena_test_${WT_BRANCH//[^a-z0-9_]/_}"
    createdb -T catena_dev "$db"
    wt state set db_name "$db"
    ;;
esac
```

### Testing hooks

`wt run-hook <name> [--branch X] [--path Y]` runs a hook with synthetic env
vars without touching git. Useful for iterating on hook scripts.

## Automatic File Copying

By default, `wt` reads `.gitignore` and copies any **regular files** it lists
(like `.env`, `.env.local`) to new worktrees so you can start working
immediately. Directories in `.gitignore` (`node_modules/`, `dist/`, `.next/`,
etc.) are skipped — copying them would be slow and pointless.

If you want to copy a directory or have explicit control over what gets
copied, add a `.worktreeinclude` file at the repo root:

```
.env
.env.local
config/local.json
secrets/
```

When `.worktreeinclude` exists it takes precedence over the `.gitignore`
fallback, and entries can be files or directories. Each entry must also be in
`.gitignore` (prevents accidentally copying tracked files).

**Skip copying**: Use `--no-copy` for a clean worktree without any copied files.

## Releasing

1. Update `VERSION` in `bin/wt`:

   ```sh
   # Edit bin/wt and change VERSION="0.2.0" to the new version
   ```

2. Commit and tag:

   ```sh
   git add bin/wt
   git commit -m "chore: bump version to 0.2.0"
   git tag v0.2.0
   git push origin main --tags
   ```

3. Get the SHA256 of the release tarball:

   ```sh
   curl -sL https://github.com/venables/wt/archive/refs/tags/v0.2.0.tar.gz | shasum -a 256
   ```

4. Update [venables/homebrew-tap](https://github.com/venables/homebrew-tap):

   Edit `Formula/wt.rb` with the new version and SHA256.

## License

MIT
