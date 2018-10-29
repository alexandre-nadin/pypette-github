#!/usr/bin/env bash
export CTGB_PIPE_HOME=/mnt/storage/alexn/dev/ctgb/ctgb-pipe

# ---------------------
# Snakemake functions
# ---------------------
function setPythonpath() {
  export PYTHONPATH=${PYTHONPATH}:${CTGB_PIPE_HOME} 
}
function snakemake() {
  export PYTHONPATH=${PYTHONPATH}:${CTGB_PIPE_HOME} 
  command snakemake $@
}

function smk() {
  export PYTHONPATH=${PYTHONPATH}:${CTGB_PIPE_HOME} 
  command snakemake $@
}

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
