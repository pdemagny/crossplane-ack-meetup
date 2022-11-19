# Crossplane Examples

## Managed Resources

```bash
# List existing CRDs provided by ACK Controllers in your cluster
❯ kubectl get crds | grep crossplane
```

```bash
# Create SQS Queues
❯ kubectl apply -f ./1-resources/aws-sqs-queues.yaml

# Observe the results
❯ kubectl get queue.sqs.aws.crossplane.io
❯ kubectl describe queue.sqs.aws.crossplane.io
❯ kubectl get events
❯ CROSSPLANE_AWS_POD_NAME=$(kubectl get pods -n crossplane-system -l pkg.crossplane.io/provider=provider-aws --no-headers -o jsonpath='{.items[0].metadata.name}')
❯ kubectl logs -n crossplane-system "${CROSSPLANE_AWS_POD_NAME}"

# Go ahead and change the delaySeconds attribute for a queue, what's happening ?
❯ AWS_SQS_QUEUE_URL=$(aws sqs get-queue-url --region eu-west-1 --queue-name cp-test-queue --query 'QueueUrl' --output text)
❯ aws sqs set-queue-attributes --queue-url "${AWS_SQS_QUEUE_URL}" --attributes file://1-resources/set-queue-attributes.json --region eu-west-1
❯ watch -n 1 aws sqs get-queue-attributes --queue-url "${AWS_SQS_QUEUE_URL}" --attribute-names All --region eu-west-1

# Or delete a queue (Don't try this at home !)
❯ aws sqs delete-queue --queue-url "${AWS_SQS_QUEUE_URL}" --region eu-west-1
❯ watch -n 1 aws sqs get-queue-attributes --queue-url "${AWS_SQS_QUEUE_URL}" --attribute-names All --region eu-west-1
```

```bash
# Create a VPC Network and 2 VPC Subnets
❯ kubectl apply -f ./1-resources/aws-vpc-network.yaml

# Observe the results
❯ kubectl get managed
```

```bash
# Create an Amazon RDS DBInstance
❯ kubectl apply -f ./1-resources/aws-rds-dbinstance.yaml

# Observe the results
❯ kubectl describe dbinstance.rds.aws.crossplane.io/cp-test-db

# After a few minutes, you should see something like this
❯ watch -n 1 "aws rds describe-db-instances --region eu-west-1 --query 'DBInstances[*].[DBInstanceStatus, Endpoint.Address, Endpoint.Port]' --output text"
available       cp-test-db.<REDACTED>.eu-west-1.rds.amazonaws.com     5432

# After a few minutes, you can check that Crossplane has populated the connection secret with
❯ kubectl get secret -n default cp-test-db-out -o jsonpath='{.data.password}' | base64 -d

# Cleaning up
❯ kubectl delete dbinstance.rds.aws.crossplane.io/cp-test-db
❯ kubectl delete -f './1-resources/*.yaml'
```

## Compositions

```bash
# Install the example RDS & S3 XRDs and Compositions in your cluster
❯ kubectl apply -f ./2-compositions/rds -f ./2-compositions/s3

# For the RDS example, you will need to create a VPC & 2 Subnets first, you can do so by re-using the example from the `./1-resources/` directory
❯ kubectl apply -f ./1-resources/aws-vpc-network.yaml

# Get the VPCId and the Subnet IDs and update the placeholders in the ./2-compositions/postgres.yaml file either manually:
❯ kubectl get managed
# Or with sed:
❯ sed -i -e "s/<YOUR_VPC_ID>/$(kubectl get vpcs.ec2.aws.crossplane.io cp-test-vpc -o jsonpath="{.status.atProvider.vpcId}")/" \
  -e "s/<YOUR_SUBNET1_ID>/$(kubectl get subnets.ec2.aws.crossplane.io cp-test-vpc-sn1 -o jsonpath="{.status.atProvider.subnetId}")/" \
  -e "s/<YOUR_SUBNET2_ID>/$(kubectl get subnets.ec2.aws.crossplane.io cp-test-vpc-sn2 -o jsonpath="{.status.atProvider.subnetId}")/" ./2-compositions/postgres.yaml

# Once you have edited the ./2-compositions/postgres.yaml file, apply it
❯ kubectl apply -f ./2-compositions/postgres.yaml

# You can now see your RelationalDatabase
❯ kubectl get relationaldatabases.awsblueprints.io cp-test-xdb

# Or its composite resources individually
❯ kubectl get managed

# After a few minutes, you can check that Crossplane has populated the connection secret with
❯ kubectl get secret -n default cp-test-xdb-out -o jsonpath='{.data.password}' | base64 -d

# Cleaning up
❯ kubectl delete -f './2-compositions/rds/*.yaml' -f './2-compositions/s3/*.yaml' -f './2-compositions/*.yaml'
```

## Packages

```bash
# First, build up a Configuration package containing everything to get a PostGres DB instance from either AWS or GCP
❯ kubectl crossplane build configuration --verbose -f 3-packages/ --name cp-test-pkg

# Login to your Docker Hub account
❯ docker login

# Push this Configuration package to your registry
❯ kubectl crossplane push configuration --verbose -f 3-packages/cp-test-pkg.xpkg pdemagnyhub/cp-test-pkg:0.0.1

# Install on whatever cluster you'd like
❯ kubectl crossplane install configuration --verbose pdemagnyhub/cp-test-pkg:0.0.1 cp-test-pkg

# Observe the results
❯ kubectl get providers.pkg.crossplane.io
❯ kubectl get crds | grep postgres
```
