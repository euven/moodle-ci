#!/bin/bash

source $HOME/config.sh

echo "CHECKING FOR SYNTAX ERRORS..."

find $CODEHOME -path $CODEHOME/vendor -prune -o -type f -name '*.php' | parallel php -l "{}" 2>> /tmp/linterrors | grep -v "^No syntax errors detected"

if [ -s /tmp/linterrors ]; then  # check the size here, as -e doesn't play nicely
    echo "SYNTAX ERRORS FOUND:"
    cat /tmp/linterrors
    exit 1
else
    echo "No syntax errors found :)"
fi

