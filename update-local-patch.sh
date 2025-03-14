#!/bin/bash

# determine the script path
script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# import a source file
function import_source() {
    local -r import_path="${1}"
    shift
    
    echo -n "importing ${import_path} ... "
    if [ ! -f "${import_path}" ]; then
        echo "ERROR"
        echo "ERROR: file not found: ${import_path}" > /dev/stderr
        exit 1
    else
        source ${import_path}
        echo "ok"
    fi
}

# import functions
import_source "${script_path}/utils.sh"
import_source "${script_path}/default-values.sh"

# set defaults
dev_path=${default_dev_path}
patch_path_suffix=${default_patch_path_suffix}

# output spacing
echo

# print the script usage
function print_usage() {
    echo "Usage: ${0} -f file_to_update [-r repo_dirname] [-d dev_path] [-p patch_path] [-s patch_path_suffix]"
    echo
    echo "Required parameters:"
    echo "  -f file_to_update: the file to update"
    echo
    echo "Optional parameters:"
    echo "  -r repo_dirname: the name of the repo to patch; if omitted, the current path is used to determine the repo"
    echo "  -d dev_path: the path to the dev directory, defaults to ${default_dev_path}"
    echo "  -p patch_path: the path to the patch files, defaults to repo_path + patch_path_suffix"
    echo "  -s patch_path_suffix: the suffix to append to the repo path, defaults to ${default_patch_path_suffix}"
    echo "  -h: print this help message"
    echo
    echo "Example: ${0} -r insights-alerting"
}

# parse command line parameters
while getopts "r:f:d:p:s:h" opt; do
    case ${opt} in
        r)  repo_dirname=${OPTARG}
            ;;
        f)  file_to_update=${OPTARG}
            ;;
        d)  dev_path=${OPTARG}
            ;;
        p)  patch_dirname=${OPTARG}
            ;;
        s)  patch_path_suffix=${OPTARG}
            ;;
        h)  print_usage
            exit 0
            ;;
        ?)  echo "Invalid option: -${OPTARG}" >&2
            exit 1
            ;;
    esac
done

# handle missing required parameters
if [ "${file_to_update}" = "" ]; then
    echo "ERROR: no file specified, run with -h for more information" > /dev/stderr
    exit 1
fi

# make sure the specified file exists
if [ ! -f "${file_to_update}" ]; then
    echo "ERROR: file not found: ${file_to_update}" > /dev/stderr
    exit 1
fi

# determine the announce the repo name and path
if [ "${repo_dirname}" != "" ]; then
    # if the repo name is specified, use it
    repo_path="${dev_path}/${repo_dirname}"
else
    # otherwise, use the current path to determine the repo
    echo -n "repo_dirname was not specified with -r, using the current path to determine the repo ... "

    current_path="$(pwd)"
    dev_subpath=$(echo "${current_path}" | sed "s|${HOME}/Dev/||")

    if [ "${dev_subpath}" = "${current_path}" ]; then
        # the current path is not in the dev path
        echo "ERROR"
        echo "ERROR: repo_dirname was not specified and the current path is not within the dev path (dev_path: ${dev_path})" > /dev/stderr
        exit 1
    fi

    repo_dirname=$(echo "${dev_subpath}" | cut -d "/" -f 1)
    repo_path="${dev_path}/${repo_dirname}"

    echo "ok"

    # output spacing
    echo
fi

# announce the repo name and path
print_var repo_dirname
print_var repo_path

# calculate and announce the patch path
if [ "${patch_path}" = "" ]; then
    patch_path=${repo_path}${patch_path_suffix}
fi
print_var patch_path

# output spacing
echo

# verify the paths exist
echo -n "checking paths ... "

check_path "${repo_path}"
check_path "${patch_path}"

echo "ok"

# output spacing
echo

# determine the child path for the file to update
file_to_update_full_path=$(realpath "${file_to_update}")
file_to_update_child_path=$(echo "${file_to_update_full_path}" | sed "s|${repo_path}/||")
print_var file_to_update_child_path

# output spacing
echo

# calculate md5sums
file_to_update_md5sum=$(calc_md5sum "${file_to_update_full_path}")
patch_file_md5sum=$(calc_md5sum "${patch_path}/${file_to_update_child_path}")

# announce the proposed update
echo "proposed update:"
echo "  from: ${file_to_update_md5sum} ${file_to_update_full_path}"
echo "    to: ${patch_file_md5sum} ${patch_path}/${file_to_update_child_path}"

# output spacing
echo

# prompt for the user to proceed with the updating the patch file
read -p "continue (y/N)? " choice
case "$choice" in 
  y|Y ) echo
        ;;
  * )   echo "aborting, nothing will be updated"
        exit 0
        ;;
esac

# make sure the patch file path exists
file_to_update_just_child_path=$(dirname "${file_to_update_child_path}")
if [ ! -d "${patch_path}/${file_to_update_just_child_path}" ]; then
    mkdir -p "${patch_path}/${file_to_update_just_child_path}"
fi

# copy the file to the patch path
echo -n "copying "
cp -v ${file_to_update_full_path} ${patch_path}/${file_to_update_child_path}

# output spacing
echo

echo "updated"

# exit normally
exit 0
