#!/bin/bash

echo "Deploying updates to GitHub ..."

# Build the project
hugo -t harbor

# Go to public folder and add changes to git
cd public
git add .

# commit changes
msg="Rebuilding site `date '+%Y-%m-%d %H:%M:%S'`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git commit -m "$msg"
# Push source and build repos.
git push origin master

# Come Back up to the Project Root
cd ..

# Commit source repository changes
git add .
git commit -m "$msg"
git push
