import re

def isRegexInList(regex, names=[]):
  if regexInList(regex, names):
    return True
  else:
    return False

def regexInList(regex, names=[]):
  return list(filter(re.compile(regex).match, names))
