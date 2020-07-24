#!/bin/bash

set -x
set -e

if [ ! -z "$TRAVIS_TAG" ]
then
    sed -i 's/__tag__ = ""/__tag__ = "'${TRAVIS_TAG}'"/g' setup.py
fi

if [ ! -z "$TRAVIS_BUILD_NUMBER" ]
then
    sed -i 's/__build__ = 0/__build__ = '${TRAVIS_BUILD_NUMBER}'/g' setup.py
fi

if [ ! -z "$TRAVIS_COMMIT" ]
then
    sed -i 's/__commit__ = \"00000000\"/__commit__ = \"'${TRAVIS_COMMIT::6}'\"/g' setup.py
fi
