"""Live checks of every part of the stack. Every value shown in the CLI comes from here."""

import json
import subprocess
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from pathlib import Path

from .paths import load_env


@dataclass
class Check:
    name: str
    ok: bool
    detail: str


def _http(url: str, headers: dict[str, str] | None = None, timeout: float = 2.0) -> tuple[int, bytes]:
    req = urllib.request.Request(url, headers=headers or {})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.status, resp.read()
    except urllib.error.HTTPError as e:
        return e.code, b""
    except (urllib.error.URLError, TimeoutError, OSError):
        return 0, b""


def _run(cmd: list[str], timeout: float = 5.0) -> str:
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=timeout).stdout
    except (OSError, subprocess.TimeoutExpired):
        return ""


def check_colima() -> Check:
    out = _run(["colima", "list", "--json"])
    for line in out.splitlines():
        try:
            vm = json.loads(line)
        except json.JSONDecodeError:
            continue
        if vm.get("status") == "Running":
            return Check("colima", True, f"running  {vm.get('memory', 0) / 2**30:.0f} GB")
    return Check("colima", False, "stopped")


def check_unsloth() -> Check:
    env = load_env()
    port = env.get("UNSLOTH_PORT", "8890")
    code, _ = _http(f"http://127.0.0.1:{port}/api/health")
    if code != 200:
        return Check("unsloth", False, f"not running (:{port})")
    code, body = _http(
        f"http://127.0.0.1:{port}/v1/models",
        {"Authorization": f"Bearer {env.get('UNSLOTH_API_KEY', '')}"},
    )
    model = "no model loaded"
    if code == 200:
        loaded = [m for m in json.loads(body).get("data", []) if m.get("loaded")]
        if loaded:
            m = loaded[0]
            model = f"{m['id'].split('/')[-1].removesuffix('-GGUF').lower()}  {m.get('context_length', 0) // 1024}K ctx"
    rss_kb = 0
    for line in _run(["ps", "-axo", "rss=,command="]).splitlines():
        if "llama-server" in line or "unsloth_studio/bin/python" in line:
            rss_kb += int(line.split(None, 1)[0])
    return Check("unsloth", True, f"{model}  {rss_kb / 2**20:.1f} GB")


def check_open_webui() -> Check:
    code, _ = _http("http://localhost:3000/health")
    return Check("open-webui", code == 200, ":3000" if code == 200 else "down")


def check_hermes() -> Check:
    code, _ = _http("http://localhost:9119/")
    up = code in (200, 302)
    return Check("hermes", up, ":9119  local qwen" if up else "down")


def check_gws() -> Check:
    root = Path.home() / ".config" / "gws" / "profiles"
    profiles = sorted(p.name for p in root.glob("*") if (p / "credentials.enc").exists()) if root.exists() else []
    return Check("gws", len(profiles) == 3, f"{len(profiles)}/3 profiles")


def check_memory() -> Check:
    total = int(_run(["sysctl", "-n", "hw.memsize"]) or 0)
    pages = {}
    for line in _run(["vm_stat"]).splitlines()[1:]:
        key, _, value = line.partition(":")
        pages[key.strip()] = int(value.strip().rstrip(".") or 0)
    used = (
        pages.get("Pages active", 0) + pages.get("Pages wired down", 0) + pages.get("Pages occupied by compressor", 0)
    ) * 16384
    return Check("memory", total > 0, f"{used / 2**30:.1f} / {total / 2**30:.0f} GB used")


CHECKS = [check_colima, check_unsloth, check_open_webui, check_hermes, check_gws, check_memory]


def run_all() -> list[Check]:
    """Run every check in parallel and return results in display order."""
    with ThreadPoolExecutor(max_workers=len(CHECKS)) as pool:
        return list(pool.map(lambda fn: fn(), CHECKS))
