---
sidebar_position: 1
title: SLE Micro on X86_64 on libvirt (KCLI)
---

# Intro
## Libvirtd 

The libvirtd program is the server side daemon component of the libvirt virtualization management system.
This daemon runs on host servers and performs required management tasks for virtualized guests. This includes activities such as starting, stopping and migrating guests between host servers, configuring and manipulating networking, and managing storage for use by guests.
The libvirt client libraries and utilities connect to this daemon to issue tasks and collect information about the configuration and resources of the host system and guests.
(see https://libvirt.org/manpages/libvirtd.html)

## KCLI
This tool is meant to ease interaction with the following virtualization providers:
Libvirt/Vsphere/Kubevirt/Aws/Gcp/Ibmcloud/oVirt/Openstack/Packet

You can:
- Manage vms (create/delete/list/info/ssh/start/stop/console/serialconsole/webconsole/create or delete disk/create or delete nic/clone/snapshot)
- Deploy them using profiles
- Define more complex workflows using plans and products.

Kubernetes clusters can also be deployed with the following type:

Kubeadm/Openshift/OKD/Hypershift/Microshift/K3s/Kind

To see more details about KCLI, please visit https://kcli.readthedocs.io/en/latest/index.html

## KCLI Installation

A generic script is provided for installation:
```bash 
curl https://raw.githubusercontent.com/karmab/kcli/main/install.sh | sudo bash
```
Maybe you need to create network pool and the storage pool the first time:
```bash
kcli create pool -p /var/lib/libvirt/images -n default
``` 

For more details, please visit https://kcli.readthedocs.io/en/latest/installation.html


# Image-based process step by step

We have to create the image based and prepare the image with ignition and combustion files.
Basically we will use the following documents as reference to create the image changing the base SLEMicro image to be downloaded (**in this case will be SLE Micro x86_64**):

- Prerequisites: https://suse-edge.github.io/quickstart/slemicro-utm-aarch64#prerequisites  (Remember to download the x86_64 image)
- Image preparation: https://suse-edge.github.io/quickstart/slemicro-utm-aarch64#image-preparation
- Ignition & Combustion files: https://suse-edge.github.io/quickstart/slemicro-utm-aarch64#ignition--combustion-files

After following the previous steps, at this point you should have a folder with the following files:
- slemicro.raw (SLE-Micro.x86_64-5.4.0-Default-GM.raw)
- ignition-and-combustion.iso

The base image SLE Micro with the customization based on ignition and combustion.

## Convert the raw image to qcow2
```bash
qemu-img convert -O qcow2 SLE-Micro.x86_64-5.4.0-Default-GM.raw slemicro
```

## Move the image to libvirtd images folder
```bash
mv slemicro /var/lib/libvirt/images/
```

## Create the VM
```bash
kcli create vm -i slemicro -P cloudinit=false -P memory=4096 -P numcpu=4 -P disks=['{"size": 20}']  -P iso=ignition-and-combustion.iso
```

After a couple of seconds, the VM will boot up and will configure itself
using the ignition and combustion scripts, including registering itself
to SCC

```bash
kcli list vm 
+-------------------------+--------+-----------------+----------+-------+----------+
|           Name          | Status |        Ip       |  Source  |  Plan | Profile  |
+-------------------------+--------+-----------------+----------+-------+----------+
| distracted-duncanmcleod |   up   | 192.168.122.233 | slemicro | kvirt | slemicro |
+-------------------------+--------+-----------------+----------+-------+----------+
```

## Access to the vm

```bash
kcli ssh distracted-duncanmcleod
```
or using ssh directly and the user set in the ignition file (in this case root)
```bash
ssh root@192.168.122.233
```

## Delete the VM
```bash
kcli delete vm distracted-duncanmcleod
```
