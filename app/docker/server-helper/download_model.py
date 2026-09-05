#!/usr/bin/env python3
"""Download SenseVoiceSmall model.pt for FunASR local ASR.

First install/start writes a zero-byte placeholder via FPK lifecycle scripts;
this helper runs inside the server container before app.py and replaces it.
"""

import os
import sys
import tempfile
import urllib.request


SOURCES = [
    "https://modelscope.cn/models/iic/SenseVoiceSmall/resolve/master/model.pt",
    "https://huggingface.co/FunAudioLLM/SenseVoiceSmall/resolve/main/model.pt",
    "https://hf-mirror.com/FunAudioLLM/SenseVoiceSmall/resolve/main/model.pt",
]
BLOCK = 1024 * 1024  # 1MB


def download(target, url):
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "Mozilla/5.0 (xiaozhi-esp32-server-fpk)"},
    )
    fd, tmp = tempfile.mkstemp(
        prefix="model.pt.", suffix=".tmp", dir=os.path.dirname(target)
    )
    downloaded = 0
    try:
        with urllib.request.urlopen(req, timeout=120) as resp, os.fdopen(fd, "wb") as out:
            while True:
                chunk = resp.read(BLOCK)
                if not chunk:
                    break
                out.write(chunk)
                downloaded += len(chunk)
                if downloaded % (20 * BLOCK) < BLOCK:
                    print(f"  downloaded {downloaded / (1024 * 1024):.1f} MB", flush=True)
        if downloaded < 1024 * 1024:
            raise RuntimeError("downloaded file is unexpectedly small")
        os.replace(tmp, target)
    except Exception:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise


def main():
    target = sys.argv[1]
    errors = []
    for url in SOURCES:
        print(f"Trying {url}")
        try:
            download(target, url)
            return 0
        except Exception as exc:  # noqa: BLE001 - try next mirror
            errors.append(f"{url}: {exc}")
            print(f"Failed: {exc}", file=sys.stderr)
    raise SystemExit("All model sources failed:\n" + "\n".join(errors))


if __name__ == "__main__":
    main()
