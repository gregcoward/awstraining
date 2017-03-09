#!/bin/bash -x
function pushFiles() {
    scp -i /home/centos/privatekey.pem -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no /opt/k8s-bigip-ctlr-master-26326.tar.gz admin@${1}:~/k8s-bigip-ctlr-master-26326.tar.gz
    scp -i /home/centos/privatekey.pem -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no /opt/calicoctl admin@${1}:~/calicoctl
    ssh -i /home/centos/privatekey.pem -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no admin@${1} "sudo docker load -i ~/k8s-bigip-ctlr-master-26326.tar.gz"
    ssh -i /home/centos/privatekey.pem -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no admin@${1} "sudo docker run -d -p 5000:5000 --restart=always --name registry registry:2"
    ssh -i /home/centos/privatekey.pem -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no admin@${1} "sudo docker images"
    ssh -i /home/centos/privatekey.pem -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no admin@${1} "sudo docker tag 93d8e97443f8 localhost:5000/cc"
    ssh -i /home/centos/privatekey.pem -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no admin@${1} "sudo docker push localhost:5000/cc"
    ssh -i /home/centos/privatekey.pem -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no admin@${1} "chmod +x ~/calicoctl"
    ssh -i /home/centos/privatekey.pem -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no admin@${1} "sudo ~/calicoctl /usr/bin"
}
# Get Master IP address
masterIP=$( kubectl get ep | awk '/^kubernetes / { print $2 }' | cut -d: -f1 )
# Find Node IP addresses
kubectl get nodes | grep internal | cut -d" " -f1 | while read line
do
   ipAddress=$(nslookup $line | awk '/^Address: / { print $2 }')
   if [[ ${ipAddress} == ${masterIP} ]]; then
        echo "Do nothing."
   else
        echo ${ipAddress} >> /tmp/nodes
   fi
done
#
exec 3</tmp/nodes
while IFS='' read -r -u 3 line || [[ -n "$line" ]] 
do
   pushFiles ${line}
done