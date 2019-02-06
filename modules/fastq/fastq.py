import os
pipeman.includeModule("cluster/cluster.py")

def fastq__runsPathsProject(prj):
  """
  Gets each project run path.
  """
  return [ 
    os.path.join(
      run, 
      "{}{}".format(
        fastq__runProjectTag(),
        prj))
    for run in fastq__runsPaths()
  ]

def fastq__runProjectTag():
  if pipeman.config.cluster.sequencing_runs.structured:
    tag = pipeman.config.cluster.sequencing_runs.project_tag 
  else:
    tag = ""
  return tag

@cluster__prefixMountPoint
def fastq__runPath(runid):
  """
  Builds the path of the given runid.
  """
  return os.path.join(
    pipeman.config.cluster.sequencing_runs.dir, 
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
    run_path = os.path.join( 
      pipeman.cluster_mnt_point.rstrip(os.path.sep),
      pipeman.config.cluster.sequencing_runs.dir.strip(os.path.sep),
      run
    )
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
    pipeman.samples.load(fastq__mapped_samples_io_dft.format(**kwargs))

def fastq__mapStringSamples(s, **kwargs):
  fastq__loadSamples(**kwargs)
  return pipeman.samples.buildStringFromKeywords(s, **kwargs)
  
def fastq__mapSampleReads(read, **kwargs):
  return fastq__mapStringSamples(fastq_merging__sample_read_io, sample_read=read, **kwargs)

