# ---------
# Aligner
# ---------
def mapping__alignerDft():
  return 'aligner'

def mapping__aligner():
  try:
    return pipeman.config.pipeline.modules.mapping.aligner.name
  except:
    pipeman.log.error("No aligner found in pipeline configuration.")

def mapping__alignerDir(append=False):
  aligner = mapping__aligner()
  if aligner:
    res = aligner
  else:
    res = mapping__alignerDft()
  if append:
    res = os.path.sep + res
  return res
    
def mapping__alignerModule():
  aligner = mapping__aligner()
  module = ""
  if aligner:
    module = '{}.sk'.format(aligner)
  return module

def mapping__includeAlignerModule():
  aligner = mapping__aligner()
  if aligner:
    include: mapping__alignerModule()

# -----------
# Alignment
# -----------
def mapping__sampleReadGroup(sample):
  experimentName = sample.sample_run + "_" + sample.sample_name
  platform       = pipeman.config.pipeline.sequencing.platform
  center         = pipeman.config.pipeline.center.name 
  return "\t".join([
    "@RG",
    "ID:" + experimentName, # experiment_name = sample[0]_sample[2]
    "PL:" + platform, # PLATFORM
    "PU:" + sample.sample_run, # sample[0]
    "LB:" + experimentName, # experiment_name
    "SM:" + sample.sample_name, # sample[2]
    "CN:" + center  # CENTER
  ])

# ---------------
# Mapping Genome 
# ---------------
@cluster__prefixMountPoint
def mapping__genomeIndex():
  """
  Retrieves the genome index using cluster and project metadata parameters.
  Uses 
   - cluster.genome_dir
   - project.genome .gencode and .species
  """
  return os.path.join(
    "{cluster.genome_dir}",
    "{genome.name}",
    "{aligner.command}").format(
      cluster  = pipeman.config.cluster,
      genome   = pipeman.config.project.genome,
      aligner  = pipeman.config.pipeline.modules.mapping[mapping__aligner()]
    )

# ---------
# Merging
# ---------
def picardMergeInputString(inputs=[]):
  return " ".join([ "I={}".format(i) for i in inputs])

# ---------------
# Sorting tools
# ---------------
def mapping__sorter():
  try:
    res = pipeman.config.pipeline.modules.mapping.sorter.name
  except:
    res = None
  return res
 
def mapping__sorterDir(append=False):
  sorter = mapping__sorter()
  res = ""
  if sorter:
    res = os.path.sep.join(["sorted", sorter])
    if append:
      res = os.path.sep + res
  return res
