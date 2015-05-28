#!/bin/bash
### Script that copies contents of the source folder to the destination folder
### If copying process for single file hangs for more than 10 seconds,
### script skips this file and logs its name.
### If destination file already exists,
### script skips file without logging its name.


##
 # Copyright 2015 Andrey Sapegin
 #
 # Licensed under the "Attribution-NonCommercial-ShareAlike" Vizsage
 # Public License (the "License"). You may not use this file except
 # in compliance with the License. Roughly speaking, non-commercial
 # users may share and modify this code, but must give credit and 
 # share improvements. However, for proper details please 
 # read the full License, available at
 #  http://vizsage.com/license/Vizsage-License-BY-NC-SA.html 
 # and the handy reference for understanding the full license at 
 #  http://vizsage.com/license/Vizsage-Deed-BY-NC-SA.html
 #
 # Please contact the author for any other kinds of use.
 #
 # Unless required by applicable law or agreed to in writing, any
 # software distributed under the License is distributed on an 
 # "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
 # either express or implied. See the License for the specific 
 # language governing permissions and limitations under the License.
 #
 ##

# Function copies the source file ($1) to destination ($2)
# by chunks using dd (e.g., by 1 Mb chunks = 256 times of 4096 byte blocks).
# If copy of one chunk takes more than 10 seconds,
# function deletes destination file,
# logs the path to the failed source into $3
# and returns
function copyfile {
    blocksize=4096
    count=256
    sourcefile=$1
    destfile=$2
    log=$3
    blocks_read=0
    # create destination file
    touch $destfile
    timeout 10 chmod --reference="$sourcefile" "$destfile"
    timeout 10 chown --reference="$sourcefile" "$destfile"
    # check the size of source file in bytes
    filesize=$(stat -c%s "$sourcefile")
    # copy until all bytes of file are not copied
    while [ "$((blocks_read*blocksize))" -lt "$filesize" ]
    do
	# copy 4096 bytes to destination file with timeout of 10 seconds, symlinks not followed
	timeout 10 dd if=$sourcefile iflag=nofollow bs=$blocksize count=$count skip=$blocks_read >> $destfile
	# check the status after command is finished
	status=$?
	# if command waws killed by timeout
	if [ "$status" -eq 124 ]
	then
	    # delete destination file
	    rm -f $destfile
	    # log path to the source file into log
	    echo $destfile >> $log
	    # exit function
	    return
	fi
	# update number of bytes copied
	blocks_read=$((blocks_read+count))
    done
}

# Function prints help
function print_help {
    echo "Script copies contents of the source folder to the destination folder"
    echo "If copying process for single file hangs for more than 10 seconds,"
    echo "script skips this file and logs its name. If destination file already exists,"
    echo "script skips file without logging its name."
    echo "Usage:"
    echo "sudo copy.sh <source_folder> <destination_folder> <log_file>"
    echo "(sudo could be needed to preserve attributes and ownership)"
}

### MAIN ###
# currently copies contents of the source folder (NOT FILE) 
# to the destination folder

# print help if number of arguments is not 3 or help was requested
if [[  ($# -ne 3) || ($# == "-h") || ( $# == "--help") ]]
then
    print_help
    exit
fi

#source
# delete the slash at the end of directory path if present
if [ 'echo ${1:-1}'=="/" ]
then
    csource=${1::-1}
else
    csource=$1
fi

#destination
# delete the slash at the end of directory path if present
if [ 'echo ${2:-1}'=="/" ]
then
    cdestination=${2::-1}
else
    cdestination=$2
fi

#logfile
logfile=$3

# go to source folder
currentdir=`pwd`
cd $csource

# create a file tree
filetree="tree.txt"
# find a filename that does not exists in the source folder
while [ -e $csource/$filetree ]
do
    # add .txt to the tree filename until it does not exists in the source
    filetree+=".txt"
done
# create tree and save it to the file
tree -n -a -f -i -o $cdestination/$filetree .

# go back to the currentdir
cd $currentdir

# copy files from tree one by one
while read line
do
    # make the path to the source file, 
    # delete "." in the beginning of the filename (from tree)
    sfile=$csource${line:1}
    # make destination path, 
    # delete "." in the beginning of filename (from tree)
    dfile=$cdestination${line:1}
    # If destination directory NOT exists
    if [ ! -e "$(dirname $dfile)" ]; then
	# create directory
	mkdir $(dirname $dfile)
	timeout 10 chown --reference="$(dirname $sfile)" "$(dirname $dfile)"
	timeout 10 chmod --reference="$(dirname $sfile)" "$(dirname $dfile)"
    fi
    # If destination file NOT exists
    if [ ! -e "$dfile" ]; then
	# if source file is actually a directory, create a directory
	if [ -d "$sfile" ]; then
	    mkdir $dfile
	    timeout 10 chown --reference="$sfile" "$dfile"
	    timeout 10 chmod --reference="$sfile" "$dfile"
        # otherwise copy file
	else
	    # copy file with timeout
	    copyfile $sfile $dfile $logfile
	fi
    fi
done < <(head -n -2 ${cdestination}/${filetree})

# delete the file tree
rm -f $cdestination/$filetree

# Report stats
if [ -e "$logfile" ]
then
    failes=`wc -l "$logfile"`
else
    failes=0
fi

echo "Copy finished. $failes files skipped due to timeout."
