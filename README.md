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
wt [command] [options]

Commands:
  <branch>                   Add a worktree (shorthand for 'wt add')
  list|ls                    Show active worktrees
  add [options] <branch>     Add a worktree
  remove|rm <path|branch>    Remove a worktree by path or branch name
  back                       Go to the main worktree
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

# Go back to the main worktree
wt back
```

## Automatic File Copying

By default, `wt` copies gitignored files (like `.env`, `.env.local`) to new
worktrees so you can start working immediately.

Alternatively, you can explicitly list which ignored files to copy by creating a
`.worktreeinclude` file:

```
.env
.env.local
config/local.json
```

Files in `.worktreeinclude` must also be in `.gitignore` (prevents accidentally
copying tracked files).

**Skip copying**: Use `--no-copy` for a clean worktree without any copied files.

## License

MIT
