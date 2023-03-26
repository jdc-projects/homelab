cp cluster.yml.template cluster.yml
sed -i'' -e "s#{certificate-authority-data}#$CLUSTER_CA_CERT_DATA#g" ./cluster.yml
sed -i'' -e "s#{server-domain}#$TF_VAR_server_base_domain#g" ./cluster.yml
sed -i'' -e "s#{server-port}#$SERVER_KUBE_PORT#g" ./cluster.yml
sed -i'' -e "s#{client-certificate-data}#$CLIENT_CERT_DATA#g" ./cluster.yml
sed -i'' -e "s#{client-key-data}#$CLIENT_KEY_DATA#g" ./cluster.yml
