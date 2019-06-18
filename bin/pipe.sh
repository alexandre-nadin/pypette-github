# -------------------------
# Command Base Parameters
# -------------------------
function pipe::cmdPrefix() {
  printf "pipe-"
}

function pipe::extless() {
  printf ${1%%.*}
}

function pipe::cmd() {
  #
  # File sourcing the current file.
  #
  echo "sources: ${BASH_SOURCE[@]}" >&2
  basename "${BASH_SOURCE[1]}"
}

function pipe::dir() {
  readlink -f $(dirname ${BASH_SOURCE[1]})
}

function pipe::cmdType() {
  pipe::type \
    $(pipe::cmdType 
      $(pipe::extless
        $(pipe::cmd)))
}

function pipe::type() {
  printf "${1##$(pipe::cmdPrefix)}"
}


# -----------------
# Command parsing
# -----------------
function pipe::msgManual() {
  cat << eol
Please consult the following help:
$(manual)
eol
}

function pipe::checkProject() {
  pipe::isParamGiven "$PROJECT" || pipe::errorParamNotGiven "PROJECT"
}

function pipe::isParamGiven() {
  [ ! -z ${1:+x} ] 
}

function pipe::msgParamNotGiven() {
  cat << eol
Parameter ${1} not given.
eol
}

# -----
# Qsub
# -----

# -------
# Errors
# -------
function pipe::errorParamNotGiven() {
  pipe::errexit "$(pipe::msgParamNotGiven $1)"
}

function pipe::verbecho() {
  ${VERBOSE} && printf "$@\n" || : 
}

function pipe::infecho() {
  printf "Info: $@\n"
}

function pipe::errexit() {
  printf "Error: $@\n\n"
  pipe::msgManual
  exit 1
}

function pipe::msgUnrecOpt() {
  cat << eol
Unrecognized option '$@'.
eol
}

function pipe::errorUnrecOpt() {
  pipe::errexit "$(pipe::msgUnrecOpt $@)"
}
