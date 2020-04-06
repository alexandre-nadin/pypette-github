def star__readsToString(r1, r2):
  """  
  Takes arrays of reads 1 and 2.
  Builds the input string for Star's readFilesIn parameter. 
  """
  return f"{r1} {r2}"

def star__indexDir(**kwargs):
  """
  Retrieves the genome index using cluster and project metadata parameters.
  """
  return os.path.join(
    annot__gencodeDir(**kwargs),
    bam__configAligner().name)
