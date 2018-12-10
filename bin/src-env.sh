#!/usr/bin/env bash
_dir=$(readlink -f $(dirname "${BASH_SOURCE[0]}"))

source "${_dir}/ctgb-pipe.sh"
"${_dir}/set-dirs"

## Include binaries
export PATH="${PATH}":"${CTGB_PIPE_HOME}/bin"

condactivate ctgb-pipe
