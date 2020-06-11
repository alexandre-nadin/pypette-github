#bash

grepLineNbRegex ()
{
  cat /dev/stdin | sed -e 's/^/\^/' -e 's/$/:/'
}

orRegex() {
  cat /dev/stdin | tr '\n' '|' | sed -e 's/|$//' -e 's/|/\\|/g'
}

frame() {
#
# Narrows the STDIN list.
# Requires index to start and number of following elements.
#
  cat /dev/stdin             \
  | tail -n +$((0+${1:-1}))  \
  | head -n ${2:--0}
}

procNb() {
  cat /proc/cpuinfo | grep '^processor'
}

maxCores() {
  cat /proc/cpuinfo   \
   | grep '^cpu core' \
   | cut -d: -f2      \
   | sort -t= -nr -k3 \
   | head -1          \
   | sed 's/ //'
}

freeMem ()
{
  free -g | grep 'buffers/cache' | cut -d: -f2 | awk '{print $2}' \
  || printf -- 0
}

timestamp ()
{
  date +%Y-%m-%d-%H-%M-%S
}

vars-declaration()
#
# Show shell declaration for the given variables. Reads from STDIN.
#
{
  while read -r line; do
    for var in $line; do 
      printf -- "$var='${!var}'\n"
    done
  done < <(cat /dev/stdin)
}

vars-ls()
#
# Lists given variables. Reads from STDIN.
#
{
  local vars=$(cat /dev/stdin) indent=${1:-0} indentStr='' maxLen=0 indentVar
  if [ $indent -gt 0 ]; then
    indentStr=$(str-repeat $indent <<< ' ')
  fi 

  maxLen=$(tr ' ' '\n' <<< "$vars" | str-len | nb-max)
  for var in $vars; do 
    indentVar=$(str-repeat $((maxLen + 1 - ${#var})) <<< ' ')
    printf -- "${indentStr}${var}${indentVar}: ${!var}\n"
  done
}

str-len ()
{
  while read -r line; do
    printf "${#line}\n"
  done
}

str-repeat ()
{
  local str=$(cat /dev/stdin) times=${1:-1}
  printf "${str}%.0s" $(seq $times)
}

nb-max ()
{
  local max=1
  while read -r nb; do
    [ $nb -gt $max ] && max=$nb || :
  done
  printf $max
}

str-join ()
{
  local sep="${1:-_}"
  cat /dev/stdin | tr '\n' "${sep[0]}" | sed "s/${sep[0]}\$//"
}
