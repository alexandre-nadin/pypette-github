#bash

# ------------
# Temporaries
# ------------
GNMS_TMP_EXTS='gz\|bed\|gtf\|fa\|fasta'

genomes-tmps ()
#
# Lists all temporaries for genomes.
#
{
  find genomes -type f -regex ".*\(${GNMS_TMP_EXTS}\)"
}

genomes-rm-tmps ()
#
# Removes all temporaries for genomes.
#
{
  genomes-tmps | xargs rm
}

# ---------------
# User Commands
# ---------------
clip-add-usr-cmds              \
  genomes-tmps genomes-rm-tmps
