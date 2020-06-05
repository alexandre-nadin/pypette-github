#bash

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
  while read -r line; do
    for var in $line; do 
      printf -- "$var: ${!var}\n"
    done
  done < <(cat /dev/stdin)
}
