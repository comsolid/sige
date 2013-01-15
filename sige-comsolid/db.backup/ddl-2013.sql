ALTER TABLE evento
   ADD COLUMN apresentado boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN evento.apresentado IS 'indica que o palestrante realmente veio e participou';

ALTER TABLE pessoa ADD COLUMN bio text;