import addict

def rseqc__inferExperiment(file, debug=False):
  """
  Reads an infer_experiment output file. 
  Deduces pair endedness and strandedness
  """
  if debug:
    return addict.Dict({
      'isPairEnd'    : None,
      'isStranded'   : None,
      'strandedness' : None,
      'fcStrand'     : None,
      'readsFailed'  : None,
      'readsHalf1'   : None,
      'readsHalf2'   : None
    })

  with open(file, 'r') as f:                       
    data = [ line.strip() for line in f.readlines() if line.strip() ]

  pe = True if 'pairend' in data[0].lower() else False 

  readsFailed, readsHalf1, readsHalf2 = [ 
    float(read.split(':')[1].strip())
    for read in data[1:4] ]

  stranded = True if abs(readsHalf1 - readsHalf2) >= 0.2 else False

  if not stranded:
    strandedness = 'unstranded'
    fcStrand     = 0
  elif readsHalf1 > readsHalf2:
    strandedness = 'forward'
    fcStrand     = 1
  else:
    strandedness = 'reverse'
    fcStrand     = 2

  return addict.Dict({
    'isPairEnd'    : pe,
    'isStranded'   : stranded,
    'strandedness' : strandedness,
    'fcStrand'     : fcStrand,
    'readsFailed'  : readsFailed,
    'readsHalf1'   : readsHalf1,
    'readsHalf2'   : readsHalf2
  })

