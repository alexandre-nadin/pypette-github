def runs__projectPaths(prj):
  """
  Gets each project run path.
  """
  return [ 
    os.path.join(
      run, 
      "{}{}/".format(
        runs__projectTag(),
        prj))
    for run in runs__paths()
  ]

def runs__projectTag():
  if pipeman.config.cluster.sequencingRuns.structured:
    tag = pipeman.config.cluster.sequencingRuns.projectTag 
  else:
    tag = ""
  return tag

def runs__paths(check_runs=True):
  """
  Retrieves the runs' directory.
  Checks their existence is 'check_runs' (default).
  """
  runs_dirs = [ 
    runs__path(runid)
    for runid in pipeman.config.project.run_ids
  ] 
  if check_runs:
    runs__checkRuns(runs_dirs)
  return runs_dirs

@cluster__prefixMountPoint
def runs__path(runid):
  """
  Builds the path of the given runid.
  """
  return os.path.join(
    pipeman.config.cluster.sequencingRuns.dir, 
    runid)
   
def runs__checkRuns(runs=[]):
  """
  Checks the given run paths exist.
  Logs non-blocking warnings before raising the error.
  """
  error = False
  for run in runs:
    if not os.path.isdir(run):
      pipeman.log.error("Run {} doesn't exist.".format(run))
      error = True
  if error: 
    raise

def runs__runFromFilepath(filepath):
  """ 
  Retrieves a Run id from a file containing paths. 
  """
  for run in pipeman.config.project.run_ids:
    run_path = runs__path(run)
    if filepath.startswith(run_path):
      return run
    else:
      continue
