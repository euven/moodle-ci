#!/bin/bash

TESTFILE=$1  # this must be an absolute path to the feature file
#PHPUNITTEST=`basename $TESTFILE`
PHPUNITTEST=`basename $TESTFILE``md5sum $TESTFILE | awk '{ print substr($1,1,6) }'`
export PHPUNITTEST
CODEHOME=/mnt/ramdisk/code
DEFAULTPORT=7000  # the default port set in configcloud.php, when no port is present

# cleanup function
cleanup() {
    dropdb db-$PHPUNITTEST
    rm -rf /mnt/ramdisk/sitedata/phpunit-$PHPUNITTEST
}

# create separate database and sitedata for the test
dropdb db-$PHPUNITTEST > /dev/null 2>&1  # just in case ;)
createdb -T db-$DEFAULTPORT db-$PHPUNITTEST

cp -a /mnt/ramdisk/sitedata/phpunit-$DEFAULTPORT /mnt/ramdisk/sitedata/phpunit-$PHPUNITTEST
rm -rf /mnt/ramdisk/sitedata/phpunit-$PHPUNITTEST/muc /mnt/ramdisk/sitedata/phpunit-$PHPUNITTEST/phpunit/lock

# run run run bananaphone!
echo "Testing $TESTFILE"
$CODEHOME/vendor/bin/phpunit $TESTFILE
phpunitresult=$?
cleanup
exit $phpunitresult

trap "cleanup" INT TERM EXIT
