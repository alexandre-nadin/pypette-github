#bash
SAMPLES_SELECTED=()

samples-csv ()
{
  printf -- "samples/all/runs/${CLIP_RUN}/samples.csv"
}

samples-read ()
{
  cut -d, -f1 $(samples-csv) \
  | tail -n +2               \
  | sort | uniq 
}

samples-ls () 
#
# Lists available samples with their indexes.
# Can filter on the specified indexes.
#
{
  local idxes idxRegex
  idxes=$(tr ' ' '\n' <<< "$@")
  idxRegex=$(grepLineNbRegex <<< "$idxes" | orRegex)
  samples-read  \
  | grep -n '^' \
  | grep "${idxes:+$idxRegex}"
}

samples ()
{
#
# Lists all available sample names. 
# Index filtering is available.
#
  samples-ls $@ | cut -d: -f2
}

samples-select ()
#
# Selects the samples with the given indexes.
# Updates sample selection.
#
{
  local samples="$(samples $@)"
  SAMPLES_SELECTED=$(echo $samples)
  clip-save-session
  echo -e "$samples"
}

samples-less ()
#
# Excludes the samples given in STDIN.
# Updates sample selection.
#
{
  local samples="$(
          grep -v "$(cat /dev/stdin | sed '/^$/d' | orRegex)" \
            < <(samples) \
          || samples)"
  SAMPLES_SELECTED=$(echo $samples)
  clip-save-session
  echo -e "$samples"
}

samples-to-index ()
#
# Gets the serial number of the given :sample: name.
#
{
  while read -r sample; do
    samples-ls | grep ":${sample}\$" | cut -d: -f1
  done < <(cat /dev/stdin)
}

samples-count ()
{
  samples | wc -l
}

samples-selected ()
#
# Lists all previously selected samples.
#
{
  clip-load
  tr ' ' '\n' <<< "$SAMPLES_SELECTED"
}

samples-are-all-selected ()
#
# Tells whether all the samples were previously selected.
#
{
  [ $(samples-selected | wc -l) -eq $(samples | wc -l) ]
}

# ------------
# Temporaries
# ------------
SPLS_TMP_EXTS='gz\|bam'
sample-tmps ()
#
# Lists all temporaries for the samples given in stdin
#
{
  for spl in $(cat /dev/stdin); do
    find samples/${spl}/runs/$(clip-run) -type f -regex ".*\.\(${SPLS_TMP_EXTS}\)"
  done
}

samples-tmps ()
#
# Lists all the temporaries for all samples.
#
{
  samples | sample-tmps
}

sample-rm-tmps ()
#
# Removes all temporaries for samples given in STDIN.
#
{
  cat /dev/stdin | sample-tmps | xargs rm
}

GNMS_TMP_EXTS='gz\|bed\|gtf\|fa\|fasta'
genomes-tmps()
#
# Lists all temporaries for genomes.
#
{
  find genomes -type f -regex ".*\(${GNMS_TMP_EXTS}\)"
}

genomes-rm-temps()
#
# Removes all temporaries for genomes.
#
{
  genomes-tmps | xargs rm
}
