START TRANSACTION;

--
-- PostgreSQL database dump
--

-- Dumped from database version 9.2.2
-- Dumped by pg_dump version 9.2.2
-- Started on 2013-01-24 18:37:21 BRT

SET statement_timeout = 0;
SET client_encoding = 'UTF-8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- TOC entry 205 (class 3079 OID 11773)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 2215 (class 0 OID 0)
-- Dependencies: 205
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- TOC entry 220 (class 1255 OID 21200)
-- Name: funcgerarsenha(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION funcgerarsenha(codemail character varying) RETURNS character varying
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


SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 168 (class 1259 OID 21207)
-- Name: caravana; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE caravana (
    id_caravana integer NOT NULL,
    nome_caravana character varying(100) NOT NULL,
    apelido_caravana character varying(20) NOT NULL,
    id_municipio integer NOT NULL,
    id_instituicao integer,
    criador integer NOT NULL
);


--
-- TOC entry 169 (class 1259 OID 21210)
-- Name: caravana_encontro; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE caravana_encontro (
    id_caravana integer NOT NULL,
    id_encontro integer NOT NULL,
    responsavel integer NOT NULL,
    validada boolean DEFAULT false NOT NULL
);


--
-- TOC entry 2216 (class 0 OID 0)
-- Dependencies: 169
-- Name: COLUMN caravana_encontro.responsavel; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN caravana_encontro.responsavel IS 'Responsável pela caravana.
Seu cadastro deve estar realizado previamente.';


--
-- TOC entry 170 (class 1259 OID 21214)
-- Name: caravana_id_caravana_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE caravana_id_caravana_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2217 (class 0 OID 0)
-- Dependencies: 170
-- Name: caravana_id_caravana_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE caravana_id_caravana_seq OWNED BY caravana.id_caravana;


--
-- TOC entry 171 (class 1259 OID 21216)
-- Name: dificuldade_evento; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE dificuldade_evento (
    id_dificuldade_evento integer NOT NULL,
    descricao_dificuldade_evento character varying(15) NOT NULL
);


--
-- TOC entry 2218 (class 0 OID 0)
-- Dependencies: 171
-- Name: TABLE dificuldade_evento; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE dificuldade_evento IS 'Mostra o nível de dificuldade do Evento.
Básico
Intermediário
Avançado';


--
-- TOC entry 172 (class 1259 OID 21219)
-- Name: encontro; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE encontro (
    id_encontro integer NOT NULL,
    nome_encontro character varying(100) NOT NULL,
    apelido_encontro character varying(10) NOT NULL,
    data_inicio date NOT NULL,
    data_fim date NOT NULL,
    ativo boolean DEFAULT false NOT NULL
);


--
-- TOC entry 173 (class 1259 OID 21223)
-- Name: encontro_horario; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE encontro_horario (
    id_encontro_horario integer NOT NULL,
    descricao character varying(20) NOT NULL,
    hora_inicial time without time zone NOT NULL,
    hora_final time without time zone NOT NULL,
    CONSTRAINT encontro_horario_check CHECK ((hora_inicial < hora_final))
);


--
-- TOC entry 174 (class 1259 OID 21227)
-- Name: encontro_horario_id_encontro_horario_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE encontro_horario_id_encontro_horario_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2219 (class 0 OID 0)
-- Dependencies: 174
-- Name: encontro_horario_id_encontro_horario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE encontro_horario_id_encontro_horario_seq OWNED BY encontro_horario.id_encontro_horario;


--
-- TOC entry 175 (class 1259 OID 21229)
-- Name: encontro_id_encontro_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE encontro_id_encontro_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2220 (class 0 OID 0)
-- Dependencies: 175
-- Name: encontro_id_encontro_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE encontro_id_encontro_seq OWNED BY encontro.id_encontro;


--
-- TOC entry 176 (class 1259 OID 21231)
-- Name: encontro_participante; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE encontro_participante (
    id_encontro integer NOT NULL,
    id_pessoa integer NOT NULL,
    id_instituicao integer,
    id_municipio integer NOT NULL,
    id_caravana integer,
    id_tipo_usuario integer DEFAULT 3 NOT NULL,
    validado boolean DEFAULT false NOT NULL,
    data_validacao timestamp without time zone,
    data_cadastro timestamp without time zone DEFAULT now() NOT NULL,
    confirmado boolean DEFAULT false NOT NULL,
    data_confirmacao timestamp without time zone
);


--
-- TOC entry 177 (class 1259 OID 21238)
-- Name: estado; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE estado (
    id_estado integer NOT NULL,
    nome_estado character varying(30) NOT NULL,
    codigo_estado character(2) NOT NULL
);


--
-- TOC entry 178 (class 1259 OID 21241)
-- Name: estado_id_estado_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE estado_id_estado_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2221 (class 0 OID 0)
-- Dependencies: 178
-- Name: estado_id_estado_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE estado_id_estado_seq OWNED BY estado.id_estado;


--
-- TOC entry 179 (class 1259 OID 21243)
-- Name: evento; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE evento (
    id_evento integer NOT NULL,
    nome_evento character varying(100) NOT NULL,
    id_tipo_evento integer NOT NULL,
    id_encontro integer NOT NULL,
    validada boolean DEFAULT false NOT NULL,
    resumo text NOT NULL,
    responsavel integer NOT NULL,
    data_validacao timestamp without time zone,
    data_submissao timestamp without time zone DEFAULT now() NOT NULL,
    curriculum text DEFAULT 'Curriculum Básico'::text NOT NULL,
    id_dificuldade_evento integer DEFAULT 1 NOT NULL,
    perfil_minimo text DEFAULT 'Perfil Mínimo do Participante'::text NOT NULL,
    preferencia_horario text,
    apresentado boolean DEFAULT false NOT NULL
);


--
-- TOC entry 2222 (class 0 OID 0)
-- Dependencies: 179
-- Name: TABLE evento; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE evento IS 'Evento é qualquer tipo de atividade no Encontro: Palestra, Minicurso, Oficina.';


--
-- TOC entry 2223 (class 0 OID 0)
-- Dependencies: 179
-- Name: COLUMN evento.validada; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN evento.validada IS 'O administrador deve indicar qual o evento aprovado.';


--
-- TOC entry 2224 (class 0 OID 0)
-- Dependencies: 179
-- Name: COLUMN evento.apresentado; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN evento.apresentado IS 'indica que o palestrante realmente veio e participou';


--
-- TOC entry 180 (class 1259 OID 21254)
-- Name: evento_arquivo_id_evento_arquivo_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE evento_arquivo_id_evento_arquivo_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 181 (class 1259 OID 21256)
-- Name: evento_arquivo; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE evento_arquivo (
    id_evento_arquivo integer DEFAULT nextval('evento_arquivo_id_evento_arquivo_seq'::regclass) NOT NULL,
    id_evento integer NOT NULL,
    nome_arquivo character varying(255) NOT NULL,
    arquivo oid NOT NULL,
    nome_arquivo_md5 character varying(255) DEFAULT md5(((((random() * (1000)::double precision))::integer)::character varying)::text) NOT NULL
);


--
-- TOC entry 182 (class 1259 OID 21264)
-- Name: evento_demanda; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE evento_demanda (
    evento integer NOT NULL,
    id_pessoa integer NOT NULL,
    data_solicitacao date DEFAULT now() NOT NULL
);


--
-- TOC entry 183 (class 1259 OID 21268)
-- Name: evento_id_evento_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE evento_id_evento_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2225 (class 0 OID 0)
-- Dependencies: 183
-- Name: evento_id_evento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE evento_id_evento_seq OWNED BY evento.id_evento;


--
-- TOC entry 184 (class 1259 OID 21270)
-- Name: evento_palestrante; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE evento_palestrante (
    id_evento integer NOT NULL,
    id_pessoa integer NOT NULL
);


--
-- TOC entry 185 (class 1259 OID 21273)
-- Name: evento_participacao; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE evento_participacao (
    evento integer NOT NULL,
    id_pessoa integer NOT NULL
);


--
-- TOC entry 186 (class 1259 OID 21276)
-- Name: evento_realizacao; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE evento_realizacao (
    evento integer NOT NULL,
    id_evento integer NOT NULL,
    id_sala integer NOT NULL,
    data date NOT NULL,
    hora_inicio time without time zone,
    hora_fim time without time zone,
    descricao character varying(100) NOT NULL,
    CONSTRAINT check_horario CHECK ((hora_fim > hora_inicio))
);


--
-- TOC entry 187 (class 1259 OID 21280)
-- Name: evento_realizacao_evento_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE evento_realizacao_evento_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2226 (class 0 OID 0)
-- Dependencies: 187
-- Name: evento_realizacao_evento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE evento_realizacao_evento_seq OWNED BY evento_realizacao.evento;


--
-- TOC entry 188 (class 1259 OID 21282)
-- Name: evento_realizacao_multipla; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE evento_realizacao_multipla (
    evento_realizacao_multipla integer NOT NULL,
    evento integer NOT NULL,
    data date NOT NULL,
    hora_inicio time without time zone NOT NULL,
    hora_fim time without time zone NOT NULL,
    CONSTRAINT evento_realizacao_multipla_check CHECK ((hora_fim > hora_inicio))
);


--
-- TOC entry 189 (class 1259 OID 21286)
-- Name: evento_realizacao_multipla_evento_realizacao_multipla_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE evento_realizacao_multipla_evento_realizacao_multipla_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2227 (class 0 OID 0)
-- Dependencies: 189
-- Name: evento_realizacao_multipla_evento_realizacao_multipla_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE evento_realizacao_multipla_evento_realizacao_multipla_seq OWNED BY evento_realizacao_multipla.evento_realizacao_multipla;


--
-- TOC entry 190 (class 1259 OID 21288)
-- Name: instituicao; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE instituicao (
    id_instituicao integer NOT NULL,
    nome_instituicao character varying(100) NOT NULL,
    apelido_instituicao character varying(50) NOT NULL
);


--
-- TOC entry 2228 (class 0 OID 0)
-- Dependencies: 190
-- Name: TABLE instituicao; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE instituicao IS 'Instituição de origem da pessoa. Escola, Comunidade.';


--
-- TOC entry 2229 (class 0 OID 0)
-- Dependencies: 190
-- Name: COLUMN instituicao.apelido_instituicao; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN instituicao.apelido_instituicao IS 'EEMF Adauto Bezerra.
Essa informação pode estar no CRACHÁ.';


--
-- TOC entry 191 (class 1259 OID 21291)
-- Name: instituicao_id_instituicao_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE instituicao_id_instituicao_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2230 (class 0 OID 0)
-- Dependencies: 191
-- Name: instituicao_id_instituicao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE instituicao_id_instituicao_seq OWNED BY instituicao.id_instituicao;


--
-- TOC entry 192 (class 1259 OID 21293)
-- Name: mensagem_email; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mensagem_email (
    id_encontro integer NOT NULL,
    id_tipo_mensagem_email integer NOT NULL,
    mensagem text NOT NULL,
    assunto character varying(200) NOT NULL,
    link character varying(70)
);


--
-- TOC entry 193 (class 1259 OID 21299)
-- Name: municipio; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE municipio (
    id_municipio integer NOT NULL,
    nome_municipio character varying(40) NOT NULL,
    id_estado integer NOT NULL
);


--
-- TOC entry 194 (class 1259 OID 21302)
-- Name: municipio_id_municipio_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE municipio_id_municipio_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2231 (class 0 OID 0)
-- Dependencies: 194
-- Name: municipio_id_municipio_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE municipio_id_municipio_seq OWNED BY municipio.id_municipio;


--
-- TOC entry 195 (class 1259 OID 21304)
-- Name: pessoa; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE pessoa (
    id_pessoa integer NOT NULL,
    nome character varying(100) NOT NULL,
    email character varying(100) NOT NULL,
    apelido character varying(20) NOT NULL,
    twitter character varying(32),
    endereco_internet character varying(100),
    senha character varying(255) DEFAULT md5(((((random() * (1000)::double precision))::integer)::character varying)::text),
    cadastro_validado boolean DEFAULT false NOT NULL,
    data_validacao_cadastro timestamp without time zone,
    data_cadastro timestamp without time zone DEFAULT now(),
    id_sexo integer DEFAULT 0 NOT NULL,
    nascimento date NOT NULL,
    telefone character varying(16),
    administrador boolean DEFAULT false NOT NULL,
    facebook character varying(50),
    email_enviado boolean DEFAULT false NOT NULL,
    bio text
);


--
-- TOC entry 2232 (class 0 OID 0)
-- Dependencies: 195
-- Name: COLUMN pessoa.nome; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN pessoa.nome IS 'Nome completo e em letra Maiúscula';


--
-- TOC entry 2233 (class 0 OID 0)
-- Dependencies: 195
-- Name: COLUMN pessoa.email; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN pessoa.email IS 'email em letra minúscula';


--
-- TOC entry 2235 (class 0 OID 0)
-- Dependencies: 195
-- Name: COLUMN pessoa.endereco_internet; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN pessoa.endereco_internet IS 'Um endereço começando com http:// indicando onde estão as informações da pessoa.
Pode ser um blog, página do facebook, site...';


--
-- TOC entry 2236 (class 0 OID 0)
-- Dependencies: 195
-- Name: COLUMN pessoa.senha; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN pessoa.senha IS 'Senha do usuário usando criptografia md5 do comsolid.
Valor padrão vai ser o próprio nome do usuário.';


--
-- TOC entry 2237 (class 0 OID 0)
-- Dependencies: 195
-- Name: COLUMN pessoa.email_enviado; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN pessoa.email_enviado IS 'Indica se o sistema conseguiu conectar a um servidor de email e validar o email.';


--
-- TOC entry 196 (class 1259 OID 21316)
-- Name: pessoa_arquivo; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE pessoa_arquivo (
    id_pessoa integer NOT NULL,
    foto oid NOT NULL
);


--
-- TOC entry 197 (class 1259 OID 21319)
-- Name: pessoa_id_pessoa_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE pessoa_id_pessoa_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2238 (class 0 OID 0)
-- Dependencies: 197
-- Name: pessoa_id_pessoa_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE pessoa_id_pessoa_seq OWNED BY pessoa.id_pessoa;


--
-- TOC entry 198 (class 1259 OID 21321)
-- Name: sala; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sala (
    id_sala integer NOT NULL,
    nome_sala character varying(20) NOT NULL
);


--
-- TOC entry 199 (class 1259 OID 21324)
-- Name: sala_id_sala_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sala_id_sala_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2239 (class 0 OID 0)
-- Dependencies: 199
-- Name: sala_id_sala_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sala_id_sala_seq OWNED BY sala.id_sala;


--
-- TOC entry 200 (class 1259 OID 21326)
-- Name: sexo; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sexo (
    id_sexo integer NOT NULL,
    descricao_sexo character varying(15) NOT NULL,
    codigo_sexo character(1) NOT NULL
);


--
-- TOC entry 201 (class 1259 OID 21329)
-- Name: tipo_evento; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tipo_evento (
    id_tipo_evento integer NOT NULL,
    nome_tipo_evento character varying(20) NOT NULL
);


--
-- TOC entry 2240 (class 0 OID 0)
-- Dependencies: 201
-- Name: TABLE tipo_evento; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE tipo_evento IS 'Tipos de Eventos: Palestra, Minicurso, Oficina.';


--
-- TOC entry 202 (class 1259 OID 21332)
-- Name: tipo_evento_id_tipo_evento_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tipo_evento_id_tipo_evento_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2241 (class 0 OID 0)
-- Dependencies: 202
-- Name: tipo_evento_id_tipo_evento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tipo_evento_id_tipo_evento_seq OWNED BY tipo_evento.id_tipo_evento;


--
-- TOC entry 203 (class 1259 OID 21334)
-- Name: tipo_mensagem_email; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tipo_mensagem_email (
    id_tipo_mensagem_email integer NOT NULL,
    descricao_tipo_mensagem_email character varying(30) NOT NULL
);


--
-- TOC entry 204 (class 1259 OID 21337)
-- Name: tipo_usuario; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tipo_usuario (
    id_tipo_usuario integer NOT NULL,
    descricao_tipo_usuario character varying(15) NOT NULL
);


--
-- TOC entry 2089 (class 2604 OID 21547)
-- Name: id_caravana; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY caravana ALTER COLUMN id_caravana SET DEFAULT nextval('caravana_id_caravana_seq'::regclass);


--
-- TOC entry 2092 (class 2604 OID 21548)
-- Name: id_encontro; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY encontro ALTER COLUMN id_encontro SET DEFAULT nextval('encontro_id_encontro_seq'::regclass);


--
-- TOC entry 2093 (class 2604 OID 21549)
-- Name: id_encontro_horario; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY encontro_horario ALTER COLUMN id_encontro_horario SET DEFAULT nextval('encontro_horario_id_encontro_horario_seq'::regclass);


--
-- TOC entry 2099 (class 2604 OID 21550)
-- Name: id_estado; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY estado ALTER COLUMN id_estado SET DEFAULT nextval('estado_id_estado_seq'::regclass);


--
-- TOC entry 2105 (class 2604 OID 21551)
-- Name: id_evento; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento ALTER COLUMN id_evento SET DEFAULT nextval('evento_id_evento_seq'::regclass);


--
-- TOC entry 2110 (class 2604 OID 21552)
-- Name: evento; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_realizacao ALTER COLUMN evento SET DEFAULT nextval('evento_realizacao_evento_seq'::regclass);


--
-- TOC entry 2112 (class 2604 OID 21553)
-- Name: evento_realizacao_multipla; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_realizacao_multipla ALTER COLUMN evento_realizacao_multipla SET DEFAULT nextval('evento_realizacao_multipla_evento_realizacao_multipla_seq'::regclass);


--
-- TOC entry 2114 (class 2604 OID 21554)
-- Name: id_instituicao; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY instituicao ALTER COLUMN id_instituicao SET DEFAULT nextval('instituicao_id_instituicao_seq'::regclass);


--
-- TOC entry 2115 (class 2604 OID 21555)
-- Name: id_municipio; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY municipio ALTER COLUMN id_municipio SET DEFAULT nextval('municipio_id_municipio_seq'::regclass);


--
-- TOC entry 2122 (class 2604 OID 21556)
-- Name: id_pessoa; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY pessoa ALTER COLUMN id_pessoa SET DEFAULT nextval('pessoa_id_pessoa_seq'::regclass);


--
-- TOC entry 2123 (class 2604 OID 21557)
-- Name: id_sala; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sala ALTER COLUMN id_sala SET DEFAULT nextval('sala_id_sala_seq'::regclass);


--
-- TOC entry 2124 (class 2604 OID 21558)
-- Name: id_tipo_evento; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tipo_evento ALTER COLUMN id_tipo_evento SET DEFAULT nextval('tipo_evento_id_tipo_evento_seq'::regclass);


--
-- TOC entry 2128 (class 2606 OID 21353)
-- Name: caravana_encontro_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY caravana_encontro
    ADD CONSTRAINT caravana_encontro_pk PRIMARY KEY (id_caravana, id_encontro);


--
-- TOC entry 2126 (class 2606 OID 21355)
-- Name: caravana_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY caravana
    ADD CONSTRAINT caravana_pk PRIMARY KEY (id_caravana);


--
-- TOC entry 2131 (class 2606 OID 21357)
-- Name: dificuldade_evento_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY dificuldade_evento
    ADD CONSTRAINT dificuldade_evento_pk PRIMARY KEY (id_dificuldade_evento);


--
-- TOC entry 2135 (class 2606 OID 21359)
-- Name: encontro_horario_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY encontro_horario
    ADD CONSTRAINT encontro_horario_pkey PRIMARY KEY (id_encontro_horario);


--
-- TOC entry 2137 (class 2606 OID 21361)
-- Name: encontro_participante_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY encontro_participante
    ADD CONSTRAINT encontro_participante_pk PRIMARY KEY (id_encontro, id_pessoa);


--
-- TOC entry 2133 (class 2606 OID 21363)
-- Name: encontro_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY encontro
    ADD CONSTRAINT encontro_pk PRIMARY KEY (id_encontro);


--
-- TOC entry 2139 (class 2606 OID 21365)
-- Name: estado_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY estado
    ADD CONSTRAINT estado_pk PRIMARY KEY (id_estado);


--
-- TOC entry 2143 (class 2606 OID 21367)
-- Name: evento_arquivo_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY evento_arquivo
    ADD CONSTRAINT evento_arquivo_pk PRIMARY KEY (id_evento_arquivo);


--
-- TOC entry 2146 (class 2606 OID 21369)
-- Name: evento_demanda_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY evento_demanda
    ADD CONSTRAINT evento_demanda_pk PRIMARY KEY (evento, id_pessoa);


--
-- TOC entry 2148 (class 2606 OID 21371)
-- Name: evento_palestrante_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY evento_palestrante
    ADD CONSTRAINT evento_palestrante_pk PRIMARY KEY (id_evento, id_pessoa);


--
-- TOC entry 2150 (class 2606 OID 21373)
-- Name: evento_participacao_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY evento_participacao
    ADD CONSTRAINT evento_participacao_pk PRIMARY KEY (evento, id_pessoa);


--
-- TOC entry 2141 (class 2606 OID 21375)
-- Name: evento_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY evento
    ADD CONSTRAINT evento_pk PRIMARY KEY (id_evento);


--
-- TOC entry 2154 (class 2606 OID 21377)
-- Name: evento_realizacao_multipla_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY evento_realizacao_multipla
    ADD CONSTRAINT evento_realizacao_multipla_pkey PRIMARY KEY (evento_realizacao_multipla);


--
-- TOC entry 2152 (class 2606 OID 21379)
-- Name: evento_realizacao_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY evento_realizacao
    ADD CONSTRAINT evento_realizacao_pk PRIMARY KEY (evento);


--
-- TOC entry 2158 (class 2606 OID 21381)
-- Name: instituicao_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY instituicao
    ADD CONSTRAINT instituicao_pk PRIMARY KEY (id_instituicao);


--
-- TOC entry 2160 (class 2606 OID 21383)
-- Name: mensagem_email_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mensagem_email
    ADD CONSTRAINT mensagem_email_pk PRIMARY KEY (id_encontro, id_tipo_mensagem_email);


--
-- TOC entry 2162 (class 2606 OID 21385)
-- Name: municipio_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY municipio
    ADD CONSTRAINT municipio_pk PRIMARY KEY (id_municipio);


--
-- TOC entry 2167 (class 2606 OID 21387)
-- Name: pessoa_arquivo_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pessoa_arquivo
    ADD CONSTRAINT pessoa_arquivo_pk PRIMARY KEY (id_pessoa);


--
-- TOC entry 2165 (class 2606 OID 21389)
-- Name: pessoa_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pessoa
    ADD CONSTRAINT pessoa_pk PRIMARY KEY (id_pessoa);


--
-- TOC entry 2169 (class 2606 OID 21391)
-- Name: sala_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sala
    ADD CONSTRAINT sala_pk PRIMARY KEY (id_sala);


--
-- TOC entry 2171 (class 2606 OID 21393)
-- Name: sexo_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sexo
    ADD CONSTRAINT sexo_pk PRIMARY KEY (id_sexo);


--
-- TOC entry 2173 (class 2606 OID 21395)
-- Name: tipo_evento_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tipo_evento
    ADD CONSTRAINT tipo_evento_pk PRIMARY KEY (id_tipo_evento);


--
-- TOC entry 2175 (class 2606 OID 21397)
-- Name: tipo_mensagem_email_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tipo_mensagem_email
    ADD CONSTRAINT tipo_mensagem_email_pk PRIMARY KEY (id_tipo_mensagem_email);


--
-- TOC entry 2177 (class 2606 OID 21399)
-- Name: tipo_usuario_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tipo_usuario
    ADD CONSTRAINT tipo_usuario_pk PRIMARY KEY (id_tipo_usuario);


--
-- TOC entry 2129 (class 1259 OID 21400)
-- Name: caravana_encontro_responsavel_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX caravana_encontro_responsavel_idx ON caravana_encontro USING btree (id_encontro, responsavel);


--
-- TOC entry 2163 (class 1259 OID 21401)
-- Name: email_uidx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX email_uidx ON pessoa USING btree (email);


--
-- TOC entry 2144 (class 1259 OID 21402)
-- Name: evento_arquivomd5_uidx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX evento_arquivomd5_uidx ON evento_arquivo USING btree (nome_arquivo_md5);


--
-- TOC entry 2155 (class 1259 OID 21403)
-- Name: evento_realizacaomultipla_uidx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX evento_realizacaomultipla_uidx ON evento_realizacao_multipla USING btree (evento, data, hora_inicio, hora_fim);


--
-- TOC entry 2156 (class 1259 OID 21404)
-- Name: instituicao_indx_unq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX instituicao_indx_unq ON instituicao USING btree (apelido_instituicao);


--
-- TOC entry 2181 (class 2606 OID 21407)
-- Name: caravana_caravana_encontro_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY caravana_encontro
    ADD CONSTRAINT caravana_caravana_encontro_fk FOREIGN KEY (id_caravana) REFERENCES caravana(id_caravana);


--
-- TOC entry 2178 (class 2606 OID 21412)
-- Name: caravana_criador_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY caravana
    ADD CONSTRAINT caravana_criador_fkey FOREIGN KEY (criador) REFERENCES pessoa(id_pessoa);


--
-- TOC entry 2184 (class 2606 OID 21417)
-- Name: caravana_encontro_encontro_participante_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY encontro_participante
    ADD CONSTRAINT caravana_encontro_encontro_participante_fk FOREIGN KEY (id_caravana, id_encontro) REFERENCES caravana_encontro(id_caravana, id_encontro);


--
-- TOC entry 2190 (class 2606 OID 21422)
-- Name: dificuldade_evento_evento_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento
    ADD CONSTRAINT dificuldade_evento_evento_fk FOREIGN KEY (id_dificuldade_evento) REFERENCES dificuldade_evento(id_dificuldade_evento);


--
-- TOC entry 2182 (class 2606 OID 21427)
-- Name: encontro_caravana_encontro_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY caravana_encontro
    ADD CONSTRAINT encontro_caravana_encontro_fk FOREIGN KEY (id_encontro) REFERENCES encontro(id_encontro);


--
-- TOC entry 2185 (class 2606 OID 21432)
-- Name: encontro_encontro_participante_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY encontro_participante
    ADD CONSTRAINT encontro_encontro_participante_fk FOREIGN KEY (id_encontro) REFERENCES encontro(id_encontro);


--
-- TOC entry 2191 (class 2606 OID 21437)
-- Name: encontro_evento_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento
    ADD CONSTRAINT encontro_evento_fk FOREIGN KEY (id_encontro) REFERENCES encontro(id_encontro);


--
-- TOC entry 2204 (class 2606 OID 21442)
-- Name: estado_municipio_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY municipio
    ADD CONSTRAINT estado_municipio_fk FOREIGN KEY (id_estado) REFERENCES estado(id_estado);


--
-- TOC entry 2196 (class 2606 OID 21447)
-- Name: evento_evento_palestrante_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_palestrante
    ADD CONSTRAINT evento_evento_palestrante_fk FOREIGN KEY (id_evento) REFERENCES evento(id_evento);


--
-- TOC entry 2200 (class 2606 OID 21452)
-- Name: evento_evento_realizacao_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_realizacao
    ADD CONSTRAINT evento_evento_realizacao_fk FOREIGN KEY (id_evento) REFERENCES evento(id_evento);


--
-- TOC entry 2194 (class 2606 OID 21457)
-- Name: evento_realizacao_evento_demanda_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_demanda
    ADD CONSTRAINT evento_realizacao_evento_demanda_fk FOREIGN KEY (evento) REFERENCES evento_realizacao(evento);


--
-- TOC entry 2198 (class 2606 OID 21462)
-- Name: evento_realizacao_evento_participacao_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_participacao
    ADD CONSTRAINT evento_realizacao_evento_participacao_fk FOREIGN KEY (evento) REFERENCES evento_realizacao(evento);


--
-- TOC entry 2202 (class 2606 OID 21467)
-- Name: evento_realizacao_multipla_evento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_realizacao_multipla
    ADD CONSTRAINT evento_realizacao_multipla_evento_fkey FOREIGN KEY (evento) REFERENCES evento_realizacao(evento);


--
-- TOC entry 2192 (class 2606 OID 21472)
-- Name: evento_responsavel_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento
    ADD CONSTRAINT evento_responsavel_fkey FOREIGN KEY (responsavel) REFERENCES pessoa(id_pessoa);


--
-- TOC entry 2179 (class 2606 OID 21477)
-- Name: instituicao_caravana_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY caravana
    ADD CONSTRAINT instituicao_caravana_fk FOREIGN KEY (id_instituicao) REFERENCES instituicao(id_instituicao);


--
-- TOC entry 2186 (class 2606 OID 21482)
-- Name: instituicao_encontro_participante_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY encontro_participante
    ADD CONSTRAINT instituicao_encontro_participante_fk FOREIGN KEY (id_instituicao) REFERENCES instituicao(id_instituicao);


--
-- TOC entry 2180 (class 2606 OID 21487)
-- Name: municipio_caravana_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY caravana
    ADD CONSTRAINT municipio_caravana_fk FOREIGN KEY (id_municipio) REFERENCES municipio(id_municipio);


--
-- TOC entry 2187 (class 2606 OID 21492)
-- Name: municipio_encontro_participante_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY encontro_participante
    ADD CONSTRAINT municipio_encontro_participante_fk FOREIGN KEY (id_municipio) REFERENCES municipio(id_municipio);


--
-- TOC entry 2183 (class 2606 OID 21497)
-- Name: pessoa_caravana_encontro_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY caravana_encontro
    ADD CONSTRAINT pessoa_caravana_encontro_fk FOREIGN KEY (responsavel) REFERENCES pessoa(id_pessoa);


--
-- TOC entry 2188 (class 2606 OID 21502)
-- Name: pessoa_encontro_participante_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY encontro_participante
    ADD CONSTRAINT pessoa_encontro_participante_fk FOREIGN KEY (id_pessoa) REFERENCES pessoa(id_pessoa);


--
-- TOC entry 2195 (class 2606 OID 21507)
-- Name: pessoa_evento_demanda_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_demanda
    ADD CONSTRAINT pessoa_evento_demanda_fk FOREIGN KEY (id_pessoa) REFERENCES pessoa(id_pessoa);


--
-- TOC entry 2197 (class 2606 OID 21512)
-- Name: pessoa_evento_palestrante_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_palestrante
    ADD CONSTRAINT pessoa_evento_palestrante_fk FOREIGN KEY (id_pessoa) REFERENCES pessoa(id_pessoa);


--
-- TOC entry 2199 (class 2606 OID 21517)
-- Name: pessoa_evento_participacao_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_participacao
    ADD CONSTRAINT pessoa_evento_participacao_fk FOREIGN KEY (id_pessoa) REFERENCES pessoa(id_pessoa);


--
-- TOC entry 2201 (class 2606 OID 21522)
-- Name: sala_evento_realizacao_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_realizacao
    ADD CONSTRAINT sala_evento_realizacao_fk FOREIGN KEY (id_sala) REFERENCES sala(id_sala);


--
-- TOC entry 2205 (class 2606 OID 21587)
-- Name: sexo_pessoa_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY pessoa
    ADD CONSTRAINT sexo_pessoa_fk FOREIGN KEY (id_sexo) REFERENCES sexo(id_sexo);


--
-- TOC entry 2193 (class 2606 OID 21532)
-- Name: tipo_evento_evento_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento
    ADD CONSTRAINT tipo_evento_evento_fk FOREIGN KEY (id_tipo_evento) REFERENCES tipo_evento(id_tipo_evento);


--
-- TOC entry 2203 (class 2606 OID 21537)
-- Name: tipo_mensagem_email_mensagem_email_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mensagem_email
    ADD CONSTRAINT tipo_mensagem_email_mensagem_email_fk FOREIGN KEY (id_tipo_mensagem_email) REFERENCES tipo_mensagem_email(id_tipo_mensagem_email);


--
-- TOC entry 2189 (class 2606 OID 21542)
-- Name: tipo_usuario_encontro_participante_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY encontro_participante
    ADD CONSTRAINT tipo_usuario_encontro_participante_fk FOREIGN KEY (id_tipo_usuario) REFERENCES tipo_usuario(id_tipo_usuario);


CREATE OR REPLACE FUNCTION funcvalidausuario()
  RETURNS trigger AS
$BODY$
BEGIN
IF NEW.cadastro_validado = 'T' THEN
--    SELECT now() INTO NEW.data_validacao_cadastro;
    NEW.data_validacao_cadastro = now();
  END IF;
  RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


CREATE OR REPLACE FUNCTION funcvalidaevento()
  RETURNS trigger AS
$BODY$
BEGIN
IF NEW.validada = 'T' THEN
    NEW.data_validacao = now();
  END IF;
  RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE TRIGGER trgrvalidaevento
  BEFORE UPDATE
  ON evento
  FOR EACH ROW
  EXECUTE PROCEDURE funcvalidaevento();
  
CREATE TRIGGER trgrvalidausuario
  BEFORE UPDATE
  ON pessoa
  FOR EACH ROW
  EXECUTE PROCEDURE funcvalidausuario();

--
-- TOC entry 2214 (class 0 OID 0)
-- Dependencies: 6
-- Name: public; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2013-01-24 18:37:21 BRT

--
-- PostgreSQL database dump complete
--

ROLLBACK;
