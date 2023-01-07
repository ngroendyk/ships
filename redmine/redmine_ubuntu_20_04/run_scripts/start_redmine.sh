#!/bin/bash
# Purpose: Seeds redmine data and attachements if any are provided at:
#          "/workspace/backup_redmine_data.tar.gz"
#          Also, starts mysql and apache2 so that redmine can work.
#

# 0. Source the common-script, to pull in script vars, ect.
active_script="YES"  # Set this so we can use the common-script properly.
source redmine_common.sh


# 1. Start SQL
service mysql start

# 2. Check for backup/seed data
if [ -f "${backup_datafile}" ]; then
	# 2.1 Check if data already seeded
	if [ ! -f "${HOME}/db_data_seeded" ]; then
		echo "No previously seeded data."
		# data exists, unzip and seed database and file attachments.
		mkdir "${scratch_path}"
		cd "${scratch_path}"
		cp "${backup_datafile}" "${scratch_path}"
		tar -zxf "${backup_zipfile}"
		# We should now have 1 or 2 files. 1 for dbase, 1 for attachments.
		# unzip them and seed/tar if needed.

		# Check for database file
		if [ -f "$dbase_filename_zipped" ]; then
			echo "Found SQL backup. Re-seeding redmine dbase..."
			tar -zxf "$dbase_filename_zipped"
			# Now seed dbase.
			if [ -f "$dbase_filename" ]; then
				mysql redmine_default < $dbase_filename
				echo "  Done!"
			else
				echo " Error! Can't seed database, couldnt find: $dbase_filename in tar-archive"
			fi
		fi

		# Check for attachments to unzip.
		if [ -f "$attachment_filename_zipped" ]; then
			echo "Found Attachments to restore. Restoring..."
			cd "$attachment_dir"
			cp "${scratch_path}/${attachment_filename_zipped}" "$attachment_dir"
			tar -zxf "$attachment_filename_zipped" .
			rm "$attachment_filename_zipped"
			echo "  Done!"
		fi
		touch "${HOME}/db_data_seeded"  # prevent re-seeding the dbase each time we are called.
	fi
else
	echo "No seed-data, start a fresh redmine instance."
	echo "  NOTE: If you had previous redmine data to load, please place"
	echo "        it in '${backup_datafile}' and restart container with"
	echo "        a mounted volume (eg. -v <some_host_Dir>:/workspace."
	echo "        If this true is a new-instance, remember the default"
	echo "        redmine user/pass is 'admin' and 'admin'."
fi

# 3. start apache2, so that it can use ruby/related launches to start redmine
service apache2 start

# 4. start cron, so our data backs-up
service cron start

# 5. Since we are called via Dockerfile, we need to ensure we dont exit, otherwise container
#   dies. This is a workaround! We should really force our apache/sql daemons to the
#   foreground, and/or monitor their pids... but this will work for now.
# Infact, we we monitored their Pids, and any external actions to indicate a shutdown we
# could then force a final persist of the dbase and just die-out. (could signal a die out
# via the workspace and a 1 second interval poll... food for thought @todo)
while true; do sleep 1000; done

