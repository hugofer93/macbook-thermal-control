#!/bin/bash
# macbook-thermal-control - Wrapper script for process name visibility
# This wrapper uses exec -a to set the process name as shown in Activity Monitor/ps/htop

set -e

# The actual installation directory (set during installation)
INSTALL_DIR="__INSTALL_DIR__"
PYTHON_SCRIPT="$INSTALL_DIR/scripts/macbook-max-cooling.py"

# Use exec -a to set the process name as shown in Activity Monitor/ps/htop
exec -a "macbook-thermal-control" /usr/bin/python3 "$PYTHON_SCRIPT" "$@"
