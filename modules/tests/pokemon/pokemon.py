# --------------------------------------------
# Query pipeline samples' pandas data frame
# --------------------------------------------
from utils.dicts import toAddict

# ------------------
# Sample Evolution
# ------------------
def getEvol(poke):
  """
  Get next evolution
  """
  if poke.evol_id:
    return pipman.samples.queryFirstNameOrId(poke.evol_id) 

def getEvols(poke):
  """
  Gets all possible evolutions
  """
  evol = poke
  while evol.evol_id:
    evol = getEvol(evol)
    yield evol

# -------------------------------------
# Messages for Sample characteristics
# -------------------------------------
def msgPoke(poke):
  """
  Present a sample.
  """
  return (
    "Hey! I am {sample_name}{evol_msg}. I am {personality}."
     .format(
       **poke,
       evol_msg=" and I evolve at level {evol_lvl} with {evol_cond}"
         .format(**poke) 
         if poke.evol_id else ""
     )
  )

def msgEvols(poke):
  """
  Describes a sample's evolutions.
  """
  me = ""
  if poke.evol_id:
    me += (
      "My evolutions are {evol_list}."
      .format(evol_list="; ".join(
        [
          "{sample_name} ({type})".format(**evol)
          for evol in getEvols(poke)
        ]
      ))
    )
  else:
    me += "I do not evolve."
  return me

def msgEvol(poke):
  """
  Describes a sample's evolution.
  """
  if poke.evol_id:
    me = "I evolve into {sample_name}".format(**getEvol(poke))
  else:
    me = "I do not evolve."
  return me
