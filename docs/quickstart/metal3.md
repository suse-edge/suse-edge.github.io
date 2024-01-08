---
sidebar_position: 4
title: BMC automated deployments with Metal3
---

## What is Metal<sup>3</sup>?

Metal<sup>3</sup> is a [CNCF project](https://metal3.io/) which provides baremetal infrastructure
management capabilites for Kubernetes.

Metal<sup>3</sup> provides Kubernetes-native resources to manage the lifecycle of baremetal servers
which support management via out-of-band protocols such as [Redfish](https://www.dmtf.org/standards/redfish)

It also has mature support for [Cluster API (CAPI)](https://cluster-api.sigs.k8s.io/) which enables management
of infrastructure resources accross multiple infrastructure providers via a broadly adopted vendor-neutral APIs.

## Why use this method

This method is useful for scenarios where the target hardware supports out-of-band management, and a fully-automated
infrastructure management flow is desired.

This method provides declarative APIs that enable inventory and state management of baremetal servers, including
automated inspection, cleaning and provisioning/deprovisioning.

## High level architecture

TODO diagram

## Prerequisites

- Management cluster
  -  Must have network connectivity to the target server management/BMC API
  -  Must have network connectivity to the target server controlplane network
  - [Kubectl](https://kubernetes.io/docs/reference/kubectl/kubectl/), [Podman](https://podman.io), and [Helm](https://helm.sh) need to be installed
  - For mult-node management clusters an additional reserved IP address is required

- Hosts to be controlled
  - Must support out-of-band management via Redfish, iDRAC or iLO interfaces
  - Must support deployment via virtualmedia (PXE is not currently supported)
  - Must have network connectivity to the Management cluster for access to the Metal<sup>3</sup> provisioning APIs

TODO we need a more detailed support matrix of vendors and BMC firmware versions.

### Setup bootstrap cluster

The basic steps to install and use Metal<sup>3</sup> are:

- Install an RKE2 management cluster
- Install Rancher
- Install a storage provider
- Install the Metal<sup>3</sup> dependencies
- Install CAPI dependencies
- Register BareMetalHost CRs to define the baremetal inventory
- Create a downstream cluster by defining CAPI resources

### Install Metal3 dependencies

If not already installed as part of the Rancher installation, cert-manager must be installed and running

A persistent storage provider must be installed, Longhorn is recommended but local-path can also be used for
dev/PoC environments, the instructions below assume a StorageClass has been
[marked as default](https://kubernetes.io/docs/tasks/administer-cluster/change-default-storage-class/)
otherwise additional configuration for the Metal3 chart is required.

An additional IP is required, which is managed by [MetalLB](https://metallb.universe.tf/) to provide a
consistent endpoint for the Metal<sup>3</sup> management services.
This IP must be part of the controlplane subnet, and reserved for static configuration (not part of any DHCP pool).

First we install MetalLB:

```
helm repo add suse-edge https://suse-edge.github.io/charts
helm install \
  metallb suse-edge/metallb \
  --namespace metallb-system \
  --create-namespace
```

Then we define an `IPAddressPool` and `L2Advertisment` using the reserved IP, defined as `STATIC_IRONIC_IP` below:

```
export STATIC_IRONIC_IP=<STATIC_IRONIC_IP>

cat <<-EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: ironic-ip-pool
  namespace: metallb-system
spec:
  addresses:
  - ${STATIC_IRONIC_IP}/32
  serviceAllocation:
    priority: 100
    serviceSelectors:
    - matchExpressions:
      - {key: app.kubernetes.io/name, operator: In, values: [metal3-ironic]}
EOF

cat <<-EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: ironic-ip-pool-l2-adv
  namespace: metallb-system
spec:
  ipAddressPools:
  - ironic-ip-pool
EOF
```

Now Metal3 can be installed:

```
helm install \
  metal3 suse-edge/metal3 \
  --namespace metal3-system \
  --create-namespace \
  --set global.ironicIP="${STATIC_IRONIC_IP}"
```

Note that it can take around 2 minutes for the initContainer to run on this deployment so ensure the
pods are all running before proceeding:

```
kubectl get pods -n metal3-system
NAME                                                    READY   STATUS    RESTARTS   AGE
baremetal-operator-controller-manager-85756794b-fz98d   2/2     Running   0          15m
metal3-metal3-ironic-677bc5c8cc-55shd                   4/4     Running   0          15m
metal3-metal3-mariadb-7c7d6fdbd8-64c7l                  1/1     Running   0          15m
```

### Install Cluster API dependencies

TODO - update this to use the Rancher turtles operator instead

Install [clusterctl](https://cluster-api.sigs.k8s.io/user/quick-start.html#install-clusterctl) 1.6.x, then install the core, infrastructure, bootstrap and controplane providers

```
clusterctl init --core cluster-api:v1.6.0 --infrastructure metal3:v1.6.0
clusterctl init --bootstrap rke2 --control-plane rke2
```

### Add BareMetalHost Inventory

To register baremetal servers for automated deployment it is necessary to create two resources, a Secret containing the credentials
for access to the BMC, and a Metal<sup>3</sup> BareMetalHost resource which describes the BMC connection and other details:

```
apiVersion: v1
kind: Secret
metadata:
  name: controlplane-0-credentials
type: Opaque
data:
  username: YWRtaW4=
  password: cGFzc3dvcmQ=
---
apiVersion: metal3.io/v1alpha1
kind: BareMetalHost
metadata:
  name: controlplane-0
  labels:
    cluster-role: control-plane
spec:
  online: true
  bootMACAddress: "00:f3:65:8a:a3:b0"
  bmc:
    address: redfish-virtualmedia://192.168.125.1:8000/redfish/v1/Systems/68bd0fb6-d124-4d17-a904-cdf33efe83ab
    disableCertificateVerification: true
    credentialsName: controlplane-0-credentials
```

Note the following:
- The Secret username/password must be base64 encoded.  Note this should not include any trailing newlines (e.g use `echo -n` not just `echo`!)
- The `cluster-role` label may be set now or later on cluster creation, in the example below we expect `control-plane` or `worker`
- `bootMACAddress` must be a valid MAC which matches the controlplane NIC of the host
- The `bmc` address is the connection to the BMC management API, the following are supported:
  - `redfish-virtualmedia://<IP ADDRESS>/redfish/v1/Systems/<SYSTEM ID>` : redfish virtualmedia, e.g SuperMicro
  - `idrac-virtualmedia://<IP ADDRESS>/redfish/v1/Systems/System.Embedded.1` : Dell iDRAC
- See the [Upstream API docs](https://github.com/metal3-io/baremetal-operator/blob/main/docs/api.md) for more details on the BareMetalHost API

### Create downstream clusters

We now create Cluster API resources which define the downstream cluster, and Machine resources which will cause the BareMetalHost resources to
be provisioned, then bootstrapped to form an RKE2 cluster.

### Controlplane deployment

TODO

### Worker/Compute deployment

TODO


## Next steps

## Planned changes

## Additional Resources

### Single-node configuration (experimental/unsupported)

For test/PoC environments where the management cluster is a single node, it's possible to avoid the requirement for an additional IP.

In this mode the endpoint for the management cluster APIs is the IP of the management cluster, thus is should be either reserved when using DHCP
or statically configured.

TODO example of how to do this with NodePort, if we want to include it in the docs?
