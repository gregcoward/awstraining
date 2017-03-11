#!/bin/bash -xe
#
cat << EOF | ETCD_ENDPOINTS=http://REPLACEME:4001 calicoctl create -f -
apiVersion: v1
kind: bgpPeer
metadata:
  peerIP: REPLACENODE
  scope: global
spec:
  asNumber: 64511
EOF