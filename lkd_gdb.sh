#!/usr/bin/env bash

gdb \
  -q \
  -ex "add-auto-load-safe-path $(pwd)" \
  -ex "file $(pwd)/vmlinux" \
  -ex "set architecture i386:x86-64:intel" \
  -ex "target remote :1234" \
  -ex "break start_kernel" \
  -ex "continue" \
  -ex "lx-symbols"