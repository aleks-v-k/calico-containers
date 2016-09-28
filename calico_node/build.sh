#!/bin/sh
set -e
set -x

# Ensure the main and testing repros are present. Needed for runit
apk add --update-cache --repository "http://alpine.gliderlabs.com/alpine/edge/community" runit

# These packages make it into the final image.
apk add --update-cache python py-setuptools libffi ip6tables ipset iputils iproute2 yajl conntrack-tools

# These packages are only used for building and get removed.
apk add --virtual temp python-dev libffi-dev py-pip alpine-sdk curl

# Install Confd
curl -L https://github.com/projectcalico/confd/releases/download/v0.10.0-scale/confd.static -o /sbin/confd

# Copy patched BIRD daemon with tunnel support.
# curl -L https://github.com/projectcalico/calico-bird/releases/download/v0.1.0/bird -o /sbin/bird
curl -L https://github.com/aleks-v-k/calico-bird/releases/download/fix-routes-on-reboot-test/bird -o /sbin/bird
curl -L https://github.com/projectcalico/calico-bird/releases/download/v0.1.0/bird6 -o /sbin/bird6
curl -L https://github.com/projectcalico/calico-bird/releases/download/v0.1.0/birdcl -o /sbin/birdcl
chmod +x /sbin/*

# FIXME: pinned version of urllib3 to 1.17, because new one (1.18) breaks
# etcd connection from nodes. Actually it should be reworked in kuberdock -
# etcd works fine if it's cert is generated with --domain <master hostname>
# and this hostname is used in ETCD_AUTHORITY on nodes.
pip install urllib3==1.17

# Install Felix and libcalico
pip install git+https://github.com/projectcalico/calico.git@1.4.0b2
pip install git+https://github.com/projectcalico/libcalico.git@v0.15.0
# Output the python library list
pip list > libraries.txt

# Cleanup
apk del temp && rm -rf /var/cache/apk/*
