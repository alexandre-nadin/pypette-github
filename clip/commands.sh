#bash
CMD_LAST=''
CMD_JOBS=1
CMD_SNAKE_OPTS=""

cmd-set-last ()
#
# Sets and saves the last command executed.
#
{
  CMD_LAST="$1"
  clip-save-session
}

cmd-last ()
#
# Prints the last command executed.
# Selected samples, target process and last command have to be registered.
#
{
  clip-load
  samples-selected | target-$(target-process) | cmd-${CMD_LAST}
}

cmds-pypette ()
#
# Lists available pypette commands
#
{
  \ls ${CLIP_DIR}/../bin/pypette-* \
  | xargs -I{} basename {}
}

cmd-register ()
#
# Registers the given :cmd: in a wrapper function.
#
{
  eval "$(cmd-build-func $1)"
}

cmd-build-func ()
#
# Creates the recipe for a pipeable function that wraps the given executable :cmd: name.
#
{
  local cmd="$1"
  cat << eol
cmd-${cmd} ()
{
  local targets=\$(cat /dev/stdin | xargs)
  clip-load
  cmd-set-last ${cmd}
  clip-save-session
  cat << _eol
  time ${cmd} $(cmd-parameters)
_eol
}
eol
}

cmd-parameters ()
#
# Returns the default parameters for a pypette command.
#
{
  cat << 'eol'
    --no-cluster -j $(cmd-jobs)      \
    -p $CLIP_PRJ -o $CLIP_OUTDIR     \
    --snake-opts "$(cmd-snake-opts)" \
    $targets                \
    2>&1 | tee $(cmd-log)
eol
}

cmd-log ()
#
# Sets the command log for the piped command.
#
{
  clip-load
  printf -- "${CLIP_LOGDIR}/$(target-process)__run_$(clip-run)__spls_$(target-samples)__$(timestamp).out"
}

cmd-set-jobs ()
{
  CMD_JOBS="$1"
  clip-save-session
}

cmd-jobs ()
{
  local maxMem freeMem jobs
  maxMem=32
  freeMem=$(freeMem)
  if [ $freeMem -gt 0 ]; then
    jobs=$((freeMem/maxMem))
  else
    jobs=1
  fi
  printf -- ${CMD_JOBS:-$jobs}
}

cmd-snake-opts ()
{
  printf -- "$CMD_SNAKE_OPTS"
}

cmd-set-snake-opts ()
{
  CMD_SNAKE_OPTS="$@"
  clip-save-session
}

# Register all wrappers for pypette executables
for cmd in $(cmds-pypette); do 
  cmd-register "$cmd"
done
