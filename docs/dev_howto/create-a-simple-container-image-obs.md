---
sidebar_position: 2
title: Create a simple container image based on Tumbleweed using OBS (openSUSE Build Service)
---

## Create the project to host the assets

In this case it will be a _subproject_ of the "home:foobar" project

* Go to https://build.opensuse.org/
* Log in
* Select "Your Home Project" (Left Nav menu)
* Select the "Subprojects" tab
* Press "Create Subproject" (In Left Nav menu);
* Fill in the name (e.g. containers).

## Enable container builds in the project config

* Go to https://build.opensuse.org/project/show/home:foobar
* Select the "Project Config" tab
* Paste the following code:

```
%if "%_repository" == "images"
Type: docker
Repotype: none
Patterntype: none
BuildEngine: podman
%endif
```

## Add the Tumbleweed images repository

* Go to the subproject home page (e.g. https://build.opensuse.org/repositories/home:foobar:containers)
* Select the "Repositories" tab
* Press the "Add from a Project" button
* Fill in "Project" field with "`openSUSE:Templates:Images:Tumbleweed`"
* Choose "images" in Repositories dropdown
* Rename it as "images" (this is important as it will be later on used in the registry path)
* Unselect all the architectures you don't need

## Create a package for the subproject

* Go to https://build.opensuse.org/project/show/home:foobar:containers
* Press "Create Package" button
* Fill in the name (e.g. mytoolbox).

## Create the Dockerfile

Create a simple Dockerfile locally, something like:

```
# The container image tag needs to be specified as follows:
#!BuildTag: mytoolbox:latest
 
FROM opensuse/tumbleweed
RUN zypper -n in traceroute iputils netcat-openbsd curl && \
    zypper clean -a
```

## Upload the Dockerfile

* Go to https://build.opensuse.org/package/show/home:foobar:containers/mytoolbox
* Press the "Add File" button
* Choose the file and upload it

## Build results

* Go to https://build.opensuse.org/package/show/home:foobar:containers/mytoolbox
* Images will appear in Build Results section
* Press the "Refresh" button in Build Results section
* Wait for build results.

## Resulting images

If everything went as it should, the container image will be hosted at the [openSUSE registry](https://registry.opensuse.org/)

* Go to https://registry.opensuse.org/
* On the search bar, type "project=^home:foobar:" and press enter
* Click on the package icon or name (home/foobar/containers/images/mytoolbox)
* Expand the tag (latest) to see the Image IDs, arch, build time, etc as well as the `podman pull` command.

## Modify the Dockerfile file via CLI

* Install `osc` via your favourite package manager (see https://en.opensuse.org/openSUSE:OSC)
* Run `osc checkout home:foobar:containers`. It will ask your username/password and a method to store the password safely.
* Cd into that folder `cd home\:foobar\:containers/mytoolbox/`
* Edit the `Dockerfile` as you please
* Run `osc commit` and put a proper commit message
* The build will be automatically triggered
