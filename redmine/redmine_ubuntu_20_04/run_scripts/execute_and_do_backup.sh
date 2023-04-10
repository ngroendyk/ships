#!/bin/bash
/assets/run_scripts/backup_redmine_data.sh
result="$?"
/assets/run_scripts/check_backup.sh "$result"

