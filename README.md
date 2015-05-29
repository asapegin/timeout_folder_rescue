# timeout_folder_rescue

<h3>NO GUARANTEE: use it "as is", without warranties or conditions of any kind.</h3>

<h3>Description</h3>

Bash script, that copies contents of source folder to the destination folder file by file. If copying process for single file hangs for more than 10 seconds, or returns input/output error, script skips this file and logs its name. If destination file already exists, script skips file without logging its name. Folder structure is recreated according to source tree, however, no files or folders are deleted or overwritten in destination.

<h3>Example use case</h3>

I have an encrypted drive, which seems to be failing. If I try to copy files from the mounted encrypted volume, some files are copied just well, but for some other files copy process lasts forever. E.g., Midnight Commander shows that copy is "stalled". Probably because this is encrypted volume, sometimes no I/O error is reported. Of course, one could skip such files manually, but since the drive contains a lot of files, this takes forever as well. This script does it automatically.

<h3>Hint</h3>

In most cases, you do not need this script. Usually, 'cp -v -r -p -n -d source/. destination/' will do the trick for you (please read cp man for details on parameters). However, cp does not show any progress.

Alternatively, you could you rsync with timeout: rsync -vruzlpEXog --progress --timeout=10 source/ destination/

After cp or rsync with timeout, you could run rsync without timeout to try to read problematic files, e.g. 'rsync -vruzlpEXog --progress source/ destination/'. Please also read rsync man for details on parameters.

Differnt to cp, this script reports the speed of copy process (thanks to dd), but for each chunks of file only, not for the whole file or folder. 

Different to rsync, it immediately stops file copy after first I/O error.

Modifying the timeout, blocksize and count, you could set a minimal speed for file copy. E.g., with timeout of 10 seconds, 4096 blocksize and 256 count, script will skip all files, that could not be copied faster than 1 Mb / 10 seconds, i.e. ~ 100Kbyte/s.

<h3>How script works in more details</h3>

1. Script builds a tree for source folder and iterates for each line in the 'tree' output.
2. If the path to file does not exist in destination, it will be created.
4. Folder attributes and ownership information are copied as well (with 10 seconds timeout).
5. If file already exists, nothing is done, script skips the file
6. If the file does not exist, script tries to copy it chunk by chunk with dd; blocksize and count are specified in the code (e.g., by 1Mb = 4096 blocksize x 256 count). For example, if file size is 10Mb, dd will be runned 10 times.
7. Each dd operation has a timeout of 10 seconds. I.e., dd has 10 seconds to copy each 1Mb chunk.
8. If any of dd operation for specific file is killed due to timeout, or dd returns input/output error, script deletes destination file, logs an error and skips the file.
9. If file was copied without an error, script copies file attributes and ownership (with 10 seconds timeout).

<h3>Usage</h3>

$ sudo copy.sh absolute_path_to_source_folder absolute_path_to_destination_folder log_file

(sudo could be needed to preserve ownership and/or attributes)
