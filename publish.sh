#!/bin/bash

echo "=> Build"
hugo

echo "=> Publish"
cd public && git add .
msg="Rebuilding site `date '+%Y-%m-%d %H:%M:%S'`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git commit -m "$msg"
git push origin master
