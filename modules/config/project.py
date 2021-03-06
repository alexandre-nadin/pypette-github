project__samplesTarget = "samples/samples.csv"

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
