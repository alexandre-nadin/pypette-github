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
  If :runid: found in several rawDirs, considers the first valid path found.
  Accepts a single path as well as a list of paths.
  """ 
  runPath = None
  rawDirs = pypette.config.cluster.sequencingRuns.rawDirs
  rawDirs = [ rawDirs ] if type(rawDirs) is str else rawDirs
  for rawDir in rawDirs:
    runPathTmp = os.path.join(rawDir, runid)
    if os.path.exists(runPathTmp):
      runPath = runPathTmp
      break
  if not runPath:
    pypette.log.info(f"No path found for run '{runid}'. Check your rawDirs in your cluster configuration ({rawDirs}).")
  return runPath
   
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

def runs__samplesheet(runid):
  """
  Retrieve the samplesheet used in the given :runid:.
  """
  runPath = runs__path(runid)
  ssheet = None
  if runPath:
    ssheet = os.path.join(runPath, "samplesheet.csv")
  return ssheet

def runs__prjPath(runid):
  return os.path.join(runs__path(runid), pypette.project)
