#!/usr/bin/env bash
_dir=$(readlink -f $(dirname "${BASH_SOURCE[0]}"))

source "${_dir}/ctgb-pipe.sh"
"${_dir}/set-dirs"

## Include binaries
export PATH="${PATH}":"${_dir}"
export CTGB__DIR_PROJECTS="${HOME}/dev/ctgb/projects"

condactivate ctgb-pipe
