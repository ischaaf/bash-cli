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
  bcli_parse_opts "m_" "$doc" "$@"
  if [[ "${m_subcmd:-}" == help || -n "${m_help:-}" ]]; then
    echo "$doc"
    return 0
  fi
  echo "Custom option was set to: ${m_custom:-}"
  echo "Field was passed as: ${m_field:-}"
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
  # local subcommand help config
  bcli_parse_opts "" "$doc" "$@"
  if [[ "${subcmd:-}" == help || -n "${help:-}" ]]; then
    echo "$doc"
    return 0
  fi
  echo "Config is ${config}"
  echo "Subcommand is: ${subcmd:-}"
  echo "Remaining is: ${BCLI_REMAINING[*]}"
  if [[ "${subcmd:-}" == mycommand ]]; then
    echo "Calling subcommand"
    mycommand "${BCLI_REMAINING[@]}"
  fi
}

main "$@"
