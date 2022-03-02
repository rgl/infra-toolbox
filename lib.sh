#!/bin/bash
set -eu -o pipefail -o errtrace


function err_trap {
    local err="$?"
    set +o xtrace
    local exit_code="${1:-1}"
    echo "ERROR: ${BASH_COMMAND} exited with status $err at:" >&2
    echo "       ${BASH_SOURCE[1]}:${BASH_LINENO[0]}" >&2
    if [ ${#FUNCNAME[@]} -gt 2 ]; then
        for (( i=1; i<${#FUNCNAME[@]}-1; i++ )); do
            echo "       ${BASH_SOURCE[$i+1]}:${BASH_LINENO[$i]} ${FUNCNAME[$i]}" >&2
        done
    fi
    exit "$exit_code"
}

trap err_trap ERR


function title {
    cat <<EOF

########################################################################
#
# $*
#

EOF
}
