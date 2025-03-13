#!/bin/bash

# CKS Training Scenario: automountServiceAccountToken Security Issues
# This script creates insecure pods with automountServiceAccountToken enabled

echo "Creating CKS training environment for automountServiceAccountToken scenarios..."

# Create a namespace for our training
kubectl create namespace cks-training

# Create a service account with automountServiceAccountToken defaulted to true (insecure)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: insecure-sa
  namespace: cks-training
EOF

# Create a service account with automountServiceAccountToken explicitly set to true (insecure)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: explicit-insecure-sa
  namespace: cks-training
automountServiceAccountToken: true
EOF

# Create a secure service account for comparison
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: secure-sa
  namespace: cks-training
automountServiceAccountToken: false
EOF

# Create a secret to demonstrate access via service account token
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: sensitive-data
  namespace: cks-training
type: Opaque
data:
  password: $(echo -n "supersecret" | base64)
  api-key: $(echo -n "production-api-key-12345" | base64)
EOF

# Create a role that allows reading secrets
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secret-reader
  namespace: cks-training
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
EOF

# Bind the role to the insecure service account
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-secrets
  namespace: cks-training
subjects:
- kind: ServiceAccount
  name: insecure-sa
  namespace: cks-training
roleRef:
  kind: Role
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io
EOF

# Deploy an insecure pod with the default token mounted
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: insecure-pod
  namespace: cks-training
spec:
  serviceAccountName: insecure-sa
  containers:
  - name: alpine
    image: alpine:3.14
    command: 
    - /bin/sh
    - -c
    - |
      apk add --no-cache curl && sleep infinity
EOF

# Deploy an insecure pod with explicitly requesting token mounting
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: explicit-insecure-pod
  namespace: cks-training
spec:
  serviceAccountName: secure-sa
  automountServiceAccountToken: true
  containers:
  - name: alpine
    image: alpine:3.14
    command: 
    - /bin/sh
    - -c
    - |
      apk add --no-cache curl && sleep infinity
EOF

# Deploy a secure pod with token mounting disabled
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
  namespace: cks-training
spec:
  serviceAccountName: secure-sa
  automountServiceAccountToken: false
  containers:
  - name: alpine
    image: alpine:3.14
    command: 
    - /bin/sh
    - -c
    - |
      apk add --no-cache curl && sleep infinity
EOF

echo "Environment created successfully!"
echo ""
echo "To verify the token mounting:"
echo "kubectl exec -n cks-training insecure-pod -- ls -la /var/run/secrets/kubernetes.io/serviceaccount/"
echo "kubectl exec -n cks-training explicit-insecure-pod -- ls -la /var/run/secrets/kubernetes.io/serviceaccount/"
echo "kubectl exec -n cks-training secure-pod -- ls -la /var/run/secrets/kubernetes.io/serviceaccount/"
echo ""
echo "To demonstrate accessing secrets with the mounted token (from insecure-pod):"
echo ""
echo "# Option 1: Execute commands directly (non-interactive):"
echo "kubectl exec -n cks-training insecure-pod -- sh -c 'KUBE_TOKEN=\$(cat /var/run/secrets/kubernetes.io/serviceaccount/token) && \\"
echo "  curl -s https://kubernetes.default.svc/api/v1/namespaces/cks-training/secrets \\"
echo "  -H \"Authorization: Bearer \$KUBE_TOKEN\" -k'"
echo ""
echo "# Option 2: Get an interactive shell and run commands manually:"
echo "kubectl exec -it -n cks-training insecure-pod -- sh"
echo "# Then inside the container:"
echo "KUBE_TOKEN=\$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
echo "curl -s https://kubernetes.default.svc/api/v1/namespaces/cks-training/secrets \\"
echo "  -H \"Authorization: Bearer \$KUBE_TOKEN\" -k"
echo "curl -s https://kubernetes.default.svc/api/v1/namespaces/cks-training/secrets/sensitive-data \\"
echo "  -H \"Authorization: Bearer \$KUBE_TOKEN\" -k"
echo ""
echo "# TASK: To complete this exercise, create a directory and save the decoded secrets:"
echo "mkdir -p /tmp/exercise-completed"
echo "KUBE_TOKEN=\$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
echo "SECRET_JSON=\$(curl -s https://kubernetes.default.svc/api/v1/namespaces/cks-training/secrets/sensitive-data \\"
echo "  -H \"Authorization: Bearer \$KUBE_TOKEN\" -k)"
echo "echo \$SECRET_JSON | grep -o '\"password\":\"[^\"]*\"' | cut -d\":\" -f2 | tr -d '\"' | base64 -d > /tmp/exercise-completed/password.txt"
echo "echo \$SECRET_JSON | grep -o '\"api-key\":\"[^\"]*\"' | cut -d\":\" -f2 | tr -d '\"' | base64 -d > /tmp/exercise-completed/api-key.txt"
echo ""
echo "# After completing these steps, run the validation script to verify your work:"
echo "# ./validate.sh"
echo ""

echo "To see what happens with the secure pod (should fail):"
echo "kubectl exec -n cks-training secure-pod -- sh -c 'ls -l /var/run/secrets/kubernetes.io/serviceaccount/ 2>/dev/null || echo \"No token mounted!\"'"
echo ""
echo "To clean up the environment when done:"
echo "kubectl delete namespace cks-training"


