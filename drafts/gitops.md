

## Install helm:

`kubectl -n kube-system create serviceaccount tiller`

`kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller`

`helm init --service-account tiller --tiller-image=jessestuart/tiller:v2.9.1 --override spec.selector.matchLabels.'name'='tiller',spec.selector.matchLabels.'app'='helm' --history-max 10 --output yaml | sed 's@apiVersion: extensions/v1beta1@apiVersion: apps/v1@' | kubectl apply -f -`

## Install flux

Fork [flux repo](https://github.com/fluxcd/flux-get-started) and rename it. 
For example,my fork is https://github.com/Efrat19/local-cluster.

Adding the charts repo:
`helm repo add fluxcd https://charts.fluxcd.io`

Adding the CRD:
`kubectl apply -f https://raw.githubusercontent.com/fluxcd/helm-operator/master/deploy/flux-helm-release-crd.yaml`

Creating the namespace:
`kubectl create namespace flux`

Install flux chart, be sure to give it your own git-url:
`helm upgrade -i flux fluxcd/flux --set git.url=git@github.com:Efrat19/local-cluster.git --namespace flux`

And the helm-operator:
`helm upgrade -i helm-operator fluxcd/helm-operator --set git.ssh.secretName=flux-git-deploy --namespace flux`

```console
~ $ kubectl get po -n flux
NAME                              READY   STATUS    RESTARTS   AGE
flux-6b578c8cd-p696h              1/1     Running   0          4m32s
flux-memcached-8647794c5f-gdw2p   1/1     Running   0          4m32s
helm-operator-66d5477cb7-xwgzh    1/1     Running   0          4m1s
```