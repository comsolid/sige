START TRANSACTION;

--
-- PostgreSQL database dump
--

-- Dumped from database version 9.3.6
-- Dumped by pg_dump version 9.3.6
-- Started on 2016-05-24 19:29:00 BRT

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- TOC entry 214 (class 3079 OID 11791)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 2269 (class 0 OID 0)
-- Dependencies: 214
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- TOC entry 227 (class 1255 OID 39902)
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


--
-- TOC entry 228 (class 1255 OID 39903)
-- Name: funcvalidaevento(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION funcvalidaevento() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN

IF NEW.validada = 'T' THEN

    NEW.data_validacao = now();

  END IF;

  RETURN NEW;

END;

$$;


--
-- TOC entry 229 (class 1255 OID 39904)
-- Name: funcvalidausuario(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION funcvalidausuario() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN

IF NEW.cadastro_validado = 'T' THEN

--    SELECT now() INTO NEW.data_validacao_cadastro;

    NEW.data_validacao_cadastro = now();

  END IF;

  RETURN NEW;

END;

$$;


SET default_with_oids = false;

--
-- TOC entry 170 (class 1259 OID 39905)
-- Name: artigo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE artigo (
    id_artigo integer NOT NULL,
    nomearquivo_original character varying(255),
    tamanho integer,
    criado timestamp with time zone NOT NULL,
    responsavel integer NOT NULL,
    id_encontro integer NOT NULL,
    dados bytea NOT NULL,
    titulo character varying(255),
    aceito boolean DEFAULT false NOT NULL,
    deletado boolean DEFAULT false NOT NULL,
    dt_delecao timestamp with time zone,
    dt_aceitacao timestamp with time zone
);


--
-- TOC entry 171 (class 1259 OID 39913)
-- Name: artigo_id_artigo_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE artigo_id_artigo_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2270 (class 0 OID 0)
-- Dependencies: 171
-- Name: artigo_id_artigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE artigo_id_artigo_seq OWNED BY artigo.id_artigo;


--
-- TOC entry 172 (class 1259 OID 39915)
-- Name: caravana; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE caravana (
    id_caravana integer NOT NULL,
    nome_caravana character varying(255) NOT NULL,
    apelido_caravana character varying(20) NOT NULL,
    id_municipio integer NOT NULL,
    id_instituicao integer,
    criador integer NOT NULL
);


--
-- TOC entry 173 (class 1259 OID 39918)
-- Name: caravana_encontro; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE caravana_encontro (
    id_caravana integer NOT NULL,
    id_encontro integer NOT NULL,
    responsavel integer NOT NULL,
    validada boolean DEFAULT false NOT NULL
);


--
-- TOC entry 2271 (class 0 OID 0)
-- Dependencies: 173
-- Name: COLUMN caravana_encontro.responsavel; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN caravana_encontro.responsavel IS 'Responsável pela caravana.

Seu cadastro deve estar realizado previamente.';


--
-- TOC entry 174 (class 1259 OID 39922)
-- Name: caravana_id_caravana_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE caravana_id_caravana_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2272 (class 0 OID 0)
-- Dependencies: 174
-- Name: caravana_id_caravana_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE caravana_id_caravana_seq OWNED BY caravana.id_caravana;


--
-- TOC entry 179 (class 1259 OID 39944)
-- Name: dificuldade_evento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE dificuldade_evento (
    id_dificuldade_evento integer NOT NULL,
    descricao_dificuldade_evento character varying(15) NOT NULL
);


--
-- TOC entry 2274 (class 0 OID 0)
-- Dependencies: 179
-- Name: TABLE dificuldade_evento; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE dificuldade_evento IS 'Mostra o nível de dificuldade do Evento.

Básico

Intermediário

Avançado';


--
-- TOC entry 180 (class 1259 OID 39947)
-- Name: encontro; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE encontro (
    id_encontro integer NOT NULL,
    nome_encontro character varying(255) NOT NULL,
    apelido_encontro character varying(50) NOT NULL,
    data_inicio date NOT NULL,
    data_fim date NOT NULL,
    ativo boolean DEFAULT false NOT NULL,
    periodo_submissao_inicio date NOT NULL,
    periodo_submissao_fim date NOT NULL,
    certificados_liberados boolean DEFAULT false NOT NULL,
    certificados_template_participante_encontro text DEFAULT 'Certificamos que {nome} participou do(a) {encontro}.'::text,
    certificados_template_palestrante_evento text DEFAULT 'Certificamos que {nome} apresentou o(a) {tipo_evento}: {nome_evento} no(a) {encontro}, com carga horária de {carga_horaria}.'::text,
    certificados_template_participante_evento text DEFAULT 'Certificamos que {nome} participou do(a) {tipo_evento}: {nome_evento} no(a) {encontro}, com carga horária de {carga_horaria}.'::text,
    id_municipio integer DEFAULT 1 NOT NULL,
    id_tipo_horario integer DEFAULT 1 NOT NULL
);


--
-- TOC entry 181 (class 1259 OID 39951)
-- Name: encontro_horario; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE encontro_horario (
    id_encontro_horario integer NOT NULL,
    descricao character varying(20) NOT NULL,
    hora_inicial time without time zone NOT NULL,
    hora_final time without time zone NOT NULL,
    CONSTRAINT encontro_horario_check CHECK ((hora_inicial < hora_final))
);


--
-- TOC entry 182 (class 1259 OID 39955)
-- Name: encontro_horario_id_encontro_horario_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE encontro_horario_id_encontro_horario_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2276 (class 0 OID 0)
-- Dependencies: 182
-- Name: encontro_horario_id_encontro_horario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE encontro_horario_id_encontro_horario_seq OWNED BY encontro_horario.id_encontro_horario;


--
-- TOC entry 183 (class 1259 OID 39957)
-- Name: encontro_id_encontro_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE encontro_id_encontro_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2277 (class 0 OID 0)
-- Dependencies: 183
-- Name: encontro_id_encontro_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE encontro_id_encontro_seq OWNED BY encontro.id_encontro;


--
-- TOC entry 175 (class 1259 OID 39924)
-- Name: encontro_participante; Type: TABLE; Schema: public; Owner: -
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
-- TOC entry 184 (class 1259 OID 39959)
-- Name: estado; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE estado (
    id_estado integer NOT NULL,
    nome_estado character varying(30) NOT NULL,
    codigo_estado character(2) NOT NULL
);


--
-- TOC entry 185 (class 1259 OID 39962)
-- Name: estado_id_estado_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE estado_id_estado_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2278 (class 0 OID 0)
-- Dependencies: 185
-- Name: estado_id_estado_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE estado_id_estado_seq OWNED BY estado.id_estado;


--
-- TOC entry 186 (class 1259 OID 39964)
-- Name: evento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE evento (
    id_evento integer NOT NULL,
    nome_evento character varying(255) NOT NULL,
    id_tipo_evento integer NOT NULL,
    id_encontro integer NOT NULL,
    validada boolean DEFAULT false NOT NULL,
    resumo text NOT NULL,
    responsavel integer NOT NULL,
    data_validacao timestamp without time zone,
    data_submissao timestamp without time zone DEFAULT now() NOT NULL,
    id_dificuldade_evento integer DEFAULT 1 NOT NULL,
    perfil_minimo text DEFAULT 'Perfil Mínimo do Participante'::text NOT NULL,
    preferencia_horario text,
    apresentado boolean DEFAULT false NOT NULL,
    tecnologias_envolvidas text,
    id_artigo integer
);


--
-- TOC entry 2279 (class 0 OID 0)
-- Dependencies: 186
-- Name: TABLE evento; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE evento IS 'Evento é qualquer tipo de atividade no Encontro: Palestra, Minicurso, Oficina.';


--
-- TOC entry 2280 (class 0 OID 0)
-- Dependencies: 186
-- Name: COLUMN evento.validada; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN evento.validada IS 'O administrador deve indicar qual o evento aprovado.';


--
-- TOC entry 2281 (class 0 OID 0)
-- Dependencies: 186
-- Name: COLUMN evento.apresentado; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN evento.apresentado IS 'indica que o palestrante realmente veio e participou';


--
-- TOC entry 187 (class 1259 OID 39975)
-- Name: evento_arquivo_id_evento_arquivo_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE evento_arquivo_id_evento_arquivo_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 188 (class 1259 OID 39977)
-- Name: evento_arquivo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE evento_arquivo (
    id_evento_arquivo integer DEFAULT nextval('evento_arquivo_id_evento_arquivo_seq'::regclass) NOT NULL,
    id_evento integer NOT NULL,
    nome_arquivo character varying(255) NOT NULL,
    arquivo oid NOT NULL,
    nome_arquivo_md5 character varying(255) DEFAULT md5(((((random() * (1000)::double precision))::integer)::character varying)::text) NOT NULL
);


--
-- TOC entry 189 (class 1259 OID 39985)
-- Name: evento_demanda; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE evento_demanda (
    evento integer NOT NULL,
    id_pessoa integer NOT NULL,
    data_solicitacao date DEFAULT now() NOT NULL
);


--
-- TOC entry 190 (class 1259 OID 39989)
-- Name: evento_id_evento_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE evento_id_evento_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2282 (class 0 OID 0)
-- Dependencies: 190
-- Name: evento_id_evento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE evento_id_evento_seq OWNED BY evento.id_evento;


--
-- TOC entry 191 (class 1259 OID 39991)
-- Name: evento_palestrante; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE evento_palestrante (
    id_evento integer NOT NULL,
    id_pessoa integer NOT NULL,
    confirmado boolean DEFAULT false NOT NULL
);


--
-- TOC entry 192 (class 1259 OID 39995)
-- Name: evento_participacao; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE evento_participacao (
    id_evento_realizacao integer NOT NULL,
    id_pessoa integer NOT NULL
);


--
-- TOC entry 193 (class 1259 OID 39998)
-- Name: evento_realizacao; Type: TABLE; Schema: public; Owner: -
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
-- TOC entry 194 (class 1259 OID 40002)
-- Name: evento_realizacao_evento_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE evento_realizacao_evento_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2283 (class 0 OID 0)
-- Dependencies: 194
-- Name: evento_realizacao_evento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE evento_realizacao_evento_seq OWNED BY evento_realizacao.evento;


--
-- TOC entry 195 (class 1259 OID 40010)
-- Name: evento_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE evento_tags (
    id_evento integer NOT NULL,
    id_tag integer NOT NULL
);


--
-- TOC entry 196 (class 1259 OID 40013)
-- Name: instituicao; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE instituicao (
    id_instituicao integer NOT NULL,
    nome_instituicao character varying(100) NOT NULL,
    apelido_instituicao character varying(50) NOT NULL
);


--
-- TOC entry 2284 (class 0 OID 0)
-- Dependencies: 196
-- Name: TABLE instituicao; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE instituicao IS 'Instituição de origem da pessoa. Escola, Comunidade.';


--
-- TOC entry 2285 (class 0 OID 0)
-- Dependencies: 196
-- Name: COLUMN instituicao.apelido_instituicao; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN instituicao.apelido_instituicao IS 'Escola Fulano de Tal.

Essa informação pode ser utilizada no CRACHÁ.';


--
-- TOC entry 197 (class 1259 OID 40016)
-- Name: instituicao_id_instituicao_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE instituicao_id_instituicao_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2286 (class 0 OID 0)
-- Dependencies: 197
-- Name: instituicao_id_instituicao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE instituicao_id_instituicao_seq OWNED BY instituicao.id_instituicao;


--
-- TOC entry 198 (class 1259 OID 40018)
-- Name: mensagem_email; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE mensagem_email (
    id_encontro integer NOT NULL,
    id_tipo_mensagem_email integer NOT NULL,
    mensagem text NOT NULL,
    assunto character varying(200) NOT NULL,
    link character varying(70),
    assinatura_email character varying(255),
    assinatura_siteoficial character varying(255)
);


--
-- TOC entry 176 (class 1259 OID 39931)
-- Name: municipio; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE municipio (
    id_municipio integer NOT NULL,
    nome_municipio character varying(40) NOT NULL,
    id_estado integer NOT NULL
);


--
-- TOC entry 199 (class 1259 OID 40024)
-- Name: municipio_id_municipio_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE municipio_id_municipio_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2287 (class 0 OID 0)
-- Dependencies: 199
-- Name: municipio_id_municipio_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE municipio_id_municipio_seq OWNED BY municipio.id_municipio;


--
-- TOC entry 200 (class 1259 OID 40026)
-- Name: pessoa; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE pessoa (
    id_pessoa integer NOT NULL,
    nome character varying(255) NOT NULL,
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
    bio text,
    slideshare character varying(32),
    token character varying(32),
    token_validade timestamp without time zone,
    cpf bigint
);


--
-- TOC entry 2288 (class 0 OID 0)
-- Dependencies: 200
-- Name: COLUMN pessoa.nome; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN pessoa.nome IS 'Nome completo e em letra Maiúscula';


--
-- TOC entry 2289 (class 0 OID 0)
-- Dependencies: 200
-- Name: COLUMN pessoa.email; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN pessoa.email IS 'email em letra minúscula';


--
-- TOC entry 2290 (class 0 OID 0)
-- Dependencies: 200
-- Name: COLUMN pessoa.endereco_internet; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN pessoa.endereco_internet IS 'Um endereço começando com http:// indicando onde estão as informações da pessoa.

Pode ser um blog, página do facebook, site...';


--
-- TOC entry 2291 (class 0 OID 0)
-- Dependencies: 200
-- Name: COLUMN pessoa.senha; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN pessoa.senha IS 'Senha do usuário usando criptografia md5 do comsolid.

Valor padrão vai ser o próprio nome do usuário.';


--
-- TOC entry 2292 (class 0 OID 0)
-- Dependencies: 200
-- Name: COLUMN pessoa.email_enviado; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN pessoa.email_enviado IS 'Indica se o sistema conseguiu conectar a um servidor de email e validar o email.';


--
-- TOC entry 201 (class 1259 OID 40038)
-- Name: pessoa_arquivo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE pessoa_arquivo (
    id_pessoa integer NOT NULL,
    foto oid NOT NULL
);


--
-- TOC entry 202 (class 1259 OID 40041)
-- Name: pessoa_id_pessoa_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE pessoa_id_pessoa_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2293 (class 0 OID 0)
-- Dependencies: 202
-- Name: pessoa_id_pessoa_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE pessoa_id_pessoa_seq OWNED BY pessoa.id_pessoa;


--
-- Name: pessoa_mudar_email; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE pessoa_mudar_email (
    id integer NOT NULL,
    email_anterior character varying(100) NOT NULL,
    novo_email character varying(100) NOT NULL,
    motivo text NOT NULL,
    data_submissao timestamp without time zone DEFAULT now() NOT NULL,
    ultima_atualizacao timestamp without time zone,
    atualizado_por integer,
    status boolean
);


--
-- Name: COLUMN pessoa_mudar_email.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN pessoa_mudar_email.status IS 'null para aberto, false para negado e true para atualizado.';


--
-- Name: pessoa_mudar_email_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE pessoa_mudar_email_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: pessoa_mudar_email_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE pessoa_mudar_email_id_seq OWNED BY pessoa_mudar_email.id;


--
-- Name: sala; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sala (
    id_sala integer NOT NULL,
    nome_sala character varying(20) NOT NULL
);


--
-- TOC entry 204 (class 1259 OID 40046)
-- Name: sala_id_sala_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sala_id_sala_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2294 (class 0 OID 0)
-- Dependencies: 204
-- Name: sala_id_sala_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sala_id_sala_seq OWNED BY sala.id_sala;


--
-- TOC entry 205 (class 1259 OID 40048)
-- Name: sexo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sexo (
    id_sexo integer NOT NULL,
    descricao_sexo character varying(15) NOT NULL,
    codigo_sexo character(1) NOT NULL
);


--
-- TOC entry 206 (class 1259 OID 40051)
-- Name: tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tags (
    id integer NOT NULL,
    descricao character varying(30) NOT NULL
);


--
-- TOC entry 207 (class 1259 OID 40054)
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2295 (class 0 OID 0)
-- Dependencies: 207
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tags_id_seq OWNED BY tags.id;


--
-- TOC entry 208 (class 1259 OID 40056)
-- Name: tipo_evento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tipo_evento (
    id_tipo_evento integer NOT NULL,
    nome_tipo_evento character varying(20) NOT NULL
);


--
-- TOC entry 2296 (class 0 OID 0)
-- Dependencies: 208
-- Name: TABLE tipo_evento; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE tipo_evento IS 'Tipos de Eventos: Palestra, Minicurso, Oficina.';


--
-- TOC entry 209 (class 1259 OID 40059)
-- Name: tipo_evento_id_tipo_evento_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tipo_evento_id_tipo_evento_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2297 (class 0 OID 0)
-- Dependencies: 209
-- Name: tipo_evento_id_tipo_evento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tipo_evento_id_tipo_evento_seq OWNED BY tipo_evento.id_tipo_evento;


--
-- TOC entry 213 (class 1259 OID 48073)
-- Name: tipo_horario; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tipo_horario (
    id_tipo_horario integer NOT NULL,
    intervalo_minutos integer NOT NULL,
    horario_inicial time without time zone NOT NULL,
    horario_final time without time zone NOT NULL
);


--
-- TOC entry 212 (class 1259 OID 48071)
-- Name: tipo_horario_id_tipo_horario_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tipo_horario_id_tipo_horario_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2298 (class 0 OID 0)
-- Dependencies: 212
-- Name: tipo_horario_id_tipo_horario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tipo_horario_id_tipo_horario_seq OWNED BY tipo_horario.id_tipo_horario;


--
-- TOC entry 210 (class 1259 OID 40061)
-- Name: tipo_mensagem_email; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tipo_mensagem_email (
    id_tipo_mensagem_email integer NOT NULL,
    descricao_tipo_mensagem_email character varying(30) NOT NULL
);


--
-- TOC entry 211 (class 1259 OID 40064)
-- Name: tipo_usuario; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tipo_usuario (
    id_tipo_usuario integer NOT NULL,
    descricao_tipo_usuario character varying(15) NOT NULL
);


--
-- TOC entry 2012 (class 2604 OID 40067)
-- Name: id_artigo; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY artigo ALTER COLUMN id_artigo SET DEFAULT nextval('artigo_id_artigo_seq'::regclass);


--
-- TOC entry 2013 (class 2604 OID 40068)
-- Name: id_caravana; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY caravana ALTER COLUMN id_caravana SET DEFAULT nextval('caravana_id_caravana_seq'::regclass);


--
-- TOC entry 2023 (class 2604 OID 40070)
-- Name: id_encontro; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY encontro ALTER COLUMN id_encontro SET DEFAULT nextval('encontro_id_encontro_seq'::regclass);


--
-- TOC entry 2030 (class 2604 OID 40071)
-- Name: id_encontro_horario; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY encontro_horario ALTER COLUMN id_encontro_horario SET DEFAULT nextval('encontro_horario_id_encontro_horario_seq'::regclass);


--
-- TOC entry 2032 (class 2604 OID 40072)
-- Name: id_estado; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY estado ALTER COLUMN id_estado SET DEFAULT nextval('estado_id_estado_seq'::regclass);


--
-- TOC entry 2038 (class 2604 OID 40073)
-- Name: id_evento; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento ALTER COLUMN id_evento SET DEFAULT nextval('evento_id_evento_seq'::regclass);


--
-- TOC entry 2043 (class 2604 OID 40074)
-- Name: evento; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_realizacao ALTER COLUMN evento SET DEFAULT nextval('evento_realizacao_evento_seq'::regclass);


--
-- TOC entry 2045 (class 2604 OID 40076)
-- Name: id_instituicao; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY instituicao ALTER COLUMN id_instituicao SET DEFAULT nextval('instituicao_id_instituicao_seq'::regclass);


--
-- TOC entry 2019 (class 2604 OID 40077)
-- Name: id_municipio; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY municipio ALTER COLUMN id_municipio SET DEFAULT nextval('municipio_id_municipio_seq'::regclass);


--
-- TOC entry 2052 (class 2604 OID 40078)
-- Name: id_pessoa; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY pessoa ALTER COLUMN id_pessoa SET DEFAULT nextval('pessoa_id_pessoa_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY pessoa_mudar_email ALTER COLUMN id SET DEFAULT nextval('pessoa_mudar_email_id_seq'::regclass);


--
-- Name: id_sala; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sala ALTER COLUMN id_sala SET DEFAULT nextval('sala_id_sala_seq'::regclass);


--
-- TOC entry 2054 (class 2604 OID 40081)
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tags ALTER COLUMN id SET DEFAULT nextval('tags_id_seq'::regclass);


--
-- TOC entry 2055 (class 2604 OID 40082)
-- Name: id_tipo_evento; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tipo_evento ALTER COLUMN id_tipo_evento SET DEFAULT nextval('tipo_evento_id_tipo_evento_seq'::regclass);


--
-- TOC entry 2056 (class 2604 OID 48076)
-- Name: id_tipo_horario; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tipo_horario ALTER COLUMN id_tipo_horario SET DEFAULT nextval('tipo_horario_id_tipo_horario_seq'::regclass);


--
-- TOC entry 2059 (class 2606 OID 40092)
-- Name: artigo_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY artigo
    ADD CONSTRAINT artigo_pkey PRIMARY KEY (id_artigo);


--
-- TOC entry 2063 (class 2606 OID 40094)
-- Name: caravana_encontro_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY caravana_encontro
    ADD CONSTRAINT caravana_encontro_pk PRIMARY KEY (id_caravana, id_encontro);


--
-- TOC entry 2061 (class 2606 OID 40096)
-- Name: caravana_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY caravana
    ADD CONSTRAINT caravana_pk PRIMARY KEY (id_caravana);


--
-- TOC entry 2072 (class 2606 OID 40100)
-- Name: dificuldade_evento_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY dificuldade_evento
    ADD CONSTRAINT dificuldade_evento_pk PRIMARY KEY (id_dificuldade_evento);


--
-- TOC entry 2076 (class 2606 OID 40102)
-- Name: encontro_horario_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY encontro_horario
    ADD CONSTRAINT encontro_horario_pkey PRIMARY KEY (id_encontro_horario);


--
-- TOC entry 2066 (class 2606 OID 40104)
-- Name: encontro_participante_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY encontro_participante
    ADD CONSTRAINT encontro_participante_pk PRIMARY KEY (id_encontro, id_pessoa);


--
-- TOC entry 2074 (class 2606 OID 40106)
-- Name: encontro_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY encontro
    ADD CONSTRAINT encontro_pk PRIMARY KEY (id_encontro);


--
-- TOC entry 2078 (class 2606 OID 40108)
-- Name: estado_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY estado
    ADD CONSTRAINT estado_pk PRIMARY KEY (id_estado);


--
-- TOC entry 2082 (class 2606 OID 40110)
-- Name: evento_arquivo_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_arquivo
    ADD CONSTRAINT evento_arquivo_pk PRIMARY KEY (id_evento_arquivo);


--
-- TOC entry 2085 (class 2606 OID 40112)
-- Name: evento_demanda_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_demanda
    ADD CONSTRAINT evento_demanda_pk PRIMARY KEY (evento, id_pessoa);


--
-- TOC entry 2087 (class 2606 OID 40114)
-- Name: evento_palestrante_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_palestrante
    ADD CONSTRAINT evento_palestrante_pk PRIMARY KEY (id_evento, id_pessoa);


--
-- TOC entry 2089 (class 2606 OID 40116)
-- Name: evento_participacao_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_participacao
    ADD CONSTRAINT evento_participacao_pk PRIMARY KEY (id_evento_realizacao, id_pessoa);


--
-- TOC entry 2080 (class 2606 OID 40118)
-- Name: evento_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento
    ADD CONSTRAINT evento_pk PRIMARY KEY (id_evento);


--
-- TOC entry 2091 (class 2606 OID 40122)
-- Name: evento_realizacao_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_realizacao
    ADD CONSTRAINT evento_realizacao_pk PRIMARY KEY (evento);


--
-- TOC entry 2093 (class 2606 OID 40124)
-- Name: evento_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_tags
    ADD CONSTRAINT evento_tags_pkey PRIMARY KEY (id_evento, id_tag);


--
-- TOC entry 2096 (class 2606 OID 40126)
-- Name: instituicao_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY instituicao
    ADD CONSTRAINT instituicao_pk PRIMARY KEY (id_instituicao);


--
-- TOC entry 2098 (class 2606 OID 40128)
-- Name: mensagem_email_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mensagem_email
    ADD CONSTRAINT mensagem_email_pk PRIMARY KEY (id_encontro, id_tipo_mensagem_email);


--
-- TOC entry 2068 (class 2606 OID 40130)
-- Name: municipio_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY municipio
    ADD CONSTRAINT municipio_pk PRIMARY KEY (id_municipio);


--
-- TOC entry 2105 (class 2606 OID 40132)
-- Name: pessoa_arquivo_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY pessoa_arquivo
    ADD CONSTRAINT pessoa_arquivo_pk PRIMARY KEY (id_pessoa);


--
-- TOC entry 2101 (class 2606 OID 80217)
-- Name: pessoa_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY pessoa
    ADD CONSTRAINT pessoa_email_key UNIQUE (email);


--
-- Name: pessoa_mudar_email_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY pessoa_mudar_email
    ADD CONSTRAINT pessoa_mudar_email_pkey PRIMARY KEY (id);


--
-- Name: pessoa_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY pessoa
    ADD CONSTRAINT pessoa_pk PRIMARY KEY (id_pessoa);


--
-- TOC entry 2107 (class 2606 OID 40136)
-- Name: sala_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sala
    ADD CONSTRAINT sala_pk PRIMARY KEY (id_sala);


--
-- TOC entry 2109 (class 2606 OID 40138)
-- Name: sexo_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sexo
    ADD CONSTRAINT sexo_pk PRIMARY KEY (id_sexo);


--
-- TOC entry 2111 (class 2606 OID 40140)
-- Name: tags_descricao_uidx; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tags
    ADD CONSTRAINT tags_descricao_uidx UNIQUE (descricao);


--
-- TOC entry 2113 (class 2606 OID 40142)
-- Name: tags_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tags
    ADD CONSTRAINT tags_pk PRIMARY KEY (id);


--
-- TOC entry 2115 (class 2606 OID 40144)
-- Name: tipo_evento_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tipo_evento
    ADD CONSTRAINT tipo_evento_pk PRIMARY KEY (id_tipo_evento);


--
-- TOC entry 2121 (class 2606 OID 48083)
-- Name: tipo_horario_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tipo_horario
    ADD CONSTRAINT tipo_horario_pkey PRIMARY KEY (id_tipo_horario);


--
-- TOC entry 2117 (class 2606 OID 40146)
-- Name: tipo_mensagem_email_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tipo_mensagem_email
    ADD CONSTRAINT tipo_mensagem_email_pk PRIMARY KEY (id_tipo_mensagem_email);


--
-- TOC entry 2119 (class 2606 OID 40148)
-- Name: tipo_usuario_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tipo_usuario
    ADD CONSTRAINT tipo_usuario_pk PRIMARY KEY (id_tipo_usuario);


--
-- TOC entry 2057 (class 1259 OID 80218)
-- Name: artigo_id_artigo_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX artigo_id_artigo_key ON artigo USING btree (id_artigo);


--
-- TOC entry 2064 (class 1259 OID 40149)
-- Name: caravana_encontro_responsavel_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX caravana_encontro_responsavel_idx ON caravana_encontro USING btree (id_encontro, responsavel);


--
-- TOC entry 2099 (class 1259 OID 40150)
-- Name: email_uidx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX email_uidx ON pessoa USING btree (email);


--
-- TOC entry 2083 (class 1259 OID 40151)
-- Name: evento_arquivomd5_uidx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX evento_arquivomd5_uidx ON evento_arquivo USING btree (nome_arquivo_md5);


--
-- Name: index_pessoa_on_nome; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pessoa_on_nome ON pessoa USING btree (nome);


--
-- Name: instituicao_indx_unq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX instituicao_indx_unq ON instituicao USING btree (apelido_instituicao);


--
-- Name: trgrvalidaevento; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trgrvalidaevento
    BEFORE UPDATE ON evento
    FOR EACH ROW
    EXECUTE PROCEDURE funcvalidaevento();


--
-- Name: trgrvalidausuario; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trgrvalidausuario
    BEFORE UPDATE ON pessoa
    FOR EACH ROW
    EXECUTE PROCEDURE funcvalidausuario();


--
-- Name: artigo_id_encontro_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY artigo
    ADD CONSTRAINT artigo_id_encontro_fkey FOREIGN KEY (id_encontro) REFERENCES encontro(id_encontro);


--
-- TOC entry 2123 (class 2606 OID 40161)
-- Name: artigo_id_pessoa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY artigo
    ADD CONSTRAINT artigo_id_pessoa_fkey FOREIGN KEY (responsavel) REFERENCES pessoa(id_pessoa);


--
-- TOC entry 2127 (class 2606 OID 40166)
-- Name: caravana_caravana_encontro_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY caravana_encontro
    ADD CONSTRAINT caravana_caravana_encontro_fk FOREIGN KEY (id_caravana) REFERENCES caravana(id_caravana);


--
-- TOC entry 2124 (class 2606 OID 40171)
-- Name: caravana_criador_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY caravana
    ADD CONSTRAINT caravana_criador_fkey FOREIGN KEY (criador) REFERENCES pessoa(id_pessoa);


--
-- TOC entry 2130 (class 2606 OID 40176)
-- Name: caravana_encontro_encontro_participante_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY encontro_participante
    ADD CONSTRAINT caravana_encontro_encontro_participante_fk FOREIGN KEY (id_caravana, id_encontro) REFERENCES caravana_encontro(id_caravana, id_encontro);


--
-- TOC entry 2139 (class 2606 OID 40181)
-- Name: dificuldade_evento_evento_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento
    ADD CONSTRAINT dificuldade_evento_evento_fk FOREIGN KEY (id_dificuldade_evento) REFERENCES dificuldade_evento(id_dificuldade_evento);


--
-- TOC entry 2128 (class 2606 OID 40186)
-- Name: encontro_caravana_encontro_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY caravana_encontro
    ADD CONSTRAINT encontro_caravana_encontro_fk FOREIGN KEY (id_encontro) REFERENCES encontro(id_encontro);


--
-- TOC entry 2131 (class 2606 OID 40191)
-- Name: encontro_encontro_participante_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY encontro_participante
    ADD CONSTRAINT encontro_encontro_participante_fk FOREIGN KEY (id_encontro) REFERENCES encontro(id_encontro);


--
-- TOC entry 2140 (class 2606 OID 40196)
-- Name: encontro_evento_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento
    ADD CONSTRAINT encontro_evento_fk FOREIGN KEY (id_encontro) REFERENCES encontro(id_encontro);


--
-- TOC entry 2138 (class 2606 OID 80219)
-- Name: encontro_id_municipio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY encontro
    ADD CONSTRAINT encontro_id_municipio_fkey FOREIGN KEY (id_municipio) REFERENCES municipio(id_municipio) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 2137 (class 2606 OID 72016)
-- Name: encontro_id_tipo_horario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY encontro
    ADD CONSTRAINT encontro_id_tipo_horario_fkey FOREIGN KEY (id_tipo_horario) REFERENCES tipo_horario(id_tipo_horario);


--
-- TOC entry 2136 (class 2606 OID 40201)
-- Name: estado_municipio_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY municipio
    ADD CONSTRAINT estado_municipio_fk FOREIGN KEY (id_estado) REFERENCES estado(id_estado);


--
-- TOC entry 2146 (class 2606 OID 40206)
-- Name: evento_evento_palestrante_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_palestrante
    ADD CONSTRAINT evento_evento_palestrante_fk FOREIGN KEY (id_evento) REFERENCES evento(id_evento);


--
-- TOC entry 2150 (class 2606 OID 40211)
-- Name: evento_evento_realizacao_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_realizacao
    ADD CONSTRAINT evento_evento_realizacao_fk FOREIGN KEY (id_evento) REFERENCES evento(id_evento);


--
-- TOC entry 2143 (class 2606 OID 80224)
-- Name: evento_id_artigo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento
    ADD CONSTRAINT evento_id_artigo_fkey FOREIGN KEY (id_artigo) REFERENCES artigo(id_artigo);


--
-- TOC entry 2144 (class 2606 OID 40216)
-- Name: evento_realizacao_evento_demanda_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_demanda
    ADD CONSTRAINT evento_realizacao_evento_demanda_fk FOREIGN KEY (evento) REFERENCES evento_realizacao(evento);


--
-- TOC entry 2148 (class 2606 OID 40221)
-- Name: evento_realizacao_evento_participacao_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_participacao
    ADD CONSTRAINT evento_realizacao_evento_participacao_fk FOREIGN KEY (id_evento_realizacao) REFERENCES evento_realizacao(evento);


--
-- TOC entry 2141 (class 2606 OID 40231)
-- Name: evento_responsavel_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento
    ADD CONSTRAINT evento_responsavel_fkey FOREIGN KEY (responsavel) REFERENCES pessoa(id_pessoa);


--
-- TOC entry 2152 (class 2606 OID 40236)
-- Name: evento_tags_id_evento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_tags
    ADD CONSTRAINT evento_tags_id_evento_fkey FOREIGN KEY (id_evento) REFERENCES evento(id_evento);


--
-- TOC entry 2153 (class 2606 OID 40241)
-- Name: evento_tags_id_tag_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_tags
    ADD CONSTRAINT evento_tags_id_tag_fkey FOREIGN KEY (id_tag) REFERENCES tags(id);


--
-- TOC entry 2125 (class 2606 OID 40246)
-- Name: instituicao_caravana_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY caravana
    ADD CONSTRAINT instituicao_caravana_fk FOREIGN KEY (id_instituicao) REFERENCES instituicao(id_instituicao);


--
-- TOC entry 2132 (class 2606 OID 40251)
-- Name: instituicao_encontro_participante_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY encontro_participante
    ADD CONSTRAINT instituicao_encontro_participante_fk FOREIGN KEY (id_instituicao) REFERENCES instituicao(id_instituicao);


--
-- TOC entry 2126 (class 2606 OID 40256)
-- Name: municipio_caravana_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY caravana
    ADD CONSTRAINT municipio_caravana_fk FOREIGN KEY (id_municipio) REFERENCES municipio(id_municipio);


--
-- TOC entry 2133 (class 2606 OID 40261)
-- Name: municipio_encontro_participante_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY encontro_participante
    ADD CONSTRAINT municipio_encontro_participante_fk FOREIGN KEY (id_municipio) REFERENCES municipio(id_municipio);


--
-- TOC entry 2129 (class 2606 OID 40266)
-- Name: pessoa_caravana_encontro_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY caravana_encontro
    ADD CONSTRAINT pessoa_caravana_encontro_fk FOREIGN KEY (responsavel) REFERENCES pessoa(id_pessoa);


--
-- TOC entry 2134 (class 2606 OID 40271)
-- Name: pessoa_encontro_participante_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY encontro_participante
    ADD CONSTRAINT pessoa_encontro_participante_fk FOREIGN KEY (id_pessoa) REFERENCES pessoa(id_pessoa);


--
-- TOC entry 2145 (class 2606 OID 40276)
-- Name: pessoa_evento_demanda_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_demanda
    ADD CONSTRAINT pessoa_evento_demanda_fk FOREIGN KEY (id_pessoa) REFERENCES pessoa(id_pessoa);


--
-- TOC entry 2147 (class 2606 OID 40281)
-- Name: pessoa_evento_palestrante_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_palestrante
    ADD CONSTRAINT pessoa_evento_palestrante_fk FOREIGN KEY (id_pessoa) REFERENCES pessoa(id_pessoa);


--
-- TOC entry 2149 (class 2606 OID 40286)
-- Name: pessoa_evento_participacao_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_participacao
    ADD CONSTRAINT pessoa_evento_participacao_fk FOREIGN KEY (id_pessoa) REFERENCES pessoa(id_pessoa);


--
-- Name: pessoa_mudar_email_atualizado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY pessoa_mudar_email
    ADD CONSTRAINT pessoa_mudar_email_atualizado_por_fkey FOREIGN KEY (atualizado_por) REFERENCES pessoa(id_pessoa);


--
-- Name: sala_evento_realizacao_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_realizacao
    ADD CONSTRAINT sala_evento_realizacao_fk FOREIGN KEY (id_sala) REFERENCES sala(id_sala);


--
-- TOC entry 2155 (class 2606 OID 40296)
-- Name: sexo_pessoa_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY pessoa
    ADD CONSTRAINT sexo_pessoa_fk FOREIGN KEY (id_sexo) REFERENCES sexo(id_sexo);


--
-- TOC entry 2142 (class 2606 OID 40301)
-- Name: tipo_evento_evento_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento
    ADD CONSTRAINT tipo_evento_evento_fk FOREIGN KEY (id_tipo_evento) REFERENCES tipo_evento(id_tipo_evento);


--
-- TOC entry 2154 (class 2606 OID 40306)
-- Name: tipo_mensagem_email_mensagem_email_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mensagem_email
    ADD CONSTRAINT tipo_mensagem_email_mensagem_email_fk FOREIGN KEY (id_tipo_mensagem_email) REFERENCES tipo_mensagem_email(id_tipo_mensagem_email);


--
-- TOC entry 2135 (class 2606 OID 40311)
-- Name: tipo_usuario_encontro_participante_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY encontro_participante
    ADD CONSTRAINT tipo_usuario_encontro_participante_fk FOREIGN KEY (id_tipo_usuario) REFERENCES tipo_usuario(id_tipo_usuario);


-- Completed on 2016-05-24 19:30:00 BRT

--
-- PostgreSQL database dump complete
--

COMMIT;
