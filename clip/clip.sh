#bash

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
  [ -f "$CLIP_SNAPSHOT" ] || touch "$CLIP_SNAP_SHOT"
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
  echo CLIP_DIR PRJ OUTDIR RUN
}

