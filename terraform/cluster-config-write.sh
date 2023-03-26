cp cluster.yml.template cluster.yml
sed -i'' -e "s#{certificate-authority-data}#$KUBE_CLUSTER_CA_CERT_DATA#g" ./cluster.yml
sed -i'' -e "s#{server-domain}#$TF_VARS_server_base_domain#g" ./cluster.yml
sed -i'' -e "s#{server-port}#$SERVER_KUBE_PORT#g" ./cluster.yml
sed -i'' -e "s#{client-certificate-data}#$KUBE_CLIENT_CERT_DATA#g" ./cluster.yml
sed -i'' -e "s#{client-key-data}#$KUBE_CLIENT_KEY_DATA#g" ./cluster.yml
rm cluster.yml-e
