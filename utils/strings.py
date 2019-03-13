import utils.dicts

class StringFormatter(str):
  """
  This class is used to add more flexibility to handling string formats.
  """

  def formatPartialMap(self, keepMissingKeys=False, **kwargs):
    """
    Formats only the string keywords found in the given dictionnary in flexible way.
    Leaves missing keywords untouched for later formatting if :keepMissingKeys: is verified.
    Else empties missing keywords.
    """
    self = StringFormatter(self.format_map(utils.dicts.Default(kwargs, keepMissingKeys)))
    return self

  def keywords(self): 
    """ Returns own format keywords """ 
    from string import Formatter 
    return [ fname for _, fname, _, _ in Formatter().parse(self) if fname ]
