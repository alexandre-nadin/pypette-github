_dir=$(readlink -f $(dirname "${BASH_SOURCE[0]}")) 
PIPELINE='seqrun'
export PATH="${PATH}:$(readlink -f ${_dir}/../bin)"

# Project
export project=PersicoA_435_Autism_Rna_Seq

# Sample (ideally covered in more than 1 run)
export sample_name=ME107A

# Run
export sample_run=181110_A00626_0013_BHFYH7DMXX

function test__samplesCsv() {
  time ctgb-pipe -p rnaseq --prj $project \
    --smk "-f samples/samples.csv --config debug=True"
}

function test__samplesSet() {
  test__samplesCsv
  csv="${WORKFLOW_DIR}/project-analysis/${project}/samples/samples.csv"
  head -n 1 "$csv" > "${csv}.tmp"       \
   && grep "ME107A\|ME108A" "$csv"      \
    >> "${csv}.tmp"                     \
   && mv "${csv}.tmp" "$csv" 
}

function test__selectSampleSet() {
  csv="$1"
  head -n 1 "$csv" > "${csv}.tmp"       \
   && grep "ME107A\|ME108A" "$csv"      \
    >> "${csv}.tmp"                     \
   && mv "${csv}.tmp" "$csv" 
}
