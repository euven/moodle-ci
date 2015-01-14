#!/bin/bash

FEATUREFILE=$1  # this must be an absolute path to the feature file
FEATURE=`basename $FEATUREFILE``echo $FEATUREFILE | md5sum | awk '{print substr($1,1,6)}'` # ensure uniqueness
CODEHOME=/mnt/ramdisk/code
DEFAULTPORT=7000  # the default port set in configcloud.php, when no port is present

# first get a unique random port and fire up the webserver
# we need to ignore anything below 6000, as selenium goes there
PHPPORT=`FEATUREFILE=$FEATUREFILE DEFAULTPORT=$DEFAULTPORT php -r "srand(hexdec(substr(md5(getenv('FEATUREFILE')), 0, 16))); echo rand(getenv('DEFAULTPORT')+1, 20000);"`
while true
do
    if ! [[ `ps aux | grep "[p]hp -S" | grep "localhost:$PHPPORT"` ]]
    then
	export PHPPORT
	phppid=`php -S localhost:$PHPPORT -t $CODEHOME > /dev/null 2>&1 & echo $!`
	echo "Web server started on port $PHPPORT (pid: $phppid)"
        break
    fi
    echo "A highly unlikely port clash has occured :D - waiting for port $PHPPORT to become available"
    sleep 5
done

# cleanup function
cleanup() {
    kill $phppid
    dropdb db-$PHPPORT
    rm -rf /mnt/ramdisk/sitedata/behat-$PHPPORT
}

# create separate database and sitedata for the feature
#dropdb $FEATURE > /dev/null 2>&1  # just in case ;)
createdb -T db-$DEFAULTPORT db-$PHPPORT

cp -a /mnt/ramdisk/sitedata/behat-$DEFAULTPORT /mnt/ramdisk/sitedata/behat-$PHPPORT
rm -rf /mnt/ramdisk/sitedata/behat-$PHPPORT/muc /mnt/ramdisk/sitedata/behat-$PHPPORT/behat/lock

# update behat.yml
sed -i "s/localhost:$DEFAULTPORT/localhost:$PHPPORT/g" /mnt/ramdisk/sitedata/behat-$PHPPORT/behat/behat.yml

# run run run bananaphone!
echo "Testing $FEATUREFILE"
$CODEHOME/vendor/bin/behat --ansi --config /mnt/ramdisk/sitedata/behat-$PHPPORT/behat/behat.yml --tags "~@_file_upload" $FEATUREFILE
#$CODEHOME/vendor/bin/behat --config /mnt/ramdisk/sitedata/behat-$PHPPORT/behat/behat.yml --tags "~@javascript" $FEATUREFILE
behatresult=$?
cleanup
exit $behatresult

trap "cleanup" INT TERM EXIT
