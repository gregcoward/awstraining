#!/bin/bash -xe
#
while getopts r: option
do	case "$option" in
     r) role=$OPTARG;;     
    esac 
done
accesskey=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/${role} | jq -r .AccessKeyId)
secretkey=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/${role} | jq -r .SecretAccessKey)


