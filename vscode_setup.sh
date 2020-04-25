#!/usr/bin/env bash

source ./shell/echos.sh
source ./shell/requirers.sh

CURRENT_DIR="$PWD"

###############################################################################
bot "VS Code"
###############################################################################

. "$CURRENT_DIR/shell/vscode.sh"
