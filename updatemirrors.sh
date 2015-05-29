#!/bin/bash
# script for updating local git mirrors (caches)
# these mirrors are checked by jenkins when triggering jobs, instead of the actual upstream repos (prevents high traffic, etc.)

JENKINSHOME=/var/lib/jenkins
mirrors='moodle-r2.mirror totara.mirror'
for mirror in $mirrors
do
    echo "`date` - UPDATING MIRROR $mirror"
    cd $JENKINSHOME/moodle-ci/gitcaches/$mirror && git fetch && git remote prune origin
done
