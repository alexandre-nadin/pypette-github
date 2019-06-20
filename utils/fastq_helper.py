#!/usr/bin/env python
import os
import sys
import re
from collections import OrderedDict
import addict

## Illumina naming convention: 
class FastqFile(object):
  # This class helps to get a fastq file's information.
  # The file should respect Illumina filename convention:
  #   /path/to/SampleName_SampleNumber_LaneNumber_ReadNumber_ChunkNumber.fastq_extension
  # 

  regex_fields = addict.Dict(
    ('sample_name',      "\w+"       ),
    ('sample_number',    "S\d+"      ),
    ('sample_lane',      "L\d+"      ),
    ('sample_read',      "R[12]"     ),
    ('sample_chunknb',   "\d+"       ),
  )
  field_sep = '_'

  regex_fields.update({
    'sample_path':      "\w+",
    'sample_run':       "\w+",
    'sample_basename':  "\w+",
    'sample_chunkname': field_sep.join(val for key, val in regex_fields.items()),
    'sample_extension': "\.fastq\.gz" 
  })

  fields_regex_str = field_sep.join(
    [
      f"({regex})" 
      for regex in [
        regex_fields['sample_name'], 
        regex_fields['sample_number'], 
        regex_fields['sample_lane'], 
        regex_fields['sample_read'], 
        regex_fields['sample_chunknb']
      ]
    ]) + f"({regex_fields['sample_extension']})"

  def __init__(self, filename, run_name=""):
    self.sample_path = os.path.abspath(filename).strip()
    self.sample_basename = os.path.basename(self.sample_path)
   
    try:
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
    except AttributeError as ae:
      sys.stderr.write(f"File {filename} doesn't seem to follow Illumina's fastq naming convention.\n")

    self.sample_chunkname = self.sample_basename.rstrip(self.sample_extension)
    self.sample_run = run_name 

  @classmethod
  def fieldNames(cls):
    return list(cls.regex_fields.keys())
