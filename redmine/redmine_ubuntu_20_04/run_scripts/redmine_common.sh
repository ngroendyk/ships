#!/bin/bash
# Purpose: THIS SCRIPT IS MEANT TO BE SOURCED by other scripts. Not to be
# ran be ran manually. It's purpose is to provide common vars used by
# the redmine management scripts.

if [[ "$active_script" != "YES" ]]; then
	echo "Do not run this script by hand! It is meant to be used by other scripts!"
	exit 1
fi

# Set vars

# The name of the meta-tarball which contains the sql tarball and attachments tarball
backup_datafile="/workspace/backup_redmine_data.tar.gz"

## Computed from datafile.
backup_datadir=`echo "$backup_datafile"|rev|cut -d'/' -f2-|rev`
backup_zipfile=`echo "$backup_datafile"|rev|cut -d'/' -f1 |rev`
echo "datadir is: ${backup_datadir}"
echo "datafile is: ${backup_zipfile}"

# A writable place in container (not persisted workspace) to do some work.
scratch_path="${HOME}/scratch"

# The name of the SQL dump tarball & untar'd file
dbase_filename_zipped="backup_data.sql.tar.gz"
dbase_filename=`echo "$dbase_filename_zipped" |cut -d'.' -f1-2`

# The name of the attachments tarball
attachment_filename_zipped="backup_attachments.tar.gz"

# The location where the attachments live (For taking a tar, or restoring from a tar...
# This is the location where redmine writes its attachments)
attachment_dir="/var/lib/redmine/default/files"

