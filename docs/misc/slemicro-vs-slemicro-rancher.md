---
sidebar_position: 1
title: SLE Micro vs SLE Micro for Rancher
---

## SLE Micro  
SLE Micro is a minimal, general-purpose operating system that is also
well suited for use in 
containerized environments. It is based on the concept of a transactional server, 
where the entire operating system is treated as a single, immutable unit. This 
means that any changes to the system are made through atomic transactions, which 
can be rolled back if necessary. This approach provides increased security, 
reliability, and consistency, making it ideal for use in production environments. 

It includes only the essential components required to run container workloads and 
has a small footprint, making it ideal for running in resource-constrained 
environments such as edge devices or IoT devices.

SLE Micro can be used as a single-node container host, Kubernetes cluster node, 
single-node KVM virtualization host or in public cloud.

One of the main benefits of using SLE Micro is its open standards design, which 
allows users to explore commodity hardware from several vendors and build an 
open source-based software platform. This enables significant cost savings on 
both software and hardware while keeping full control of the technology stack
strategy and roadmap.

One example for the usage would be Telecom where SLE Micro is helping them 
unlock the cost-savings potential of open-source design for both software and 
hardware. With the open standards design, they can explore commodity hardware 
from several vendors and build an open source-based software platform using 
open standards such as Kubernetes with open source tools of their choice. 
Ultimately, they expect significant savings on software and hardware, while 
keeping full control of their technology stack strategy and roadmap. 

For more info and steps on how to use SLE micro you can check the 
[following](https://documentation.suse.com/sle-micro/5.3/html/SLE-Micro-all/book-deployment-slemicro.html)



## SLE Micro for Rancher 

SLE Micro for Rancher is a single-purpose variant of SLE Micro. It is specifically designed 
to run Kubernetes and its containerized workloads in a Rancher environment. 

It is built around the [Elemental platform](https://elemental.docs.rancher.com), which provides
the features and tools for declarative deployment and
management of the operating system.

There are a couple of fundamental differences between SLE Micro for
Rancher and SLE Micro.

SLE Micro **for Rancher** is
* declarative
* image based
* cloud native.

Making it an ideal match to Kubernetes and Rancher.

SLE Micro is more traditional being
* imperative
* package based
* transactional

Being package-based, SLE Micro still needs package repositories for
deployment and updates and additionally a registry for container
workloads.


SLE Micro for Rancher fits ideally into an existing cloud-native
infrastructure as deployments and updates are served via a container
registry.

It is completely manageable from within Rancher, everything in the SLE
Micro for Rancher stack is represented as a Kubernetes resource

This all makes SLE Micro for Rancher ideally suited for running Kubernetes
clusters on the edge.