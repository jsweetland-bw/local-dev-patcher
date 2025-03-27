#!/bin/bash

# set default output verbosity
export quiet_output=0

# print the script usage
function print_usage() {
    echo "Usage: ${0} [-r repo_dirname] [-d dev_path] [-s patch_path_suffix] [-qh]"
    echo
    echo "Optional parameters:"
    echo "  -r repo_dirname: the name of the repo to patch; if omitted, the current path is used to determine the repo"
    echo "  -d dev_path: the path to the dev directory, defaults to ${default_dev_path}"
    echo "  -s patch_path_suffix: the suffix to append to the repo path, defaults to ${default_patch_path_suffix}"
    echo "  -q: quiet output, show fewer messages"
    echo "  -h: print this help message"
    echo
    echo "Example: ${0} -r insights-alerting"
}

# parse command line parameters
while getopts "r:d:s:qh" opt; do
    case ${opt} in
        r)  repo_dirname=${OPTARG}
            ;;
        d)  dev_path=${OPTARG}
            ;;
        s)  patch_path_suffix=${OPTARG}
            ;;
        q)  quiet_output=1
            ;;
        h)  
            print_usage
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
import_source "${script_path}/console-output.sh" ${quiet_output}
import_source "${script_path}/file-operations.sh" ${quiet_output}
import_source "${script_path}/default-values.sh" ${quiet_output}

# set defaults
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
console_output "INFO" "$(print_var repo_dirname)"
console_output "INFO" "$(print_var repo_path)"

# configure and announce the patch path
patch_path="${repo_path}${patch_path_suffix}"
console_output "INFO" "$(print_var patch_path)"

# output spacing
console_output "INFO" ""

# check the patch path
console_output_nobreak "INFO" "checking paths ... "
if [ ! -d "${patch_path}" ]; then
    console_output "INFO" "ERROR"
    console_output "ERROR" "path does not exist: ${patch_path}"
    exit 1
fi
console_output "INFO" "ok"
console_output "INFO" ""

# find and print the files in the patch path
file_count=0
console_output "INFO" "patch files:"
for patch_file in $(find_files "${patch_path}"); do
    console_output_nobreak "INFO" "  - "
    console_output "PRIORITY" "${patch_file}"
    ((file_count++))
done

console_output "INFO" ""
console_output "INFO" "total files: ${file_count}"
