"""Main application window: repo table, filter box, and git action buttons."""
from __future__ import annotations

from pathlib import Path

from PySide6.QtCore import Qt, Slot
from PySide6.QtGui import QAction, QColor, QKeySequence
from PySide6.QtWidgets import (
    QAbstractItemView,
    QFileDialog,
    QHBoxLayout,
    QHeaderView,
    QLabel,
    QLineEdit,
    QMainWindow,
    QMessageBox,
    QProgressBar,
    QPushButton,
    QStatusBar,
    QTableWidget,
    QTableWidgetItem,
    QVBoxLayout,
    QWidget,
)

from git_ops import get_repo_status, git_add_all, git_commit, git_init, git_pull, git_pull_push, git_push
from models import RepoStatus
from theme import MOCHA, STATE_COLORS
from ui.commit_dialog import CommitDialog
from workers import ActionWorker, ScanWorker

COLUMNS = ["Repo", "Branch", "Staged", "Unstaged", "Untracked", "Ahead", "Behind", "Status", "Path"]
PATH_COLUMN = len(COLUMNS) - 1  # hidden column holding the full path, used as a lookup key

STATE_TEXT = {
    "clean": "✓ Clean",
    "dirty": "● Changes",
    "ahead": "↑ Ahead",
    "behind": "↓ Behind",
    "diverged": "↕ Diverged",
    "error": "⚠ Error",
}


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Git Hub — Repo Manager")
        self.resize(1180, 700)

        self._repos: dict[str, RepoStatus] = {}
        self._scan_worker: ScanWorker | None = None
        self._action_workers: list[ActionWorker] = []  # keep references alive while running
        self._git_menu_actions: list[QAction] = []  # git actions that need a repo selected

        self._build_menu_bar()
        self._build_ui()
        self.start_scan()

    # -------------------------------------------------------------- menu bar
    def _build_menu_bar(self):
        menubar = self.menuBar()

        # --- File menu: same pattern as any app's File dropdown ---
        file_menu = menubar.addMenu("&File")

        add_folder_action = QAction("Add Folder…", self)
        add_folder_action.setShortcut(QKeySequence("Ctrl+O"))
        add_folder_action.triggered.connect(self.browse_and_add_folder)
        file_menu.addAction(add_folder_action)

        rescan_action = QAction("Rescan Home", self)
        rescan_action.setShortcut(QKeySequence("Ctrl+R"))
        rescan_action.triggered.connect(self.start_scan)
        file_menu.addAction(rescan_action)

        file_menu.addSeparator()

        quit_action = QAction("Quit", self)
        quit_action.setShortcut(QKeySequence("Ctrl+Q"))
        quit_action.triggered.connect(self.close)
        file_menu.addAction(quit_action)

        # --- Git menu: one QAction per git operation, wired to the same
        # methods the buttons call. Anything appended to _git_menu_actions
        # gets enabled/disabled together with the button row based on
        # whether a repo is currently selected. ---
        git_menu = menubar.addMenu("&Git")

        init_action = QAction("Init", self)
        init_action.setToolTip("git init")
        init_action.triggered.connect(self.action_init)
        git_menu.addAction(init_action)

        add_action = QAction("Add All", self)
        add_action.setShortcut(QKeySequence("Ctrl+Shift+A"))
        add_action.setToolTip("git add -A")
        add_action.triggered.connect(self.action_add_all)
        git_menu.addAction(add_action)

        commit_action = QAction("Commit…", self)
        commit_action.setShortcut(QKeySequence("Ctrl+K"))
        commit_action.triggered.connect(self.action_commit)
        git_menu.addAction(commit_action)

        git_menu.addSeparator()

        pull_action = QAction("Pull", self)
        pull_action.setShortcut(QKeySequence("Ctrl+L"))
        pull_action.triggered.connect(self.action_pull)
        git_menu.addAction(pull_action)

        push_action = QAction("Push", self)
        push_action.setShortcut(QKeySequence("Ctrl+P"))
        push_action.triggered.connect(self.action_push)
        git_menu.addAction(push_action)

        sync_action = QAction("Pull + Push", self)
        sync_action.setShortcut(QKeySequence("Ctrl+Shift+P"))
        sync_action.triggered.connect(self.action_pull_push)
        git_menu.addAction(sync_action)

        self._git_menu_actions = [init_action, add_action, commit_action, pull_action, push_action, sync_action]

    # ------------------------------------------------------------------ UI
    def _build_ui(self):
        central = QWidget()
        central.setObjectName("centralWidget")
        self.setCentralWidget(central)
        root_layout = QVBoxLayout(central)
        root_layout.setContentsMargins(16, 14, 16, 12)
        root_layout.setSpacing(10)

        root_layout.addLayout(self._build_header_row())

        self.table = self._build_table()
        root_layout.addWidget(self.table, stretch=1)

        root_layout.addLayout(self._build_action_row())

        self._build_status_bar()
        self._update_action_buttons()

    def _build_header_row(self) -> QHBoxLayout:
        row = QHBoxLayout()

        title = QLabel("Git Hub")
        title.setObjectName("headerLabel")
        row.addWidget(title)
        row.addStretch()

        self.search_box = QLineEdit()
        self.search_box.setPlaceholderText("Filter repos…")
        self.search_box.setFixedWidth(240)
        self.search_box.textChanged.connect(self._apply_filter)
        row.addWidget(self.search_box)

        self.rescan_btn = QPushButton("⟲ Rescan ~")
        self.rescan_btn.setToolTip(f"Re-scan {Path.home()} for git repositories")
        self.rescan_btn.clicked.connect(self.start_scan)
        row.addWidget(self.rescan_btn)

        self.add_repo_btn = QPushButton("+ Add Folder")
        self.add_repo_btn.setObjectName("accentButton")
        self.add_repo_btn.setToolTip("Track a folder outside your scan, or init a new repo")
        self.add_repo_btn.clicked.connect(self.browse_and_add_folder)
        row.addWidget(self.add_repo_btn)

        return row

    def _build_table(self) -> QTableWidget:
        table = QTableWidget(0, len(COLUMNS))
        table.setHorizontalHeaderLabels(COLUMNS)
        table.setColumnHidden(PATH_COLUMN, True)
        table.setEditTriggers(QAbstractItemView.NoEditTriggers)
        table.setSelectionBehavior(QAbstractItemView.SelectRows)
        table.setSelectionMode(QAbstractItemView.SingleSelection)
        table.setAlternatingRowColors(True)
        table.setSortingEnabled(True)
        table.verticalHeader().setVisible(False)

        header = table.horizontalHeader()
        header.setSectionResizeMode(0, QHeaderView.Stretch)
        for i in range(1, PATH_COLUMN):
            header.setSectionResizeMode(i, QHeaderView.ResizeToContents)

        table.itemSelectionChanged.connect(self._update_action_buttons)
        return table

    def _build_action_row(self) -> QHBoxLayout:
        row = QHBoxLayout()

        self.selected_label = QLabel("No repo selected")
        self.selected_label.setObjectName("subtleLabel")
        row.addWidget(self.selected_label)
        row.addStretch()

        self.init_btn = QPushButton("Init")
        self.init_btn.setToolTip("git init")
        self.init_btn.clicked.connect(self.action_init)

        self.add_btn = QPushButton("Add All")
        self.add_btn.setToolTip("git add -A")
        self.add_btn.clicked.connect(self.action_add_all)

        self.commit_btn = QPushButton("Commit")
        self.commit_btn.setToolTip("git commit -m …")
        self.commit_btn.clicked.connect(self.action_commit)

        self.pull_btn = QPushButton("Pull")
        self.pull_btn.setToolTip("git pull")
        self.pull_btn.clicked.connect(self.action_pull)

        self.push_btn = QPushButton("Push")
        self.push_btn.setToolTip("git push (sets upstream automatically if needed)")
        self.push_btn.clicked.connect(self.action_push)

        self.sync_btn = QPushButton("Pull + Push")
        self.sync_btn.setObjectName("accentButton")
        self.sync_btn.setToolTip("git pull, then git push")
        self.sync_btn.clicked.connect(self.action_pull_push)

        for btn in (self.init_btn, self.add_btn, self.commit_btn, self.pull_btn, self.push_btn, self.sync_btn):
            row.addWidget(btn)

        return row

    def _build_status_bar(self):
        self.status = QStatusBar()
        self.setStatusBar(self.status)

        self.summary_label = QLabel("")
        self.status.addWidget(self.summary_label, stretch=1)

        self.progress = QProgressBar()
        self.progress.setFixedWidth(160)
        self.progress.setRange(0, 0)  # indeterminate spinner
        self.progress.setVisible(False)
        self.status.addPermanentWidget(self.progress)

    # ------------------------------------------------------------ scanning
    def start_scan(self):
        if self._scan_worker and self._scan_worker.isRunning():
            return

        self.table.setRowCount(0)
        self._repos.clear()
        self.rescan_btn.setEnabled(False)
        self.progress.setVisible(True)
        self.status.showMessage(f"Scanning {Path.home()} …")

        self._scan_worker = ScanWorker(Path.home())
        self._scan_worker.repo_found.connect(self._on_repo_found)
        self._scan_worker.finished_scan.connect(self._on_scan_finished)
        self._scan_worker.start()

    @Slot(object)
    def _on_repo_found(self, status: RepoStatus):
        self._upsert_repo(status)

    @Slot(int)
    def _on_scan_finished(self, count: int):
        self.rescan_btn.setEnabled(True)
        self.progress.setVisible(False)
        plural = "y" if count == 1 else "ies"
        self.status.showMessage(f"Found {count} repositor{plural} under {Path.home()}", 5000)
        self._update_summary()

    # ----------------------------------------------------------- add folder
    def browse_and_add_folder(self):
        folder = QFileDialog.getExistingDirectory(self, "Select a folder", str(Path.home()))
        if not folder:
            return

        path = Path(folder)
        is_git_repo = (path / ".git").exists()

        if not is_git_repo:
            reply = QMessageBox.question(
                self,
                "Not a git repository",
                f"'{path.name}' isn't a git repo yet.\nRun 'git init' here now?",
                QMessageBox.Yes | QMessageBox.No,
            )
            if reply == QMessageBox.Yes:
                self._run_action(path, git_init, "init")
            return

        self._upsert_repo(get_repo_status(path))
        self._update_summary()

    # ---------------------------------------------------------- table sync
    def _upsert_repo(self, status: RepoStatus):
        key = str(status.path)
        self._repos[key] = status
        row = self._find_row(key)
        if row is None:
            row = self.table.rowCount()
            self.table.insertRow(row)

        self.table.setSortingEnabled(False)

        def set_item(col: int, text: str, color: str | None = None, center: bool = False):
            item = QTableWidgetItem(text)
            if color:
                item.setForeground(QColor(color))
            if center:
                item.setTextAlignment(Qt.AlignCenter)
            item.setFlags(item.flags() & ~Qt.ItemIsEditable)
            self.table.setItem(row, col, item)

        set_item(0, status.name)
        set_item(1, status.branch)
        set_item(2, "—" if status.error else str(status.staged), center=True,
                  color=MOCHA["peach"] if status.staged else None)
        set_item(3, "—" if status.error else str(status.unstaged), center=True,
                  color=MOCHA["yellow"] if status.unstaged else None)
        set_item(4, "—" if status.error else str(status.untracked), center=True,
                  color=MOCHA["overlay1"] if status.untracked else None)
        set_item(5, f"↑{status.ahead}" if status.ahead else "—", center=True,
                  color=MOCHA["blue"] if status.ahead else None)
        set_item(6, f"↓{status.behind}" if status.behind else "—", center=True,
                  color=MOCHA["peach"] if status.behind else None)

        state = status.state_label
        set_item(7, STATE_TEXT.get(state, state), color=STATE_COLORS.get(state), center=True)
        set_item(8, key)

        self.table.setSortingEnabled(True)
        self._update_action_buttons()

    def _find_row(self, key: str) -> int | None:
        for row in range(self.table.rowCount()):
            item = self.table.item(row, PATH_COLUMN)
            if item and item.text() == key:
                return row
        return None

    def _apply_filter(self, text: str):
        text = text.lower().strip()
        for row in range(self.table.rowCount()):
            name_item = self.table.item(row, 0)
            path_item = self.table.item(row, PATH_COLUMN)
            match = not text or text in name_item.text().lower() or text in path_item.text().lower()
            self.table.setRowHidden(row, not match)

    def _update_summary(self):
        total = len(self._repos)
        dirty = sum(1 for r in self._repos.values() if not r.error and not r.is_clean)
        errored = sum(1 for r in self._repos.values() if r.error)

        parts = [f"{total} repo{'s' if total != 1 else ''}"]
        if dirty:
            parts.append(f"{dirty} with changes")
        if errored:
            parts.append(f"{errored} errored")
        self.summary_label.setText(" · ".join(parts))

    # --------------------------------------------------------- selection
    def _selected_repo(self) -> RepoStatus | None:
        selection_model = self.table.selectionModel()
        if not selection_model:
            return None
        rows = selection_model.selectedRows()
        if not rows:
            return None
        path_item = self.table.item(rows[0].row(), PATH_COLUMN)
        if not path_item:
            return None
        return self._repos.get(path_item.text())

    def _update_action_buttons(self):
        repo = self._selected_repo()
        has_selection = repo is not None
        self.selected_label.setText(f"Selected: {repo.name}" if repo else "No repo selected")
        for btn in (self.init_btn, self.add_btn, self.commit_btn, self.pull_btn, self.push_btn, self.sync_btn):
            btn.setEnabled(has_selection)
        for action in self._git_menu_actions:
            action.setEnabled(has_selection)

    # ------------------------------------------------------------ actions
    def _run_action(self, path: Path, fn, label: str):
        self.status.showMessage(f"Running git {label} in {path.name} …")
        worker = ActionWorker(path, fn)
        worker.succeeded.connect(self._on_action_succeeded)
        worker.failed.connect(self._on_action_failed)
        worker.finished.connect(lambda w=worker: self._forget_worker(w))
        self._action_workers.append(worker)
        worker.start()

    def _forget_worker(self, worker: ActionWorker):
        if worker in self._action_workers:
            self._action_workers.remove(worker)

    @Slot(object, str)
    def _on_action_succeeded(self, status: RepoStatus, output: str):
        self._upsert_repo(status)
        self._update_summary()
        first_line = output.splitlines()[0] if output else "done"
        self.status.showMessage(f"{status.name}: {first_line}", 6000)

    @Slot(object, str)
    def _on_action_failed(self, path: Path, error: str):
        first_line = error.splitlines()[0] if error else "unknown error"
        self.status.showMessage(f"Failed: {first_line}", 8000)
        QMessageBox.warning(self, "Git command failed", error)

    def action_init(self):
        repo = self._selected_repo()
        if repo:
            self._run_action(repo.path, git_init, "init")

    def action_add_all(self):
        repo = self._selected_repo()
        if repo:
            self._run_action(repo.path, git_add_all, "add")

    def action_commit(self):
        repo = self._selected_repo()
        if not repo:
            return

        dialog = CommitDialog(repo.name, self)
        if dialog.exec() != CommitDialog.Accepted:
            return

        message = dialog.message
        stage_all = dialog.stage_all

        def commit_flow(path: Path) -> str:
            out_lines = []
            if stage_all:
                out_lines.append(git_add_all(path))
            out_lines.append(git_commit(path, message))
            return "\n".join(line for line in out_lines if line)

        self._run_action(repo.path, commit_flow, "commit")

    def action_pull(self):
        repo = self._selected_repo()
        if repo:
            self._run_action(repo.path, git_pull, "pull")

    def action_push(self):
        repo = self._selected_repo()
        if repo:
            self._run_action(repo.path, git_push, "push")

    def action_pull_push(self):
        repo = self._selected_repo()
        if repo:
            self._run_action(repo.path, git_pull_push, "pull + push")

    # --------------------------------------------------------------- close
    def closeEvent(self, event):
        if self._scan_worker and self._scan_worker.isRunning():
            self._scan_worker.cancel()
            self._scan_worker.wait(2000)
        for worker in list(self._action_workers):
            worker.wait(2000)
        event.accept()
