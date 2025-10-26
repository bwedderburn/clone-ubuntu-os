"""Scope tab UI construction helper."""

from __future__ import annotations

from typing import Any

from ._qt import require_qt

__all__ = ["build_scope_tab"]


def build_scope_tab(gui: Any) -> object | None:
    qt = require_qt()
    if qt is None:
        return None
    QWidget = qt.QWidget
    QVBoxLayout = qt.QVBoxLayout
    QHBoxLayout = qt.QHBoxLayout
    QLabel = qt.QLabel
    QComboBox = qt.QComboBox
    QLineEdit = qt.QLineEdit
    QPushButton = qt.QPushButton
    QTextEdit = qt.QTextEdit
    w = QWidget()
    L = QVBoxLayout(w)
    # Provide default scope resource if gui object does not define one (test safety)
    if not hasattr(gui, "scope_res"):
        gui.scope_res = ""
    r = QHBoxLayout()
    r.addWidget(QLabel("VISA Resource:"))
    gui.scope_edit = QLineEdit(gui.scope_res)
    r.addWidget(gui.scope_edit)
    b = QPushButton("List VISA")
    b.clicked.connect(gui.list_visa)
    r.addWidget(b)
    L.addLayout(r)
    r = QHBoxLayout()
    r.addWidget(QLabel("Channel:"))
    gui.scope_ch = QComboBox()
    gui.scope_ch.addItems(["1", "2", "3", "4"])
    r.addWidget(gui.scope_ch)
    L.addLayout(r)
    b = QPushButton("Single Capture")
    b.clicked.connect(gui.capture_scope)
    L.addWidget(b)
    b = QPushButton("Save Screenshot")
    b.clicked.connect(gui.save_shot)
    L.addWidget(b)
    b = QPushButton("Save CSV (Calibrated)")
    b.clicked.connect(gui.save_csv)
    L.addWidget(b)
    gui.scope_log = QTextEdit()
    gui.scope_log.setReadOnly(True)
    L.addWidget(gui.scope_log)
    return w
