#!/bin/bash

TESTFILE=$1  # this must be an absolute path to the feature file
TEST=`basename $TESTFILE`
TESTHOME="$HOME/$TEST"
TESTFILE=`echo $TESTFILE | sed "s|$HOME/code|$TESTHOME|"`

# cleanup function
cleanup() {
    kill $phppid
    dropdb $TEST
    rm -rf /mnt/ramdisk/sitedata/phpunit-$TEST $TESTHOME
}

# create separate database and sitedata for the test
dropdb $TEST > /dev/null 2>&1  # just in case ;)
createdb -T jenkins $TEST

cp -a /mnt/ramdisk/sitedata/phpunit /mnt/ramdisk/sitedata/phpunit-$TEST
rm -rf /mnt/ramdisk/sitedata/phpunit-$TEST/muc /mnt/ramdisk/sitedata/phpunit-$TEST/phpunit/lock
cp -a $HOME/code $TESTHOME

# update config.php
sed -i "s/jenkins/$TEST/g" $TESTHOME/config.php
sed -i "s|sitedata/phpunit|sitedata/phpunit-$TEST|g" $TESTHOME/config.php
#sed -i "s/localhost:8000/localhost:$PORT/g" $TESTHOME/config.php

# update phpunit.yml
#sed -i "s/localhost:8000/localhost:$PORT/g" /mnt/ramdisk/sitedata/phpunit-$TEST/phpunit/phpunit.yml
#sed -i "s|$HOME/code|$TESTHOME|g" /mnt/ramdisk/sitedata/phpunit-$TEST/phpunit/phpunit.yml

# run run run bananaphone!
echo "Testing $TESTFILE"
$TESTHOME/vendor/bin/phpunit --config $TESTFILE
phpunitresult=$?
cleanup
exit $phpunitresult

trap "cleanup" INT TERM EXIT
