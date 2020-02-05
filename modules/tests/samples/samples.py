# --------------------
# Samples Evolutions
# --------------------
def getEvol(sample):
  """
  Get next evolution
  """
  if sample.evol_id:
    return pypette.samples.queryFirstNameOrId(sample.evol_id) 

def getEvols(sample):
  """
  Gets all possible evolutions
  """
  evol = sample
  while evol.evol_id:
    evol = getEvol(evol)
    yield evol

# -------------------------------------
# Messages for Sample characteristics
# -------------------------------------
def msgPoke(sample):
  """
  Present a sample.
  """
  return (
    "Hey! I am {sample_name}{evol_msg}. I am {personality}."
     .format(
       **sample,
       evol_msg=" and I evolve at level {evol_lvl} with {evol_cond}"
         .format(**sample) 
         if sample.evol_id else ""
     )
  )

def msgEvols(sample):
  """
  Describes a sample's evolutions.
  """
  me = ""
  if sample.evol_id:
    me += (
      "My evolutions are {evol_list}."
      .format(evol_list="; ".join(
        [
          "{sample_name} ({type})".format(**evol)
          for evol in getEvols(sample)
        ]
      ))
    )
  else:
    me += "I do not evolve."
  return me

def msgEvol(sample):
  """
  Describes a sample's evolution.
  """
  if sample.evol_id:
    me = "I evolve into {sample_name}".format(**getEvol(sample))
  else:
    me = "I do not evolve."
  return me
