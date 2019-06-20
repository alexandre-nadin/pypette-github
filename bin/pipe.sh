#!/usr/bin/env bash

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

# -----------------
# Command parsing
# -----------------
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

function pipe::checkParams() {
  for param in "$@"; do
     pipe::checkParam "$param"
  done
}

function pipe::checkParam() {
  pipe::isParamGiven "$1" || pipe::errorParamNotGiven "$1"
}

function pipe::isParamGiven() {
  [ ! -z ${!1:+x} ] 
}

function pipe::checkPipeline() {
  pipe::existsPipeline "$PIPELINE" || pipe::errorPipelineNotExist "$PIPELINE"
}

# ----------------
# Error Messages
# ----------------
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

