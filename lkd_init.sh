#!/usr/bin/env bash

docker build -f lkd_Dockerfile -t lkd . || exit 1

# we want an in-tree build but git clone won't let us clone into a non-empty directory
# thus the rsync
git clone -depth 1 https://github.com/torvalds/linux linux_tmp && \
rsync -a linux_tmp/ $(pwd)/  && \
rm -rf linux_tmp || exit 1

./lkd_build_kernel.sh && \
./lkd_create_root_fs.sh || exit 1

ls -a | grep -v lkd  | grep -v -E "^(.|..)$" > .dockerignore && \
echo "lkd_qemu_image.qcow2" >> .dockerignore &&\
echo ".vagrant" >> .dockerignore || exit 1

exit 0
