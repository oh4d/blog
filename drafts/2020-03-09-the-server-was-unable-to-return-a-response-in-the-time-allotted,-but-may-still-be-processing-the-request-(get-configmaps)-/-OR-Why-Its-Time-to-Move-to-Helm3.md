---
layout: post
title: the server was unable to return a response in the time allotted, but may still be processing the request (get configmaps) / OR Why Its Time to Move to Helm3
lang: en
categories:
    - Kubernetes
    - helm
# tags:
#     - hoge
#     - foo
---

## The issue with helm2 

#### (spoiler: Tiller is causing troubles as usual)

As a heavy user of helm2 charts in production, I came across an issue which you are likely to run into when using helm2 charts in a large scale:
Under the hood, Tiller (helm server) is creating a ConfigMap for every release of a helm chart, and stores them in the tiller namespace.
So you can [rollback](https://helm.sh/docs/helm/helm_rollback/) a helm chart in case you are not happy with the new version. *(:bulb: Yes I am aware of the existence of `history-max` helm flag. don't know why but it doesn't seem to work, for me and for [many other people](https://github.com/helm/helm/issues/2332))*
Considering the fact that the charts are updated a few times a day, and every new version is a separated release, after a few months you will end up with:

```console
~ $ kubectl get configmaps --namespace tiller | wc -l
16589 
```
<span style='font-size:30px;'>&#128556;</span>

To manage the ConfigMaps, Tiller is sending API requests to kubernetes api-server. Unfortunately such amount of ConfigMaps is too much for the api-server to handle, and Tiller requests will time-out. In return, Tiller will start to complain on helm operations like `helm upgrade` and `helm delete`. you will bump into the infamous kubernetes error message - (first thought its a helm error but apparently this is kuberntes official [`http.StatusGatewayTimeout` error message](https://github.com/kubernetes/kubernetes/blob/24fb2c1afd51069a526e4c36ea5d3af993fd6b26/staging/src/k8s.io/apimachinery/pkg/api/errors/errors.go#L440))

`the server was unable to return a response in the time allotted, but may still be processing the request (get configmaps)`

The heavy load on the api-server might slow other operations. In severe cases, you might even loose it for a few minutes. 

## First-Aid Solution
####  (for production emergency :fire: / super lazy devops <span style='font-size:30px;'>&#129445;</span> )

Since its a [well-known issue](https://github.com/helm/helm/issues/2332), somebody wrote a [script](https://github.com/helm/helm/issues/2332#issuecomment-336565784) to manually delete old config maps.
If you choose not to migrate to helm3, you can still run this script every now and than (like I did it before figuring out how to migrate my charts) you can also keep around a grafana dashboard to monitor the configMaps scale, and it will alert you once its going crazy:

<!-- dashboard image -->

## How Helm3 solves this bug once and for all
#### (the proper solution)

The main difference between helm2 and helm3 is that **helm3 is tillerless** - helm operations goes directly to kubernetes api-server, Which is much more efficient. As a result, thank god, :star-struck: helm3 doesn't throw a huge number of configMaps to tiller namespace (because there is not tiller)

## helm 2to3 plugin

the helm team created a [plugin](https://github.com/helm/helm-2to3) which is supposed to help you migrate your released from helm2 to helm3. 
```console
$ helm plugin install https://github.com/helm/helm-2to3.git
Downloading and installing helm-2to3 v0.4.1 ...
https://github.com/helm/helm-2to3/releases/download/v0.4.1/helm-2to3_0.4.1_darwin_amd64.tar.gz
Installed plugin: 2to3
```
My cluster is configured differently so I didn't try it myself, but it seems simple, just follow the [instructions](https://github.com/helm/helm-2to3#usage) and you should be good :smiling_imp: (I don't really care if not)

## Installing helm3 client

1. Download a compatible binary from the [official release page](https://github.com/helm/helm/releases)
   
2. Untar and copy the binary to your PATH. I don't want to override my helm2 client binary, so I will name it helm3:
```console
tar -xvzf ~/Downloads/helm-v3.1.1-darwin-amd64.tar.gz darwin-amd64/helm 
mv ./darwin-amd64/helm /usr/local/bin/helm3
chmod +x /usr/local/bin/helm3
```
3. Thats it! run `helm3`
> :bulb: If you run MacOS Catalina like I do, the OS wont allow you to run this, unless you go to `System Preferences -> Security & Privacy -> General` and allow it to run.

4. **Optional:** add the official charts repo:
```console
~ $ helm3 repo add stable https://kubernetes-charts.storage.googleapis.com/
"stable" has been added to your repositories
```
```console
~ $ helm3 repo ls
NAME    URL                                               
stable  https://kubernetes-charts.storage.googleapis.com/
```

## Summary
From client point of view, there isn't much of a change between helm2 and 3. most helm commands remain the same, a few flags might change. [view the changelog](https://helm.sh/docs/topics/v2_v3_migration/). You can now happily install and manage helm3 compatible helm charts. Helm2 and 3 can live together in the same cluster, so you can still keep your old charts.

## Happy Helm3ing!