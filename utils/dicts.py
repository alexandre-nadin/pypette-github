def toAddict(func):
  import addict
  def wrapper(*args, **kwargs):
    return addict.Dict(func(*args, **kwargs))
  return wrapper

def popFirst(func):
  """
  Pops the first element of a dictionnary.
  Originally intended to use on pandas DataFrame.T.to_dict() since each key
  is an index.
  """
  def wrapper(*args, **kwargs):
    dic = func(*args, **kwargs)
    dic = dic[list(dic.keys())[0]] if dic else {}
    return dic
  return wrapper

class Default(dict):
  def __init__(self, d, nomissing=True):
    self.nomissing = nomissing
    super(Default, self).__init__(d)

  def __missing__(self, key):
      return '' if self.nomissing else '{' + key + '}'
