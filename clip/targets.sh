#bash
TARGET_PROCESS=""

target-set-process ()
{
  TARGET_PROCESS="$1"
  clip-save-session
}

target-process ()
{
  printf -- "$TARGET_PROCESS"
}

target-samples ()
#
# Gets the indexes of the selected samples.
# Links them in one string.
#
{
  if samples-are-all-selected; then
    printf 'all'
  else
    samples-selected | samples-to-index | str-join '_'
  fi
}

target-build-function ()
#
# Creates the recipe for a pipeable function that builds the given :target:
# Registers the target in user commands.
#
{
  local name="$1" target="$2" funcname=''
  funcname="target-${name}"
  clip-add-usr-cmds $funcname
  cat << eol
${funcname} ()
#
# Target for the ${name} process.
#
{ 
  local sample_run="\$(clip-run)"
  while read -r sample_name; do
    clip-load
    target-set-process "$name" 
    clip-save-session
    printf -- "${target}\n"
  done 
}
eol
}

target-register ()
#
# Registers the given :target: in a function.
# Parameters:
#   $1: target name, reflects a process such as 'multiqc-rnasq'
#   $2: target, for example 'samples/${sample_name}/runs/${sample_run}/fastq/merge-by-read/mapped/STAR/multiqc_report.html'
#       Note that arguments are single-quoted to avoid the shell substituting sample_name and sample_run during the function declaration.
#
{
  eval "$(target-build-function $@)"
}

clip-add-usr-cmds                   \
  target-process target-set-process \
  target-register

target-register multiqc-rnaseq 'samples/${sample_name}/runs/${sample_run}/fastq/merge-by-read/mapped/STAR/multiqc_report.html'

target-register multiqc-dna-wes 'samples/${sample_name}/runs/${sample_run}/fastq/merge-by-read/trimmed/bbduk/mapped/bwa/sorted/picard/markdup/multiqc_report.html'

target-register multiqc-dna-wgs 'samples/${sample_name}/runs/${sample_run}/fastq/merge-by-read/trimmed/bbduk/mapped/bwa/sorted/picard/markdup/multiqc_report.html'

