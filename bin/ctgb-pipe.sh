#!/usr/bin/env bash
SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
SCRIPT_DIR=$(dirname "${SCRIPT_PATH}")
EXEC_DIR="$(readlink -f $(pwd))"

PIPELINE_SNAKEFILE="Snakefile"
VARENVS_TAG="_CPIPE_"

# ---------------------
# Snakemake functions
# ---------------------
function baseSnakemake() {
  exportVarenvs
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

      -v|--verbose
          Makes this command verbose.

      -h|--help
          Displays this help manual.
    
EOFMAN
}

function msgManual() {
  cat << eol
Please consult the following help:
$(manual)
eol
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
}

function checkParams() {
  checkDirs
  checkProject
  checkPipeline
}

function isParamGiven() {
  [ ! -z ${1:+x} ] 
}

function existsPipeline() {
  [ -f $(pathPipelineSnakefile ${1}) ]
}

function checkProject() {
  isParamGiven "$PROJECT"    || errorParamNotGiven "PROJECT"
}

function checkPipeline() {
  isParamGiven "$PIPELINE"   || errorParamNotGiven "PIPELINE"
  existsPipeline "$PIPELINE" || errorPipelineNotExist "$PIPELINE"
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

function envPipeline() {
  printf "pipe-${PIPELINE}" \
   | tr '[[:upper:]]' '[[:lower:]]'
}

function envActivate() {
  condactivate $(envPipeline)
}

function cmdSnakemake() {
  cat << eol | xargs
  \snakemake
   --snakefile $(pathPipelineSnakefile root)
   ${SNAKE_OPTIONS[@]}
eol
}

function execSnakemake() {
  infecho "\$ $(cmdSnakemake)\n"
  eval "$(cmdSnakemake)"
}

# ---------
# Env Vars
# ---------
function exportVarenvs() {
  exportCpipeVarenv "HOME" $(pathHome)
  exportCpipeVarenv "PROJECT" "$PROJECT"
  exportCpipeVarenv "PIPE_NAME" "$PIPELINE"
  exportCpipeVarenv "PIPE_SNAKE" $(pathPipelineSnakefile $PIPELINE)
  exportCpipeVarenv "WORKFLOW_DIR" "$WORKFLOW_DIR"
  exportCpipeVarenv "CLUSTER_MNT_POINT" "$CLUSTER_MNT_POINT"
  exportCpipeVarenv "SHELL_ENV" "$SHELL_ENV"
  exportCpipeVarenv "PYTHON_SYSPATH" "$(pythonSysPath)"
  exportCpipeVarenv "EXEC_DIR" "$EXEC_DIR"
  export PYTHONPATH=${PYTHONPATH:+${PYTHONPATH}":"}$(pathHome)
}

function pythonSysPath() {
  python -c 'import sys; print(" ".join(sys.path))'
}

function cpipeVarenvOf() {
  printf "${VARENVS_TAG}${1}"
}

function exportCpipeVarenv() {
  eval "export $(cpipeVarenvOf ${1})=\"${2}\""
}

# -------
# Errors
# -------
function verbecho() {
  ${VERBOSE} && printf "$@\n" || : 
}

function infecho() {
  printf "Info: $@\n" >&2
}

function errexit() {
  printf "Error: $@\n\n" >&2
  msgManual
  exit 1
}

function msgUnrecOpt() {
  cat << eol
Unrecognized option '$@'.
eol
}

function errorUnrecOpt() {
  errexit "$(msgUnrecOpt $@)"
}

function msgParamNotGiven() {
  cat << eol
Parameter ${1} not given.
eol
}

function errorParamNotGiven() {
  errexit "$(msgParamNotGiven $1)"
}

function msgPipelineNotExist() {
cat << eol
Pipeline "$(pathPipelineSnakefile ${1})" not found in '$(pathPipelines)/'.
eol
}

function errorPipelineNotExist() {
  errexit "$(msgPipelineNotExist $1)"
} 

# ----------------------------
# -------------------
# Module generators
# -------------------
function cpipe::fileAddSyntax() {
  cpipe::editorSyntax >> "$1"
}
 
function cpipe::editorSyntax() {
  cat << eol 
#!/usr/bin/env python
eol
}

function cpipe::includePipeline() {
  [ $# -eq 1 ] || exit 1
  cpipe::includeBase
  cat << eol
includePipeline("${1}")
eol
}

function cpipe::includeModule() {
  [ $# -eq 1 ] || exit 1
  cat << eol
includeModule("${1}")
eol
}

function cpipe::includeFiletype() {
  [ $# -eq 2 ] || exit 1
  cat << eol
include_${1}("${2}")
eol
}

function cpipe::includeBase() {
  cat << eol
include: "${CTGB_PIPE_HOME}/pipelines/pipeline.sk"
eol
}
