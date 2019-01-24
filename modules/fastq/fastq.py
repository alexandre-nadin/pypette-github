def setConfigs(**kwargs):
  """
  Not elegant way to deal with config files.
  Should set dependence to cluster.yaml (retreived in {prj_name}/metadata.json)
  Loads {prj_name}/metadata.json.
  """
  import os
  """ Load cluster configuration """
  pipeman.config_manager.loadConfig(
    os.path.join(
      pipeman.dir_modules, "lims", "cluster.yaml"
    )
  )
  """ Load project metadata configuration """
  pipeman.config_manager.loadConfig(
    "{prj_name}/metadata.json".format(**kwargs)
  )

def fastq__getRuns():
  return [ 
    os.path.join(pipeman.config.cluster.sequencing_runs_dir, runid)
    for runid in pipeman.config.project.run_ids
  ]

def fastq__checkRuns(runs=[]):
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
      pipeman.config.cluster.sequencing_runs_dir,
      run, 
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
  
