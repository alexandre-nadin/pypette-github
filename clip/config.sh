#bash
set-raw-dir ()
{
  local lustre="${1:-2}"
  local rawDir='    rawDir:'
  local rawDirLine="^${rawDir}.*\$"
  sed -i "s|${rawDirLine}|${rawDir} \"/lustre${lustre}/raw_data\"|" config/cluster.yaml
}
