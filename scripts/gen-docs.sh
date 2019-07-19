#!/bin/sh

set -eux

swift package generate-xcodeproj
jazzy \
    --clean \
    --author "Adam Fowler" \
    --author_url https://github.com/adam-fowler \
    --github_url https://github.com/adam-fowler/xml-encoder \
    --copyright "© 2019 Adam Fowler" \
    --xcodebuild-arguments -project,XMLEncoder.xcodeproj,-scheme,XMLEncoder-Package

# stash everything that isn't in docs
git stash push -- ":(exclude)docs"

git checkout gh-pages
# copy contents of docs to docs/current replacing the ones that are already there
rm -rf docs/current
mv docs/ current/
mkdir docs
mv current/ docs/
# commit
git add --all docs
git commit -m "Publish latest docs"
git push
# return to master branch
git checkout master
git stash pop
