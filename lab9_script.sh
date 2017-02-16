#!/bin/bash
#
# Get the proxy tarball.
curl -sk https://raw.githubusercontent.com/gregcoward/awstraining/master/proxy-0-0-1.tgz -o /opt/proxy-0-0-1.tgz
#
chmod 000644 /opt/proxy-0-0-1.tgz
chown root:root /opt/proxy-0-0-1.tgz
#
# Donwload Node
curl --silent --location https://rpm.nodesource.com/setup_7.x | bash -
#
# Install Node
yum -y install nodejs
#
# Extract the proxy
cd /opt
tar -zxvf /opt/proxy-0-0-1.tgz
#
# Start the proxy
"node /opt/proxy/lib/Proxy.js -n ",
{ "Ref" : "appConnectorName" },
" -u ",
{ "Ref" : "adminUsername" },
" -w ",
{ "Ref" : "adminPassword" },
"\n"

cd /opt
curl -O https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz
tar -xvpf aws-cfn-bootstrap-latest.tar.gz
cd aws-cfn-bootstrap-1.4/
python setup.py build
python setup.py install
ln -s /usr/init/redhat/cfn-hup /etc/init.d/cfn-hup
chmod 775 /usr/init/redhat/cfn-hup
cd /opt
mkdir aws
cd aws
mkdir bin
ln -s /usr/bin/cfn-hup /opt/aws/bin/cfn-hup
ln -s /usr/bin/cfn-init /opt/aws/bin/cfn-init
ln -s /usr/bin/cfn-signal /opt/aws/bin/cfn-signal
ln -s /usr/bin/cfn-elect-cmd-leader /opt/aws/bin/cfn-elect-cmd-leader
ln -s /usr/bin/cfn-get-metadata /opt/aws/bin/cfn-get-metadata
ln -s /usr/bin/cfn-send-cmd-event /opt/aws/bin/cfn-send-cmd-event
ln -s /usr/bin/cfn-send-cmd-result /opt/aws/bin/cfn-send-cmd-result