def mapping_bwa__readsToString(R1=[], R2=[]):
  return "{R1} {R2}".format(
    R1 = "<(zcat {})".format(" ".join(R1)) if R1 else "",
    R2 = "<(zcat {})".format(" ".join(R2)) if R2 else ""
  )

def mapping_bwa__genomeIndex():
  return os.path.join(
    mapping__genomeIndex(),
    pipeman.config.project.genome.name)
