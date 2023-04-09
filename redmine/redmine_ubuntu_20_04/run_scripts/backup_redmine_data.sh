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
	exit 1
fi

# 2. wipe/create a scratch dir for packaging the backup data.
if [ -d "$scratch_path" ]; then
	echo "Wiping old scratch path: $scratch_path"
	rm -rf "$scratch_path"
fi

# 3. DUMP the SQL database
mkdir "$scratch_path"
cd "$scratch_path"
echo "Saving database to file..."
mysqldump redmine_default > "$dbase_filename"
tar -czf "$dbase_filename_zipped" "$dbase_filename"  # tar/zip the sql dump
rm "$dbase_filename"  # Wipe untar'd-zipped snapshot file.
echo "  Done!"

# 4. Check for attachments
pushd "$attachment_dir" > /dev/null
filecnt=`ls -1a |wc -l`  # lists files 1-per-line, wc counts lines (incl ., ..)
if [ "$filecnt" -gt "2" ]; then  # convert strs to ints. do arith compare
	# We have files to zip up!
	echo "Found Attachments. Saving..."

	mkdir "${scratch_path}/attached_files"
	# We copy data, rather than zip-in-place since redmine is still running (Snapshot)
	rsync -a "$attachment_dir" "${scratch_path}/attached_files"

	# Now create a tarball of the attachments.
	popd > /dev/null
	tar -czf "$attachment_filename_zipped" -C "${scratch_path}/attached_files/files" . 
	rm -rf "${scratch_path}/attached_files"  # Done with this temp dir
	echo "  Done!"
else
	popd > /dev/null
fi

# 5. Package files in ${scrath} path
echo "Packaging backups..."
tar -czf "$backup_zipfile" *

# 6. Copy the new backup_zipfile to persisted directory, but dont overwrite current persisted data.
#    (We want to make sure the data gets there first, and is in good condition before we wipe out
#     old-seed data. This handles cases where the server/VM/docker dies whilst mid-backup. This will
#     guarentee that at any given time 1 or more sets of data will be valid (either the old one,
#     the old & new, or the new". So at least we won't loose everything)
cp "$backup_zipfile" "${backup_datadir}/${backup_zipfile}.new_and_valid"
sync

# 7. We now know new data got there. Lets overwite the backup file that we normally use.
if [ -f "$backup_datafile" ]; then
	rm "$backup_datafile"
fi
cp "${backup_datadir}/${backup_zipfile}.new_and_valid" "$backup_datafile"
sync

# 8. remove the second backup.
rm "${backup_datadir}/${backup_zipfile}.new_and_valid"
sync

# 9. Done!
echo "  Done!"

