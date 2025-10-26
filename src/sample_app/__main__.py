"""Entry-point wiring for the sample Tkinter app."""

from .gui import build_app


def main() -> None:
  app = build_app()
  app.mainloop()


if __name__ == "__main__":
  main()
