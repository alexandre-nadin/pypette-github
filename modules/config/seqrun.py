pipeman.includeModule('config/project.py')
seqrun__projectQcTarget = "{prj}/multiqc_report.html"

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
    if pipeline.lower() in pipeman.config.run.projects[prj]:
      return pipeline
  return None
