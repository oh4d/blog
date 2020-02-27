## Installing helm3 

1. you are supposed to download a binary from the [official release page](https://github.com/helm/helm/releases)
2. then you put it in your PATH. I dont want to override my helm2 client binary, so I will name it helm3:
   
   `mv '/Users/efrat/Documents/local-k8s-cluster/ansible/playbooks/templates/darwin-amd64/helm' /usr/local/bin/helm3`
   `chmod +x /usr/local/bin/helm3`

3. If you run CatalinaOS like I do, your mac wont allow you to run this, you will have to go to System Perferneces -> Security & Privacy -> General and allow it to run.

4. Thats it! run `helm3`

5. add the official charts repo:

`helm3 repo add stable https://kubernetes-charts.storage.googleapis.com/`

6. `helm3 repo ls`