"""Adjust kitty OS-window opacity when focus changes.

Focused kitty OS windows are kept at 0.9 opacity; all other kitty OS
windows are dimmed to 0.5. This is loaded as a global watcher from
kitty.conf.
"""

from datetime import datetime
from pathlib import Path
from typing import Any

from kitty.boss import Boss
from kitty.window import Window

FOCUSED_OPACITY = "0.95"
UNFOCUSED_OPACITY = "0.6"
LOG_FILE = Path.home() / ".config" / "kitty" / "focus_opacity.log"
LOG = False


def _log(message: str) -> None:
    if not LOG:
        return
    try:
        LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
        timestamp = datetime.now().isoformat(timespec="seconds")
        with LOG_FILE.open("a", encoding="utf-8") as log:
            log.write(f"{timestamp} {message}\n")
    except Exception:
        # Never let diagnostics break kitty startup or focus handling.
        pass


def _remote_control(boss: Boss, window: Window, args: tuple[str, ...]) -> None:
    try:
        _log(f"remote_control window_id={window.id} args={args!r}")
        boss.call_remote_control(window, args)
    except Exception as exc:
        _log(f"remote_control_failed window_id={window.id} args={args!r} error={exc!r}")


def _set_all_opacity(boss: Boss, window: Window, opacity: str) -> None:
    _remote_control(boss, window, ("set-background-opacity", "--all", opacity))


def _set_os_window_opacity(boss: Boss, window: Window, opacity: str) -> None:
    # set-background-opacity applies to the OS window containing the matched
    # kitty window, so matching the focused kitty window is enough to restore
    # the whole focused terminal window to the desired opacity.
    _remote_control(
        boss,
        window,
        ("set-background-opacity", f"--match=id:{window.id}", opacity),
    )


def on_focus_change(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    _log(f"on_focus_change window_id={window.id} focused={data.get('focused')!r} data={data!r}")
    if data.get("focused"):
        _set_all_opacity(boss, window, UNFOCUSED_OPACITY)
        _set_os_window_opacity(boss, window, FOCUSED_OPACITY)
    else:
        _set_all_opacity(boss, window, UNFOCUSED_OPACITY)


_log("focus_opacity watcher imported")
