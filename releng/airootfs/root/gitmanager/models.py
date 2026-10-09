"""Data models describing a scanned git repository's current status."""
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


@dataclass
class RepoStatus:
    path: Path
    name: str
    branch: str = "—"
    ahead: int = 0
    behind: int = 0
    staged: int = 0
    unstaged: int = 0
    untracked: int = 0
    has_upstream: bool = False
    error: str = ""

    @property
    def is_clean(self) -> bool:
        return (
            not self.error
            and self.staged == 0
            and self.unstaged == 0
            and self.untracked == 0
            and self.ahead == 0
            and self.behind == 0
        )

    @property
    def dirty_count(self) -> int:
        return self.staged + self.unstaged + self.untracked

    @property
    def state_label(self) -> str:
        """A single-word classification used to pick a status color/label."""
        if self.error:
            return "error"
        if self.is_clean:
            return "clean"
        if self.ahead and self.behind:
            return "diverged"
        if self.ahead:
            return "ahead"
        if self.behind:
            return "behind"
        return "dirty"
