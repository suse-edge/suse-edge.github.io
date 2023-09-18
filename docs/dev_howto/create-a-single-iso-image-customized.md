---
sidebar_position: 3
title: Create a custom single-iso image (using SLE Micro installer and combustion image) to use it on Virtual CD-ROM
---

## Clone the SLE Micro installer repository from OBS

* Log in to [OBS](https://build.opensuse.org)
* Go to the [SLE Micro installer repository](https://build.opensuse.org/project/show/SUSE:SLE-15-SP4:Update:Products:Micro54/SLE-Micro)
* Create a branch from this project to link 2 packages (`combustion` and `SLE-Micro`) to modify the combustion package to add some extra code. Then we need to link the SLE Micro image to be able to build a new image with the combustion package modified.

To create the link between the 2 packages, go to the `Meta` tab and then add the next lines:

```xml
<repository name="standard">
  <path project="SUSE:SLE-15-SP4:Update:Products:Micro54" repository="standard"/>
  <arch>aarch64</arch>
  <arch>ppc64le</arch>
  <arch>s390x</arch>
  <arch>x86_64</arch>
</repository>
<repository name="images" rebuild="local">
  <path project="home:<user>:branches:SUSE:SLE-15-SP4:Update:Products:Micro54" repository="standard"/>
  <arch>x86_64</arch>
</repository>
```

After that click on `Save` and then you should see something like:

![obs-single-iso.png](images/obs-single-iso.png)

Now, any modification in the combustion package, after building the package, the SLE Micro image will be automatically rebuilt with the new combustion package changes.

## Modify the combustion package

To modify the combustion package, we need to go to the `combustion` package and then download the next file:

``` 
osc getbinaries home:<user>:branches:SUSE:SLE-15-SP4:Update:Products:Micro54 combustion standard x86_64 combustion-1.0+git2.obscpio
```

This file contains the combustion image that will be used by the SLE Micro installer to create the final image.

To extract the content of this file, we need to execute the next command:

```bash
cpio -idmv < combustion-1.0+git2.obscpio
```

After that, we should see something like:

```bash
$ ls -l
total 68
drwxr-xr-x   4096 sep 14 13:20 .
drwx------.  4096 sep 14 13:20 ..
-rw-r--r--   6064 sep 12 16:09 combustion
-rw-r--r--    512 sep 12 16:07 combustion-1.0+git2.obscpio
-rw-r--r--   1032 sep 12 16:07 combustion-prepare.service
-rw-r--r--   1488 sep 12 16:07 combustion.rules
-rw-r--r--   1009 sep 12 16:07 combustion.service
-rw-r--r--  18092 sep 12 16:07 LICENSE
-rw-r--r--    408 sep 12 16:07 Makefile
-rw-r--r--   1240 sep 14 13:20 module-setup.sh
-rw-r--r--   4686 sep 12 16:07 README.md
```

Let's change the next things:

- **Timeout** to wait for the config drive from 10 to 15 seconds

`sed -i 's/devtimeout=10/devtimeout=15/g' module-setup.sh`  

- **Combustion labels** to be able to mount the config drive adding the labels `install` and `INSTALL`

```bash
...
...
for label in combustion COMBUSTION ignition IGNITION install INSTALL; do
...
...
```

After changing the code, we need to create a new `combustion-1.0+git2.obscpio` file:

``` 
find combustion-1.0+git2 -type f -print | cpio -ocv > combustion-1.0+git2.obscpio
```

And upload again to the combustion package OBS to build a new package with the modifications

``` 
osc add combustion-1.0+git2.obscpio
osc commit -m "Update combustion-1.0+git2.obscpio"
```

After that you should see a new build is running: 

``` 
osc results
```

## Build a new SLE Micro OBS custom image with the new combustion package modified

After the combustion package is built, we need to rebuild a new SLE Micro image with the new combustion package.

To do that you can go to the `SLE-Micro` package and then click on `Trigger Rebuild` and then select the `images` repository and then click on `Trigger Rebuild` again.
Another easier option to do that, is to modify the `SLE-Micro.changes` to add some information about the new combustion changes and then commit the changes and then the image will be automatically rebuilt.


## Download the new iso image to prepare it with xorriso and adding combustion

After the image is built, we need to download the new iso image to prepare it with `xorriso` and adding combustion.
To do that, we need to go to the `images` repository and then download the new iso image.

Now, we should have the next files to generate the final `single-iso` image:

- Input:
  - SLE-Micro.x86_64-5.4.0-Default-SelfInstall-Build15.1.install.iso   (This is the new build image with the combustion package modified)
  - combustion folder with the next structure:
    - ./script   (this is the combustion script with the tasks we want to execute during the installation in the combustion phase)
- Output:
  -  SLE-Micro-Selfinstall-with-mycombustion-single-iso.iso (This is the final single-iso image with the combustion script included and the installer iso image)


Using `xorriso` we will create the final single-iso:

``` 
xorriso -indev ./SLE-Micro.x86_64-5.4.0-Default-SelfInstall-Build15.1.install.iso \
        -outdev ./SLE-Micro-Selfinstall-with-mycombustion-single-iso.iso \
        -map ~/my-local-path/combustion /combustion \
        -boot_image any replay -changes_pending yes
```

After that, we should have the final iso image with the combustion script included `SLE-Micro-Selfinstall-with-mycombustion-single-iso.iso`


> This feature will be added to the SLE Micro 5.5 release, but meanwhile, we could use this workaround to create a single-iso image with the combustion script included.