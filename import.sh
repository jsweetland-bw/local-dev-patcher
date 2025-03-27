# import a source file
# note: this function uses plain echo statements  to print output instead of
#   the console_output and console_output_nobreak functions because those
#   functions are not available until the associated source file has been
#   imported
# 1: the path to the source file
# 2: whether or not to print the import message
function import_source() {
    local -r import_path="${1}"
    local -r quiet_output="${2}"
    shift

    # make sure quiet_output is set
    if [ "${quiet_output}" = "" ]; then
        quiet_output=0
    fi
    
    if [ ! -f "${import_path}" ]; then
        if [ ${quiet_output} -eq 0 ]; then
            echo "ERROR"
        fi

        echo "ERROR: file not found: ${import_path}" > /dev/stderr
        exit 1
    else
        if [ ${quiet_output} -eq 0 ]; then
            echo -n "importing ${import_path} ... "
        fi

        source ${import_path}

        if [ ${quiet_output} -eq 0 ]; then
            echo "ok"
        fi
    fi
}
