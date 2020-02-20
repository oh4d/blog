# Running kubernetes on Raspberry-pi

In this post I will document the steps for running my self-hosted kubernetes cluster.

## 1. firmware
My cluster is made of 2 RaspberryPi 4X4, 1 Raspberry 3B+, and 1 old lenovo PC running Ubuntu16.
you will need a microSD card, a power cable and an ethernet cable for each node

## 2. Burn images to SD cards:

I downloaded [Raspbian-buster-lite zipped latest image](https://www.raspberrypi.org/downloads/raspbian/)

insert your SD card to a computer. I am using MacBookPro, where `diskutil` already installed:

```bash

~ $ diskutil list                                                                              
/dev/disk0 (internal, physical):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:      GUID_partition_scheme                        *251.0 GB   disk0
   1:                        EFI EFI                     314.6 MB   disk0s1
   2:                 Apple_APFS Container disk1         250.7 GB   disk0s2

/dev/disk1 (synthesized):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:      APFS Container Scheme -                      +250.7 GB   disk1
                                 Physical Store disk0s2
   1:                APFS Volume Macintosh HD - Data     218.1 GB   disk1s1
   2:                APFS Volume Preboot                 87.8 MB    disk1s2
   3:                APFS Volume Recovery                526.6 MB   disk1s3
   4:                APFS Volume VM                      4.5 GB     disk1s4
   5:                APFS Volume Macintosh HD            11.1 GB    disk1s5

/dev/disk2 (external, physical):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:     FDisk_partition_scheme                        *15.9 GB    disk2
   1:             Windows_FAT_32 boot                    268.4 MB   disk2s1
   2:                      Linux                         1.6 GB     disk2s2
```
the SD card is `/dev/disk2`. I now unmount it:

`diskutil unmountdisk /dev/disk2`

and now I am good to go with writing the image:

`unzip -p ~/Downloads/2020-02-05-raspbian-buster-lite.zip | pv | sudo dd of=/dev/disk2 bs=1m`

once its done, lets allow ssh:

`touch /Volumes/boot/ssh`

and finally eject:

`diskutil eject /dev/disk2`

repeat that part for each of your SD cards.

## 3. DHCP configurations:

`sudo apt install vim`

and than paste a script I copies from [here](https://kubecloud.io/setting-up-a-kubernetes-1-11-raspberry-pi-cluster-using-kubeadm-952bbda329c8):
```bash
#!/bin/sh

hostname=$1
ip=$2 # should be of format: 192.168.1.100
dns=$3 # should be of format: 192.168.1.1

# Change the hostname
sudo hostnamectl --transient set-hostname $hostname
sudo hostnamectl --static set-hostname $hostname
sudo hostnamectl --pretty set-hostname $hostname
sudo sed -i s/raspberrypi/$hostname/g /etc/hosts

# Set the static ip

sudo cat <<EOT >> /etc/dhcpcd.conf
interface eth0
static ip_address=$ip/24
static routers=$dns
static domain_name_servers=$dns
EOT
```

`chmod +x dns.sh && sudo ./dns.sh k8s-master 192.168.1.100 192.168.1.1`

The paramaters are node name, node IP and router IP.

## 3. Install Ansible

setting ssh connection for each node:

`ssh-copy-id pi@k8s-master.local` 
`ssh-copy-id pi@k8s-worker-1.local` 

and creating and inventory file:
my cluster is made of 1 ubuntu old lappy, 2 rpi4 and 1 rpi3,
so it looks like:

```ini
[k8s-master]
k8s-master.local ansible_user=pi

[rpi-workers]
k8s-worker-1.local ansible_user=pi
k8s-worker-2.local ansible_user=pi

[ubuntu-workers]
efrat-Lenovo-G550.local ansible_user=efrat

[k8s-workers:children]
ubuntu-workers
rpi-workers

[rpi:children]
rpi-workers
k8s-master
```
#### testing - pinging all servers:

```bash
~ $ ansible -i hosts all -m ping

k8s-master.local | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    }, 
    "changed": false, 
    "ping": "pong"
}
efrat-Lenovo-G550.local | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    }, 
    "changed": false, 
    "ping": "pong"
}
k8s-worker-1.local | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    }, 
    "changed": false, 
    "ping": "pong"
}
k8s-worker-2.local | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    }, 
    "changed": false, 
    "ping": "pong"
}
```
## 4. Kubernetes pre-configurations

I actually copied lots of staff from [this repo](https://github.com/mrlesmithjr/ansible-rpi-k8s-cluster)

All you have to do is to adjust the scripts to your own needs.

mine is [here](githubansible)



