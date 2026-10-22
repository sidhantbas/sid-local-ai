"""Double-clap detection, plus the background daemon that listens for 60 s after each unlock.

Nothing is recorded: each ~12 ms audio block is reduced to a peak and an RMS value,
compared against a running noise floor, and thrown away.
"""

import json
import threading
import time
from dataclasses import asdict, dataclass

import numpy as np
import sounddevice as sd

from .paths import CONFIG_DIR

SAMPLE_RATE = 44100
BLOCK = 512  # ~11.6 ms per block
CONFIG_FILE = CONFIG_DIR / "clap.json"


@dataclass
class ClapConfig:
    min_peak: float = 0.25  # absolute peak (0..1) a clap must reach
    ratio: float = 8.0  # how far above the noise floor the block RMS must jump
    min_gap: float = 0.15  # seconds between the two claps
    max_gap: float = 0.70
    listen_seconds: float = 60.0  # daemon: how long the mic stays on after an unlock

    @classmethod
    def load(cls) -> "ClapConfig":
        if CONFIG_FILE.exists():
            return cls(**{**asdict(cls()), **json.loads(CONFIG_FILE.read_text())})
        return cls()

    def save(self) -> None:
        CONFIG_DIR.mkdir(parents=True, exist_ok=True)
        CONFIG_FILE.write_text(json.dumps(asdict(self), indent=2) + "\n")


class DoubleClapDetector:
    """Feed audio blocks; returns True from feed() when a double clap completes."""

    REFRACTORY = 0.12  # one clap rings for a few blocks; ignore onsets this close together

    def __init__(self, cfg: ClapConfig):
        self.cfg = cfg
        self.noise = 0.01
        self.last_onset = -1.0
        self.first_clap: float | None = None
        self.peak = 0.0
        self.rms = 0.0

    def feed(self, block: np.ndarray, now: float) -> tuple[bool, bool]:
        """Returns (clap_onset, double_clap)."""
        self.peak = float(np.max(np.abs(block)))
        self.rms = float(np.sqrt(np.mean(block**2)))
        onset = (
            self.peak >= self.cfg.min_peak
            and self.rms >= self.cfg.ratio * self.noise
            and now - self.last_onset >= self.REFRACTORY
        )
        if not onset:
            self.noise = 0.98 * self.noise + 0.02 * max(self.rms, 1e-4)
            if self.first_clap is not None and now - self.first_clap > self.cfg.max_gap:
                self.first_clap = None
            return False, False
        self.last_onset = now
        if self.first_clap is not None and self.cfg.min_gap <= now - self.first_clap <= self.cfg.max_gap:
            self.first_clap = None
            return True, True
        self.first_clap = now
        return True, False


def listen(cfg: ClapConfig, seconds: float | None, on_block=None) -> bool:
    """Listen until a double clap (True) or until `seconds` pass (False)."""
    detector = DoubleClapDetector(cfg)
    hit = threading.Event()
    heard_anything = threading.Event()

    def callback(indata, frames, t, status):
        block = indata[:, 0]
        if np.any(block):
            heard_anything.set()
        onset, double = detector.feed(block, time.monotonic())
        if on_block:
            on_block(detector, onset, double)
        if double:
            hit.set()

    with sd.InputStream(channels=1, samplerate=SAMPLE_RATE, blocksize=BLOCK, dtype="float32", callback=callback):
        start = time.monotonic()
        deadline = None if seconds is None else start + seconds
        warned = False
        while not hit.is_set():
            now = time.monotonic()
            if deadline is not None and now >= deadline:
                return False
            # macOS delivers pure zeros (no error) when microphone access is denied
            if not warned and not heard_anything.is_set() and now - start > 3:
                print("clap: only silence from the mic; check System Settings > Privacy > Microphone", flush=True)
                warned = True
            hit.wait(0.1)
    return True


def test() -> None:
    """Live meter for tuning: shows level, noise floor, and every clap it hears."""
    cfg = ClapConfig.load()
    print(f"settings: {CONFIG_FILE} {asdict(cfg)}")
    print("clap twice to test; Ctrl+C to stop\n")

    def show(det: DoubleClapDetector, onset: bool, double: bool):
        bar = "#" * min(40, int(det.peak * 40))
        if double:
            print(f"\r{' ' * 78}\r  >>> DOUBLE CLAP  (peak {det.peak:.2f})", flush=True)
        elif onset:
            print(f"\r{' ' * 78}\r  clap  peak {det.peak:.2f}  rms {det.rms:.3f}  floor {det.noise:.4f}", flush=True)
        else:
            print(f"\r  level [{bar:<40}] {det.peak:.2f}  floor {det.noise:.4f}", end="", flush=True)

    try:
        while True:
            listen(cfg, None, show)
    except KeyboardInterrupt:
        print("\nstopped")


def daemon() -> None:
    """Background service: after login and after every unlock, listen; on a double clap, launch."""
    from Foundation import NSDistributedNotificationCenter, NSObject
    from PyObjCTools import AppHelper

    from .launch import launch_terminal

    cfg = ClapConfig.load()
    busy = threading.Lock()

    def window(reason: str):
        if not busy.acquire(blocking=False):
            return
        try:
            print(f"{time.strftime('%F %T')} listening {cfg.listen_seconds:.0f}s ({reason})", flush=True)
            if listen(cfg, cfg.listen_seconds):
                print(f"{time.strftime('%F %T')} double clap -> launching", flush=True)
                launch_terminal()
        except Exception as e:  # keep the daemon alive whatever the audio layer does
            print(f"{time.strftime('%F %T')} error: {e}", flush=True)
        finally:
            busy.release()

    class Observer(NSObject):
        def unlocked_(self, note):
            threading.Thread(target=window, args=("unlock",), daemon=True).start()

    observer = Observer.new()
    NSDistributedNotificationCenter.defaultCenter().addObserver_selector_name_object_(
        observer, "unlocked:", "com.apple.screenIsUnlocked", None
    )
    threading.Thread(target=window, args=("login",), daemon=True).start()
    AppHelper.runConsoleEventLoop(installInterrupt=True)
