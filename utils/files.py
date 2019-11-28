#!/usr/bin/env python
import os
def extensionless(name):
  """
  Removes a file name's extensions.
  > extensionless('/path/to/file.ext1.ext2.ext3')
    /path/to/file
  """
  split = os.path.splitext(name)
  return os.path.basename(split[0]) if split[1] else split[0]

def extension(name):
  split = os.path.splitext(name)
  return split[1] if split[1] else None

def touch(filenames=[]):
  """ Touches the given filenames. """
  for filename in filenames:
    with open(str(filename), 'a'):
      pass

def withFile(func):
  """
  Returns None if the file returned by the function :func: does not exist and
  the :withFile: attribute is given.
  """
  def wrapper(*args, **kwargs):
    _attr = 'withFile' 
    res = func(*args, **kwargs)
    if _attr in kwargs.keys() \
    and kwargs[_attr]         \
    and not os.path.exists(res):
      res = None
    return res
  return wrapper

