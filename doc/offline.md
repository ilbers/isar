= Working Offline

== Prepare Partial Debian Mirror

```
HOST=ftp.de.debian.org
WEB_HOME=/mnt/sdc1/w
ARCHES=amd64,arm64,armhf,i386
mkdir -p $WEB_HOME
```

```
DST=$WEB_HOME/debian
DISTROS=bullseye,bullseye-updates,bookworm,bookworm-updates
time debmirror -p --getcontents -e http -h $HOST -d $DISTROS -a $ARCHES $DST
```

```
DST=$WEB_HOME/debian-security
DISTROS=bullseye/updates,bookworm/updates
time debmirror -p --getcontents -e http -h $HOST -r /debian-security \
    -d $DISTROS -a $ARCHES $DST
```

== Prepare Git Mirror

```
DST=$WEB_HOME/git
```

```
PKG=hello
mkdir -p $DST/ilbers/$PKG.git
cd $DST/ilbers/$PKG.git
git init --bare
cp hooks/post-update.sample hooks/post-update
cd -
git clone https://github.com/ilbers/$PKG.git
cd $PKG
git remote add local $DST/ilbers/$PKG.git
git push local master
```

Repeat for `libhello`.

== Set Up Apache

```
sudo apt-get install apache2
sudo vi /etc/apache2/sites-available/000-default.conf
```

```
<VirtualHost *:80>
	...
	Alias /debian /mnt/sdc1/w/debian
	Alias /debian-security /mnt/sdc1/w/debian-security
	Alias /git /mnt/sdc1/w/git
	<Directory /mnt/sdc1/w>
		Options +Indexes
		AllowOverride None
		Require all granted
	</Directory>
</VirtualHost>
```

Repeat for `/etc/apache2/sites-available/default-ssl.conf`.

`sudo systemctl reload apache2`

== Set Up BIND

A DNS server is necessary to resolve `localhost` from `buildchroot-target`.

```
sudo apt-get install bind9
sudo systemctl start bind9
sudo vi /etc/resolv.conf
```

```
nameserver 127.0.0.1
```

== Use Offline Files

```
git clone https://github.com/ilbers/isar.git
cd isar
. isar-init-build-env ../build
vi conf/local.conf
```

```
DISTRO_APT_PREMIRRORS = "\
    ftp\.de\.debian\.org localhost\n\
    security\.debian\.org localhost/debian-security\n"

PREMIRRORS:prepend = "git://github.com/ git://localhost/git/\n"

FETCHCMD:git = "GIT_SSL_NO_VERIFY=1 git -c core.fsyncobjectfiles=0"
```

Setting `GIT_SSL_NO_VERIFY` is necessary if SSL certificate is self-signed or
its CN isn't `localhost`.

== TODO

* Build without BIND
* Change `protocol=https` to `protocol=http` in `PREMIRRORS`, drop FETCHCMD_git
* Tool for mirroring git repos
