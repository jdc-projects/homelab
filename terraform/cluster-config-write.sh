cp cluster.yml.template cluster.yml
sed -i "s#{certificate-authority-data}#$KUBE_CLUSTER_CA_CERT_DATA#g" ./cluster.yml
sed -i "s#{server-domain}#$SERVER_BASE_DOMAIN#g" ./cluster.yml
sed -i "s#{server-port}#$SERVER_KUBE_PORT#g" ./cluster.yml
sed -i "s#{client-certificate-data}#$KUBE_CLIENT_CERT_DATA#g" ./cluster.yml
sed -i "s#{client-key-data}#$KUBE_CLIENT_KEY_DATA#g" ./cluster.yml
