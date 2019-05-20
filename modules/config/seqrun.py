seqrun__projectQCTarget = "{prj}/multiqc.html"
project__sampleTarget = "samples/samples.csv" # take it from config module
project__QcPathTarget = ""

def seqrun__debugOptions():
  return f"--config debug={config.debug}" if config.debug and config.debug in [True, False] else ''

def seqrun__projectsQC():
  """ Returns the seqrun's projects QC targets """
  return [ 
    seqrun__projectQCTarget.format(prj=prj)
    for prj in pipeman.config.run.projects.keys() 
  ]

def seqrun__projectSamples(prj):
  """ Returns a project samples file's absolute path """
  return os.path.join(
    seqrun__projectDir(prj),  # TODO: Move in relevant module file related to project
    project__sampleTarget)

def project__samplesTarget():
  return os.path.join(
    seqrun__projectsDir(),
    "{prj}",
    project__sampleTarget
  )

def seqrun__projectQcPath(prj):      # TODO: move to qc_seqrun?
  return os.path.join(
    seqrun__projectDir(prj),
    seqrun__projectQcTarget(prj, formatted=True)
  )

def seqrun__projectQcTarget(prj, formatted=False):
  pipeman.includeModule(
    "qc/qc_{pipeline}.py"
     .format(pipeline=seqrun__projectPipeline(prj)))
  target = qc__multiqcStd
  if formatted:
    target = target.format(sample_run=pipeman.project)
  return target

# ---------------
# Project Paths
# ---------------
def seqrun__projectQcPathTarget():
  return os.path.join(
    seqrun__projectDirTarget(),
    "{prefix}multiqc.html"
  )

def seqrun__projectDirTarget():
  return os.path.join(
    seqrun__projectsDir(), 
    "{prj}")


def seqrun__projectDir(prj):
  return seqrun__projectDirTarget().format(prj=prj)

def seqrun__projectsDir():
  return os.path.join(
    pipeman.workflowDir,
    pipeman.config.cluster.projects.outDir)

# ------------------------------
# Project pipeline information
# ------------------------------
def seqrun__projectPipeline(prj):
  """ Deduces a project's pipeline """
  for pipeline in pipeman.pipelines:
    if pipeline.lower() in seqrun__projectTitlesFmt(prj):
      return pipeline
  return None

def seqrun__projectTitlesFmt(prj):
  """ Formats all of a project's possible titles. 
  Todo: Remove when project information will be flawlessly set on our LIMS
  """
  return [ 
    title.lower().replace('_', '').replace(' ', '')
    for title in seqrun__projectTitles(prj)
  ]

def seqrun__projectTitles(prj):
  """ Gets all of a project's possible titles.
  TODO: Remove when project information will be flawlessly set on our LIMS
  """
  data = pipeman.config.run.projects[prj]
  return list(set([
      data.type, 
      data.pipeline, 
      *data.quotationTitles]))
