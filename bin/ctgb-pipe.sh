#!/usr/bin/env bash
export CTGB_PIPE_HOME=/mnt/storage/alexn/dev/ctgb/ctgb-pipe

# ---------------------
# Snakemake functions
# ---------------------
function set_pythonpath() {
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
function cpipe::file_add_syntax() {
  cpipe::editor_syntax >> "$1"
}
 
function cpipe::editor_syntax() {
  cat << eol 
#!/usr/bin/env python
eol
}

function cpipe::include_pipeline() {
  [ $# -eq 1 ] || exit 1
  cpipe::include_base
  cat << eol
include_pipeline("${1}")
eol
}

function cpipe::include_module() {
  [ $# -eq 1 ] || exit 1
  cat << eol
include_module("${1}")
eol
}

function cpipe::include_filetype() {
  [ $# -eq 2 ] || exit 1
  cat << eol
include_${1}("${2}")
eol
}

function cpipe::include_base() {
  cat << eol
include: "${CTGB_PIPE_HOME}/pipelines/base-config.sk"
eol
}
