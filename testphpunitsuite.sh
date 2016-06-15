#!/bin/bash

source $HOME/config.sh

TESTSUITE=$1  # a full suite name
PHPUNITTEST=`echo "$TESTSUITE" | awk '{print $1}'``echo "$TESTSUITE" | md5sum | awk '{print $1}'`  # add md5 for some uniqueness
export PHPUNITTEST

# cleanup function
cleanup() {
    dropdb db-$PHPUNITTEST
    rm -rf $SITEDATAROOT/phpunit-$PHPUNITTEST
}

# create separate database and sitedata for the test
dropdb db-$PHPUNITTEST > /dev/null 2>&1  # just in case ;)
createdb -T db-$DEFAULTPORT db-$PHPUNITTEST

cp -a $SITEDATAROOT/phpunit-$DEFAULTPORT $SITEDATAROOT/phpunit-$PHPUNITTEST
rm -rf $SITEDATAROOT/phpunit-$PHPUNITTEST/muc $SITEDATAROOT/phpunit-$PHPUNITTEST/phpunit/lock

# run run run bananaphone!
echo "Testing suite $TESTSUITE"
$CODEHOME/vendor/bin/phpunit --colors --testsuite "$TESTSUITE"
phpunitresult=$?
cleanup
exit $phpunitresult

trap "cleanup" INT TERM EXIT
