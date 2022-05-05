#!/usr/bin/env bash

if [[ -L vmlinux-gdb.py ]]
then
    rm vmlinux-gdb.py
fi

if [[ ! -e vmlinux-gdb.py ]]
then
    cp scripts/gdb/vmlinux-gdb.py .
fi

docker run -it \
    --rm --cap-add=SYS_PTRACE \
    --security-opt seccomp=unconfined \
    -v $(pwd):/io \
    -v $(pwd)/lkd_gdbinit:/home/dbg/.gdbinit \
    --net host \
    --hostname "lkd-arch-container" \
    --name arch_kernel_debugging \
    --user "$(id -u):$(id -g)" \
    lkd
