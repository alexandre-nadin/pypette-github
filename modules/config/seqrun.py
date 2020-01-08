pypette.includeModule('config/project.py')
seqrun__projectQcTarget          = "{project}/multiqc_report.html"
seqrun__projectSamplesMetaTarget = "{project}/samples.csv"

def seqrun__projectsQc():
  """ Returns the seqrun's projects QC targets """
  return [ 
    seqrun__projectQcTarget.format(project=project)
    for project in pypette.config.run.projects.keys() 
  ]

def seqrun__projectQcPath(project): # TODO: move to qc_seqrun?
  return os.path.join(
    project__dir(project),
    project__pipelineQcTarget(
      seqrun__projectPipelineDft(project),
      formatted=True)
  )

# ------------------------------
# Project pipeline information
# ------------------------------
def seqrun__projectPipeline(project):
  """ Returns a project's pipeline if it exists in pypette """
  pipeline = pypette.config.run.projects[project].pipeline
  if pipeline and pipeline.lower() in map(str.lower, pypette.pipelines):
    return pipeline
  else:
    return None

def seqrun__projectPipelineDft(project):
  """ Infers a default pipeline if none recognized from project configuration """
  pipeline = seqrun__projectPipeline(project)
  if pipeline and pypette.config.run.projects[project].genome:
    return pipeline
  else:
    return 'fastqc'
