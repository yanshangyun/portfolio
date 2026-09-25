#!/usr/bin/env bash
# Checks (and optionally fixes) MP4 files that aren't "faststart" —
# i.e. their moov atom comes after mdat, forcing browsers to download
# nearly the whole file before playback can begin.
#
# Usage:
#   scripts/check-faststart.sh                 # scan assets/projects, report only
#   scripts/check-faststart.sh --fix           # scan assets/projects, fix in place
#   scripts/check-faststart.sh --fix a.mp4 b.mp4   # check/fix specific files

set -euo pipefail

FIX=0
FILES=()

for arg in "$@"; do
    if [ "$arg" = "--fix" ]; then
        FIX=1
    else
        FILES+=("$arg")
    fi
done

if [ ${#FILES[@]} -eq 0 ]; then
    REPO_ROOT="$(git rev-parse --show-toplevel)"
    while IFS= read -r -d '' f; do
        FILES+=("$f")
    done < <(find "$REPO_ROOT/assets/projects" -name "*.mp4" -print0)
fi

is_faststart() {
    python3 - "$1" <<'PY'
import struct, sys

path = sys.argv[1]
with open(path, 'rb') as f:
    data = f.read()

pos = 0
moov_pos = mdat_pos = -1
while pos < len(data) - 8:
    size = struct.unpack('>I', data[pos:pos+4])[0]
    typ = data[pos+4:pos+8].decode('latin1', errors='replace')
    if typ == 'moov' and moov_pos == -1:
        moov_pos = pos
    if typ == 'mdat' and mdat_pos == -1:
        mdat_pos = pos
    if size == 0:
        break
    if size == 1:
        size = struct.unpack('>Q', data[pos+8:pos+16])[0]
    pos += size

sys.exit(0 if (moov_pos != -1 and mdat_pos != -1 and moov_pos < mdat_pos) else 1)
PY
}

bad=0
for f in "${FILES[@]}"; do
    [ -f "$f" ] || continue
    if is_faststart "$f"; then
        continue
    fi

    if [ "$FIX" = "1" ]; then
        tmp="${f%.mp4}.faststart.mp4"
        ffmpeg -y -v error -i "$f" -c copy -movflags +faststart "$tmp"
        mv "$tmp" "$f"
        echo "fixed: $f"
    else
        echo "NOT-FASTSTART: $f"
        bad=1
    fi
done

exit $bad
