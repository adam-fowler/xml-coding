#!/bin/sh

set -eux

swift package generate-xcodeproj
jazzy \
    --output . \
    --author "Adam Fowler" \
    --author_url https://github.com/adam-fowler \
    --github_url https://github.com/adam-fowler/xml-encoder \
    --module "XML Encoder"
