### CKS Scenario 1 ###

This repository houses the first scenario in CKS Training this is intended to demonstrate building out my own scenarios based on attack methods

## Scenario ##
Pre-requisites
```bash
chmod +x scenario.sh
./scenario.sh
```

Once the scenario is deployed and running follow the tasks outlined here to meet the validation.sh methods

The following namespaces have been created cks-training with three specific pods explicit-insecure-pod, secure-pod, insecure-pod the task is
to extract the serviceAccountToken in the insecure pod and identify the secrets that are able to be accessed with the use of this automountServiceAccountToken.

You have to place the extracted secrets from insecure-pod in the the /tmp/exercise-completed/ directory inside the pod itself with the following parameters
password.txt (this is checked via validation.sh), api-key.txt.

This specific method demonstrates the intricacies of running pods with automountServiceAccountToken in a pod with a service account that has access to other
resources.

