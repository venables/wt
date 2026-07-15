# wt

**`git worktree` with a CLI that fits in your head, sane defaults, and one hook.**

```sh
wt feature/login    # creates ../myrepo.feature-login, runs your post-create hook, cds in
# ... do work, make a PR
wt done             # removes the worktree, drops you back in myrepo
```

Stop typing `git worktree add -b feature/login ../myrepo.feature-login feature/login`
and then `cd` there by hand. Just `wt feature/login`.

**Why wt?**

- **Five verbs, no incantations** — `wt <branch>` to create, `wt done` to
  finish, `wt back` to return to main, `wt rm` to remove, `wt ls` to see them.
- **Sane defaults** — Worktrees land at `../<repo>.<branch>`, and new branches
  fork from your current branch.
- **One hook** — a single `post-create` hook does everything project-specific:
  copy `.env`, run `pnpm install`, trust your `mise` config, seed a database.
  `wt` stays tiny; your hook does the rest.
- **Shell-native** — a small wrapper auto-cds you into new worktrees and back
  out when you remove the one you're in.
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

## Shell Setup (auto-cd)

`wt` prints the target worktree path to stdout so a shell wrapper can cd there
for you. Source the shipped `wt.sh` from your `.bashrc` or `.zshrc`:

```sh
# If installed via Homebrew:
source "$(brew --prefix)/share/wt/wt.sh"

# Manual install: source the wt.sh that ships next to the wt script, e.g.
# source "$HOME/path/to/wt/share/wt.sh"
```

The wrapper cds into new worktrees on create, returns you to the main worktree
after `wt done` or `wt rm` of the current worktree, and recovers a shell whose
worktree was removed from another tab.

### Bonus: Launch Claude Code after

```sh
# In your .zshrc or .bashrc
wtc() { wt "$@" && claude; }
```

## Usage

```
wt <command> [args]

  <branch>              Create a worktree for <branch> (enters it if it exists)
  create <branch>       Same as the shorthand, with options below
  ls|list               List worktrees
  rm|remove [-f] <ref>  Remove a worktree by branch name or path
  done [-f|--force]     Remove the current worktree and return to main
  back                  Print the main worktree path

Options for create:
  -b, --base <branch>   Base branch for a new branch (defaults to current)
  -p, --path <path>     Custom worktree path
  --no-hook             Skip the post-create hook
```

### Examples

```sh
# Create a worktree for an existing branch (or a new branch off the current one)
wt feature/login

# Create a new branch from main regardless of where you invoke from
wt -b main feature/new-thing

# List all worktrees
wt ls

# Remove a worktree by branch name
wt rm feature/login

# Force-remove a dirty worktree
wt rm -f feature/login

# Go back to the main worktree
wt back

# Done with this branch: remove the current worktree and cd to main
wt done
```

Note: running `wt <branch>` from inside another worktree branches off _that_
worktree's branch. Pass `-b main` to branch from main regardless.

## The post-create hook

`wt` runs a single executable at `~/.config/wt/hooks/post-create` (override the
directory with `$WT_HOOKS_DIR`) right after a worktree is created. Write it in
any language, make it executable, and put everything project-specific in it:
copying `.env` files, installing dependencies, trusting tool versions, warming a
cache. If the hook fails, `wt` warns but still drops you into the worktree so
you can fix it. Skip it for one run with `wt --no-hook <branch>`.

Each run receives these env vars:

- `WT_PATH` — absolute path to the new worktree
- `WT_BRANCH` — branch name
- `WT_REPO_ROOT` — main repo path
- `WT_REPO_NAME` — main repo basename

A reference hook that copies dotenv files and installs dependencies lives at
[`share/hooks/post-create.example`](share/hooks/post-create.example):

```sh
install -Dm755 share/hooks/post-create.example ~/.config/wt/hooks/post-create
```

## Releasing

1. Update `VERSION` in `bin/wt`.
2. Commit, tag, and push:

   ```sh
   git commit -am "chore: bump version to X.Y.Z"
   git tag vX.Y.Z
   git push origin main --tags
   ```

3. Get the SHA256 of the release tarball:

   ```sh
   curl -sL https://github.com/venables/wt/archive/refs/tags/vX.Y.Z.tar.gz | shasum -a 256
   ```

4. Update [venables/homebrew-tap](https://github.com/venables/homebrew-tap)'s
   `Formula/wt.rb` with the new version and SHA256.

## License

MIT
