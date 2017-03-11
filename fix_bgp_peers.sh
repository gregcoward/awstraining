#!/bin/bash -xe
#
function pushFiles() {
    scp -i /home/centos/privatekey.pem -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no /opt/bgp_peers.sh admin@${1}:~/bgp_peers.sh
    ssh -i /home/centos/privatekey.pem -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no admin@${1} "chmod +x ~/bgp_peers.sh"
}
masterIP=$( kubectl get ep | awk '/^kubernetes / { print $2 }' | cut -d: -f1 )
sudo sed -i "s|REPLACEME|$masterIP|" /opt/bgp_peers.sh

exec 3</tmp/nodes
while IFS='' read -r -u 3 line || [[ -n "$line" ]] 
do
   pushFiles ${line}
done