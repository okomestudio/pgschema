#!/bin/bash

havearg() {
  name="$1"
  shift
  for arg in $@; do
    if [ "$arg" = "$name" ]; then
      return 0
    fi
  done
  return 1
}


argval() {
  name="$1"
  shift

  while true; do
    case $1 in
      $name)
        shift
        echo $1
        return 0
        ;;
      "")
        return 1
        ;;
    esac

    shift
  done
}


query() {
  psql -Atqc "$1"
}


migrate() {
  path="$(pathfor $1 $2)"

  if [ -z "$DRYRUN" ]; then
    echo "running $path"

    psql -v 'ON_ERROR_STOP=1' -q <$path

    update=1
    if [ "$2" = "up" ]; then
      next="$1"
    elif [ "$1" = "1" ]; then
      update=0
    else
      next="$(($1-1))"
    fi

    if [ "$update" = "1" ]; then
      psql -v 'ON_ERROR_STOP=1' -q -c "UPDATE schema_state SET current = $next;"
    fi

  else
    echo would run $path
  fi
}


pathfor() {
  echo "migrate/$(printf '%02d' $1).${2}.sql"
}


existingfiles() {
  while read num; do
    path="$(pathfor $num $1)"
    test -e "$path" && echo "$num" || true
  done
}
