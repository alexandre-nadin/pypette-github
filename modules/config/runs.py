def runs__projectPaths(project):
  """
  Gets each project run path.
  """
  return [ 
    os.path.join(run, f"{project}" )
    for run in runs__paths()
  ]

def runs__paths(check_runs=False):
  """
  Retrieves the runs' directory.
  Checks their existence is 'check_runs' (default).
  """
  runs_dirs = [ 
    runs__path(runid)
    for runid in pypette.config.project.runIds
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
    pypette.config.cluster.sequencingRuns.rawDir, 
    runid)
   
def runs__checkRuns(runs=[]):
  """
  Checks the given run paths exist.
  Logs non-blocking warnings before raising the error.
  """
  error = False
  for run in runs:
    if not os.path.isdir(run):
      pypette.log.error(f"Run {run} doesn't exist.")
      error = True
  if error: 
    raise

def runs__runFromFilepath(filepath):
  """ 
  Retrieves a Run id from a file containing paths. 
  """
  for run in pypette.config.project.runIds:
    run_path = runs__path(run)
    if filepath.startswith(run_path):
      return run
    else:
      continue

def runs__samplesheet(runid):
  """
  Retrieve the samplesheet used in the given :runid:.
  """
  return os.path.join(
    runs__path(runid),
    "samplesheet.csv")

def runs__prjPath(runid):
  return os.path.join(runs__path(runid), pypette.project)
