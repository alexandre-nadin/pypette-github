import os
from utils.fastq_helper import FastqFile
from utils.files import touch

pypette.includeModule("cluster/cluster.py")

def fastq__mapFilename(filename):
  """
  Maps the illumina metadata based on the given filename.
  """
  fastqFile = FastqFile(
    filename.strip(), 
    run_name = runs__runFromFilepath(filename))
  if fastqFile.isValid:
    return [ 
      fastqFile.__dict__[field]
      for field in FastqFile.fieldNames()
    ]
  else:
    return None

def fastq__loadSamples(**kwargs):
  if pypette.samples.data is None:
    pypette.samples.load(**kwargs)
