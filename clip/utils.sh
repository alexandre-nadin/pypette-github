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
   | head -1
}
