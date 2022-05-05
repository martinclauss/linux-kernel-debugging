#!/usr/bin/env bash

if [[ $# -ne 1 ]]
then
	echo "usage: $0 <path to Vagrantfile>"
	exit 1
fi

if [[ ! -e $1 ]]
then
	echo "the Vagrantfile you provided does not exist"
	exit 1
fi

export VAGRANT_VAGRANTFILE=$1

# uncomment if you need to install libvirt support for vagrant
# vagrant plugin install vagrant-libvirt && \
vagrant up --provider libvirt && \
vagrant ssh && \
vagrant destory -f && \
rm -rf .vagrant
