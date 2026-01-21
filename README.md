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

## Usage

```
wt [command] [options]

Commands:
  <branch>                   Add a worktree (shorthand for 'wt add')
  list|ls                    Show active worktrees
  add [-b base] <branch>     Add a worktree
  remove|rm <path|branch>    Remove a worktree by path or branch name
  prune                      Run git worktree prune
```

### Examples

```sh
# Create a worktree for an existing branch
wt feature/login

# Create a worktree for a new branch based on main
wt -b main feature/new-thing

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

## License

MIT
