#!/bin/bash

source $HOME/config.sh

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

mkdir -p $SITEDATAROOT/phpunit-$DEFAULTPORT
mkdir -p $SITEDATAROOT/site  # some fake shiz that's needed

dropdb db-$DEFAULTPORT > /dev/null 2>&1  # just in case ;)
createdb -E utf8 db-$DEFAULTPORT

cd $CODEHOME

#add composer
curl http://getcomposer.org/installer | php
php composer.phar config github-oauth.github.com $GITHUB_TOKEN  # use token to deal with github limits
#php composer.phar install --dev
php composer.phar install

#set up phpunit
php $CODEHOME/admin/tool/phpunit/cli/init.php || exit 1


###
### Run phpunit tests
###
echo "RUNNING PHPUNIT TESTS"
#vendor/bin/phpunit
#find $CODEHOME ! -path "$CODEHOME/vendor/*" -path "*/tests/*_test.php" -type f -printf '%s %p\n' | sort -rn | awk '{print $2}' | parallel bash $HOME/testphpunitfile.sh "{}"
#find all the test suites by parsing phpunit.xml; run test suites in parallel
xmlstarlet sel -T -t -m '//phpunit/testsuites/testsuite/@name' -v '.' -n $CODEHOME/phpunit.xml | parallel bash $HOME/moodle-ci/testphpunitsuite.sh "{}"
exit $?
