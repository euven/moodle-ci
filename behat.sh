#!/bin/bash

#check if this version has behat
moodleversion=$(grep "\$release" $WORKSPACE/version.php | awk '{print $3}' | sed "s/'//g")
if [[ $moodleversion < 2.5 ]]
then
    echo "No behatz for this version of Moodle/Totara, so nothing to do :)"
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

rm -rf $HOME/elearning/sitedata/behat_$JOB_NAME/*
find $HOME/elearning/sitedata/behat_$JOB_NAME -name ".*" -exec rm -rf {} \;
# just in case, clear the fake site dir too
rm -rf $HOME/elearning/sitedata/site/*
find $HOME/elearning/sitedata/site -name ".*" -exec rm -rf {} \;

dropdb $JOB_NAME
createdb -O jenkins -E utf8 $JOB_NAME

#add composer
curl http://getcomposer.org/installer | php
#cp $HOME/elearning/composer.phar $WORKSPACE/.

#add config
cp $HOME/elearning/config.php $WORKSPACE/.

#set up behat
#php $WORKSPACE/admin/tool/behat/cli/util.php --drop
php $WORKSPACE/admin/tool/behat/cli/init.php 

# get the generated conf file
behatconf=$HOME/elearning/sitedata/behat_$JOB_NAME/behat/behat.yml



###
### Run behat
###
# ensure built-in php webserver is running
if ! [[ `ps aux | grep "[p]hp -S $JOB_NAME.localhost:"` ]]
then
    # seeing that we're running multiple tests on this server, we need to use diff ports
    # when starting the internal php webserver. So... determine the port and fix the generated
    # behat.yml file to point to the right port

    # search for available port, starting at 8000 and incrementing by 1
    port=7999
    while true
    do
        port=$((port+1))
        if ! [[ `ps aux | grep "[p]hp -S" | grep ".localhost:$port"` ]]
        then
            break;
        fi
    done

    echo "Starting internal webserver at $JOB_NAME.localhost:$port...";
    php -S $JOB_NAME.localhost:$port -t $WORKSPACE > /dev/null 2>&1 & echo $!
else
    # internal webserver already running - get port
    port=`ps aux | grep "[p]hp -S $JOB_NAME.localhost:" | egrep -o $JOB_NAME.localhost:[0-9]+ | awk -F ":" '{print $2}'`
    
fi
# ensure we have a legit port before continuing
numberregex='^[0-9]+$'
if ! [[ $port =~ $numberregex ]] ; then
    echo "ERROR: bad port: $port!"
    exit 1
fi

# update generated behat.yml and config.php files with the determined port - replacing default port 8000
sed -i -e s/localhost:8000/localhost:$port/g $behatconf
sed -i -e s/localhost:8000/localhost:$port/g $WORKSPACE/config.php

# ensure selenium server is running
if ! [[ `ps aux | grep "[s]elenium-server-standalone"` ]]
then
	currentdisplay=$DISPLAY
	export DISPLAY=:10

	# we want to run selenium headless on a different display - this allows for that ;)
	echo "Starting Xvfb ..."
	Xvfb :10 -ac > /dev/null 2>&1 & echo $!

	echo "Starting Selenium ..."
	nohup java -jar $HOME/elearning/selenium-server-standalone-2.39.0.jar > /dev/null 2>&1 & echo $!

	export DISPLAY=$currentdisplay

fi

echo "RUNNING BEHAT TESTS"
#vendor/bin/behat --tags ~@javascript --config $behatconf  # disable js tests
vendor/bin/behat --config $behatconf # all tests
