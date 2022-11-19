# ACK Examples

```bash
# List existing CRDs provided by ACK Controllers in your cluster
❯ kubectl get crds | grep .services.k8s.aws
```

```bash
# Create an Amazon Managed service for Prometheus Workspace
❯ kubectl apply -f ./amp-workspace.yaml

# Observe the results
❯ kubectl describe workspace.prometheusservice.services.k8s.aws/ack-amp-test-workspace
❯ aws amp list-workspaces --region eu-west-1 --query 'workspaces[0].arn' --output text
❯ ACK_POD_NAME=$(kubectl get pods -n ack-amp -l app.kubernetes.io/name=ack-amp --no-headers -o jsonpath='{.items[0].metadata.name}')
❯ kubectl logs -n ack-amp "${ACK_POD_NAME}"
```

```bash
# Create an Amazon S3 Bucket
❯ kubectl apply -f ./s3-bucket.yaml

# Observe the results
❯ kubectl describe bucket.s3.services.k8s.aws/ack-test-bucket-15
❯ aws s3 ls
❯ ACK_POD_NAME=$(kubectl get pods -n ack-s3 -l app.kubernetes.io/name=ack-s3 --no-headers -o jsonpath='{.items[0].metadata.name}')
❯ kubectl logs -n ack-s3 "${ACK_POD_NAME}"
```

```bash
# Create an Amazon RDS DBInstance
❯ kubectl apply -f './rds-*.yaml'

# Observe the results
❯ kubectl describe dbinstance.rds.services.k8s.aws/ack-test-db
❯ ACK_POD_NAME=$(kubectl get pods -n ack-rds -l app.kubernetes.io/name=ack-rds --no-headers -o jsonpath='{.items[0].metadata.name}')
❯ kubectl logs -n ack-rds "${ACK_POD_NAME}"
❯ kubectl get --watch dbinstance.rds.services.k8s.aws/ack-test-db

# After a few minutes, you should see something like this
❯ aws rds describe-db-instances --region eu-west-1 --query 'DBInstances[*].[DBInstanceStatus, Endpoint.Address, Endpoint.Port]' --output text
available       ack-test-db.<REDACTED>.eu-west-1.rds.amazonaws.com    3306

# You can check that the ACK RDS controller reconciled these FieldExports with the ConfigMap
❯ kubectl describe configmaps -n default ack-test-db-cm
```

```bash
# Cleaning up
❯ kubectl delete -f './*.yaml'
```
