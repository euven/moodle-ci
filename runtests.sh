#!/bin/bash
ls /var/lib/go-agent/
nohostkeycheck="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
WORKSPACE=/var/lib/go-agent/pipelines/$GO_PIPELINE_NAME
BUILDNAME=$GO_PIPELINE_NAME-$GO_PIPELINE_COUNTER

##
## spin up cloud instance
##
echo ""
echo "########## Spawn cloud instance"
echo ""

source $HOME/moodle-ci/config.sh
python $HOME/moodle-ci/spinup.py $BUILDNAME  # this will write an ip to a file in /tmp
retval=$?
if [ ! $retval -eq 0 ]; then
    echo "Cloud instance creation failed :("
    exit 1
fi

# add a trap here to clean up the cloud if anything goes wrang from now on
trap "cleanup" SIGHUP SIGINT SIGTERM SIGQUIT EXIT
cleanup() {

    # clean the cloud!
    echo 'clean clean cloud!'
    python $HOME/moodle-ci/spindown.py $BUILDNAME

    # clean the workspace, as we need to conserve space
    rm -rf $WORKSPACE

    rm /tmp/$BUILDNAME
}

if [ ! -f /tmp/$BUILDNAME ]; then
    echo "could not find cloud instance for this job..."
    exit 1
fi

cloudip=`cat /tmp/$BUILDNAME`
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
echo ""
echo "########## Prepare cloud instance"
echo ""

#first, fix the hostname
ssh $nohostkeycheck ubuntu@$cloudip "echo \"127.0.0.1 \`hostname\`\" | sudo tee -a /etc/hosts" > /dev/null 2>&1

#move postgres to ram
ssh $nohostkeycheck ubuntu@$cloudip "sudo cp -a /var/lib/postgresql /mnt/ramdisk/. && sudo service postgresql start"

#move firefox to ram
ssh $nohostkeycheck ubuntu@$cloudip "sudo rm /usr/bin/firefox && sudo cp -a /usr/lib/firefox /mnt/ramdisk/. && sudo ln -s /mnt/ramdisk/firefox/firefox.sh /usr/bin/firefox"

#code
rsync -e "ssh $nohostkeycheck" -az --exclude '.git' $WORKSPACE/ ubuntu@$cloudip:/mnt/ramdisk/code

## todo: put the files copies below in for loop!
#lint checker
scp $nohostkeycheck $HOME/moodle-ci/lintcheckercloud.sh ubuntu@$cloudip:

#behat scripts
scp $nohostkeycheck $HOME/moodle-ci/behatcloud.sh ubuntu@$cloudip:
scp $nohostkeycheck $HOME/moodle-ci/testbehatfeature.sh ubuntu@$cloudip:

#phpunit script
scp $nohostkeycheck $HOME/moodle-ci/phpunitcloud.sh ubuntu@$cloudip:
scp $nohostkeycheck $HOME/moodle-ci/testphpunitsuite.sh ubuntu@$cloudip:

#moodle config
scp $nohostkeycheck $HOME/moodle-ci/configcloud.php ubuntu@$cloudip:config.php

#chromedriver
#scp $nohostkeycheck $HOME/moodle-ci/chromedriver ubuntu@$cloudip:

#selenium server
scp $nohostkeycheck $HOME/moodle-ci/selenium-server-standalone-$SELENIUM_VERSION.jar ubuntu@$cloudip:selenium-server-standalone.jar

#composer cache, so we don't need to download all the packages every time (behat-relevant)
if [ -f $HOME/.composer ]; then
    scp -r $nohostkeycheck $HOME/.composer ubuntu@$cloudip
fi

#create and copy env file
export | grep GO_ >> $WORKSPACE/envrc
export | grep GITHUB >> $WORKSPACE/envrc
scp $nohostkeycheck $WORKSPACE/envrc ubuntu@$cloudip:


##
## Lint!
##
echo ""
echo "########## Check syntax"
echo ""

if [[ $* == *lint* ]]; then
    ssh $nohostkeycheck ubuntu@$cloudip "bash lintcheckercloud.sh"
    if [[ $? > 0 ]]; then
        exit 1
    fi
fi

##
## Run phpunit tests
##
echo ""
echo "########## Run PHPUnit"
echo ""

if [[ $* == *phpunit* ]]; then
    ssh $nohostkeycheck ubuntu@$cloudip "bash phpunitcloud.sh"
    if [[ $? > 0 ]]; then
        exit 1
    fi
fi

##
## Run behat tests
##
echo ""
echo "########## Run Behat"
echo ""

if [[ $* == *behat* ]]; then
    ssh $nohostkeycheck ubuntu@$cloudip "bash behatcloud.sh"
    if [[ $? > 0 ]]; then
        exit 1
    fi
fi

# sync back any composer cache updates (behat-relevant)
if (ssh $nohostkeycheck ubuntu@$cloudip [ -d .composer ]); then
	rsync -e "ssh $nohostkeycheck" -a --delete ubuntu@$cloudip:.composer/ $HOME/.composer
fi
