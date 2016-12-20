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
$ export REGION=$(aws configure get region)
$ export CLUSTER_DOMAIN="$REGION.$BASE_FQDN"
## You'll need to create the bucket just once in the entire lifecycle
$ aws s3api create-bucket --bucket $(echo $KOPS_STATE_STORE | cut -d'/' -f3) --create-bucket-configuration LocationConstraint=$REGION

$ create_hosted_zone.sh
$ setup_cluster.sh
# Edit cluster settings as you like. The scope of edits you can make is too big to cover here.
# Configuring some aspects is covered in sections below
$ kops update cluster $CLUSTER_DOMAIN --yes
# Wait till the instances are up
$ kubectl create -f https://raw.githubusercontent.com/kubernetes/kops/v1.4.3/addons/monitoring-standalone/v1.2.0.yaml
$ kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.5.0/src/deploy/kubernetes-dashboard.yaml
```

# Further configuration

## Configuration options before install
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

# Use a different state store for kops
$ export KOPS_STATE_STORE="s3://yolo-my-bucket"
```


## Configure master and node volume size
```bash
# From inside the image.
# List instance groups
$ kops get instancegroups
# You get an output similar to this
# NAME                    ROLE    MACHINETYPE     MIN     MAX     ZONES
# master-ap-south-1a      Master  t2.medium       1       1       ap-south-1a
# nodes                   Node    t2.small        1       1       ap-south-1a
# The NAME column is the one you can use to update things. For changing nodes size
$ kops edit ig nodes
# It will open an editor with yaml config like so.
#metadata:
#  creationTimestamp: "2016-12-19T11:12:08Z"
#  name: nodes
#spec:
#  associatePublicIp: true
#  image: kope.io/k8s-1.4-debian-jessie-amd64-hvm-ebs-2016-10-21
#  machineType: t2.small
#  maxSize: 1
#  minSize: 1
#  role: Node
#  zones:
#  - ap-south-1a

# Add the rootVolumeSize and rootVolumeType keys under spec

#metadata:
#  creationTimestamp: "2016-12-19T11:12:08Z"
#  name: nodes
#spec:
#  associatePublicIp: true
#  image: kope.io/k8s-1.4-debian-jessie-amd64-hvm-ebs-2016-10-21
#  machineType: t2.small
#  maxSize: 1
#  minSize: 1
#  role: Node
#  rootVolumeSize: 10
#  rootVolumeType: gp2
#  zones:
#  - ap-south-1a

# Close the editor and apply the update like so. Assuming $CLUSTER_DOMAIN variable is set from before.
$ kops update cluster $CLUSTER_DOMAIN --yes
# Once the changes are applied
$ kops rolling-update cluster --yes

```

# Known issues

## I get RequestTimeTooSkewed type errors

Try restarting docker daemon first. This usually resets the time slip.

If that doesn't work use `-v /etc/localtime:/etc/localtime:ro` flag when running the docker image.


## After a rolling update, api server panics and route53 does not update

Sign up for GCP
