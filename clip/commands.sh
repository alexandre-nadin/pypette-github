#bash
nJobs=2
log="log.out"
snkOpts="-n"

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
    --no-cluster -j $nJobs  \
    -p $PRJ -o $OUTDIR      \
    --snake-opts "$snkOpts" \
    $targets                \
    2>&1 | tee $(cmd-log)
eol
}

cmd-log ()
{
  clip-load
  printf "${LOG_DIR}/$(target-process)__run_$(target-run)__spls_$(target-samples)__$(timestamp).out"
}

# Register all wrappers to pypette executables
for cmd in $(cmds-pypette); do 
  cmd-register "$cmd"
done

