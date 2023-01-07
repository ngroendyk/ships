#!/bin/bash
# Purpose: start mysql server and seed data.

service mysql start
service mysql status

echo "$1" | mysql

service mysql stop
