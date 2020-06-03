#!/usr/bin/env bash

BCLI_SECTIONS=(NONE: OPTIONS: ARGS: SUBCOMMANDS:)

BCLI_OPT_RE="^(-[a-zA-Z0-9])?,?(--[^[:space:]]+)?[[:space:]]+(<([a-zA-Z0-9]+)>[[:space:]]+)?(.*)$"

function _bcli_reset () {
  unset BCLI_OPTS
  unset BCLI_ARGS
  unset BCLI_CMDS
  unset OPT_VALUES
  unset ARG_VALUES
  unset SUBCOMMAND
  unset REMAINING

  declare -agx BCLI_OPTS
  declare -agx BCLI_ARGS
  declare -agx BCLI_CMDS
  declare -Agx BCLI_OPT_VALUES
  declare -Agx BCLI_ARG_VALUES
  declare -gx  BCLI_SUBCOMMAND
  declare -agx BCLI_REMAINING
  BCLI_OPTS=()
  BCLI_ARGS=()
  BCLI_CMDS=()
}

function _bcli_parse_doc () {
  _bcli_reset
  local doc section
  doc="$1"
  shift
  section="NONE:"
  while read -r line; do
    # shellcheck disable=SC2076
    if [[ "${BCLI_SECTIONS[*]}" =~ "${line}" ]]; then
      # echo "Changing section to: $line"
      section="$line"
      continue
    fi
    case "$section" in
      NONE:)
        continue
        ;;
      OPTIONS:)
        if [[ "$line" =~ $BCLI_OPT_RE ]]; then
          set +u
          short="${BASH_REMATCH[1]}"
          long="${BASH_REMATCH[2]}"
          set -u
        else
          echo "Invalid Option Format: $line"
          return 1
        fi
        BCLI_OPTS+=("$line")
        continue
        ;;
      ARGS:)
        BCLI_ARGS+=("${line%%[[:space:]]*}")
        continue
        ;;
      SUBCOMMANDS:)
        BCLI_CMDS+=("${line%%[[:space:]]*}")
        continue
        ;;
    esac;
    echo "doc line: $line"
  done <<< "$doc"
}

function bcli_doc () {
  # Kinda hacky right now, assume indent is 2 spaces
  # This means the string should have 4 spaces of extra
  # indent, remove with sub and save to doc variable
  doc="${1//$'\n'    /$'\n'}"
}

function bcli_parse_opts () {
  local doc
  doc="$1"
  shift
  _bcli_parse_doc "$doc"
  # echo "[BCLI] Starting arg parse, \$* is: '$*'"

  # Start Arg Parsing
  cur_arg=0
  while (( "$#" )); do
    case "$1" in
      --)
        shift;
        BCLI_REMAINING+=("$@")
        break;
        ;; # End arg parsing
      -*) # Parse option
        # echo "Parsing opt: $1"
        opt_set=""
        for opt in "${BCLI_OPTS[@]}"; do
          # echo "Checking opt line: $opt"
          [[ "$opt" =~ $BCLI_OPT_RE ]]
          set +u
          short="${BASH_REMATCH[1]}"
          long="${BASH_REMATCH[2]}"
          arg_name="${BASH_REMATCH[4]}"
          # desc="${BASH_REMATCH[5]}"
          set -u
          # echo "Checking with $short,$long"
          if [[ "$1" == "$short" || "$1" == "$long" ]]; then
            if [[ -n "$arg_name" ]]; then
              # echo "Setting opt: $1 to value $2"
              BCLI_OPT_VALUES["$short,$long"]="$2"
              shift 2
            else
              # echo "Setting flag: $1"
              BCLI_OPT_VALUES["$short,$long"]="1"
              shift
            fi
            opt_set="1"
            break
          fi
        done
        if [[ -z "$opt_set" ]]; then
          echo "Invalid option $1"
          echo "$doc"
          return 1
        fi
        ;;
      *)
        if [[ "$cur_arg" -lt "${#BCLI_ARGS[@]}" ]]; then
          echo "[BCLI] Setting positional arg: ${BCLI_ARGS[$cur_arg]} to $1"
          BCLI_ARG_VALUES["${BCLI_ARGS[$cur_arg]}"]="$1"
          cur_arg=$((cur_arg + 1))
          shift
        elif [[ -z "${SUBCOMMAND:-}" && "${#BCLI_CMDS[@]}" ]]; then
          for cmd in "${BCLI_CMDS[@]}"; do
            if [[ "$cmd" == "$1" ]]; then
              echo "[BCLI] Setting subcommand to $1"
              BCLI_SUBCOMMAND="$1"
              shift
              BCLI_REMAINING+=("$@")
              return
            fi
          done
          echo "Error invalid subcommand: $1"
          return 1
        else
          echo "[BCLI] Adding $1 to remaining"
          BCLI_REMAINING+=("$1")
          shift
        fi
        ;;
    esac
  done
}
