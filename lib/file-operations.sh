# file operations functions

# find the files in a path
function find_files() {
    find ${1} -type f
}

# check if a path exists
function check_path() {
    if [ ! -d "${1}" ]; then
        echo "ERROR"
        echo "ERROR: path does not exist: ${1}" > /dev/stderr
        exit 1
    fi
}

# check if a file exists
function check_file() {
    if [ ! -f "${1}" ]; then
        echo "ERROR"
        echo "ERROR: file does not exist: ${1}" > /dev/stderr
        exit 1
    fi
}

# calculate the md5sum for a file
function calc_md5sum() {
    md5sum ${1} 2>/dev/null | awk '{print $1}'
}
