#!/bin/bash -xe

# Create variables
masterIP="empty"
node1IP="empty"
node2IP="empty"

# Get Master IP address
masterIP=$( kubectl get ep | awk '/^kubernetes / { print $2 }' | cut -d: -f1 )

# Find Node IP addresses
kubectl get nodes | grep internal | cut -d" " -f1 | while read line
do
   ipAddress=$(nslookup $line | awk '/^Address: / { print $2 }')
   if [[ ${ipAddress} == ${masterIP} ]]; then
        echo "Do nothing."
   elif [[ ${node1IP} == "empty" ]]; then
        scp -i /home/centos/privatekey.pem -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no /opt/k8s-bigip-ctlr-master-26326.tar.gz admin@${ipAddress}:~/k8s-bigip-ctlr-master-26326.tar.gz
        ssh -i /home/centos/privatekey.pem -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no admin@${ipAddress} "sudo docker load -i ~/k8s-bigip-ctlr-master-26326.tar.gz"
        ssh -i /home/centos/privatekey.pem -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no admin@${ipAddress} "sudo docker run -d -p 5000:5000 --restart=always --name registry registry:2"
        ssh -i /home/centos/privatekey.pem -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no admin@${ipAddress} "sudo docker images"
        ssh -i /home/centos/privatekey.pem -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no admin@${ipAddress} "sudo docker tag 93d8e97443f8 localhost:5000/cc"
        ssh -i /home/centos/privatekey.pem -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no admin@${ipAddress} "sudo docker push localhost:5000/cc"
   else
        scp -i /home/centos/privatekey.pem -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no /opt/k8s-bigip-ctlr-master-26326.tar.gz admin@${ipAddress}:~/k8s-bigip-ctlr-master-26326.tar.gz
        ssh -i /home/centos/privatekey.pem -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no admin@${ipAddress} "sudo docker load -i ~/k8s-bigip-ctlr-master-26326.tar.gz"
        ssh -i /home/centos/privatekey.pem -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no admin@${ipAddress} "sudo docker run -d -p 5000:5000 --restart=always --name registry registry:2"
        ssh -i /home/centos/privatekey.pem -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no admin@${ipAddress} "sudo docker images"
        ssh -i /home/centos/privatekey.pem -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no admin@${ipAddress} "sudo docker tag 93d8e97443f8 localhost:5000/cc"
        ssh -i /home/centos/privatekey.pem -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no admin@${ipAddress} "sudo docker push localhost:5000/cc" 
   fi
done

exit