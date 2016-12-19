# k8s
Kubernetes setup and Docker image to work with.


# Setup an entire cluster from scratch on blank aws.

## Pre-Reqs
* Docker
* Aws token
## Create a user and get IAM keys
Use [this url](https://console.aws.amazon.com/iam/home#/users$new?step=details) to create a user.

## Add key and token to aws/credentials
```
[default]
aws_access_key_id = <access key>
aws_secret_access_key = <secret key>
```

## On your machine
```bash
# Build dockerfile if you have not already
$ cd /path/to/this/repo
$ docker build -t kubernetes .

# Run the docker image and load the aws volume

$ docker run -v ~/.aws:/root/.aws:ro -v ~/.kube:/root/.kube -v ~/.ssh:/root/.ssh -it kubernetes
```

## Inside the container
### Basic setup
```bash
$ export BASE_FQDN="example.com"
$ export CLUSTER_DOMAIN="k8s.$BASE_FQDN"
$ create_hosted_zone.sh
$ setup_cluster.sh
# Once these worked.
$ kops update cluster $CLUSTER_DOMAIN --yes
$ kubectl create -f https://raw.githubusercontent.com/kubernetes/kops/v1.4.3/addons/monitoring-standalone/v1.2.0.yaml
$ kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.5.0/src/deploy/kubernetes-dashboard.yaml
```
### Options for further configuration
```bash
# Set the instance type to be used for master
$ export MASTER_SIZE="t2.large"
# Set the instance type to be used for minion nodes
$ export NODE_SIZE="t2.medium"
# Number of minion nodes
$ export NODE_COUNT=2
# Multiple availability zones for the k8s cluster
# The following command selects all availability zones under current region
$ export AVAILABILITY_ZONES=$(aws ec2 describe-availability-zones | jq -r '[.AvailabilityZones[].ZoneName]| join(",")')
# Location constraint on s3 buckets
$ export S3_BUCKET_LOCATION_CONSTRAINT=${S3_BUCKET_LOCATION_CONSTRAINT:-`aws configure get region`}

# Use a different state store for kops
$ export KOPS_STATE_STORE="s3://yolo-my-bucket"
```