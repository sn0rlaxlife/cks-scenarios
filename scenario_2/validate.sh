#!/bin/bash

# This script is used to validate the scenario in scaling down the deployments that found CVE's associated with them

# Set colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "Validating deployment scaling in production namespace..."

# Get the replica count for the deployment in production namespace
REPLICA_COUNT=$(kubectl get deployment deploy-metrics -n production -o jsonpath='{.spec.replicas}')

# Check if command was successful
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to get deployment information. Make sure deployment exists.${NC}"
    exit 1
fi

# Validate replica count is 0
if [ "$REPLICA_COUNT" -eq 0 ]; then
    echo -e "${GREEN}✓ Success: Deployment 'deploy-metrics' in production namespace is correctly scaled down to 0 replicas.${NC}"
else
    echo -e "${RED}✗ Failed: Deployment 'deploy-metrics' in production namespace has $REPLICA_COUNT replicas. It should be scaled down to 0.${NC}"
    echo "Please run: kubectl scale deployment deploy-metrics -n production --replicas=0"
    exit 1
fi

# Additional check: verify that no pods are running for this deployment
RUNNING_PODS=$(kubectl get pods -n production -l app=nginx --field-selector=status.phase=Running --no-headers | wc -l)
if [ "$RUNNING_PODS" -eq 0 ]; then
    echo -e "${GREEN}✓ Success: No running pods found for the deployment.${NC}"
else
    echo -e "${RED}⚠ Warning: Found $RUNNING_PODS running pods even though replica count is set to $REPLICA_COUNT.${NC}"
    echo "This could be due to pods still terminating or potential issues with the deployment."
fi

echo "Validation completed."
exit 0
