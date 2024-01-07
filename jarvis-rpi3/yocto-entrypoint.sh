#!/usr/bin/env bash

PROJECT_URL=https://github.com/denoming/jarvis

function sync()
{
    if [ ! -f $PWD/.init ]; then
        repo init -u $PROJECT_URL -b main -m rpi3.xml
        repo sync -j $(nproc)
        touch $PWD/.init
    fi
}

sync

export TEMPLATECONF=${TEMPLATECONF:-$PWD/sources/meta-jarvis/conf/templates/raspberrypi3}
source sources/poky/oe-init-build-env build-rpi3
bash
