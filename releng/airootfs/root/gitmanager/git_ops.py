"""Thin wrappers around git CLI commands.

Every function here runs synchronously and can block for a while (network
calls for pull/push especially) — callers must invoke these from a
background thread (see workers.py), never from the Qt UI thread.
"""
from __future__ import annotations

import subprocess
from pathlib import Path
from typing import Optional

from models import RepoStatus

GIT_TIMEOUT = 25  # seconds; generous for slow networks on pull/push


class GitCommandError(Exception):
    """Raised when a git command exits non-zero. Carries the command and stderr."""

    def __init__(self, command: str, returncode: int, stderr: str):
        self.command = command
        self.returncode = returncode
        self.stderr = stderr.strip()
        super().__init__(f"`git {command}` failed ({returncode}): {self.stderr}")


def _run(args: list[str], cwd: Path, timeout: int = GIT_TIMEOUT) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["git", *args],
        cwd=str(cwd),
        capture_output=True,
        text=True,
        timeout=timeout,
    )


def _run_or_raise(args: list[str], cwd: Path, timeout: int = GIT_TIMEOUT) -> str:
    result = _run(args, cwd, timeout)
    if result.returncode != 0:
        raise GitCommandError(" ".join(args), result.returncode, result.stderr or result.stdout)
    return result.stdout.strip()


def get_repo_status(repo_path: Path) -> RepoStatus:
    """Return a fully populated RepoStatus for the repo at repo_path.

    Uses `git status --porcelain=v2 --branch`, which gives branch name,
    ahead/behind counts, and per-file status codes in one machine-readable
    call — no need to run status, branch, and rev-list separately.
    """
    name = repo_path.name or str(repo_path)
    try:
        result = _run(["status", "--porcelain=v2", "--branch"], repo_path)
    except (subprocess.TimeoutExpired, OSError) as e:
        return RepoStatus(path=repo_path, name=name, error=str(e))

    if result.returncode != 0:
        return RepoStatus(path=repo_path, name=name, error=(result.stderr or "git status failed").strip())

    branch = "—"
    ahead = behind = 0
    staged = unstaged = untracked = 0
    has_upstream = False

    for line in result.stdout.splitlines():
        if line.startswith("# branch.head "):
            branch = line.split(" ", 2)[2]
        elif line.startswith("# branch.upstream "):
            has_upstream = True
        elif line.startswith("# branch.ab "):
            # e.g. "# branch.ab +2 -1"
            parts = line.split()
            ahead = int(parts[2].lstrip("+"))
            behind = int(parts[3].lstrip("-"))
        elif line.startswith("1 ") or line.startswith("2 "):
            # ordinary changed / renamed entries: "1 XY ..." — XY are the
            # index (staged) and worktree (unstaged) status characters
            xy = line.split(" ", 2)[1]
            if xy[0] != ".":
                staged += 1
            if xy[1] != ".":
                unstaged += 1
        elif line.startswith("u "):
            # unmerged/conflicted — counts as needing attention on both sides
            staged += 1
            unstaged += 1
        elif line.startswith("? "):
            untracked += 1

    if branch == "(detached)":
        branch = "detached HEAD"

    return RepoStatus(
        path=repo_path,
        name=name,
        branch=branch,
        ahead=ahead,
        behind=behind,
        staged=staged,
        unstaged=unstaged,
        untracked=untracked,
        has_upstream=has_upstream,
    )


def git_init(path: Path) -> str:
    return _run_or_raise(["init"], path)


def git_add_all(path: Path) -> str:
    return _run_or_raise(["add", "-A"], path)


def git_commit(path: Path, message: str) -> str:
    if not message.strip():
        raise GitCommandError("commit", 1, "Commit message cannot be empty")
    return _run_or_raise(["commit", "-m", message], path)


def current_branch(path: Path) -> Optional[str]:
    result = _run(["symbolic-ref", "--short", "-q", "HEAD"], path)
    if result.returncode == 0:
        return result.stdout.strip()
    return None


def git_pull(path: Path) -> str:
    return _run_or_raise(["pull"], path)


def git_push(path: Path) -> str:
    """Push, and if the branch has no upstream yet, set one on origin and retry."""
    result = _run(["push"], path)
    if result.returncode == 0:
        return result.stdout.strip() or result.stderr.strip() or "Pushed."

    combined = (result.stderr or "") + (result.stdout or "")
    if "has no upstream branch" in combined or "set-upstream" in combined:
        branch = current_branch(path) or "HEAD"
        return _run_or_raise(["push", "--set-upstream", "origin", branch], path)

    raise GitCommandError("push", result.returncode, combined)


def git_pull_push(path: Path) -> str:
    out1 = git_pull(path)
    out2 = git_push(path)
    return f"{out1}\n{out2}".strip()
