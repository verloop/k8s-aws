#!/bin/bash
# Set variables
export BASE_FQDN=${BASE_FQDN:-"test.verloop.io"}

# PS: save $CALLER_REF_ID, you might need it next time if hosted zone didn't work
CALLER_REF_ID=${CALLER_REF_ID:-`python -c "import uuid; print(uuid.uuid4())"`}
echo $CALLER_REF_ID

# Create a route53 hosted zone
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones | jq -r --arg name "${BASE_FQDN}." '.HostedZones[]| select(.Name==$name)| .Id')
if [ -z "$HOSTED_ZONE_ID" ]; then aws route53 create-hosted-zone --name $BASE_FQDN --caller-reference $CALLER_REF_ID; else echo "Hosted zone exists with namespaces" && aws route53 get-hosted-zone --id "$HOSTED_ZONE_ID" | jq -r '.DelegationSet.NameServers | sort[]'; fi