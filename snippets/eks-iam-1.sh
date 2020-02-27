#!/bin/bash

command -v kubectl || echo "kubectl must be installed.... exiting" && exit 2
command -v jq || echo "jq must be installed.... exiting" && exit 2
command -v aws || echo "aws cli must be installed.... exiting" && exit 2

export CLUSTER="$(kubectl config view -ojson | jq -r --arg CTX $(kubectl config current-context) '.contexts | .[] | select(.name == $CTX) | .context.cluster | split("/") | .[length-1]')"
export REGION=$(aws configure get region)
export OIDC=$(aws eks describe-cluster --name ${CLUSTER} --query cluster.identity.oidc | jq -r '.issuer | split("/") | .[length-1]')
export ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
echo "cluster $CLUSTER in region $REGION and account number ${ACCOUNT} has OIDC token: ${OIDC}"

curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluentd-quickstart.yaml | sed "s/{{cluster_name}}/${CLUSTER}/;s/{{region_name}}/${REGION}/;s/name: REGION/name: AWS_REGION/;" | kubectl apply -f -

echo "{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${ACCOUNT}:oidc-provider/oidc.eks.${REGION}.amazonaws.com/id/${OIDC}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.${REGION}.amazonaws.com/id/${OIDC}:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}" >> trust_relationshsips.json

aws iam create-role --role-name k8s-cloudwatch-agent --assume-role-policy-document file://trust_relationshsips.json

aws iam attach-role-policy --role-name k8s-cloudwatch-agent --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy


kubectl annotate -n amazon-cloudwatch sa cloudwatch-agent fluentd "eks.amazonaws.com/role-arn=arn:aws:iam::${ACCOUNT}:role/k8s-cloudwatch-agent"

kubectl get po -n amazon-cloudwatch -oname | xargs kubectl delete 