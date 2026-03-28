#!/usr/bin/env bash
# Serve the OJW web UI from docs/ for local testing.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec bash "$SCRIPT_DIR/../cygnet/run.sh" "$SCRIPT_DIR/docs"
