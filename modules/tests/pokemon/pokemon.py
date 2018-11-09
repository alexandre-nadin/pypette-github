# --------------------------------------------
# Query pipeline samples' pandas data frame
# --------------------------------------------
from utils.dicts import toAddict

def queryPokes(query):
  """
  Returns an addict Dict of all found samples filterd by **where.
  """
  pokes = pipman.samples.query(query)
  if pokes.empty:
    pipman.log.error(
      "No information found for sample filter '{}'."
       .format(query)
    )
    raise
  else:
    return pokes.T.to_dict()

def queryPoke(query):
  """
  Returns the first sample filtered by query string.
  """
  pokes = queryPokes(query)
  return pokes[list(pokes.keys())[0]]

@toAddict
def getPokeDict(nameOrId):
  """
  Gets a dict from a sample query
  """
  try:
    return queryPoke('sample_id=={nb} or sample_name=={nb}'
      .format(nb=int(nameOrId)))
  except ValueError:
    return queryPoke('sample_name=="{}"'.format(nameOrId))

@toAddict
def getPokesDict(nameOrId):
  """
  Gets a dict from samples query
  """
  try:
    return queryPokes('sample_id=={nb} or sample_name=={nb}'
      .format(nb=int(nameOrId)))
  except ValueError:
    return queryPokes('sample_name=="{}"'.format(nameOrId))

def getEvol(poke):
  """
  Get next evolution
  """
  if poke.evol_id:
    return getPokeDict(poke.evol_id) 

def getEvols(poke):
  """
  Gets all possible evolutions
  """
  evol = poke
  while evol.evol_id:
    evol = getEvol(evol)
    yield evol

# ------------------------------------------------------
# String messages describing samples' characteristics.
# ------------------------------------------------------
def msgPoke(poke):
  """
  Present a sample.
  """
  me = "Hey! I am {sample_name}"
  if poke.evol_id:
    me += " and I evolve at level {evol_lvl} with {evol_cond}"
  me += "."
  me += " I am {personality}."
  return me.format(**poke)

def msgEvols(poke):
  """
  Describes a sample's evolutions.
  """
  me = ""
  if poke.evol_id:
    me += (
       "My evolutions are "
     + "; ".join([ 
       "{sample_name} ({type})"
         .format(**evol)
         for evol in getEvols(poke)
      ])
     + "."
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
