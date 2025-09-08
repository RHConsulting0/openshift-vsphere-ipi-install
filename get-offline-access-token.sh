#!/bin/bash

# https://access.redhat.com/solutions/4844461

# https://api.openshift.com/
# Get a new bearer token using an offline access token
# The offline access token can be generated from https://cloud.redhat.com/openshift/token
# The offline access token does not expire, but can be revoked from https://cloud.redhat.com/openshift/token
# The bearer token expires after 1 hour
# The bearer token can be used to get a new offline access token
# The offline access token can be used to get a new bearer token
# The bearer token can be used to access the OpenShift APIs
USER="username"
PASS="password"


curl -d "username=$USER&password=$PASS&grant_type=password&client_id=cloud-services" https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token -s 


## {"error":"invalid_grant","error_description":"Client not allowed for direct access grants"}