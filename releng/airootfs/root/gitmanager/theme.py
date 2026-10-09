"""Catppuccin Mocha color palette and a matching Qt stylesheet, mauve accent.

Palette reference: https://github.com/catppuccin/catppuccin (Mocha flavor)
"""

MOCHA = {
    "rosewater": "#f5e0dc",
    "flamingo": "#f2cdcd",
    "pink": "#f5c2e7",
    "mauve": "#cba6f7",
    "red": "#f38ba8",
    "maroon": "#eba0ac",
    "peach": "#fab387",
    "yellow": "#f9e2af",
    "green": "#a6e3a1",
    "teal": "#94e2d5",
    "sky": "#89dceb",
    "sapphire": "#74c7ec",
    "blue": "#89b4fa",
    "lavender": "#b4befe",
    "text": "#cdd6f4",
    "subtext1": "#bac2de",
    "subtext0": "#a6adc8",
    "overlay2": "#9399b2",
    "overlay1": "#7f849c",
    "overlay0": "#6c7086",
    "surface2": "#585b70",
    "surface1": "#45475a",
    "surface0": "#313244",
    "base": "#1e1e2e",
    "mantle": "#181825",
    "crust": "#11111b",
}

ACCENT = MOCHA["mauve"]
ACCENT_HOVER = MOCHA["pink"]
ACCENT_PRESSED = "#a884e0"  # slightly darker mauve for the pressed state

# Maps a repo's computed state to a palette color, used in the status column
# and for tinting non-zero staged/unstaged/untracked/ahead/behind counts.
STATE_COLORS = {
    "clean": MOCHA["green"],
    "dirty": MOCHA["yellow"],
    "ahead": MOCHA["blue"],
    "behind": MOCHA["peach"],
    "diverged": MOCHA["red"],
    "error": MOCHA["red"],
}


def stylesheet() -> str:
    c = MOCHA
    return f"""
    * {{
        font-family: "Cantarell", "Noto Sans", "Segoe UI", sans-serif;
        font-size: 13px;
        color: {c['text']};
    }}

    QMainWindow, QDialog {{
        background-color: {c['base']};
    }}

    QWidget#centralWidget {{
        background-color: {c['base']};
    }}

    QMenuBar {{
        background-color: {c['mantle']};
        color: {c['text']};
        border-bottom: 1px solid {c['surface0']};
        padding: 2px;
    }}
    QMenuBar::item {{
        background: transparent;
        padding: 4px 10px;
        border-radius: 4px;
    }}
    QMenuBar::item:selected {{
        background-color: {c['surface0']};
    }}
    QMenu {{
        background-color: {c['mantle']};
        border: 1px solid {c['surface0']};
        padding: 4px;
    }}
    QMenu::item {{
        padding: 6px 24px 6px 12px;
        border-radius: 4px;
    }}
    QMenu::item:selected {{
        background-color: {ACCENT};
        color: {c['crust']};
    }}

    QToolBar {{
        background-color: {c['mantle']};
        border: none;
        padding: 6px;
        spacing: 6px;
    }}

    QStatusBar {{
        background-color: {c['mantle']};
        color: {c['subtext0']};
        border-top: 1px solid {c['surface0']};
    }}
    QStatusBar::item {{
        border: none;
    }}

    QLabel {{
        color: {c['text']};
        background: transparent;
    }}
    QLabel#subtleLabel {{
        color: {c['subtext0']};
    }}
    QLabel#headerLabel {{
        color: {ACCENT};
        font-size: 19px;
        font-weight: 700;
    }}
    QLabel#dialogHint {{
        color: {c['subtext0']};
    }}

    QPushButton {{
        background-color: {c['surface0']};
        color: {c['text']};
        border: 1px solid {c['surface1']};
        border-radius: 6px;
        padding: 6px 14px;
    }}
    QPushButton:hover {{
        background-color: {c['surface1']};
        border-color: {ACCENT};
    }}
    QPushButton:pressed {{
        background-color: {c['surface2']};
    }}
    QPushButton:disabled {{
        color: {c['overlay0']};
        background-color: {c['mantle']};
        border-color: {c['surface0']};
    }}

    QPushButton#accentButton {{
        background-color: {ACCENT};
        color: {c['crust']};
        border: none;
        font-weight: 600;
    }}
    QPushButton#accentButton:hover {{
        background-color: {ACCENT_HOVER};
    }}
    QPushButton#accentButton:pressed {{
        background-color: {ACCENT_PRESSED};
    }}
    QPushButton#accentButton:disabled {{
        background-color: {c['surface1']};
        color: {c['overlay0']};
    }}

    QPushButton#dangerHover:hover {{
        border-color: {c['red']};
        color: {c['red']};
    }}

    QLineEdit, QTextEdit, QPlainTextEdit {{
        background-color: {c['mantle']};
        border: 1px solid {c['surface1']};
        border-radius: 6px;
        padding: 6px 8px;
        selection-background-color: {ACCENT};
        selection-color: {c['crust']};
    }}
    QLineEdit:focus, QTextEdit:focus, QPlainTextEdit:focus {{
        border-color: {ACCENT};
    }}

    QTableWidget {{
        background-color: {c['mantle']};
        alternate-background-color: {c['base']};
        gridline-color: {c['surface0']};
        border: 1px solid {c['surface0']};
        border-radius: 8px;
        selection-background-color: {c['surface1']};
        selection-color: {c['text']};
    }}
    QTableWidget::item {{
        padding: 7px 6px;
        border: none;
    }}
    QTableWidget::item:selected {{
        background-color: {c['surface1']};
    }}
    QHeaderView::section {{
        background-color: {c['mantle']};
        color: {c['subtext1']};
        padding: 9px 6px;
        border: none;
        border-bottom: 2px solid {ACCENT};
        font-weight: 600;
    }}
    QTableCornerButton::section {{
        background-color: {c['mantle']};
        border: none;
    }}

    QScrollBar:vertical {{
        background: {c['mantle']};
        width: 12px;
        margin: 0;
    }}
    QScrollBar::handle:vertical {{
        background: {c['surface1']};
        border-radius: 5px;
        min-height: 30px;
    }}
    QScrollBar::handle:vertical:hover {{
        background: {ACCENT};
    }}
    QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical {{
        height: 0;
    }}
    QScrollBar:horizontal {{
        background: {c['mantle']};
        height: 12px;
    }}
    QScrollBar::handle:horizontal {{
        background: {c['surface1']};
        border-radius: 5px;
        min-width: 30px;
    }}
    QScrollBar::handle:horizontal:hover {{
        background: {ACCENT};
    }}
    QScrollBar::add-line:horizontal, QScrollBar::sub-line:horizontal {{
        width: 0;
    }}

    QProgressBar {{
        background-color: {c['mantle']};
        border: 1px solid {c['surface1']};
        border-radius: 6px;
        text-align: center;
        color: {c['text']};
    }}
    QProgressBar::chunk {{
        background-color: {ACCENT};
        border-radius: 5px;
    }}

    QToolTip {{
        background-color: {c['surface0']};
        color: {c['text']};
        border: 1px solid {ACCENT};
        padding: 4px 8px;
        border-radius: 4px;
    }}

    QSplitter::handle {{
        background-color: {c['surface0']};
    }}

    QCheckBox {{
        spacing: 8px;
    }}
    QCheckBox::indicator {{
        width: 16px;
        height: 16px;
        border: 1px solid {c['surface2']};
        border-radius: 4px;
        background: {c['mantle']};
    }}
    QCheckBox::indicator:checked {{
        background-color: {ACCENT};
        border-color: {ACCENT};
    }}

    QMessageBox {{
        background-color: {c['base']};
    }}
    """
