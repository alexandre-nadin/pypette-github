#!/usr/bin/env python
from easydev import Logging

class Manager(object):
  def __init__(self):
    self.log = Logging(self.__class__.__name__, "INFO")
