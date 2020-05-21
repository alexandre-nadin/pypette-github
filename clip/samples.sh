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
  samples-ls $@ \
  | cut -d: -f2
}

