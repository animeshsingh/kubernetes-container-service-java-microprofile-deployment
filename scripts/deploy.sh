#!/bin/bash

function sleep_func() {
#statements
echo -e "sleeping for 1m"
sleep 60s
}

function download_helm() {
  #statements
  curl  https://storage.googleapis.com/kubernetes-helm/helm-v2.2.3-linux-amd64.tar.gz > helm-v2.2.3-linux-amd64.tar.gz
  tar -xf helm-v2.2.3-linux-amd64.tar.gz
  chmod +x ./linux-amd64
  # Install Tiller using Helm
  echo "Install Tiller"
  linux-amd64/helm init
}

function install_helm(){
  #Add the repository
  linux-amd64/helm repo add mb http://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/wasdev/microservicebuilder/helm/
  #Install Microservice Builder Fabric using Helm
  sleep 60s
  linux-amd64/helm install mb/fabric
}


echo "Create Java microservices using MicroProfile"
IP_ADDR=$(bx cs workers $CLUSTER_NAME | grep deployed | awk '{ print $2 }')
if [ -z $IP_ADDR ]; then
  echo "$CLUSTER_NAME not created or workers not ready"
  exit 1
fi

echo -e "Configuring vars"
exp=$(bx cs cluster-config $CLUSTER_NAME | grep export)
if [ $? -ne 0 ]; then
  echo "Cluster $CLUSTER_NAME not created or not ready."
  exit 1
fi
eval "$exp"

echo -e "Deleting previous version of Java microservices using MicroProfile if it exists"
kubectl delete svc,rc,deployments,pods -l app=microprofile-app

kuber=$(kubectl get pods -l app=microprofile-app)
if [ ${#kuber} -ne 0 ]; then
	sleep 120s
fi

echo -e "Installing Helm"
download_helm
install_helm
sleep 3m
install_helm
echo "Deploying speaker"
cd manifests
kubectl create -f deploy-speaker.yaml
#sleep_func

echo "Deploying schedule"
kubectl create -f deploy-schedule.yaml
#sleep_func

echo "Deploying vote"
kubectl create -f deploy-vote.yaml
#sleep_func

echo "Deploying session"
kubectl create -f deploy-session.yaml
#sleep_func

echo "Deploying webapp"
kubectl create -f deploy-webapp.yaml
#sleep_func
echo "Deploying nginx"

sed -i "s/xx.xx.xx.xx/$IP_ADDR/g" deploy-nginx.yaml
kubectl create -f deploy-nginx.yaml
#sleep_func
sleep 5m

PORT=$(kubectl get service nginx-svc | grep nginx-svc | sed 's/.*://g' | sed 's/\/.*//g')

echo ""
echo "View the Java microservices using MicroProfile at http://$IP_ADDR:$PORT"
