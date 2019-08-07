def override(func):
  """
  Raises an error to override a method.
  The method to be overridden should return a documentation string
  for debugging purpose.
  """
  def wrapper(*args, **kwargs):
    msg = func(*args, **kwargs) 
    raise Exception(
      "Function/method '{}' has to be overridden in a subclass. {}"
        .format(func.__name__, msg)
    )
  return wrapper

def overrideProperty(func):
  """
  Raises an error to override a property method.
  The method to be overridden should return a documentation string
  for debugging purpose.
  """
  def wrapper(*args, **kwargs):
    msg = func(*args, **kwargs) 
    raise Exception(
      "Method '{}' has to be overridden in a subclass. It should be decorated with '@property'. Doc: {}"
        .format(func.__name__, msg)
    )
  return wrapper
