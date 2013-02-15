ALTER TABLE evento
   ADD COLUMN apresentado boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN evento.apresentado IS 'indica que o palestrante realmente veio e participou';

ALTER TABLE pessoa ADD COLUMN bio text;

ALTER TABLE public.evento DROP COLUMN curriculum;
ALTER TABLE public.evento ADD COLUMN tecnologias_envolvidas text;

-- upgrade versao 1.1.2
ALTER TABLE pessoa ADD COLUMN slideshare character varying(32);
