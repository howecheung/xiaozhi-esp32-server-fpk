#!/bin/sh
set -e

MODEL="/opt/xiaozhi-esp32-server/models/SenseVoiceSmall/model.pt"
MARKER="/opt/xiaozhi-esp32-server/data/.sensevoice_model_ready"
MIN_SIZE=1048576

# 占位文件小于 1MB 时视为尚未下载，自动从 ModelScope / HuggingFace 拉取
SIZE=$(stat -c %s "$MODEL" 2>/dev/null || echo 0)
if [ ! -f "$MARKER" ] || [ "$SIZE" -lt "$MIN_SIZE" ]; then
  echo "SenseVoiceSmall model not ready (${SIZE} bytes), downloading..."
  python3 /opt/xiaozhi-esp32-server/fpk-helper/download_model.py "$MODEL"
  echo "SenseVoiceSmall model ready."
fi

exec python3 app.py
