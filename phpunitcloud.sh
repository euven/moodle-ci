#!/bin/bash

CODEHOME=/mnt/ramdisk/code
DEFAULTPORT=7000

#check if this version has phpunit
moodleversion=$(grep "\$release" $CODEHOME/version.php | awk '{print $3}' | sed "s/'//g")
echo "version is $moodleversion"
if [[ $moodleversion < 2.3 ]]
then
    echo "No phpunit for this version - nothing to do :)"
    exit
fi

echo "RUNNING PHPUNIT TESTS"

##
## SETUP
##

mkdir -p /mnt/ramdisk/sitedata/phpunit-$DEFAULTPORT
mkdir -p /mnt/ramdisk/sitedata/site  # some fake shiz that's needed

dropdb db-$DEFAULTPORT > /dev/null 2>&1  # just in case ;)
createdb -E utf8 db-$DEFAULTPORT

cd $CODEHOME

#add composer
curl http://getcomposer.org/installer | php
php composer.phar config github-oauth.github.com 21a8cb94266d3373f2bfb35a9d98f92063bf8ab9  # to deal with github limits
#php composer.phar install --dev
php composer.phar install

#add config
cp $HOME/config.php $CODEHOME/.

#set up phpunit
php $CODEHOME/admin/tool/phpunit/cli/init.php


###
### Run phpunit tests
###
echo "RUNNING PHPUNIT TESTS"
#vendor/bin/phpunit
#find $CODEHOME ! -path "$CODEHOME/vendor/*" -path "*/tests/*_test.php" -type f -printf '%s %p\n' | sort -rn | awk '{print $2}' | parallel bash $HOME/testphpunitfile.sh "{}"
xmlstarlet sel -T -t -m '//phpunit/testsuites/testsuite/@name' -v '.' -n $CODEHOME/phpunit.xml | parallel bash $HOME/testphpunitsuite.sh "{}"
exit $?
