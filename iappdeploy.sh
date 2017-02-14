#!/bin/bash
export PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin/"

## You can add or remove any command line arguments that you need to make this work with your iApp.

while getopts i:d:x: option
do	case "$option" in
     i) ipAddress=$OPTARG;;
     d) domainFqdn=$OPTARG;;
     x) passwd=$OPTARG;;
    esac 
done

user="admin"

# download and install Certificate
## Uncomment the below section to download and install certificates on your BIG-IP
#echo "Starting Certificate download"
#certificate_location=$sslCert
#curl -k -s -f --retry 5 --retry-delay 10 --retry-max-time 10 -o /config/o365FedCert.pfx $certificate_location
# 
#response_code=$(curl -sku $user:$passwd -w "%{http_code}" -X POST -H "Content-Type: application/json" https://localhost/mgmt/tm/sys/crypto/pkcs12 -d '{"command": "install","name": "o365FedCert","options": [ { "from-local-file": "/config/o365FedCert.pfx" }, { "passphrase": "'"$sslPswd"'" } ] }' -o /dev/null)
#
#if [[ $response_code != 200  ]]; then
#     echo "Failed to install SSL cert; exiting with response code '"$response_code"'"
#     exit
#else 
#     echo "Certificate download complete."
#fi

# download iApp templates
## Uncomment the below section if you need to download a customer iApp
#template_location="http://cdn.f5.com/product/blackbox/staging/azure"
#
#for template in f5.microsoft_office_365_idp.v1.1.0.tmpl
#do
#     curl -k -s -f --retry 5 --retry-delay 10 --retry-max-time 10 -o /config/$template $template_location/$template
#     response_code=$(curl -sku $user:$passwd -w "%{http_code}" -X POST -H "Content-Type: application/json" https://localhost/mgmt/tm/sys/config -d '{"command": "load","name": "merge","options": [ { "file": "/config/'"$template"'" } ] }' -o /dev/null)
#     if [[ $response_code != 200  ]]; then
#          echo "Failed to install iApp template; exiting with response code '"$response_code"'"
#          exit
#     else
#          echo "iApp template installation complete."
#     fi
#     sleep 10
#done

# deploy application
response_code=$(curl -sku $user:$passwd -w "%{http_code}" -X POST -H "Content-Type: application/json" https://localhost/mgmt/tm/sys/application/service/ -d '{"name":"windows_test_app","partition":"Common","deviceGroup":"none","inheritedDevicegroup":"true","inheritedTrafficGroup":"false","strictUpdates":"enabled","template":"/Common/f5.microsoft_iis","trafficGroup":"none","lists":[{"name":"irules__irules","encrypted":"no"},{"name":"net__client_vlan","encrypted":"no","value":["/Common/external"]}],"tables":[{"name":"basic__snatpool_members"},{"name":"net__snatpool_members"},{"name":"optimizations__hosts"},{"name":"pool__hosts","columnNames":["name"],"rows":[{"row":["'"$domainFqdn"'"]}]},{"name":"pool__members","columnNames":["addr","port","connection_limit"],"rows":[{"row":["'"$ipAddress"'","80","0"]}]},{"name":"server_pools__servers"}],"variables":[{"name":"client__http_compression","encrypted":"no","value":"/#create_new#"},{"name":"client__standard_caching_without_wa","encrypted":"no","value":"/#create_new#"},{"name":"client__tcp_wan_opt","encrypted":"no","value":"/#create_new#"},{"name":"monitor__credentials","encrypted":"no","value":"none"},{"name":"monitor__frequency","encrypted":"no","value":"30"},{"name":"monitor__http_method","encrypted":"no","value":"GET"},{"name":"monitor__http_version","encrypted":"no","value":"http11"},{"name":"monitor__monitor","encrypted":"no","value":"/#create_new#"},{"name":"monitor__response","encrypted":"no","value":"200 OK"},{"name":"monitor__uri","encrypted":"no","value":"/"},{"name":"net__client_mode","encrypted":"no","value":"wan"},{"name":"net__route_to_bigip","encrypted":"no","value":"no"},{"name":"net__same_subnet","encrypted":"no","value":"no"},{"name":"net__server_mode","encrypted":"no","value":"lan"},{"name":"net__snat_type","encrypted":"no","value":"automap"},{"name":"net__vlan_mode","encrypted":"no","value":"enabled"},{"name":"pool__addr","encrypted":"no","value":"0.0.0.0"},{"name":"pool__http","encrypted":"no","value":"/#create_new#"},{"name":"pool__lb_method","encrypted":"no","value":"least-connections-member"},{"name":"pool__mask","encrypted":"no","value":"0.0.0.0"},{"name":"pool__persist","encrypted":"no","value":"/#cookie#"},{"name":"pool__pool_to_use","encrypted":"no","value":"/#create_new#"},{"name":"pool__port","encrypted":"no","value":"80"},{"name":"pool__use_pga","encrypted":"no","value":"no"},{"name":"pool__xff","encrypted":"no","value":"yes"},{"name":"server__ntlm","encrypted":"no","value":"/#do_not_use#"},{"name":"server__oneconnect","encrypted":"no","value":"/#create_new#"},{"name":"server__slow_ramp_setvalue","encrypted":"no","value":"300"},{"name":"server__tcp_lan_opt","encrypted":"no","value":"/#create_new#"},{"name":"server__tcp_req_queueing","encrypted":"no","value":"no"},{"name":"server__use_slow_ramp","encrypted":"no","value":"yes"},{"name":"ssl__mode","encrypted":"no","value":"no_ssl"},{"name":"ssl_encryption_questions__advanced","encrypted":"no","value":"yes"},{"name":"ssl_encryption_questions__help","encrypted":"no","value":"hide"},{"name":"stats__request_logging","encrypted":"no","value":"/#do_not_use#"}]}' -o /dev/null)

if [[ $response_code != 200  ]]; then
     echo "Failed to install iApp template; exiting with response code ${response_code}"
     exit ${response_code}
else 
     echo "Deployment complete."
fi


# How to get the json formatted string from an iApp that has been run and fully configured ... 
# *** Please NOTE the "~" ...***
#curl -skvv -u admin:admin -X GET -H "Content-Type: application/json" https://localhost/mgmt/tm/sys/application/service/~Common~iappname.app~iappname | jq . 

## Create an RDP Pool for access to the Windows Server.

pool_response_code=$(curl -sku ${user}:${passwd} -w "%{http_code}" -X POST -H "Content-Type: application/json" https://localhost:8443/mgmt/tm/ltm/pool -d '{"name":"rdp_pool","description":"rdp_pool","monitor":"/Common/tcp ","members":[{"name":"'"$ipAddress"':3389","address":"'"$ipAddress"'"}]}')

if [[ ${pool_response_code} != 200 ]]; then
    echo "Failed to create the rdp_pool; exiting with response code ${pool_response_code}"
    exit ${pool_response_code}
else
    echo "RDP Pool creation complete."
fi 

## Create an RDP Virtual for access to the Windows Server.

vip_response_code=$(curl -sku ${user}:${passwd} -w "%{http_code}" -X POST -H "Content-Type: application/json" https://localhost:8443/mgmt/tm/ltm/virtual -d '{"name":"rdp_vip","destination":"/Common/0.0.0.0:3389","enabled":true,"ipProtocol":"tcp","mask":"any","pool":"/Common/rdp_pool","source":"0.0.0.0/0","sourceAddressTranslation":{"type":"automap"},"translateAddress":"enabled","translatePort":"enabled","vlansDisabled":true,"vsIndex":3,"profiles":[{"name":"tcp"}]}')

if [[ ${vip_response_code} != 200 ]]; then
    echo "Failed to create RDP-VIP; exiting with response code ${vip_response_code}"
    exit ${vip_response_code}
else
    echo "RDP_VIP creation complete."
fi
exit

