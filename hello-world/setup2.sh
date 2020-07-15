curl -L https://github.com/apache/camel-k/releases/download/v1.1.0/camel-k-client-1.1.0-linux-64bit.tar.gz -o camel-k-client.tar.gz
tar -zxf camel-k-client.tar.gz
sudo mv kamel /usr/local/bin/

export OPENSHIFT_VERSION=v3.11.0
export OPENSHIFT_COMMIT=0cbc58b

# set docker0 to promiscuous mode
# Download and install the oc binary
sudo mount --make-shared /

sudo service docker stop
sudo echo '{"insecure-registries": ["172.30.0.0/16"]}' | sudo tee /etc/docker/daemon.json > /dev/null
sudo service docker start

DOWNLOAD_URL=https://github.com/openshift/origin/releases/download/$OPENSHIFT_VERSION/openshift-origin-client-tools-$OPENSHIFT_VERSION-$OPENSHIFT_COMMIT-linux-64bit.tar.gz
wget -O client.tar.gz ${DOWNLOAD_URL}
tar xvzOf client.tar.gz > oc.bin
sudo mv oc.bin /usr/local/bin/oc
sudo chmod 755 /usr/local/bin/oc

# Figure out this host's IP address
IP_ADDR="$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)"
# Setup cluster dir
sudo mkdir -p /home/runner/lib/oc
sudo chmod 777 /home/runner/lib/oc
cd /home/runner/lib/oc
# Start OpenShift
oc cluster up --public-hostname=$IP_ADDR --enable=persistent-volumes,registry,router
oc login -u system:admin
# Wait until we have a ready node in openshift
TIMEOUT=0
TIMEOUT_COUNT=60
until [ $TIMEOUT -eq $TIMEOUT_COUNT ]; do
  if [ -n "$(oc get nodes | grep Ready)" ]; then
    break
  fi
  echo "openshift is not up yet"
  TIMEOUT=$((TIMEOUT+1))
  sleep 5
done
if [ $TIMEOUT -eq $TIMEOUT_COUNT ]; then
  echo "Failed to start openshift"
  exit 1
fi
echo "openshift is deployed and reachable"

# Installing Camel K cluster resources
kamel install --cluster-setup
