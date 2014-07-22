#!/bin/bash

nohostkeycheck="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

##
## spin up cloud instance
##
source $HOME/elearning/cloudrc
python $HOME/elearning/spinup.py $BUILD_TAG  # this will write an ip to a file in /tmp
retval=$?
if [ ! $retval -eq 0 ]; then
    echo "Cloud instance creation failed :("
    exit 1
fi

if [ ! -f /tmp/$BUILD_TAG ]; then
    echo "could not find cloud instance for this job..."
    exit 1
fi

cloudip=`cat /tmp/$BUILD_TAG`
# wait for ssh access - sometimes it takes a while for the floating ip to be assigned to the cloud instance
sshtrycount=0
while [ 1 ]; do
    if [[ $sshtrycount -gt 100 ]]; then
        echo "Could not connect to cloud instance..."
        exit 1
    fi

    ssh $nohostkeycheck ubuntu@$cloudip ls > /dev/null 2>&1
    if [[ $? -gt 0 ]]; then
        echo "Waiting for ssh access..."
        let "sshtrycount=sshtrycount+1"
        sleep 5
    else
        break
    fi
done


##
## prepare cloud instance with necessary files, etc.
##
#move postgres to ram
ssh $nohostkeycheck ubuntu@$cloudip "sudo cp -a /var/lib/postgresql /mnt/ramdisk/. && sudo service postgresql start"

#code
cd $WORKSPACE && git archive --format=zip --output=code.zip HEAD && scp $nohostkeycheck code.zip ubuntu@$cloudip:
ssh $nohostkeycheck ubuntu@$cloudip "unzip -q code.zip -d code"

## todo: put the files copies below in for loop!
#lint checker
scp $nohostkeycheck $HOME/elearning/lintcheckercloud.sh ubuntu@$cloudip:

#behat scripts
scp $nohostkeycheck $HOME/elearning/behatcloud.sh ubuntu@$cloudip:
scp $nohostkeycheck $HOME/elearning/testbehatfeature.sh ubuntu@$cloudip:

#phpunit script
scp $nohostkeycheck $HOME/elearning/phpunitcloud.sh ubuntu@$cloudip:

#moodle config
scp $nohostkeycheck $HOME/elearning/configcloud.php ubuntu@$cloudip:config.php

#phantomjs - NOTE: USING 1.9.2, as 1.9.7 is too slow
#scp $nohostkeycheck $HOME/elearning/phantomjs ubuntu@$cloudip:

#selenium server built from latest code
scp $nohostkeycheck $HOME/elearning/selenium-server-built-20140729.jar ubuntu@$cloudip:selenium-server-standalone.jar

#create and copy env file
export | grep BUILD_ >> $WORKSPACE/envrc
export | grep JOB_ >> $WORKSPACE/envrc
scp $nohostkeycheck $WORKSPACE/envrc ubuntu@$cloudip:


##
## Lint!
##
if [[ $* == *lint* ]]; then
    ssh $nohostkeycheck ubuntu@$cloudip "bash lintcheckercloud.sh"
    if [[ $? > 0 ]]; then
        exit 1
    fi
fi

##
## Run behat tests
##
if [[ $* == *behat* ]]; then
    ssh $nohostkeycheck ubuntu@$cloudip "bash behatcloud.sh"
    if [[ $? > 0 ]]; then
        exit 1
    fi
fi

##
## Run phpunit tests
##
if [[ $* == *phpunit* ]]; then
    ssh $nohostkeycheck ubuntu@$cloudip "bash phpunitcloud.sh"
    if [[ $? > 0 ]]; then
        exit 1
    fi
fi

#traps don't work yet: https://issues.jenkins-ci.org/browse/JENKINS-17116
#trap "cleanup" SIGHUP SIGINT SIGTERM SIGQUIT EXIT

# cleanup
cleanup() {
    # clean the cloud!
    python $HOME/elearning/spindown.py $BUILD_TAG
}
