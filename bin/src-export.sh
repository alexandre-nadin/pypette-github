#!/usr/bin/env bash
_dir=$(readlink -f $(dirname "${BASH_SOURCE[0]}")) 
export PATH="${PATH}:${_dir}"

# Temporary way of activating conda environments
if [ ${#_CPIPE_PIPE_ENV} -gt 0 ]; then
  printf "Sourcing SHELL_ENV '$SHELL_ENV'\n" >&2
  source $SHELL_ENV
  type -a condactivate
  printf "Activating conda env '$_CPIPE_PIPE_ENV'.\n" >&2
  condeactivate || true
  condactivate $_CPIPE_PIPE_ENV
else
  :
fi

