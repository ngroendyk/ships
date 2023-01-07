#!/bin/bash
# Purpose: start mysql server and install redmine/seed data.

service mysql start
service mysql status

# It appears these dir's have mis-configured perms, preventing us from connecting. This
# should get us going.
chmod 755 /var/lib/mysql
chmod 755 /run/mysqld

apt-get -y install redmine redmine-mysql

service mysql stop
