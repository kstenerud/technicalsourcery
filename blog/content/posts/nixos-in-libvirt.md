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


Prerequisites
-------------

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


Booting the Installer
---------------------

First, launch a VM, picking a decent place to create your qcow2 disk image (you will be installing to this) so that you can find it later:

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

**Note**: The `--cdrom` entry sets the ISO image to boot from **once**. After rebooting, it will boot from your qcow2 image instead.

After launching the VM, it will sit there awhile looking like it's stuck, but should boot within a couple of minutes:

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


Some tips before you continue
-----------------------------

There will invariably be problems, so here are some tips:

### Exiting the console

To exit the console, hold the CTRL key and press `]`, then press Enter.

### Reconnecting to the console:

To reconnect to the console, type `virsh console nixos`

### Deleting everything and starting over

If everything gets completely broken, here's how to start over fresh:

* Stop the VM by typing `virsh destroy nixos` (turns off the machine)
* Remove the domain by typing `virsh undefine nixos --nvram` (deletes the VM)
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

The console can be a bit funny at times (especially if you resize your shell window), so it's generally nicer to SSH in. We'll use a password-based SSH login since it's only the installer.

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

### Switch to root

Switch to root to make the installation process less cumbersome:
```text
[nixos@nixos:~]$ sudo su -

[root@nixos:~]#
```

### Setup the disk

This follows the [example in the NixOS manual](https://nixos.org/manual/nixos/stable/#sec-installation-partitioning), except that your disk is `/dev/vda`.

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

### Customize your install

At this point, you can customize your configuration before installing. To do so, edit your `configuration.nix`:

```text
[root@nixos:~]# nano /mnt/etc/nixos/configuration.nix
```

Once you're happy with your configuration, press CTRL-X and save the file to exit the editor.

#### Configuration: Add an admin user

It's a good idea to create an admin user for yourself because logging in as root is dangerous. Start by creating a password for yourself:

```text
[root@nixos:~]# mkpasswd -m sha-512
Password: 
$6$Cc5l1Gyv2gP$Mw0RKFkH719QCZAggQDTJIDcE4HoHFEYUqS71H0FVA/AHR4BJEWhfyPaR3RKiz3WsMsDp1di4oPX3b1s3s6Jt.
```

Next, add a user configuration modeled after this one to your `configuration.nix`:

```text
  users.users.myuser = {
    isNormalUser = true;
    home = "/home/myuser";
    description = "My user";
    # wheel allows sudo, networkmanager allows network modifications
    extraGroups = [ "wheel" "networkmanager" ];
    # For password login (works for console and SSH):
    hashedPassword = "$6$Cc5l1Gyv2gP$Mw0RKFkH719QCZAggQDTJIDcE4HoHFEYUqS71H0FVA/AHR4BJEWhfyPaR3RKiz3WsMsDp1di4oPX3b1s3s6Jt.";
    # For SSH key login (works for SSH only):
    openssh.authorizedKeys.keys = [ "ssh-dss AAAAB3Nza... myuser@foobar" ];
  };
```

#### Configuration: Enable SSH

You can also turn on SSH so that you can connect via secure shell after rebooting (otherwise only the console will work):

```text
  services.openssh.enable = true; 
```

### Run the installer

Once you're happy with your configuration, it's time to build and install the OS:

```text
[root@nixos:~]# nixos-install
```

If you made any mistakes, it will print out error messages detailing what you need to fix in your `configuration.nix`.

The last installer step will ask you to set the root password (you can use `nixos-install --no-root-passwd` to disable this and leave it blank):

```text
setting root password...
Enter new UNIX password: ***
Retype new UNIX password: ***
```

### Reboot

This will cause it to reboot into your newly installed disk:

```text
[root@nixos:~]# reboot

Domain creation completed.
Restarting guest.
Connected to domain nixos
Escape character is ^]


<<< Welcome to NixOS 21.05.1970.11c662074e2 (x86_64) - hvc0 >>>

Run 'nixos-help' for the NixOS manual.

nixos login: 
```

Log in as the admin user you created (or you can log in via SSH if you enbled it). If you need to make further changes to the configuration, edit `/etc/nixos/configuration.nix` and then build the new configuration:

```text
nixos-rebuild switch
```

At this point, you have a functional NixOS in a virtual machine. You're at the equivalent of [chapter 3 in the NixOS manual](https://nixos.org/manual/nixos/stable/#sec-changing-config), and can now start [configuring your OS](https://nixos.org/manual/nixos/stable/index.html#ch-configuration).

Enjoy!
