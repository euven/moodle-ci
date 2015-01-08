#!/bin/bash
JENKINSHOME=/var/lib/jenkins
mirrors='moodle-r2.mirror totara.mirror'
for mirror in $mirrors
do
    echo "`date` - UPDATING MIRROR $mirror"
    cd $JENKINSHOME/moodle-ci/gitcaches/$mirror && git fetch && git remote prune origin
done
