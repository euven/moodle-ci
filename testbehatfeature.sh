#!/bin/bash

FEATUREFILE=$1  # this must be an absolute path to the feature file
FEATURE=`basename $FEATUREFILE``echo $FEATUREFILE | md5sum | awk '{print substr($1,1,6)}'` # ensure uniqueness
FEATUREHOME="$HOME/$FEATURE"
FEATUREFILE=`echo $FEATUREFILE | sed "s|$HOME/code|$FEATUREHOME|"`

# cleanup function
cleanup() {
    kill $phppid
    dropdb $FEATURE
    rm -rf /mnt/ramdisk/sitedata/behat-$FEATURE $FEATUREHOME
}

# create separate database and sitedata for the feature
dropdb $FEATURE > /dev/null 2>&1  # just in case ;)
createdb -T jenkins $FEATURE

cp -a /mnt/ramdisk/sitedata/behat /mnt/ramdisk/sitedata/behat-$FEATURE
rm -rf /mnt/ramdisk/sitedata/behat-$FEATURE/muc /mnt/ramdisk/sitedata/behat-$FEATURE/behat/lock
cp -a $HOME/code $FEATUREHOME

# search for available port, starting at 8001 and incrementing by 1
#PORT=8000
#while true
#do
#PORT=$((PORT+1))
#if ! [[ `ps aux | grep "[p]hp -S" | grep "localhost:$PORT"` ]]
#then
    # start the webserver on the available port right away!
#    phppid=`php -S localhost:$PORT -t $FEATUREHOME > /dev/null 2>&1 & echo $!`
#    break;
#fi
#done
PORT=`FEATUREFILE=$FEATUREFILE php -r "srand(hexdec(substr(md5(getenv('FEATUREFILE')), 0, 16))); echo rand(6000, 20000);"`  # we need to ignore anything below 6000, as selenium goes there
phppid=`php -S localhost:$PORT -t $FEATUREHOME > /dev/null 2>&1 & echo $!`
echo "Web server started on port $PORT (pid: $phppid)"

# update config.php
sed -i "s/jenkins/$FEATURE/g" $FEATUREHOME/config.php
sed -i "s|sitedata/behat|sitedata/behat-$FEATURE|g" $FEATUREHOME/config.php
sed -i "s/localhost:8000/localhost:$PORT/g" $FEATUREHOME/config.php

# update behat.yml
sed -i "s/localhost:8000/localhost:$PORT/g" /mnt/ramdisk/sitedata/behat-$FEATURE/behat/behat.yml
sed -i "s|$HOME/code|$FEATUREHOME|g" /mnt/ramdisk/sitedata/behat-$FEATURE/behat/behat.yml

# run run run bananaphone!
echo "Testing $FEATUREFILE"
$FEATUREHOME/vendor/bin/behat --config /mnt/ramdisk/sitedata/behat-$FEATURE/behat/behat.yml $FEATUREFILE
behatresult=$?
cleanup
exit $behatresult

trap "cleanup" INT TERM EXIT


