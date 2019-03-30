Initialize
----------

```
useradd -m -s /bin/bash karl
```

```
sudo snap install docker &&
sudo apt update &&
sudo apt install -y docker-compose &&
sudo usermod -aG docker $(whoami) &&
git clone git@github.com:kstenerud/technicalsourcery.git &&
sudo mv technicalsourcery /home/
```

Bug workaround: https://stackoverflow.com/questions/47223280/docker-containers-can-not-be-stopped-or-removed-permission-denied-error

```
sudo systemctl disable apparmor.service --now &&
sudo service apparmor teardown
```



Start
-----

```
cd /home/technicalsourcery &&
docker-compose up
```


Update
------

```
ssh karl@technicalsourcery.net /home/technicalsourcery/refresh.sh
```
