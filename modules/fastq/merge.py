## Todo: Check how to convert this function into Snakemake wrapper
def fastq_merging__mergeReadsCmd(input, output):
  """
  Concatenates the given fastq files if several. Links single fastq otherwise.
  """
  input.reads.sort()
  if len(input.reads) == 1:
    cmd = """
      ln.rel {input.reads[0]} {output.read}
    """
  else:
    cmd = f"""
      zcat {input.reads} \
       | gzip            \
       > {output.read}
    """
    cmd = f"""
      zcat {input.reads} | gzip > {output.read}
    """
  return cmd
