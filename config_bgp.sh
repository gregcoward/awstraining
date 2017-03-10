#!/bin/bash

cat << EOF | ETCD_ENDPOINTS=http://10.10.38.20:4001 calicoctl create -f -
apiVersion: v1
kind: bgpPeer
metadata:
  peerIP: 10.10.20.163
  scope: global
spec:
  asNumber: 64511
EOF
