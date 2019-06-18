#!/usr/bin/env bash
source pipe.sh

SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
SCRIPT_DIR=$(dirname "${SCRIPT_PATH}")
EXEC_DIR="$(readlink -f $(pwd))"

PIPELINE_SNAKEFILE="Snakefile"
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
function manual() {
  cat << EOFMAN
  
  DESCRIPTION
      Launches a CTGB PIPELINE for the given PROJECT.
      SNAKEMAKE_OPTIONs will be passed to the Snakemake command.

  USAGE
      $ $0 --prj PROJECT -p PIPELINE [--smk SNAKEMAKE_OPTION ...]

  OPTIONS
      --prj
          Name of the project to analyse.

      -p|--pipeline
          Name of the ctgb-pipe PIPELINE to load.

      --ls-pipes
          Lists available pipelines in ctgb-pipe.

      --ls-modules
          Lists available modules in ctgb-pipe.

      --smk|--snake-options
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

# ------
# Paths
# ------
function pathHome() {
  readlink -f "${SCRIPT_DIR}/.."
}

function pathPipelines() {
  printf "$(pathHome)/pipelines"
}

function pathPipelineSnakefile() {
  printf "$(pathPipelines)/${1}/${PIPELINE_SNAKEFILE}"
}

function pathModules() {
  printf "$(pathHome)/modules"
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
  checkDirs
  pipe::checkProject
  checkPipeline
}

function existsPipeline() {
  [ -f $(pathPipelineSnakefile ${1}) ]
}

function checkPipeline() {
  pipe::isParamGiven "$PIPELINE" || pipe::errorParamNotGiven "PIPELINE"
  existsPipeline "$PIPELINE"     || errorPipelineNotExist "$PIPELINE"
}

function checkDirs() {
  :
}

# ----------
# Commands 
# ----------
function msgListPipelines() {
  cat << eol
Available pipelines: 
eol
}

function listPipelines() (
  cd "$(pathPipelines)"
  set +f
  msgListPipelines
  ls -1 */{,*/}${PIPELINE_SNAKEFILE}     \
   | sed "s|/\?${PIPELINE_SNAKEFILE}$||" \
   | xargs                          \
   2>/dev/null
)

function msgListModules() {
  cat << eol
Available modules: 
eol
}

function listModules() (
  cd "$(pathModules)"
  set +f
  msgListModules 
  ls */{,*/}*.{sk,snake} \
    2> /dev/null
)

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
   --snakefile $(pathPipelineSnakefile root) \
   ${SNAKE_OPTIONS[@]}  
eol
  #\
 #  $(clusterVarEnvsStr)
  
}

function execSnakemake() {
  pipe::infecho "\$ $(cmdSnakemake)\n"
  eval "$(cmdSnakemake)"
}

# ---------
# Env Vars
# ---------
function exportVarenvs() {
  exportCpipeVarenv "HOME" $(pathHome)
  exportCpipeVarenv "PROJECT" "$PROJECT"
  exportCpipeVarenv "PIPE_NAME" "$PIPELINE"
  exportCpipeVarenv "PIPE_ENV" "$(envPipeline)"
  exportCpipeVarenv "PIPE_SNAKE" $(pathPipelineSnakefile $PIPELINE)
  exportCpipeVarenv "WORKFLOW_DIR" "$WORKFLOW_DIR"
  exportCpipeVarenv "CLUSTER_MNT_POINT" "$CLUSTER_MNT_POINT"
  exportCpipeVarenv "SHELL_ENV" "$SHELL_ENV"
  export PYTHONPATH=${PYTHONPATH:+${PYTHONPATH}":"}$(pathHome)
  exportCpipeVarenv "PYTHON_SYSPATH" "$(pythonSysPath) $PYTHONPATH"
  exportCpipeVarenv "EXEC_DIR" "$EXEC_DIR"
}

function pythonSysPath() {
  python -c 'import sys; print(" ".join(sys.path))'
}

function cpipeVarenvOf() {
  printf "${VARENVS_TAG}${1}"
}

_varenvs=()
function clusterEnvs() {
  local varStrs=()
  local varStr=''
  for var in "${_varenvs[@]}"; do
    varStr="$var=\"${!var}\""
    if [ ${#varStrs} -gt 0 ]; then
      varStrs=("${varStrs[@]}" "$varStr")
    else
      varStrs=("$varStr")
    fi
  done
  str.join -d ',' "${varStrs[@]}"
}

function clusterVarEnvsStr() {
  local str=''
  if [ ${#_varenvs} -gt 0 ]; then
    str="--cluster \'qsub -v $(clusterEnvs)\'"
  fi
  #printf -- "--cluster 'qsub $str'"
  printf -- "$str"
}

function exportCpipeVarenv() {
  local var="$(cpipeVarenvOf ${1})"
  if [ ${#_varenvs} -gt 0 ]; then
    _varenvs=(${_varenvs[@]} "$var") 
  else
    _varenvs=("$var")
  fi
  eval "export $(cpipeVarenvOf ${1})=\"${2}\""
}

# -------
# Errors
# -------
function msgPipelineNotExist() {
  cat << eol
Pipeline "$(pathPipelineSnakefile ${1})" not found in '$(pathPipelines)/'.
eol
}

function errorPipelineNotExist() {
  pipe::errexit "$(msgPipelineNotExist $1)"
} 
