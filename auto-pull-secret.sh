#!/bin/sh 

# This script fetches a new offline access token and uses it to get a new bearer token
# https://access.redhat.com/solutions/4844461
# https://api.openshift.com/

#TOKEN for cloud

export OFFLINE_ACCESS_TOKEN="token goes here"


export BEARER=$(curl \
--silent \
--data-urlencode "grant_type=refresh_token" \
--data-urlencode "client_id=cloud-services" \
--data-urlencode "refresh_token=${OFFLINE_ACCESS_TOKEN}" \
https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token | \
jq -r .access_token)

curl -X POST https://api.openshift.com/api/accounts_mgmt/v1/access_token --header "Content-Type:application/json" --header "Authorization: Bearer $BEARER" | jq

