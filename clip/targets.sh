#bash
TARGET_PROCESS=""

target-set-process ()
#
# Sets the current process.
#
{
  TARGET_PROCESS="$1"
  clip-save-session
}

target-process ()
#
# Shows the current target process.
#
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
${funcname}-str ()
#
# Target string for the ${name} process.
#
{
  printf '$target'
}

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

# -----------------
# Standard Targets
# -----------------
target-register multiqc-rnaseq 'samples/${sample_name}/runs/${sample_run}/fastq/merge-by-read/mapped/STAR/multiqc_report.html'

target-register multiqc-dna-wes 'samples/${sample_name}/runs/${sample_run}/fastq/merge-by-read/trimmed/bbduk/mapped/bwa/sorted/picard/markdup/multiqc_report.html'

target-register multiqc-dna-wgs 'samples/${sample_name}/runs/${sample_run}/fastq/merge-by-read/trimmed/bbduk/mapped/bwa/sorted/picard/markdup/multiqc_report.html'

# ---------------
# Custom Targets
# ---------------
TARGETS_FILE="${CLIP_SNAPDIR}/targets.sh"

target-load-custom ()
#
# Loads custom targets.
#
{
  [ -f "$TARGETS_FILE" ] || touch "$TARGETS_FILE"
  source "$TARGETS_FILE"
}

target-register-custom ()
#
# Registers the given :target: in a function.
# Parameters:
#   $1: target name, reflects a process such as 'multiqc-rnasq'
#   $2: target, for example 'samples/${sample_name}/runs/${sample_run}/fastq/merge-by-read/mapped/STAR/multiqc_report.html'
#       Note that arguments are single-quoted to avoid the shell substituting sample_name and sample_run during the function declaration.
# The target declaration will be saved in your cutom target file and will be loaded at each new CLIP session. Check it in : $ targets-file.
#
{
  if target-register "$@"; then
    target-save-custom "$@"
  else
    printf "Something went wrong with registering target $@" >&2
    return 1
  fi
}

targets-file ()
{
  printf -- "$TARGETS_FILE\n"
}

target-save-custom ()
#
# Saves custom targets for future sessions.
#
{
  local name="$1" target="$2"
  printf -- "target-register $name '$target'\n" >> "$TARGETS_FILE"
}

# --------------
# User Commands
# --------------
clip-add-usr-cmds                   \
  target-process target-set-process \
  target-register-custom targets-file
