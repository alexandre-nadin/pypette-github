# bash
source pipe.sh
pipe::setManual pipetype::manual

pipetype__TYPEXECS=(production staging local)
pipetype__paramsMandatory=(PROJECT TARGET)

# ----------
# Workflow
# ----------
function pipetype::runFlow() {
  pipetype::parseParams "$@"
  pipetype::checkParams
  pipetype::exportVarenvs
  pipetype::execPipeline
}

function pipetype::exportVarenvs() {
  export TYPEXEC
  export FORCE
  export DEBUG
  export VERBOSE
}

# --------------
# CLI & Parsing
# --------------
function pipetype::manual() {
  cat << eol

  DESCRIPTION
      Launches the $(pipetype::pipeline) pipeline to produce a TARGET file for the given PROJECT.

  USAGE
      $ $0 \ 
          --project PROJECT                              \ 
	  --target TARGET                                \ 
          [ --cluster-rules FILE ]                       \ 
          [ --typexec $(pipetype::choiceTypexec) ]         \ 
          [ --force ]                                    \ 
          [ --debug ]                                    \ 
          [ --verbose ] 

  OPTIONS
      -p|--project
          Name of the project to process.

      -t|--target
          Name of the target file to be produced by the pipeline.

      -c|--cluster-rules
          Yaml file with all the pipeline's rules for cluster execution. 
          Default is $(pipetype::clusterRulesDft).

      -x|--typexec
          The type of execution of the pipeline. Can be one among [$(pipetype::choiceTypexec)].
          Default is '${pipetype__TYPEXECS[0]}'.

      -f|--force
          Forces the generation of the TARGET.

      -o|--outdir
          The directory where to write output results.

      --debug
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
        -p|--project)
          PROJECT="$2"          && shift
          ;;

        -t|--target)
          TARGET="$2"           && shift 
          ;;

        -c|--cluster-rules)
          CLUSTER_RULES="$2"    && shift
          ;;

        -x|--typexec)
          TYPEXEC="$2"          && shift
          ;;

        -f|--force)
          FORCE=true
          ;;

        -o|--outdir)
          WORKDIR="$2" && shift
          ;;

        --debug)
          DEBUG=true
          ;;

        -h|--help)
          pipetype::manual      && exit
          ;;
  
        -v|--verbose)
          VERBOSE=true
          ;;
  
        -*)
          pipe::errorUnrecOpt "$1"
          ;;
  
      esac
      shift
  done
}

function pipetype::checkParams() {
  pipe::requireParams ${pipetype__paramsMandatory[@]}
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
  printf "Given '$1' type for --typexec option is not available. Available types are: $(pipetype::choiceTypexec)."
}

function pipetype::choiceTypexec() {
  str.join -d '|' ${pipetype__TYPEXECS[@]}
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
  printf "pypette-"
}

# ---------------------
# Pipeline Execution
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
   ${WORKDIR:+--outdir ${WORKDIR}}
   --snakemake "$(pipetype::smkParams)"
eol
}

function pipetype::cmdTypexec() {
  printf "pipe"
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
  ${FORCE:+--force}
  ${DEBUG:+--config debug=True}
eol
}

function pipetype::smkOptionsCluster() {
  ! pipetype::smkUseClusterOptions || pipetype::smkOptionsClusterStr
}

function pipetype::smkUseClusterOptions() {
  ! pipe::isParamGiven "TYPEXEC" || [ "${TYPEXEC}" != 'local' ];
}

function pipetype::smkOptionsClusterStr() {
  cat << eol
  --cluster-config $(pipetype::clusterRules)
  --cluster \'$(pipetype::cmdQsub)\'
eol
}

function pipetype::cmdQsub() {
  cat << "eol"
  qsub 
    -V 
    -N {cluster.name} 
    -l select={cluster.select}:ncpus={cluster.ncpus}:mem={cluster.mem}
eol
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


