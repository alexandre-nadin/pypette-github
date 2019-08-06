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

def camelCase(s):
  """
  Transforms the given string into camel case. Removes the '_'
  """
  title = (
      s
       .replace('_', ' ')
       .title()
       .replace(' ', ''))

  """ Lowers first char """
  if title:
    ret = title[0].lower()
  if len(title) > 1:
    ret += title[1:]
  return ret

def setTaggedVarEnvsAttrs(obj, tag=""):
  """
  Gets and formats the environment variables found in os environ with the given tags.
  Sets them as the given object's attributes.
  """
  import re
  for varenv in getTaggedVarEnvs(tag=tag):
    var = camelCase(re.sub(rf'^{tag}', '', varenv))
    setattr(obj, var, os.environ[varenv])
