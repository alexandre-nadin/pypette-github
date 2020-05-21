#bash

target-build-function ()
  #
  # Creates the recipe for a pipeable function that builds the given :target:
  #
{
  local name="$1" target="$2"
  cat << eol
target-${name} ()
{
  while read -r sample_name; do
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

target-register multiqc-rnaseq 'samples/${sample_name}/runs/${RUN}/fastq/merge-by-read/mapped/STAR/multiqc_report.html'

target-register multiqc-dna-wes 'samples/${sample_name}/runs/${RUN}/fastq/merge-by-read/trimmed/bbduk/mapped/bwa/sorted/picard/markdup/multiqc_report.html'

target-register multiqc-dna-wgs 'samples/${sample_name}/runs/${RUN}/fastq/merge-by-read/trimmed/bbduk/mapped/bwa/sorted/picard/markdup/multiqc_report.html'
