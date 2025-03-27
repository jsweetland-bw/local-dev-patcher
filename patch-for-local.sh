#!/bin/bash

# set default output verbosity
export quiet_output=0

# determine the relative file name for a file
# 1: the file to patch
# 2: the patch path
# 3: the repo path
function calc_relative_file() {
    local -r given_file="${1}"
    local -r patch_path="${2}"
    local -r repo_path="${3}"

    realpath "${given_file}" | sed "s|${patch_path}/||" | sed "s|${repo_path}/||"
}

# list a file
# 1: the relative file name
# 2: the md5sum of the patch file
# 3: the md5sum of the repo file
function list_file() {
    local -r relative_file="${1}"
    local -r patch_md5="${2}"
    local -r repo_md5="${3}"

    console_output_nobreak "PRIORITY" "  "
    if [ "${patch_md5}" != "${repo_md5}" ]; then
        console_output_nobreak "PRIORITY" "!"
    else
        console_output_nobreak "PRIORITY" " "
    fi
    console_output "PRIORITY" " ${relative_file}"
}

# prompt to continue
function continue_prompt() {
    echo
    read -p "continue (y/N)? " choice
    case "$choice" in 
    y|Y ) echo
            ;;
    * )   echo "aborting, nothing will be copied"
            exit 0
            ;;
    esac
}

# patch a file
# 1: the relative file
# 2: the patch file
# 3: the repo file
function patch_file() {
    local -r relative_file="${1}"
    local -r patch_file="${2}"
    local -r repo_file="${3}"

    local -r patch_md5=$(calc_md5sum "${patch_file}")
    local -r repo_md5=$(calc_md5sum "${repo_file}")

    if [ "${patch_md5}" = "${repo_md5}" ]; then
        file_skip_list="${relative_file} ${file_skip_list}"
    else
        if [ ${quiet_output} -eq 0 ]; then
            cp -v ${patch_file} ${repo_file}
        else
            cp ${patch_file} ${repo_file}
        fi

        ((files_updated++))
    fi
}

# print the script usage
function print_usage() {
    echo "Usage: ${0} [-r repo_dirname] [-f file_to_patch] [-d dev_path] [-p patch_path] [-s patch_path_suffix] [-qh]"
    echo
    echo "Optional parameters:"
    echo "  -r repo_dirname: the name of the repo to patch; if omitted, the current path is used to determine the repo"
    echo "  -f file_to_patch: the file to patch; if omitted, all available files will be patched"
    echo "  -d dev_path: the path to the dev directory, defaults to ${default_dev_path}"
    echo "  -p patch_path: the path to the patch files, defaults to repo_path + patch_path_suffix"
    echo "  -s patch_path_suffix: the suffix to append to the repo path, defaults to ${default_patch_path_suffix}"
    echo "  -q: quiet output, show fewer messages"
    echo "  -h: print this help message"
    echo
    echo "Example: ${0} -r insights-alerting"
}

# parse command line parameters
while getopts "r:f:d:p:s:qh" opt; do
    case ${opt} in
        r)  repo_dirname=${OPTARG}
            ;;
        f)  file_to_patch=${OPTARG}
            ;;
        d)  dev_path=${OPTARG}
            ;;
        p)  patch_dirname=${OPTARG}
            ;;
        s)  patch_path_suffix=${OPTARG}
            ;;
        q)  quiet_output=1
            ;;
        h)  print_usage
            exit 0
            ;;
        ?)  echo "Invalid option: -${OPTARG}" >&2
            exit 1
            ;;
    esac
done

# determine the script path
script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# import functions
source "${script_path}/import.sh"  # silently sourced because it contains the import_source function
import_source "${script_path}/console-output.sh"
import_source "${script_path}/file-operations.sh"
import_source "${script_path}/default-values.sh"

# set defaults if the vars are unset
if [ "${dev_path}" = "" ]; then
    dev_path=${default_dev_path}
fi
if [ "${patch_path_suffix}" = "" ]; then
    patch_path_suffix=${default_patch_path_suffix}
fi

# output spacing
console_output "INFO" ""

# determine the announce the repo name and path
if [ "${repo_dirname}" != "" ]; then
    # if the repo name is specified, use it
    repo_path="${dev_path}/${repo_dirname}"
else
    # otherwise, use the current path to determine the repo
    console_output_nobreak "INFO" "repo_dirname was not specified with -r, using the current path to determine the repo ... "

    current_path="$(pwd)"
    dev_subpath=$(echo "${current_path}" | sed "s|${HOME}/Dev/||")

    if [ "${dev_subpath}" = "${current_path}" ]; then
        # the current path is not in the dev path
        console_output "INFO" "ERROR"
        console_output "ERROR" "repo_dirname was not specified and the current path is not within the dev path (dev_path: ${dev_path})"
        exit 1
    fi

    repo_dirname=$(echo "${dev_subpath}" | cut -d "/" -f 1)
    repo_path="${dev_path}/${repo_dirname}"

    console_output "INFO" "ok"

    # output spacing
    console_output "INFO" ""
fi

# announce the repo directory name and path
console_output "INFO" $(print_var repo_dirname)
console_output "INFO" $(print_var repo_path)

# calculate and announce the patch path
if [ "${patch_path}" = "" ]; then
    patch_path=${repo_path}${patch_path_suffix}
fi
console_output "INFO" $(print_var patch_path)

# output spacing
console_output "INFO" ""

# verify the paths exist
console_output_nobreak "INFO" "checking paths ... "

check_path "${repo_path}"
check_path "${patch_path}"

if [ "${file_to_patch}" != "" ]; then
    check_file "${file_to_patch}"
fi

console_output "INFO" "ok"

# output spacing
console_output "INFO" ""

# indentify and announce the files to patch
files_updated=0
file_skip_list=""
console_output "PRIORITY" "files to be copied to the repo:"
if [ "${file_to_patch}" != "" ]; then
    path_to_file=$(realpath "${file_to_patch}")
    relative_file=$(calc_relative_file "${path_to_file}" "${patch_path}" "${repo_path}")
    patch_file="${patch_path}/${relative_file}"
    repo_file="${repo_path}/${relative_file}"
    
    patch_md5=$(calc_md5sum "${patch_file}")
    repo_md5=$(calc_md5sum "${repo_file}")

    list_file "${relative_file}" "${patch_md5}" "${repo_md5}"

    continue_prompt

    # copy the files to the repo
    console_output "PRIORITY" "copying files ..."
    patch_file "${relative_file}" "${patch_file}" "${repo_file}"
else
    for patch_file in $(find_files "${patch_path}"); do
        relative_file=$(calc_relative_file "${patch_file}" "${patch_path}" "${repo_path}")
        repo_file="${repo_path}/${relative_file}"
        
        patch_md5=$(calc_md5sum "${patch_file}")
        repo_md5=$(calc_md5sum "${repo_file}")

        list_file "${relative_file}" "${patch_md5}" "${repo_md5}"
    done

    continue_prompt

    # copy the files to the repo
    console_output "PRIORITY" "copying files ..."
    for patch_file in $(find_files "${patch_path}"); do
        relative_file=$(calc_relative_file "${patch_file}" "${patch_path}" "${repo_path}")
        repo_file="${repo_path}/${relative_file}"

        patch_file "${relative_file}" "${patch_file}" "${repo_file}"
    done
fi

# announce the files that were skipped
if [ "${file_skip_list}" != "" ]; then
    console_output "INFO" ""
    console_output "INFO" "the folllowing files were skipped because they were already up to date:"
    for skipped_file in $(echo "${file_skip_list}"); do
        console_output "INFO" "  ${skipped_file}"
    done
fi

# announce the results of the patch
console_output "PRIORITY" ""
if [ ${files_updated} -eq 0 ]; then
    console_output "PRIORITY" "no files updated"
else
    console_output "PRIORITY" "${files_updated} file(s) updated"
fi

# exit normally
exit 0
