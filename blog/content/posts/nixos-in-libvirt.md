---
title: "Test-driving a NixOS VM using libvirt"
date: 2021-08-01T14:11:43+01:00
featuredImage: "thumbnail.svg"
description: "NixOS has a lot of really cool ideas, but unfortunately installing on a VM is still tricky. This guide is designed as a \"just get me something working, please!\" way to get a headless NixOS install up and running in a libvirt VM."
categories:
  - virtualization
tags:
  - virtualization
  - nixos
  - libvirt
  - headless
---

NixOS has a lot of really cool ideas, but unfortunately installing on a VM is still tricky. This guide is designed as a "just get me something working, please!" way to get a headless NixOS install up and running in a libvirt VM.


Preliminary Pieces
------------------

You will need to have libvirt and virt-install on your system.

On Ubuntu:

```text
sudo apt update
sudo apt install qemu-kvm libvirt-daemon-system virtinst
```

On Redhat:

```text
sudo yum install kvm virt-manager libvirt libvirt-python python-virtinst
```

You'll also need the [NixOS minimal ISO image](https://nixos.org/download.html)


Booting the VM
--------------

First, launch a VM, picking a decent place to create your qcow2 disk image so that you can find it later:

```text
virt-install --name=nixos \
--memory=8196 \
--vcpus=2 \
--disk /path/to/my-nixos-disk-image.qcow2,device=disk,bus=virtio,size=16 \
--cdrom=/path/to/latest-nixos-minimal-x86_64-linux.iso \
--os-type=generic  \
--boot=uefi \
--nographics \
--console pty,target_type=virtio
```

This launches a UEFI-enabled (`--boot=uefi`) headless (`--nographics`) VM named "nixos" (`--name=nixos`) with 8 GB of RAM (`--memory=8192`), 2 CPUs (`--vcpus=2`), and a disk image with 16GB of space (`size=16`). It also connects to the guest's console (`--console pty,target_type=virtio`).

It will sit there awhile looking like it's stuck, but should boot within a couple of minutes:

```text
Starting install...
Connected to domain nixos
Escape character is ^]

<<< Welcome to NixOS 21.05.1970.11c662074e2 (x86_64) - hvc0 >>>
The "nixos" and "root" accounts have empty passwords.

An ssh daemon is running. You then must set a password
for either "root" or "nixos" with `passwd` or add an ssh key
to /home/nixos/.ssh/authorized_keys be able to login.


Run 'nixos-help' for the NixOS manual.

nixos login: nixos (automatic login)


[nixos@nixos:~]$
```


Some tips before you go further
-------------------------------

There will invariably be problems, so here are some tips:

### Exiting the console

To exit the console, hold the CTRL key and press `]`, then press Enter.

### Reconnecting to the console:

To reconnect to the console, type `virsh console nixos`

### Deleting everything and starting over

If you manage to screw up royally, here's how to start fresh:

* Stop the VM by typing `virsh destroy nixos`
* Remove the domain by typing `virsh undefine nixos --nvram`
* If you want the disk image gone also, you must delete it manually (wherever you put `my-nixos-disk-image.qcow2`)

### Accessing the VM from your host

Use the `virsh` command to access the VM from the host. It's a good idea to [familiarize yourself with virsh](https://libvirt.org/manpages/virsh.html).

```text
$ virsh list
 Id   Name    State
-----------------------
 13   nixos   running
```

### Getting the guest's IP address

You can do this within the guest by typing `ip a`, or you can do it from the host side using virsh's `net-dhcp-leases` command:

```text
$ virsh net-dhcp-leases default
 Expiry Time           MAC address         Protocol   IP address          Hostname         Client ID or DUID
-----------------------------------------------------------------------------------------------------------------
 2021-07-23 21:04:31   52:54:00:33:0c:ee   ipv4       192.168.111.206/24   nixos            01:52:54:00:33:0c:ee

```

### Connecting to the installer via SSH

The console can be a bit funny at times, so it's generally nicer to SSH in. We'll just use password-based SSH login since it's only the installer.

1. Create a password (Note: This is only setting a temporary password for the **installer**, not the OS you are about to install):

```text
[nixos@nixos:~]$ passwd
New password: 
Retype new password: 
passwd: password updated successfully
```

2. Get the IP address:

```text
[nixos@nixos:~]$ ip a
...
2: ens2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
...
    inet 192.168.111.206/24 brd 192.168.111.255 scope global dynamic noprefixroute ens2
...
```

3. SSH in to the installer:

```text
$ ssh nixos@192.168.111.206
Password: 
Last login: Sun Aug  1 05:39:07 2021

[nixos@nixos:~]$
```


Installing NixOS
----------------

Switch to root to make things easier:
```text
[nixos@nixos:~]$ sudo su

[root@nixos:/home/nixos]#
```

Now you can install. This follows the [example in the NixOS manual](https://nixos.org/manual/nixos/stable/#sec-installation-partitioning)

**Note**: Your disk image is `/dev/vda`

```text
parted --script /dev/vda -- mklabel gpt
parted --script /dev/vda -- mkpart primary 512MiB -8GiB
parted --script /dev/vda -- mkpart primary linux-swap -8GiB 100%
parted --script /dev/vda -- mkpart ESP fat32 1MiB 512MiB
parted --script /dev/vda -- set 3 esp on
mkfs.ext4 -F -L nixos /dev/vda1
mkswap -L swap /dev/vda2
mkfs.fat -F 32 -n boot /dev/vda3
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
swapon /dev/vda2
nixos-generate-config --root /mnt
```

From here, you can customize your install:

```text
nano /mnt/etc/nixos/configuration.nix
```

You should turn on SSH so that you can connect via secure shell after rebooting (or else just continue using the console):

```text
  services.openssh.enable = true; 
```

Once you're happy, press CTRL-X and save the file to exit the editor.

Start the installer:

```text
nixos-install
```

The last installer step will ask you to set the root password (use `nixos-install --no-root-passwd` to disable this and leave it blank):

```text
setting root password...
Enter new UNIX password: ***
Retype new UNIX password: ***
```

Finally, reboot. It will now boot from your installed disk:

```text
[root@nixos:/home/nixos]# reboot

Domain creation completed.
Restarting guest.
Connected to domain nixos
Escape character is ^]


<<< Welcome to NixOS 21.05.1970.11c662074e2 (x86_64) - hvc0 >>>

Run 'nixos-help' for the NixOS manual.

nixos login: 
```

Log in as root using the password you set (if a password wasn't set, it will log you in without a password):

```text
nixos login: root
Password: 

[root@nixos:~]# 
```

If you didn't set a root password, do so now by typing `passwd`.

You should also create a user for yourself because loggging in as root is dangerous:

```text
useradd -m myuser
passwd myuser
```

Now you can log in via the console, or via SSH if you turned it on:

```text
ssh myuser@192.168.111.206
```

At this point, you have a functional NixOS virtual machine. You're at the equivalent of [chapter 3 in the NixOS manual](https://nixos.org/manual/nixos/stable/#sec-changing-config), and can now start [configuring your OS](https://nixos.org/manual/nixos/stable/index.html#ch-configuration).
