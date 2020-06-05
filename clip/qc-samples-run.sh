#!/usr/bin/env bash
PRJ=OlivaS_895_AIRC_CD138_CD3
OUTDIR=/lustre1/standard-analysis/projects/OlivaS_895_AIRC_CD138_CD3
RUN=200213_A00626_0103_BHM3MHDSXX
PYPETTE_DIR=/lustre1/ctgb-usr/src/pypette
#PYPETTE_DIR=/home/anadin/dev/ctgb/pypette

# ---------
# Utilities
# ----------
toRegexOr() {
  cat /dev/stdin | tr '\n' '|' | sed -e 's/|$//' -e 's/|/\\|/g'
}

frame() {
  #
  # Narrows the STDIN list.
  # Requires index to start and number of following elements.
  #
  cat /dev/stdin             \
  | tail -n +$((0+${1:-1}))  \
  | head -n ${2:--0}
}

procNb() {
  cat /proc/cpuinfo | grep '^processor'
}

maxCores() {
  cat /proc/cpuinfo   \
   | grep '^cpu core' \
   | cut -d: -f2      \
   | sort -t= -nr -k3 \
   | head -1
}

# --------------
# Configuration
# --------------
setRawDir() {
  local lustre="${1:-2}"
  local rawDir='    rawDir:'
  local rawDirLine="^${rawDir}.*\$"
  sed -i "s|${rawDirLine}|${rawDir} \"/lustre${lustre}/raw_data\"|" config/cluster.yaml
}

# --------
# Targets
# --------
mqcTarget() {
  #
  # Unique multiqc target for all samples.
  # Type has to be specified.
  #
  ${1}MqcTarget <<< 'all'
}

mqcTargets() {
  #
  # Qc target for each sample;
  # Type has to be specified first.
  # Target indowing available. 
  #
  local type="$1" && shift
  samples $@ | ${type}MqcTarget
}

mqcTargetsSamples() {
  #
  # Qc target for each given sample.
  # Type has to be specified first.
  # Sample list is expected in STDIN
  #
  ${1}MqcTarget < /dev/stdin
}

samples() {
  #
  # Lists all available samples. Frame can be specified.
  #
  readSamples | frame ${1:+$1} ${2:+$2}
}

sample-to-idx() {
  local name=$(cat /dev/stdin)
  samples | grep -n "$name" | cut -d: -f1
}

samplesIdx() {
  #
  # Retrieves sample names by their index.
  #
  for i in $@; do
    samples $i 1
  done
}

samples-() {
  #
  # Lists available samples excluding selection from STDIN
  #
  grep -v "$(cat /dev/stdin | toRegexOr)" \
   < <(samples) \
  || samples;  
}

samplesCount() {
  samples | wc -l
}

samplesSelected() {
  samples $fromSpl $nbSpl
}

readSamples() {
  cut -d, -f1 samples/all/runs/${RUN}/samples.csv \
  | tail -n +2  \
  | sort | uniq 
}

dna-wesMqcTarget() {
  while read -r spl;
  do
    echo "samples/${spl}/runs/${RUN}/fastq/merge-by-read/trimmed/bbduk/mapped/bwa/sorted/picard/markdup/multiqc_report.html"
  done < <(cat /dev/stdin)
}

dna-wgsMqcTarget() {
  cat /dev/stdin | dna-wesMqcTarget
}

rnaseqMqcTarget() {
  while read -r spl;
  do
    echo "samples/${spl}/runs/${RUN}/fastq/merge-by-read/mapped/STAR/multiqc_report.html" 
  done < <(cat /dev/stdin)
}

# ---------
# Aligned
# ---------
alignedSamplesFiles() {
  find samples/*/runs/${RUN} -type f -name '*.Log.final.out' 
}

alignedSamples() {
  alignedSamplesFiles | cut -d/ -f2
}

# ------------
# Temp files
# ------------
TMP_REGEX='.*\.gz\|.*\.bam'
sampleTmps() {
  while read -r spl;
  do
    find samples/${spl}/runs/${RUN} -type f -regex "$TMP_REGEX"
  done < <(cat /dev/stdin)
}

samplesTmps() {
  samples | sampleTmps
}

sampleCleanTmps() {
  cat /dev/stdin \
   | sampleTmps  \
   | xargs rm
}

sampleBakTmps() {
  cat /dev/stdin \
   | sampleTmps  \
   | xargs -I{} mv {} {}.bak 
}

samplesBak() {
  find samples/*/runs/${RUN}/ -type f -regex ".*.bak"
}

genomes-tmps() {
  find genomes -type f -regex '.*\(gz\|bed\|gtf\|fa\|fasta\)'
}

clean-genomes() {
  genomes-tmps | xargs rm
}

# --------------------------
# Parameters and Variables
#
# Parameters can be variable, fixed or computed.
# Variables are parameters that can be changed by the user.
# --------------------------
VARS=(nTry fromSpl nbSpl nJobs)
vars() {
  echo "${VARS[@]}"
}

PARAMS=(${VARS[@]} rangeSpl maxSpl)
params() {
  tr ' ' '\n' <<<  ${PARAMS[@]}
}

param-value() {
  # Prints the given variable name and its value.
  while read -r param; do
    printf "$param: ${!param}\n"
  done < <(cat /dev/stdin)
}

print-params() {
  # Prints all parameters.
  printf "\n*** Parameters ***\n"
  params | param-value | tr '\n' '\t'
  printf "\n\n"
}

vars-set-dft() {
  # Sets variable parameters.
  set-ntry-fromspl-nbspl-njobs \
    1                          \
    1                          \
    $(samplesCount)            \
    $(( $nbSpl + 2 ))
}

vars-update() {
  # Updates all variable parameters with input values
  for var in $(vars); do
    var-update-noempty "$var" "$1" && shift
  done
}

var-update() {
  eval "${1}=${2}"
}

var-update-noempty() {
  # Updates the given param if the value is not empty.
  local param="$1" oldVal newVal
  oldVal="${!param}"
  newVal="${2:-$oldVal}"
  var-update "$param" "$newVal"
}

params-update() {
  # Updates (non-variable) parameters.
  rangeSpl=$(( fromSpl + nbSpl -1 ))
  [ $rangeSpl -gt $(samplesCount) ] && maxSpl=$(samplesCount) || maxSpl=$rangeSpl ;
}

set-ntry-fromspl-nbspl-njobs() {
  vars-update $@
  params-update
  print-params >&2
}

logStd() {
  printf "qc-samples-${RUN}_try${nTry}.out\n"
}

logSpls() {
  printf "qc-samples-${RUN}_s${fromSpl}-s${maxSpl}_try${nTry}.out\n"
}

grepErrorsFiles() {
  grep -i --color -A2 '^Missing\|Error' $@
}

logs() {
  \ls ./*try*.out
}

logsErrors() {
  grepErrorsFiles $(logs)
}

logsLast() {
  #
  # Gets the last try log for each log.
  #
  logs \
   | sed 's/try.*out$//' \
   | sort | uniq \
   | xargs -I{} sh -c '\ls -t {}* | head -1'
}

logsLastErrors() {
  grepErrorsFiles $(logsLast)
}

snakeOptsSet() {
  snkOpts="$1"
}

vars-set-dft
snakeOptsSet "--nolock --notemp"

snakeOptsAdd() {
  snkOpts+="$@"
}

cmdPipelineLogTargets() {
  # Defaut command for given :pipeline: and :targets:
  local pipeline log targets
  pipeline="$1" && shift 
  log="$1" && shift 
  targets="$@"
  cat << eol
  time pypette-${pipeline}  \
    --no-cluster -j $nJobs  \
    -p $PRJ -o $OUTDIR      \
    --snake-opts "$snkOpts" \
    $targets                \
    2>&1 | tee $log
eol
}

cmdQCStdPipeline() {
  # Standard QC command. Expects :pipeline: name.
  local pipeline="$1"
  cmdPipelineLogTargets "$pipeline" "$(logStd)" $(mqcTarget $pipeline) 
}

cmdQCSplsPipeline() {
  # QC command for selected samples. Expects :pipeline: name.
  local pipeline="$1"
  cmdPipelineLogTargets "$pipeline" "$(logSpls)" $(mqcTargets $pipeline $fromSpl $nbSpl) 
}

commands() {
  cat << "eol"

* Commands *
  commands
  samples; samplesCount
  
* Configuration *
  time pypette-rnaseq --no-cluster -j 6 -p $PRJ -o $OUTDIR --snake-opts "--nolock --restart-times 1" config/all.done config/project.json && \
  setRawDir 1 && \
  time pypette-rnaseq --no-cluster -j 6 -p $PRJ -o $OUTDIR --snake-opts "--nolock --restart-times 1" samples/all/runs/${RUN}/samples.csv

* Limits & Logs *
  nTry=1 ; fromSpl=1 ; nbSpl=$(($(samplesCount)-0)) ; nJobs=$(($nbSpl+2)) ; rangeSpl=$((fromSpl+nbSpl-1)) ; [ $rangeSpl -gt $(samplesCount) ] && maxSpl=$(samplesCount) || maxSpl=$rangeSpl ;
  logStd="qc-samples-${RUN}_try${nTry}.out" ; echo "logStd: '$logStd'"
  logSpls="qc-samples-${RUN}_s${fromSpl}-s${maxSpl}_try${nTry}.out" ; echo "logSpls: '$logSpls'"

* Standard targets *
  time pypette-rnaseq  --no-cluster -j $nJobs -p $PRJ -o $OUTDIR --snake-opts "--nolock --restart-times 1" $(mqcTarget rnaseq) 2>&1 | tee $logStd
  time pypette-dna-wgs --no-cluster -j $nJobs -p $PRJ -o $OUTDIR --snake-opts "--nolock --restart-times 1" $(mqcTarget dna-wgs) 2>&1 | tee $logStd

* Filter Sample Targets *
  time pypette-rnaseq  --no-cluster -j $nJobs -p $PRJ -o $OUTDIR --snake-opts "--nolock --restart-times 1" $(mqcTargets rnaseq $fromSpl $nbSpl) 2>&1 | tee $logSpls
  time pypette-dna-wgs --no-cluster -j $nJobs -p $PRJ -o $OUTDIR --snake-opts "--nolock --restart-times 1" $(mqcTargets dna-wgs $fromSpl $nbSpl) 2>&1 | tee $logSpls

eol
}

source "${PYPETTE_DIR}/bin/src-export.sh"
type pypette
commands
export OPENBLAS_NUM_THREADS=$(maxCores)
