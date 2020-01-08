samples__wildcardFields = { 
  'samples': 'sample_name', 
  'runs'   : 'sample_run', 
}

sampleWildcardRegex  = "\[(\w+)\]"

def samples__formatWildcardString(s):
  """
  Replaces the given string's wildcard delimitors by Snakemake's.
  """
  return s.replace('[', '{').replace(']', '}')

def samples__wildcardOutput(**kwargs):
  """
  Joins the given dict's values.
  """
  return "".join(kwargs.values())

def samples__formatWildcardOutput(**kwargs):
  """
  Builds a Snakemake output from the given dict.
  """
  return samples__formatWildcardString(samples__wildcardOutput(**kwargs))

def samples__wildcardFilters(wcOutput):
  wcFilters = {}
  import re
  for agg, field in samples__wildcardFields.items():
    searchStr = f"{agg}/(\w+)"
    match = re.search(searchStr, wcOutput)
    if match:
      wcFilters[field] = match.groups()[0]
  return wcFilters

def samples__mapWildcardString(**kwargs):
  """
  Takes a dict and does the following from it:
   - builds expected wildcard output;
   - maps matching samples according to the expected samples' wildcardFields.
  """
  wcOutput   = samples__formatWildcardOutput(**kwargs)
  wcFilters  = samples__wildcardFilters(wcOutput)
  return pypette.samples.map(wcOutput, **wcFilters)
