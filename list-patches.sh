#!/bin/bash

# set default output verbosity
export quiet_output=0

# write console output without a newline
# 1: the type of output
#   PRIORITY
#   INFO
#   ERROR
# 2: the string to print
function console_output_nobreak() {
    local -r output_type="${1}"
    local -r output_string="${2}"

    if [ "${output_type}" = "PRIORITY" ]; then
        echo -ne "${output_string}" > /dev/stdout
    elif [ "${output_type}" = "INFO" ]; then
        if [ ${quiet_output} -eq 0 ]; then
            echo -ne "${output_string}" > /dev/stdout
        fi
    elif [ "${output_type}" = "ERROR" ]; then
        echo -ne "ERROR: ${output_string}" > /dev/stderr
    else
        echo -ne "${output_string}" > /dev/stdout
    fi
}

# write console output with a newline
# 1: the type of output
#   PRIORITY
#   INFO
#   ERROR
# 2: the string to print
function console_output() {
    local -r output_type="${1}"
    local -r output_string="${2}"

    console_output_nobreak "${output_type}" "${output_string}\n"
}

# import a source file
function import_source() {
    local -r import_path="${1}"
    shift
    
    console_output_nobreak "INFO" "importing ${import_path} ... "
    if [ ! -f "${import_path}" ]; then
        console_output "INFO" "ERROR"
        console_output "ERROR" "file not found: ${import_path}"
        exit 1
    else
        source ${import_path}
        console_output "INFO" "ok"
    fi
}

# print the script usage
function print_usage() {
    echo "Usage: ${0} [-r repo_dirname] [-d dev_path] [-s patch_path_suffix] [-qh]"
    echo
    echo "Optional parameters:"
    echo "  -r repo_dirname: the name of the repo to patch; if omitted, the current path is used to determine the repo"
    echo "  -d dev_path: the path to the dev directory, defaults to ${default_dev_path}"
    echo "  -s patch_path_suffix: the suffix to append to the repo path, defaults to ${default_patch_path_suffix}"
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
import_source "${script_path}/utils.sh"
import_source "${script_path}/default-values.sh"

# set defaults for unset values
if [ "${dev_path}" = "" ]; then
    dev_path=${default_dev_path}
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
console_output "INFO" ""

# find and print the patch paths
patches_found=0
console_output "INFO" "available patch paths:"
for dir in $(find ${dev_path} -type d -maxdepth 1 | grep "${repo_path}"); do
    if [ "${dir}" != "${repo_path}" ]; then
        console_output_nobreak "INFO" "  - "
        console_output "PRIORITY" "${dir}"
        ((patches_found++))
    fi
done

console_output "INFO" ""
console_output "INFO" "${patches_found} available patch(es) found"
