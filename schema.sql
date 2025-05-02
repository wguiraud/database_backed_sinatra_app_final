CREATE TABLE lists (
                       id serial PRIMARY KEY,
                       name text NOT NULL UNIQUE
);

CREATE TABLE todos (
                       id serial PRIMARY KEY,
                       name text NOT NULL,
                       completed boolean NOT NULL DEFAULT false,
                       list_id integer NOT NULL REFERENCES lists (id)
);

ALTER TABLE todos
DROP CONSTRAINT IF EXISTS todos_list_id_fkey,
ADD CONSTRAINT todos_list_id_fkey
FOREIGN KEY (list_id)
REFERENCES lists(id)
ON DELETE CASCADE;