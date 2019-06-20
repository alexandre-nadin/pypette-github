#!/usr/bin/env bash
source pipe.sh
pipe::setManual pipetype::manual

pipetype__TYPEXECS=(staging local)
pipetype__paramsMandatory=(PROJECT TARGET)

# --------------
# CLI & Parsing
# --------------
function pipetype::manual() {
  cat << eol

  DESCRIPTION
      Launches the $(pipetype::pipeline) pipeline for the given PROJECT.

  USAGE
      $ $0                   \ 
          --project PROJECT           \ 
          --target TARGET             \ 
          [ --cluster-rules FILE ]    \ 
          [ --typexec $(str.join -d '|' ${pipetype__TYPEXECS[@]}) ] \ 
          [ -d|--debug ]              \ 
          [ -v|--verbose ] 

  OPTIONS
      --project
          Name of the project to analyze.

      --target
          Name of the target file.

      --cluster-rules
          Yaml file with all the pipeline's rules for cluster execution. 
          Default is $(pipetype::clusterRulesDft).

      --typexec
          The type of execution of the pipeline. Can be one among [ ${pipetype__TYPEXECS[@]} ].

      -d|--debug
          Execute the pipeline in debug mode.

      -v|--verbose
          Makes this command verbose.

      -h|--help
          Displays this help manual.
eol
}

function pipetype::parseParams() {
  while [ $# -ge 1 ]
  do
      case "$1" in
        --project)
          PROJECT="$2"          && shift
          ;;

        --target)
          TARGET="$2"           && shift 
          ;;

        --cluster-rules)
          CLUSTER_RULES="$2"    && shift
          ;;

        --typexec)
          TYPEXEC="$2"          && shift
          ;;

        -d|--debug)
          DEBUG=true
          ;;

        -h|--help)
          pipetype::manual      && exit
          ;;
  
        -v|--verbose)
          VERBOSE=true
          ;;
  
        *)
          pipe::errorUnrecOpt "$1"
          ;;
  
      esac
      shift
  done
}

function pipetype::checkParams() {
  pipe::checkParams ${pipetype__paramsMandatory[@]}
  pipetype::checkTypexec
}

function pipetype::checkTypexec() {
  [ -z ${TYPEXEC:+x} ] \
    || pipetype::matchTypexec "$TYPEXEC" \
    || pipe::errexit "$(pipetype::msgTypexecNotExist ${TYPEXEC})"
}

function pipetype::matchTypexec() {
  \grep  -qs " $1 " <<< " ${pipetype__TYPEXECS[@]} "
}

function pipetype::msgTypexecNotExist() {
  printf "Given '$1' type for --typexec option is not available."
}

# -----------------------
# Pipeline Type Specific
# -----------------------
function pipetype::pipeline() {
  pipetype::name $(pipe::extless $(pipe::cmdName))
}

function pipetype::name() {
  printf "${1##$(pipetype::cmdPrefix)}"
}

function pipetype::cmdPrefix() {
  printf "pipe-"
}

# ---------------------
# CTGB Pipe Execution
# ---------------------
function pipetype::execPipeline() {
  pipe::infecho "\$ $(pipetype::cmdPipeline)"
  eval $(pipetype::cmdPipeline)
}

function pipetype::cmdPipeline() {
  cat << eol | tr '\n' ' '
  $(pipetype::cmdTypexec)
   -p $(pipetype::pipeline)
   --project $PROJECT 
   --snakemake "$(pipetype::smkParams)"
eol
}

function pipetype::cmdTypexec() {
  printf "cpipe${TYPEXEC:+-$TYPEXEC}"
}

function pipetype::cmdQsub() {
  cat << "eol"
  qsub 
    -V 
    -N {cluster.name} 
    -l select={cluster.select}:ncpus={cluster.ncpus}:mem={cluster.mem}
eol
}

# -------------------
# Snakemake Options
# -------------------
function pipetype::smkParams() {
  printf "$TARGET $(pipetype::smkOptions)"
}

function pipetype::smkOptions() {
  cat << eol
  $(pipetype::smkOptionsBase)
  $(pipetype::smkOptionsCluster)
eol
}

function pipetype::smkOptionsBase() {
  cat << eol
  --jobs 32 
  --latency-wait 30 
  --rerun-incomplete
  ${DEBUG:+--config debug=${DEBUG}}
eol
}

function pipetype::smkOptionsCluster() {
  ! pipetype::smkUseClusterOptions || pipetype::smkOptionsClusterStr
}

function pipetype::smkOptionsClusterStr() {
  cat << eol
  --cluster-config $(pipetype::clusterRules)
  --cluster \'$(pipetype::cmdQsub)\'
eol
}

function pipetype::smkUseClusterOptions() {
  ! pipe::isParamGiven "TYPEXEC" || [ "${TYPEXEC}" != 'local' ];
}


# --------------------
# Cluster Ressources
# --------------------
function pipetype::clusterRules() {
  printf "${CLUSTER_RULES:-$(pipetype::clusterRulesDft)}"
}

function pipetype::clusterRulesDft() {
  readlink -f "$(pipetype::clusterRulesDftTemplate)"
}

function pipetype::clusterRulesDftTemplate() {
  printf "$(pipe::cmdDir)/../pipelines/$(pipetype::pipeline)/cluster-rules.yaml"
}


