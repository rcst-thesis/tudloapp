#!/usr/bin/env bash
set -euo pipefail

command -v ffmpeg >/dev/null || {
  echo "ffmpeg is required." >&2
  exit 1
}

audio_root="${1:-assets/audio}"

find "$audio_root" -type f \( -iname '*.aac' -o -iname '*.m4a' -o -iname '*.ogg' -o -iname '*.wav' \) -print0 |
  while IFS= read -r -d '' input; do
    output="${input%.*}.mp3"
    ffmpeg -loglevel error -y -i "$input" -vn -map_metadata -1 \
      -codec:a libmp3lame -q:a 4 "$output"
    rm -- "$input"
    echo "$output"
  done
