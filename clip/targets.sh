#bash
TARGET_PROCESS=""

target-set-process()
{
  TARGET_PROCESS="$1"
  clip-save-session
}

target-process()
{
  printf "$TARGET_PROCESS"
}

target-samples ()
#
# Gets the indexes of the selected samples.
# Links them in one string.
#
{
  samples-selected | samples-to-index| tr '\n' '_' | sed 's/_$//'
}

target-build-function ()
  #
  # Creates the recipe for a pipeable function that builds the given :target:
  #
{
  local name="$1" target="$2"
  cat << eol
target-${name} ()
{ 
  local sample_run="\$(clip-run)"
  while read -r sample_name; do
    clip-load
    target-set-process "$name" 
    clip-save-session
    printf "${target}\n"
  done 
}
eol
}

target-register ()
  #
  # Registers the given :target: in a function.
  #
{
  eval "$(target-build-function $@)"
}

target-register multiqc-rnaseq 'samples/${sample_name}/runs/${sample_run}/fastq/merge-by-read/mapped/STAR/multiqc_report.html'

target-register multiqc-dna-wes 'samples/${sample_name}/runs/${sample_run}/fastq/merge-by-read/trimmed/bbduk/mapped/bwa/sorted/picard/markdup/multiqc_report.html'

target-register multiqc-dna-wgs 'samples/${sample_name}/runs/${sample_run}/fastq/merge-by-read/trimmed/bbduk/mapped/bwa/sorted/picard/markdup/multiqc_report.html'
