
`kubectl create namespace monitoring`

applying Persistent Volume

if no rpi:
```bash
helm repo add rook-release https://charts.rook.io/release
helm install --namespace rook rook-release/rook-ceph --name rook
```

if rpi:
```bash
kubectl apply -f https://raw.githubusercontent.com/rook/rook/release-0.5/cluster/examples/kubernetes/rook-operator.yaml 

the deployment:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rook-operator
  namespace: default
spec:
  replicas: 1
  selector: 
    matchLabels: 
        app: rook-operator
  template:
    metadata:
      labels:
        app: rook-operator
    spec:
      serviceAccountName: rook-operator
      containers:
      - name: rook-operator
        image: rook/rook:v0.5.1
        args: ["operator"]
        env:
        - name: ROOK_REPO_PREFIX
          value: rook
```


kubectl apply -f https://raw.githubusercontent.com/rook/rook/release-0.5/cluster/examples/kubernetes/rook-cluster.yaml
namespace/rook configured
cluster.rook.io/rook created
kubectl apply -f https://raw.githubusercontent.com/rook/rook/release-0.5/cluster/examples/kubernetes/rook-storageclass.yaml
pool.rook.io/replicapool created
storageclass.storage.k8s.io/rook-block created
kubectl get secret rook-operator-token-mjcns -n default -oyaml | sed "/resourceVer/d;/uid/d;/self/d;/creat/d;/namespace/d" | kubectl -n monitoring apply -f -
secret/rook-operator-token-mjcns created
kubectl patch storageclass rook-block -p '{"metadata":{"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'
storageclass.storage.k8s.io/rook-block patched

git clone https://github.com/carlosedp/cluster-monitoring.git
 k apply -f cluster-monitoring/manifests/
tmp % (⎈ local:monitoring) until kubectl get customresourcedefinitions servicemonitors.monitoring.coreos.com ; do date; sleep 1; echo ""; done
NAME                                    CREATED AT
servicemonitors.monitoring.coreos.com   2020-02-23T00:52:53Z
tmp % (⎈ local:monitoring) until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done
NAMESPACE    NAME                      AGE
monitoring   alertmanager              2m33s
monitoring   coredns                   2m17s
monitoring   grafana                   2m25s
monitoring   kube-apiserver            2m17s
monitoring   kube-controller-manager   2m17s
monitoring   kube-scheduler            2m17s
monitoring   kube-state-metrics        2m24s
monitoring   kubelet                   2m17s
monitoring   node-exporter             2m23s
monitoring   prometheus                2m18s
monitoring   prometheus-operator       2m34s
 k apply -f cluster-monitoring/manifests/


helm install stable/influxdb --name influx --namespace influx

<!-- `helm install stable/metrics-server --namespace monitoring --name metrics-server` -->



<!-- `helm3 install stable/prometheus-operator --namespace monitoring --generate-name` -->