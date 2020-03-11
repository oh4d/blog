---
layout: post
title: Helm2 to 3 migration guide for fluxcd users
lang: en
categories:
    - Kubernetes
    - helm
    - fluxcd
    - GitOps
# tags:
#     - hoge
#     - foo
---
{% include smooth-scroll.html %}

In my company we use fluxcd gitops operaor to manage our kubernetes clusters. We also use flux official helm-operator, to deploy our helm charts. the helm-operator was originally designed for helm2 charts, but once helm V3 was out, fluxcd team did a great work on the helm-operator, and now it is is compatible with both helm2 and helm3 charts. In this post I will cover the steps I took to complete my charts migration.

## What is Flux and how to get started

#### (<a href="#move">skip</a> if you are already a flux ninja <img src="https://emojipedia-us.s3.dualstack.us-west-1.amazonaws.com/thumbs/120/emojipedia/240/ninja_1f977.png" srcset="https://emojipedia-us.s3.dualstack.us-west-1.amazonaws.com/thumbs/240/emojipedia/240/ninja_1f977.png 2x" alt="Ninja on Emojipedia 13.0" width="50" height="50">)

> Flux is a tool that automatically ensures that the state of your Kubernetes cluster matches the configuration you’ve supplied in Git. It uses an operator in the cluster to trigger deployments inside Kubernetes, which means that you don’t need a separate continuous delivery tool.

1. Fork [flux repo](https://github.com/fluxcd/flux-get-started) and rename it. 
For example, my fork is [https://github.com/Efrat19/local-cluster](https://github.com/Efrat19/local-cluster).

2. Add the charts repo:
   ```console 
~ $ helm repo add fluxcd https://charts.fluxcd.io
```

3. Add the CRD: 
```console 
~ $ kubectl apply -f https://raw.githubusercontent.com/fluxcd/helm-operator/master/deploy/flux-helm-release-crd.yaml
```

4. Create a namespace:
```console 
~ $ kubectl create namespace flux
```

5. Install flux chart, be sure to give it your own git-url:
```console 
~ $ helm upgrade -i flux fluxcd/flux --set git.url=git@github.com:Efrat19/local-cluster.git --namespace flux
```

6. Install the helm-operator:
```console 
~ $ helm upgrade -i helm-operator fluxcd/helm-operator --set git.ssh.secretName=flux-git-deploy --namespace flux
```

7. test:
```console
~ $ kubectl get po -n flux
NAME                              READY   STATUS    RESTARTS   AGE
flux-6b578c8cd-p696h              1/1     Running   0          4m32s
flux-memcached-8647794c5f-gdw2p   1/1     Running   0          4m32s
helm-operator-66d5477cb7-xwgzh    1/1     Running   0          4m1s
```

## Why I couldn't use helm 2to3 plugin

the helm team created a plugin which is supposed to help you migrate your released from helm2 to helm3. If you are using fluxcd to manage your cluster, this tool is helpless because your changes will conflict with the chart source, and overwritten by the flux operator on the next sync cycle. :sad face:

## <a id="move">Time to move:</a>

### step 1: switch to multiversioned helm-operator

Figure out in which namespace your flux helm-operator is running, and its version:
```console
~ $ helm ls flux-helm-op --output yaml
Next: ""
Releases:
- AppVersion: 1.0.0-rc7
  Chart: helm-operator-0.5.0
  Name: flux-helm-op
  Namespace: flux
  Revision: 1
  Status: DEPLOYED
  Updated: Tue Jan 21 12:44:31 2020             Tue Jan 21 12:44:31 2020        DEPLOYED        helm-operator-0.5.0     1.0.0-rc7       flux            
```

as you can see, my helm operator is deployed into `flux` namespace. I should take care of 2 points:
1. The image version must be higher than `1.0.0-rc5`, otherwise I should bump it up.
2. I will add "HELM_VERSION=v2,v3" environment variable. 

```console
~ $ echo "
image:
  tag: "1.0.0-rc9"
extraEnvs: 
- name: HELM_VERSION
  value: "v2,v3"
" >> flux-helm3-values.yaml
```
```console
 ~ $ helm upgrade helm-operator fluxcd/helm-operator --wait \
--namespace flux -f flux-helm3-values.yaml
```

As you can see in helm-operator [source code](https://github.com/fluxcd/helm-operator/blob/9951e409d5f8e14eee0139194b85290f42939247/cmd/helm-operator/main.go#L213-L234), once the change is done, both v2 and v3 helm versions will be respected.


### step 2: Gently make the required changes in your chart source

this will take a bit of time. when using fluxcd, your cluster content is version-controller in a dedicated git repository, and you keep your charts under the  `/charts` path. cd into `charts/your-chart` and make the following changes:

1. add a service account

### step 3: Bump the helm version in your chart source 

go to your helm release (`/releases/your-chart-release.yaml` in the repo). Set the `spec.helmVersion` to `v3`. (the default value is `v2`).

### Make the swap

commit and push the changes. once synced, the 
add 