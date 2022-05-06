# Linux Kernel Debugging

## Quick Start

Check the [requirements](#requirements) and see the [example](#example) session!

## Design Decisions

### Terminology

- **host**: Probably the machine you are sitting in front of!
- **container**: A Docker container, that we use for `pwndbg` (`gdb`). It is not essential to use Docker but it keeps the host system cleaner.
- **virtual machine**: This is what QEMU provides us, and we use it to run the Linux kernel with a Debian root filesystem.

### QEMU

QEMU allows us to run the Linux kernel inside a virtualized / emulated environment so that it can be stopped and continued as we want. Currently it is not possible (at least to for me) to enable KVM because single stepping will be disturbed by certain interrupts (see https://lkml.kernel.org/lkml/20210315221020.661693-3-mlevitsk@redhat.com/). So we have to stick with full emulation until this gets "fixed". Unfortunately, this makes the execution of the virtual machine slower. You can try it yourself by adding `-enable-kvm` as a command line argument to `qemu-system-x86_64` in `lkd_run_qemu.sh` and start debugging with `lkd_debug.sh`. Watch the behavior during single stepping.

We also use `-smp 1` to only have a single virtual CPU.

### Debian

Since we are only interested in debugging the (vanilla) Linux kernel it does not really matter what distribution (files, services, utils, ...) we use. Debian is a good choice and it is also very easy to create a root filesystem with `debootstrap`. So we use a vanilla Linux kernel with the Debian filesystem.

### pwndbg

`pwndbg` is a very nice overlay / extension to `gdb` that eases the debugging process a lot with nice visualizations and handy functions.

### Docker

For debugging we use `pwndbg` but also install `pwntools` for convenience. Since I do not want to clutter my host system too much I like to use containers. This is the only reason I use Docker here. You could also just run the debugger on your host by ignoring the `lkd_debug.sh` script and use `lkd_gdb.sh` directly.

## Files

The files (except `README.md`) are all prefixed with `lkd` (Linux Kernel Debugging) so that you can see more easily which files belong to the Linux kernel and which not once the kernel is cloned to the same directory.

Overview of the interesting files. In parenthesis you see where it is used in the default setup:

- `lkd_Dockerfile` (host)
    - a Dockerfile that sets up a container with `pwndbg` and `pwntools` for more convenient debugging (Arch Linux based)

- `lkd_build_kernel.sh` (host)
    - makes the necessary kernel configurations for a kernel that is able to be debugged
    - builds the kernel

- `lkd_create_root_fs.sh` (host)
    - creates a 5GB QCOW2 disk image and installs a root filesystem in it (necessary tools and files)
    - also changes the password for `root` to `test`
    - some other settings

- `lkd_debug.sh` (host)
    - starts the Docker image (with some bind mounts, user permission settings, capabilities to allow debugging, e.g. SYS_PTRACE, ...)

- `lkd_docker_create_user.sh` (container)
    - runs inside the Docker container and creates a `dbg` user (and group) with password `test`
    - you might want to change the `YOUR_HOST_UID` and `YOUR_HOST_GID` according to your `id -u` and `id -g` output on your host system

- `lkd_gdb.sh` (container)
    - actually run gdb with some initial commands (attach, set correct architecture, ...)

- `lkd_gdbinit` (container)
    - custom `.gdbinit` that will be available inside the Docker container and sets some default values (and also loads `pwndbg`)

- `lkd_init.sh` (host)
    - clones the recent kernel into to current directory (next to the `lkd_*` files)
    - executes other scripts to
      - build the kernel
        - this takes a while... ☕
      - create the root filesystem
        - **Note**: this step uses `sudo` so don't miss the chance to enter your password, otherwise there will be a timeout!
    - builds the Docker image (`lkd_Dockerfile`)
    
- `lkd_kill_qemu.sh` (host)
    - kills `qemu-system-x86_64` process if something goes wrong / hangs

- `lkd_run_qemu.sh` (host)
    - starts QEMU with the appropriate command line arguments
    - if you provide the `debug` argument QEMU starts in debugging mode and waits until a debugger is attached (before the kernel starts)
        - `./lkd_run_qemu.sh` -> QEMU runs *without* gdb support enabled
        - `./lkd_run_qemu.sh debug` -> QEMU runs *with* gdb support enabled

## Requirements

### Arch Linux

```
# get system up-to-date
$ sudo pacman -Syu

# install all requirements
$ sudo pacman -S rsync git qemu debootstrap base-devel docker bc

# start docker service
$ sudo systemctl start docker

# you might want to add your user to the docker group
$ sudo usermod -aG docker $USER
```

### Fedora

Note: Red Hat also develops `podman` which should also be fine (`sudo dnf update && sudo dnf install podman podman-docker`).

```
# get system up-to-date
$ sudo dnf update

# install Docker according to https://docs.docker.com/engine/install/fedora/
$ sudo dnf install dnf-plugins-core
$ sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
$ sudo dnf install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# install compilers and development tools
$ sudo dnf groupinstall "Development Tools"

# install the rest of the requirements
$ sudo dnf install rsync git qemu-system-x86 qemu-img debootstrap bc openssl iproute

# start docker service
$ sudo systemctl start docker

# you might want to add your user to the docker group
$ sudo usermod -aG docker $USER
```

### Ubuntu

```
# get system up-to-date
$ sudo apt-get update && sudo apt-get upgrade

# install Docker according to https://docs.docker.com/engine/install/ubuntu/
$ sudo apt-get install ca-certificates curl gnupg lsb-release
$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
$ echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
$ sudo apt-get update
$ sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# install the rest of the requirements (compilers, build tools, qemu, ...)
$ sudo apt-get install build-essential rsync git qemu-system-x86 debootstrap bc openssl libncurses-dev gawk flex bison libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf

# start docker service
$ sudo systemctl start docker

# you might want to add your user to the docker group
$ sudo usermod -aG docker $USER
```

If you are using any other distribution you need to install the equivalent packages. Open a Pull Request if you want to contribute installation instructions for other distributions ;)

## Example

In one terminal window:

```
$ git clone https://github.com/martinclauss/linux-kernel-debugging.git
$ cd linux-kernel-debugging
$ ./lkd_init.sh
$ ./lkd_run_qemu.sh debug
```

in *another* terminal window:

```
$ ./lkd_debug.sh
```

You should now see a `pwndbg` session like this where the execution halts at `start_kernel`:

```
start_kernel () at init/main.c:929
929	{
loading vmlinux
LEGEND: STACK | HEAP | CODE | DATA | RWX | RODATA
────────────────────────────────────────[ REGISTERS ]────────────────────────────────────────
 RAX  0x0
 RBX  0x0
 RCX  0x0
 RDX  0x0
 RDI  0x13730
 RSI  0x3d3b350f
 R8   0xffffffffffff
 R9   0xffff0000ffffffff
 R10  0xffffffff0000ffff
 R11  0x1f0
 R12  0x0
 R13  0x0
 R14  0x0
 R15  0x0
 RBP  0x0
 RSP  0xffffffff82803f50 (init_thread_union+16208) —▸ 0xffffffff8100011a (secondary_startup_64_no_verify+213) ◂— nop    word ptr [rax + rax] /* 0x6a9c0000441f0f66 */
 RIP  0xffffffff82fb0b48 (start_kernel) ◂— push   r14 /* 0x814940c7c7485641 */
─────────────────────────────────────────[ DISASM ]──────────────────────────────────────────
 ► 0xffffffff82fb0b48 <start_kernel>       push   r14
   0xffffffff82fb0b4a <start_kernel+2>     mov    rdi, -0x7d7eb6c0              <0xffffffff82814940>
   0xffffffff82fb0b51 <start_kernel+9>     push   r13
   0xffffffff82fb0b53 <start_kernel+11>    push   r12
   0xffffffff82fb0b55 <start_kernel+13>    push   rbp
   0xffffffff82fb0b56 <start_kernel+14>    push   rbx
   0xffffffff82fb0b57 <start_kernel+15>    sub    rsp, fixed_percpu_data+24     <24>
   0xffffffff82fb0b5b <start_kernel+19>    mov    rax, qword ptr gs:[0x28]
   0xffffffff82fb0b64 <start_kernel+28>    mov    qword ptr [rsp + 0x10], rax
   0xffffffff82fb0b69 <start_kernel+33>    xor    eax, eax
   0xffffffff82fb0b6b <start_kernel+35>    call   set_task_stack_end_magic            <set_task_stack_end_magic>
──────────────────────────────────────[ SOURCE (CODE) ]──────────────────────────────────────
In file: /io/init/main.c
   924 		&unknown_options[1]);
   925 	memblock_free(unknown_options, len);
   926 }
   927
   928 asmlinkage __visible void __init __no_sanitize_address start_kernel(void)
 ► 929 {
   930 	char *command_line;
   931 	char *after_dashes;
   932
   933 	set_task_stack_end_magic(&init_task);
   934 	smp_setup_processor_id();
──────────────────────────────────────────[ STACK ]──────────────────────────────────────────
00:0000│ rsp 0xffffffff82803f50 (init_thread_union+16208) —▸ 0xffffffff8100011a (secondary_startup_64_no_verify+213) ◂— nop    word ptr [rax + rax] /* 0x6a9c0000441f0f66 */
01:0008│     0xffffffff82803f58 (init_thread_union+16216) ◂— 0
... ↓        6 skipped
────────────────────────────────────────[ BACKTRACE ]────────────────────────────────────────
 ► f 0 0xffffffff82fb0b48 start_kernel
   f 1 0xffffffff8100011a secondary_startup_64_no_verify+213
   f 2              0x0
─────────────────────────────────────────────────────────────────────────────────────────────
pwndbg>
```

In the first window you first should see "nothing" since QEMU waits until we attach and `continue`. So `continue` (`c`) in `pwndbg` and see how the machine boots. Surely, you could also add some breakpoints right now if you want. Use `Ctrl+C` in `pwndbg` to stop kernel execution and, for example, inspect memory, registers, set breakpoints, etc.

## Network

When the QEMU machine is booted, login as `root` and `test` as password. Then:

```
# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: enp0s3: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN group default qlen 1000
    link/ether 52:54:00:12:34:56 brd ff:ff:ff:ff:ff:ff
3: sit0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN group default qlen 1000
    link/sit 0.0.0.0 brd 0.0.0.0

# dhclient enp0s3
[  191.121720] e1000: enp0s3 NIC Link is Up 1000 Mbps Full Duplex, Flow Control: RX
[  191.126675] IPv6: ADDRCONF(NETDEV_CHANGE): enp0s3: link becomes ready
[  191.132681] ip (211) used greatest stack depth: 12696 bytes left

# ping 9.9.9.9
PING 9.9.9.9 (9.9.9.9) 56(84) bytes of data.
64 bytes from 9.9.9.9: icmp_seq=1 ttl=255 time=14.1 ms
64 bytes from 9.9.9.9: icmp_seq=2 ttl=255 time=15.3 ms
^C
--- 9.9.9.9 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1004ms
rtt min/avg/max/mdev = 14.066/14.680/15.294/0.614 ms
```

If you want the connection to be established on every boot just edit the `/etc/network/interfaces` file:

```
# interfaces(5) file used by ifup(8) and ifdown(8)
# Include files from /etc/network/interfaces.d:
source /etc/network/interfaces.d/*

auto enp0s3
iface enp0s3 inet dhcp
```

## SSH

Port forwarding is already enabled from `<host>:2222` to `<qemu>:22` (see `-net` in `lkd_run_qemu.sh`)

```
# apt-get update && apt-get install openssh-server
# sed -i -e 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
# systemctl enable ssh
# systemctl start ssh
```

From the host try:

```
$ ssh -p 2222 root@localhost
The authenticity of host '[localhost]:2222 ([127.0.0.1]:2222)' can't be established.
ED25519 key fingerprint is SHA256:PheabPPUlay23YYu1NnMS+tak4oaqS0piSdsIDH6yDE.
This host key is known by the following other names/addresses:
    ~/.ssh/known_hosts:73: [127.0.0.1]:2222
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '[localhost]:2222' (ED25519) to the list of known hosts.
root@localhost's password:
Linux hostname 5.18.0-rc5 #1 SMP PREEMPT_DYNAMIC Mon May 2 11:08:29 CEST 2022 x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Mon May  2 13:50:52 2022
...
```

## Kernel Version / Commit

The default `git clone` has a `--depth 1` parameter to reduce the amount of data that must be transferred from https://github.com/torvalds/linux. This means that you can only build the latest commit. If you want to compile and debug a specific commit you should adjust the `git clone ...` line in `lkd_init.sh`.

## Testing (mostly for myself)

Test the setup with `vagrant` and `libvirt`:

```
$ ./lkd_test_vagrant.sh $(realpath <lkd_Vagrantfile_xyz>)
```

with `<lkd_Vagrantfile_xyz>` in `lkd_Vagrantfile_{arch,fedora,ubuntu}`.

## Contributions

Just open a PR and I'll see what I can do :)
