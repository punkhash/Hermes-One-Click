"""Diagnostic log export and lightweight retention for Cosmius Hermes."""

from __future__ import annotations

import io
import json
import os
import platform
import time
import zipfile
from pathlib import Path
from typing import Iterable

from api.config import (
    DEFAULT_WORKSPACE,
    LAST_WORKSPACE_FILE,
    PYTHON_EXE,
    SESSION_INDEX_FILE,
    SETTINGS_FILE,
    STATE_DIR,
    WORKSPACES_FILE,
    _get_config_path,
)
from api.helpers import _redact_text


LOG_EXPORT_DIR = STATE_DIR / "log_exports"
CLIENT_EVENTS_LOG = STATE_DIR / "client-events.log"
MAX_TEXT_FILE_BYTES = 512 * 1024
MAX_CLIENT_EVENTS_BYTES = 2 * 1024 * 1024
EXPORT_RETENTION_SECONDS = 24 * 60 * 60


def _today_key() -> str:
    return time.strftime("%Y-%m-%d", time.localtime())


def _log_cleanup_stamp() -> Path:
    return STATE_DIR / ".logs-cleaned-day"


def _safe_read_text(path: Path, limit: int = MAX_TEXT_FILE_BYTES) -> str:
    try:
        raw = path.read_bytes()
    except OSError:
        return ""
    if len(raw) > limit:
        raw = raw[-limit:]
        prefix = f"[truncated to last {limit} bytes]\n"
    else:
        prefix = ""
    return prefix + raw.decode("utf-8", errors="replace")


def _redact(text: str) -> str:
    return _redact_text(text or "")


def _write_text(zf: zipfile.ZipFile, name: str, text: str) -> None:
    zf.writestr(name, _redact(text))


def _add_file(zf: zipfile.ZipFile, path: Path, arcname: str, *, redact: bool = True) -> None:
    try:
        if not path.exists() or not path.is_file():
            return
    except OSError:
        return
    text = _safe_read_text(path)
    zf.writestr(arcname, _redact(text) if redact else text)


def _safe_glob_logs(root: Path) -> Iterable[Path]:
    try:
        yield from root.glob("*.log")
    except OSError:
        return


def _safe_mtime(path: Path) -> float:
    try:
        return path.stat().st_mtime if path.exists() else 0
    except OSError:
        return 0


def _agent_log_candidates() -> list[Path]:
    candidates: list[Path] = []
    try:
        from api.profiles import get_active_hermes_home

        candidates.extend(_safe_glob_logs(get_active_hermes_home() / "logs"))
    except Exception:
        pass
    local_home = Path(os.environ.get("HERMES_HOME", str(Path.home() / ".hermes")))
    candidates.extend(_safe_glob_logs(local_home / "logs"))
    appdata_home = Path.home() / "AppData" / "Local" / "hermes" / "logs"
    candidates.extend(_safe_glob_logs(appdata_home))
    portable_bootstrap_logs = Path.home() / "AppData" / "Local" / "Cosmius Hermes" / "logs"
    candidates.extend(_safe_glob_logs(portable_bootstrap_logs))
    unique: list[Path] = []
    seen: set[str] = set()
    for p in candidates:
        try:
            key = str(p.resolve()) if p.exists() else str(p)
        except OSError:
            key = str(p)
        if key not in seen:
            seen.add(key)
            unique.append(p)
    return sorted(unique, key=_safe_mtime, reverse=True)[:8]


def cleanup_log_artifacts(force: bool = False) -> None:
    """Run a once-per-day cleanup to keep local diagnostic files bounded."""
    try:
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        LOG_EXPORT_DIR.mkdir(parents=True, exist_ok=True)
    except OSError:
        return
    stamp = _log_cleanup_stamp()
    today = _today_key()
    if not force:
        try:
            if stamp.exists() and stamp.read_text(encoding="utf-8").strip() == today:
                return
        except OSError:
            pass

    cutoff = time.time() - EXPORT_RETENTION_SECONDS
    for item in LOG_EXPORT_DIR.glob("hermes-logs-*.zip"):
        try:
            if item.stat().st_mtime < cutoff:
                item.unlink()
        except OSError:
            pass

    # Keep only today's client event diagnostics, and bound the file if the user
    # repeatedly reproduces an issue in one day.
    try:
        if CLIENT_EVENTS_LOG.exists():
            mday = time.strftime("%Y-%m-%d", time.localtime(CLIENT_EVENTS_LOG.stat().st_mtime))
            if mday != today:
                CLIENT_EVENTS_LOG.write_text("", encoding="utf-8")
            elif CLIENT_EVENTS_LOG.stat().st_size > MAX_CLIENT_EVENTS_BYTES:
                tail = CLIENT_EVENTS_LOG.read_bytes()[-MAX_CLIENT_EVENTS_BYTES:]
                CLIENT_EVENTS_LOG.write_bytes(b"[truncated previous client events]\n" + tail)
    except OSError:
        pass

    try:
        stamp.write_text(today, encoding="utf-8")
    except OSError:
        pass


def get_log_status() -> dict:
    cleanup_log_artifacts()
    exports = []
    try:
        export_items = sorted(LOG_EXPORT_DIR.glob("hermes-logs-*.zip"), key=_safe_mtime, reverse=True)[:5]
    except OSError:
        export_items = []
    for item in export_items:
        try:
            exports.append({"name": item.name, "size": item.stat().st_size, "mtime": item.stat().st_mtime})
        except OSError:
            pass
    try:
        client_size = CLIENT_EVENTS_LOG.stat().st_size if CLIENT_EVENTS_LOG.exists() else 0
    except OSError:
        client_size = 0
    return {
        "ok": True,
        "state_dir": str(STATE_DIR),
        "export_dir": str(LOG_EXPORT_DIR),
        "client_events_size": client_size,
        "retention_hours": 24,
        "recent_exports": exports,
    }


def build_log_export_zip() -> tuple[bytes, str]:
    cleanup_log_artifacts()
    try:
        LOG_EXPORT_DIR.mkdir(parents=True, exist_ok=True)
    except OSError:
        pass
    ts = time.strftime("%Y%m%d-%H%M%S", time.localtime())
    filename = f"hermes-logs-{ts}.zip"
    buf = io.BytesIO()

    with zipfile.ZipFile(buf, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        summary = {
            "created_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "platform": platform.platform(),
            "python": PYTHON_EXE,
            "state_dir": str(STATE_DIR),
            "default_workspace": str(DEFAULT_WORKSPACE),
            "config_path": str(_get_config_path()),
            "pid": os.getpid(),
            "env": {
                "PYTHONUTF8": os.environ.get("PYTHONUTF8", ""),
                "PYTHONIOENCODING": os.environ.get("PYTHONIOENCODING", ""),
                "HERMES_WEBUI_PORT": os.environ.get("HERMES_WEBUI_PORT", ""),
                "HERMES_WEBUI_AGENT_DIR": os.environ.get("HERMES_WEBUI_AGENT_DIR", ""),
            },
        }
        _write_text(zf, "summary.json", json.dumps(summary, ensure_ascii=False, indent=2))

        _add_file(zf, SETTINGS_FILE, "webui/settings.json")
        _add_file(zf, WORKSPACES_FILE, "webui/workspaces.json")
        _add_file(zf, LAST_WORKSPACE_FILE, "webui/last_workspace.txt")
        _add_file(zf, SESSION_INDEX_FILE, "webui/session_index.json")
        _add_file(zf, CLIENT_EVENTS_LOG, "webui/client-events.log")
        _add_file(zf, _get_config_path(), "hermes/config.yaml")

        try:
            from api.profiles import get_active_hermes_home

            _add_file(zf, get_active_hermes_home() / ".env", "hermes/env.redacted")
        except Exception:
            pass

        for idx, log_path in enumerate(_agent_log_candidates(), start=1):
            _add_file(zf, log_path, f"hermes-agent/log-{idx}-{log_path.name}")

    data = buf.getvalue()
    try:
        (LOG_EXPORT_DIR / filename).write_bytes(data)
    except OSError:
        pass
    return data, filename
