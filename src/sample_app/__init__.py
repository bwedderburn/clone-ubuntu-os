"""Sample modular GUI package to demonstrate packaging workflow."""

from importlib.metadata import version, PackageNotFoundError

__all__ = ["get_version"]


def get_version() -> str:
  """Return the package version if installed, fallback to placeholder."""
  try:
    return version("sample_app")
  except PackageNotFoundError:
    return "0.0.0"
