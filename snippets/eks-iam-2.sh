export CLUSTER="$(kubectl config view -ojson | jq -r --arg CTX $(kubectl config current-context) '.contexts | .[] | select(.name == $CTX) | .context.cluster | split("/") | .[length-1]')"
export REGION=$(aws configure get region)
export OIDC=$(aws eks describe-cluster --name ${CLUSTER} --query cluster.identity.oidc | jq -r '.issuer | split("/") | .[length-1]')
export ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
echo "cluster $CLUSTER in region $REGION and account number ${ACCOUNT} has OIDC token: ${OIDC}"
