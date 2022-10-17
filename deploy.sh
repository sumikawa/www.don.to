#!/bin/bash
PATH="$PATH":/usr/local/bin
cd /var/middleman
bundle config set frozen 'false'
bundle config set path 'vendor/bundle'
bundle install --binstubs vendor/bin
bundle exec middleman build > build.log
