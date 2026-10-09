"""Recursively scan a directory tree for git repositories."""
from __future__ import annotations

import os
from pathlib import Path
from typing import Iterable, Iterator

# Directories that are never useful to descend into: dependency caches,
# build output, virtualenvs, etc. Scanning into these is slow and never
# turns up a repo you'd want listed.
DEFAULT_SKIP_DIRS = {
    "node_modules", "__pycache__", ".venv", "venv", "env",
    ".cache", ".npm", ".cargo", ".rustup", ".local",
    ".m2", ".gradle", "build", "dist", "target",
    "Trash", ".Trash", ".mozilla", ".config", ".steam",
    ".wine", "vendor",
}


def scan_for_repos(
    root: Path,
    max_depth: int = 8,
    skip_dirs: Iterable[str] = DEFAULT_SKIP_DIRS,
) -> Iterator[Path]:
    """Yield the path of every directory under `root` that is a git repo.

    A directory counts as a repo if it contains a `.git` entry — either a
    directory (a normal repo) or a file (a worktree / submodule pointer).
    Common noise directories (node_modules, venvs, build output, caches)
    are pruned before they're walked into. Scanning stops going deeper
    than `max_depth` levels below `root` to keep large home directories
    fast to scan.
    """
    root = root.expanduser().resolve()
    if not root.is_dir():
        return

    skip = set(skip_dirs)
    root_depth = len(root.parts)

    for dirpath, dirnames, filenames in os.walk(root, topdown=True, onerror=lambda e: None):
        current = Path(dirpath)
        depth = len(current.parts) - root_depth

        if depth >= max_depth:
            dirnames[:] = []
            continue

        # Prune noisy directories, and hidden directories other than .git,
        # before os.walk descends into them.
        pruned = []
        for d in dirnames:
            if d in skip:
                continue
            if d.startswith(".") and d != ".git":
                continue
            pruned.append(d)
        dirnames[:] = pruned

        has_git_dir = ".git" in dirnames
        has_git_file = ".git" in filenames  # worktrees/submodules use a .git file

        if has_git_dir or has_git_file:
            yield current
            if has_git_dir:
                # Don't walk into the repo's internal .git directory itself,
                # but keep scanning subdirectories in case of nested repos.
                dirnames.remove(".git")
