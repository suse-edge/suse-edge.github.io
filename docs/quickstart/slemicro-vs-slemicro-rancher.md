---
title: SLE Micro vs SLE Micro for Rancher
---


## SLE Micro  

It is a minimal operating system designed for use in containerized environments. It includes only the essential components required to run container workloads and has a small footprint, making it ideal for running in resource-constrained environments such as edge devices or IoT devices. It is based on the concept of a transactional server, where the entire operating system is treated as a single, immutable unit. This means that any changes to the system are made through atomic transactions, which can be rolled back if necessary. This approach provides increased security, reliability, and consistency, making it ideal for use in production environments. SLE Micro can be used as a single-node container host, Kubernetes cluster node, single-node KVM virtualization host or in public cloud. One example for the usage would be Telecom where SLE Micro is helping them unlock the cost-savings potential of open-source design for both software and hardware. With the open standards design, they can explore commodity hardware from several vendors and build an open source-based software platform using open standards such as Kubernetes with open source tools of their choice. Ultimately, they expect significant savings on software and hardware, while keeping full control of their technology stack strategy and roadmap. For more info and steps on how to use SLE micro you can check the [following](https://documentation.suse.com/sle-micro/5.3/html/SLE-Micro-all/book-deployment-slemicro.html)



## SLE Micro for Rancher 

On the other hand, we base SLE Micro for Rancher around Elemental, and it is designed to work with containerized workloads. It includes additional features and tools that make it easier to deploy and manage container workloads in a Rancher environment. This includes preconfigured networking and storage options, as well as integrated monitoring and logging capabilities. Another difference is that it is not strictly a transactional server, but it does include transactional features. For example, it uses the Btrfs file system, which is also used in the SLE Micro and supports snapshots and rollbacks, allowing you to easily revert to a previous system state if needed. Additionally, updates to the system are delivered through a transactional update mechanism, which ensures that the system remains in a consistent state throughout the update process. See more [here](https://documentation.suse.com/trd/kubernetes/html/kubernetes_ri_rancher-k3s-sles/id-introduction.html)
