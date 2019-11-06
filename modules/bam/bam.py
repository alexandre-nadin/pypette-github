# ---------
# Aligner
# ---------
def bam__alignerDft():
  return 'aligner'

def bam__configAligner():
  try:
    return pipeman.config.pipeline.modules.mapping.aligner
  except:
    pipeman.log.error("No aligner found in pipeline configuration.")

def bam__alignerDir(append=False):
  aligner = bam__configAligner().name
  if aligner:
    res = aligner
  else:
    res = bam__alignerDft()
  if append:
    res = os.path.sep + res
  return res
    
def bam__alignerModule(aligner):
  return f"{aligner.name}.sk".lower()

def bam__includeAlignerModule():
  aligner = bam__configAligner()
  if aligner.name:
    include: bam__alignerModule(aligner)
  else:
    pipeman.log.error("No aligner found in the pipeline configuration.")

# -----------
# Alignment
# -----------
def bam__sampleReadGroup(sample):
  fcid           = bam__runFlowCellID(sample.sample_run)
  experimentName = fcid + "_" + sample.sample_name
  platform       = pipeman.config.pipeline.sequencing.platform
  center         = pipeman.config.pipeline.center.name 
  return "\\t".join([
    "@RG",
    "ID:" + experimentName,
    "PL:" + platform,
    "PU:" + sample.sample_run,
    "LB:" + experimentName,
    "SM:" + sample.sample_name,
    "CN:" + center
  ])

def bam__runFlowCellID(run):
  return run.split('_').pop()[1:]

# ---------
# Merging
# ---------
def picardMergeInputString(inputs=[]):
  return " ".join([ "I={}".format(i) for i in inputs])

# ---------------
# Sorting tools
# ---------------
def bam__sorter():
  try:
    res = pipeman.config.pipeline.modules.mapping.sorter.name
  except:
    res = None
  return res
 
def bam__sorterDir(append=False):
  sorter = bam__sorter()
  res = ""
  if sorter:
    res = os.path.sep.join(["sorted", sorter])
    if append:
      res = os.path.sep + res
  return res
