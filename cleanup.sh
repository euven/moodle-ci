#!/bin/bash

source $HOME/elearning/config.sh

# clean the workspace to conserve space
rm -rf $WORKSPACE/*

# kill the cloud server instance
python $HOME/elearning/spindown.py $BUILD_TAG

