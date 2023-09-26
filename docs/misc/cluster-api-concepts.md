---
sidebar_position: 5
title: Cluster API core concepts
---

# Cluster API core concepts

## Intro

Via the [official docs](https://cluster-api.sigs.k8s.io/):

> Cluster API is a Kubernetes sub-project focused on providing declarative APIs and tooling
> to simplify provisioning, upgrading, and operating multiple Kubernetes clusters.
>
> Started by the Kubernetes Special Interest Group (SIG) Cluster Lifecycle,
> the Cluster API project uses Kubernetes-style APIs and patterns
> to automate cluster lifecycle management for platform operators.
> The supporting infrastructure, like virtual machines, networks, load balancers, and VPCs,
> as well as the Kubernetes cluster configuration are all defined in the same way
> that application developers operate deploying and managing their workloads.
> This enables consistent and repeatable cluster deployments across a wide variety of infrastructure environments.

## Cluster types

### Management Cluster

A _Management_ cluster manages the state and lifecycle of _Workload_ clusters using components called providers.
Each Management cluster stores and reconciles the Cluster API resources (e.g. Machine, MachineDeployment, etc.)
of Workload clusters by running one or more providers.

### Workload Cluster

_Workload_ clusters, as the name suggests, are used to run and orchestrate the application workloads of the user.
Workload clusters, in the context of Cluster API, are always managed by a Management cluster.

## Providers

### Infrastructure Provider

Infrastructure providers are responsible for provisioning the necessary infrastructure and compute resources.
Each node, regardless of its type (e.g. a VM or baremetal), requires specific configuration options
which these providers use during the provisioning process e.g. OS image and checksum, network settings, etc.

A popular and widely adopted baremetal infrastructure provider is the
[CAPM3](https://github.com/metal3-io/cluster-api-provider-metal3) project (Cluster API Provider Metal³).
It enables users to deploy a Cluster API based cluster using Metal3.

### Bootstrap Provider

Bootstrap providers are responsible for turning a fully provisioned server into a Kubernetes node.
This includes, but is not limited to, configuring, initializing and joining control plane and worker nodes,
generating kubeconfig and cluster certificates, etc.

The [CAPRKE2](https://github.com/rancher-sandbox/cluster-api-provider-rke2/) project
(Cluster API Provider RKE2) aims to provide both Control Plane and Bootstrap providers for RKE2 based clusters.
It is currently in early development by the Rancher team.