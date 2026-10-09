"""Background QThread workers so scanning and git commands never freeze the UI."""
from __future__ import annotations

from pathlib import Path
from typing import Callable

from PySide6.QtCore import QThread, Signal

from git_ops import get_repo_status
from git_scanner import scan_for_repos
from models import RepoStatus


class ScanWorker(QThread):
    """Walks `root` for git repos and emits a RepoStatus for each one found."""

    repo_found = Signal(object)   # RepoStatus, emitted as each repo is discovered
    finished_scan = Signal(int)   # total repos found
    progress = Signal(str)        # path currently being checked, for status text

    def __init__(self, root: Path, parent=None):
        super().__init__(parent)
        self.root = root
        self._cancelled = False

    def cancel(self):
        self._cancelled = True

    def run(self):
        count = 0
        for repo_path in scan_for_repos(self.root):
            if self._cancelled:
                break
            self.progress.emit(str(repo_path))
            status = get_repo_status(repo_path)
            self.repo_found.emit(status)
            count += 1
        self.finished_scan.emit(count)


class ActionWorker(QThread):
    """Runs a single git action (init/add/commit/pull/push/...) off the UI thread."""

    succeeded = Signal(object, str)   # refreshed RepoStatus, output text
    failed = Signal(object, str)      # repo path, error text

    def __init__(self, repo_path: Path, action: Callable[[Path], str], parent=None):
        super().__init__(parent)
        self.repo_path = repo_path
        self.action = action

    def run(self):
        try:
            output = self.action(self.repo_path)
        except Exception as e:  # noqa: BLE001 — surface any failure to the UI
            self.failed.emit(self.repo_path, str(e))
            return
        refreshed = get_repo_status(self.repo_path)
        self.succeeded.emit(refreshed, output or "Done.")
