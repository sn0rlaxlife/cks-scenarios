#!/bin/bash

# Create namespaces
kubectl create namespace production
kubectl create namespace infra


# Create deployment manifest for nginx in production namespace
cat <<EOF > nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deploy-metrics
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.26.3
        ports:
        - containerPort: 80
EOF

# Apply nginx deployment
kubectl apply -f nginx-deployment.yaml

# Create deployment manifest for busybox in infra namespace
cat <<EOF > busybox-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deploy-busy
  namespace: infra
spec:
  replicas: 3
  selector:
    matchLabels:
      app: busybox
  template:
    metadata:
      labels:
        app: busybox
    spec:
      containers:
      - name: busybox
        image: busybox:1.36
        command: ["sleep", "3600"]
EOF

# Apply busybox deployment
kubectl apply -f busybox-deployment.yaml

# Clean up temporary manifest files
rm nginx-deployment.yaml busybox-deployment.yaml

echo "Namespaces and deployments created successfully."

# Wait for deployments to be ready
echo "Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=60s -n production deployment/deploy-metrics
kubectl wait --for=condition=available --timeout=60s -n infra deployment/deploy-busy
echo "All deployments are ready."

# Install trivy to run security scan
echo "Installing Trivy..."
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin v0.61.1

# Instructions
echo "Run trivy on the following namespaces infra/prod deployments and find any CVE's if they do exist ensure that the deployment replicas are set to 0."
echo "After finding the CVE's run the following command to set the replicas to 0 then run ./validate.sh to validate the changes."
