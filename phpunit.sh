#!/bin/bash

#check if this version has phpunit
moodleversion=$(grep "\$release" $WORKSPACE/version.php | awk '{print $3}' | sed "s/'//g")
if [[ $moodleversion < 2.3 ]]
then
    echo "No phpunitz for this version of Moodle/Totara, so nothing to do :)"
    exit
fi

##
## SETUP
##

# clean the workspace a bit - not really required anymore, as the new git plugin
# has a config option for this
cd $WORKSPACE
git reset --hard HEAD
git clean -df

rm -rf $HOME/moodle-ci/sitedata/phpunit_$JOB_NAME/*
find $HOME/moodle-ci/sitedata/phpunit_$JOB_NAME -name ".*" -exec rm -rf {} \;
# just in case, clear the fake site dir too
rm -rf $HOME/moodle-ci/sitedata/site/*
find $HOME/moodle-ci/sitedata/site -name ".*" -exec rm -rf {} \;

dropdb $JOB_NAME
createdb -O jenkins -E utf8 $JOB_NAME

#add composer
#cp $HOME/moodle-ci/composer.phar $WORKSPACE/.
curl http://getcomposer.org/installer | php
php composer.phar install --dev

#add config
cp $HOME/moodle-ci/config.php $WORKSPACE/.

#set up phpunit
php $WORKSPACE/admin/tool/phpunit/cli/init.php


###
### Run phpunit tests
###
echo "RUNNING PHPUNIT TESTS"
vendor/bin/phpunit
