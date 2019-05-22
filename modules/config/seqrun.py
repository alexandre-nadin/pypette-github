pipeman.includeModule('config/project.py')
seqrun__projectQcTarget = "{prj}/multiqc.html"

def seqrun__debugOptions():
  return f"--config debug={config.debug}" if config.debug and config.debug in [True, False] else ''

def seqrun__projectsQc():
  """ Returns the seqrun's projects QC targets """
  return [ 
    seqrun__projectQcTarget.format(prj=prj)
    for prj in pipeman.config.run.projects.keys() 
  ]

def seqrun__projectQcPath(prj): # TODO: move to qc_seqrun?
  return os.path.join(
    project__dir(prj),
    project__pipelineQcTarget(
      seqrun__projectPipeline(prj),
      formatted=True)
  )

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
