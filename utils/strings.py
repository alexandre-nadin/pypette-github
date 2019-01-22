import utils.dicts

class StringFormatter(str):
  """
  This class is used to add more flexibility to handling string formats.
  """
  def formatMapFlexi(self, d, nomissing=True):
    """
    Formats only the string keywords found in the given dictionnary in flexible way.
    Empties other keywords if nomissing. Else leaves them untouched for further formatting.
    """
    return self.format_map(utils.dicts.Default(d, nomissing))

  def keywords(self): 
    """ Returns own format keywords """ 
    from string import Formatter 
    return [ fname for _, fname, _, _ in Formatter().parse(self) if fname ]
