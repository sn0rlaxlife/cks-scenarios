#!/bin/bash

# CKS Training Validation Script
# This script validates that the user has successfully accessed and decoded secrets from the insecure pod

echo "🔍 Starting validation of the automountServiceAccountToken exercise..."
echo

# Check if namespace exists
if ! kubectl get namespace cks-training &>/dev/null; then
  echo "❌ ERROR: The cks-training namespace doesn't exist. Have you run the scenario.sh script?"
  exit 1
fi

# Check if the insecure pod is running
if ! kubectl get pod -n cks-training insecure-pod -o jsonpath='{.status.phase}' 2>/dev/null | grep -q "Running"; then
  echo "❌ ERROR: The insecure-pod is not running. Have you run the scenario.sh script?"
  exit 1
fi

echo "✅ Found the required namespace and pod."
echo "🔍 Checking if you completed the exercise by decoding the secrets..."

# Check if the directory and files exist
DIR_EXISTS=$(kubectl exec -n cks-training insecure-pod -- test -d /tmp/exercise-completed && echo "yes" || echo "no")
if [[ "$DIR_EXISTS" != "yes" ]]; then
  echo "❌ ERROR: Directory /tmp/exercise-completed not found in the insecure pod."
  echo "🔍 Have you created the directory and decoded the secrets as instructed in the scenario?"
  exit 1
fi

# Check the password file
PASSWORD_CORRECT=$(kubectl exec -n cks-training insecure-pod -- cat /tmp/exercise-completed/password.txt 2>/dev/null | grep -q "supersecret" && echo "yes" || echo "no")
if [[ "$PASSWORD_CORRECT" != "yes" ]]; then
  echo "❌ ERROR: The decoded password is incorrect or missing."
  echo "🔍 Make sure you've properly decoded the password from the secret and saved it to /tmp/exercise-completed/password.txt"
  exit 1
fi

# Check the API key file
APIKEY_CORRECT=$(kubectl exec -n cks-training insecure-pod -- cat /tmp/exercise-completed/api-key.txt 2>/dev/null | grep -q "production-api-key-12345" && echo "yes" || echo "no")
if [[ "$APIKEY_CORRECT" != "yes" ]]; then
  echo "❌ ERROR: The decoded API key is incorrect or missing."
  echo "🔍 Make sure you've properly decoded the API key from the secret and saved it to /tmp/exercise-completed/api-key.txt"
  exit 1
fi

echo "✅ Successfully verified you decoded both secrets correctly!"
echo "🎉 Congratulations! You've successfully completed the automountServiceAccountToken exercise."
echo "🔒 Remember: In real-world scenarios, always set automountServiceAccountToken: false when possible."
echo "   This prevents pods from automatically gaining access to Kubernetes API credentials."
