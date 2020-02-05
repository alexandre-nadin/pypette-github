import os
from utils.fastq_helper import FastqFile
from utils.files import touch

pypette.includeModule("cluster/cluster.py")

def fastq__mapFilenames(files=[], runid=""):
  """
  Returns a map of valid fields from fastq file names
  """
  return [ file for file in fastq__mappedFilenames(files, runid) if file ]

def fastq__mappedFilenames(files=[], runid=""):
  """
  Return a map of fields from fastq file names
  """
  return [ fastq__mapFilename(file, runid) for file in files ]

def fastq__mapFilename(filename, runid):
  """
  Maps the filename's metadata fields
  """
  fastqFile = FastqFile(filename.strip(), run_name = runid)
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
