#!/usr/bin/env bash
set -eEu -o pipefail

# shellcheck disable=SC1091
source ./bash_cli.bash

function mycommand () {
  local doc
  bcli_doc "
    This is a subcommand
    OPTIONS:
      --help           print this message
      --custom <value> set a custom value to use
    ARGS:
      field   Some custom field
  "
  bcli_parse_opts "$doc" "$@"
  if [[ "${BCLI_SUBCOMMAND:-}" == help || -n "${BCLI_OPT_VALUES[,--help]:-}" ]]; then
    echo "$doc"
    return 0
  fi
  echo "Custom option was set to: ${BCLI_OPT_VALUES[,--custom]:-}"
  echo "Field was passed as: ${BCLI_ARG_VALUES[field]:-}"
}

function main() {
  local doc
  bcli_doc "
    This is a test CLI
    OPTIONS:
      --help                    print this message
      -c,--config <filename>    Config file to use
    ARGS:
    SUBCOMMANDS:
      help        Print this message
      mycommand   Dummy first command
      cmd2        Dummy second command
  "
  bcli_parse_opts "$doc" "$@"
  if [[ "${BCLI_SUBCOMMAND:-}" == help || -n "${BCLI_OPT_VALUES[,--help]:-}" ]]; then
    echo "$doc"
    return 0
  fi
  echo "Config is ${BCLI_OPT_VALUES[-c,--config]:-}"
  echo "Args are: ${BCLI_ARG_VALUES[*]}"
  echo "Subcommand is: ${BCLI_SUBCOMMAND:-}"
  echo "Remaining is: ${BCLI_REMAINING[*]}"
  if [[ "${BCLI_SUBCOMMAND:-}" == mycommand ]]; then
    echo "Calling subcommand"
    mycommand "${BCLI_REMAINING[@]}"
  fi
}

main "$@"
