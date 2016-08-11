BEGIN;


CREATE FUNCTION set_updated_on_update()
RETURNS TRIGGER AS
$$
BEGIN
  NEW."updated" := NOW() AT TIME ZONE 'UTC';
  RETURN NEW;
END;
$$
LANGUAGE PLPGSQL;


CREATE TABLE person (
  id      BIGSERIAL PRIMARY KEY,
  name    TEXT NOT NULL,
  age     INTEGER,
  updated TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'UTC')
);
CREATE UNIQUE INDEX person_name_uniq ON person(name);


-- PostgreSQL database migration status
CREATE TABLE pgschema_state (
  current INTEGER
);
INSERT INTO pgschema_state (current) VALUES (1);


COMMIT;
