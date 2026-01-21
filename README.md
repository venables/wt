# wt

A simple git worktree manager. Creates worktrees at `../<repo>-<branch>`.

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

To automatically cd into new worktrees after creation, add to your `.bashrc` or `.zshrc`:

```sh
# If installed via Homebrew:
source "$(brew --prefix)/share/wt/wt.sh"

# Or add this function directly:
wt() { local p; p=$(command wt "$@") && [[ -d "$p" ]] && cd "$p" || echo "$p"; }
```

### Bonus: Launch Claude Code after

Add a `wtc` function to your shell config to create a worktree and start coding with Claude:

```sh
# In your .zshrc or .bashrc
wtc() { wt "$@" && claude; }
```

## Usage

```
wt [command] [options]

Commands:
  <branch>                   Add a worktree (shorthand for 'wt add')
  list|ls                    Show active worktrees
  add [options] <branch>     Add a worktree
  remove|rm <path|branch>    Remove a worktree by path or branch name
  prune                      Run git worktree prune

Options for add:
  -b, --base <branch>        Base branch (defaults to current branch)
  -p, --path <path>          Custom worktree path
  --no-copy                  Skip copying .worktreeinclude/.gitignore files
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

# List all worktrees
wt list

# Remove a worktree by branch name
wt remove feature/login
```

## File Copying

When creating a worktree, `wt` can automatically copy gitignored files (like `.env`) to the new worktree.

### .worktreeinclude

Create a `.worktreeinclude` file in your repo root to specify which files to copy:

```
.env
.env.local
```

Each pattern must also exist in `.gitignore` (to prevent copying tracked files).

### Fallback

If no `.worktreeinclude` exists, `wt` falls back to copying all files matching patterns in `.gitignore` that exist in the source worktree.

### Skipping

Use `--no-copy` to skip file copying entirely.

## License

MIT
