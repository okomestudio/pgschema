#!/usr/bin/env bats

load helpers

@test "[full] up and down" {
  EMPTY_SCHEMA="$(mktemp)"
  pg_dump -s >$EMPTY_SCHEMA

  run ./update -all
  run ./rollback -all

  diff <(pg_dump -s) $EMPTY_SCHEMA
  result=$?

  rm $EMPTY_SCHEMA
  return $result
}
