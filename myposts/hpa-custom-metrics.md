# How to add HPA custom metrics

On this post I will cover the easy way to use your custom prometheus metrics as HPA scale factors

## The [HPA]()

> The Horizontal Pod Autoscaler automatically scales the number of pods in a replication controller, deployment, replica set or stateful set based on observed CPU utilization (or, with custom metrics support, on some other application-provided metrics)

Originally released on ??????, The Horizontal Pod Autoscaler is implemented as a Kubernetes API resource and a controller. The resource determines the behavior of the controller. The controller periodically adjusts the number of replicas in a replication controller or deployment to match the observed average CPU utilization to the target specified by user.

### Installing HPA

HPA requires the metric-server, so you will have to 

`helm install stable/metrics-server --name metric-server --namespace kube-system`

now here is a little demo containing a sample app + its HPA:

gist-----------------

install it with `kubectl apply -f gist-----------------`




