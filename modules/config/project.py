project__samplesTarget = "samples/samples.csv"

def project__samplesTargetPath():
  return os.path.join(
    project__projectsDir(),
    "{prj}",
    project__samplesTarget
  )

def project__projectsDir():
  return os.path.join(
    pipeman.config.cluster.stdAnalysisDir,
    pipeman.config.cluster.projects.outDir)

def project__dirFmt():
  return os.path.join(
    project__projectsDir(), 
    "{prj}")

def project__dir(prj):
  return project__dirFmt().format(prj=prj)

def project__samplesMetaPath(prj):
  """ Returns a project samples file's absolute path """
  return os.path.join(
    project__dir(prj), 
    project__samplesTarget)

def project__pipelineQcTarget(pipeline, formatted=False, **kwargs):
  """ Includes the correct QC target for the given pipeline's module. """
  pipeman.includeModule(f"qc/{pipeline}.py")
  target = qc__multiqcStd
  if formatted:
    target = target.format(sample_run=pipeman.project)
  return target

