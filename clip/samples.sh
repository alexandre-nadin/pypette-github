#bash
samplesSelected=()

samples-csv ()
{
  printf "samples/all/runs/${RUN}/samples.csv"
}

samples-read ()
{
  cut -d, -f1 $(samples-csv) \
  | tail -n +2               \
  | sort | uniq 

}

samples-ls () 
{
  #
  # Lists available samples with their indexes.
  # Can filter on the specified indexes.
  #
  local idxes idxRegex
  idxes=$(tr ' ' '\n' <<< "$@")
  idxRegex=$(orRegex <<< "$idxes")
  samples-read  \
  | grep -n '^' \
  | grep "${idxRegex:+$idxRegex}"
}

samples ()
{
  #
  # Lists all available sample names. 
  # Index filtering is available.
  #
  local samples="$(samples-ls $@ | cut -d: -f2)"
  samplesSelected=$(echo $samples)
  echo -e "\n[samples]" >&2
  clip-save-session
  echo -e "[samples]" >&2
  echo -e "  samples: '$samples'" >&2
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
  samplesSelected=$(echo $samples)
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
  echo -e "samplesSelected: '$samplesSelected'" >&2
  tr ' ' '\n' <<< "$samplesSelected"
}
