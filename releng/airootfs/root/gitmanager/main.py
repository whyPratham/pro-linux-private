#!/usr/bin/env python3
"""Git Hub — a desktop GUI for managing every git repo under your home directory.

Scans ~ for repositories, shows each one's branch, staged/unstaged/untracked
file counts and ahead/behind status, and lets you init, add, commit, pull,
and push straight from buttons.

Run with:  python main.py
"""
import sys

from PySide6.QtWidgets import QApplication

from theme import stylesheet
from ui.main_window import MainWindow


def main():
    app = QApplication(sys.argv)
    app.setApplicationName("Git Hub")
    app.setStyleSheet(stylesheet())

    window = MainWindow()
    window.show()

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
