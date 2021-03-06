# build-Umgebung vorbereiten
apt-get install pbuilder cdebootstrap debootstrap devscripts
mkdir -p /mnt/sda8/backports/squeeze/debs/finished
mkdir -p /mnt/sda8/backports/squeeze/debs/unfinished
cd /mnt/sda8/backports/squeeze/debs/finished
apt-ftparchive packages . | gzip > Packages.gz
cd /mnt/sda8/backports/squeeze/debs/unfinished
apt-ftparchive packages . | gzip > Packages.gz

# wheezy:
#pbuilder --create --basetgz /var/cache/pbuilder/base-wheezy-bpo.tar.gz --distribution wheezy --architecture i386 --othermirror "deb http://security.debian.org/ wheezy/updates main|deb file:///home/ronny/lernstick/backports/wheezy/debs/finished ./|deb file:///home/ronny/lernstick/backports/wheezy/debs/unfinished ./|deb http://lernstick.killmulehill.net/debian wheezy-backports main" --bindmounts /home/ronny/lernstick/backports/wheezy/debs --allow-untrusted

# jessie32:
#pbuilder --create --basetgz /var/cache/pbuilder/base-jessie32-bpo.tar.gz --distribution jessie --architecture i386 --othermirror "deb http://security.debian.org/ jessie/updates main|deb http://http.debian.net/debian jessie-backports main|deb http://packages.lernstick.ch/lernstick lernstick-8 main contrib non-free|deb http://packages.lernstick.ch/lernstick lernstick-8-backports main contrib non-free|deb http://packages.lernstick.ch/lernstick lernstick-8-thirdparty main contrib non-free|deb http://packages.lernstick.ch/lernstick lernstick-8-staging main contrib non-free|deb http://packages.lernstick.ch/lernstick lernstick-8-thirdparty-staging main contrib non-free|deb http://packages.lernstick.ch/lernstick lernstick-8-backports-staging main contrib non-free|deb file:///home/ronny/lernstick/backports/jessie/debs/unfinished ./" --bindmounts /home/ronny/lernstick/backports/jessie/debs --allow-untrusted

# jessie64:
#pbuilder --create --basetgz /var/cache/pbuilder/base-jessie64-bpo.tar.gz --distribution jessie --architecture amd64 --othermirror "deb http://security.debian.org/ jessie/updates main|deb http://http.debian.net/debian jessie-backports main|deb file:///home/ronny/lernstick/backports/jessie/debs/unfinished ./|deb http://packages.lernstick.ch/lernstick lernstick-8-backports main contrib non-free" --bindmounts /home/ronny/lernstick/backports/jessie/debs --allow-untrusted


# armhf:
pbuilder --create --basetgz /var/cache/pbuilder/base-jessie64-bpo.tar.gz --distribution jessie --architecture armhf --othermirror "deb http://security.debian.org/ jessie/updates main|deb http://http.debian.net/debian jessie-backports main|deb file:///home/ronny/lernstick/backports/jessie/debs/unfinished ./|deb http://packages.lernstick.ch/lernstick lernstick-8-backports main contrib non-free" --bindmounts /home/ronny/lernstick/backports/jessie/debs --allow-untrusted

# Source-Paket der Software herunterladen
cat <<EOF > /etc/apt/sources.list.d/wheezy-src.list
deb-src http://ftp.ch.debian.org/debian/ wheezy main
EOF
apt-get update

# chroot aktualisieren
# (sollte nur sehr selten notwendig sein)
pbuilder --update --architecture i386 --allow-untrusted --basetgz /var/cache/pbuilder/base-wheezy-bpo.tar.gz --bindmounts /home/ronny/lernstick/backports/wheezy


# Sourcen herunterladen und anpassen (damit es als Backport erkennbar wird)
apt-get source $PACKAGE
cd $PACKAGE-*
# debian/control: add new field
# Uploaders: Sylvain Beucler <beuc@beuc.net>
export DEBEMAIL="ronny.standtke@fhnw.ch" 
export DEBFULLNAME="Ronny Standtke"
export EDITOR="vim"
dch --bpo

# Sourcen in chroot übersetzen

# wheezy:
sudo pbuilder --login --architecture i386 --basetgz /var/cache/pbuilder/base-wheezy-bpo.tar.gz --bindmounts /home/ronny/lernstick/backports/wheezy

# jessie32:
sudo pbuilder --login --architecture i386 --basetgz /var/cache/pbuilder/base-jessie32-bpo.tar.gz --bindmounts /home/lernstick/lernstick/backports/jessie

# jessie64:
sudo pbuilder --login --basetgz /var/cache/pbuilder/base-jessie-bpo.tar.gz --bindmounts /home/ronny/lernstick/backports/jessie

cd /mnt/sda8/backports/$PACKAGE-*

apt-get update; apt-get upgrade; apt-get -t jessie-backports --yes --force-yes install pbuilder; apt-get --yes --force-yes install sudo devscripts fakeroot; /usr/lib/pbuilder/pbuilder-satisfydepends --continue-fail; export DEB_BUILD_OPTIONS=noddebs

erstes build:
dpkg-buildpackage -sa

nachfolgende builds (z.B. backport für eine andere Architektur):
dpkg-buildpackage -B

früher:
debuild -nc

# der Schalter "-ai386" sollte eigentlich nicht nötig sein, für libtool war es aber doch...
# der Schalter "-j3" beschleunigt das Bauen durch Parallelisierung, funktioniert jedoch nicht bei allen Paketen...

# damit backport für weitere, später gebaute backports verfügbar ist...
mv $PACKAGE /mnt/sda8/backports/squeeze/debs/unfinished
apt-ftparchive packages . | gzip > Packages.gz

# Paket testen, und wenn für gut befunden
mv $PACKAGE /mnt/sda8/backports/squeeze/debs/finished
apt-ftparchive packages . | gzip > Packages.gz
