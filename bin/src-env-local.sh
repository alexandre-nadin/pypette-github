#!/usr/bin/env bash
_dir=$(readlink -f $(dirname "${BASH_SOURCE[0]}"))

source "${_dir}/ctgb-pipe.sh"

## Include binaries
export PATH="${PATH}":"${_dir}"
export CTGB__DIR_PROJECTS="${HOME}/dev/ctgb/project-analysis"
export CLUSTER_MNT_POINT="${HOME}/dev/ctgb/cluster"
export TMPDIR='/tmp'
"${_dir}/set-dirs"


condactivate ctgb-pipe
