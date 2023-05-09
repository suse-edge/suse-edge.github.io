---
sidebar_position: 1
title: SLE Micro on X86_64 on libvirt (virt-install)
---

# Intro
## Libvirtd 

The libvirtd program is the server side daemon component of the libvirt virtualization management system.
This daemon runs on host servers and performs required management tasks for virtualized guests. This includes activities such as starting, stopping and migrating guests between host servers, configuring and manipulating networking, and managing storage for use by guests.
The libvirt client libraries and utilities connect to this daemon to issue tasks and collect information about the configuration and resources of the host system and guests.
(see https://libvirt.org/manpages/libvirtd.html)

## Virt-install
`virt-install` is a command line tool for creating new KVM , Xen, or Linux container guests using the "libvirt" hypervisor management library. See the EXAMPLES section at the end of this document to quickly get started.
`virt-install` tool supports both text based & graphical installations, using VNC or SDL graphics, or a text serial console. The guest can be configured to use one or more virtual disks, network interfaces, audio devices, physical USB or PCI devices, among others.
The installation media can be held locally or remotely on NFS , HTTP , FTP servers. In the latter case `virt-install` will fetch the minimal files necessary to kick off the installation process, allowing the guest to fetch the rest of the OS distribution as needed. PXE booting, and importing an existing disk image (thus skipping the install phase) are also supported.

To see more details about virt-install options, please visit https://linux.die.net/man/1/virt-install
To see more details about virt-manager and the graphical interface, please visit https://virt-manager.org/

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

## Create the VM
```bash
virt-install --name MyVM --memory 4096 --vcpus 4 --disk ./slemicro --import --cdrom ./ignition-and-combustion.iso --network default --osinfo detect=on,name=sle-unknown
```

After a couple of seconds, the VM will boot up and will configure itself
using the ignition and combustion scripts, including registering itself
to SCC

```bash
virsh list
 Id   Nombre          State
----------------------------------
 14   MyVM          running
```

## Access to the vm

You can access to the VM using virsh console:
```bash
virsh console MyVM

Connected to domain MyVM
```
or using ssh directly and the user set in the ignition file (in this case root)
```bash
virsh domifaddr MyVM
 Nombre     MAC address          Protocol     Address
-------------------------------------------------------------------------------
 vnet14     52:54:00:f0:be:e5    ipv4         192.168.122.221/24
 
ssh root@192.168.122.221
```

## Delete the VM
```bash
virsh destroy MyVM ; virsh undefine MyVM
```
