#!/usr/bin/env bash

export VAGRANT_VAGRANTFILE=lkd_Vagrantfile

# uncomment if you need to install libvirt support for vagrant
# vagrant plugin install vagrant-libvirt && \
vagrant up --provider libvirt && \
vagrant ssh && \
vagrant destory -f && \
rm -rf .vagrant
