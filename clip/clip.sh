#bash
CLIP_SNAPSHOT=${1:-'clip'}
CLIP_LOGDIR='logs'
CLIP_SNAPDIR='clip'
  
CLIP_OUTDIR=${CLIP_OUTDIR:-$(pwd)}
CLIP_PRJ=${CLIP_PRJ:-$(basename "$CLIP_OUTDIR")}
CLIP_RUN=${CLIP_RUN:-all}

# ---------------
# CLIP Session
# ---------------

clip-init ()
#
# Initializes a clip session.
#
{
  clip-source-modules
  clip-set-logs
  clip-init-session
  clip-load
  target-load-custom
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
  [ -f "$(clip-snapshot-file)" ] || clip-save-session
}

clip-load ()
#
# Loads a clip session
#
{
  source "$(clip-snapshot-file)"
}

clip-snapshot-file ()
#
# Prints the path of the current clip snapshot session.
#
{
  printf -- "${CLIP_SNAPDIR}/${CLIP_SNAPSHOT}.sh"
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
# Saves the STDIN in the clip snapshot file.
#
{
  mkdir -p "$CLIP_SNAPDIR"
  cat /dev/stdin > "$(clip-snapshot-file)"
}

# --------
# Modules
# --------
CLIP_MODULES=(
  clip.sh
  samples.sh
  genomes.sh
  targets.sh
  commands.sh
  utils.sh
)

clip-source-modules ()
#
# Sources all the clip modules.
#
{
  for module in $(clip-modules-path); do
    source $module $CLIP_SNAPSHOT
  done
}

clip-modules-path ()
#
# Lists the absolute path for all clip modules.
#
{
  clip-modules | clip-module-path
}

clip-modules ()
#
# Lists all the clip modules.
#
{
  tr ' ' '\n' <<< ${CLIP_MODULES[@]}
}

clip-module-path ()
#
# Gives the absolute path of the given clip module.
# Reads from STDIN.
#
{
  while read -r module; do
    printf "${CLIP_DIR}/${module}\n"
  done < <(cat -)
}

# -------------------
# Session Variables
# -------------------

CLIP_SESSION_VARS=(
  CLIP_DIR 
  CLIP_OUTDIR
  CLIP_SNAPSHOT
  CLIP_PRJ
  CLIP_RUN 
  TARGET_PROCESS
  SAMPLES_SELECTED
  CMD_JOBS 
  CMD_SNAKE_OPTS
  CMD_LAST
)

clip-vars () 
#
# Prints all clip variables in use.
#
{
  echo ${CLIP_SESSION_VARS[@]}
}

clip-session ()
#
# Lists all clip session variables in use.
#
{
  cat << eol >&2
*********************
* SESSION VARIABLES *
*********************
$(clip-vars | vars-ls 2)


eol
}

clip-run ()
#
# Shows the current sequencing run.
#
{
  printf -- "$CLIP_RUN"
}

clip-set-run ()
#
# Sets the sequencing run.
#
{
  CLIP_RUN="$1"
  clip-save-session
}

# ---------------
# Documentation
# ---------------
clip-manual ()
#
# Manual for CLIP
#
{
  cat << eol

*********************************************
*
* CLIP - Command Line Interface for Pypette
*
*********************************************

------------
- SYNOPSIS -
------------

Clip provides pipeable tools to apply pypette pipelines to specific samples.

Clip helps you to:
  * Filter pypette samples
  * Generate standard and custom process targets
  * Declare pipeable functions to create custom template targets
  * Produce a pypette command with default options
  * Produce a default log file registering all the command output

---------------
- GET STARTED -
---------------
Functions:
  clip-manual  : displays this manual
  clip-cmds    : displays available functions with their documentation
  clip-session : displays variable info about current CLIP session 

-------------
- MORE INFO -
-------------
Doc & Tutorial: https://bitbucket.org/cosrhsr/pypette/wiki/clip

eol
}

# ---------
# Commands
# ---------
CLIP_USER_CMDS=()

clip-cmds ()
#
# Lists clip user functions with documentation.
#
{
  clip-cmds-all ${CLIP_USER_CMDS[@]}
}

clip-add-usr-cmds ()
#
# Adds a command to the list of available user commands.
#
{
  CLIP_USER_CMDS+=($@)
}

clip-cmds-all ()
#
# Lists exhaustively all clip functions with documentation.
#
{
  cat $(clip-modules-path) | func-doc $@
}

# --------------
# User Commands
# --------------
clip-add-usr-cmds                    \
  clip-manual clip-session clip-cmds \
  clip-run clip-set-run 
