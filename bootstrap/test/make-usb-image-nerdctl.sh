#!/usr/bin/env bash

nerdctl run -v `pwd`:/mnt -w /mnt --rm camden.ornl.gov/toolbox/centos-ornl:8 bash -c 'dnf install -y e2fsprogs; truncate --size 128M test-usb.img; mkfs.ext4 -L OEMDRV test-usb.img; debugfs -f <(echo "write test-usb/ks.cfg ks.cfg") -w test-usb.img'
