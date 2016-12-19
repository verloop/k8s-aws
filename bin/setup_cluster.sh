#!/bin/bash
# Domain of the cluster
BASE_FQDN=${BASE_FQDN:-"test.verloop.io"}
CLUSTER_DOMAIN="k8s.$BASE_FQDN"
# Set availability zone
# for multi-zone 
# AVAILABILITY_ZONES=$(aws ec2 describe-availability-zones | jq -r '[.AvailabilityZones[].ZoneName]| join(",")')
AVAILABILITY_ZONES=${AVAILABILITY_ZONES:-`aws ec2 describe-availability-zones | jq -r '.AvailabilityZones[0].ZoneName'`}

S3_BUCKET_LOCATION_CONSTRAINT=${S3_BUCKET_LOCATION_CONSTRAINT:-`aws configure get region`}

# Small for test
NODE_SIZE=${NODE_SIZE:-"t2.small"}
MASTER_SIZE=${MASTER_SIZE:-"t2.medium"}
NODE_COUNT=${NODE_COUNT:-1}

# Use the domain name to grab the newly made hosted zone id
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones | jq -r --arg name "${BASE_FQDN}." '.HostedZones[]| select(.Name==$name)| .Id')

# Use the hosted zone id to grab name servers

NS_FROM_AWS=$(aws route53 get-hosted-zone --id "$HOSTED_ZONE_ID" | jq -r '.DelegationSet.NameServers | sort[]')
# Still inside the container, test if the NS propagated
NS_FROM_DIG=$(curl -s http://dig.jsondns.org/IN/$BASE_FQDN/NS | jq -r '[.answer[].rdata] | sort[]')

# Check if NS records matched
if [ "$NS_FROM_AWS" == "$NS_FROM_DIG" ]; then echo "NS looks good, start installing"; else echo -e "Nope"; fi

# Set the state store up
aws s3api create-bucket --bucket $(echo $KOPS_STATE_STORE | cut -d'/' -f3) --create-bucket-configuration LocationConstraint=$S3_BUCKET_LOCATION_CONSTRAINT
# Create the cluster
kops create cluster --kubernetes-version 1.5.1 --zones ${AVAILABILITY_ZONES} --node-count $NODE_COUNT --node-size $NODE_SIZE --master-size $MASTER_SIZE $CLUSTER_DOMAIN

echo "Please check the cluster settings and continue"