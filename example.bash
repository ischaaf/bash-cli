#!/usr/bin/env bash
set -eEu -o pipefail

# shellcheck disable=SC1091
source ./bash_cli.bash

function mycommand () {
  local doc="\
    This is a subcommand
    OPTIONS:
      --custom <value> set a custom value to use
    ARGS:
      field   Some custom field
  "
  echo "Using: $*"
  bcli_parse_opts "$doc" "$@"
  echo "Custom option was set to: ${BCLI_OPT_VALUES[,--custom]:-}"
  echo "Field was passed as: ${BCLI_ARG_VALUES[field]:-}"
}

function main() {
  local doc="\
    This is a test CLI
    OPTIONS:
      -c,--config <filename>    Config file to use
    ARGS:
      input The input filename
    SUBCOMMANDS:
      mycommand   Dummy first command
      cmd2        Dummy second command
  "
  bcli_parse_opts "$doc" "$@"
  echo "Config is ${BCLI_OPT_VALUES[-c,--config]:-}"
  echo "Args are: ${BCLI_ARG_VALUES[*]}"
  echo "Subcommand is: ${BCLI_SUBCOMMAND:-}"
  echo "Remaining is: ${BCLI_REMAINING[*]}"
  local input="${BCLI_ARG_VALUES[input]}"
  echo "Input is: $input"
  if [[ "${BCLI_SUBCOMMAND:-}" == mycommand ]]; then
    echo "Calling subcommand"
    mycommand "${BCLI_REMAINING[@]}"
  fi
}

main "$@"
