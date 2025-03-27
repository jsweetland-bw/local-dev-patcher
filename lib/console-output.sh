# console output functions

# print a variable name and value
# 1: the variable name
function print_var() {
    local -r variable_name="${1}"

    echo "${variable_name}: ${!variable_name}"
}

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

# prompt to continue
# 1: the prompt message
# 2: the abort message
function continue_prompt() {
    local -r prompt_msg="${1}"
    local -r abort_msg="${2}"

    echo
    read -p "${prompt_msg} (y/N)? " choice
    case "$choice" in 
    y|Y ) echo
            ;;
    * )   echo "aborting; ${abort_msg}"
            exit 0
            ;;
    esac
}
