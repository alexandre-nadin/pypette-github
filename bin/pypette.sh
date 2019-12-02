# bash
trap pypette::cleanup EXIT SIGKILL

function pypette::cleanup() {
  pypette::cleanJobsDir
}

function pypette::fullPath() {
  readlink -f "$1"
}

SCRIPT_PATH=$(pypette::fullPath "$0")
SCRIPT_DIR=$(dirname "${SCRIPT_PATH}")
EXE_DIR="$(pypette::fullPath $(pwd))"
VARENVS_TAG="_PYPETTE_"

# ---------
# Workflow
# ---------
function pypette::runFlow() {
  pypette::initParams
  pypette::parseParams "$@"
  pypette::checkParams
  pypette::envActivate
  pypette::exportVarenvs
  pypette::execSnakemake
  pypette::cleanJobsDir
}

# -------------------------
# Command Base Parameters
# -------------------------
function pypette::extless() {
  printf ${1%%.*}
}

function pypette::lastSource() {
  local idx=$(( ${#BASH_SOURCE[@]} - 1))
  printf ${BASH_SOURCE[$idx]}
}

function pypette::cmdName() {
  basename "$(pypette::cmdPath)"
}

function pypette::cmdPath() {
  pypette::fullPath $(pypette::lastSource)
}

function pypette::cmdDir() {
  dirname $(pypette::cmdPath)
}

# -------
# Paths
# -------
function pypette::homeDir() {
  pypette::fullPath "$(pypette::cmdDir)/.."
}

function pypette::pathPipelines() {
  printf "$(pypette::homeDir)/pipelines"
}

function pypette::pathPipelineSnakefile() {
  printf "$(pypette::pathPipelines)/${1}/${pypette__PIPELINE_SNAKEFILE}"
}

function pypette::pathModules() {
  printf "$(pypette::homeDir)/modules"
}

# --------------------
# Pipelines & Modules
# --------------------
pypette__PIPELINE_SNAKEFILE="Snakefile"

function pypette::existsPipeline() {
  [ -f $(pypette::pathPipelineSnakefile ${1}) ]
}

function pypette::listPipelines() (
  cd "$(pypette::pathPipelines)"
  set +f
  pypette::msgListPipelines
  ls -1 */{,*/}${pypette__PIPELINE_SNAKEFILE}     \
   | sed "s|/\?${pypette__PIPELINE_SNAKEFILE}$||" \
   | xargs                          \
   2>/dev/null
)

function pypette::msgListPipelines() {
  cat << eol
Available pipelines: 
eol
}

function pypette::listModules() (
  cd "$(pypette::pathModules)"
  set +f
  pypette::msgListModules 
  ls */{,*/}*.{sk,snake} \
    2> /dev/null
)

function pypette::msgListModules() {
  cat << eol
Available modules: 
eol
}

# -------
# Manual
# -------
pypette__manual='manual'
function pypette::setManual() {
  pypette__manual="$1"
}

function pypette::manual() {
  $pypette__manual
}

function pypette::msgManual() {
  cat << eol
Please consult the help: '\$ $(pypette::cmdName) --help'
eol
}

pypette__paramsMandatory=(PROJECT PIPELINE)

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

      -o|--outdir
          The directory where to write output results.

      -k|--keep-files-regex
          The regex pattern of the temporary files to keep (ex.: '.*merged/.*bam').

          
      --ls-pipes
          Lists available pipelines in ctgb-pipe.

      --ls-modules
          Lists available modules in ctgb-pipe.

      --snakemake
          List of options to pass to Snakemake. 

      -c|--conda-env
          Specifies the conda environment in which the pipeline is to be executed.
          Default is 'pypette-PIPELINE'.

      -v|--verbose
          Makes this command verbose.

      -h|--help
          Displays this help manual.
    


EOFMAN
}

# -----------
# Parameters
# -----------
function pypette::initParams() {
  PROJECT=""
  PIPELINE=""
  SNAKE_OPTIONS=()
  VERBOSE=false
  CLUSTER_MNT_POINT=${CLUSTER_MNT_POINT:-""}
  WORKDIR="$(pwd)"
  KEEP_FILES_REGEX=""
  CONDA_ENV=""
}

function pypette::parseParams() {
  while [ $# -ge 1 ]
  do
      case "$1" in
        --project)
          PROJECT="$2"                && shift
          ;;

        -p|--pipeline)
          PIPELINE="$2"               && shift
          ;;
  
        --snakemake)
          SNAKE_OPTIONS+=("$2")       && shift
          ;;

        -c|--conda-env)
          CONDA_ENV="$2"              && shift
          ;;
  
        -h|--help)
          manual                      && exit
          ;;
  
        --ls-pipes)
          pypette::listPipelines      && exit
          ;;
  
        --ls-modules)
          pypette::listModules
          exit
          ;;

        -o|--outdir)
          WORKDIR=$(pypette::fullPath "$2") && shift
          ;;
             
        -k|--keep-files-regex)
          KEEP_FILES_REGEX="$2"       && shift
          ;;

        -v|--verbose)
          VERBOSE=true
          ;;
  
        *)
          pypette::errorUnrecOpt "$1"
          ;;
 
        *)
          echo "Taking snakemake command: '$1'"
          ;;
  
      esac
      shift
  done
}

function pypette::checkParams() {
  pypette::requireParams ${pypette__paramsMandatory[@]}
  pypette::checkPipeline
}

function pypette::requireParams() {
  for param in "$@"; do
     pypette::requireParam "$param"
  done
}

function pypette::requireParam() {
  pypette::isParamGiven "$1" || pypette::errorParamNotGiven "$1"
}

function pypette::isParamGiven() {
  [ ! -z ${!1:+x} ] 
}

function pypette::checkPipeline() {
  pypette::existsPipeline "$PIPELINE" || pypette::errorPipelineNotExist "$PIPELINE"
}

# ------------------
# Conda Environment
# ------------------
function pypette::envPipelineDft() {
  printf "pypette-${PIPELINE}" \
   | tr '[[:upper:]]' '[[:lower:]]'
}

function pypette::envPipeline() {
  printf "${CONDA_ENV:-$(pypette::envPipelineDft)}"
}

function pypette::envActivate() {
  pypette::infecho "Executing in '$(pypette::envPipeline)' conda environment."
  condactivate $(pypette::envPipeline)
}

# ------------------
# Shell Environment
# ------------------
function pypette::exportVarenvs() {
  pypette::exportVarenv "HOME" $(pypette::homeDir)
  pypette::exportVarenv "PROJECT" "$PROJECT"
  pypette::exportVarenv "PIPE_NAME" "$PIPELINE"
  pypette::exportVarenv "PIPE_ENV" "$(pypette::envPipeline)"
  pypette::exportVarenv "PIPE_SNAKE" $(pypette::pathPipelineSnakefile $PIPELINE)
  pypette::exportVarenv "WORKDIR" "$WORKDIR"
  pypette::exportVarenv "CLUSTER_MNT_POINT" "$CLUSTER_MNT_POINT"
  pypette::exportVarenv "KEEP_FILES_REGEX" "$KEEP_FILES_REGEX"
  export TMPDIR=${TMPDIR:-/lustre2/scratch/tmp}
  export PATH="${SCRIPT_DIR}${PATH:+:${PATH}}"
  export PYTHONPATH=${PYTHONPATH:+${PYTHONPATH}":"}$(pypette::homeDir)
  pypette::exportVarenv "PYTHON_SYSPATH" "$(pypette::pythonSysPath) ${PYTHONPATH:+${PYTHONPATH[@]}} $(pypette::homeDir)"
  pypette::exportVarenv "EXE_DIR" "$EXE_DIR"
  pypette::exportVarenv "EXE_TIME" "$(date '+%y%m%d-%H%M%S')"
}

function pypette::pythonSysPath() {
  python -c 'import sys; print(" ".join(sys.path))'
}

pypette__varenvs=()
function pypette::exportVarenv() {
  local var="$(pypette::varenvOf ${1})"
  if [ ${#pypette__varenvs[@]} -gt 0 ]; then
    pypette__varenvs=(${pypette__varenvs[@]} "$var") 
  else
    pypette__varenvs=("$var")
  fi
  eval "export $(pypette::varenvOf ${1})=\"${2}\""
}

function pypette::varenvOf() {
  printf "${VARENVS_TAG}${1}"
}

# --------------------
# Snakemake Commands
# --------------------
function pypette::execSnakemake() {
  pypette::infecho "\$ $(pypette::cmdSnakemake)\n"
  eval "$(pypette::cmdSnakemake)"
}

function pypette::cmdSnakemake() {
  cat << eol 
  \snakemake  \
   --snakefile $(pypette::pathPipelineSnakefile root) \
   ${SNAKE_OPTIONS[@]}  
eol
}

# -----------------
# Jobs Directories
# -----------------
function pypette::jobsDir() {
  printf "${WORKDIR}/jobs"
}

function pypette::hasJobsDir() {
  [ -d "$(pypette::jobsDir)" ]
}

function pypette::jobsLogsDirs() {
  find $(pypette::jobsDir) -mindepth 1 -maxdepth 1 -type d \
   | xargs -I {} readlink -f {} ;
}

function pypette::hasJobsLogsDirs() {
  pypette::jobsLogsDirs && [ $(pypette::jobsLogsDirs | wc -l) -gt 0 ]
}

function pypette::jobsLogs() {
  find $(pypette::jobsDir) -mindepth 1 -maxdepth 2 -type f
}

function pypette::hasJobsLogs() {
  pypette::hasJobsDir && [ $(pypette::jobsLogs | wc -l) -gt 0 ]
}


# ----------
# Cleaning
# ----------
function pypette::cleanJobsDir() {
  pypette::cleanLogBashErrors
  pypette::rmEmptyJobsDirs
}

function pypette::cleanLogBashErrors() {
  pypette::hasJobsLogs || return 0
  pypette::jobsLogs            \
   | xargs sed -i '/^-bash:/d'
}

function pypette::rmEmptyJobsDirs() {
  pypette::hasJobsLogsDirs || return 0
  for jobDir in $(pypette::jobsLogsDirs); do
    if [ $(ls "$jobDir" | wc -l) -gt 0 ]; then
      :
    else
      rm -r "$jobDir"
    fi
  done
}

# ---------------
# Error messages
# ---------------
function pypette::errorParamNotGiven() {
  pypette::errexit "$(pypette::msgParamNotGiven $1)"
}

function pypette::msgParamNotGiven() {
  cat << eol
Parameter ${1} not given.
eol
}

function pypette::verbecho() {
  ${VERBOSE} && printf "$@\n" || : 
}

function pypette::infecho() {
  printf "Info: $@\n"
}

function pypette::errexit() {
  printf "Error: $@\n"
  pypette::msgManual
  exit 1
}

function pypette::msgUnrecOpt() {
  cat << eol
Unrecognized option '$@'.
eol
}

function pypette::errorUnrecOpt() {
  pypette::errexit "$(pypette::msgUnrecOpt $@)"
}

function pypette::errorPipelineNotExist() {
  pypette::errexit "$(pypette::msgPipelineNotExist $1)"
} 

function pypette::msgPipelineNotExist() {
  cat << eol
Pipeline "$(pypette::pathPipelineSnakefile ${1})" not found in '$(pypette::pathPipelines)/'.
eol
}
