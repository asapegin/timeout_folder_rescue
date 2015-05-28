# timeout_folder_rescue

<h2>NO GUARANTEE</h2> 
<h3>USE IT "AS IS", WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND</h3>

<h3>Description</h3>

Bash script, that copies contents of source folder to the destination folder file by file. If copying process for single file hangs for more than 10 seconds, script skips this file and logs its name. If destination file already exists, script skips file without logging its name. Folder structure is recreated according to source tree, however, no files or folders are deleted or overwritten in destination.

<h3>Example use case</h3>

I have an encrypted drive, which seems to be failing. If I try to copy files from the mounted encrypted volume, some files are copied just well, but for some other files copy process lasts forever. E.g., Midnight Commander shows that copy is "stalled". Probably because this is encrypted volume, no I/O error is reported. Of course, one could skip such files manually, but since the drive contains a lot of files, this takes forever as well.

<h3>How script works in more details</h3>

1. Script builds a tree for source folder and iterates for each line in the 'tree' output.
2. If the path to file does not exist in destination, it will be created.
4. Folder attributes and ownership information is copied as well (with 10 seconds timeout).
5. If file already exists, nothing is done, script skips the file
6. If the file does not exist, script creates file and copies file attributes and ownership (with 10 seconds timeout)
7. Then script tries to copy it chunk by chunk with dd; blocksize and count are specified in the code (e.g., by 1Mb = 4096 blocksize x 256 count). For example, if file size is 10Mb, dd will be runned 10 times.
8. Each dd operation has a timeout of 10 seconds. I.e., dd has 10 seconds to copy each 1Mb chunk.
9. If any of dd operation for specific file is killed due to timeout, script deletes destination file, logs an error and skips the file.

<h3>Usage</h3>

$ sudo copy.sh absolute_path_to_source_folder absolute_path_to_destination_folder log_file

(sudo could be needed to preserve ownership and/or attributes)
