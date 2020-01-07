pipeman.includeModule("cluster/cluster.py")

@cluster__prefixMountPoint
def fastq_adapter__toolAdapters(trimmingTool):
  """
  Retrieves the cluster's path to the given :trimmingTool: 's adapters.
  """
  return os.path.join(
    pipeman.config.cluster.adapterDir,
    pipeman.config.pipeline.modules.fastq.adapters[trimmingTool]
  )

fastq_adapter__complBaseDic = {
  'a': 't',
  't': 'a',
  'c': 'g',
  'g': 'c'
}
 
def fastq_adapter__complement(s):
  """
  Complements bases from the given string :s: 
  """
  return ''.join(map(lambda x: fastq_adapter__complBaseDic[x], s.lower()))

def fastq_adapter__reverse(s):
  """
  Reverses the given :s: string
  """
  return ''.join(reversed(s)).strip()

def fastq_adapter__reverseComplementFasta(f):
  """
  Reads an input fasta file and reverse-complements each adapter.
  Tags headers starting with '>'.
  """
  with open(f, 'r') as fh:
    return (
      fastq_adapter__complement(fastq_adapter__reverse(line)).upper()
      if not line.startswith('>')
      else line + "_reversed"
      for line in map(str.strip, fh.readlines()))

