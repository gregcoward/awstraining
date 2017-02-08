#!/bin/bash
date
echo 'Starting BIG-IP Applicaiton Config'
POOLMEM='{"Fn::GetAtt": ["Webserver","PrivateIp"]}'
tmsh save /sys config
tmsh create ltm pool rdp-pool members add { ${POOLMEM}:3389} } monitor tcp
tmsh create ltm pool http-pool members add { ${POOLMEM}:80 } monitor http
tmsh save /sys config
tmsh create ltm virtual /Common/rdp-3389 { destination 0.0.0.0:3389 mask any ip-protocol tcp pool /Common/rdp-pool profiles replace-all-with { tcp { } }  source 0.0.0.0/0 source-address-translation { type automap } translate-address enabled translate-port enabled }
tmsh create ltm virtual /Common/http-80 { destination 0.0.0.0:80 mask any ip-protocol tcp pool /Common/http-pool profiles replace-all-with { tcp { } http { } }  source 0.0.0.0/0 source-address-translation { type automap } translate-address enabled translate-port enabled }
tmsh save /sys config
date
echo 'BIG-IP Applicaiton Configuration Done'


#!/bin/bash
GATEWAY_MAC=`ifconfig eth0 | egrep HWaddr | awk '{print tolower($5)}'`
GATEWAY_CIDR_BLOCK=`curl http://169.254.169.254/latest/meta-data/network/interfaces/macs/${GATEWAY_MAC}/subnet-ipv4-cidr-block`
GATEWAY_NET=${GATEWAY_CIDR_BLOCK%/*}
GATEWAY_PREFIX=${GATEWAY_CIDR_BLOCK#*/}
GATEWAY=`echo ${GATEWAY_NET} | awk -F. '{ print $1\".\"$2\".\"$3\".\"$4+1 }'`
VPC_CIDR_BLOCK=`curl http://169.254.169.254/latest/meta-data/network/interfaces/macs/${GATEWAY_MAC}/vpc-ipv4-cidr-block`
VPC_NET=${VPC_CIDR_BLOCK%/*}
VPC_PREFIX=${VPC_CIDR_BLOCK#*/}
NAME_SERVER=`echo ${VPC_NET} | awk -F. '{ print $1\".\"$2\".\"$3\".\"$4+2 }'`
POOLMEM='{"Fn::GetAtt": ["Webserver","PrivateIp"]}'
POOLMEMPORT=3389
APPNAME='demo-app-1'
VIRTUALSERVERPORT=3389