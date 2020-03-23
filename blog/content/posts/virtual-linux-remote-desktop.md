---
title: "Virtual Linux Remote Desktop"
date: 2019-04-03T07:03:11+01:00
featuredImage: "thumbnail.jpg"
description: "Have you ever wanted a persistent Linux virtual desktop that you could host anywhere and access remotely? Now you can do it, using only Ubuntu and a cheap VPS!"
categories:
  - remote-desktop
tags:
  - remote-desktop
  - linux
---

Have you ever wanted a persistent Linux virtual desktop that you could host anywhere and access remotely? Now you can do it, using only Ubuntu and a cheap VPS!

I like having deterministic work environments. Disaster recovery becomes a cinch when you can just destroy and rebuild your desktop container, map your home directory back in, and continue working.


## How it Works

There are remote desktop packages that can operate on top of a purely software X window stack. We can leverage that to run in a container, where there is no hardware to access. All we need to do is install the desktop environment, and then set up the remote desktop software. This setup works in containers, virtual machines, even bare metal.

I'll be using Ubuntu as my base operating system, but it should be doable in other distributions as well.


## Baseline Setup

The desktop environment will attempt to install bluetooth, which will break things. We pre-emptively install and disable it:

```bash
sudo apt update
sudo apt install -y bluez
sudo systemctl disable bluetooth
```

You'll need some preliminary tools installed:

```bash
sudo apt install -y software-properties-common openssh-server locales tzdata debconf
```

### Desktop Environment

Next, choose a desktop environment. Due to dbus issues, only mate and lxde desktop environments work when installed this way.

```bash
sudo apt install -y ubuntu-mate-desktop
```

or

```bash
sudo apt install -y lubuntu-desktop
```

This step will take awhile!


## Configure for GUI Use

light-locker will interfere with remote desktop software, so remove it if it got installed:

```bash
sudo apt remove -y light-locker
```

Here are some services we don't need to have running:

```bash
sudo systemctl disable apport
sudo systemctl disable cpufrequtils
sudo systemctl disable hddtemp
sudo systemctl disable lm-sensors
sudo systemctl disable network-manager
sudo systemctl disable speech-dispatcher
sudo systemctl disable ufw
sudo systemctl disable unattended-upgrades
```

Some other things you may want to set up:

#### Timezone:

```bash
sudo timedatectl set-timezone "America/Vancouver"
```

#### Language:

```bash
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8
```

#### Keyboard Layout:

```bash
echo "keyboard-configuration keyboard-configuration/layoutcode string us" | sudo debconf-set-selections
echo "keyboard-configuration keyboard-configuration/modelcode string pc105" | sudo debconf-set-selections
```

## Add a User

Depending on whether you're using lxc or multipass or some other virtualization system, you may already have a user set up such as "ubuntu". I prefer to set up my own user, like so:

```bash
sudo useradd -m -s /bin/bash -U -G adm,sudo mynewuser
echo mynewuser:mynewpassword | sudo chpasswd
```

Remember to set up allowed keys for the user if you have any.


## Remote Desktop Software

### X2Go

X2Go is the easiest to set up. It works over ssh, which is nice and convenient, but requires a direct connection. I prefer to grab the latest from the PPA, but the default may work for you as well.

```bash
sudo add-apt-repository -y ppa:x2go/stable
sudo apt install -y x2goserver x2goserver-xsession x2goclient
```

X2Go uses ssh for communication. You'll need to either set up allowed keys, or just for testing you could enable password authentication:

```bash
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sudo service ssh restart
```

### Chrome Remote Desktop

This is purely optional. You'll still need X2Go installed to be able to set up Chrome Remote Desktop.

First, download and install the debs:

```bash
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
sudo apt install -y ./google-chrome-stable_current_amd64.deb ./chrome-remote-desktop_current_amd64.deb
```

Chrome Remote Desktop will use a default screen resolution of 1600x1200, which is the wrong aspect ratio, and will result in black bands on the sides when you go fullscreen. We can just change it to whatever we want, for example 1920x1080:

```bash
sudo sed -i 's/DEFAULT_SIZE_NO_RANDR = "[0-9]*x[0-9]*"/DEFAULT_SIZE_NO_RANDR = "1920x1080"/g' /opt/google/chrome-remote-desktop/chrome-remote-desktop
```

Now you'll need to log in to the remote desktop via X2Go. You can get your virtual machine's ip address using `ip addr`, then log in as the user you created earlier.

**Note:** You may need to resize the virtual screen to see the menu bar.

Inside the X2Go remote desktop, do the following:

* Launch Chrome
* Sign in
* Turn on sync (or go to settings to selectively sync - even disable everything if you want)
* Go to the chrome store and install Chrome Remote Desktop
* Launch Chrome Remote Desktop and enable connections to your computer.

You should now be able to see and log in to your virtual desktop using Chrome Remote Desktop.

## Conclusion

Setting up a virtual desktop is a bit involved, but once you know what needs to be done, it's not too hard to write up a script that does this automatically. I do exactly that in my [Ubuntu dev environment installer](https://github.com/kstenerud/ubuntu-dev-installer).

Happy hacking!
