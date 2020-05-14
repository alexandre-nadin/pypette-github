# bash
source pypette.sh
pypette::setManual pypetype::manual

# ----------
# Workflow
# ----------
pypetype::runFlow() {
  pypetype::initParams
  pypetype::parseParams "$@"
  pypetype::checkParams
  pypetype::exportVarenvs
  pypetype::execPipeline
}

pypetype::exportVarenvs() {
  export FORCE
  export DEBUG
  export VERBOSE
}

# --------------
# CLI & Parsing
# --------------
pypetype__paramsMandatory=(PROJECT TARGET)

pypetype::manual() {
  cat << eol

  PYPETTE v$(pypette::version)

  DESCRIPTION
      Launches the $(pypetype::pipeline) pipeline to produce TARGET files for the given PROJECT.

  USAGE
      $ $0 \ 
          TARGET [TARGET ...]                            \ 
          --project|-p PROJECT                           \ 
          [ --cluster-rules FILE ]                       \ 
          [ --no-cluster ]                               \ 
          [ --cores|--jobs|-j N ]                        \ 
          [ --force ]                                    \ 
          [ --outdir ]                                   \ 
          [ --snake-opts SNAKE_OPTION ...]               \ 
          [ --keep-files-regex REGEX ]                   \ 
          [ --debug ]                                    \ 
          [ --verbose ]

  OPTIONS
      TARGET
          Targets to build. May be rules or files.

      -p|--project
          Name of the project to process.

      -c|--cluster-rules
          Yaml file with all the pipeline's rules for cluster execution.
          Default is $(pypetype::clusterRulesDft).

      --no-cluster
          Executes every job on this machine. Cluster options are not forwarded.

      --cores|--jobs|-j
          Max number of cores in parallel.

      -f|--force
          Forces the generation of the TARGET.

      -o|--outdir
          The directory where to write output results.
 
      --snake-opts
          List of options to pass to Snakemake

      -k|--keep-files-regex
          The regex pattern of the temporary files to keep (ex.: '.*merged/.*bam').

      --debug
          Execute the pipeline in debug mode.

      -v|--verbose
          Makes this command verbose.

      -h|--help
          Displays this help manual.


eol
}

# -----------
# Parameters
# -----------
pypetype::initParams() {
  PROJECT=""
  TARGET=()
  SNAKE_OPTIONS=()
  WORKDIR="$(pwd)"
  USE_CLUSTER=true
  MAX_CORES=""
}

pypetype::parseParams() {
  while [ $# -ge 1 ]; do
    case "$1" in
      -p|--project)
        PROJECT="$2" && shift
        ;;

      -c|--cluster-rules)
        CLUSTER_RULES="$2" && shift
        ;;

      --no-cluster)
        USE_CLUSTER=false
        ;;

      --cores|--jobs|-j)
        MAX_CORES="$2" && shift
        ;;

      -f|--force)
        FORCE=true
        ;;

      -o|--outdir)
        WORKDIR=$(pypette::fullPath "$2") && shift
        ;;

      --snake-opts)
        SNAKE_OPTIONS+=("$2") && shift
        ;;

      -k|--keep-files-regex)
        KEEP_FILES_REGEX="$2" && shift
        ;;

      --debug)
        DEBUG=true
        ;;

      -h|--help)
        pypetype::manual && exit
        ;;

      -v|--verbose)
        VERBOSE=true
        ;;

      -*)
        pypette::errorUnrecOpt "$1"
        ;;

      *)
        TARGET+=($1)
        ;;

    esac
    shift
  done
}

pypetype::checkParams() {
  pypette::requireParams ${pypetype__paramsMandatory[@]}
}

# -----------------------
# Pipeline Type Specific
# -----------------------
pypetype::pipeline() {
  pypetype::name $(pypette::extless $(pypette::cmdName))
}

pypetype::name() {
  printf "${1##$(pypetype::cmdPrefix)}"
}

pypetype::cmdPrefix() {
  printf "pypette-"
}

# ---------------------
# Pipeline Execution
# ---------------------
pypetype::execPipeline() {
  pypette::infecho "\$ $(pypetype::cmdPipeline)"
  eval $(pypetype::cmdPipeline)
}

pypetype::cmdPipeline() {
  cat << eol | tr '\n' ' '
    $(pypette::cmdDir)/pypette
   -p $(pypetype::pipeline)
   --project $PROJECT
   ${WORKDIR:+--outdir ${WORKDIR}}
   ${KEEP_FILES_REGEX:+--keep-files-regex ${KEEP_FILES_REGEX}}
   --snakemake "$(pypetype::smkParams)"
eol
}

# -------------------
# Snakemake Options
# -------------------
pypetype::smkParams() {
   printf ' %s' "${TARGET[@]} $(pypetype::smkOptions)"
}

pypetype::smkOptions() {
  cat << eol
  $(pypetype::smkOptionsBase)
  $(pypetype::smkOptionsCluster)
eol
}

pypetype::smkOptionsBase() {
  cat << eol
  ${MAX_CORES:+--jobs $MAX_CORES}
  --latency-wait 90
  --rerun-incomplete
  ${SNAKE_OPTIONS:+${SNAKE_OPTIONS[@]}}
  ${FORCE:+--force}
  ${DEBUG:+--config debug=True}
eol
}

pypetype::smkOptionsCluster() {
  ! pypetype::smkUseClusterOptions || pypetype::smkOptionsClusterStr
}

pypetype::smkUseClusterOptions() {
  ! pypette::isParamGiven "DEBUG" && $USE_CLUSTER
}

pypetype::smkOptionsClusterStr() {
  cat << eol
  --cluster-config $(pypetype::clusterRules)
  --cluster \'$(pypetype::cmdQsub)\'
eol
}

pypetype::cmdQsub() {
  cat << "eol"
  qsub
    -V
    -N {cluster.name}
    -l select={cluster.select}:ncpus={cluster.ncpus}:mem={cluster.mem}
    -o {cluster.out}
    -e {cluster.err}
eol
}


# --------------------
# Cluster Ressources
# --------------------
pypetype::clusterRules() {
  printf "${CLUSTER_RULES:-$(pypetype::clusterRulesDft)}"
}

pypetype::clusterRulesDft() {
  pypette::fullPath "$(pypetype::clusterRulesDftTemplate)"
}

pypetype::clusterRulesDftTemplate() {
  printf "$(pypette::cmdDir)/../pipelines/$(pypetype::pipeline)/cluster-rules.yaml"
}
