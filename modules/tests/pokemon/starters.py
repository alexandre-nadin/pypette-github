def getStartersDict():
  return pipeman.samples.query('prevol_id.isnull()')

def msgStarters(pokes):
  """
  Describes all starters.
  """
  msgs = [
    "{sample_name}, of {type} type. It is {personality}."
     .format(**val)
    for val in pokes.values()
  ]
  return (
      "Starters are:"
    + "".join([
        "{} - {}".format(os.linesep, msg)
         for msg in msgs
      ])
  )
