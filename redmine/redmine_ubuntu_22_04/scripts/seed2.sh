#!/bin/bash
# Purpose: start mysql server and seed data.

service mysql start
service mysql status

cd /usr/share/redmine
bundle exec rake generate_secret_token
bundle exec rake db:migrate RAILS_ENV="production"

service mysql stop
