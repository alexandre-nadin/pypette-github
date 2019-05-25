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
    pipeman.samples.load()

def fastq__addStringFixes(s, prefix="", suffix="", **kwargs):
  """
  Adds the given :prefix: and :suffix: to the :s: string
  """
  return f"{prefix}{s}{suffix}"

def fastq__mapStringSamples(s, mapSuffix=True, withResult=False, **kwargs):
  fastq__loadSamples(**kwargs)
  if mapSuffix:
    res = pipeman.samples.buildStringFromKeywords(
            fastq__addStringFixes(s, **kwargs), 
            **kwargs)
  else:
    res = [ 
      fastq__addStringFixes(bstring, **kwargs)
      for bstring in pipeman.samples.buildStringFromKeywords(
            s, **kwargs)]
    
  if withResult and not res:
    pipeman.log.error(f"No result found for query '{s}' and keywords {kwargs}.")
    raise 
  else:
    return res
