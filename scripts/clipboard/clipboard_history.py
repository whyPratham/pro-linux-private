#!/usr/bin/env python3
"""
Clipboard History Applet
A modern, lightweight clipboard manager for Linux desktops.
Built with GTK4 + PyGObject. Follows Catppuccin Mocha design language.

Author: Punit | PRO Linux Project
"""

import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
gi.require_version("Notify", "0.7")

from gi.repository import Gtk, Gdk, GLib, Gio, Pango
import json
import os
import time
import threading
from datetime import datetime
from typing import Optional

try:
    from gi.repository import Notify
    NOTIFY_AVAILABLE = True
except Exception:
    NOTIFY_AVAILABLE = False

# ─── Constants ────────────────────────────────────────────────────────────────

APP_ID        = "io.github.prolinux.ClipboardHistory"
APP_NAME      = "Clipboard History"
VERSION       = "1.0.0"
MAX_ITEMS     = 100
POLL_INTERVAL = 800   # ms — lightweight polling

DATA_DIR  = os.path.join(GLib.get_user_data_dir(), "clipboard-history")
DATA_FILE = os.path.join(DATA_DIR, "history.json")
CSS_FILE  = os.path.join(os.path.dirname(__file__), "style.css")

# Catppuccin Mocha palette
MOCHA = {
    "base":    "#1e1e2e",
    "mantle":  "#181825",
    "crust":   "#11111b",
    "surface0": "#313244",
    "surface1": "#45475a",
    "surface2": "#585b70",
    "overlay0": "#6c7086",
    "overlay1": "#7f849c",
    "text":    "#cdd6f4",
    "subtext0": "#a6adc8",
    "mauve":   "#cba6f7",
    "lavender": "#b4befe",
    "blue":    "#89b4fa",
    "green":   "#a6e3a1",
    "red":     "#f38ba8",
    "yellow":  "#f9e2af",
    "peach":   "#fab387",
}

CSS = f"""
/* ── Catppuccin Mocha — Clipboard History ── */

window, .view {{
    background-color: {MOCHA['base']};
    color: {MOCHA['text']};
}}

headerbar {{
    background-color: {MOCHA['mantle']};
    border-bottom: 1px solid {MOCHA['surface0']};
    min-height: 52px;
}}

headerbar .title-widget label {{
    color: {MOCHA['text']};
    font-weight: 600;
    font-size: 15px;
    letter-spacing: -0.2px;
}}

/* Search entry */
.search-entry {{
    background-color: {MOCHA['surface0']};
    border: 1.5px solid {MOCHA['surface1']};
    border-radius: 10px;
    color: {MOCHA['text']};
    padding: 6px 12px;
    min-width: 220px;
    font-size: 13.5px;
    transition: border-color 150ms ease;
}}

.search-entry:focus {{
    border-color: {MOCHA['mauve']};
    outline: none;
    box-shadow: 0 0 0 2px alpha({MOCHA['mauve']}, 0.18);
}}

.search-entry placeholder {{
    color: {MOCHA['overlay0']};
}}

/* Scrolled list area */
scrolledwindow {{
    background-color: {MOCHA['base']};
}}

/* Section label */
.section-label {{
    color: {MOCHA['overlay1']};
    font-size: 11px;
    font-weight: 600;
    letter-spacing: 0.8px;
    padding: 10px 18px 4px;
}}

/* Clip card */
.clip-card {{
    background-color: {MOCHA['surface0']};
    border: 1px solid {MOCHA['surface1']};
    border-radius: 12px;
    margin: 4px 14px;
    padding: 12px 14px;
    transition: background-color 120ms ease, border-color 120ms ease;
}}

.clip-card:hover {{
    background-color: {MOCHA['surface1']};
    border-color: {MOCHA['overlay0']};
}}

.clip-card.pinned {{
    border-color: {MOCHA['mauve']};
    background-color: alpha({MOCHA['mauve']}, 0.08);
}}

.clip-card.pinned:hover {{
    background-color: alpha({MOCHA['mauve']}, 0.14);
}}

/* Card text */
.clip-text {{
    color: {MOCHA['text']};
    font-size: 13.5px;
    line-height: 1.45;
}}

.clip-meta {{
    color: {MOCHA['overlay0']};
    font-size: 11px;
    margin-top: 2px;
}}

/* Action buttons */
.clip-action {{
    background: transparent;
    border: none;
    border-radius: 8px;
    padding: 4px 6px;
    color: {MOCHA['overlay1']};
    min-width: 0;
    min-height: 0;
    transition: background-color 120ms ease, color 120ms ease;
}}

.clip-action:hover {{
    background-color: {MOCHA['surface2']};
    color: {MOCHA['text']};
}}

.clip-action.copy-btn:hover {{
    color: {MOCHA['blue']};
    background-color: alpha({MOCHA['blue']}, 0.12);
}}

.clip-action.pin-btn:hover, .clip-action.pin-btn.active {{
    color: {MOCHA['mauve']};
    background-color: alpha({MOCHA['mauve']}, 0.12);
}}

.clip-action.pin-btn.active {{
    color: {MOCHA['mauve']};
}}

.clip-action.delete-btn:hover {{
    color: {MOCHA['red']};
    background-color: alpha({MOCHA['red']}, 0.12);
}}

/* Clear all button */
.clear-btn {{
    background-color: alpha({MOCHA['red']}, 0.14);
    color: {MOCHA['red']};
    border: 1px solid alpha({MOCHA['red']}, 0.3);
    border-radius: 9px;
    padding: 5px 13px;
    font-size: 13px;
    font-weight: 500;
    transition: background-color 120ms ease;
}}

.clear-btn:hover {{
    background-color: alpha({MOCHA['red']}, 0.24);
    border-color: {MOCHA['red']};
}}

/* Empty state */
.empty-icon {{
    color: {MOCHA['surface2']};
    margin-bottom: 14px;
}}

.empty-title {{
    color: {MOCHA['subtext0']};
    font-size: 16px;
    font-weight: 600;
    margin-bottom: 6px;
}}

.empty-subtitle {{
    color: {MOCHA['overlay0']};
    font-size: 13px;
}}

/* Count badge */
.count-badge {{
    background-color: {MOCHA['surface1']};
    color: {MOCHA['overlay1']};
    border-radius: 20px;
    padding: 2px 10px;
    font-size: 11.5px;
    font-weight: 500;
}}

/* Separator */
separator {{
    background-color: {MOCHA['surface0']};
    min-height: 1px;
    margin: 2px 0;
}}

/* Toast / notification bar */
.toast-bar {{
    background-color: {MOCHA['surface1']};
    color: {MOCHA['text']};
    border-radius: 10px;
    border: 1px solid {MOCHA['surface2']};
    padding: 8px 16px;
    font-size: 13px;
}}
"""


# ─── Data Layer ───────────────────────────────────────────────────────────────

class ClipboardEntry:
    """A single clipboard history entry."""

    def __init__(self, text: str, timestamp: float = None,
                 pinned: bool = False):
        self.text      = text
        self.timestamp = timestamp or time.time()
        self.pinned    = pinned

    def preview(self, max_len: int = 120) -> str:
        """Return a clean single-line preview of the text."""
        cleaned = " ".join(self.text.split())
        if len(cleaned) > max_len:
            return cleaned[:max_len] + "…"
        return cleaned

    def time_label(self) -> str:
        """Return a human-readable relative timestamp."""
        delta = time.time() - self.timestamp
        if delta < 60:
            return "just now"
        if delta < 3600:
            return f"{int(delta // 60)}m ago"
        if delta < 86400:
            return f"{int(delta // 3600)}h ago"
        return datetime.fromtimestamp(self.timestamp).strftime("%d %b")

    def char_count(self) -> str:
        lines = self.text.count("\n") + 1
        chars = len(self.text)
        if lines > 1:
            return f"{chars} chars · {lines} lines"
        return f"{chars} chars"

    def to_dict(self) -> dict:
        return {
            "text":      self.text,
            "timestamp": self.timestamp,
            "pinned":    self.pinned,
        }

    @classmethod
    def from_dict(cls, d: dict) -> "ClipboardEntry":
        return cls(
            text      = d["text"],
            timestamp = d.get("timestamp", time.time()),
            pinned    = d.get("pinned", False),
        )


class HistoryStore:
    """Manages in-memory history and JSON persistence."""

    def __init__(self):
        self.entries: list[ClipboardEntry] = []
        os.makedirs(DATA_DIR, exist_ok=True)
        self.load()

    def add(self, text: str) -> bool:
        """Add a new entry. Returns True if actually added."""
        text = text.strip()
        if not text:
            return False
        # Avoid consecutive duplicates
        unpinned = [e for e in self.entries if not e.pinned]
        if unpinned and unpinned[0].text == text:
            return False
        # Remove duplicate if exists anywhere
        self.entries = [e for e in self.entries if e.text != text or e.pinned]
        # Insert at front of unpinned section
        insert_at = 0
        for i, e in enumerate(self.entries):
            if not e.pinned:
                insert_at = i
                break
            insert_at = i + 1
        self.entries.insert(insert_at, ClipboardEntry(text))
        # Trim unpinned to MAX_ITEMS
        unpinned = [e for e in self.entries if not e.pinned]
        if len(unpinned) > MAX_ITEMS:
            oldest = unpinned[-1]
            self.entries.remove(oldest)
        self.save()
        return True

    def remove(self, entry: ClipboardEntry):
        if entry in self.entries:
            self.entries.remove(entry)
            self.save()

    def clear_unpinned(self):
        self.entries = [e for e in self.entries if e.pinned]
        self.save()

    def toggle_pin(self, entry: ClipboardEntry):
        entry.pinned = not entry.pinned
        # Re-sort: pinned first
        self.entries.sort(key=lambda e: (0 if e.pinned else 1, 0))
        self.save()

    def filtered(self, query: str) -> list[ClipboardEntry]:
        if not query:
            return list(self.entries)
        q = query.lower()
        return [e for e in self.entries if q in e.text.lower()]

    def save(self):
        try:
            data = [e.to_dict() for e in self.entries]
            with open(DATA_FILE, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
        except Exception as ex:
            print(f"[ClipHist] Save error: {ex}")

    def load(self):
        if not os.path.exists(DATA_FILE):
            return
        try:
            with open(DATA_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
            self.entries = [ClipboardEntry.from_dict(d) for d in data]
        except Exception as ex:
            print(f"[ClipHist] Load error: {ex}")


# ─── UI Components ────────────────────────────────────────────────────────────

class ClipCard(Gtk.Box):
    """A single clipboard entry card with actions."""

    def __init__(self, entry: ClipboardEntry, on_copy, on_pin, on_delete):
        super().__init__(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        self.entry     = entry
        self._on_copy  = on_copy
        self._on_pin   = on_pin
        self._on_delete = on_delete

        self.add_css_class("clip-card")
        if entry.pinned:
            self.add_css_class("pinned")

        self._build()

    def _build(self):
        # ── Text column ──
        text_col = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=1)
        text_col.set_hexpand(True)

        preview = Gtk.Label(label=self.entry.preview())
        preview.add_css_class("clip-text")
        preview.set_xalign(0)
        preview.set_ellipsize(Pango.EllipsizeMode.END)
        preview.set_max_width_chars(80)
        text_col.append(preview)

        meta_str = f"{self.entry.time_label()} · {self.entry.char_count()}"
        if self.entry.pinned:
            meta_str = "📌 Pinned · " + meta_str
        meta = Gtk.Label(label=meta_str)
        meta.add_css_class("clip-meta")
        meta.set_xalign(0)
        text_col.append(meta)

        self.append(text_col)

        # ── Actions column ──
        actions = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=2)
        actions.set_valign(Gtk.Align.CENTER)

        self.pin_btn = self._make_btn(
            "view-pin-symbolic" if self.entry.pinned else "view-pin-symbolic",
            "🔖" if not self.entry.pinned else "📌",
            "Unpin" if self.entry.pinned else "Pin",
            "pin-btn",
            self._pin_clicked,
        )
        if self.entry.pinned:
            self.pin_btn.add_css_class("active")

        copy_btn = self._make_btn(
            "edit-copy-symbolic", "⎘", "Copy", "copy-btn", self._copy_clicked
        )
        del_btn = self._make_btn(
            "edit-delete-symbolic", "🗑", "Delete", "delete-btn",
            self._delete_clicked
        )

        actions.append(self.pin_btn)
        actions.append(copy_btn)
        actions.append(del_btn)
        self.append(actions)

    def _make_btn(self, icon_name, fallback_label,
                  tooltip, css_class, handler) -> Gtk.Button:
        btn = Gtk.Button()
        btn.set_tooltip_text(tooltip)
        btn.add_css_class("clip-action")
        btn.add_css_class(css_class)
        btn.connect("clicked", handler)

        # Try icon; fall back to emoji label
        try:
            icon = Gtk.Image.new_from_icon_name(icon_name)
            icon.set_icon_size(Gtk.IconSize.NORMAL)
            btn.set_child(icon)
        except Exception:
            btn.set_label(fallback_label)

        return btn

    def _copy_clicked(self, _btn):
        self._on_copy(self.entry)

    def _pin_clicked(self, _btn):
        self._on_pin(self.entry)

    def _delete_clicked(self, _btn):
        self._on_delete(self.entry)


class EmptyState(Gtk.Box):
    """Shown when there are no clipboard entries."""

    def __init__(self):
        super().__init__(
            orientation=Gtk.Orientation.VERTICAL,
            spacing=6,
        )
        self.set_valign(Gtk.Align.CENTER)
        self.set_vexpand(True)
        self.set_margin_top(60)
        self.set_margin_bottom(60)

        icon = Gtk.Label(label="📋")
        icon.add_css_class("empty-icon")
        # Large emoji via markup
        icon.set_markup('<span size="xx-large">📋</span>')
        self.append(icon)

        title = Gtk.Label(label="Nothing here yet")
        title.add_css_class("empty-title")
        self.append(title)

        sub = Gtk.Label(
            label="Copy something and it will appear here."
        )
        sub.add_css_class("empty-subtitle")
        sub.set_justify(Gtk.Justification.CENTER)
        self.append(sub)


# ─── Main Window ──────────────────────────────────────────────────────────────

class ClipboardWindow(Gtk.ApplicationWindow):
    """Main application window."""

    def __init__(self, app: Gtk.Application, store: HistoryStore):
        super().__init__(application=app, title=APP_NAME)
        self.store        = store
        self._search_text = ""
        self._clipboard   = Gdk.Display.get_default().get_clipboard()
        self._last_text   = ""

        self.set_default_size(520, 680)
        self.set_resizable(True)

        self._apply_css()
        self._build_ui()
        self._start_monitor()

    # ── CSS ──

    def _apply_css(self):
        provider = Gtk.CssProvider()
        provider.load_from_string(CSS)
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )

    # ── UI Layout ──

    def _build_ui(self):
        # Header bar
        header = Gtk.HeaderBar()
        header.set_show_title_buttons(True)

        # Title
        title_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        title_lbl = Gtk.Label(label="Clipboard History")
        title_lbl.add_css_class("title")
        title_box.append(title_lbl)

        self.count_badge = Gtk.Label(label="0")
        self.count_badge.add_css_class("count-badge")
        title_box.append(self.count_badge)
        header.set_title_widget(title_box)

        # Search
        self.search = Gtk.SearchEntry()
        self.search.add_css_class("search-entry")
        self.search.set_placeholder_text("Search clipboard…")
        self.search.connect("search-changed", self._on_search)
        header.pack_start(self.search)

        # Clear all
        clear_btn = Gtk.Button(label="Clear All")
        clear_btn.add_css_class("clear-btn")
        clear_btn.set_tooltip_text("Clear all unpinned entries")
        clear_btn.connect("clicked", self._on_clear_all)
        header.pack_end(clear_btn)

        self.set_titlebar(header)

        # ── Main scroll area ──
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scroll.set_vexpand(True)

        self.list_box = Gtk.Box(
            orientation=Gtk.Orientation.VERTICAL,
            spacing=0,
        )
        self.list_box.set_margin_top(6)
        self.list_box.set_margin_bottom(12)

        scroll.set_child(self.list_box)
        self.set_child(scroll)

        self._refresh_list()

    # ── List Rendering ──

    def _refresh_list(self):
        """Rebuild the list from store, applying current search filter."""
        # Clear existing
        while True:
            child = self.list_box.get_first_child()
            if child is None:
                break
            self.list_box.remove(child)

        entries = self.store.filtered(self._search_text)
        self._update_badge(len(entries))

        if not entries:
            self.list_box.append(EmptyState())
            return

        # Pinned section
        pinned   = [e for e in entries if e.pinned]
        unpinned = [e for e in entries if not e.pinned]

        if pinned:
            self._add_section_label("Pinned")
            for entry in pinned:
                self.list_box.append(self._make_card(entry))

        if unpinned:
            if pinned:
                sep = Gtk.Separator()
                sep.set_margin_top(6)
                sep.set_margin_bottom(6)
                self.list_box.append(sep)
            self._add_section_label("Recent")
            for entry in unpinned:
                self.list_box.append(self._make_card(entry))

    def _add_section_label(self, text: str):
        lbl = Gtk.Label(label=text.upper())
        lbl.add_css_class("section-label")
        lbl.set_xalign(0)
        self.list_box.append(lbl)

    def _make_card(self, entry: ClipboardEntry) -> ClipCard:
        card = ClipCard(
            entry,
            on_copy   = self._on_copy,
            on_pin    = self._on_pin,
            on_delete = self._on_delete,
        )
        # Make whole card clickable to copy
        click = Gtk.GestureClick()
        click.connect("released", lambda g, n, x, y: self._on_copy(entry))
        card.add_controller(click)
        return card

    def _update_badge(self, count: int):
        self.count_badge.set_text(str(count))

    # ── Clipboard Monitor ──

    def _start_monitor(self):
        """Poll clipboard every POLL_INTERVAL ms on main thread via GLib."""
        GLib.timeout_add(POLL_INTERVAL, self._poll_clipboard)

    def _poll_clipboard(self) -> bool:
        """Check clipboard for new text. Returns True to keep polling."""
        self._clipboard.read_text_async(None, self._on_clipboard_read)
        return True  # keep timer alive

    def _on_clipboard_read(self, clipboard, result):
        try:
            text = clipboard.read_text_finish(result)
        except Exception:
            return
        if not text or text == self._last_text:
            return
        self._last_text = text
        if self.store.add(text):
            GLib.idle_add(self._refresh_list)

    # ── Action Handlers ──

    def _on_copy(self, entry: ClipboardEntry):
        """Copy an entry back to clipboard."""
        self._last_text = entry.text          # prevent re-adding same text
        self._clipboard.set(entry.text)
        self._show_toast("Copied to clipboard")

    def _on_pin(self, entry: ClipboardEntry):
        self.store.toggle_pin(entry)
        GLib.idle_add(self._refresh_list)

    def _on_delete(self, entry: ClipboardEntry):
        self.store.remove(entry)
        GLib.idle_add(self._refresh_list)

    def _on_clear_all(self, _btn):
        dialog = Gtk.MessageDialog(
            transient_for = self,
            modal         = True,
            message_type  = Gtk.MessageType.WARNING,
            buttons       = Gtk.ButtonsType.OK_CANCEL,
            text          = "Clear clipboard history?",
        )
        dialog.set_secondary_text(
            "All unpinned entries will be removed. "
            "Pinned items will be kept."
        )
        dialog.connect("response", self._on_clear_response)
        dialog.present()

    def _on_clear_response(self, dialog, response):
        dialog.destroy()
        if response == Gtk.ResponseType.OK:
            self.store.clear_unpinned()
            GLib.idle_add(self._refresh_list)
            self._notify("Clipboard history cleared.")
            self._show_toast("History cleared")

    def _on_search(self, entry):
        self._search_text = entry.get_text()
        self._refresh_list()

    # ── Toast & Notifications ──

    def _show_toast(self, message: str):
        """Show a subtle in-window status message."""
        # We use the window title area briefly
        pass  # GTK4 Adw.Toast would require libadwaita — keeping it simple

    def _notify(self, message: str):
        if not NOTIFY_AVAILABLE:
            return
        try:
            Notify.init(APP_NAME)
            n = Notify.Notification.new(APP_NAME, message, "edit-paste")
            n.set_urgency(Notify.Urgency.LOW)
            n.show()
        except Exception:
            pass


# ─── Application ──────────────────────────────────────────────────────────────

class ClipboardApp(Gtk.Application):
    """GTK4 Application entry point."""

    def __init__(self):
        super().__init__(
            application_id = APP_ID,
            flags          = Gio.ApplicationFlags.DEFAULT_FLAGS,
        )
        self.store  = HistoryStore()
        self.window = None

        self.connect("activate", self._on_activate)

    def _on_activate(self, app):
        if self.window:
            self.window.present()
            return
        self.window = ClipboardWindow(app, self.store)
        self.window.present()


# ─── Entry Point ──────────────────────────────────────────────────────────────

def main():
    app = ClipboardApp()
    return app.run()


if __name__ == "__main__":
    raise SystemExit(main())
