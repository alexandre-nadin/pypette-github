import os

def cmdOrLink(cmd, sharedFile, output):
  """
  Returns the given :cmd: shell command if the shared file :sharedFile: does not exists, otherwise the command to link the file to the :output:.
  Returns also a boolean for forcing the command execution in debug mode. 
  """
  if sharedFile and os.path.exists(sharedFile):
    return (
      f" ln -s {sharedFile} {output} ",
      True)
  return (cmd, False)
    
