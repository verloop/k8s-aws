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
```bash
# Set variables
$ BASE_FQDN="test.verloop.io"
# set kops option
$ export KOPS_STATE_STORE="s3://verloop-k8s-state-store"
# Domain of the cluster
$ CLUSTER_DOMAIN="k8s.$BASE_FQDN"
# Set availability zone
# for multi-zone 
# AVAILABILITY_ZONES=$(aws ec2 describe-availability-zones | jq -r '[.AvailabilityZones[].ZoneName]| join(",")')
$ AVAILABILITY_ZONES=$(aws ec2 describe-availability-zones | jq -r '.AvailabilityZones[0].ZoneName')

# Small for test
$ NODE_SIZE="t2.small"
$ MASTER_SIZE="t2.medium"
$ NODE_COUNT=1


$ S3_BUCKET_LOCATION_CONSTRAINT=$(aws configure get region)

# PS: save $CALLER_REF_ID, you might need it next time if hosted zone didn't work
$ CALLER_REF_ID=${CALLER_REF_ID:-`python -c "import uuid; print(uuid.uuid4())"`}
$ echo $CALLER_REF_ID

# Create a route53 hosted zone
$ aws route53 create-hosted-zone --name $BASE_FQDN --caller-reference $CALLER_REF_ID

# Use the domain name to grab the newly made hosted zone id
$ HOSTED_ZONE_ID=$(aws route53 list-hosted-zones | jq -r '.HostedZones[]| select(.Name="$DOMAIN")| .Id')

# Use the hosted zone id to grab name servers

$ NS_FROM_AWS=$(aws route53 get-hosted-zone --id "$HOSTED_ZONE_ID" | jq -r '.DelegationSet.NameServers | sort[]')
```


**Add these name servers on your provider if it's not on route53**

```bash
# Still inside the container, test if the NS propagated
$ NS_FROM_DIG=$(curl -s http://dig.jsondns.org/IN/$BASE_FQDN/NS | jq -r '[.answer[].rdata] | sort[]')

# Check if NS records matched
$ if [ "$NS_FROM_AWS" == "$NS_FROM_DIG" ]; then echo "NS looks good, start installing"; else echo -e "Nope"; fi

# Set the state store up
$ aws s3api create-bucket --bucket $(echo $KOPS_STATE_STORE | cut -d'/' -f3) --create-bucket-configuration LocationConstraint=$S3_BUCKET_LOCATION_CONSTRAINT
# Create the cluster
$ kops create cluster --kubernetes-version 1.5.1 --zones ${AVAILABILITY_ZONES} --node-count $NODE_COUNT --node-size $NODE_SIZE --master-size $MASTER_SIZE $CLUSTER_DOMAIN

# PS: the following command will bring the cluster up
$ kops update cluster $CLUSTER_DOMAIN --yes

# Install heapster and dashboard

$ kubectl create -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/monitoring-standalone/v1.2.0.yaml
$ kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.5.0/src/deploy/kubernetes-dashboard.yaml
```