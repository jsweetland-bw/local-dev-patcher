#!/bin/bash# set default output verbosity
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

# determine the script path
script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# import functions
import_source "${script_path}/utils.sh"
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

# handle missing required parameters
if [ "${file_to_update}" = "" ]; then
    console_output "ERROR" "no file specified, run with -h for more information"
    exit 1
fi

# make sure the specified file exists
if [ ! -f "${file_to_update}" ]; then
    console_output "ERROR" "file not found: ${file_to_update}"
    exit 1
fi

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

# announce the repo name and path
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

console_output "INFO" "ok"

# output spacing
console_output "INFO" ""

# determine the child path for the file to update
file_to_update_full_path=$(realpath "${file_to_update}")
file_to_update_child_path=$(echo "${file_to_update_full_path}" | sed "s|${repo_path}/||")
console_output "INFO" $(print_var file_to_update_child_path)

# output spacing
console_output "INFO" ""

# calculate md5sums
file_to_update_md5sum=$(calc_md5sum "${file_to_update_full_path}")
patch_file_md5sum=$(calc_md5sum "${patch_path}/${file_to_update_child_path}")

# announce the proposed update
console_output "PRIORITY" "proposed update:"
console_output "PRIORITY" "  from: ${file_to_update_md5sum} ${file_to_update_full_path}"
console_output "PRIORITY" "    to: ${patch_file_md5sum} ${patch_path}/${file_to_update_child_path}"

# output spacing
console_output "INFO"

# prompt for the user to proceed with the updating the patch file
read -p "continue (y/N)? " choice
case "$choice" in 
  y|Y ) console_output "PRIORITY" ""
        ;;
  * )   console_output "PRIORITY" "aborting, nothing will be updated"
        exit 0
        ;;
esac

# make sure the patch file path exists
file_to_update_just_child_path=$(dirname "${file_to_update_child_path}")
if [ ! -d "${patch_path}/${file_to_update_just_child_path}" ]; then
    mkdir -p "${patch_path}/${file_to_update_just_child_path}"
fi

# copy the file to the patch path
console_output_nobreak "PRIORITY" "copying "
if [ ${quiet_output} -eq 0 ]; then
    cp -v ${file_to_update_full_path} ${patch_path}/${file_to_update_child_path}
else
    console_output "PRIORITY" "..."
fi

console_output "PRIORITY"
console_output "PRIORITY" "updated"

# exit normally
exit 0
