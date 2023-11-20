---
sidebar_position: 4
title: MetalLB on K3s
---

# Intro
## MetalLB

Via the [official docs](https://metallb.universe.tf/):

> MetalLB is a load-balancer implementation for bare metal Kubernetes clusters, using standard routing protocols.

Network load balancers in bare-metal environments are much more difficult than in cloud environments. Instead of performing an API call, it involves having either network appliances or a combination of a load balancer + VIP to handle HA (or a single node load balancer SPOF). Those are not easily automated so having a K8s deployment where things go up and down all the time is challenging.

MetalLB tries to _fix_ this by leveraging the K8s model to create `LoadBalancer` type of services like if they were in the cloud... but on bare-metal.

There are two different approaches, via [L2 mode](https://metallb.universe.tf/concepts/layer2/) (using ARP _tricks_) or via [BGP](https://metallb.universe.tf/concepts/bgp/). Mainly L2 doesn't need any special network gear but BGP is in general _better_. It depends on the use cases.

## MetalLB on K3s (using L2)

In this quickstart, L2 mode will be used so it means we don't need any special network gear but just a couple of free IPs in our network range, ideally outside of the DHCP pool so they are not assigned.

In this example, our DHCP pool is `192.168.122.100-192.168.122.200` (yes, 3 IPs, see [Traefik and MetalLB](#traefik-and-metallb) for the reason of the extra IP) for a `192.168.122.0/24` network so anything outside this range is ok (besides the gateway and other hosts that can be already running!)

### Prerequisites

* A K3s cluster where MetalLB is going to be deployed. Hint, you can use [the K3s on SLE Micro guide](https://suse-edge.github.io/quickstart/k3s-on-slemicro).

> :warning: K3S comes with its own service load balancer named Klipper. You [need to disable it in order to run MetalLB](https://metallb.universe.tf/configuration/k3s/). To disable Klipper, K3s needs to be installed using the `--disable=servicelb` flag.

*  Helm
*  A couple of free IPs in our network range. In this case `192.168.122.10-192.168.122.12`

### Deployment

MetalLB leverages Helm (and other methods as well), so:

```
helm repo add metallb https://metallb.github.io/metallb
helm install --create-namespace -n metallb-system metallb metallb/metallb

while ! kubectl wait --for condition=ready -n metallb-system $(kubectl get pods -n metallb-system -l app.kubernetes.io/component=controller -o name) --timeout=10s; do sleep 2 ; done
```

### Configuration

At this point, the installation is completed. Now it is time to [configure](https://metallb.universe.tf/configuration/) using our example values:

```sh
cat <<-EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: ip-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.122.10/32
  - 192.168.122.11/32
  - 192.168.122.12/32
EOF

cat <<-EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: ip-pool-l2-adv
  namespace: metallb-system
spec:
  ipAddressPools:
  - ip-pool
EOF
```

At this point, it is ready to be used. There are a lot of things you can customize for L2 mode such as:

* [IPv6 And Dual Stack Services](https://metallb.universe.tf/usage/#ipv6-and-dual-stack-services)
* [Control automatic address allocation](https://metallb.universe.tf/configuration/_advanced_ipaddresspool_configuration/#controlling-automatic-address-allocation)
* [Reduce the scope of address allocation to specific Namespaces and services](https://metallb.universe.tf/configuration/_advanced_ipaddresspool_configuration/#reduce-scope-of-address-allocation-to-specific-namespace-and-service)
* [Limiting the set of nodes where the service can be announced from](https://metallb.universe.tf/configuration/_advanced_l2_configuration/#limiting-the-set-of-nodes-where-the-service-can-be-announced-from)
* [Specify network interfaces that LB IP can be announce from](https://metallb.universe.tf/configuration/_advanced_l2_configuration/#specify-network-interfaces-that-lb-ip-can-be-announced-from)

And a lot more for [BGP](https://metallb.universe.tf/configuration/_advanced_bgp_configuration/)

### Traefik and MetalLB

Traefik is deployed by default with K3s ([it can be disabled](https://docs.k3s.io/networking#traefik-ingress-controller) with `--disable=traefik`) and it is by default exposed as `LoadBalancer` (to be used with Klipper). However, as Klipper needs to be disabled, Traefik service for ingress is still a `LoadBalancer` type... so at the moment of deploying MetalLB the first IP will be assigned automatically to Traefik Ingress.

```
# Before deploying MetalLB
kubectl get svc -n kube-system traefik
NAME      TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
traefik   LoadBalancer   10.43.44.113   <pending>     80:31093/TCP,443:32095/TCP   28s
# After deploying MetalLB
kubectl get svc -n kube-system traefik
NAME      TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)                      AGE
traefik   LoadBalancer   10.43.44.113   192.168.122.10   80:31093/TCP,443:32095/TCP   3m10s
```

We will leverage this [later](#ingress-with-metallb).

### Usage

Let's create an example deployment:

```sh
cat <<- EOF | kubectl apply -f -
---
apiVersion: v1
kind: Namespace
metadata:
  name: hello-kubernetes
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: hello-kubernetes
  namespace: hello-kubernetes
  labels:
    app.kubernetes.io/name: hello-kubernetes
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-kubernetes
  namespace: hello-kubernetes
  labels:
    app.kubernetes.io/name: hello-kubernetes
spec:
  replicas: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: hello-kubernetes
  template:
    metadata:
      labels:
        app.kubernetes.io/name: hello-kubernetes
    spec:
      serviceAccountName: hello-kubernetes
      containers:
        - name: hello-kubernetes
          image: "paulbouwer/hello-kubernetes:1.10"
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: 8080
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /
              port: http
          readinessProbe:
            httpGet:
              path: /
              port: http
          env:
          - name: HANDLER_PATH_PREFIX
            value: ""
          - name: RENDER_PATH_PREFIX
            value: ""
          - name: KUBERNETES_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: KUBERNETES_POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: KUBERNETES_NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
          - name: CONTAINER_IMAGE
            value: "paulbouwer/hello-kubernetes:1.10"
EOF
```

And finally, the service:

```sh
cat <<- EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: hello-kubernetes
  namespace: hello-kubernetes
  labels:
    app.kubernetes.io/name: hello-kubernetes
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: http
      protocol: TCP
      name: http
  selector:
    app.kubernetes.io/name: hello-kubernetes
EOF
```

Let's see it in action:

```sh
kubectl get svc -n hello-kubernetes
NAME               TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)        AGE
hello-kubernetes   LoadBalancer   10.43.127.75   192.168.122.11   80:31461/TCP   8s

curl http://192.168.122.11
<!DOCTYPE html>
<html>
<head>
    <title>Hello Kubernetes!</title>
    <link rel="stylesheet" type="text/css" href="/css/main.css">
    <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Ubuntu:300" >
</head>
<body>

  <div class="main">
    <img src="/images/kubernetes.png"/>
    <div class="content">
      <div id="message">
  Hello world!
</div>
<div id="info">
  <table>
    <tr>
      <th>namespace:</th>
      <td>hello-kubernetes</td>
    </tr>
    <tr>
      <th>pod:</th>
      <td>hello-kubernetes-7c8575c848-2c6ps</td>
    </tr>
    <tr>
      <th>node:</th>
      <td>allinone (Linux 5.14.21-150400.24.46-default)</td>
    </tr>
  </table>
</div>
<div id="footer">
  paulbouwer/hello-kubernetes:1.10 (linux/amd64)
</div>
    </div>
  </div>

</body>
</html>
```


## Ingress with MetalLB

As Traefik is already serving as an ingress controller, we can expose any http/https traffic via an `Ingress` object such as:

```
IP=$(kubectl get svc -n kube-system traefik -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
cat <<- EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-kubernetes-ingress
  namespace: hello-kubernetes
spec:
  rules:
  - host: hellok3s.${IP}.sslip.io
    http:
      paths:
        - path: "/"
          pathType: Prefix
          backend:
            service:
              name: hello-kubernetes
              port:
                name: http
EOF
```

And then:

```sh
curl http://hellok3s.${IP}.sslip.io
<!DOCTYPE html>
<html>
<head>
    <title>Hello Kubernetes!</title>
    <link rel="stylesheet" type="text/css" href="/css/main.css">
    <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Ubuntu:300" >
</head>
<body>

  <div class="main">
    <img src="/images/kubernetes.png"/>
    <div class="content">
      <div id="message">
  Hello world!
</div>
<div id="info">
  <table>
    <tr>
      <th>namespace:</th>
      <td>hello-kubernetes</td>
    </tr>
    <tr>
      <th>pod:</th>
      <td>hello-kubernetes-7c8575c848-fvqm2</td>
    </tr>
    <tr>
      <th>node:</th>
      <td>allinone (Linux 5.14.21-150400.24.46-default)</td>
    </tr>
  </table>
</div>
<div id="footer">
  paulbouwer/hello-kubernetes:1.10 (linux/amd64)
</div>
    </div>
  </div>

</body>
</html>
```

Also to verify that MetalLB is working correctly `arping` can be used as:

`arping hellok3s.${IP}.sslip.io`

Expected result:

```sh
ARPING 192.168.64.210
60 bytes from 92:12:36:00:d3:58 (192.168.64.210): index=0 time=1.169 msec
60 bytes from 92:12:36:00:d3:58 (192.168.64.210): index=1 time=2.992 msec
60 bytes from 92:12:36:00:d3:58 (192.168.64.210): index=2 time=2.884 msec
```

In the example above, the traffic flows as follows:
1. `hellok3s.${IP}.sslip.io` is resolved to the actual IP.
2. Then the traffic is handled by the `metallb-speaker` pod.
3. `metallb-speaker` redirects the traffic to the `traefik` controller.
4. Finally Traefik forwards the request to the `hello-kubernetes` Service.
