# bash
trap pypette::onexit EXIT SIGKILL

pypette::onexit() {
  pypette::setJobsDirPermissions
  pypette::cleanJobsDir
}

pypette::fullPath() {
  readlink -f "$1"
}

SCRIPT_PATH=$(pypette::fullPath "$0")
SCRIPT_DIR=$(dirname "${SCRIPT_PATH}")
EXE_DIR="$(pypette::fullPath $(pwd))"
EXE_TIME=$(date '+%y%m%d-%H%M%S')
VARENVS_TAG="_PYPETTE_"

# ---------
# Workflow
# ---------
pypette::runFlow() {
  pypette::initParams
  pypette::parseParams "$@"
  pypette::checkParams
  pypette::setLogsDir
  pypette::envActivate
  pypette::exportVarenvs
  pypette::execSnakemake
}

# -------------------------
# Command Base Parameters
# -------------------------
pypette::extless() {
  printf ${1%%.*}
}

pypette::lastSource() {
  local idx=$(( ${#BASH_SOURCE[@]} - 1))
  printf ${BASH_SOURCE[$idx]}
}

pypette::cmdName() {
  basename "$(pypette::cmdPath)"
}

pypette::cmdPath() {
  pypette::fullPath $(pypette::lastSource)
}

pypette::cmdDir() {
  dirname $(pypette::cmdPath)
}

# -------
# Paths
# -------
pypette::homeDir() {
  pypette::fullPath "$(pypette::cmdDir)/.."
}

pypette::pathPipelines() {
  printf "$(pypette::homeDir)/pipelines"
}

pypette::pathPipelineSnakefile() {
  printf "$(pypette::pathPipelines)/${1}/${pypette__PIPELINE_SNAKEFILE}"
}

pypette::pathModules() {
  printf "$(pypette::homeDir)/modules"
}

# --------------------
# Pipelines & Modules
# --------------------
pypette__PIPELINE_SNAKEFILE="Snakefile"

pypette::existsPipeline() {
  [ -f $(pypette::pathPipelineSnakefile ${1}) ]
}

pypette::listPipelines() (
  cd "$(pypette::pathPipelines)"
  set +f
  pypette::msgListPipelines
  ls -1 */{,*/}${pypette__PIPELINE_SNAKEFILE}     \
   | sed "s|/\?${pypette__PIPELINE_SNAKEFILE}$||" \
   | xargs                          \
   2>/dev/null
)

pypette::msgListPipelines() {
  cat << eol
Available pipelines:
eol
}

pypette::listModules() (
  cd "$(pypette::pathModules)"
  set +f
  pypette::msgListModules
  ls */{,*/}*.{sk,snake} \
    2> /dev/null
)

pypette::msgListModules() {
  cat << eol
Available modules:
eol
}

# -------
# Manual
# -------
pypette::version() {
  cat "$(pypette::homeDir)/version.txt"
}

pypette__manual='manual'
pypette::setManual() {
  pypette__manual="$1"
}

pypette::manual() {
  $pypette__manual
}

pypette::msgManual() {
  cat << eol
Please consult the help: '\$ $(pypette::cmdName) --help'
eol
}

pypette__paramsMandatory=(PROJECT PIPELINE)

manual() {
  cat << EOFMAN

  PYPETTE v$(pypette::version)
 
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
pypette::initParams() {
  PROJECT=""
  PIPELINE=""
  SNAKE_OPTIONS=()
  VERBOSE=false
  CLUSTER_MNT_POINT=${CLUSTER_MNT_POINT:-""}
  WORKDIR="$(pwd)"
  KEEP_FILES_REGEX=""
  CONDA_ENV=""
}

pypette::parseParams() {
  while [ $# -ge 1 ]; do
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
        pypette::listPipelines && exit
        ;;
 
      --ls-modules)
        pypette::listModules
        exit
        ;;

      -o|--outdir)
        WORKDIR=$(pypette::fullPath "$2") && shift
        ;;
          
      -k|--keep-files-regex)
        KEEP_FILES_REGEX="$2" && shift
        ;;

      -v|--verbose)
        VERBOSE=true
        ;;
 
      *)
        pypette::errorUnrecOpt "$1"
        ;;

      *)
        echo "Taking snakemake command: '$1'" >&2
        ;;
 
    esac
    shift
  done
}

pypette::checkParams() {
  pypette::requireParams ${pypette__paramsMandatory[@]}
  pypette::checkPipeline
}

pypette::requireParams() {
  for param in "$@"; do
     pypette::requireParam "$param"
  done
}

pypette::requireParam() {
  pypette::isParamGiven "$1" || pypette::errorParamNotGiven "$1"
}

pypette::isParamGiven() {
  [ ! -z ${!1:+x} ]
}

pypette::checkPipeline() {
  pypette::existsPipeline "$PIPELINE" || pypette::errorPipelineNotExist "$PIPELINE"
}

# ------------------
# Conda Environment
# ------------------
pypette::envPipelineDft() {
  printf "pypette-${PIPELINE}" \
   | tr '[[:upper:]]' '[[:lower:]]'
}

pypette::envPipeline() {
  printf "${CONDA_ENV:-$(pypette::envPipelineDft)}"
}

pypette::envActivate() {
  pypette::infecho "Executing in '$(pypette::envPipeline)' conda environment."
  condactivate $(pypette::envPipeline)
}

# ------------------
# Shell Environment
# ------------------
pypette::exportVarenvs() {
  pypette::exportExecVarenv "HOME" $(pypette::homeDir)
  pypette::exportExecVarenv "PROJECT"
  pypette::exportExecVarenv "PIPE_NAME" "$PIPELINE"
  pypette::exportExecVarenv "PIPE_ENV" "$(pypette::envPipeline)"
  pypette::exportExecVarenv "PIPE_SNAKE" $(pypette::pathPipelineSnakefile $PIPELINE)
  pypette::exportExecVarenv "WORKDIR"
  pypette::exportExecVarenv "CLUSTER_MNT_POINT"
  pypette::exportExecVarenv "KEEP_FILES_REGEX"
  export TMPDIR=${TMPDIR:-/lustre2/scratch/tmp}
  export PATH="${SCRIPT_DIR}${PATH:+:${PATH}}"
  export PYTHONPATH=${PYTHONPATH:+${PYTHONPATH}":"}$(pypette::homeDir)
  pypette::exportExecVarenv "PYTHON_SYSPATH" "$(pypette::pythonSysPath) ${PYTHONPATH:+${PYTHONPATH[@]}} $(pypette::homeDir)"
  pypette::exportExecVarenv "EXE_DIR"
  pypette::exportExecVarenv "EXE_TIME"
}

pypette::pythonSysPath() {
  python -c 'import sys; print(" ".join(sys.path))'
}

pypette::exportExecVarenv() {
  #
  # Export the given varenv for the executable.
  #
  eval "export $(pypette::tagVarenv ${1})=\"${2:-${!1}}\""
}

pypette::tagVarenv() {
  #
  # Sets tag to execution varenv name
  #
  printf "${VARENVS_TAG}${1}"
}

# --------------------
# Snakemake Commands
# --------------------
pypette::execSnakemake() {
  pypette::infecho "\$ $(pypette::cmdSnakemake)\n"
  eval "$(pypette::cmdSnakemake)"
}

pypette::cmdSnakemake() {
  cat << eol
  \snakemake  \
   --snakefile $(pypette::pathPipelineSnakefile root) \
   ${SNAKE_OPTIONS[@]}
eol
}

# -----------------
# Jobs Directories
# -----------------
pypette::setLogsDir() {
  pypette::mkExecDir
}

pypette::execLogOut() {
  printf "$(pypette::execDir)/exec.out"
}

pypette::execLogErr() {
  printf "$(pypette::execDir)/exec.err"
}

pypette::execDir() {
  printf "$(pypette::jobsDir)/${EXE_TIME}"
}

pypette::mkExecDir() {
  mkdir -p $(pypette::execDir)
}

pypette::jobsDir() {
  printf "${WORKDIR}/jobs"
}

pypette::hasJobsDir() {
  [ -d "$(pypette::jobsDir)" ]
}

pypette::jobsLogsDirs() {
  pypette::hasJobsDir || return 0
  find $(pypette::jobsDir) -mindepth 1 -maxdepth 1 -type d \
   | xargs -I {} readlink -f {} ;
}

pypette::hasJobsLogsDirs() {
  [ $(pypette::jobsLogsDirs | wc -l) -gt 0 ]
}

pypette::jobsLogs() {
  pypette::hasJobsDir || return 1
  find $(pypette::jobsDir)    \
    -mindepth 1               \
    -maxdepth 2               \
    -type f                   \
    -regextype sed            \
    -regex '.*\.err\|.*\.out'
}

pypette::hasJobsLogs() {
  [ $(pypette::jobsLogs | wc -l) -gt 0 ]
}


# -----------
# Jobs Logs
# -----------
pypette::setJobsDirPermissions() {
  chmod -R u+rwX,g+rX $(pypette::jobsDir)
}

pypette::cleanJobsDir() {
  pypette::cleanLogBashErrors
  pypette::rmEmptyJobsDirs
}

pypette::cleanLogBashErrors() {
  pypette::hasJobsLogs || return 0
  pypette::jobsLogs            \
   | xargs sed -i '/^-bash:/d'
}

pypette::rmEmptyJobsDirs() {
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
pypette::errorParamNotGiven() {
  pypette::errexit "$(pypette::msgParamNotGiven $1)"
}

pypette::msgParamNotGiven() {
  cat << eol
Parameter ${1} not given.
eol
}

pypette::verbecho() {
  ${VERBOSE} && printf "$@\n" || :
}

pypette::infecho() {
  printf "Info: $@\n"
}

pypette::errexit() {
  printf "Error: $@\n"
  pypette::msgManual
  exit 1
}

pypette::msgUnrecOpt() {
  cat << eol
Unrecognized option '$@'.
eol
}

pypette::errorUnrecOpt() {
  pypette::errexit "$(pypette::msgUnrecOpt $@)"
}

pypette::errorPipelineNotExist() {
  pypette::errexit "$(pypette::msgPipelineNotExist $1)"
}

pypette::msgPipelineNotExist() {
  cat << eol
Pipeline "$(pypette::pathPipelineSnakefile ${1})" not found in '$(pypette::pathPipelines)/'.
eol
}
