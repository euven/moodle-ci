#!/bin/bash
# this script ensures all automitically-created jenkins jobs are up to date
JENKINSHOME=/var/lib/jenkins

configs='git-config-moodle.yaml git-config-totara.yaml'

for conffile in $configs
do
    # make/update jenkins jobs
    echo "`date` - UPDATE JOBS FOR $conffile"
    /usr/local/bin/jenkins-makejobs-git $JENKINSHOME/moodle-ci/$conffile
done
