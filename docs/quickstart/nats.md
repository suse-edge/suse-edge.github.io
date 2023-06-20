---
sidebar_position: 5
title: NATS on K3s
---

# Intro
[NATS](https://nats.io/) is a connective technology built for the ever-increasingly hyper-connected world. It is a single technology that enables applications to securely communicate across any combination of cloud vendors, on-premise, edge, web and mobile, and devices. NATS consists of a family of open-source products that are tightly integrated but can be deployed easily and independently. NATS is being used globally by thousands of companies, spanning use cases including microservices, edge computing, mobile, and IoT, and can be used to augment or replace traditional messaging.

## Architecture
NATS is an infrastructure that allows data exchange between applications in the form of messages.

### NATS Client Applications
NATS client libraries can be used to allow the applications to publish, subscribe, request, and reply between different instances.
These applications are generally referred to as `client applications`.

### NATS Service Infrastructure
The NATS services are provided by one or more NATS server processes that are configured to interconnect with each other and provide a NATS service infrastructure. The NATS service infrastructure can scale from a single NATS server process running on an end device to a public global super-cluster of many clusters spanning all major cloud providers and all regions of the world.

### Simple messaging design
NATS makes it easy for applications to communicate by sending and receiving messages. These messages are addressed and identified by subject strings and do not depend on network location.
Data is encoded and framed as a message and sent by a publisher. The message is received, decoded, and processed by one or more subscribers.

### NATS JetStream
NATS has a built-in distributed persistence system called JetStream.
JetStream was created to solve the problems identified with streaming in technology today - complexity, fragility, and a lack of scalability. JetStream also solves the problem with the coupling of the publisher and the subscriber (the subscribers need to be up and running to receive the message when it is published).
More information about NATS JetStream can be found [here](https://docs.nats.io/nats-concepts/jetstream).

## Installation

### Install NATS on top of K3s
NATS is built for multiple architectures, so it can easily be installed on the [the K3s on SLE Micro Setup](https://suse-edge.github.io/docs/quickstart/k3s-on-slemicro).

Let's create a values file that will be used for overwriting the default values of NATS.

```sh
cat > values.yaml <<EOF
cluster:
  # Enable the HA setup of the NATS
  enabled: true
  replicas: 3

nats:
  jetstream:
    # Enable JetStream
    enabled: true

    memStorage:
      enabled: true
      size: 2Gi

    fileStorage:
      enabled: true
      size: 1Gi
      storageDirectory: /data/
EOF
```

Now let's install NATS via helm:

`helm install nats nats/nats --namespace nats --values values.yaml --create-namespace`

With the `values.yaml` file above, the following components will be in the `nats` namespace:

1. HA version of NATS Statefulset containing 3 containers: NATS server + Config reloader and Metrics sidecars.
2. NATS box container which comes with a set of `NATS` utilities that can be used to verify the setup.
3. JetStream Key-Value backend also will be enabled which comes with `PVCs` bounded to the pods.

#### Test the setup
`kubectl exec -n nats -it deployment/nats-box -- /bin/sh -l`

```sh
# Create a subscription for the test subject
nats sub test &
# Send a message to the test subject
nats pub test hi
```

#### Clean up

```sh
helm -n nats uninstall nats
rm values.yaml
```

### NATS as a backend for K3s
One component K3s leverages is [KINE](https://github.com/k3s-io/kine), which is a shim enabling the replacement of etcd with alternate storage backends originally targeting relational databases.
As JetStream provides a Key Value API, this makes it possible to have NATS as a backend for the K3s cluster.

There is already merged PR which makes the built-in NATS in K3s straight-forward but the change is still [not included](https://github.com/k3s-io/k3s/issues/7410#issue-1692989394) in the K3s releases.

For this reason, the K3s binary should be built manually.

In this tutorial, [SLE Micro on OSX on Apple Silicon (UTM)](https://suse-edge.github.io/docs/quickstart/slemicro-utm-aarch64) VM will be used.

**NOTE:** Run the commands bellow on the OSX PC.

#### Build K3s

```sh
git clone --depth 1 https://github.com/k3s-io/k3s.git && cd k3s

# The following command will add `nats` in the build tags which will enable the NATS built-in feature in K3s
sed -i '' 's/TAGS="ctrd/TAGS="nats ctrd/g' scripts/build

mkdir -p build/data && make download && make generate
SKIP_VALIDATE=true make

# Replace <node-ip> with the actual IP of the node where the K3s will be started
export NODE_IP=<node-ip>
sudo scp dist/artifacts/k3s-arm64 ${NODE_IP}:/usr/local/bin/k3s
```

#### Install NATS CLI

```sh
TMPDIR=$(mktemp -d)
nats_version="nats-0.0.35-linux-arm64"
curl -o "${TMPDIR}/nats.zip" -sfL https://github.com/nats-io/natscli/releases/download/v0.0.35/${nats_version}.zip
unzip "${TMPDIR}/nats.zip" -d "${TMPDIR}"

sudo scp ${TMPDIR}/${nats_version}/nats ${NODE_IP}:/usr/local/bin/nats
rm -rf ${TMPDIR}
```

#### Run NATS as K3s backend

Let's ssh on the node and run the K3s with the `--datastore-endpoint` flag pointing to `nats`.

**NOTE:** The command below will start K3s as a foreground process, so the logs can be easily followed to see if there are any issues.
If you want to not block the current terminal a `&` flag could be added before the command to start it as a background process.

`k3s server  --datastore-endpoint=nats://`

**NOTE:** For making the K3s server with the NATS backend permanent on your `slemicro` VM, the script below can be run, which will create a `systemd` service with the needed configurations.

```sh
export INSTALL_K3S_SKIP_START=false
export INSTALL_K3S_SKIP_DOWNLOAD=true

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --datastore-endpoint=nats://"  sh -
```

#### Troubleshooting

The following commands can be run on the node to verify that everything with the stream is working properly:

```sh
nats str report -a
nats str view -a
```
