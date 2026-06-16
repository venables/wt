# wt

**`git worktree` with a better CLI, sane defaults, and hooks.**

One command to spin up a worktree, copy your `.env` files, run your setup, and
drop you into a ready-to-code directory.

```sh
wt feature/login    # creates ../myrepo-feature-login, copies .env, runs your hook, cds in
# ... do work, make a PR
wt done             # cleans up, drops you back in myrepo
```

Stop typing `git worktree add -b feature/login ../myrepo-feature-login feature/login`
and then manually copying `.env` files and running `pnpm install`. Just `wt feature/login`.

**Why wt?**

- **A CLI that fits in your head** — `wt <branch>` to create, `wt done` to
  finish, `wt back` to return to main, `wt cleanup` to tidy up. No more
  five-argument `git worktree add` incantations.
- **Sane defaults** — Worktrees land at `../<repo>-<branch>`, new branches
  fork from your current branch, and `.env` files come along automatically so
  nothing is broken on first `cd`.
- **Hooks, hooks, hooks** — `pre`/`post` hooks for add, remove, and enter let
  every repo do its own thing: `pnpm install`, `mise trust`, seed a database,
  warm a cache, page your dog. `wt` stays small; your hooks do the rest.
- **Shell-native** — Optional auto-cd into new worktrees, plus a one-liner to
  launch Claude Code (or any other tool) the moment the worktree is ready.
- **Read more** — [Why I built wt](https://venabl.es/wt) and
  [Cleaning up worktrees with wt](https://venabl.es/wt-cleanup).

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

### Optional dependencies

`wt cleanup` uses [`gum`](https://github.com/charmbracelet/gum) for its
interactive multi-select picker when it's on your `PATH`, and falls back to a
plain numbered prompt otherwise. The Homebrew formula installs `gum`
automatically; for the manual install, add it with `brew install gum`. Run
`wt doctor` to see what's detected.

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
  create <branch> [opts]         Create a worktree (enters it if it already exists)
  rm|remove [-f] <branch|path>   Remove worktree (runs pre-worktree-remove hook)
  list|ls                        List worktrees
  enter <branch|path>            Print worktree path (runs post-worktree-enter)
  run <branch|path> -- <cmd>     Run a command inside a worktree
  back                           Print main worktree path
  done [-f|--force]              Remove current worktree, return to main
  cleanup|clean                  Interactively remove non-main worktrees
  nuke [-y|--yes]                Force-remove ALL non-main worktrees
  prune                          Run git worktree prune

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

# Note: running `wt <branch>` from inside another worktree branches off
# *that* worktree's branch and creates the new directory as its sibling.
# Pass `-b main` (or `--base main`) to branch from main regardless of
# where you invoke from.

# Create worktree without copying files
wt --no-copy feature/quick-fix

# List all worktrees
wt list

# Run a command inside a worktree without cd
wt run feature/login -- pnpm test

# Remove a worktree by branch name
wt remove feature/login

# Force-remove a dirty worktree
wt rm -f feature/login

# Go back to the main worktree
wt back

# Done with this branch: remove current worktree and cd to main
wt done

# Pick worktrees to remove from an interactive list. Each row shows whether the
# branch is merged, how far ahead/behind main it is, and when it last changed.
# Uses gum (https://github.com/charmbracelet/gum) for a multi-select picker when
# installed; falls back to a numbered prompt otherwise.
wt cleanup

# Wipe every non-main worktree (with confirmation)
wt nuke
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

### Philosophy

`wt` itself stays small: create worktrees, copy the files you need, run hooks,
clean up. Anything project-specific — trusting tool versions, installing
dependencies, provisioning a database — belongs in a hook. That keeps the CLI
boring and lets each repo do exactly what it needs.

### Example hook

```sh
# ~/.config/wt/hooks/post-worktree-add
#!/usr/bin/env bash
set -euo pipefail

cd "$WT_PATH"

# Trust the new worktree's mise config
if command -v mise >/dev/null 2>&1; then
  mise trust
fi

if [[ -f pnpm-lock.yaml ]]; then
  pnpm install --frozen-lockfile
elif [[ -f bun.lock || -f bun.lockb ]]; then
  bun install --frozen-lockfile
elif [[ -f package-lock.json ]]; then
  npm ci
fi
```

A reference `post-worktree-add` hook that copies common dotenv files lives at
[`share/hooks/post-worktree-add.example`](share/hooks/post-worktree-add.example).
Drop it in `~/.config/wt/hooks/` (and pair with `wt --no-copy`) if you'd
rather handle file copying explicitly from a hook.

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
   # Edit bin/wt and change VERSION="0.3.0" to the new version
   ```

2. Commit and tag:

   ```sh
   git add bin/wt
   git commit -m "chore: bump version to 0.3.0"
   git tag v0.3.0
   git push origin main --tags
   ```

3. Get the SHA256 of the release tarball:

   ```sh
   curl -sL https://github.com/venables/wt/archive/refs/tags/v0.3.0.tar.gz | shasum -a 256
   ```

4. Update [venables/homebrew-tap](https://github.com/venables/homebrew-tap):

   Edit `Formula/wt.rb` with the new version and SHA256.

## License

MIT
