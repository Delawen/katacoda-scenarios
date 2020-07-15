launch.sh
cd /tmp
wget https://github.com/apache/camel-k/releases/download/v1.1.0/camel-k-client-1.1.0-linux-64bit.tar.gz
tar -xvzf /tmp/camel-k-client-1.1.0-linux-64bit.tar.gz
mv kamel ~/
cd
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm install registry stable/docker-registry \
  --version 1.9.4 \
  --namespace kube-system \
  --set service.type=NodePort \
  --set service.nodePort=31500
export REGISTRY_ADDRESS=$(kubectl -n kube-system get service registry-docker-registry -o jsonpath='{.spec.clusterIP}')  

export NODE_PORT=$(kubectl get --namespace kube-system -o jsonpath="{.spec.ports[0].nodePort}" services registry-docker-registry)
export NODE_IP=$(kubectl get nodes --namespace kube-system -o jsonpath="{.items[0].status.addresses[0].address}")     
echo "http://"$NODE_IP:$NODE_PORT
echo $REGISTRY_ADDRESS

helm repo add camel-k https://apache.github.io/camel-k/charts
helm repo update
helm install \
  --generate-name \
  --set platform.build.registry.address=$NODE_IP:$NODE_PORT \
  --set platform.build.registry.insecure=true \
  camel-k/camel-k

#./kamel install --cluster-setup
#./kamel install --registry $REGISTRY_ADDRESS
./kamel init wa.js
./kamel run wa.js
./kamel get

