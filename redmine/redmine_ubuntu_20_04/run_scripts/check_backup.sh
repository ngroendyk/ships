#!/bin/bash
# Purpose: Take a snapshot of the redmine data/attachments and persist to
#          docker's persisted workspace directory.

# 0. Source the common-script, to pull in script vars, ect.

active_script="YES"  # Set this so we can use the common-script properly.
source /assets/run_scripts/redmine_common.sh


# 1. Check for workspace
if [ ! -d "$backup_datadir" ]; then
	echo "ERROR! Can't backup redmine data! No persistable workspace directory!!!"
	echo " If you actually want to keep this data ensure you start docker with a"
	echo " mounted volume (so we can save to that directory and its contents persist"
	echo " event after the container dies). e.g.: docker run -v some_hostside_location:/workspace"
	echo " backupdatadir: >${backup_datadir}<"
	exit 1
fi

#2. check if the build went through ok or now. add to writeout file
tstamp=`date`
echo "$tstamp" > "${backup_datadir}/BACKUP_INFO.txt"
if [ $1 -eq 0 ]; then
	echo "SUCCESS" >> "${backup_datadir}/BACKUP_INFO.txt" 
else
	echo "FAILED" >> "${backup_datadir}/BACKUP_INFO.txt" 
fi
sync

# 9. Done!
echo "  Done!"

