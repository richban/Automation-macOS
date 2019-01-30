#!/usr/bin/env bash

# This scripts deals with common SHH keys setup. Namely:
#   - Generates SSH keys if not already present.
#   - If a remote host is passed, copies them over for SSH access.
#   - Displays the public key to be copied to git hosting services and changes
#       this very repository's remote from HTTPS to SSH.
# 	Author: @davla
#####################################################
#
#                   Variables
#
#####################################################

SSH_HOME="$HOME/.ssh"

#####################################################
#
#                   Keys creation
#
#####################################################

mkdir -p "$SSH_HOME"
[[ ! -f "$SSH_HOME/id_rsa" ]] && ssh-keygen -t rsa -b 4096 -C "rbanyi@me.com"
ssh-add ~/.ssh/id_rsa
