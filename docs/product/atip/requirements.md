---
sidebar_position: 3
title: "*Draft* Prerequisites and Assumptions"
---

# SUSE Adaptive Telco Infrastructure Platform (ATIP)

SUSE ATIP is a platform designed for hosting modern, cloud native, Telco applications at scale from core to edge. 

This page will provide details of the expected requirements to deploy and use ATIP

##   Hardware
Minimum hardware specs, support, validated designs, stack validation etc
##   Network
Expected network setup, example setups
##   Services (DHCP, DNS, etc)
External services required by ATIP, common options for DHCP, DNS, etc.

## Disable rebootmgr strategic 

For telco workloads is really important to disable the rebootmgr strategic in order to avoid the reboot of the nodes in case of updates scheduled by the system.

You could verify the strategic status using the next command:

```bash
cat /etc/rebootmgr.conf
[rebootmgr]
window-start=03:30
window-duration=1h30m
strategy=best-effort
lock-group=default
```

and you could disable it using the next command:

```bash
sed -i 's/strategy=best-effort/strategy=off/g' /etc/rebootmgr.conf
```
or using the rebootmgrctl command:

```bash
rebootmgrctl strategy off
```

> For more information about rebootmgr, please check: https://github.com/SUSE/rebootmgr