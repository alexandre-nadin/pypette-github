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
  local samples="$(samples-ls $@ | cut -d: -f2)"
  SAMPLES_SELECTED=$(echo $samples)
  clip-save-session
  echo -e "$samples"
}

samples-less ()
#
# Excludes the samples given in STDIN.
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
  local sample=$(cat /dev/stdin)
  samples-ls | grep ":${sample}\$" | cut -d: -f1
}

samples-selected ()
{
  clip-load
  tr ' ' '\n' <<< "$SAMPLES_SELECTED"
}
