#!/usr/bin/env bash

YOUR_HOST_UID=1000
YOUR_HOST_GID=1000

# add dbg user and group with password "test"
groupadd -g $YOUR_HOST_GID dbg
useradd -u $YOUR_HOST_UID -g $YOUR_HOST_GID -s /bin/bash -m -p $(openssl passwd -1 test) dbg

# make dbg sudoer
usermod -aG wheel dbg
