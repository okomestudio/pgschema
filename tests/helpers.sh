###############################################################################
# Bats PostgreSQL migration test helpers
#
# No need to call setup or teardown explicitly; their presence causes
# them to be run before/after every individual test.

setup() {
  # Use these environment variables to connect to postgres.
  export PGHOST PGPORT PGUSER PGPASSWORD
  export PGDATABASE="$(head -c9 /dev/urandom | base64)"

  # Create a new database with a nice random name.
  createdb $PGDATABASE
}

teardown() {
  dropdb $PGDATABASE
}


# Test that the schema is unchanged by a given ($1) up-and-down.
test_up_and_down() {
  # Go to the schema right before applying $1 and record the schema.
  run ./update -until "$1"
  START_SCHEMA="$(mktemp)"
  show_schema >$START_SCHEMA

  # Go up and back down for the tested schema.
  run ./update -next
  run ./rollback -next

  # Compare the resulting schema with the recorded one.
  diff $START_SCHEMA <(show_schema)
  result=$?

  # Clean up and return the appropriate error code.
  rm $START_SCHEMA
  return $result
}

# Dump a representation of the schema.
show_schema() {
  PGDATABASE=${PGDATABASE-public}

  tables="$(psql -At <<EOF
SELECT table_name
FROM information_schema.tables
WHERE table_schema='$PGDATABASE'
ORDER BY 1;
EOF
)"
  echo "$tables" | while read table
  do
    echo "table: $table"

    columns="$(psql -At <<EOF
SELECT column_name, column_default, is_nullable, data_type
FROM information_schema.columns
WHERE table_schema='$PGDATABASE' AND table_name='$table'
ORDER BY 1;
EOF
)"
    echo "$columns" | while read column
    do
      echo " - column: $column"
    done

    indexes="$(psql -At <<EOF
SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname='$PGDATABASE' AND tablename='$table'
ORDER BY 1;
EOF
)"
    echo "$indexes" | while read index
    do
      echo " - index: $index"
    done

    constraints="$(psql -At <<EOF
SELECT constraint_name, constraint_type, is_deferrable, initially_deferred
FROM information_schema.table_constraints
WHERE
  table_schema='$PGDATABASE'
  AND table_name='$table'
  AND constraint_name NOT LIKE '%_not_null'
ORDER BY 1;
EOF
)"
    echo "$constraints" | while read constraint
    do
      echo " - constraint: $constraint"
    done
  done
}

# Test that a table ($1) exists in the schema.
table_exists() {
  psql -Atc '\d' | cut -d\| -f2,3 | grep -Eq "^$1\|table$"
}

# Test that a table ($1) exists in the attic schema.
attic_table_exists() {
  psql -Atc '\dt attic.*' | cut -d\| -f2,3 | grep -Eq "^$1\|table$"
}

# Test that a type ($1) exists in the schema.
type_exists() {
  psql -Atc '\dT' | cut -d\| -f2 | grep -Eq "^$1$"
}

# Test that a column ($2) exists on a table ($1).
column_exists() {
  psql -Atc "\\d $1" | cut -d\| -f1 | grep -Eq "^$2$"
}

# Test that a column ($2) on a table ($1) has a default value ($3).
column_has_default() {
  psql -Atc "\\d $1" | cut -d\| -f1,3 | grep -q "$2|default $3"
}

# Test that a column ($2) on a table ($1) has constraint ($3).
column_has_constraint() {
  psql -Atc "\\d $1" | cut -d\| -f1,3 | grep -q "$2|$3"
}

# Test that a table ($1) has a row that satisfies clause ($2).
row_exists() {
  test "$(psql -Atc "SELECT COUNT(*) FROM $1 WHERE $2;")" != "0"
}

# Test that a table ($1) has N ($2) records.
n_rows_exist() {
  test "$(psql -Atc "SELECT COUNT(*) FROM $1;")" == "$2"
}

# Test that an index ($1) exists.
index_exists() {
  psql -Atc "\\di $1" | grep -q "|$1|"
}

# Test that a function ($1) exists.
function_exists() {
  psql -Atc "\\df $1" | grep -q "|$1|"
}
