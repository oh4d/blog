install traefik:
`helm install stable/traefik  --namespace traefik --name traefik --set serviceType=NodePort`

`helm repo add maesh https://containous.github.io/maesh/charts`
`helm repo update`

`helm install --name=maesh --namespace=maesh maesh/maesh --set smi.enable=false --set smi.deploy=false`