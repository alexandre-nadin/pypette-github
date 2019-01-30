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
