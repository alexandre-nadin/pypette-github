def core__subCmd(pipeline, project, target):
  """ Returns a pypette sub-command string to be executed """
  return f"""
    pypette-{pipeline}    \
      --project {project} \
      --target {target}
  """

def core__smkCmd(target):
  """ Default snakemake command to execute. """
  return f"""
    {target} {core__debugOptions()}
  """

def core__debugOptions():
  """ Defaut Snakemake debug option """
  if config.debug and config.debug in [True, False]:
    ret = f"--config debug={config.debug}" 
  else:
    ret = ''
  return ret
