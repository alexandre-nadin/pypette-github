import os

def setVars(*args, namespace={}):
  """
  Fetches the given env variables from the environment.
  Sets them in the given namespace.
  """
  for var in args:
    if var in os.environ.keys():
      namespace[var] = os.environ[var]
    else:
      namespace[var] = ""

def getTaggedVarEnvs(tag=""):
  """
  Retrieves environment variables starting with the given tag.
  """
  return [ varenv 
    for varenv in os.environ.keys() 
    if varenv.startswith(tag)
  ]

def setTaggedVarEnvsAttrs(obj, tag="", stripTag=True):
  """
  Gets and formats the environment variables found in os environ with the given tags.
  Sets them as the given object's attributes.
  """
  import re
  for varenv in getTaggedVarEnvs(tag=tag):
    varenv_name = re.sub(
      r"^{}".format(tag),
      "",
      varenv).lower()
 
    setattr(
      obj, 
      varenv_name,
      os.environ[varenv])
