pipeman.includeModule('config/project.py')
seqrun__projectQcTarget          = "{prj}/multiqc_report.html"
seqrun__projectSamplesMetaTarget = "{prj}/samples.csv"

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
      seqrun__projectPipelineDft(prj),
      formatted=True)
  )

# ------------------------------
# Project pipeline information
# ------------------------------
def seqrun__projectPipeline(prj):
  """ Returns a project's pipeline if it exists in pypette """
  pipeline = pipeman.config.run.projects[prj].pipeline
  if pipeline and pipeline.lower() in map(str.lower, pipeman.pipelines):
    return pipeline
  else:
    return None

def seqrun__projectPipelineDft(prj):
  """ Infers a default pipeline if none recognized from project configuration """
  pipeline = seqrun__projectPipeline(prj)
  if pipeline and pipeman.config.run.projects[prj].genome:
    return pipeline
  else:
    return 'fastqc'
