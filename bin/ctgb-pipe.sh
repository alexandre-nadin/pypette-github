#!/usr/bin/env bash
source pipe.sh

SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
SCRIPT_DIR=$(dirname "${SCRIPT_PATH}")
EXEC_DIR="$(readlink -f $(pwd))"

VARENVS_TAG="_CPIPE_"

# ---------------------
# Snakemake functions
# ---------------------
function baseSnakemake() {
  #exportVarenvs
  command snakemake "$@"
}

function snakemake() {
  baseSnakemake "$@"
}

function smk() {
  baseSnakemake "$@"
}

# -------
# Manual
# -------
cpipe__paramsMandatory=(PROJECT PIPELINE)
function manual() {
  cat << EOFMAN
  
  DESCRIPTION
      Launches a CTGB PIPELINE for the given PROJECT.
      SNAKEMAKE_OPTIONs will be passed to the Snakemake command.

  USAGE
      $ $0 --project PROJECT -p PIPELINE [--snakemake SNAKEMAKE_OPTION ...]

  OPTIONS
      --project
          Name of the project to analyse.

      -p|--pipeline
          Name of the ctgb-pipe PIPELINE to load.

      --ls-pipes
          Lists available pipelines in ctgb-pipe.

      --ls-modules
          Lists available modules in ctgb-pipe.

      --snakemake
          List of options to pass to Snakemake. 

      -c|--conda-env
          Specifies the conda environment in which the pipeline is to be executed.
          Default is 'pipe-PIPELINE'.

      -v|--verbose
          Makes this command verbose.

      -h|--help
          Displays this help manual.
    
EOFMAN
}

# -----------
# Parameters
# -----------
function initParams() {
  PROJECT=""
  PIPELINE=""
  SNAKE_OPTIONS=()
  VERBOSE=false
  CLUSTER_MNT_POINT=${CLUSTER_MNT_POINT:-""}
  WORKFLOW_DIR=${WORKFLOW_DIR:-""}
  CONDA_ENV=""
}

function checkParams() {
  pipe::checkParams ${cpipe__paramsMandatory[@]}
  pipe::checkPipeline
}


# ----------
# Commands 
# ----------
function envPipelineDft() {
  printf "pipe-${PIPELINE}" \
   | tr '[[:upper:]]' '[[:lower:]]'
}

function envPipeline() {
  printf "${CONDA_ENV:-$(envPipelineDft)}"
}

function envActivate() {
  pipe::infecho "Executing in '$(envPipeline)' conda environment."
  condactivate $(envPipeline)
}

function cmdSnakemake() {
  cat << eol 
  \snakemake  \
   --snakefile $(pipe::pathPipelineSnakefile root) \
   ${SNAKE_OPTIONS[@]}  
eol
}

function execSnakemake() {
  pipe::infecho "\$ $(cmdSnakemake)\n"
  eval "$(cmdSnakemake)"
}

# ---------
# Env Vars
# ---------
_varenvs=()

function exportVarenvs() {
  exportCpipeVarenv "HOME" $(pipe::homeDir)
  exportCpipeVarenv "PROJECT" "$PROJECT"
  exportCpipeVarenv "PIPE_NAME" "$PIPELINE"
  exportCpipeVarenv "PIPE_ENV" "$(envPipeline)"
  exportCpipeVarenv "PIPE_SNAKE" $(pipe::pathPipelineSnakefile $PIPELINE)
  exportCpipeVarenv "WORKFLOW_DIR" "$WORKFLOW_DIR"
  exportCpipeVarenv "CLUSTER_MNT_POINT" "$CLUSTER_MNT_POINT"
  exportCpipeVarenv "SHELL_ENV" "$SHELL_ENV"
  export PYTHONPATH=${PYTHONPATH:+${PYTHONPATH}":"}$(pipe::homeDir)
  exportCpipeVarenv "PYTHON_SYSPATH" "$(pythonSysPath) $PYTHONPATH"
  exportCpipeVarenv "EXEC_DIR" "$EXEC_DIR"
}

function pythonSysPath() {
  python -c 'import sys; print(" ".join(sys.path))'
}

function exportCpipeVarenv() {
  local var="$(cpipeVarenvOf ${1})"
  if [ ${#_varenvs[@]} -gt 0 ]; then
    _varenvs=(${_varenvs[@]} "$var") 
  else
    _varenvs=("$var")
  fi
  eval "export $(cpipeVarenvOf ${1})=\"${2}\""
}

function cpipeVarenvOf() {
  printf "${VARENVS_TAG}${1}"
}
