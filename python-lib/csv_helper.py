#!/usr/bin/env python
import os, sys
sys.path.insert(0, os.path.abspath(os.path.curdir))

def csv__get_split_lines(filename, delimiter=","):
  import csv
  with open(filename, 'r') as f:
    reader = csv.reader(f, delimiter=delimiter)
    for row in reader:
      yield row

class CsvMap(object):
  delimitor = ','
  def __init__(self, filename, delimitor=',', colnames=[]):
    self.filename = filename
    self.delimitor = delimitor
    self.colnames = colnames
    self.colindexes = Enumeration(self.colnames)

  def query(self, fields=(), **where):
    ## 
    # fields: tuple of indexes of the columns to display.
    # where: dictionnary to filter on the column indexes. 
    #   Ex: where={0: ['one', 'two']}
    #    will filter each row where the column 0 contains either 'one' or 'two'.
    #
    ret = []
    for row in csv__get_split_lines(self.filename, self.delimitor):
      ## Check the filter on fields
      row_to_append = True
      ## By defaut append. As soon as a value is invalid, exclude the row.
      for key in where.keys():
        try:
          index = self.colindexes.get_indexes([key])[0]
        except AttributeError as ae:
          #sys.stderr.write("Warning: column name '{}' does not exist among {}. Ignoring it.{}".format(
          #  key, self.colnames, os.linesep
          #))
          continue
        if not row[index] in where[key]:
          row_to_append = False
          break
      ## Check the fields to output
      if row_to_append==False:
        continue
      
      new_row = [ row[_idx] for _idx in self.colindexes.get_indexes(fields) ] \
        if not len(fields) == 0 \
        else row
      ret.append(new_row)
    return ret

  def query_idx(self, fields=(), where={}):
    ## 
    # fields: tuple of indexes of the columns to display.
    # where: dictionnary to filter on the column indexes. 
    #   Ex: where={0: ['one', 'two']}
    #    will filter each row where the column 0 contains either 'one' or 'two'.
    #
    ret = []
    for row in csv__get_split_lines(self.filename, self.delimitor):
      ## Check the filter on fields
      row_to_append = True
      ## By defaut append. As soon as a value is invalid, exclude the row.
      for key in where.keys():
        if not isinstance(key, int):
          sys.stderr.write("Warning: index '{}' is not an integer. Ignoring it.{}".format(key, os.linesep))
          continue
        if not key<len(row):
          sys.stderr.write("Warning: index '{}' index is superior to number of fields ({}). Ignoring it.{}".format(key, len(row), os.linesep))
          continue
        if not row[key] in where[key]:
          row_to_append = False
          break
      ## Check the fields to output
      if row_to_append==False:
        continue
      
      new_row = [ row[elem] for elem in fields ] \
        if not len(fields) == 0 \
        else row
      ret.append(new_row)
    return ret

class Enumeration(object):
  def __init__(self, names=[]):
    for idx, name in enumerate(names):
      setattr(self, name, idx)
  def get_indexes(self, names=[]):
    ## Returns a list of indexes which correspond to the given enumeration attribute.
    return [ getattr(self, name) for name in names ]

