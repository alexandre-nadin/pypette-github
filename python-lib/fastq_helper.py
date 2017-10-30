#!/usr/bin/env python
import os
import sys
import re
sys.path.insert(0, os.path.abspath(os.path.curdir))
#print("currently in '{}'".format(os.path.abspath(os.path.curdir)))
#import enumeration as enum
from collections import OrderedDict

## Illumina naming convention: 
class FastqFile(object):
  # This class helps to get a file's information.
  # The file should respect illumina filename convention:
  #   /path/to/SampleName_SampleNumber_LaneNumber_ReadNumber_ChunkNumber.fastq_extension
  # 
  fields_regex_dic = OrderedDict([
    ('sample_path', "\w+"),
    ('sample_run', "\w+"),
    ('sample_basename', "\w+"),
    ('sample_chunkname', "\w+"),
    ('sample_name', "\w+"),
    ('sample_number', "S\d+"),
    ('sample_lane', "L\d+"),
    ('sample_read', "R[12]"),
    ('sample_chunknb', "\d+"),
    ('sample_extension', "\.fastq.*")
  ])
  field_sep = '_'
#  fields_regex_str = field_sep.join([
#                   "({})".format(_regex) for _regex in [
#                     [
#                      fields_regex_dic[_field] for _field in [
#                       'sample_name', 'sample_number',  
#                       'sample_lane', 'sample_read', 'sample_chunknb'
#                      ]
#                     ]
#                   ]
#                 ]) + "({})".format(fields_regex_dic['sample_extension'])
  fields_regex_str = field_sep.join([
                   "({})".format(_regex) for _regex in [
                      fields_regex_dic['sample_name'], 
                     fields_regex_dic['sample_number'], 
                     fields_regex_dic['sample_lane'], 
                     fields_regex_dic['sample_read'], 
                     fields_regex_dic['sample_chunknb']
                   ]
                 ]) + "({})".format(fields_regex_dic['sample_extension'])
                 

  def __init__(self, filename, run_name=""):
    self.sample_path = os.path.abspath(filename).strip()
    self.sample_basename = os.path.basename(self.sample_path)
    self.sample_name, \
     self.sample_number, \
     self.sample_lane, \
     self.sample_read, \
     self.sample_chunknb, \
     self.sample_extension = re.search(
                     self.fields_regex_str, self.sample_basename
                             ).groups()
    self.sample_chunkname = self.sample_basename.rstrip(self.sample_extension)
    self.sample_run = run_name 

  @classmethod
  def get_field_names(cls):
    return list(cls.fields_regex_dic.keys())
