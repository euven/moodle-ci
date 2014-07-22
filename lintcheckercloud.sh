#!/bin/bash

WORKSPACE=code

echo "CHECKING FOR SYNTAX ERRORS"
#find $WORKSPACE -path $WORKSPACE/vendor -prune -o -type f -name '*.php' -print0 | xargs -0L1 php -l

if [ -e $WORKSPACE/linterrors ]; then
    #remove old linterror file
    rm $WORKSPACE/linterrors
fi

#find $WORKSPACE -path $WORKSPACE/vendor -prune -o -type f -name '*.php' -print0 | while read -d $'\0' file
#do
#    php -l "$file" 2>> $WORKSPACE/linterrors # run linter on file
#done

find $WORKSPACE -path $WORKSPACE/vendor -prune -o -type f -name '*.php' | parallel php -l "{}" 2>> $WORKSPACE/linterrors

if [ -s $WORKSPACE/linterrors ]; then  # check the size here, as -e doesn't play nicely
    echo "SYNTAX ERRORS FOUND:"
    cat $WORKSPACE/linterrors
    exit 1
fi

