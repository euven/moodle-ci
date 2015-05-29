# moodle-ci - testing in parallel on Openstack

These scripts allow you to run Moodle's PHPUnit, Behat and lint tests in parallel, on Openstack ;)

Other scripts are also included that are used with Jenkins:
* auto job creator `updatejobs.sh` (put on cron) - uses *jenkins-autojobs* (`pip install jenkins-autojobs`)
* local git mirrors - `updatemirrors.sh` (put on cron)

## requirements
* Ubuntu 14.04 - other Linux OS's should work too - these instructions were tested and are written for Ubuntu 14.04
* Openstack cloud account - you can get one from http://www.catalyst.net.nz/what-we-offer/cloud-services/catalyst-cloud

## installation and config

### jenkins master server
* Apart from installing and setting up Jenkins, the following is required:
```
sudo apt-get install zip python-pip python-dev
sudo pip install python-novaclient
```
* Create an ssh key pair for jenkins; add the public key to openstack, with a key name of: jenkins
* As the jenkins user, checkout this repo to `/var/lib/jenkins/moodle-ci`
* Download Selenium's standalone server (version: $SELENIUM_VERSION) and stick it in `/var/lib/jenkins/moodle-ci/` too
* `cp config-dist.sh config.sh` and fill in creds
* Configure a jenkins job to:
  * execute `runtests.sh` when a build is triggered
  * execute `cleanup.sh` as a post-build script (bash traps don't seem to work yet)

### openstack snapshot
To prepare the snapshot for running Moodle/Totara tests, start off by installing the following:
```
sudo apt-get install php5 php5-dev php5-gd php5-pgsql php5-xdebug php5-curl php5-xmlrpc php5-intl php-soap haveged xvfb postgresql openjdk-7-jre unzip wget curl git vim firefox htop ghostscript parallel xmlstarlet xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic
sudo locale-gen en_AU.utf8
sudo update-locale
```
* For more speedz create a ram mount, where we'll host the db, code and sitedata
  * Edit `/etc/fstab` and add `/mnt/ramdisk tmpfs defaults,size=2048M` (depending on the flavour you plan to use, you might have to increase this)
  * `sudo mount -a`
* Add an ubuntu postgres user with creds as in `cloudconfig.php`
* Edit `postgres.conf` to point to a ramdisk location: `data_directory = '/mnt/ramdisk/postgresql/9.3/main'`

**NOTE**: some of the scripts might have to be modified to point to where you host your code and sitedata (TODO: make these locations configurable)

**These instructions are not perfect and a work in progress - feel free to contribute if anything is wrong/missing! Enjoy! :)**
