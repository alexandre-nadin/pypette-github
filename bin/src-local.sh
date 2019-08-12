#!/usr/bin/env bash
export CLUSTER_MNT_POINT="${HOME}/dev/ctgb/cluster"

function mountClusterPoint() {
  mkdir -p "$CLUSTER_MNT_POINT"
  mountpoint -q "$CLUSTER_MNT_POINT" \
   || sshfs -o nonempty anadin@172.21.151.42:${1:-/} "$CLUSTER_MNT_POINT"
#   || sshfs \
#        -d \
#        -o allow_other \
#        -o reconnect \
#        -o ServerAliveInterval=15 \
#        anadin@172.21.151.42:${1:-/} "$CLUSTER_MNT_POINT" \
#        -p 12345 \
#        -C

}

# Mount cluster directory if specified
if [ ! -z "${CLUSTER_MNT_POINT:+x}" ]; then
  mountClusterPoint "/"
fi
