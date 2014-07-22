#!/bin/bash

WORKSPACE=/home/ubuntu/code

#check if this version has phpunit
moodleversion=$(grep "\$release" $WORKSPACE/version.php | awk '{print $3}' | sed "s/'//g")
if [[ $moodleversion < 2.3 ]]
then
    echo "No phpunit for this version of Moodle/Totara, so nothing to do :)"
    exit
fi

##
## SETUP
##

mkdir -p /mnt/ramdisk/sitedata/phpunit
mkdir -p /mnt/ramdisk/sitedata/site  # some fake shiz that's needed

dropdb jenkins /dev/null 2>&1  # just in case ;)
createdb -E utf8 jenkins

cd $WORKSPACE

#add composer
curl http://getcomposer.org/installer | php
php composer.phar config github-oauth.github.com 21a8cb94266d3373f2bfb35a9d98f92063bf8ab9  # to deal with github limits
php composer.phar install --dev

#add config
cp $HOME/config.php $WORKSPACE/.

#set up phpunit
php $WORKSPACE/admin/tool/phpunit/cli/init.php


###
### Run phpunit tests
###
echo "RUNNING PHPUNIT TESTS"
vendor/bin/phpunit
#find $WORKSPACE ! -path "$WORKSPACE/vendor/*" -path "*/tests/*_test.php" -type f | parallel --delay 2 $WORKSPACE/vendor/bin/phpunit "{}"  # the parallel approach seems slower here :(
