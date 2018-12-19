#!/usr/bin/env python
import os
import sys
import re
from collections import OrderedDict
import addict

#class FastqField(object):
#  def __init__(self, name, regex, in_basename=True):
#    (
#      self.name, self.regex, self.in_basename
#    ) = (name, regex, in_basename)

  

## Illumina naming convention: 
class FastqFile(object):
  # This class helps to get a fastq file's information.
  # The file should respect Illumina filename convention:
  #   /path/to/SampleName_SampleNumber_LaneNumber_ReadNumber_ChunkNumber.fastq_extension
  # 
#  fastq_fields = addict.Dict(OrderedDict([
#    FastqField('sample_path',      "\w+"      , False ),
#    FastqField('sample_run',       "\w+"      , False ),
#    FastqField('sample_basename',  "\w+"      , False ),
#    FastqField('sample_chunkname', "\w+"      , False ),
#    FastqField('sample_name',      "\w+"      , True  ),
#    FastqField('sample_number',    "S\d+"     , True  ),
#    FastqField('sample_lane',      "L\d+"     , True  ),
#    FastqField('sample_read',      "R[12]"    , True  ),
#    FastqField('sample_chunknb',   "\d+"      , True  ),
#    FastqField('sample_extension', "\.fastq.*", False ),
#  ]))

  regex_fields = addict.Dict(OrderedDict([
    ('sample_path',      "\w+"       ),
    ('sample_run',       "\w+"       ),
    ('sample_basename',  "\w+"       ),
    ('sample_chunkname', "\w+"       ),
    ('sample_name',      "\w+"       ),
    ('sample_number',    "S\d+"      ),
    ('sample_lane',      "L\d+"      ),
    ('sample_read',      "R[12]"     ),
    ('sample_chunknb',   "\d+"       ),
    ('sample_extension', "\.fastq.*" )
  ]))
  field_sep = '_'
#  fields_regex_str = field_sep.join([
#                   "({})".format(regex) for regex in [
#                     [
#                      regex_fields[_field] for _field in [
#                       'sample_name', 'sample_number',  
#                       'sample_lane', 'sample_read', 'sample_chunknb'
#                      ]
#                     ]
#                   ]
#                 ]) + "({})".format(regex_fields['sample_extension'])

#  _fields_regex_str = field_sep.join(
#    [
#      "({})".format(fastq_field.regex) 
#        for fastq_field in fastq_fields
#        if fastq_field.in_basename
#    ]) + "({})".format(
#        fastq_fieldsregex_fields['sample_extension'])

  fields_regex_str = field_sep.join(
    [
      "({})".format(regex) 
      for regex in [
        regex_fields['sample_name'], 
        regex_fields['sample_number'], 
        regex_fields['sample_lane'], 
        regex_fields['sample_read'], 
        regex_fields['sample_chunknb']
      ]
    ]) + "({})".format(
        regex_fields['sample_extension'])

  def __init__(self, filename, run_name=""):
    self.sample_path = os.path.abspath(filename).strip()
    self.sample_basename = os.path.basename(self.sample_path)
    (
      self.sample_name, 
      self.sample_number, 
      self.sample_lane, 
      self.sample_read,
      self.sample_chunknb, 
      self.sample_extension,
    ) = re.search(
          self.fields_regex_str, 
          self.sample_basename
        ).groups()
    self.sample_chunkname = self.sample_basename.rstrip(self.sample_extension)
    self.sample_run = run_name 

  @classmethod
  def fieldNames(cls):
    return list(cls.regex_fields.keys())
