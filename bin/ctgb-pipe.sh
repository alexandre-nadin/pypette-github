#!/usr/bin/env bash
SCRIPT_PATH=$(readlink -f "${0}")
SCRIPT_DIR=$(dirname "${SCRIPT_PATH}")

# ---------------------
# Snakemake functions
# ---------------------
function baseSnakemake() {
  exportVarenvs
  command snakemake $@
}

function snakemake() {
  baseSnakemake $@
}

function smk() {
  baseSnakemake $@
}

# -------
# Manual
# -------
function manual() {
cat << EOFMAN
  
  DESCRIPTION
      Launches a ctgb-pipe PIPELINE.
      snakemake-options will be passed to the snakemake command.

  USAGE
      $ $0 -p PIPELINE [-o snake-option ...]

  OPTIONS
      -p|--pipeline
          Name of the ctgb-pipe PIPELINE to load.

      --ls-pipes
          Lists available pipelines in ctgb-pipe.

      --ls-modules
          Lists available modules in ctgb-pipe.

      -o|--snake-options
          List of options to pass to Snakemake

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
  printf "$(pathPipelines)/${1}/Snakefile"
}

function pathModules() {
  printf "$(pathHome)/modules"
}

# -----------
# Parameters
# -----------
function initParams() {
  PIPELINE=""
  SNAKE_OPTIONS=()
  VERBOSE=false
}

function checkParams() {
  checkPipeline
}

function isParamGiven() {
  [ ! -z ${1:+x} ] 
}

function existsPipeline() {
  [ -f $(pathPipelineSnakefile ${1}) ]
}

function checkPipeline() {
  isParamGiven "$PIPELINE"   || errorParamNotGiven "PIPELINE"
  existsPipeline "$PIPELINE" || errorPipelineNotExist "$PIPELINE"
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
  ls */{,*/}Snakefile \
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
  export CPIPE_HOME=$(pathHome)
  export CPIPE_PIPE_NAME="$PIPELINE"
  export CPIPE_PIPE_SNAKE=$(pathPipelineSnakefile $PIPELINE)
  export PYTHONPATH=${PYTHONPATH:+${PYTHONPATH}":"}${CPIPE_HOME} 
}

# -------
# Errors
# -------
function verbecho() {
  ${VERBOSE} && printf "$@\n" || : 
}

function infecho() {
  printf "Info: $@\n"
}

function errexit() {
  printf "Error: $@\n\n"
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
