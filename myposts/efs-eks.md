# The fastest way to deploy AWS EFS volume to EKS cluster

## Background
EFS is an AWS abstarction for NFS - network file system, allowing you to share a server volume between multiple machines on the network.

## 4 steps:
### 1. Creating the EFS

copy the filesystemID:
<<>>
### 2. Installing efs-provisioner helm chart


`helm install stable/efs-provisioner --set efsProvisioner.efsFileSystemId=${FS_ID} --set efsProvisioner.awsRegion=${REGION} --set efsProvisioner.storageClass.name="example-efs" --name example-efs-provisioner`

this chart is stable and trustfull, but lacks a few core components, which we will apply now:

### 3. creating the PVC

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: example-efs-pvc
  namespace: legacy
  annotations:
    volume.beta.kubernetes.io/storage-class: example-efs
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 50Gi
  storageClassName: "example-efs"
```
### 5. Creating the rbac
```yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: example-efs-provisioner
rules:
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: example-efs-provisioner
subjects:
  - kind: ServiceAccount
    name: example-efs-provisioner
    # replace with namespace where provisioner is deployed
    namespace: legacy
roleRef:
  kind: Role
  name: example-efs-provisioner
  apiGroup: rbac.authorization.k8s.io
```
once all this stuff is deployed, its time to mount and use the provisioned EFS:
### 4. mounting over deployments:

```yaml
# Source: legacy/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: release-name-legacy
  labels:
    app.kubernetes.io/name: legacy
    helm.sh/chart: legacy-0.1.0
    app.kubernetes.io/instance: release-name
    app.kubernetes.io/version: "1.0"
    app.kubernetes.io/managed-by: Tiller
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: legacy
      app.kubernetes.io/instance: release-name
  template:
    metadata:
      labels:
        app.kubernetes.io/name: legacy
        app.kubernetes.io/instance: release-name
        role: admin
    spec:
      volumes:
      - name: mail-secret
        secret:
          secretName: release-name-legacy-mail-secret
      
      - name: images-efs
        persistentVolumeClaim:
          claimName: legacy-pics-efs-pvc
      
      containers:
        - name: legacy
          image: "572995054717.dkr.ecr.eu-west-1.amazonaws.com/y2_legacy_adminpricelist:prod-2.0.0-1888f76f4abae08b4d5070fde74e9e2fa6d876e1"
          imagePullPolicy: IfNotPresent
          volumeMounts:
          - name: mail-secret
            mountPath: /etc/msmtprc
            subPath: msmtprc
            readOnly: true
          
          - name: images-efs
            mountPath: /home/luach/yad2/Pic1/
            subPath: Pic1
            readOnly: false
          - name: images-efs
            mountPath: /home/luach/yad2/Pic2/
            subPath: Pic2
            readOnly: false
          - name: images-efs 
            mountPath: /home/luach/yad2/Pic3/
            subPath: Pic3
            readOnly: false
          
          env:
          
          - name: YAD2_HOSTNAME
            value: "http://dr.adminpricelist.yad2.co.il"
          
          ports:
            - name: http
              containerPort: 8080
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /
              port: http
              httpHeaders:
              - name: Authorization
                value: Basic ZWZyYXQ6MTAxMjk4
            timeoutSeconds: 10
          readinessProbe:
            httpGet:
              path: /
              port: http
              httpHeaders:
              - name: Authorization
                value: Basic ZWZyYXQ6MTAxMjk4
            timeoutSeconds: 10
          resources:
            limits:
              cpu: 200m
              memory: 1300Mi
            requests:
              cpu: 60m
              memory: 600Mi
```





