import os

def setVars(*args, namespace={}):
  """
  Fetches the given env variables from the environment.
  Sets them in the given namespace.
  """
  for var in args:
    namespace[var] = os.environ[var]
