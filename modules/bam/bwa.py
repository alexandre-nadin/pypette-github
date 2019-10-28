def bam_bwa__readsToString(R1=[], R2=[]):
  return "{R1} {R2}".format(
    R1 = "<(zcat {})".format(" ".join(R1)) if R1 else "",
    R2 = "<(zcat {})".format(" ".join(R2)) if R2 else ""
  )

def bam_bwa__genomeIndex():
  return os.path.join(
    annot__indexDir(),
    pipeman.config.project.genome.name)
