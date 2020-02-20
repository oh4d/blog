# The fastest way to deploy AWS EFS volume to EKS cluster

## Background
EFS is an AWS abstarction for NFS - network file system, allowing you to share a server volume between multiple machines on the network.

## 4 steps:
### 1. Creating the EFS

copy the filesystemID:
<<>>
### 2. Installing efs-provisioner helm chart


`helm install stable/efs-provisioner --set efsProvisioner.efsFileSystemId=${FS_ID} --set efsProvisioner.awsRegion=${REGION}`

### 3. creating the PVC


### 4. mounting over pods