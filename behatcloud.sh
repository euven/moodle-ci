#!/bin/bash

source envrc
WORKSPACE=/mnt/ramdisk/code

#check if this version has behat
moodleversion=$(grep "\$release" $WORKSPACE/version.php | awk '{print $3}' | sed "s/'//g")
if [[ $moodleversion < 2.5 ]]
then
    echo "No behat for this version of Moodle/Totara, so nothing to do :)"
    exit
fi

echo "RUNNING BEHAT TESTS";

##
## SETUP
##
mkdir -p /mnt/ramdisk/sitedata/behat
mkdir -p /mnt/ramdisk/sitedata/site  # some fake shiz that's needed

dropdb db-7000 > /dev/null 2>&1  # just in case ;)
createdb -E utf8 db-7000

#add selenium - no way to get most current version yet :( #todo
#wget --no-verbose http://selenium-release.storage.googleapis.com/2.42/selenium-server-standalone-2.42.2.jar -O selenium-server-standalone.jar


#add composer
cd $WORKSPACE
curl http://getcomposer.org/installer | php
php composer.phar config github-oauth.github.com 21a8cb94266d3373f2bfb35a9d98f92063bf8ab9  # to deal with github limits

#add config
cp $HOME/config.php $WORKSPACE/.

#set up behat
php $WORKSPACE/admin/tool/behat/cli/init.php 


###
### Start services
###
# start selenium server
# use xvfb for running selenium/browser headlessly on a specified display

# fire up the hub
nohup java -jar $HOME/selenium-server-standalone.jar -role hub -browserTimeout 1000 > /dev/null 2>&1 & echo $!
sleep 15

# fire up the nodes
NODECOUNT=`nproc`
HUB='http://localhost:4444/grid/register'
for node in $(seq 1 $NODECOUNT); do
    NUMDISPLAY=$((10 + $node))
    PORT=$((5555 + $node))

    echo "Starting Xvfb on display $NUMDISPLAY..."
    Xvfb :$NUMDISPLAY -ac > /dev/null 2>&1 & echo $!
    echo "Starting selenium node on port $PORT"
    # use ramdisk, as this will create the browser profile in ram
    #DISPLAY=:$NUMDISPLAY nohup java -Djava.io.tmpdir=/mnt/ramdisk -jar $HOME/selenium-server-standalone.jar -role node -hub $HUB -port $PORT -timeout 0 -maxSession 1 -browserSessionReuse -Dwebdriver.chrome.driver=$HOME/chromedriver > /dev/null 2>&1 & echo $!
    DISPLAY=:$NUMDISPLAY nohup java -Djava.io.tmpdir=/mnt/ramdisk -jar $HOME/selenium-server-standalone.jar -role node -hub $HUB -port $PORT -timeout 0 -maxSession 1 -browserTimeout 1000 -browserSessionReuse > /dev/null 2>&1 & echo $!
    sleep 5
done


###
### Run tests
###
echo "RUNNING BEHAT TESTS"
# make sure the biggest tests get run first, to ensure max cpu utilisation
find $WORKSPACE ! -path "$WORKSPACE/vendor/*" -type f -name '*.feature' -printf '%s %p\n' | sort -rn | awk '{print $2}' | parallel --jobs 75% --delay 2 bash $HOME/testbehatfeature.sh {}
exit $?
