#!/usr/bin/env bats

load helpers

@test "[0001] up and down" {
  test_up_and_down 1
}

@test "[0001] tables exist" {
  run ./update -through 1

  table_exists person;
  table_exists pgschema_state;
}
