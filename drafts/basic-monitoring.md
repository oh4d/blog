
`kubectl create namespace monitoring`

1. Installing metrics-server

`helm install stable/metrics-server --namespace monitoring --name metrics-server`

`helm3 install stable/prometheus-operator --namespace monitoring --generate-name `