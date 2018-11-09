#!/usr/bin/env python
def toAddict(func):
  import addict
  def wrapper(*args, **kwargs):
    return addict.Dict(func(*args, **kwargs))
  return wrapper
