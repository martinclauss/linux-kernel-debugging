#/usr/bin/env bash

if [[ $# -eq 1 && $1 == "debug" ]]
then
    DEBUG="-s -S"
else
    DEBUG=""
fi


# w/ KVM support
# does not quite work: https://lkml.iu.edu/hypermail/linux/kernel/2103.2/00282.html
# single-stepping gets interrupted by e.g. timers

# qemu-system-x86_64 -kernel arch/x86_64/boot/bzImage -append "root=/dev/sda rw console=ttyS0 nokaslr" -drive file=./lkd_qemu_image.qcow2,format=raw --enable-kvm -cpu host --nographic -m 4096 -net nic,model=virtio -net user,hostfwd=tcp:127.0.0.1:2222-:22 -smp 1 $DEBUG |& tee lkd_vm.log

# w/o KVM support
qemu-system-x86_64 -kernel arch/x86_64/boot/bzImage -append "root=/dev/sda rw console=ttyS0 nokaslr" -drive file=./lkd_qemu_image.qcow2,format=raw --nographic -m 4096 -net nic,model=e1000 -net user,hostfwd=tcp:127.0.0.1:2222-:22 -smp 1 $DEBUG |& tee lkd_vm.log

# reset the terminal
reset
