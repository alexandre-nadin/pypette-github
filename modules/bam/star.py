def star__readsToString(R1=[], R2=[]):
  """  
  Takes arrays of reads 1 and 2.
  Builds the input string for Star's readFilesIn parameter. 
  """
  return "{R1} {R2}".format(
    R1=','.join(R1) if config.pipeline.name != 'scrna' else '', 
    R2=','.join(R2))

def star__indexDir():
  """
  Retrieves the genome index using cluster and project metadata parameters.
  """
  return os.path.join(
    annot__gencodeDir(),
    bam__configAligner().name)

