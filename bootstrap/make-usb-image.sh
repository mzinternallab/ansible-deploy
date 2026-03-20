#!/bin/bash
docker run --rm --privileged -v $(pwd):/workdir camden.ornl.gov/toolbox/centos-ornl:8stream bash -c 'dnf install -y dosfstools && truncate --size 128M /workdir/'"${1}"' && mkfs.fat -F 32 -n OEMDRV /workdir/'"${1}"' && mount /workdir/'"${1}"' /mnt && cp -vr /workdir/'"${2}"'/* /mnt'
