---
sidebar_position: 2
title: Rancher portfolio disambiguation
---

# Rancher portfolio disambiguation

[Rancher](https://www.rancher.com/) ecosystem host a few projects under its umbrella. For newcomers it may be not easy to have a clear picture on the different products and projects. This is a humble attempt to clarify it.

## TL;DR
RKE1, RKE2 and K3s are flavours of Kubernetes, Rancher Manager can be used to manage and provision different deployments of Kubernetes itself with a primary focus on RKE1/RKE2, Fleet can watch Git Repositories, detect changes and tell Kubernetes what it needs to be running, Elemental considers a specific approach to provisioning Kubernetes in Edge scenarios where the provisioning can be preloaded at the OS level for Rancher Manager to control later

### Rancher
[Rancher](https://www.rancher.com/products/rancher) (or Rancher Manager) is a multi cluster management solution for provisioning, managing and accessing multiple downstream kubernetes clusters.
To provision new clusters Rancher can interact with different infrastructure and virtualization tools (vSphere/AWS etc) as an api client, request VMs and networks and setup a kubernetes cluster inside of those, it also works with bare metal machines by generating an join command you an run each time.

### Fleet
[Fleet](https://fleet.rancher.io/) is usually a component of [Rancher](https://www.rancher.com/products/rancher) (although it can be used independently) that allows you to use a GitOps workflow for multi-cluster (i.e it allows you to define your git repositories and the clusters they should apply to at the management cluster level).

### Elemental
[Elemental](https://elemental.docs.rancher.com/) is a way to automatically deploy/register new clusters and manage the OS of their node, you can define clusters and their nodes on the management cluster then generate an OS installer image, when booting your node from that image it will install the node, register it to the manager and configure it for its role in the local cluster. This is the SUSE/Rancher way of doing zero touch provisioning.
Elemental takes a different view of cluster provisioning focused on Edge deployments, typically Rancher services datacentre deployments of Kubernetes with enterprise servers etc; in an Edge scenario e.g. factory or cruise ship theres no guarantee of access for Rancher to contact and provision a cluster directly (i.e. limited bandwidth, firewalls etc) - Elemental instead is used to preload an operating system with all the information needed to set the cluster up, you can install that into the servers that you want to cluster and then it will reach back to Rancher to be under management at that point

### Kubernetes
[Kubernetes](https://kubernetes.io/) as a standard and core technology is really a cross industry effort like Linux and has become core to DevOps as a cultural movement - as it enables defining and deploying your infrastructure as code and with lots of automation for extensive business continuity and high availability

Kubernetes is a receptacle though - it runs what you tell it to run, usually people use automation to tell it what to do and this requires some kind of application to detect application configuration and apply it to Kubernetes - usually this is fulfilled through developer pipelines (CI/CD) where things are deployed as they are developed

### Kubernetes distributions
Kubernetes Distributions, like Linux OSes, come in different flavours, RKE and RKE2 are two different flavours of Kubernetes in this manner; but like Ubuntu vs SUSE do for an OS they are ultimately just packaging an implementation of Kubernetes. Other examples include EKS,AKS and GKE which are flavours produced by AWS, Azure and GCP respectively. When we say a kubernetes cluster we mean a specific instance of a distribution installed on servers that are managed as a group (each server being a node in the cluster)

### K3Ss
[K3s](https://docs.k3s.io/) is a fully compliant and lightweight Kubernetes distribution focused on Edge, IoT, ARM or just for situations where a PhD in K8s clusterology is infeasible

### RKE (or RKE1)
[Rancher Kubernetes Engine](https://www.rancher.com/products/rke) is a Kubernetes distribution that uses an older architecture and relies on Docker Engine to run containers

### RKE2
[RKE2](https://docs.rke2.io/) also known as RKE Government, is Rancher's next-generation Kubernetes distribution that uses a newer architecture based on ContainerD.
RKE2 combines the best-of-both-worlds from the 1.x version of RKE (hereafter referred to as RKE1) and K3s.
From K3s, it inherits the usability, ease-of-operations, and deployment model.
From RKE1, it inherits close alignment with upstream Kubernetes. In places K3s has diverged from upstream Kubernetes in order to optimize for edge deployments, but RKE1 and RKE2 can stay closely aligned with upstream.

### Rancher vs K3s vs RKE
You don’t need Rancher to set up K3s or RKE1 or RKE2 on their own it just makes the whole process easier.
Rancher runs as a Management Interface that can interact with running clusters and also provision new clusters - as well as manage authentication to the downstream clusters, and it can also do other things like interact with applications that kubernetes is orchestrating and provides monitoring tools
