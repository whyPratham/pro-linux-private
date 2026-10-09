# Git Hub — Centralized Git Repo Manager

A desktop GUI (PySide6 / Qt) that scans your home directory for git
repositories, shows the live status of every one (branch, staged /
unstaged / untracked file counts, ahead/behind vs. upstream), and lets
you run `init`, `add`, `commit`, `pull`, and `push` from buttons — no
terminal required.

Theme: **Catppuccin Mocha**, mauve accent.

## Setup

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python main.py
```

**On Arch (matches PRO Linux):** you can skip the venv and install the
system package instead — `sudo pacman -S python-pyside6` — then just run
`python main.py` directly.

## Features

- **Recursive scan of `~`** — walks your home directory looking for
  `.git` entries, automatically skipping noisy folders
  (`node_modules`, `.venv`, `.cache`, `build`, `target`, etc.) and
  capping recursion depth so it stays fast even on a large home dir.
- **Live status per repo** — branch name, staged / unstaged / untracked
  file counts, and ahead/behind counts vs. the upstream, all from a
  single `git status --porcelain=v2 --branch` call per repo.
- **One-click actions**: Init, Add All (`git add -A`), Commit (opens a
  message dialog, with an optional "stage all first" toggle), Pull,
  Push, and a combined Pull + Push.
- **Smart push** — if a branch has no upstream yet, Push automatically
  runs `git push --set-upstream origin <branch>` instead of just failing.
- **Non-blocking UI** — scanning and every git command run on a
  background `QThread`, so the window never freezes, even on a slow
  network pull/push.
- **Filter box** to quickly narrow the list by repo name or path.
- **+ Add Folder** — track a folder outside your home directory scan,
  or get prompted to `git init` a plain folder on the spot.

## Project structure

```
git-hub/
├── main.py              # entry point — creates the QApplication + window
├── theme.py              # Catppuccin Mocha palette + Qt stylesheet (mauve accent)
├── models.py              # RepoStatus dataclass
├── git_scanner.py         # recursive filesystem walk for .git directories
├── git_ops.py              # subprocess wrappers around the git CLI
├── workers.py               # QThread workers (ScanWorker, ActionWorker)
├── ui/
│   ├── main_window.py        # table view + toolbar + action buttons
│   └── commit_dialog.py       # commit message modal
└── requirements.txt
```

## How the status columns work

Each repo is classified into one state, color-coded in the Status column:

| State      | Meaning                                    | Color  |
|------------|---------------------------------------------|--------|
| ✓ Clean    | nothing staged/unstaged/untracked, in sync  | green  |
| ● Changes  | has staged, unstaged, or untracked files    | yellow |
| ↑ Ahead    | local commits not yet pushed                | blue   |
| ↓ Behind   | remote commits not yet pulled               | peach  |
| ↕ Diverged | both ahead and behind                       | red    |
| ⚠ Error    | git command failed (corrupt repo, etc.)     | red    |

## Notes / things worth knowing

- The scanner descends into nested repos (a repo inside another repo's
  subfolder will still show up separately).
- Timeout on any single git command is 25 seconds — a hung network pull
  won't hang the whole app, it'll just report a timeout error for that repo.
- All destructive-ish actions (`push`, `pull`) run exactly what you'd
  type in a terminal — there's no hidden `--force` anywhere.
