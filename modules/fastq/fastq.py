import os
from utils.fastq_helper import FastqFile
from utils.files import touch

pipeman.includeModule("cluster/cluster.py")

def fastq__mapFilename(filename):
  """
  Maps the illumina metadata based on the given filename.
  """
  return [ 
    FastqFile(
      filename.strip(), 
      run_name= runs__runFromFilepath(filename)
    ).__dict__[field]
     for field in list(FastqFile.fieldNames())
  ]   

def fastq__loadSamples(**kwargs):
  if pipeman.samples.data is None:
    pipeman.samples.load(**kwargs)
