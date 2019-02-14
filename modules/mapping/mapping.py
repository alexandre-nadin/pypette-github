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
  return module.lower()

def mapping__includeAlignerModule():
  aligner = mapping__aligner()
  if aligner:
    include: mapping__alignerModule()

# -----------
# Alignment
# -----------
def mapping__sampleReadGroup(sample):
  fcid           = mapping__runFlowCellID(sample.sample_run)
  experimentName = fcid + "_" + sample.sample_name
  platform       = pipeman.config.pipeline.sequencing.platform
  center         = pipeman.config.pipeline.center.name 
  return "\t".join([
    "@RG",
    "ID:" + experimentName,
    "PL:" + platform,
    "PU:" + sample.sample_run,
    "LB:" + experimentName,
    "SM:" + sample.sample_name,
    "CN:" + center
  ])

def mapping__runFlowCellID(run):
  return run.split('_').pop()[1:]

# ---------------
# Mapping Genome 
# ---------------
@cluster__prefixMountPoint
def mapping__genomeDir():
  return os.path.join(
    pipeman.config.cluster.genome_dir,
    pipeman.config.project.genome.name
  )

def exome__targetDir():
  return os.path.join(
    mapping__genomeDir(),
    "annotation",
    "exomes_targets")

def exome__intervalListFmt():
  return os.path.join(
    exome__targetDir(),
    "agilent_v7_sureselect_{}.interval_list")

def exome__targetIntervals():
  return exome__intervalListFmt().format("MergedProbes")

def exome__baitIntervals():
  return exome__intervalListFmt().format("Regions")

def mapping__genomeFasta():
  """
  Retrieves the genome fastq using cluster and project metadata parameters.
  """
  return os.path.join(
    mapping__genomeDir(),
    "fa",
    pipeman.config.project.genome.name + ".fa"
  )

def mapping__genomeIndex():
  """
  Retrieves the genome index using cluster and project metadata parameters.
  """
  return os.path.join(
    mapping__genomeDir(),
    pipeman.config.pipeline.modules.mapping.aligner.name
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
