#!/bin/sh

set -eux

swift package generate-xcodeproj
jazzy \
    --author "Adam Fowler" \
    --author_url https://github.com/adam-fowler \
    --github_url https://github.com/adam-fowler/xml-encoder

git checkout gh-pages
rm -rf docs/current
mv docs/ current/
mkdir docs
mv current/ docs/
git add --all docs
git commit -m "Publish latest docs"
git push
git checkout master

