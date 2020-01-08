project__samplesTarget = "samples/samples.csv"

def project__samplesTargetPath():
  return os.path.join(
    project__projectsDir(),
    "{project}",
    project__samplesTarget
  )

def project__projectsDir():
  return os.path.join(
    pypette.config.cluster.stdAnalysisDir,
    pypette.config.cluster.projects.outDir)

def project__dirFmt():
  return os.path.join(
    project__projectsDir(), 
    "{project}")

def project__dir(project):
  return project__dirFmt().format(project=project)

def project__samplesMetaPath(project):
  """ Returns a project samples file's absolute path """
  return os.path.join(
    project__dir(project), 
    project__samplesTarget)

def project__pipelineQcTarget(pipeline, formatted=False, **kwargs):
  """ Includes the correct QC target for the given pipeline's module. """
  pypette.includeModule(f"qc/{pipeline}.py")
  target = qc__multiqcStd
  if formatted:
    target = target.format(sample_run=pypette.project)
  return target

def project__speciesGenome():
  return pypette.config.species[pypette.config.project.species]

def project__speciesGenomeName():
  return project__speciesGenome().genome.assembly.ucscRef
