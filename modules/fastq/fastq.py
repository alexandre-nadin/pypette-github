import os
from utils.fastq_helper import FastqFile
from utils.files import touch

pipeman.includeModule("cluster/cluster.py")

def fastq__runsPathsProject(prj):
  """
  Gets each project run path.
  """
  return [ 
    os.path.join(
      run, 
      "{}{}/".format(
        fastq__runProjectTag(),
        prj))
    for run in fastq__runsPaths()
  ]

def fastq__runProjectTag():
  if pipeman.config.cluster.sequencingRuns.structured:
    tag = pipeman.config.cluster.sequencingRuns.projectTag 
  else:
    tag = ""
  return tag

@cluster__prefixMountPoint
def fastq__runPath(runid):
  """
  Builds the path of the given runid.
  """
  return os.path.join(
    pipeman.config.cluster.sequencingRuns.dir, 
    runid)
   
def fastq__runsPaths(check_runs=True):
  """
  Retrieves the runs' directory.
  Checks their existence is 'check_runs' (default).
  """
  runs_dirs = [ 
    fastq__runPath(runid)
    for runid in pipeman.config.project.run_ids
  ] 
  if check_runs:
    fastq__checkRuns(runs_dirs)
  return runs_dirs

def fastq__checkRuns(runs=[]):
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

def fastq__runFromFilepath(filepath):
  """ 
  Retrieves a Run id from a file containing paths. 
  """
  for run in pipeman.config.project.run_ids:
    run_path = fastq__runPath(run)
    if filepath.startswith(run_path):
      return run
    else:
      continue

def fastq__mapFilename(filename):
  """
  Maps the illumina metadata based on the given filename.
  """
  return [ 
    FastqFile(
      filename.strip(), 
      run_name= fastq__runFromFilepath(filename)
    ).__dict__[field]
     for field in list(FastqFile.fieldNames())
  ]   

def fastq__loadSamples(**kwargs):
  if pipeman.samples.data is None:
    pipeman.samples.load(samples__csvMapDft.format(**kwargs))

def fastq__addStringFixes(s, prefix="", suffix="", **kwargs):
  """
  Adds the given :prefix: and :suffix: to the :s: string
  """
  return f"{prefix}{s}{suffix}"

def fastq__mapStringSamples(s, mapSuffix=True, withResult=False, **kwargs):
  fastq__loadSamples(**kwargs)
  if mapSuffix:
    res = pipeman.samples.buildStringFromKeywords(
            fastq__addStringFixes(s, **kwargs), 
            **kwargs)
  else:
    res = [ 
      fastq__addStringFixes(bstring, **kwargs)
      for bstring in pipeman.samples.buildStringFromKeywords(
            s, **kwargs)]
    
  if withResult and not res:
    pipeman.log.error(f"No result found for query '{s}' and keywords {kwargs}.")
    raise 
  else:
    return res
