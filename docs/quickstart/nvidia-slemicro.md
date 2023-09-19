---
sidebar_position: 8
title: NVIDIA GPU's on SLE Micro
---

# Intro

In this guide, we'll show you how to implement host-level NVIDIA GPU support via the pre-built [open-source drivers](https://github.com/NVIDIA/open-gpu-kernel-modules) on SLE Micro 5.3+. In other words, drivers that are baked into the operating system rather than dynamically loaded by NVIDIA's [GPU Operator](https://github.com/NVIDIA/gpu-operator). This configuration is highly desirable for customers that want to pre-bake all artefacts required for deployment into the image, and where the dynamic selection of the driver version is not a requirement. This guide shows how to deploy the additional components onto a pre-installed system, but the steps could also be used to create a deployment image with the software pre-baked.

However, should you want to utilise the GPU Operator for Kubernetes integration, it should still be possible to follow this guide and enable the GPU operator by telling it to utilise the *pre-installed* drivers via the `driver.enabled=false` flag in the NVIDIA GPU Operator Helm chart, where more comprehensive instructions are available [here](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/install-gpu-operator.html#chart-customization-options).

It's important to call out that the support for these drivers is provided by both SUSE and NVIDIA in tight collaboration, however if you have any concerns or questions about the combination in which you're utilising the drivers, then please ask your SUSE or NVIDIA account managers for further assistance. If you're planning on utilising [NVIDIA AI Enterprise](https://www.nvidia.com/en-gb/data-center/products/ai-enterprise/) (NVAIE) you will need to ensure that you're using an [NVAIE certified GPU](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/platform-support.html#supported-nvidia-gpus-and-systems), which *may* require the use of proprietary NVIDIA drivers. If you're unsure, please speak with your NVIDIA representative.

> NOTE: The instructions provided below will drastically simplify in the coming weeks; the instructions below demonstrate how to pull some packages from SLES repos and install them on SLE Micro, and we're currently porting these packages over to SLE Micro 5.3, 5.4, and 5.5. They'll also be available in the ALP-based Micro equivalent in the coming months.

## Prerequisites

If you're following this guide, it's assumed that you've got the following already available:

* At least one host with SLE Micro 5.3+ installed; this can be physical or virtual.
* Your host(s) is/are attached to a subscription as this will be required for package access - an evaluation is available [here](https://www.suse.com/download/sle-micro/).
* A [compatible NVIDIA GPU](https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus) installed (or passed through to the virtual machine in which SLE Micro is running).
* Access to the root user - these instructions assume you're the root user, and *not* escalating your privileges via `sudo`.

## Installation

Currently, the required packages for the NVIDIA open driver are not available in standard SLE Micro package repositories, only SUSE Linux Enterprise Server (SLES), so we need to pull them from those repositories, which we can easily do via the toolbox utility. Note that this will not be required in coming weeks - we're currently making these packages available in SLE Micro, so the next few steps will become redundant.

In the meantime, ensure that you've got the `mounts.conf` file setup correctly, this will ensure that any containers started by podman (which includes the `toolbox` utility) will automatically have your SUSE Connect credentials injected into the image. This will allow package access so we can download the packages from the SLES repositories (this file is *usually* already configured on SLE Micro 5.3, but let's make sure): 

```shell
cat << EOF > /etc/containers/mounts.conf
# This configuration file specifies the default mounts for each container of the
# tools adhering to this file (e.g., CRI-O, Podman, Buildah).  The format of the
# config is /SRC:/DST, one mount per line.
#/etc/SUSEConnect:/etc/SUSEConnect
/etc/zypp/credentials.d/SCCcredentials:/etc/zypp/credentials.d/SCCcredentials
EOF
```

Next, make a temporary directory in which we can push the packages that we need to download from SLES onto the local filesystem, for this I'm just using `/root/nvidia`:

```shell
mkdir -p /root/nvidia
```

Now we can open up the `toolbox` utility, which provides additional command line tooling and utilities that are not part of SLE Micro's base operating system. This tool is useful for troubleshooting a system where you want to maintain a minimal footprint underlying operating system:

```shell
toolbox
```

Once we're in the toolbox utility, we can ask the package manager (`zypper`) to add the `sle-module-basesystem` module, refresh the repositories, and then *download* the NVIDIA driver packages into the previously created `/root/nvidia` directory on the host filesystem, noting that from within toolbox the absolute path is `/media/root/root/nvidia`. In the example below we're specifically pulling the "G06" generation of driver, which supports the latest GPU's (please see [here](https://en.opensuse.org/SDB:NVIDIA_drivers#Install) for further information), so please ensure that you're selecting an appropriate GPU version.

In addition, the example below calls for *535.86.05* of the driver; please make sure that the driver version that you're selecting is compatible with your GPU, and in addition meets the CUDA requirements (if applicable) by checking [here](https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/). It's also advisable to check the [NVIDIA SLE15-SP4 repository](http://download.nvidia.com/suse/sle15sp4/x86_64/) to ensure that the driver version that you've chosen has an equivalent `nvidia-compute-utils-G06` package with the same version string; this repository is regularly refreshed by NVIDIA, but the versions need to match; there's a possibility that we have a newer driver version in the SUSE repo than NVIDIA has in theirs (or vice versa), so it's important to match the versions here.

When you've confirmed the above, use the following commands to pull the required packages appropriate for your system:

```shell
ADDITIONAL_MODULES=sle-module-basesystem zypper ref
zypper --pkg-cache-dir /media/root/root/nvidia install -y --download-only nvidia-open-driver-G06-signed-kmp=535.86.05
```

Now that you've got the packages available outside of the toolbox utility, exit the toolbox:

```shell
exit
```

> NOTE: Please make sure that you've exited the `toolbox` utility before proceeding!

Now you're ready to install the packages on the host operating system, and for this we need to open up a `transactional-update` session, which creates a new read/write snapshot of the underlying operating system so we can make changes to the immutable platform (for further instructions on `transactional-update` see [here](https://documentation.suse.com/sle-micro/5.4/html/SLE-Micro-all/sec-transactional-udate.html)):

```shell
transactional-update shell
```

When you're in your `transactional-update` shell, add the additional required package repositories from NVIDIA; this will allow us to pull in additional utilities, e.g. `nvidia-smi`, along with access to CUDA packages that you may want to utilise:

```shell
zypper ar https://developer.download.nvidia.com/compute/cuda/repos/sles15/x86_64/ nvidia-sle15sp4-cuda
zypper ar http://download.nvidia.com/suse/sle15sp4/ nvidia-sle15sp4-main
```

Next, move to the `/root/nvidia` directory, which will contain a couple of directories that the previous `zypper` command created with the downloaded packages from SLES. Then, we can request that the package manager install the pre-built signed kernel modules, the firmware packages, and the additional useful utilities package:

```shell
cd /root/nvidia/container-suseconnect-zypp:SLE-Module-Basesystem15-SP4-Updates/x86_64
zypper in -y nvidia-open-driver-G06-signed-kmp-default* kernel-firmware-nvidia-gspx-G06* nvidia-compute-utils-G06
```

> NOTE: If this fails to install it's likely that there's a dependency mismatch between the selected driver version and what NVIDIA is shipping in their repositories - please revisit the section above to validate that your versions match; it may require you to remove files from `/root/nvidia` and re-execute the commands starting from `toolbox`.

Now that you've installed these packages, it's time to exit the `transactional-update` session:

```shell
exit
```

> NOTE: Please make sure that you've exited the `transactional-update` session before proceeding!

Next, if you're *not* using a supported GPU, remembering that the list can be found [here](https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus), you can see if the driver will work by enabling support at the module level, but your mileage may vary -- skip this step if you're using a *supported* GPU:

```shell
sed -i '/NVreg_OpenRmEnableUnsupportedGpus/s/^#//g' /etc/modprobe.d/50-nvidia-default.conf
```

Now that you've got your drivers installed, it's time to reboot, as SLE Micro is an immutable operating system it needs to reboot into the new snapshot that you created in a previous step; the drivers are only installed into this new snapshot, and hence it's not possible to load the drivers without rebooting into this new snapshot, which will happen automatically. Issue the reboot command when you're ready:

```shell
reboot
```

Once the system has rebooted successfully, log back in and try to use the `nvidia-smi` tool to verify that the driver is loaded successfully and that it's able to both access and enumerate your GPU(s):

```shell
nvidia-smi
```

The output of this command should show you something similar to the following output, noting that in the example below we have two GPU's:

```shell
Mon Sep 18 06:58:12 2023
+---------------------------------------------------------------------------------------+
| NVIDIA-SMI 535.86.05              Driver Version: 535.86.05    CUDA Version: 12.2     |
|-----------------------------------------+----------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |         Memory-Usage | GPU-Util  Compute M. |
|                                         |                      |               MIG M. |
|=========================================+======================+======================|
|   0  NVIDIA A100-PCIE-40GB          Off | 00000000:17:00.0 Off |                    0 |
| N/A   29C    P0              35W / 250W |      4MiB / 40960MiB |      0%      Default |
|                                         |                      |             Disabled |
+-----------------------------------------+----------------------+----------------------+
|   1  NVIDIA A100-PCIE-40GB          Off | 00000000:CA:00.0 Off |                    0 |
| N/A   30C    P0              33W / 250W |      4MiB / 40960MiB |      0%      Default |
|                                         |                      |             Disabled |
+-----------------------------------------+----------------------+----------------------+

+---------------------------------------------------------------------------------------+
| Processes:                                                                            |
|  GPU   GI   CI        PID   Type   Process name                            GPU Memory |
|        ID   ID                                                             Usage      |
|=======================================================================================|
|  No running processes found                                                           |
+---------------------------------------------------------------------------------------+
```

...and that's it! You've successfully installed and verified that the NVIDIA drivers are loaded into SLE Micro.

## Further Validation

At this stage, all we've been able to verify is that at the host level the NVIDIA device can be accessed and that the drivers are loading successfully. However, if we want to be sure that it's functioning, a simple test would be to try and validate that the GPU can take instruction from a user-space application, ideally via a container, and through the CUDA library, as that's typically what a real workload would utilise. For this, we can make a further modification to the host OS by installing the `nvidia-container-toolkit`. First, open up another `transactional-update` shell, noting that we could have done this in a single transaction in the previous step, but to many (e.g. customers wanting to use Kubernetes) this step won't be required:

```shell
transactional-update shell
```

Next, install the `nvidia-container-toolkit` package, which comes from one of the repo's that we configured in a previous step. Note that this command will initially appear to fail as it has a dependency on `libseccomp`, whereas this package is `libseccomp2` in SLE Micro, so you can safely select the second option ("break dependencies") here:

```shell
zypper in install nvidia-container-toolkit
```

Your output should look like the following:

```shell
Refreshing service 'SUSE_Linux_Enterprise_Micro_5.4_x86_64'.
Refreshing service 'SUSE_Linux_Enterprise_Micro_x86_64'.
Refreshing service 'SUSE_Package_Hub_15_SP4_x86_64'.
Loading repository data...
Reading installed packages...
Resolving package dependencies...

Problem: nothing provides 'libseccomp' needed by the to be installed nvidia-container-toolkit-1.14.1-1.x86_64
 Solution 1: do not install nvidia-container-toolkit-1.14.1-1.x86_64
 Solution 2: break nvidia-container-toolkit-1.14.1-1.x86_64 by ignoring some of its dependencies

Choose from above solutions by number or cancel [1/2/c/d/?] (c): 2
(...)
```

> NOTE: We're working on fixing this dependency issue, so this should be a lot cleaner in the coming weeks.

When you're ready, you can exit the `transactional-update` shell:

```shell
exit
```
...and reboot the machine into the new snapshot:

```shell
reboot
```

> NOTE: As before, you will need to ensure that you've exited the `transactional-shell` and rebooted the machine for your changes to be enacted.

Now that the machine has rebooted, you can validate that the system is able to successfully enumerate the devices via the NVIDIA container toolkit (the output should be verbose, and it should provide a number of INFO and WARN messages, but no ERROR messages):

```shell
nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
```

When ready, you can then run a podman-based container (doing this via `podman` gives us a good way of validating access to the NVIDIA device from within a container, which should give confidence for doing the same with Kubernetes), giving it access to the labelled NVIDIA device(s) that were taken care of by the previous command, based on [SLE BCI](https://registry.suse.com/bci/bci-base-15sp5/index.html) and simply running bash:

```shell
podman run --rm --device nvidia.com/gpu=all --security-opt=label=disable -it registry.suse.com/bci/bci-base:latest bash
```

When we're in the temporary podman container we can install the required CUDA libraries, again checking the correct CUDA version for your driver [here](https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/) although the previous output of `nvidia-smi` should show the required CUDA version. In the example below we're installing *CUDA 12.1* and we're pulling a large number of examples, demo's, and development kits so you can fully validate the GPU:

```shell
zypper ar http://developer.download.nvidia.com/compute/cuda/repos/sles15/x86_64/ cuda-sle15-sp4
zypper in -y cuda-libraries-devel-12-1 cuda-minimal-build-12-1 cuda-demo-suite-12-1
```

Once this has been installed successfully, don't exit from the container, we'll run the `deviceQuery` CUDA example, which will comprehensively validate GPU access via CUDA, and from within the container itself:

```shell
/usr/local/cuda-12/extras/demo_suite/deviceQuery
```

If successful, you should see output that shows similar to the following, noting the `Result = PASS` message at the end of the command:

```shell
/usr/local/cuda-12/extras/demo_suite/deviceQuery Starting...

 CUDA Device Query (Runtime API) version (CUDART static linking)

Detected 2 CUDA Capable device(s)

Device 0: "NVIDIA A100-PCIE-40GB"
  CUDA Driver Version / Runtime Version          12.2 / 12.1
  CUDA Capability Major/Minor version number:    8.0
  Total amount of global memory:                 40339 MBytes (42298834944 bytes)
  (108) Multiprocessors, ( 64) CUDA Cores/MP:     6912 CUDA Cores
  GPU Max Clock rate:                            1410 MHz (1.41 GHz)
  Memory Clock rate:                             1215 Mhz
  Memory Bus Width:                              5120-bit
  L2 Cache Size:                                 41943040 bytes
  Maximum Texture Dimension Size (x,y,z)         1D=(131072), 2D=(131072, 65536), 3D=(16384, 16384, 16384)
  Maximum Layered 1D Texture Size, (num) layers  1D=(32768), 2048 layers
  Maximum Layered 2D Texture Size, (num) layers  2D=(32768, 32768), 2048 layers
  Total amount of constant memory:               65536 bytes
  Total amount of shared memory per block:       49152 bytes
  Total number of registers available per block: 65536
  Warp size:                                     32
  Maximum number of threads per multiprocessor:  2048
  Maximum number of threads per block:           1024
  Max dimension size of a thread block (x,y,z): (1024, 1024, 64)
  Max dimension size of a grid size    (x,y,z): (2147483647, 65535, 65535)
  Maximum memory pitch:                          2147483647 bytes
  Texture alignment:                             512 bytes
  Concurrent copy and kernel execution:          Yes with 3 copy engine(s)
  Run time limit on kernels:                     No
  Integrated GPU sharing Host Memory:            No
  Support host page-locked memory mapping:       Yes
  Alignment requirement for Surfaces:            Yes
  Device has ECC support:                        Enabled
  Device supports Unified Addressing (UVA):      Yes
  Device supports Compute Preemption:            Yes
  Supports Cooperative Kernel Launch:            Yes
  Supports MultiDevice Co-op Kernel Launch:      Yes
  Device PCI Domain ID / Bus ID / location ID:   0 / 23 / 0
  Compute Mode:
     < Default (multiple host threads can use ::cudaSetDevice() with device simultaneously) >

Device 1: "NVIDIA A100-PCIE-40GB"
  CUDA Driver Version / Runtime Version          12.2 / 12.1
  CUDA Capability Major/Minor version number:    8.0
  Total amount of global memory:                 40339 MBytes (42298834944 bytes)
  (108) Multiprocessors, ( 64) CUDA Cores/MP:     6912 CUDA Cores
  GPU Max Clock rate:                            1410 MHz (1.41 GHz)
  Memory Clock rate:                             1215 Mhz
  Memory Bus Width:                              5120-bit
  L2 Cache Size:                                 41943040 bytes
  Maximum Texture Dimension Size (x,y,z)         1D=(131072), 2D=(131072, 65536), 3D=(16384, 16384, 16384)
  Maximum Layered 1D Texture Size, (num) layers  1D=(32768), 2048 layers
  Maximum Layered 2D Texture Size, (num) layers  2D=(32768, 32768), 2048 layers
  Total amount of constant memory:               65536 bytes
  Total amount of shared memory per block:       49152 bytes
  Total number of registers available per block: 65536
  Warp size:                                     32
  Maximum number of threads per multiprocessor:  2048
  Maximum number of threads per block:           1024
  Max dimension size of a thread block (x,y,z): (1024, 1024, 64)
  Max dimension size of a grid size    (x,y,z): (2147483647, 65535, 65535)
  Maximum memory pitch:                          2147483647 bytes
  Texture alignment:                             512 bytes
  Concurrent copy and kernel execution:          Yes with 3 copy engine(s)
  Run time limit on kernels:                     No
  Integrated GPU sharing Host Memory:            No
  Support host page-locked memory mapping:       Yes
  Alignment requirement for Surfaces:            Yes
  Device has ECC support:                        Enabled
  Device supports Unified Addressing (UVA):      Yes
  Device supports Compute Preemption:            Yes
  Supports Cooperative Kernel Launch:            Yes
  Supports MultiDevice Co-op Kernel Launch:      Yes
  Device PCI Domain ID / Bus ID / location ID:   0 / 202 / 0
  Compute Mode:
     < Default (multiple host threads can use ::cudaSetDevice() with device simultaneously) >
> Peer access from NVIDIA A100-PCIE-40GB (GPU0) -> NVIDIA A100-PCIE-40GB (GPU1) : Yes
> Peer access from NVIDIA A100-PCIE-40GB (GPU1) -> NVIDIA A100-PCIE-40GB (GPU0) : Yes

deviceQuery, CUDA Driver = CUDART, CUDA Driver Version = 12.2, CUDA Runtime Version = 12.1, NumDevs = 2, Device0 = NVIDIA A100-PCIE-40GB, Device1 = NVIDIA A100-PCIE-40GB
Result = PASS
```

From here, you can continue to run any other CUDA workload - you can utilise compilers, and any other aspect of the CUDA ecosystem to run some further tests. When you're done you can exit from the container, noting that whatever you've installed in there is ephemeral (so will be lost!), and hasn't impacted the underlying operating system:

```shell
exit
```

## Implementation with Kubernetes

(Coming soon!)