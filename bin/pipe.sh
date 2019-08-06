# bash

SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "${SCRIPT_PATH}")
EXEC_DIR="$(readlink -f $(pwd))"
VARENVS_TAG="_CPIPE_"

# ---------
# Workflow
# ---------
function pipe::runFlow() {
  pipe::initParams
  pipe::parseParams "$@"
  pipe::checkParams
  pipe::envActivate
  pipe::exportVarenvs
  pipe::execSnakemake
}

# -------------------------
# Command Base Parameters
# -------------------------
function pipe::extless() {
  printf ${1%%.*}
}

function pipe::lastSource() {
  local idx=$(( ${#BASH_SOURCE[@]} - 1))
  printf ${BASH_SOURCE[$idx]}
}

function pipe::cmdName() {
  basename "$(pipe::cmdPath)"
}

function pipe::cmdPath() {
  readlink -f $(pipe::lastSource)
}

function pipe::cmdDir() {
  dirname $(pipe::cmdPath)
}

# -------
# Paths
# -------
function pipe::homeDir() {
  readlink -f "$(pipe::cmdDir)/.."
}

function pipe::pathPipelines() {
  printf "$(pipe::homeDir)/pipelines"
}

function pipe::pathPipelineSnakefile() {
  printf "$(pipe::pathPipelines)/${1}/${pipe__PIPELINE_SNAKEFILE}"
}

function pipe::pathModules() {
  printf "$(pipe::homeDir)/modules"
}

# --------------------
# Pipelines & Modules
# --------------------
pipe__PIPELINE_SNAKEFILE="Snakefile"

function pipe::existsPipeline() {
  [ -f $(pipe::pathPipelineSnakefile ${1}) ]
}

function pipe::listPipelines() (
  cd "$(pipe::pathPipelines)"
  set +f
  pipe::msgListPipelines
  ls -1 */{,*/}${pipe__PIPELINE_SNAKEFILE}     \
   | sed "s|/\?${pipe__PIPELINE_SNAKEFILE}$||" \
   | xargs                          \
   2>/dev/null
)

function pipe::msgListPipelines() {
  cat << eol
Available pipelines: 
eol
}

function pipe::listModules() (
  cd "$(pipe::pathModules)"
  set +f
  pipe::msgListModules 
  ls */{,*/}*.{sk,snake} \
    2> /dev/null
)

function pipe::msgListModules() {
  cat << eol
Available modules: 
eol
}

# -------
# Manual
# -------
pipe__manual='manual'
function pipe::setManual() {
  pipe__manual="$1"
}

function pipe::manual() {
  $pipe__manual
}

function pipe::msgManual() {
  cat << eol
Please consult the help: '\$ $(pipe::cmdName) --help'
eol
}

pipe__paramsMandatory=(PROJECT PIPELINE)
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
function pipe::initParams() {
  PROJECT=""
  PIPELINE=""
  SNAKE_OPTIONS=()
  VERBOSE=false
  CLUSTER_MNT_POINT=${CLUSTER_MNT_POINT:-""}
  WORKFLOW_DIR=${WORKFLOW_DIR:-""}
  CONDA_ENV=""
}

function pipe::parseParams() {
  while [ $# -ge 1 ]
  do
      case "$1" in
        --project)
          PROJECT="$2" && shift
          ;;

        -p|--pipeline)
          PIPELINE="$2" && shift
          ;;
  
        --snakemake)
          SNAKE_OPTIONS+=("$2") && shift
          ;;

        -c|--conda-env)
          CONDA_ENV="$2" && shift
          ;;
  
        -h|--help)
          manual && exit
          ;;
  
        --ls-pipes)
          pipe::listPipelines
          exit
          ;;
  
        --ls-modules)
          pipe::listModules
          exit
          ;;

        -d|--directory)
          SNAKE_DIR="$2" && shift
          ;;
             
        -v|--verbose)
          VERBOSE=true
          ;;
  
        *)
          pipe::errorUnrecOpt "$1"
          ;;
 
        *)
          echo "Taking snakemake command: '$1'"
          ;;
  
      esac
      shift
  done
}

function pipe::checkParams() {
  pipe::requireParams ${pipe__paramsMandatory[@]}
  pipe::checkPipeline
}

function pipe::requireParams() {
  for param in "$@"; do
     pipe::requireParam "$param"
  done
}

function pipe::requireParam() {
  pipe::isParamGiven "$1" || pipe::errorParamNotGiven "$1"
}

function pipe::isParamGiven() {
  [ ! -z ${!1:+x} ] 
}

function pipe::checkPipeline() {
  pipe::existsPipeline "$PIPELINE" || pipe::errorPipelineNotExist "$PIPELINE"
}

# ------------------
# Conda Environment
# ------------------
function pipe::envPipelineDft() {
  printf "pipe-${PIPELINE}" \
   | tr '[[:upper:]]' '[[:lower:]]'
}

function pipe::envPipeline() {
  printf "${CONDA_ENV:-$(pipe::envPipelineDft)}"
}

function pipe::envActivate() {
  pipe::infecho "Executing in '$(pipe::envPipeline)' conda environment."
  condactivate $(pipe::envPipeline)
}

# ------------------
# Shell Environment
# ------------------
function pipe::exportVarenvs() {
  pipe::exportVarenv "HOME" $(pipe::homeDir)
  pipe::exportVarenv "PROJECT" "$PROJECT"
  pipe::exportVarenv "PIPE_NAME" "$PIPELINE"
  pipe::exportVarenv "PIPE_ENV" "$(pipe::envPipeline)"
  pipe::exportVarenv "PIPE_SNAKE" $(pipe::pathPipelineSnakefile $PIPELINE)
  pipe::exportVarenv "WORKFLOW_DIR" "$WORKFLOW_DIR"
  pipe::exportVarenv "CLUSTER_MNT_POINT" "$CLUSTER_MNT_POINT"
  pipe::exportVarenv "SHELL_ENV" "$SHELL_ENV"
  export PYTHONPATH=${PYTHONPATH:+${PYTHONPATH}":"}$(pipe::homeDir)
  pipe::exportVarenv "PYTHON_SYSPATH" "$(pipe::pythonSysPath) $PYTHONPATH"
  pipe::exportVarenv "EXEC_DIR" "$EXEC_DIR"
}

function pipe::pythonSysPath() {
  python -c 'import sys; print(" ".join(sys.path))'
}

pipe__varenvs=()
function pipe::exportVarenv() {
  local var="$(pipe::varenvOf ${1})"
  if [ ${#pipe__varenvs[@]} -gt 0 ]; then
    pipe__varenvs=(${pipe__varenvs[@]} "$var") 
  else
    pipe__varenvs=("$var")
  fi
  eval "export $(pipe::varenvOf ${1})=\"${2}\""
}

function pipe::varenvOf() {
  printf "${VARENVS_TAG}${1}"
}

# --------------------
# Snakemake Commands
# --------------------
function pipe::execSnakemake() {
  pipe::infecho "\$ $(pipe::cmdSnakemake)\n"
  eval "$(pipe::cmdSnakemake)"
}

function pipe::cmdSnakemake() {
  cat << eol 
  \snakemake  \
   --snakefile $(pipe::pathPipelineSnakefile root) \
   ${SNAKE_OPTIONS[@]}  
eol
}

# ---------------
# Error messages
# ---------------
function pipe::errorParamNotGiven() {
  pipe::errexit "$(pipe::msgParamNotGiven $1)"
}

function pipe::msgParamNotGiven() {
  cat << eol
Parameter ${1} not given.
eol
}

function pipe::verbecho() {
  ${VERBOSE} && printf "$@\n" || : 
}

function pipe::infecho() {
  printf "Info: $@\n"
}

function pipe::errexit() {
  printf "Error: $@\n"
  pipe::msgManual
  exit 1
}

function pipe::msgUnrecOpt() {
  cat << eol
Unrecognized option '$@'.
eol
}

function pipe::errorUnrecOpt() {
  pipe::errexit "$(pipe::msgUnrecOpt $@)"
}

function pipe::errorPipelineNotExist() {
  pipe::errexit "$(pipe::msgPipelineNotExist $1)"
} 

function pipe::msgPipelineNotExist() {
  cat << eol
Pipeline "$(pipe::pathPipelineSnakefile ${1})" not found in '$(pipe::pathPipelines)/'.
eol
}
