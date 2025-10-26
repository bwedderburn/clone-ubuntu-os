"""Tkinter UI module for the sample app."""

from __future__ import annotations

import datetime as _dt
import tkinter as tk
from tkinter import ttk


class ClockFrame(ttk.Frame):
  """Simple frame showing live clock and greeting, to mimic modular GUI."""

  def __init__(self, master: tk.Misc, *, greeting: str = "Hello") -> None:
    super().__init__(master, padding=16)
    self._greeting = greeting

    self.columnconfigure(0, weight=1)
    self._title = ttk.Label(self, text=f"{self._greeting} from sample_app", font=("Helvetica", 16, "bold"))
    self._title.grid(row=0, column=0, pady=(0, 12))

    self._time_var = tk.StringVar(value="")
    self._time_label = ttk.Label(self, textvariable=self._time_var, font=("Helvetica", 36))
    self._time_label.grid(row=1, column=0, pady=(0, 16))

    self._update_clock()

  def _update_clock(self) -> None:
    now = _dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    self._time_var.set(now)
    # reschedule update
    self.after(1000, self._update_clock)


def build_app() -> tk.Tk:
  """Factory that builds the Tk root window and packs content."""
  root = tk.Tk()
  root.title("Sample Python GUI")
  root.geometry("480x300")
  root.configure(padx=12, pady=12)

  style = ttk.Style(root)
  if "clam" in style.theme_names():
    style.theme_use("clam")

  clock = ClockFrame(root, greeting="Welcome")
  clock.pack(expand=True, fill="both")
  return root
