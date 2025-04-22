## Scenario 2 - Container Scanning ##

* For this scenario the use of Trivy is installed in the scenario.sh script *
For running this follow the instruction below.

```bash
cd scenario_2
chmod +x scenario.sh
chmod +x validate.sh
```

## Scenario Description ##
Two namespaces have been deployed in your cluster you're notified via Slack that the following CVE's are likely in your environment the CVE notation is 
```bash
CVE-2023-52425 and CVE-2024-10041
```

Find the deployment with the following CVE's and scale the deployment to 0 via the replicas use.

After completing this step run the ./validate.sh to ensure you are complete with the scenario.
