#!/usr/bin/env bash
_dir=$(readlink -f $(dirname "${BASH_SOURCE[0]}")) 
export PATH="${_dir}:${PATH}"

# Sugar-sourcing for cli-pipette
alias clip-start='source clip'

# Temporary way of activating conda environments
if [ ${#_PYPETTE_PIPE_ENV} -gt 0 ]; then
  printf "Activating conda env '$_PYPETTE_PIPE_ENV'.\n" >&2
  condeactivate || true
  condactivate $_PYPETTE_PIPE_ENV
else
  :
fi

