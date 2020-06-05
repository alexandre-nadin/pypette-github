#bash
CLIP_SNAPSHOT=${1:-'.clip.sh'}
CLIP_LOGDIR='logs'
  
CLIP_OUTDIR=${CLIP_OUTDIR:-$(pwd)}
CLIP_PRJ=${CLIP_PRJ:-$(basename "$CLIP_OUTDIR")}
CLIP_RUN=${CLIP_RUN:-all}

source "${CLIP_DIR}/utils.sh"
source "${CLIP_DIR}/config.sh"
source "${CLIP_DIR}/samples.sh"
source "${CLIP_DIR}/targets.sh"
source "${CLIP_DIR}/commands.sh"

clip-init ()
#
# Initializes a clip session.
#
{
  clip-set-logs
  clip-init-session
  clip-load
}

clip-set-logs ()
#
# Initializes log directory
#
{
  mkdir -p "$CLIP_LOGDIR"
}

clip-init-session ()
#
# Ensures the clip session is created.
#
{
  [ -f "$CLIP_SNAPSHOT" ] || clip-save-session
}

clip-load ()
#
# Loads a clip session
#
{
  source "$CLIP_SNAPSHOT"
}

clip-save-session () 
#
# Saves a snapshot of the last clip session.
#
{
  clip-snapshot | clip-save
}

clip-snapshot ()
#
# Takes a snapshot of variables in use.
# To be redirected in a file to be sourced later for another session.
#
{
  clip-vars | vars-declaration
}

clip-save ()
#
# Saves the SDIN in the clip snapshot file.
#
{
  cat /dev/stdin > $CLIP_SNAPSHOT
}

clip-vars() 
{
  cat << eol | xargs
    CLIP_DIR CLIP_SNAPSHOT
    CLIP_OUTDIR CLIP_PRJ CLIP_RUN 
    TARGET_PROCESS SAMPLES_SELECTED
    CMD_LAST CMD_JOBS
eol
}

clip-run ()
{
  printf "$CLIP_RUN"
}

clip-set-run ()
{
  CLIP_RUN="$1"
  clip-save-session
}

