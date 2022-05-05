#!/usr/bin/env bash

make mrproper && \
make x86_64_defconfig && \
make kvm_guest.config && \
./scripts/config \
    -e DEBUG_KERNEL \
    -e DEBUG_INFO \
    -e DEBUG_INFO_DWARF4 \
    -e FRAME_POINTER \
    -e GDB_SCRIPTS \
    -e KALLSYMS \
    -d DEBUG_INFO_REDUCED \
    -d DEBUG_INFO_COMPRESSED \
    -d DEBUG_INFO_SPLIT \
    -d RANDOMIZE_BASE && \
make -j8 all && \
make -j8 modules 
