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
    self.colnameidx_dict = dict(list(
             (_colname, _colidx)
             for _colidx, _colname in enumerate(self.colnames)))
    self.colindexes = Enumeration(self.colnames)

  def query_dict(self, output_fields=(), output_foreign_keys=True, **where):
    ## 
    # output_dict: Outputs a list of dictionaries of column names associated to column values if True.
    #              Else a list of raw column values.
    # output_fields: Expects a tuple of indexes of the columns to display if output_dict=True.
    #                Else expects tuple of column names instead.
    # where: dictionnary to filter on the column indexes. 
    #   Ex: where={0: ['one', 'two']}
    #    will filter each row where the column 0 contains either 'one' or 'two'.
    #
    ret = []
    for row in csv__get_split_lines(self.filename, self.delimitor):
      ## Check the filter on output_fields
      row_to_append = True

      ## By defaut append the new rowt. As soon as a value is invalid, exclude the row.
      for _wkey in where.keys():
        new_row= {}

        ## Ignore filtering on foreign keys
        if _wkey not in self.colnameidx_dict.keys():
          continue

        try:
          ## Get the column index of the key
          index = self.colnameidx_dict[_wkey]
        except KeyError as ke:
          continue

        ## Exclude row if key does not match the required value
        if not row[index] in where[_wkey]:
          row_to_append = False
          break

      ## Add either the whole row or only the specified fields
      if row_to_append==True:
        if len(output_fields) == 0:
          new_row.update(dict(list( (_colname, row[self.colnameidx_dict[_colname]]) 
                              for _colname in self.colnameidx_dict.keys())))
        else:
          new_row.update(dict(list( (_colname, row[self.colnameidx_dict[_colname]]) 
                            for _colname in output_fields)))
  
        ## Add foreign keys if specified
        if output_foreign_keys==True:
          new_row.update(dict(list( (_key, where[_key])
                                    for _key in where.keys() 
                                     if _key not in self.colnameidx_dict.keys())))
        ret.append(new_row)
    return ret

  def query(self, output_fields=(), output_dict=False, **where):
    ## 
    # output_dict: Outputs a list of dictionaries of column names associated to column values if True.
    #              Else a list of raw column values.
    # output_fields: Expects a tuple of indexes of the columns to display if output_dict=True.
    #                Else expects tuple of column names instead.
    # where: dictionnary to filter on the column indexes. 
    #   Ex: where={0: ['one', 'two']}
    #    will filter each row where the column 0 contains either 'one' or 'two'.
    #
    ret = []
    for row in csv__get_split_lines(self.filename, self.delimitor):
      ## Check the filter on output_fields
      row_to_append = True
      ## By defaut append. As soon as a value is invalid, exclude the row.
      for key in where.keys():
        try:
          ## Get the coluimn index of the key
          index = self.colindexes.get_indexes([key])[0]
        except AttributeError as ae:
          #sys.stderr.write("Warning: column name '{}' does not exist among {}. Ignoring it.{}".format(
          #  key, self.colnames, os.linesep
          #))
          continue
        ## Exclude row if key does not match the required value
        if not row[index] in where[key]:
          row_to_append = False
          break
      ## Check the output_fields to output
      if row_to_append==False:
        continue
    
      if output_dict: 
        if len(output_fields) == 0:
          new_row = dict(list( (_colname, row[self.colnameidx_dict[_colname]]) 
                              for _colname in self.colnameidx_dict.keys()))
        else:
          new_row = dict(list( (_colname, row[self.colnameidx_dict[_colname]]) 
                            for _colname in output_fields))
      else:
        if len(output_fields) == 0:
          new_row = row
        else:
          new_row = [ row[_idx] for _idx in self.colindexes.get_indexes(output_fields) ]
      ret.append(new_row)
    return ret

  def query_idx(self, output_fields=(), where={}):
    ## 
    # output_fields: tuple of indexes of the columns to display.
    # where: dictionnary to filter on the column indexes. 
    #   Ex: where={0: ['one', 'two']}
    #    will filter each row where the column 0 contains either 'one' or 'two'.
    #
    ret = []
    for row in csv__get_split_lines(self.filename, self.delimitor):
      ## Check the filter on output_fields
      row_to_append = True
      ## By defaut append. As soon as a value is invalid, exclude the row.
      for key in where.keys():
        if not isinstance(key, int):
          sys.stderr.write("Warning: index '{}' is not an integer. Ignoring it.{}".format(key, os.linesep))
          continue
        if not key<len(row):
          sys.stderr.write("Warning: index '{}' index is superior to number of output_fields ({}). Ignoring it.{}".format(key, len(row), os.linesep))
          continue
        if not row[key] in where[key]:
          row_to_append = False
          break
      ## Check the output_fields to output
      if row_to_append==False:
        continue
      
      new_row = [ row[elem] for elem in output_fields ] \
        if not len(output_fields) == 0 \
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

