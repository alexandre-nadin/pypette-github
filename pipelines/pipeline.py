#!/usr/bin/env python

# ------
# Shell
# ------
def lshell(command, allow_empty_lines=False):
  """
  Returns the output of a given shell command in an array.
  Each element is an output line.
  Filters empty strings by default.
  """
  out = subprocess.check_output(command, shell=True).decode().split(os.linesep)
  return out if allow_empty_lines else [ _elem for _elem in out if _elem ] 

# -----------------
# PipelineManager
# -----------------
def newPipelineManager(name):
  """
  Declares a new PipelineManager the easiest way.
  Purpose: who writes a piepeline doesn't have to care about the global namespace.
  Default namespace: globals()
  """
  return pipeline.PipelineManager(name=name, namespace=globals())
