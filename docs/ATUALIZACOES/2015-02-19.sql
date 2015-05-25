START TRANSACTION;

DROP TRIGGER IF EXISTS trgrvalidaevento ON evento;

DROP TRIGGER IF EXISTS trgrvalidausuario ON pessoa;

ALTER TABLE evento_participacao
	DROP CONSTRAINT evento_participacao_pk;

ALTER TABLE evento_participacao
	DROP CONSTRAINT IF EXISTS evento_realizacao_evento_participacao_fk;

DROP TABLE IF EXISTS evento_realizacao_multipla;

DROP SEQUENCE IF EXISTS evento_realizacao_multipla_evento_realizacao_multipla_seq;

CREATE SEQUENCE artigo_id_artigo_seq
	START WITH 1
	INCREMENT BY 1
	NO MAXVALUE
	NO MINVALUE
	CACHE 1;

CREATE SEQUENCE tipo_horario_id_tipo_horario_seq
	START WITH 1
	INCREMENT BY 1
	NO MAXVALUE
	NO MINVALUE
	CACHE 1;

CREATE TABLE artigo (
	id_artigo integer DEFAULT nextval('artigo_id_artigo_seq'::regclass) NOT NULL,
	nomearquivo_original character varying(255),
	tamanho integer,
	criado timestamp with time zone NOT NULL,
	responsavel integer NOT NULL,
	id_encontro integer NOT NULL,
	dados bytea NOT NULL,
	titulo character varying(255),
	aceito boolean DEFAULT false NOT NULL,
	deletado boolean DEFAULT false NOT NULL,
	dt_delecao timestamp without time zone,
	dt_aceitacao timestamp without time zone
);

CREATE TABLE tipo_horario (
	id_tipo_horario integer DEFAULT nextval('tipo_horario_id_tipo_horario_seq'::regclass) NOT NULL,
	intervalo_minutos integer NOT NULL,
	horario_inicial time without time zone NOT NULL,
	horario_final time without time zone NOT NULL
);

INSERT INTO tipo_horario (intervalo_minutos, horario_inicial, horario_final) VALUES (60, '08:00', '17:00');

ALTER TABLE caravana
	ALTER COLUMN nome_caravana TYPE character varying(255) /* TYPE change - table: caravana original: character varying(100) new: character varying(255) */;

COMMENT ON COLUMN caravana_encontro.responsavel IS 'Responsável pela caravana.
Seu cadastro deve estar realizado previamente.';

COMMENT ON TABLE dificuldade_evento IS 'Mostra o nível de dificuldade do Evento.
Básico
Intermediário
Avançado';

ALTER TABLE encontro
	ADD COLUMN certificados_liberados boolean DEFAULT false NOT NULL,
	ADD COLUMN certificados_template_participante_encontro text DEFAULT 'Certificamos que {nome} participou do(a) {encontro} no período de 10 a 12 de Outubro de 1999.'::text,
	ADD COLUMN certificados_template_palestrante_evento text DEFAULT 'Certificamos que {nome} apresentou o(a) {tipo_evento}: {nome_evento} no(a) {encontro} no período de 10 a 12 de Outubro de 1999, com carga horária de {carga_horaria}.'::text,
	ADD COLUMN certificados_template_participante_evento text DEFAULT 'Certificamos que {nome} participou do(a) {tipo_evento}: {nome_evento} no(a) {encontro} no período de 10 a 12 de Outubro de 1999, com carga horária de {carga_horaria}.'::text,
	ADD COLUMN id_municipio integer DEFAULT 1 NOT NULL,
	ADD COLUMN id_tipo_horario integer DEFAULT 1 NOT NULL,
	ALTER COLUMN nome_encontro TYPE character varying(255) /* TYPE change - table: encontro original: character varying(100) new: character varying(255) */,
	ALTER COLUMN apelido_encontro TYPE character varying(50) /* TYPE change - table: encontro original: character varying(10) new: character varying(50) */;

COMMENT ON COLUMN encontro.id_municipio IS 'Padrão Maracanaú';

ALTER TABLE evento
	ADD COLUMN id_artigo integer,
	ALTER COLUMN nome_evento TYPE character varying(255) /* TYPE change - table: evento original: character varying(100) new: character varying(255) */;

ALTER TABLE evento_participacao
	DROP COLUMN evento,
	ADD COLUMN id_evento_realizacao integer NOT NULL;

COMMENT ON COLUMN instituicao.apelido_instituicao IS 'EEMF Adauto Bezerra.
Essa informação pode estar no CRACHÁ.';

ALTER TABLE mensagem_email
	ADD COLUMN assinatura_email character varying(255),
	ADD COLUMN assinatura_siteoficial character varying(255);

ALTER TABLE pessoa
	ALTER COLUMN nome TYPE character varying(255) /* TYPE change - table: pessoa original: character varying(100) new: character varying(255) */;

COMMENT ON COLUMN pessoa.endereco_internet IS 'Um endereço começando com http:// indicando onde estão as informações da pessoa.
Pode ser um blog, página do facebook, site...';

ALTER TABLE pessoa ADD COLUMN token character varying(32);
ALTER TABLE pessoa ADD COLUMN token_validade timestamp without time zone;

CREATE TABLE pessoa_mudar_email
(
	id serial NOT NULL,
	email_anterior character varying(100) NOT NULL,
	novo_email character varying(100) NOT NULL,
	motivo text NOT NULL,
	data_submissao timestamp without time zone NOT NULL DEFAULT now(),
	ultima_atualizacao timestamp without time zone,
	atualizado_por integer,
	status boolean,
	CONSTRAINT pessoa_mudar_email_pkey PRIMARY KEY (id),
	CONSTRAINT pessoa_mudar_email_atualizado_por_fkey FOREIGN KEY (atualizado_por)
		REFERENCES pessoa (id_pessoa) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE NO ACTION
);

ALTER TABLE pessoa_mudar_email
  OWNER TO postgres;
COMMENT ON COLUMN pessoa_mudar_email.status IS 'null para aberto, false para negado e true para atualizado.';

ALTER SEQUENCE artigo_id_artigo_seq
	OWNED BY artigo.id_artigo;

ALTER SEQUENCE tipo_horario_id_tipo_horario_seq
	OWNED BY tipo_horario.id_tipo_horario;

CREATE OR REPLACE FUNCTION funcgerarsenha(codemail character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
/*
Criador: Siqueira, Robson.
Data: 05/08/2011.
DESCRIÇÃO:
  A partir de um email válido, gera uma senha de 10 caracteres com letras maiúsculas e números.
  Se o email estiver incorreto, gera uma exceção.
  A senha já é armazenada no BD com criptografia MD5.
*/
DECLARE
  codPessoa INTEGER;
  codSenha VARCHAR(100);
BEGIN
	SELECT id_pessoa INTO codPessoa
	FROM pessoa
	WHERE email = codEmail;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'Email Inválido';
	END IF;

	codSenha = (((random() * (100000000000000)::double precision))::bigint)::character varying;
	SELECT UPPER(md5(codSenha)::varchar(10)) INTO codSenha;
	UPDATE pessoa
	SET senha = md5(codSenha)
	WHERE id_pessoa = codPessoa;
	RETURN codSenha;
END;
$$;

CREATE OR REPLACE FUNCTION funcvalidaevento() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF NEW.validada = 'T' THEN
	    NEW.data_validacao = now();
	END IF;
	RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION funcvalidausuario() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF NEW.cadastro_validado = 'T' THEN
		NEW.data_validacao_cadastro = now();
	END IF;
	RETURN NEW;
END;
$$;

ALTER TABLE artigo
	ADD CONSTRAINT artigo_pkey PRIMARY KEY (id_artigo);

ALTER TABLE evento_participacao
	ADD CONSTRAINT evento_participacao_pk PRIMARY KEY (id_evento_realizacao, id_pessoa);

ALTER TABLE tipo_horario
	ADD CONSTRAINT tipo_horario_pkey PRIMARY KEY (id_tipo_horario);

ALTER TABLE artigo
	ADD CONSTRAINT artigo_id_encontro_fkey FOREIGN KEY (id_encontro) REFERENCES encontro(id_encontro);

ALTER TABLE artigo
	ADD CONSTRAINT artigo_id_pessoa_fkey FOREIGN KEY (responsavel) REFERENCES pessoa(id_pessoa);

ALTER TABLE encontro
	ADD CONSTRAINT encontro_id_municipio_fkey FOREIGN KEY (id_municipio) REFERENCES municipio(id_municipio) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE encontro
	ADD CONSTRAINT encontro_id_tipo_horario_fkey FOREIGN KEY (id_tipo_horario) REFERENCES tipo_horario(id_tipo_horario);

ALTER TABLE evento
	ADD CONSTRAINT evento_id_artigo_fkey FOREIGN KEY (id_artigo) REFERENCES artigo(id_artigo);

ALTER TABLE evento_participacao
	ADD CONSTRAINT evento_realizacao_evento_participacao_fk FOREIGN KEY (id_evento_realizacao) REFERENCES evento_realizacao(evento);

ALTER TABLE pessoa
	ADD CONSTRAINT pessoa_email_key UNIQUE (email);

CREATE UNIQUE INDEX artigo_id_artigo_key ON artigo USING btree (id_artigo);

ROLLBACK;
