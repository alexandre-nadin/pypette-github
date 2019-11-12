# bash
source pypette.sh
pypette::setManual pypetype::manual

# ----------
# Workflow
# ----------
function pypetype::runFlow() {
  pypetype::initParams
  pypetype::parseParams "$@"
  pypetype::checkParams
  pypetype::exportVarenvs
  pypetype::execPipeline
}

function pypetype::exportVarenvs() {
  export FORCE
  export DEBUG
  export VERBOSE
}

# --------------
# CLI & Parsing
# --------------
pypetype__paramsMandatory=(PROJECT TARGET)

function pypetype::manual() {
  cat << eol

  DESCRIPTION
      Launches the $(pypetype::pipeline) pipeline to produce a TARGET file for the given PROJECT.

  USAGE
      $ $0 \ 
          --project PROJECT                              \ 
	  --target TARGET                                \ 
          [ --cluster-rules FILE ]                       \ 
          [ --force ]                                    \ 
          [ --outdir ]                                   \ 
          [ --keep-files-regex REGEX ]                   \ 
          [ --debug ]                                    \ 
          [ --verbose ] 

  OPTIONS
      -p|--project
          Name of the project to process.

      -t|--target
          Name of the target file to be produced by the pipeline.

      -c|--cluster-rules
          Yaml file with all the pipeline's rules for cluster execution. 
          Default is $(pypetype::clusterRulesDft).

      -f|--force
          Forces the generation of the TARGET.

      -o|--outdir
          The directory where to write output results.
  
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
function pypetype::initParams() {
  PROJECT=""
  TARGET=""
  WORKDIR="$(pwd)"
}

function pypetype::parseParams() {
  while [ $# -ge 1 ]
  do
      case "$1" in
        -p|--project)
          PROJECT="$2"                && shift
          ;;

        -t|--target)
          TARGET="$2"                 && shift 
          ;;

        -c|--cluster-rules)
          CLUSTER_RULES="$2"          && shift
          ;;

        -f|--force)
          FORCE=true
          ;;

        -o|--outdir)
          WORKDIR=$(pypette::fullPath "$2") && shift
          ;;
 
        -k|--keep-files-regex)
          KEEP_FILES_REGEX="$2"       && shift
          ;;

        --debug)
          DEBUG=true
          ;;

        -h|--help)
          pypetype::manual            && exit
          ;;
  
        -v|--verbose)
          VERBOSE=true
          ;;
  
        -*)
          pypette::errorUnrecOpt "$1"
          ;;
  
      esac
      shift
  done
}

function pypetype::checkParams() {
  pypette::requireParams ${pypetype__paramsMandatory[@]}
}

# -----------------------
# Pipeline Type Specific
# -----------------------
function pypetype::pipeline() {
  pypetype::name $(pypette::extless $(pypette::cmdName))
}

function pypetype::name() {
  printf "${1##$(pypetype::cmdPrefix)}"
}

function pypetype::cmdPrefix() {
  printf "pypette-"
}

# ---------------------
# Pipeline Execution
# ---------------------
function pypetype::execPipeline() {
  pypette::infecho "\$ $(pypetype::cmdPipeline)"
  eval $(pypetype::cmdPipeline)
}

function pypetype::cmdPipeline() {
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
function pypetype::smkParams() {
  printf "$TARGET $(pypetype::smkOptions)"
}

function pypetype::smkOptions() {
  cat << eol
  $(pypetype::smkOptionsBase)
  $(pypetype::smkOptionsCluster)
eol
}

function pypetype::smkOptionsBase() {
  cat << eol
  --jobs 32 
  --latency-wait 30 
  --rerun-incomplete
  ${FORCE:+--force}
  ${DEBUG:+--config debug=True}
eol
}

function pypetype::smkOptionsCluster() {
  ! pypetype::smkUseClusterOptions || pypetype::smkOptionsClusterStr
}

function pypetype::smkUseClusterOptions() {
  ! pypette::isParamGiven "DEBUG" 
}

function pypetype::smkOptionsClusterStr() {
  cat << eol
  --cluster-config $(pypetype::clusterRules)
  --cluster \'$(pypetype::cmdQsub)\'
eol
}

function pypetype::cmdQsub() {
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
function pypetype::clusterRules() {
  printf "${CLUSTER_RULES:-$(pypetype::clusterRulesDft)}"
}

function pypetype::clusterRulesDft() {
  pypette::fullPath "$(pypetype::clusterRulesDftTemplate)"
}

function pypetype::clusterRulesDftTemplate() {
  printf "$(pypette::cmdDir)/../pipelines/$(pypetype::pipeline)/cluster-rules.yaml"
}


