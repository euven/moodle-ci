#!/bin/bash

source $HOME/moodle-ci/config.sh

# clean the workspace to conserve space
rm -rf $WORKSPACE/*

# kill the cloud server instance
python $HOME/moodle-ci/spindown.py $BUILD_TAG

