#!/usr/bin/env bash

PROJECT_URL=https://github.com/karz0n/sensority

function sync()
{
    if [ ! -f $PWD/.init ]; then
        repo init -u $PROJECT_URL
        repo sync -j $(nproc)
        touch $PWD/.init
    fi
}

sync

export TEMPLATECONF=$PWD/sources/meta-sensority/conf/variant/x86_64
source sources/poky/oe-init-build-env build-qemu

bash