"""Modal dialog for entering a commit message, with an optional stage-all toggle."""
from __future__ import annotations

from PySide6.QtWidgets import (
    QCheckBox,
    QDialog,
    QDialogButtonBox,
    QLabel,
    QPlainTextEdit,
    QVBoxLayout,
)


class CommitDialog(QDialog):
    def __init__(self, repo_name: str, parent=None):
        super().__init__(parent)
        self.setWindowTitle(f"Commit — {repo_name}")
        self.setMinimumWidth(440)
        self.setModal(True)

        layout = QVBoxLayout(self)
        layout.setSpacing(10)

        layout.addWidget(QLabel(f"Commit message for <b>{repo_name}</b>:"))

        self.message_edit = QPlainTextEdit()
        self.message_edit.setPlaceholderText("Describe what changed…")
        self.message_edit.setFixedHeight(90)
        layout.addWidget(self.message_edit)

        self.stage_all_checkbox = QCheckBox("Stage all changes before committing (git add -A)")
        self.stage_all_checkbox.setChecked(True)
        layout.addWidget(self.stage_all_checkbox)

        hint = QLabel("Tip: uncheck this if you've already staged exactly what you want.")
        hint.setObjectName("dialogHint")
        hint.setWordWrap(True)
        layout.addWidget(hint)

        buttons = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        ok_button = buttons.button(QDialogButtonBox.Ok)
        ok_button.setText("Commit")
        ok_button.setObjectName("accentButton")
        buttons.accepted.connect(self._on_accept)
        buttons.rejected.connect(self.reject)
        layout.addWidget(buttons)

        self.message_edit.setFocus()

    def _on_accept(self):
        if not self.message:
            self.message_edit.setStyleSheet("border: 1px solid #f38ba8;")
            return
        self.accept()

    @property
    def message(self) -> str:
        return self.message_edit.toPlainText().strip()

    @property
    def stage_all(self) -> bool:
        return self.stage_all_checkbox.isChecked()
