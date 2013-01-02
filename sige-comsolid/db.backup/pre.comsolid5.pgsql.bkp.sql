--
-- PostgreSQL database dump
--

-- Dumped from database version 8.3.17
-- Dumped by pg_dump version 9.1.4
-- Started on 2012-11-20 11:47:52 BRT

SET statement_timeout = 0;
SET client_encoding = 'LATIN1';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- TOC entry 6 (class 2615 OID 32817052)
-- Name: armario; Type: SCHEMA; Schema: -; Owner: comsolid
--

CREATE SCHEMA armario;


ALTER SCHEMA armario OWNER TO comsolid;

--
-- TOC entry 7 (class 2615 OID 34527798)
-- Name: bv; Type: SCHEMA; Schema: -; Owner: comsolid
--

CREATE SCHEMA bv;


ALTER SCHEMA bv OWNER TO comsolid;

--
-- TOC entry 577 (class 2612 OID 22943996)
-- Name: plperl; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: postgres
--

CREATE OR REPLACE PROCEDURAL LANGUAGE plperl;


ALTER PROCEDURAL LANGUAGE plperl OWNER TO postgres;

--
-- TOC entry 576 (class 2612 OID 22943993)
-- Name: plpgsql; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: postgres
--

CREATE OR REPLACE PROCEDURAL LANGUAGE plpgsql;


ALTER PROCEDURAL LANGUAGE plpgsql OWNER TO postgres;

SET search_path = public, pg_catalog;

--
-- TOC entry 191 (class 1255 OID 32948390)
-- Dependencies: 576 3
-- Name: funcgeraralunopreferencia(); Type: FUNCTION; Schema: public; Owner: comsolid
--

CREATE FUNCTION funcgeraralunopreferencia() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/*
Criador: Siqueira, Robson.
Data: 20/11/2011.
DESCRIÇÃO: 
  Gera os armários individuais para cada aluno.
*/
DECLARE
  cursArmario CURSOR FOR SELECT id_posicao_armario 
                       FROM armario.posicao_armario
                       ORDER BY apelido;

  codPosicaoArmario INTEGER;
  codPrioridade INTEGER;
  codPessoa INTEGER;
BEGIN
  codPrioridade = 1;
  IF NEW.id_pessoa IS NULL THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' THEN
    DELETE FROM armario.aluno_preferencia WHERE id_pessoa = OLD.id_pessoa;
  END IF;

  SELECT id_pessoa INTO codPessoa FROM armario.aluno_preferencia WHERE id_pessoa = NEW.id_pessoa;
  IF NOT FOUND THEN
    OPEN cursArmario;  
    FETCH cursArmario INTO codPosicaoArmario;
    WHILE FOUND LOOP
      INSERT INTO armario.aluno_preferencia (id_pessoa, id_posicao_armario, prioridade) VALUES (NEW.id_pessoa, codPosicaoArmario, codPrioridade);
      FETCH cursArmario INTO codPosicaoArmario;
--      codPrioridade = codPrioridade + 1;
    END LOOP;
    CLOSE cursArmario;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.funcgeraralunopreferencia() OWNER TO comsolid;

--
-- TOC entry 189 (class 1255 OID 32817387)
-- Dependencies: 3 576
-- Name: funcgerararmarios(); Type: FUNCTION; Schema: public; Owner: comsolid
--

CREATE FUNCTION funcgerararmarios() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/*
Criador: Siqueira, Robson.
Data: 20/11/2011.
DESCRIÇÃO: 
  Gera os armários individuais para cada armário criado.
*/
DECLARE
  cursArmario CURSOR FOR SELECT id_posicao_armario 
                       FROM armario.posicao_armario
                       ORDER BY apelido;

  codPosicaoArmario INTEGER;
BEGIN

  OPEN cursArmario;  
  FETCH cursArmario INTO codPosicaoArmario;
  WHILE FOUND LOOP
    INSERT INTO armario.armario_individual (id_armario, id_posicao_armario) VALUES (NEW.id_armario, codPosicaoArmario);
    FETCH cursArmario INTO codPosicaoArmario;
  END LOOP;
  CLOSE cursArmario;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.funcgerararmarios() OWNER TO comsolid;

--
-- TOC entry 192 (class 1255 OID 23525605)
-- Dependencies: 576 3
-- Name: funcgerarsenha(character varying); Type: FUNCTION; Schema: public; Owner: comsolid
--

CREATE FUNCTION funcgerarsenha(codemail character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
/*
Criador: Siqueira, Robson.
Data: 05/08/2011.
DESCRI��O: 
  A partir de um email v�lido, gera uma senha de 10 caracteres com letras mai�sculas e n�meros.
  Se o email estiver incorreto, gera uma exce��o.
  A senha j� � armazenada no BD com criptografia MD5.
*/

DECLARE
  codPessoa INTEGER;
  codSenha VARCHAR(100);
BEGIN
  SELECT id_pessoa INTO codPessoa
  FROM pessoa
  WHERE email = codEmail;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Email Inv�lido';
  END IF;

  codSenha = (((random() * (100000000000000)::double precision))::bigint)::character varying;
  SELECT UPPER(md5(codSenha)::varchar(10)) INTO codSenha;
  UPDATE pessoa 
  SET senha = md5(codSenha)
  WHERE id_pessoa = codPessoa;
  
  RETURN codSenha;
END;
$$;


ALTER FUNCTION public.funcgerarsenha(codemail character varying) OWNER TO comsolid;

--
-- TOC entry 195 (class 1255 OID 34297800)
-- Dependencies: 3 576
-- Name: funcinseriraluno(bigint, character varying, character varying); Type: FUNCTION; Schema: public; Owner: comsolid
--

CREATE FUNCTION funcinseriraluno(codmatricula bigint, codnome character varying, codemail character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
/*
Criador: Siqueira, Robson da Silva.
Data: 26/12/2011.
DESCRIÇÃO: 
  Inserir alunos no BD. 
  Existe uma tabela pessoa que deve concentrar os dados das pessoas. Na tabela pessoa, o email é obrigatório e não há obrigatoriedade disso para os alunos. Então vamos tentar mesclar as informações.

*/
DECLARE
  codPessoa INTEGER;
BEGIN

  IF codEmail IS NOT NULL THEN

    SELECT id_pessoa INTO codPessoa
    FROM pessoa
    WHERE email = codEmail;

    IF FOUND THEN
      INSERT INTO armario.aluno (matricula, nome, id_pessoa) VALUES (codMatricula, codNome, codPessoa);
      UPDATE pessoa SET nome = codNome WHERE id_pessoa = codPessoa;
      RETURN TRUE;   
    END IF;

    INSERT INTO pessoa (nome, apelido, email, nascimento) VALUES (codNome, codNome::varchar(10), codEmail, '01/01/1980');
    RAISE NOTICE 'Pessoa inserida';
    PERFORM funcInserirAluno(codMatricula, codNome, codEmail);
    RETURN true;
  END IF;

  SELECT id_pessoa INTO codPessoa
  FROM pessoa
  WHERE UPPER(nome) = UPPER(codNome);

  IF FOUND THEN
    INSERT INTO armario.aluno (matricula, nome, id_pessoa) VALUES (codMatricula, codNome, codPessoa);
    UPDATE pessoa SET nome = codNome WHERE id_pessoa = codPessoa;
    RAISE NOTICE 'Inserido pelo nome';
    RETURN TRUE;   
  END IF;

  INSERT INTO armario.aluno (matricula, nome) VALUES (codMatricula, codNome);

  RETURN TRUE;
END;
$$;


ALTER FUNCTION public.funcinseriraluno(codmatricula bigint, codnome character varying, codemail character varying) OWNER TO comsolid;

--
-- TOC entry 196 (class 1255 OID 34297805)
-- Dependencies: 3 576
-- Name: funcselecionararmario(integer); Type: FUNCTION; Schema: public; Owner: comsolid
--

CREATE FUNCTION funcselecionararmario(codpessoa integer, OUT codarmario integer, OUT codposicaoarmario integer, OUT codresultado boolean) RETURNS record
    LANGUAGE plpgsql
    AS $$
/*
Criador: Siqueira, Robson da Silva.
Data: 26/12/2011.
DESCRIÇÃO: Sortear o armário e a posição que o usuário teve como preferência, de acordo com a disponibilidade.
           Se retornar TRUE encontrou um armário.
           Se retornar FALSE não há armário disponível.
*/
DECLARE
  cursArmario CURSOR FOR SELECT id_posicao_armario
                         FROM armario.aluno_preferencia
                         WHERE id_pessoa = codPessoa
                         ORDER BY prioridade, id_posicao_armario ASC;
BEGIN

  OPEN cursArmario;  
  FETCH cursArmario INTO codPosicaoArmario;
  WHILE FOUND LOOP
    SELECT id_armario INTO codArmario
    FROM armario.armario_individual
    WHERE id_pessoa IS NULL
      AND id_posicao_armario = codPosicaoArmario
    ORDER BY id_armario ASC
    LIMIT 1;
    IF FOUND THEN 
      CLOSE cursArmario;
      codResultado = TRUE;
      RETURN ;
    END IF;
    FETCH cursArmario INTO codPosicaoArmario;
  END LOOP;
  codResultado = FALSE;
  RETURN ;
END;
$$;


ALTER FUNCTION public.funcselecionararmario(codpessoa integer, OUT codarmario integer, OUT codposicaoarmario integer, OUT codresultado boolean) OWNER TO comsolid;

--
-- TOC entry 188 (class 1255 OID 32950604)
-- Dependencies: 3 576
-- Name: funcsorteararmario(); Type: FUNCTION; Schema: public; Owner: comsolid
--

CREATE FUNCTION funcsorteararmario() RETURNS integer
    LANGUAGE plpgsql
    AS $$
/*
Criador: Siqueira, Robson.
Data: 20/11/2011.
DESCRIÇÃO: 
  Sortear Armários para os alunos ainda sem armários.

  Falta o INSERT.

  Falta verificar se ainda há pessoas ou armários para selecionar.
*/
DECLARE
  codOffset INTEGER;
  codQuantidade INTEGER;
  codQuantidadeEscolhida INTEGER;
  codPessoa INTEGER;
  codMatricula BIGINT;
  codNome VARCHAR(100);
  codPosicaoArmario INTEGER;
  codPrioridade INTEGER;
  codArmario INTEGER;
  codChave INTEGER;
  codNomeArmario VARCHAR(15);
  codApelido CHAR(2);
  codResultado BOOLEAN;
  cursArmario CURSOR FOR SELECT DISTINCT(prioridade)
                         FROM armario.aluno_preferencia
                         WHERE id_pessoa = codPessoa
                         ORDER BY prioridade ASC;

BEGIN

  SELECT COUNT(*) INTO codQuantidadeEscolhida
  FROM armario.armario_individual
  WHERE id_pessoa IS NOT NULL;

  RAISE NOTICE 'Quantidade Escolhida = %', codQuantidadeEscolhida;

  IF codQuantidadeEscolhida > 0 THEN

    SELECT COUNT(DISTINCT(p.id_pessoa)) INTO codQuantidade
    FROM pessoa p INNER JOIN armario.aluno a ON (a.id_pessoa=p.id_pessoa)
    WHERE a.id_pessoa NOT IN (SELECT DISTINCT(id_pessoa) FROM armario.armario_individual WHERE id_pessoa IS NOT NULL); 

  ELSE

    SELECT COUNT(DISTINCT(p.id_pessoa)) INTO codQuantidade
    FROM pessoa p INNER JOIN armario.aluno a ON (a.id_pessoa=p.id_pessoa);
 
  END IF;    

  RAISE NOTICE 'Quantidade Restante = %', codQuantidade;

  SELECT (RANDOM()*(codQuantidade - 1))::INTEGER + 1 INTO codOffset;

  RAISE NOTICE 'Valor Escohido = %', codOffset;

  IF codQuantidadeEscolhida > 0 THEN
    SELECT p.id_pessoa INTO codPessoa
    FROM pessoa p INNER JOIN armario.aluno a ON (a.id_pessoa=p.id_pessoa)
    WHERE a.id_pessoa NOT IN (SELECT id_pessoa FROM armario.armario_individual WHERE id_pessoa IS NOT NULL)
    ORDER BY p.nome
    OFFSET codOffset 
    LIMIT 1;
  ELSE
    SELECT p.id_pessoa INTO codPessoa
    FROM pessoa p INNER JOIN armario.aluno a ON (a.id_pessoa=p.id_pessoa)
    ORDER BY p.nome
    OFFSET codOffset 
    LIMIT 1;
  END IF;

  SELECT p.nome, a.matricula INTO codNome, codMatricula
  FROM pessoa p INNER JOIN armario.aluno a ON (p.id_pessoa = a.id_pessoa)
  WHERE p.id_pessoa = codPessoa;

  RAISE NOTICE 'Aluno escolhido foi Matricula: %, Nome: %', codMatricula, codNome;

  codResultado = FALSE;
  OPEN cursArmario;  
  FETCH cursArmario INTO codPrioridade;
  WHILE FOUND LOOP
    SELECT id_armario, id_posicao_armario INTO codArmario, codPosicaoArmario
    FROM armario.armario_individual
    WHERE id_pessoa IS NULL
      AND id_posicao_armario IN (SELECT id_posicao_armario 
                                 FROM armario.aluno_preferencia
                                 WHERE id_pessoa = codPessoa
                                   AND prioridade = codPrioridade)
    ORDER BY id_posicao_armario, id_armario  ASC
    LIMIT 1;
    IF FOUND THEN 
      CLOSE cursArmario;
      FOUND = FALSE;
      codResultado = TRUE;
    ELSE
     FETCH cursArmario INTO codPrioridade;
    END IF;
  END LOOP;


  IF NOT codResultado THEN
    RAISE NOTICE 'Não há mais armários disponíveis';
    codPessoa = 0;
  ELSE
    UPDATE armario.armario_individual SET id_pessoa = codPessoa 
    WHERE id_armario = codArmario 
      AND id_posicao_armario = codPosicaoArmario;
  END IF;

  SELECT a.nome, pa.apelido, ai.codigo_chave INTO codNomeArmario, codApelido, codChave
  FROM armario.armario_individual ai INNER JOIN armario.posicao_armario pa ON (ai.id_posicao_armario = pa.id_posicao_armario)
                                     INNER JOIN armario.armario a ON (ai.id_armario = a.id_armario)
  WHERE ai.id_pessoa = codPessoa;

  IF FOUND THEN
    RAISE NOTICE 'Armario: %. Posicao: %. Chave: %', codNomeArmario, codApelido, codChave;
  END IF;

  RETURN codPessoa;
END;
$$;


ALTER FUNCTION public.funcsorteararmario() OWNER TO comsolid;

--
-- TOC entry 190 (class 1255 OID 32950605)
-- Dependencies: 576 3
-- Name: funcsorteararmarios(); Type: FUNCTION; Schema: public; Owner: comsolid
--

CREATE FUNCTION funcsorteararmarios() RETURNS boolean
    LANGUAGE plpgsql
    AS $$
/*
Criador: Siqueira, Robson.
Data: 20/11/2011.
DESCRIÇÃO: 
  Sortear Armários para os alunos ainda sem armários.

  Falta o INSERT.

  Falta verificar se ainda há pessoas ou armários para selecionar.
*/
DECLARE
  codResultado BOOLEAN;
  codQuantidadeArmario INTEGER;
  codQuantidade INTEGER;
BEGIN
  codResultado = TRUE;
  WHILE codResultado LOOP
    SELECT COUNT(*) INTO codQuantidadeArmario
    FROM armario.armario_individual
    WHERE id_pessoa IS NULL;

    SELECT COUNT(DISTINCT(p.id_pessoa)) INTO codQuantidade
      FROM pessoa p INNER JOIN armario.aluno a ON (a.id_pessoa=p.id_pessoa)
      WHERE a.id_pessoa NOT IN (SELECT DISTINCT(id_pessoa) FROM armario.armario_individual WHERE id_pessoa IS NOT NULL);
  
    IF codQuantidadeArmario = 0 THEN
      RAISE NOTICE 'Não há mais armários disponíveis.';
      codResultado = FALSE;
    ELSIF codQuantidade = 0 THEN
      RAISE NOTICE 'Não há alunos sem armários';
      codResultado = FALSE;
    ELSE
      PERFORM funcSortearArmario();
    END IF;
  END LOOP;

  RETURN TRUE;
END;
$$;


ALTER FUNCTION public.funcsorteararmarios() OWNER TO comsolid;

--
-- TOC entry 193 (class 1255 OID 23525606)
-- Dependencies: 3 576
-- Name: funcvalidaevento(); Type: FUNCTION; Schema: public; Owner: comsolid
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


ALTER FUNCTION public.funcvalidaevento() OWNER TO comsolid;

--
-- TOC entry 194 (class 1255 OID 23525607)
-- Dependencies: 576 3
-- Name: funcvalidausuario(); Type: FUNCTION; Schema: public; Owner: comsolid
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


ALTER FUNCTION public.funcvalidausuario() OWNER TO comsolid;

SET search_path = armario, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 173 (class 1259 OID 33214020)
-- Dependencies: 6
-- Name: administrador; Type: TABLE; Schema: armario; Owner: comsolid; Tablespace: 
--

CREATE TABLE administrador (
    pessoa bigint NOT NULL
);


ALTER TABLE armario.administrador OWNER TO comsolid;

--
-- TOC entry 172 (class 1259 OID 32817087)
-- Dependencies: 1932 6
-- Name: aluno; Type: TABLE; Schema: armario; Owner: comsolid; Tablespace: 
--

CREATE TABLE aluno (
    matricula bigint NOT NULL,
    id_pessoa integer NOT NULL,
    senha_tmp character varying(70),
    nome character varying(100) NOT NULL,
    email_enviado boolean DEFAULT false NOT NULL,
    curso character varying(40) NOT NULL
);


ALTER TABLE armario.aluno OWNER TO comsolid;

--
-- TOC entry 168 (class 1259 OID 32817067)
-- Dependencies: 6
-- Name: aluno_preferencia; Type: TABLE; Schema: armario; Owner: comsolid; Tablespace: 
--

CREATE TABLE aluno_preferencia (
    id_posicao_armario integer NOT NULL,
    id_pessoa integer NOT NULL,
    prioridade integer NOT NULL
);


ALTER TABLE armario.aluno_preferencia OWNER TO comsolid;

--
-- TOC entry 170 (class 1259 OID 32817075)
-- Dependencies: 6
-- Name: armario; Type: TABLE; Schema: armario; Owner: comsolid; Tablespace: 
--

CREATE TABLE armario (
    id_armario integer NOT NULL,
    nome character varying(15) NOT NULL
);


ALTER TABLE armario.armario OWNER TO comsolid;

--
-- TOC entry 169 (class 1259 OID 32817073)
-- Dependencies: 6 170
-- Name: armario_id_armario_seq; Type: SEQUENCE; Schema: armario; Owner: comsolid
--

CREATE SEQUENCE armario_id_armario_seq
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE armario.armario_id_armario_seq OWNER TO comsolid;

--
-- TOC entry 2080 (class 0 OID 0)
-- Dependencies: 169
-- Name: armario_id_armario_seq; Type: SEQUENCE OWNED BY; Schema: armario; Owner: comsolid
--

ALTER SEQUENCE armario_id_armario_seq OWNED BY armario.id_armario;


--
-- TOC entry 2081 (class 0 OID 0)
-- Dependencies: 169
-- Name: armario_id_armario_seq; Type: SEQUENCE SET; Schema: armario; Owner: comsolid
--

SELECT pg_catalog.setval('armario_id_armario_seq', 89, true);


--
-- TOC entry 171 (class 1259 OID 32817081)
-- Dependencies: 6
-- Name: armario_individual; Type: TABLE; Schema: armario; Owner: comsolid; Tablespace: 
--

CREATE TABLE armario_individual (
    id_armario integer NOT NULL,
    id_posicao_armario integer NOT NULL,
    id_pessoa integer,
    codigo_chave integer
);


ALTER TABLE armario.armario_individual OWNER TO comsolid;

--
-- TOC entry 167 (class 1259 OID 32817060)
-- Dependencies: 6
-- Name: posicao_armario; Type: TABLE; Schema: armario; Owner: comsolid; Tablespace: 
--

CREATE TABLE posicao_armario (
    id_posicao_armario integer NOT NULL,
    apelido character(2) NOT NULL
);


ALTER TABLE armario.posicao_armario OWNER TO comsolid;

--
-- TOC entry 166 (class 1259 OID 32817058)
-- Dependencies: 6 167
-- Name: posicao_armario_id_posicao_armario_seq; Type: SEQUENCE; Schema: armario; Owner: comsolid
--

CREATE SEQUENCE posicao_armario_id_posicao_armario_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE armario.posicao_armario_id_posicao_armario_seq OWNER TO comsolid;

--
-- TOC entry 2082 (class 0 OID 0)
-- Dependencies: 166
-- Name: posicao_armario_id_posicao_armario_seq; Type: SEQUENCE OWNED BY; Schema: armario; Owner: comsolid
--

ALTER SEQUENCE posicao_armario_id_posicao_armario_seq OWNED BY posicao_armario.id_posicao_armario;


--
-- TOC entry 2083 (class 0 OID 0)
-- Dependencies: 166
-- Name: posicao_armario_id_posicao_armario_seq; Type: SEQUENCE SET; Schema: armario; Owner: comsolid
--

SELECT pg_catalog.setval('posicao_armario_id_posicao_armario_seq', 1, false);


SET search_path = bv, pg_catalog;

--
-- TOC entry 174 (class 1259 OID 34527814)
-- Dependencies: 1933 7
-- Name: bv_pearson; Type: TABLE; Schema: bv; Owner: comsolid; Tablespace: 
--

CREATE TABLE bv_pearson (
    login bigint NOT NULL,
    nome character varying(200) NOT NULL,
    email character varying(100),
    senha character varying(255) DEFAULT md5(((((random() * (1000)::double precision))::integer)::character varying)::text),
    curso character varying(50)
);


ALTER TABLE bv.bv_pearson OWNER TO comsolid;

SET search_path = public, pg_catalog;

--
-- TOC entry 129 (class 1259 OID 23525608)
-- Dependencies: 3
-- Name: caravana; Type: TABLE; Schema: public; Owner: comsolid; Tablespace: 
--

CREATE TABLE caravana (
    id_caravana integer NOT NULL,
    nome_caravana character varying(100) NOT NULL,
    apelido_caravana character varying(20) NOT NULL,
    id_municipio integer NOT NULL,
    id_instituicao integer,
    criador integer NOT NULL
);


ALTER TABLE public.caravana OWNER TO comsolid;

--
-- TOC entry 130 (class 1259 OID 23525611)
-- Dependencies: 1896 3
-- Name: caravana_encontro; Type: TABLE; Schema: public; Owner: comsolid; Tablespace: 
--

CREATE TABLE caravana_encontro (
    id_caravana integer NOT NULL,
    id_encontro integer NOT NULL,
    responsavel integer NOT NULL,
    validada boolean DEFAULT false NOT NULL
);


ALTER TABLE public.caravana_encontro OWNER TO comsolid;

--
-- TOC entry 2084 (class 0 OID 0)
-- Dependencies: 130
-- Name: COLUMN caravana_encontro.responsavel; Type: COMMENT; Schema: public; Owner: comsolid
--

COMMENT ON COLUMN caravana_encontro.responsavel IS 'Respons�vel pela caravana.
Seu cadastro deve estar realizado previamente.';


--
-- TOC entry 131 (class 1259 OID 23525615)
-- Dependencies: 3 129
-- Name: caravana_id_caravana_seq; Type: SEQUENCE; Schema: public; Owner: comsolid
--

CREATE SEQUENCE caravana_id_caravana_seq
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.caravana_id_caravana_seq OWNER TO comsolid;

--
-- TOC entry 2085 (class 0 OID 0)
-- Dependencies: 131
-- Name: caravana_id_caravana_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: comsolid
--

ALTER SEQUENCE caravana_id_caravana_seq OWNED BY caravana.id_caravana;


--
-- TOC entry 2086 (class 0 OID 0)
-- Dependencies: 131
-- Name: caravana_id_caravana_seq; Type: SEQUENCE SET; Schema: public; Owner: comsolid
--

SELECT pg_catalog.setval('caravana_id_caravana_seq', 54, true);


--
-- TOC entry 132 (class 1259 OID 23525622)
-- Dependencies: 3
-- Name: dificuldade_evento; Type: TABLE; Schema: public; Owner: comsolid; Tablespace: 
--

CREATE TABLE dificuldade_evento (
    id_dificuldade_evento integer NOT NULL,
    descricao_dificuldade_evento character varying(15) NOT NULL
);


ALTER TABLE public.dificuldade_evento OWNER TO comsolid;

--
-- TOC entry 2087 (class 0 OID 0)
-- Dependencies: 132
-- Name: TABLE dificuldade_evento; Type: COMMENT; Schema: public; Owner: comsolid
--

COMMENT ON TABLE dificuldade_evento IS 'Mostra o n�vel de dificuldade do Evento.
B�sico
Intermedi�rio
Avan�ado';


--
-- TOC entry 133 (class 1259 OID 23525627)
-- Dependencies: 1898 3
-- Name: encontro; Type: TABLE; Schema: public; Owner: comsolid; Tablespace: 
--

CREATE TABLE encontro (
    id_encontro integer NOT NULL,
    nome_encontro character varying(100) NOT NULL,
    apelido_encontro character varying(10) NOT NULL,
    data_inicio date NOT NULL,
    data_fim date NOT NULL,
    ativo boolean DEFAULT false NOT NULL
);


ALTER TABLE public.encontro OWNER TO comsolid;

--
-- TOC entry 134 (class 1259 OID 23525631)
-- Dependencies: 1900 3
-- Name: encontro_horario; Type: TABLE; Schema: public; Owner: comsolid; Tablespace: 
--

CREATE TABLE encontro_horario (
    id_encontro_horario integer NOT NULL,
    descricao character varying(20) NOT NULL,
    hora_inicial time without time zone NOT NULL,
    hora_final time without time zone NOT NULL,
    CONSTRAINT encontro_horario_check CHECK ((hora_inicial < hora_final))
);


ALTER TABLE public.encontro_horario OWNER TO comsolid;

--
-- TOC entry 135 (class 1259 OID 23525635)
-- Dependencies: 3 134
-- Name: encontro_horario_id_encontro_horario_seq; Type: SEQUENCE; Schema: public; Owner: comsolid
--

CREATE SEQUENCE encontro_horario_id_encontro_horario_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.encontro_horario_id_encontro_horario_seq OWNER TO comsolid;

--
-- TOC entry 2088 (class 0 OID 0)
-- Dependencies: 135
-- Name: encontro_horario_id_encontro_horario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: comsolid
--

ALTER SEQUENCE encontro_horario_id_encontro_horario_seq OWNED BY encontro_horario.id_encontro_horario;


--
-- TOC entry 2089 (class 0 OID 0)
-- Dependencies: 135
-- Name: encontro_horario_id_encontro_horario_seq; Type: SEQUENCE SET; Schema: public; Owner: comsolid
--

SELECT pg_catalog.setval('encontro_horario_id_encontro_horario_seq', 1, false);


--
-- TOC entry 136 (class 1259 OID 23525637)
-- Dependencies: 3 133
-- Name: encontro_id_encontro_seq; Type: SEQUENCE; Schema: public; Owner: comsolid
--

CREATE SEQUENCE encontro_id_encontro_seq
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.encontro_id_encontro_seq OWNER TO comsolid;

--
-- TOC entry 2090 (class 0 OID 0)
-- Dependencies: 136
-- Name: encontro_id_encontro_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: comsolid
--

ALTER SEQUENCE encontro_id_encontro_seq OWNED BY encontro.id_encontro;


--
-- TOC entry 2091 (class 0 OID 0)
-- Dependencies: 136
-- Name: encontro_id_encontro_seq; Type: SEQUENCE SET; Schema: public; Owner: comsolid
--

SELECT pg_catalog.setval('encontro_id_encontro_seq', 3, true);


--
-- TOC entry 137 (class 1259 OID 23525639)
-- Dependencies: 1901 1902 1903 1904 3
-- Name: encontro_participante; Type: TABLE; Schema: public; Owner: comsolid; Tablespace: 
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


ALTER TABLE public.encontro_participante OWNER TO comsolid;

--
-- TOC entry 138 (class 1259 OID 23525644)
-- Dependencies: 3
-- Name: estado; Type: TABLE; Schema: public; Owner: comsolid; Tablespace: 
--

CREATE TABLE estado (
    id_estado integer NOT NULL,
    nome_estado character varying(30) NOT NULL,
    codigo_estado character(2) NOT NULL
);


ALTER TABLE public.estado OWNER TO comsolid;

--
-- TOC entry 139 (class 1259 OID 23525647)
-- Dependencies: 3 138
-- Name: estado_id_estado_seq; Type: SEQUENCE; Schema: public; Owner: comsolid
--

CREATE SEQUENCE estado_id_estado_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.estado_id_estado_seq OWNER TO comsolid;

--
-- TOC entry 2092 (class 0 OID 0)
-- Dependencies: 139
-- Name: estado_id_estado_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: comsolid
--

ALTER SEQUENCE estado_id_estado_seq OWNED BY estado.id_estado;


--
-- TOC entry 2093 (class 0 OID 0)
-- Dependencies: 139
-- Name: estado_id_estado_seq; Type: SEQUENCE SET; Schema: public; Owner: comsolid
--

SELECT pg_catalog.setval('estado_id_estado_seq', 1, false);


--
-- TOC entry 140 (class 1259 OID 23525649)
-- Dependencies: 1907 1908 1909 1910 1911 3
-- Name: evento; Type: TABLE; Schema: public; Owner: comsolid; Tablespace: 
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
    curriculum text DEFAULT 'Curriculum B�sico'::text NOT NULL,
    id_dificuldade_evento integer DEFAULT 1 NOT NULL,
    perfil_minimo text DEFAULT 'Perfil M�nimo do Participante'::text NOT NULL,
    preferencia_horario text
);


ALTER TABLE public.evento OWNER TO comsolid;

--
-- TOC entry 2094 (class 0 OID 0)
-- Dependencies: 140
-- Name: TABLE evento; Type: COMMENT; Schema: public; Owner: comsolid
--

COMMENT ON TABLE evento IS 'Evento � qualquer tipo de atividade no Encontro: Palestra, Minicurso, Oficina.';


--
-- TOC entry 2095 (class 0 OID 0)
-- Dependencies: 140
-- Name: COLUMN evento.validada; Type: COMMENT; Schema: public; Owner: comsolid
--

COMMENT ON COLUMN evento.validada IS 'O administrador deve indicar qual o evento aprovado.';


--
-- TOC entry 141 (class 1259 OID 23525660)
-- Dependencies: 3
-- Name: evento_arquivo_id_evento_arquivo_seq; Type: SEQUENCE; Schema: public; Owner: comsolid
--

CREATE SEQUENCE evento_arquivo_id_evento_arquivo_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.evento_arquivo_id_evento_arquivo_seq OWNER TO comsolid;

--
-- TOC entry 2096 (class 0 OID 0)
-- Dependencies: 141
-- Name: evento_arquivo_id_evento_arquivo_seq; Type: SEQUENCE SET; Schema: public; Owner: comsolid
--

SELECT pg_catalog.setval('evento_arquivo_id_evento_arquivo_seq', 1, false);


--
-- TOC entry 142 (class 1259 OID 23525662)
-- Dependencies: 1912 1913 3
-- Name: evento_arquivo; Type: TABLE; Schema: public; Owner: comsolid; Tablespace: 
--

CREATE TABLE evento_arquivo (
    id_evento_arquivo integer DEFAULT nextval('evento_arquivo_id_evento_arquivo_seq'::regclass) NOT NULL,
    id_evento integer NOT NULL,
    nome_arquivo character varying(255) NOT NULL,
    arquivo oid NOT NULL,
    nome_arquivo_md5 character varying(255) DEFAULT md5(((((random() * (1000)::double precision))::integer)::character varying)::text) NOT NULL
);


ALTER TABLE public.evento_arquivo OWNER TO comsolid;

--
-- TOC entry 143 (class 1259 OID 23525667)
-- Dependencies: 1914 3
-- Name: evento_demanda; Type: TABLE; Schema: public; Owner: comsolid; Tablespace: 
--

CREATE TABLE evento_demanda (
    evento integer NOT NULL,
    id_pessoa integer NOT NULL,
    data_solicitacao date DEFAULT now() NOT NULL
);


ALTER TABLE public.evento_demanda OWNER TO comsolid;

--
-- TOC entry 144 (class 1259 OID 23525671)
-- Dependencies: 140 3
-- Name: evento_id_evento_seq; Type: SEQUENCE; Schema: public; Owner: comsolid
--

CREATE SEQUENCE evento_id_evento_seq
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.evento_id_evento_seq OWNER TO comsolid;

--
-- TOC entry 2097 (class 0 OID 0)
-- Dependencies: 144
-- Name: evento_id_evento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: comsolid
--

ALTER SEQUENCE evento_id_evento_seq OWNED BY evento.id_evento;


--
-- TOC entry 2098 (class 0 OID 0)
-- Dependencies: 144
-- Name: evento_id_evento_seq; Type: SEQUENCE SET; Schema: public; Owner: comsolid
--

SELECT pg_catalog.setval('evento_id_evento_seq', 77, true);


--
-- TOC entry 145 (class 1259 OID 23525674)
-- Dependencies: 3
-- Name: evento_palestrante; Type: TABLE; Schema: public; Owner: comsolid; Tablespace: 
--

CREATE TABLE evento_palestrante (
    id_evento integer NOT NULL,
    id_pessoa integer NOT NULL
);


ALTER TABLE public.evento_palestrante OWNER TO comsolid;

--
-- TOC entry 146 (class 1259 OID 23525677)
-- Dependencies: 3
-- Name: evento_participacao; Type: TABLE; Schema: public; Owner: comsolid; Tablespace: 
--

CREATE TABLE evento_participacao (
    evento integer NOT NULL,
    id_pessoa integer NOT NULL
);


ALTER TABLE public.evento_participacao OWNER TO comsolid;

--
-- TOC entry 147 (class 1259 OID 23525680)
-- Dependencies: 1916 3
-- Name: evento_realizacao; Type: TABLE; Schema: public; Owner: comsolid; Tablespace: 
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


ALTER TABLE public.evento_realizacao OWNER TO comsolid;

--
-- TOC entry 148 (class 1259 OID 23525684)
-- Dependencies: 3 147
-- Name: evento_realizacao_evento_seq; Type: SEQUENCE; Schema: public; Owner: comsolid
--

CREATE SEQUENCE evento_realizacao_evento_seq
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.evento_realizacao_evento_seq OWNER TO comsolid;

--
-- TOC entry 2099 (class 0 OID 0)
-- Dependencies: 148
-- Name: evento_realizacao_evento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: comsolid
--

ALTER SEQUENCE evento_realizacao_evento_seq OWNED BY evento_realizacao.evento;


--
-- TOC entry 2100 (class 0 OID 0)
-- Dependencies: 148
-- Name: evento_realizacao_evento_seq; Type: SEQUENCE SET; Schema: public; Owner: comsolid
--

SELECT pg_catalog.setval('evento_realizacao_evento_seq', 13, true);


--
-- TOC entry 149 (class 1259 OID 23525686)
-- Dependencies: 1918 3
-- Name: evento_realizacao_multipla; Type: TABLE; Schema: public; Owner: comsolid; Tablespace: 
--

CREATE TABLE evento_realizacao_multipla (
    evento_realizacao_multipla integer NOT NULL,
    evento integer NOT NULL,
    data date NOT NULL,
    hora_inicio time without time zone NOT NULL,
    hora_fim time without time zone NOT NULL,
    CONSTRAINT evento_realizacao_multipla_check CHECK ((hora_fim > hora_inicio))
);


ALTER TABLE public.evento_realizacao_multipla OWNER TO comsolid;

--
-- TOC entry 150 (class 1259 OID 23525690)
-- Dependencies: 3 149
-- Name: evento_realizacao_multipla_evento_realizacao_multipla_seq; Type: SEQUENCE; Schema: public; Owner: comsolid
--

CREATE SEQUENCE evento_realizacao_multipla_evento_realizacao_multipla_seq
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.evento_realizacao_multipla_evento_realizacao_multipla_seq OWNER TO comsolid;

--
-- TOC entry 2101 (class 0 OID 0)
-- Dependencies: 150
-- Name: evento_realizacao_multipla_evento_realizacao_multipla_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: comsolid
--

ALTER SEQUENCE evento_realizacao_multipla_evento_realizacao_multipla_seq OWNED BY evento_realizacao_multipla.evento_realizacao_multipla;


--
-- TOC entry 2102 (class 0 OID 0)
-- Dependencies: 150
-- Name: evento_realizacao_multipla_evento_realizacao_multipla_seq; Type: SEQUENCE SET; Schema: public; Owner: comsolid
--

SELECT pg_catalog.setval('evento_realizacao_multipla_evento_realizacao_multipla_seq', 9, true);


--
-- TOC entry 151 (class 1259 OID 23525692)
-- Dependencies: 3
-- Name: instituicao; Type: TABLE; Schema: public; Owner: comsolid; Tablespace: 
--

CREATE TABLE instituicao (
    id_instituicao integer NOT NULL,
    nome_instituicao character varying(100) NOT NULL,
    apelido_instituicao character varying(50) NOT NULL
);


ALTER TABLE public.instituicao OWNER TO comsolid;

--
-- TOC entry 2103 (class 0 OID 0)
-- Dependencies: 151
-- Name: TABLE instituicao; Type: COMMENT; Schema: public; Owner: comsolid
--

COMMENT ON TABLE instituicao IS 'Institui��o de origem da pessoa. Escola, Comunidade.';


--
-- TOC entry 2104 (class 0 OID 0)
-- Dependencies: 151
-- Name: COLUMN instituicao.apelido_instituicao; Type: COMMENT; Schema: public; Owner: comsolid
--

COMMENT ON COLUMN instituicao.apelido_instituicao IS 'EEMF Adauto Bezerra.
Essa informa��o pode estar no CRACH�.';


--
-- TOC entry 152 (class 1259 OID 23525695)
-- Dependencies: 3 151
-- Name: instituicao_id_instituicao_seq; Type: SEQUENCE; Schema: public; Owner: comsolid
--

CREATE SEQUENCE instituicao_id_instituicao_seq
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.instituicao_id_instituicao_seq OWNER TO comsolid;

--
-- TOC entry 2105 (class 0 OID 0)
-- Dependencies: 152
-- Name: instituicao_id_instituicao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: comsolid
--

ALTER SEQUENCE instituicao_id_instituicao_seq OWNED BY instituicao.id_instituicao;


--
-- TOC entry 2106 (class 0 OID 0)
-- Dependencies: 152
-- Name: instituicao_id_instituicao_seq; Type: SEQUENCE SET; Schema: public; Owner: comsolid
--

SELECT pg_catalog.setval('instituicao_id_instituicao_seq', 205, true);


--
-- TOC entry 153 (class 1259 OID 23525697)
-- Dependencies: 3
-- Name: mensagem_email; Type: TABLE; Schema: public; Owner: comsolid; Tablespace: 
--

CREATE TABLE mensagem_email (
    id_encontro integer NOT NULL,
    id_tipo_mensagem_email integer NOT NULL,
    mensagem text NOT NULL,
    assunto character varying(200) NOT NULL,
    link character varying(70)
);


ALTER TABLE public.mensagem_email OWNER TO comsolid;

--
-- TOC entry 154 (class 1259 OID 23525703)
-- Dependencies: 3
-- Name: municipio; Type: TABLE; Schema: public; Owner: comsolid; Tablespace: 
--

CREATE TABLE municipio (
    id_municipio integer NOT NULL,
    nome_municipio character varying(40) NOT NULL,
    id_estado integer NOT NULL
);


ALTER TABLE public.municipio OWNER TO comsolid;

--
-- TOC entry 155 (class 1259 OID 23525706)
-- Dependencies: 154 3
-- Name: municipio_id_municipio_seq; Type: SEQUENCE; Schema: public; Owner: comsolid
--

CREATE SEQUENCE municipio_id_municipio_seq
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.municipio_id_municipio_seq OWNER TO comsolid;

--
-- TOC entry 2107 (class 0 OID 0)
-- Dependencies: 155
-- Name: municipio_id_municipio_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: comsolid
--

ALTER SEQUENCE municipio_id_municipio_seq OWNED BY municipio.id_municipio;


--
-- TOC entry 2108 (class 0 OID 0)
-- Dependencies: 155
-- Name: municipio_id_municipio_seq; Type: SEQUENCE SET; Schema: public; Owner: comsolid
--

SELECT pg_catalog.setval('municipio_id_municipio_seq', 182, true);


--
-- TOC entry 156 (class 1259 OID 23525708)
-- Dependencies: 1921 1922 1923 1924 1925 1926 3
-- Name: pessoa; Type: TABLE; Schema: public; Owner: comsolid; Tablespace: 
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
    email_enviado boolean DEFAULT false NOT NULL
);


ALTER TABLE public.pessoa OWNER TO comsolid;

--
-- TOC entry 2109 (class 0 OID 0)
-- Dependencies: 156
-- Name: COLUMN pessoa.nome; Type: COMMENT; Schema: public; Owner: comsolid
--

COMMENT ON COLUMN pessoa.nome IS 'Nome completo e em letra Mai�scula';


--
-- TOC entry 2110 (class 0 OID 0)
-- Dependencies: 156
-- Name: COLUMN pessoa.email; Type: COMMENT; Schema: public; Owner: comsolid
--

COMMENT ON COLUMN pessoa.email IS 'email em letra min�scula';


--
-- TOC entry 2111 (class 0 OID 0)
-- Dependencies: 156
-- Name: COLUMN pessoa.twitter; Type: COMMENT; Schema: public; Owner: comsolid
--

COMMENT ON COLUMN pessoa.twitter IS 'Iniciando com @';


--
-- TOC entry 2112 (class 0 OID 0)
-- Dependencies: 156
-- Name: COLUMN pessoa.endereco_internet; Type: COMMENT; Schema: public; Owner: comsolid
--

COMMENT ON COLUMN pessoa.endereco_internet IS 'Um endere�o come�ando com http:// indicando onde est�o as informa��es da pessoa.
Pode ser um blog, p�gina do facebook, site...';


--
-- TOC entry 2113 (class 0 OID 0)
-- Dependencies: 156
-- Name: COLUMN pessoa.senha; Type: COMMENT; Schema: public; Owner: comsolid
--

COMMENT ON COLUMN pessoa.senha IS 'Senha do usu�rio usando criptografia md5 do comsolid.
Valor padr�o vai ser o pr�prio nome do usu�rio.';


--
-- TOC entry 2114 (class 0 OID 0)
-- Dependencies: 156
-- Name: COLUMN pessoa.email_enviado; Type: COMMENT; Schema: public; Owner: comsolid
--

COMMENT ON COLUMN pessoa.email_enviado IS 'Indica se o sistema conseguiu conectar a um servidor de email e validar o email.';


--
-- TOC entry 157 (class 1259 OID 23525717)
-- Dependencies: 3
-- Name: pessoa_arquivo; Type: TABLE; Schema: public; Owner: comsolid; Tablespace: 
--

CREATE TABLE pessoa_arquivo (
    id_pessoa integer NOT NULL,
    foto oid NOT NULL
);


ALTER TABLE public.pessoa_arquivo OWNER TO comsolid;

--
-- TOC entry 158 (class 1259 OID 23525720)
-- Dependencies: 3 156
-- Name: pessoa_id_pessoa_seq; Type: SEQUENCE; Schema: public; Owner: comsolid
--

CREATE SEQUENCE pessoa_id_pessoa_seq
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pessoa_id_pessoa_seq OWNER TO comsolid;

--
-- TOC entry 2115 (class 0 OID 0)
-- Dependencies: 158
-- Name: pessoa_id_pessoa_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: comsolid
--

ALTER SEQUENCE pessoa_id_pessoa_seq OWNED BY pessoa.id_pessoa;


--
-- TOC entry 2116 (class 0 OID 0)
-- Dependencies: 158
-- Name: pessoa_id_pessoa_seq; Type: SEQUENCE SET; Schema: public; Owner: comsolid
--

SELECT pg_catalog.setval('pessoa_id_pessoa_seq', 3609, true);


--
-- TOC entry 159 (class 1259 OID 23525722)
-- Dependencies: 3
-- Name: sala; Type: TABLE; Schema: public; Owner: comsolid; Tablespace: 
--

CREATE TABLE sala (
    id_sala integer NOT NULL,
    nome_sala character varying(20) NOT NULL
);


ALTER TABLE public.sala OWNER TO comsolid;

--
-- TOC entry 160 (class 1259 OID 23525725)
-- Dependencies: 159 3
-- Name: sala_id_sala_seq; Type: SEQUENCE; Schema: public; Owner: comsolid
--

CREATE SEQUENCE sala_id_sala_seq
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sala_id_sala_seq OWNER TO comsolid;

--
-- TOC entry 2117 (class 0 OID 0)
-- Dependencies: 160
-- Name: sala_id_sala_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: comsolid
--

ALTER SEQUENCE sala_id_sala_seq OWNED BY sala.id_sala;


--
-- TOC entry 2118 (class 0 OID 0)
-- Dependencies: 160
-- Name: sala_id_sala_seq; Type: SEQUENCE SET; Schema: public; Owner: comsolid
--

SELECT pg_catalog.setval('sala_id_sala_seq', 10, true);


--
-- TOC entry 161 (class 1259 OID 23525727)
-- Dependencies: 3
-- Name: sexo; Type: TABLE; Schema: public; Owner: comsolid; Tablespace: 
--

CREATE TABLE sexo (
    id_sexo integer NOT NULL,
    descricao_sexo character varying(15) NOT NULL,
    codigo_sexo character(1) NOT NULL
);


ALTER TABLE public.sexo OWNER TO comsolid;

--
-- TOC entry 162 (class 1259 OID 23525730)
-- Dependencies: 3
-- Name: tipo_evento; Type: TABLE; Schema: public; Owner: comsolid; Tablespace: 
--

CREATE TABLE tipo_evento (
    id_tipo_evento integer NOT NULL,
    nome_tipo_evento character varying(20) NOT NULL
);


ALTER TABLE public.tipo_evento OWNER TO comsolid;

--
-- TOC entry 2119 (class 0 OID 0)
-- Dependencies: 162
-- Name: TABLE tipo_evento; Type: COMMENT; Schema: public; Owner: comsolid
--

COMMENT ON TABLE tipo_evento IS 'Tipos de Eventos: Palestra, Minicurso, Oficina.';


--
-- TOC entry 163 (class 1259 OID 23525733)
-- Dependencies: 3 162
-- Name: tipo_evento_id_tipo_evento_seq; Type: SEQUENCE; Schema: public; Owner: comsolid
--

CREATE SEQUENCE tipo_evento_id_tipo_evento_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tipo_evento_id_tipo_evento_seq OWNER TO comsolid;

--
-- TOC entry 2120 (class 0 OID 0)
-- Dependencies: 163
-- Name: tipo_evento_id_tipo_evento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: comsolid
--

ALTER SEQUENCE tipo_evento_id_tipo_evento_seq OWNED BY tipo_evento.id_tipo_evento;


--
-- TOC entry 2121 (class 0 OID 0)
-- Dependencies: 163
-- Name: tipo_evento_id_tipo_evento_seq; Type: SEQUENCE SET; Schema: public; Owner: comsolid
--

SELECT pg_catalog.setval('tipo_evento_id_tipo_evento_seq', 1, false);


--
-- TOC entry 164 (class 1259 OID 23525735)
-- Dependencies: 3
-- Name: tipo_mensagem_email; Type: TABLE; Schema: public; Owner: comsolid; Tablespace: 
--

CREATE TABLE tipo_mensagem_email (
    id_tipo_mensagem_email integer NOT NULL,
    descricao_tipo_mensagem_email character varying(30) NOT NULL
);


ALTER TABLE public.tipo_mensagem_email OWNER TO comsolid;

--
-- TOC entry 165 (class 1259 OID 23525738)
-- Dependencies: 3
-- Name: tipo_usuario; Type: TABLE; Schema: public; Owner: comsolid; Tablespace: 
--

CREATE TABLE tipo_usuario (
    id_tipo_usuario integer NOT NULL,
    descricao_tipo_usuario character varying(15) NOT NULL
);


ALTER TABLE public.tipo_usuario OWNER TO comsolid;

SET search_path = armario, pg_catalog;

--
-- TOC entry 1931 (class 2604 OID 32817078)
-- Dependencies: 169 170 170
-- Name: id_armario; Type: DEFAULT; Schema: armario; Owner: comsolid
--

ALTER TABLE ONLY armario ALTER COLUMN id_armario SET DEFAULT nextval('armario_id_armario_seq'::regclass);


--
-- TOC entry 1930 (class 2604 OID 32817063)
-- Dependencies: 166 167 167
-- Name: id_posicao_armario; Type: DEFAULT; Schema: armario; Owner: comsolid
--

ALTER TABLE ONLY posicao_armario ALTER COLUMN id_posicao_armario SET DEFAULT nextval('posicao_armario_id_posicao_armario_seq'::regclass);


SET search_path = public, pg_catalog;

--
-- TOC entry 1895 (class 2604 OID 23525741)
-- Dependencies: 131 129
-- Name: id_caravana; Type: DEFAULT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY caravana ALTER COLUMN id_caravana SET DEFAULT nextval('caravana_id_caravana_seq'::regclass);


--
-- TOC entry 1897 (class 2604 OID 23525742)
-- Dependencies: 136 133
-- Name: id_encontro; Type: DEFAULT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY encontro ALTER COLUMN id_encontro SET DEFAULT nextval('encontro_id_encontro_seq'::regclass);


--
-- TOC entry 1899 (class 2604 OID 23525743)
-- Dependencies: 135 134
-- Name: id_encontro_horario; Type: DEFAULT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY encontro_horario ALTER COLUMN id_encontro_horario SET DEFAULT nextval('encontro_horario_id_encontro_horario_seq'::regclass);


--
-- TOC entry 1905 (class 2604 OID 23525744)
-- Dependencies: 139 138
-- Name: id_estado; Type: DEFAULT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY estado ALTER COLUMN id_estado SET DEFAULT nextval('estado_id_estado_seq'::regclass);


--
-- TOC entry 1906 (class 2604 OID 23525745)
-- Dependencies: 144 140
-- Name: id_evento; Type: DEFAULT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY evento ALTER COLUMN id_evento SET DEFAULT nextval('evento_id_evento_seq'::regclass);


--
-- TOC entry 1915 (class 2604 OID 23525746)
-- Dependencies: 148 147
-- Name: evento; Type: DEFAULT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY evento_realizacao ALTER COLUMN evento SET DEFAULT nextval('evento_realizacao_evento_seq'::regclass);


--
-- TOC entry 1917 (class 2604 OID 23525747)
-- Dependencies: 150 149
-- Name: evento_realizacao_multipla; Type: DEFAULT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY evento_realizacao_multipla ALTER COLUMN evento_realizacao_multipla SET DEFAULT nextval('evento_realizacao_multipla_evento_realizacao_multipla_seq'::regclass);


--
-- TOC entry 1919 (class 2604 OID 23525748)
-- Dependencies: 152 151
-- Name: id_instituicao; Type: DEFAULT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY instituicao ALTER COLUMN id_instituicao SET DEFAULT nextval('instituicao_id_instituicao_seq'::regclass);


--
-- TOC entry 1920 (class 2604 OID 23525749)
-- Dependencies: 155 154
-- Name: id_municipio; Type: DEFAULT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY municipio ALTER COLUMN id_municipio SET DEFAULT nextval('municipio_id_municipio_seq'::regclass);


--
-- TOC entry 1927 (class 2604 OID 23525750)
-- Dependencies: 158 156
-- Name: id_pessoa; Type: DEFAULT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY pessoa ALTER COLUMN id_pessoa SET DEFAULT nextval('pessoa_id_pessoa_seq'::regclass);


--
-- TOC entry 1928 (class 2604 OID 23525751)
-- Dependencies: 160 159
-- Name: id_sala; Type: DEFAULT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY sala ALTER COLUMN id_sala SET DEFAULT nextval('sala_id_sala_seq'::regclass);


--
-- TOC entry 1929 (class 2604 OID 23525752)
-- Dependencies: 163 162
-- Name: id_tipo_evento; Type: DEFAULT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY tipo_evento ALTER COLUMN id_tipo_evento SET DEFAULT nextval('tipo_evento_id_tipo_evento_seq'::regclass);


SET search_path = armario, pg_catalog;

--
-- TOC entry 2073 (class 0 OID 33214020)
-- Dependencies: 173
-- Data for Name: administrador; Type: TABLE DATA; Schema: armario; Owner: comsolid
--

COPY administrador (pessoa) FROM stdin;
304
296
\.


--
-- TOC entry 2072 (class 0 OID 32817087)
-- Dependencies: 172
-- Data for Name: aluno; Type: TABLE DATA; Schema: armario; Owner: comsolid
--

COPY aluno (matricula, id_pessoa, senha_tmp, nome, email_enviado, curso) FROM stdin;
201027050050	3390	\N	DENISE VITORIANO SILVA	t	Ciência da Computação
200927050059	3391	\N	DENYS ABNER SANTOS BEZERRA	t	Ciência da Computação
20112045050073	3393	\N	DIEGO DO NASCIMENTO BRITO	t	Ciência da Computação
201117050149	3394	\N	DIEGO GUILHERME DE SOUZA MORAES	t	Ciência da Computação
200917050021	3395	\N	DIÊGO LIMA CARVALHO GONÇALVES	t	Ciência da Computação
201027050158	3396	\N	EDSON ALVES MELO	t	Ciência da Computação
201117050041	3401	\N	ELTON NOBRE MORAIS	t	Ciência da Computação
201017050210	3403	\N	EMANUELLA GOMES RIBEIRO	t	Ciência da Computação
200927050067	3404	\N	ÉRICA MARIA GUEDES RODRIGUES	t	Ciência da Computação
201117050238	3408	\N	FABRICIO BARROSO DE SOUSA	t	Ciência da Computação
200917050137	3415	\N	FRANCISCO DANIEL BEZERRA DE CARVALHO	t	Ciência da Computação
20112045050286	3418	\N	FRANCISCO LEANDRO HENRIQUE MOREIRA	t	Ciência da Computação
201027050069	3426	\N	HELIONEIDA MARIA VIANA	t	Ciência da Computação
201117050246	3429	\N	IAGO BARBOSA DE CARVALHO LINS	t	Ciência da Computação
201117050050	3430	\N	ISAAC THIAGO OLIVEIRA CAVALCANTE	t	Ciência da Computação
201117050068	3431	\N	ISRAEL SOARES DE OLIVEIRA	t	Ciência da Computação
20112045050111	3432	\N	ITALO MESQUITA VIEIRA	t	Ciência da Computação
201117050254	3433	\N	IVNA SILVESTRE MONTEFUSCO	t	Ciência da Computação
200927050091	3435	\N	JARDEL DAS CHAGAS RODRIGUES	t	Ciência da Computação
201117050262	3436	\N	JARDEL MAX SILVEIRA PINTO	t	Ciência da Computação
200927050105	3437	\N	JÉSSICA GOMES PEREIRA	t	Ciência da Computação
201117050084	3439	\N	JHON MAYCON SILVA PREVITERA	t	Ciência da Computação
201017050040	3440	\N	JOÃO GOMES DA SILVA NETO	t	Ciência da Computação
20112045050120	3441	\N	JOÃO GUILHERME COLOMBINI SILVA	t	Ciência da Computação
200927050113	3444	\N	JOAO OLEGARIO PINHEIRO NETO	t	Ciência da Computação
20112045050138	3447	\N	JOHN DHOUGLAS LIRA FREITAS	t	Ciência da Computação
200917050064	3448	\N	JONAS RODRIGUES VIEIRA DOS SANTOS	t	Ciência da Computação
201027050301	3449	\N	JORGE FERNANDO RAMOS BEZERRA	t	Ciência da Computação
200927050130	3450	\N	JOSE BARROSO AGUIAR NETO	t	Ciência da Computação
200917050170	3452	\N	JOSÉ MACEDO DE ARAÚJO FILHO	t	Ciência da Computação
201117050190	3454	\N	JOSÉ PAULINO DE SOUSA NETTO	t	Ciência da Computação
200927050148	3456	\N	JOSERLEY PAULO TEOFILO DA COSTA	t	Ciência da Computação
201017050236	3457	\N	JOVANE AMARO PIRES	t	Ciência da Computação
200927050156	3458	\N	JOYCE SARAIVA LIMA	t	Ciência da Computação
200927050164	3460	\N	KILDARY JUCÁ CAJAZEIRAS	t	Ciência da Computação
200927050172	3462	\N	KLEBER DE MELO MESQUITA	t	Ciência da Computação
201017050066	3463	\N	KLEVERLAND SOUSA FORMIGA	t	Ciência da Computação
201027050204	3465	\N	LEANDRO MENEZES DE SOUSA	t	Ciência da Computação
201117050130	3466	\N	LEEWAN ALVES DE MENESES	t	Ciência da Computação
200927050199	3468	\N	LEVI VIANA DE ANDRADE	t	Ciência da Computação
201027050271	3471	\N	LÍVIO SIQUEIRA LIMA	t	Ciência da Computação
201017050112	3473	\N	LUANA DE OLIVEIRA CORREIA	t	Ciência da Computação
201017050074	3474	\N	LUANA GOMES DE ANDRADE	t	Ciência da Computação
20112045050146	3477	\N	LUCIANA SA DE CARVALHO	t	Ciência da Computação
20112045050154	3478	\N	LUIS CLAUDIO COSTA CAETANO	t	Ciência da Computação
201017050139	3479	\N	LUIS RAFAEL SOUSA FERNANDES	t	Ciência da Computação
200927050202	3480	\N	MAIARA MARIA PEREIRA BASTOS SOUSA	t	Ciência da Computação
201027050239	3488	\N	MATEUS PEREIRA DE SOUSA	t	Ciência da Computação
201027050107	3545	\N	SYNARA DE FÁTIMA BEZERRA DE LIMA	t	Ciência da Computação
201027050263	2635	\N	TIAGO CORDEIRO ARAGÃO	t	Ciência da Computação
200917050234	299	\N	SHARA SHAMI ARAÚJO ALVES	t	Ciência da Computação
201017050260	3552	\N	VICTOR DE OLIVEIRA MATOS	t	Ciência da Computação
201017050155	3556	\N	WEMILY BARROS NASCIMENTO	t	Ciência da Computação
20112045050243	3560	\N	YCARO BRENNO CAVALCANTE RAMALHO	t	Ciência da Computação
200917050269	689	\N	ADONIAS CAETANO DE OLIVEIRA	t	Ciência da Computação
201027050018	1086	\N	ALCILIANO DA SILVA LIMA	t	Ciência da Computação
201017050090	1152	\N	ALDISIO GONÇALVES MEDEIROS	t	Ciência da Computação
201117050181	817	\N	AMANDA AZEVEDO DE CASTRO FROTA ARAGAO	t	Ciência da Computação
20112045050308	1018	\N	ANTONIO RENAN ROGERIO PAZ	t	Ciência da Computação
201027050123	624	\N	ARLESSON LIMA DOS SANTOS	t	Ciência da Computação
201017050171	672	\N	ÁTILA CAMURÇA ALVES	t	Ciência da Computação
20112045050030	1099	\N	ATILA SOUSA E SILVA	t	Ciência da Computação
20112045050235	767	\N	RIMARIA DE OLIVEIRA CASTELO BRANCO	t	Ciência da Computação
201117050297	1096	\N	SAMUHEL MARQUES REIS	t	Ciência da Computação
201017050198	929	\N	THEOFILO DE SOUSA SILVEIRA	t	Ciência da Computação
200927050288	1109	\N	WAGNER ALCIDES FERNANDES CHAVES	t	Ciência da Computação
20112045050251	934	\N	WAGNER DOUGLAS DO NASCIMENTO E SILVA	t	Ciência da Computação
200927050296	312	\N	WALLISSON ISAAC FREITAS DE VASCONCELOS	t	Ciência da Computação
200917050153	697	\N	WILLIAM VIEIRA BASTOS	t	Ciência da Computação
201017050309	1602	\N	VALRENICE NASCIMENTO DA COSTA	t	Ciência da Computação
201027050131	3374	\N	BRENDO DE SOUSA ALVES	t	Ciência da Computação
200917050030	3375	\N	CARLOS ADAILTON RODRIGUES	t	Ciência da Computação
201117050033	3378	\N	CLAYTON BEZERRA PRIMO	t	Ciência da Computação
20112045050294	3381	\N	DANIEL ALVES PAIVA	t	Ciência da Computação
201117050157	3384	\N	DANIEL JEAN RODRIGUES VASCONCELOS	t	Ciência da Computação
200927050040	3386	\N	DANIELE MIGUEL DA SILVA	t	Ciência da Computação
201027050140	3387	\N	DARIO ABNOR SOARES DOS ANJOS	t	Ciência da Computação
200927050210	3489	\N	MATHEUS ARLESON SALES XAVIER	t	Ciência da Computação
20112045050162	3491	\N	MATHEUS TAVEIRA SOARES	t	Ciência da Computação
20112045050197	3496	\N	MERCIA OLIVEIRA DE SOUSA	t	Ciência da Computação
201017050287	3497	\N	MOISÉS LOURENÇO BANDEIRA	t	Ciência da Computação
200917050129	3500	\N	NEYLLANY ANDRADE FERNANDES	t	Ciência da Computação
201117050289	3502	\N	NYKOLAS MAYKO MAIA BARBOSA	t	Ciência da Computação
20112045050219	3503	\N	PAULO ANDERSON FERREIRA NOBRE	t	Ciência da Computação
201027050212	3504	\N	PAULO PEREIRA GUALTER	t	Ciência da Computação
200927050237	3508	\N	PEDRO ITALO BONFIM LACERDA	t	Ciência da Computação
200917050013	3511	\N	PÉRICLES HENRIQUE GOMES DE OLIVEIRA	t	Ciência da Computação
200917050242	3512	\N	PHYLLIPE DO CARMO FELIX	t	Ciência da Computação
20112045050278	3514	\N	PRISCILA FEITOSA DE FRANÇA	t	Ciência da Computação
201027050247	3516	\N	RAFAEL BEZERRA DE OLIVEIRA	t	Ciência da Computação
201017050015	3517	\N	RAFAEL SILVA DOMINGOS	t	Ciência da Computação
201017050279	3518	\N	RAFAEL SOARES RODRIGUES	t	Ciência da Computação
201027050255	3519	\N	RAFAEL VIEIRA MOURA	t	Ciência da Computação
201117050092	3522	\N	RALPH LEAL HECK	t	Ciência da Computação
200927050253	3523	\N	RAPHAEL ARAÚJO VASCONCELOS	t	Ciência da Computação
200927050180	2569	\N	LEONILDO FERREIRA DE ABREU	t	Ciência da Computação
20112042550130	443	\N	LUIZ ROBERTO DE ALMEIDA FILHO	t	Técnico em Redes de Computadores
20112042550210	1079	\N	MARIA IZABELA NOGUEIRA SALES	t	Técnico em Redes de Computadores
201112550011	2630	\N	VALDECI ALMEIDA FILHO	t	Técnico em Redes de Computadores
20112045050049	1416	\N	BRUNO FERREIRA ALENCAR	t	Ciência da Computação
200927050024	297	\N	CAMILA LINHARES	t	Ciência da Computação
20112045050057	812	\N	DAVI FONSECA SANTOS	t	Ciência da Computação
20112045050065	1167	\N	DIEGO FARIAS DE OLIVEIRA	t	Ciência da Computação
200927050075	588	\N	ERYKA FREIRES DA SILVA	t	Ciência da Computação
201027050220	626	\N	FAUSTO SAMPAIO	t	Ciência da Computação
20112045050081	523	\N	FELIPE MARCEL DE QUEIROZ SANTOS	t	Ciência da Computação
20112045050090	1095	\N	FLAVIANA CASTELO BRANCO CARVALHO DE SOUSA	t	Ciência da Computação
200917050080	590	\N	FRANCISCO ANDERSON FARIAS MACIEL	t	Ciência da Computação
20112045050260	2245	\N	GILLIARD FERREIRA DA SILVA	t	Ciência da Computação
20112045050103	417	\N	IENDE REBECA CARVALHO DA SILVA	t	Ciência da Computação
20112045050227	3525	\N	REGINALDO MOTA DE SOUSA	t	Ciência da Computação
200917050048	3527	\N	REGIO FLAVIO DO SANTOS SILVA FILHO	t	Ciência da Computação
201117050114	3528	\N	RENAN ALMEIDA DA SILVA	t	Ciência da Computação
201017050082	3529	\N	RICARDO VALENTIM DE LIMA	t	Ciência da Computação
200917050161	3537	\N	ROMULO LOPES FRUTUOSO	t	Ciência da Computação
200917050218	307	\N	SAMIR COUTINHO COSTA	t	Ciência da Computação
201117050106	3540	\N	SAMUEL KARLMARTINS PINHEIRO MAGALHAES	t	Ciência da Computação
200927050261	3541	\N	SAULO ANDERSON FREITAS DE OLIVEIRA	t	Ciência da Computação
200927050270	3543	\N	STÉFERSON SOUZA DE OLIVEIRA	t	Ciência da Computação
201117050076	1554	\N	JEFTE SANTOS NUNES	t	Ciência da Computação
200927050121	444	\N	JOÃO PEDRO MARTINS SALES	t	Ciência da Computação
201027050026	3567	\N	ANA KATARINA TOMAZ HACHEM	f	Ciência da Computação
200917050145	3580	\N	JOÃO FELIPE SAMPAIO XAVIER DA SILVA	f	Ciência da Computação
200917050277	3582	\N	JONAS FEITOSA CAVALCANTE	f	Ciência da Computação
200917050099	3583	\N	JOSÉ TUNAY ARAÚJO	f	Ciência da Computação
200917050285	3587	\N	REGINALDO FREITAS SANTOS FILHO	f	Ciência da Computação
201027050174	632	\N	JULIANA LIMA GARÇA	t	Ciência da Computação
200917050293	325	\N	JULIANA PEIXOTO SILVA	t	Ciência da Computação
20112045050316	1097	\N	KAIO HEIDE SAMPAIO NOBREGA	t	Ciência da Computação
201027050182	323	\N	KAUÊ FRANCISCO MARCELINO MENEZES	t	Ciência da Computação
201027050190	1917	\N	LEANDRO BEZERRA MARINHO	t	Ciência da Computação
201117050122	837	\N	LUCAS SILVA DE SOUSA	t	Ciência da Computação
201017050104	1033	\N	LUÉLER PAIVA ELIAS	t	Ciência da Computação
201017050295	1052	\N	MAGNO BARROSO DE ALBUQUERQUE	t	Ciência da Computação
201017050120	694	\N	MAIKON IGOR DA SILVA SOARES	t	Ciência da Computação
201017050252	398	\N	MARCOS PAULO LIMA ALMEIDA	t	Ciência da Computação
201017050058	424	\N	MAXSUELL LOPES DE SOUSA BESSA	t	Ciência da Computação
201117050270	625	\N	MURILLO BARATA RODRIGUES	t	Ciência da Computação
20112045050200	1131	\N	NARA THWANNY ANASTACIO CARVALHO DE OLIVEIRA	t	Ciência da Computação
200922310621	1174	\N	FRANCISCO DARLILDO SOUZA LIMA	f	Técnico em Informática
20112042310040	1191	\N	BRUNO BARBOSA AMARAL	t	Técnico em Informática
201012310213	315	\N	CARLOS ANDERSON FERREIRA SALES	t	Técnico em Informática
201112310088	639	\N	CARLOS HENRIQUE NOGUEIRA DE CARVALHO	t	Técnico em Informática
20112042310058	333	\N	CARLOS THAYNAN LIMA DE ANDRADE	t	Técnico em Informática
201112310096	401	\N	CRISTINA ALMEIDA DE BRITO	t	Técnico em Informática
20112042310066	1381	\N	DANILO DE OLIVEIRA SOUSA	t	Técnico em Informática
20112042310074	334	\N	DAURYELLEN MENDES LIMA	t	Técnico em Informática
201112310118	1059	\N	DEYLON SILVA COSTA	t	Técnico em Informática
20112042310295	646	\N	EMANUEL ROSEIRA GUEDES	t	Técnico em Informática
20112042310104	996	\N	EMMILY ALVES DE ALMEIDA	t	Técnico em Informática
200822310190	616	\N	EVERTON BARBOSA MELO	t	Técnico em Informática
201022310216	673	\N	FERNANDA STHÉFFANY CARDOSO SOARES	t	Técnico em Informática
20112042310120	1133	\N	FLAVIANA DA SILVA NOGUEIRA LUCAS	t	Técnico em Informática
20112042310139	993	\N	GABRIEL BEZERRA SANTOS	t	Técnico em Informática
201012310175	1318	\N	GABRIEL DE SOUSA VENÂNCIO	t	Técnico em Informática
201112310134	809	\N	GIDEÃO SANTANA DE FRANÇA	t	Técnico em Informática
200922310206	1897	\N	GILMARA LIMA PINHEIRO	t	Técnico em Informática
201112310142	1710	\N	GINALDO ARAÚJO DA COSTA JÚNIOR	t	Técnico em Informática
20112042310147	1040	\N	GREGORY CAMPOS BEVILAQUA	t	Técnico em Informática
200922310222	417	\N	IENDE REBECA CARVALHO DA SILVA	t	Técnico em Informática
201022310224	1023	\N	ISLAS GIRÃO GARCIA	t	Técnico em Informática
201022310470	521	\N	JACKSON DENIS RODRIGUES DA COSTA	t	Técnico em Informática
20112042310279	782	\N	WILLIANY GOMES NOBRE	t	Técnico em Informática
201022310399	640	\N	YARA BERNARDO CABRAL	t	Técnico em Informática
201112310347	674	\N	YOHANA MARIA SILVA DE ALMEIDA	t	Técnico em Informática
201112310193	1792	\N	JULIA SILVA DOS SANTOS	t	Técnico em Informática
201022310062	1742	\N	ADRIANA MARA DE ALMEIDA DE SOUZA	t	Técnico em Informática
20112042310198	1707	\N	MADSON HENRIQUE DO NASCIMENTO RODRIGUES	t	Técnico em Informática
200912310050	3388	\N	DAVIANNE COELHO VALENTIM	t	Técnico em Informática
200922310095	3389	\N	DAVID NASCIMENTO DE ARAUJO	t	Técnico em Informática
201012310132	3394	\N	DIEGO GUILHERME DE SOUZA MORAES	t	Técnico em Informática
20112042310082	2162	\N	DJALMA DE SÁ RORIZ FILHO	t	Técnico em Informática
20112042310090	3397	\N	EDVANDRO VIEIRA DE ALBUQUERQUE	t	Técnico em Informática
200922310117	3399	\N	ELINE LIMA DE FREITAS	t	Técnico em Informática
201022310178	3400	\N	ELIZABETH DA PAZ SANTOS	t	Técnico em Informática
201012310485	3402	\N	EMANUEL AGUIAR FREITAS	t	Técnico em Informática
201012310264	3405	\N	EUDIJUNO SCARCELA DUARTE	t	Técnico em Informática
201022310194	3406	\N	FABIANA DE ALBUQUERQUE SIQUEIRA	t	Técnico em Informática
201022310208	3407	\N	FABIO SOUZA SANTOS	t	Técnico em Informática
201012310337	3409	\N	FABRICIO DE FREITAS ALVES	t	Técnico em Informática
20112042310112	3410	\N	FELIPE ALEXSANDER RODRIGUES CHAVES	t	Técnico em Informática
201022310038	3412	\N	FLAVIO CESA PEREIRA DA SILVA	t	Técnico em Informática
201112310126	3413	\N	FRANCISCO AMSTERDAN DUARTE DA SILVA	t	Técnico em Informática
201112310355	3416	\N	FRANCISCO FERNANDES DA COSTA NETO	t	Técnico em Informática
201012310094	3417	\N	FRANCISCO GUSTAVO CAVALCANTE BELO	t	Técnico em Informática
201012310043	3419	\N	GEORGE GLAIRTON GOMES TIMBÓ	t	Técnico em Informática
201112310150	3421	\N	GLAILSON MONTEIRO LEANDRO	t	Técnico em Informática
20112042310155	3424	\N	HALECKSON HENRICK CONSTANTINO CUNHA	t	Técnico em Informática
201012310507	3425	\N	HANNAH PRESTAH LEAL RABELO	t	Técnico em Informática
200922310214	3427	\N	HELTON ATILAS ALVES DA SILVA	t	Técnico em Informática
201112310169	3428	\N	HERBET SILVA CUNHA	t	Técnico em Informática
201022310364	2054	\N	ILANNA EMANUELLE MUNIZ SILVA	t	Técnico em Informática
201112310177	3434	\N	JAMILLE DE AQUINO ARAÚJO NASCIMENTO	t	Técnico em Informática
200922310249	3438	\N	JESSIMARA DE SENA ANDRADE	t	Técnico em Informática
201012310310	3442	\N	JOÃO HENRIQUE RODRIGUES DOS SANTOS	t	Técnico em Informática
20112042310163	3443	\N	JOÃO LUCAS DE FREITAS MATOS	t	Técnico em Informática
201012310248	3445	\N	JOELSON FERREIRA DA SILVA	t	Técnico em Informática
20112042310171	3446	\N	JOELSON FREITAS DE OLIVEIRA	t	Técnico em Informática
201022310259	3453	\N	JOSÉ NATANAEL DE SOUSA	t	Técnico em Informática
200922310281	3459	\N	JULIO CESAR OTAZO NUNES	t	Técnico em Informática
201012310019	3461	\N	KILVIA RIBEIRO MORAIS	t	Técnico em Informática
201112310207	3464	\N	LAIS EVELYN BERNARDINO ALVES	t	Técnico em Informática
201012310108	3465	\N	LEANDRO MENEZES DE SOUSA	t	Técnico em Informática
201012310205	3467	\N	LEONARDO BARBOSA DE SOUZA	t	Técnico em Informática
201112310215	3469	\N	LILIAN JACAÚNA LOPES	t	Técnico em Informática
200922310290	3470	\N	LIVIA FIGUEIREDO SOARES	t	Técnico em Informática
201012310302	3472	\N	LUAN SIDNEY NASCIMENTO DOS SANTOS	t	Técnico em Informática
200912310300	3474	\N	LUANA GOMES DE ANDRADE	t	Técnico em Informática
201112310223	3475	\N	LUCAS ÁBNER LIMA REBOUÇAS	t	Técnico em Informática
201012310540	3481	\N	MANOEL NAZARENO E SILVA	t	Técnico em Informática
201022310275	3482	\N	MARA JÉSSYCA LIMA BARBOSA	t	Técnico em Informática
201012310418	3484	\N	MARIA ANGELINA FERREIRA PONTES	t	Técnico em Informática
201012310140	3486	\N	MARIA JULIANE DA SILVA CHAGAS	t	Técnico em Informática
201022310135	634	\N	CAROLINE SANDY REGO DE OLIVEIRA	t	Técnico em Informática
201012310396	3346	\N	ADRIANA OLIVEIRA DE LIMA	t	Técnico em Informática
20112042310015	3349	\N	ALEXSANDRO DA SILVA FREITAS	t	Técnico em Informática
201012310124	3356	\N	ANA BÁRBARA CRUZ SILVA	t	Técnico em Informática
200922310028	3358	\N	ANA LARISSA XIMENES BATISTA	t	Técnico em Informática
201022310097	3363	\N	ANDRESSA MAILANNY SOUZA DA SILVA	t	Técnico em Informática
200822310220	1044	\N	JEAN LUCK CARDOSO DA SILVEIRA	t	Técnico em Informática
201012310353	3364	\N	ANTONIA MARIANA OLIVEIRA LIMA	t	Técnico em Informática
200912310203	3366	\N	ANTONIA SIDIANE DE SOUSA GONDIM	t	Técnico em Informática
201112310061	3367	\N	ANTONIO DE LIMA FERREIRA	t	Técnico em Informática
201022310100	3369	\N	ANTONIO EVERTON RODRIGUES TORRES	t	Técnico em Informática
201022310119	3370	\N	ANTONIO JEFERSON PEREIRA BARRETO	t	Técnico em Informática
201012310116	3371	\N	ANTONIO LOPES DE OLIVEIRA JÚNIOR	t	Técnico em Informática
201112310070	3372	\N	ARLEN ITALO DUARTE DE VASCONCELOS	t	Técnico em Informática
200922310079	3379	\N	CLEILSON SOUSA MESQUITA	t	Técnico em Informática
201112310100	3380	\N	DALILA DE ALENCAR LIMA	t	Técnico em Informática
200922310087	3382	\N	DANIEL GOMES CARDOSO	t	Técnico em Informática
201012310159	3383	\N	DANIEL HENRIQUE DA COSTA	t	Técnico em Informática
201022310160	3385	\N	DANIELE DO NASCIMENTO MARQUES	t	Técnico em Informática
200912310335	1654	\N	THIAGO HENRIQUE SILVA DE OLIVEIRA	t	Técnico em Informática
201022310283	3490	\N	MATHEUS CARVALHO DE FREITAS	t	Técnico em Informática
201022310291	3494	\N	MAYARA NOGUEIRA BEZERRA	t	Técnico em Informática
200922310338	3495	\N	MAYARA SUÉLLY HONORATO DA SILVA	t	Técnico em Informática
201022310305	3499	\N	NANAXARA DE OLIVEIRA FERRER	t	Técnico em Informática
201022310020	3500	\N	NEYLLANY ANDRADE FERNANDES	t	Técnico em Informática
200912310327	3501	\N	NINFA IARA SABINO ROCHA DA SILVA	t	Técnico em Informática
20112042310210	3507	\N	PEDRO HENRIQUE GOMES DE OLIVEIRA	t	Técnico em Informática
200922310362	3509	\N	PEDRO VINNICIUS VIEIRA ALVES CABRAL	t	Técnico em Informática
201022310330	3510	\N	PEDRO VITOR DE SOUSA GUIMARÃES	t	Técnico em Informática
201012310230	3516	\N	RAFAEL BEZERRA DE OLIVEIRA	t	Técnico em Informática
200912310033	3520	\N	RAFAELA DE LIMA SILVA	t	Técnico em Informática
200922310567	3521	\N	RAIMUNDO PEREIRA CAVALCANTE NETO	t	Técnico em Informática
201012310531	3526	\N	REGINALDO PATRÍCIO DE SOUZA LIMA	t	Técnico em Informática
200922310370	3531	\N	ROBSON DOUGLAS BARBOZA GONÇALVES	t	Técnico em Informática
200922310400	3533	\N	ROBSON SILVA PORTELA	t	Técnico em Informática
201112310282	3535	\N	ROGÉRIO QUEIROZ LIMA	t	Técnico em Informática
200822310433	3536	\N	ROMULO DA SILVA GOMES	t	Técnico em Informática
200912310343	3538	\N	ROSEANNE PAIVA DA SILVA	t	Técnico em Informática
201022310372	3539	\N	SAMARA SOARES DE LIMA	t	Técnico em Informática
201012310256	758	\N	SARA PINHEIRO ZACARIAS	t	Técnico em Informática
201012310051	3544	\N	SUSANA MARA CATUNDA SOARES	t	Técnico em Informática
201112310290	1063	\N	TATIANE SOUZA DA SILVA	t	Técnico em Informática
201112310304	3547	\N	TIAGO ALEXANDRE FRANCISCO DE QUEIROZ	t	Técnico em Informática
20112042310244	3548	\N	TIAGO LINO VASCONCELOS	t	Técnico em Informática
200922310427	3550	\N	VALRENICE NASCIMENTO DA COSTA	t	Técnico em Informática
201022310445	3551	\N	VICTOR ALISSON MANGUEIRA CORREIA	t	Técnico em Informática
20112042310252	3553	\N	VICTOR LUIS VASCONCELOS DA SILVA	t	Técnico em Informática
20112042310325	3555	\N	WASHINGTON LUIZ DE OLIVEIRA	t	Técnico em Informática
20112042310287	3557	\N	WILLIAM CLINTON FREIRE SILVA	t	Técnico em Informática
200822310344	3558	\N	WILLIAM PEREIRA LIMA	t	Técnico em Informática
201112310320	3559	\N	WILQUEMBERTO NUNES PINTO	t	Técnico em Informática
201022310070	631	\N	ADRYSSON DE LIMA GARÇA	t	Técnico em Informática
201112310037	449	\N	ITALO DE QUEIROZ MOURA	t	Técnico em Informática
20112042310023	1021	\N	ANA BEATRIZ FREITAS LEITE	t	Técnico em Informática
201112310053	677	\N	ANDRE TEIXEIRA DE QUEIROZ	t	Técnico em Informática
20112042310031	1140	\N	ANTONIA CLEITIANE HOLANDA PINHEIRO	t	Técnico em Informática
200822310158	1438	\N	WELLINGTON DOS SANTOS CUNHA	f	Técnico em Informática
200912310394	444	\N	JOÃO PEDRO MARTINS SALES	t	Técnico em Informática
201012310493	3566	\N	ADNISE NATALIA MOURA DOS REIS	f	Técnico em Informática
201012310450	3569	\N	ANTONIO MARCIO RIBEIRO DA SILVA	f	Técnico em Informática
200822310379	3570	\N	ARILSON MENDONÇA DO NASCIMENTO	f	Técnico em Informática
201012310523	3571	\N	CATARINA GOMES DA SILVA	f	Técnico em Informática
20112042310317	3572	\N	DIEGO SOARES DA SILVA	f	Técnico em Informática
200922310141	3573	\N	FELIPE DANIEL DE SOUSA BARBOSA	f	Técnico em Informática
200922310168	3574	\N	FRANCISCO CLEDSON ARAÚJO OLIVEIRA	f	Técnico em Informática
200822310018	3575	\N	FRANCISCO DAVID ALVES DOS SANTOS	f	Técnico em Informática
200912310297	3576	\N	FRANCISCO JOAB MAGALHÃES ROCHA	f	Técnico em Informática
200912310130	3577	\N	FRANCISCO VENÍCIUS DA SILVA SANTOS	f	Técnico em Informática
200912310157	3578	\N	FRANCISCO WANDERSON VIEIRA FERREIRA	f	Técnico em Informática
201012310370	3579	\N	GÉFRIS DE LIMA PEREIRA	f	Técnico em Informática
201012310477	3581	\N	JOÃO RAPHAEL SILVA FARIAS	f	Técnico em Informática
201012310515	3584	\N	JULIANA BARROS DA SILVA	f	Técnico em Informática
200822310328	3585	\N	MICHELE XAVIER DA SILVA	f	Técnico em Informática
200822310077	3586	\N	PATRICIA PAULA FEITOSA COSTA	f	Técnico em Informática
201112310029	3588	\N	ROBERTA DE SOUZA LIMA	f	Técnico em Informática
200822310131	3589	\N	RÔMULO SAMINÊZ DO AMARAL	f	Técnico em Informática
200912310254	3590	\N	SAMUEL BRUNO HONORATO DA SILVA	f	Técnico em Informática
200822310476	3591	\N	VIVIANE DA COSTA PEREIRA	f	Técnico em Informática
200922310613	3592	\N	WILKIA MAYARA DA SILVA NEVES	f	Técnico em Informática
200922310257	408	\N	JOÃO VICTOR RIBEIRO GALVINO	t	Técnico em Informática
20112042310180	1414	\N	JONATA ALVES DE MATOS	t	Técnico em Informática
201112310185	973	\N	JONATAS HARBAS ALVES NUNES	t	Técnico em Informática
201012310183	1151	\N	JOSÉ XAVIER DE LIMA JÚNIOR	t	Técnico em Informática
201012310167	1002	\N	KLEGINALDO GALDINO PAZ	t	Técnico em Informática
201112310231	837	\N	LUCAS SILVA DE SOUSA	t	Técnico em Informática
201112310045	432	\N	LUIZ ALEX PEREIRA CAVALCANTE	t	Técnico em Informática
201012310361	1064	\N	MAGNA MARIA VITALIANO DA SILVA	t	Técnico em Informática
200822310387	425	\N	MANOEL ALEKSANDRE FILHO	t	Técnico em Informática
201012310345	824	\N	MARIA CAMILA ALCANTARA DA SILVA	t	Técnico em Informática
20112042310201	1134	\N	MARIA SIMONE PEREIRA CORDEIRO	t	Técnico em Informática
201112310240	467	\N	MAYARA FREITAS SOUSA	t	Técnico em Informática
200912310416	1022	\N	NACELIA ALVES DA SILVA	t	Técnico em Informática
20112042550156	3493	\N	MAYARA JESSICA CAVALCANTE FREITAS	t	Técnico em Redes de Computadores
20112042550229	3498	\N	MÔNICA GUIMARÃES RIBEIRO	t	Técnico em Redes de Computadores
201112550097	3505	\N	PAULO ROBSON SANTOS DA COSTA	t	Técnico em Redes de Computadores
20112042550237	3506	\N	PEDRO DA SILVA NETO	t	Técnico em Redes de Computadores
201112550070	3513	\N	PRISCILA CARDOSO DO NASCIMENTO	t	Técnico em Redes de Computadores
201112550062	3515	\N	RAFAEL ARAGAO OLIVEIRA	t	Técnico em Redes de Computadores
201112550143	2464	\N	GLAYDSON RAFAEL MACEDO	t	Técnico em Redes de Computadores
20112042550245	3524	\N	REBECA HANNA SANTOS DA SILVA	t	Técnico em Redes de Computadores
201112550046	3530	\N	RICARLOS PEREIRA DE MELO	t	Técnico em Redes de Computadores
20112042550253	3532	\N	ROBSON MACIEL DE ANDRADE	t	Técnico em Redes de Computadores
201112550038	3534	\N	RODRIGO MUNIZ DA SILVA	t	Técnico em Redes de Computadores
20112042550270	3542	\N	SIMEANE DA SILVA MONTEIRO	t	Técnico em Redes de Computadores
20112042550288	3546	\N	THAÍS BARROS SOUSA	t	Técnico em Redes de Computadores
201112550020	3549	\N	TIAGO NASCIMENTO SILVA	t	Técnico em Redes de Computadores
20112042550296	3554	\N	VLAUDSON DA CRUZ RAMALHO	t	Técnico em Redes de Computadores
200917050102	305	\N	EMANUEL SILVA DOMINGOS	t	Ciência da Computação
20112045050014	3347	\N	ADRIANO DE LIMA SANTOS	t	Ciência da Computação
201017050023	3344	\N	ADILIO MOURA COSTA	t	Ciência da Computação
201027050298	3350	\N	ALISSON DA SILVA OLIVEIRA	t	Ciência da Computação
201027050280	3348	\N	AISSE GONÇALVES NOGUEIRA	t	Ciência da Computação
200917050072	3352	\N	ALISSON SAMPAIO DE CARVALHO ALENCAR	t	Ciência da Computação
200927050016	3353	\N	AMANDA DIOGENES LUCAS	t	Ciência da Computação
201117050173	3354	\N	AMAURI AIRES BIZERRA FILHO	t	Ciência da Computação
201117050165	3355	\N	AMSRANON GUILHERME FELICIO GOMES DA SILVA	t	Ciência da Computação
20112045050022	3362	\N	ANDRE LUIS VIEIRA LEMOS	t	Ciência da Computação
201117050203	3372	\N	ARLEN ITALO DUARTE DE VASCONCELOS	t	Ciência da Computação
201117050017	3373	\N	AUGUSTO EMANUEL RIBEIRO SILVA	t	Ciência da Computação
20112042550300	1648	\N	RENATO LIMA BRAUNA	t	Técnico em Redes de Computadores
200822310085	3565	\N	VIVIANE FERREIRA ALMEIDA	f	Técnico em Informática
201112310258	1124	\N	NILTON SILVEIRA DOS SANTOS FILHO	t	Técnico em Informática
200922310354	762	\N	OLGA SILVA CASTRO	t	Técnico em Informática
20112042310309	1001	\N	PAULO HENRIQUE COUTO VIEIRA	t	Técnico em Informática
201112310266	1121	\N	RAFAEL RODRIGUES SOUSA	t	Técnico em Informática
20112042310228	1901	\N	RAUL OLIVEIRA SOUSA	t	Técnico em Informática
201022310410	1043	\N	RAYLSON SILVA DE LIMA	t	Técnico em Informática
201112310274	682	\N	RAYSA PINHEIRO LEMOS	t	Técnico em Informática
20112042310236	1026	\N	ROSANABERG PAIXÃO DE LIMA	t	Técnico em Informática
201012310590	1100	\N	ROSINEIDE SILVA DE ARAUJO	t	Técnico em Informática
201022310429	1200	\N	TIAGO DE MATOS LIMA	t	Técnico em Informática
201012310027	312	\N	WALLISSON ISAAC FREITAS DE VASCONCELOS	t	Técnico em Informática
20112042310260	1132	\N	WIHARLEY FEITOSA NASCIMENTO	t	Técnico em Informática
201022310488	697	\N	WILLIAM VIEIRA BASTOS	t	Técnico em Informática
20112042550024	3568	\N	ANTONIO JULIAM DA SILVA	f	Técnico em Redes de Computadores
20112042550113	1179	\N	KAILTON JONATHA VASCONCELOS RODRIGUES	t	Técnico em Redes de Computadores
20112042550202	1042	\N	KEMYSON CAMURÇA AMARANTE	t	Técnico em Redes de Computadores
20112042550121	1196	\N	LUCIANO JOSÉ DE ARAÚJO	t	Técnico em Redes de Computadores
201112550178	998	\N	CÍCERO JOSÉ SOUSA DA SILVA	t	Técnico em Redes de Computadores
20112042550040	980	\N	EUGENIO REGIS PINHEIRO DANTAS	t	Técnico em Redes de Computadores
20112042550067	1183	\N	FRANCISCO FERNANDO GONCALVES DA SILVA	t	Técnico em Redes de Computadores
20112042550199	734	\N	HELCIO WESLEY DE MENEZES LIMA	t	Técnico em Redes de Computadores
20112042550261	2179	\N	ROSIANE FERREIRA FREITAS	t	Técnico em Redes de Computadores
201112550216	1898	\N	ALEXSANDRO KAUÊ CARVALHO GALDINO	t	Técnico em Redes de Computadores
201112550160	3392	\N	DIEGO ALMEIDA CARNEIRO	t	Técnico em Redes de Computadores
20112042550032	3398	\N	ELIADE MOREIRA DA SILVA	t	Técnico em Redes de Computadores
20112042550059	3411	\N	FERNANDO DENES LUZ COSTA	t	Técnico em Redes de Computadores
201112550151	3414	\N	FRANCISCO ARI CÂNDIDO DE OLIVEIRA FILHO	t	Técnico em Redes de Computadores
20112042550075	3420	\N	GILDEILSON DOS SANTOS MENDONÇA	t	Técnico em Redes de Computadores
20112042550083	3422	\N	GUILHERME DA SILVA BRAGA	t	Técnico em Redes de Computadores
20112042550091	3423	\N	GUTEMBERG MAGALHAES SOUZA	t	Técnico em Redes de Computadores
201112550291	3451	\N	JOSE IVANILDO FIRMINO ALVES	t	Técnico em Redes de Computadores
20112042550105	3455	\N	JOSÉ WEVERTON RIBEIRO MONTEIRO	t	Técnico em Redes de Computadores
201112550283	3476	\N	LUCAS FIGUEIREDO SOARES	t	Técnico em Redes de Computadores
201112550127	3483	\N	MARCOS DA SILVA JUSTINO	t	Técnico em Redes de Computadores
20112042550148	3485	\N	MARIA ELANIA VIEIRA ASEVEDO	t	Técnico em Redes de Computadores
201112550119	3487	\N	MARIA VALDENE PEREIRA DE SOUZA	t	Técnico em Redes de Computadores
201112550194	3345	\N	ADRIANA MARIA SILVA COSTA	t	Técnico em Redes de Computadores
20112042550164	3351	\N	ALISSON DO NASCIMENTO LIMA	t	Técnico em Redes de Computadores
201112550232	3357	\N	ANA FLÁVIA CASTRO ALVES	t	Técnico em Redes de Computadores
20112042550172	3359	\N	ANDERSON DE SOUZA GABRIEL PEIXOTO	t	Técnico em Redes de Computadores
201112550240	3360	\N	ANDERSON PEREIRA GONÇALVES	t	Técnico em Redes de Computadores
20112042550016	3361	\N	ANDRE ALMEIDA E SILVA	t	Técnico em Redes de Computadores
201112550259	3365	\N	ANTONIA NEY DA SILVA PEREIRA	t	Técnico em Redes de Computadores
20112042550180	3368	\N	ANTONIO ELSON SANTANA DA COSTA	t	Técnico em Redes de Computadores
201112550186	3376	\N	CARLOS YURI DE AQUINO FAÇANHA	t	Técnico em Redes de Computadores
201112550100	3492	\N	MAURO SERGIO PEREIRA	t	Técnico em Redes de Computadores
\.


--
-- TOC entry 2069 (class 0 OID 32817067)
-- Dependencies: 168
-- Data for Name: aluno_preferencia; Type: TABLE DATA; Schema: armario; Owner: comsolid
--

COPY aluno_preferencia (id_posicao_armario, id_pessoa, prioridade) FROM stdin;
8	1121	1
9	1121	1
10	1121	2
11	1121	2
12	1121	2
1	1901	3
2	1901	3
3	1901	3
4	1901	1
5	1901	1
6	1901	1
7	1901	1
8	1901	1
9	1901	1
10	1901	2
11	1901	2
12	1901	2
1	1043	3
2	1043	3
3	1043	3
4	1043	1
5	1043	1
6	1043	1
7	1043	1
8	1043	1
9	1043	1
10	1043	2
11	1043	2
12	1043	2
1	682	3
2	682	3
3	682	3
4	682	1
5	682	1
6	682	1
7	682	1
8	682	1
9	682	1
10	682	2
11	682	2
12	682	2
1	1026	3
2	1026	3
3	1026	3
4	1026	1
5	1026	1
6	1026	1
7	1026	1
8	1026	1
9	1026	1
10	1026	2
11	1026	2
12	1026	2
1	1100	3
2	1100	3
3	1100	3
4	1100	1
5	1100	1
6	1100	1
7	1100	1
8	1100	1
9	1100	1
10	1100	2
11	1100	2
12	1100	2
1	1200	3
2	1200	3
3	1200	3
4	1200	1
5	1200	1
6	1200	1
7	1200	1
8	1200	1
9	1200	1
10	1200	2
11	1200	2
12	1200	2
1	312	3
2	312	3
3	312	3
4	312	1
5	312	1
6	312	1
7	312	1
8	312	1
9	312	1
10	312	2
11	312	2
12	312	2
1	1132	3
2	1132	3
3	1132	3
4	1132	1
5	1132	1
6	1132	1
7	1132	1
8	1132	1
9	1132	1
10	1132	2
11	1132	2
12	1132	2
1	697	3
2	697	3
3	697	3
4	697	1
5	697	1
6	697	1
7	697	1
8	697	1
9	697	1
10	697	2
11	697	2
12	697	2
4	1414	1
5	1414	1
6	1414	1
7	1414	1
8	1414	1
9	1414	1
4	973	1
5	973	1
6	973	1
7	973	1
8	973	1
9	973	1
4	1151	1
5	1151	1
6	1151	1
7	1151	1
8	1151	1
9	1151	1
4	1002	1
5	1002	1
6	1002	1
7	1002	1
8	1002	1
9	1002	1
4	837	1
5	837	1
6	837	1
7	837	1
8	837	1
9	837	1
4	432	1
5	432	1
6	432	1
7	432	1
8	432	1
9	432	1
4	1064	1
5	1064	1
6	1064	1
7	1064	1
8	1064	1
9	1064	1
4	425	1
5	425	1
6	425	1
7	425	1
8	425	1
9	425	1
4	824	1
5	824	1
6	824	1
7	824	1
8	824	1
9	824	1
4	1134	1
5	1134	1
6	1134	1
7	1134	1
8	1134	1
9	1134	1
4	467	1
5	467	1
6	467	1
7	467	1
8	467	1
9	467	1
4	1022	1
5	1022	1
6	1022	1
7	1022	1
8	1022	1
9	1022	1
4	1124	1
5	1124	1
6	1124	1
7	1124	1
8	1124	1
9	1124	1
4	762	1
5	762	1
6	762	1
7	762	1
8	762	1
9	762	1
4	1001	1
5	1001	1
6	1001	1
7	1001	1
8	1001	1
9	1001	1
4	1121	1
5	1121	1
6	1121	1
7	1121	1
4	3575	1
5	3575	1
6	3575	1
7	3575	1
8	3575	1
9	3575	1
4	3576	1
5	3576	1
6	3576	1
7	3576	1
8	3576	1
9	3576	1
4	3577	1
5	3577	1
6	3577	1
7	3577	1
8	3577	1
9	3577	1
4	3578	1
5	3578	1
6	3578	1
7	3578	1
8	3578	1
9	3578	1
4	3579	1
5	3579	1
6	3579	1
7	3579	1
8	3579	1
9	3579	1
4	3581	1
5	3581	1
6	3581	1
7	3581	1
8	3581	1
9	3581	1
4	3584	1
5	3584	1
6	3584	1
7	3584	1
8	3584	1
9	3584	1
4	3585	1
5	3585	1
6	3585	1
7	3585	1
8	3585	1
9	3585	1
4	3586	1
5	3586	1
6	3586	1
7	3586	1
8	3586	1
9	3586	1
4	3588	1
5	3588	1
6	3588	1
7	3588	1
8	3588	1
9	3588	1
4	3589	1
5	3589	1
6	3589	1
7	3589	1
8	3589	1
9	3589	1
4	3590	1
5	3590	1
6	3590	1
7	3590	1
8	3590	1
9	3590	1
4	3591	1
5	3591	1
6	3591	1
7	3591	1
8	3591	1
9	3591	1
4	3592	1
5	3592	1
6	3592	1
7	3592	1
8	3592	1
9	3592	1
4	408	1
5	408	1
6	408	1
7	408	1
8	408	1
9	408	1
5	3559	1
6	3559	1
7	3559	1
8	3559	1
9	3559	1
4	631	1
5	631	1
6	631	1
7	631	1
8	631	1
9	631	1
4	449	1
5	449	1
6	449	1
7	449	1
8	449	1
9	449	1
4	1021	1
5	1021	1
6	1021	1
7	1021	1
8	1021	1
9	1021	1
4	677	1
5	677	1
6	677	1
7	677	1
8	677	1
9	677	1
4	1140	1
5	1140	1
6	1140	1
7	1140	1
8	1140	1
9	1140	1
4	1438	1
5	1438	1
6	1438	1
7	1438	1
8	1438	1
9	1438	1
4	3565	1
5	3565	1
6	3565	1
7	3565	1
8	3565	1
9	3565	1
4	444	1
5	444	1
6	444	1
7	444	1
8	444	1
9	444	1
4	3566	1
5	3566	1
6	3566	1
7	3566	1
8	3566	1
9	3566	1
4	3569	1
5	3569	1
6	3569	1
7	3569	1
8	3569	1
9	3569	1
4	3570	1
5	3570	1
6	3570	1
7	3570	1
8	3570	1
9	3570	1
4	3571	1
5	3571	1
6	3571	1
7	3571	1
8	3571	1
9	3571	1
4	3572	1
5	3572	1
6	3572	1
7	3572	1
8	3572	1
9	3572	1
10	3415	2
11	3415	2
12	3415	2
4	3573	1
5	3573	1
6	3573	1
7	3573	1
8	3573	1
9	3573	1
4	3574	1
5	3574	1
6	3574	1
1	3418	3
2	3418	3
3	3418	3
7	3574	1
8	3574	1
9	3574	1
4	3535	1
5	3535	1
6	3535	1
7	3535	1
8	3535	1
9	3535	1
4	3536	1
5	3536	1
6	3536	1
7	3536	1
8	3536	1
9	3536	1
4	3538	1
5	3538	1
6	3538	1
7	3538	1
8	3538	1
9	3538	1
4	3539	1
5	3539	1
6	3539	1
7	3539	1
8	3539	1
9	3539	1
4	758	1
5	758	1
6	758	1
7	758	1
8	758	1
9	758	1
4	3544	1
5	3544	1
6	3544	1
7	3544	1
8	3544	1
9	3544	1
4	1063	1
5	1063	1
6	1063	1
7	1063	1
8	1063	1
9	1063	1
4	3547	1
5	3547	1
6	3547	1
7	3547	1
8	3547	1
9	3547	1
4	3548	1
5	3548	1
6	3548	1
7	3548	1
8	3548	1
9	3548	1
4	3550	1
5	3550	1
6	3550	1
7	3550	1
8	3550	1
9	3550	1
4	3551	1
5	3551	1
6	3551	1
7	3551	1
8	3551	1
9	3551	1
4	3553	1
5	3553	1
4	3418	1
5	3418	1
6	3418	1
6	3553	1
7	3553	1
8	3553	1
9	3553	1
4	3555	1
5	3555	1
6	3555	1
7	3555	1
8	3555	1
9	3555	1
4	3557	1
5	3557	1
7	3418	1
8	3418	1
9	3418	1
6	3557	1
7	3557	1
8	3557	1
9	3557	1
4	3558	1
5	3558	1
6	3558	1
7	3558	1
8	3558	1
9	3558	1
4	3559	1
7	1654	1
8	1654	1
9	1654	1
4	3490	1
5	3490	1
6	3490	1
7	3490	1
8	3490	1
9	3490	1
4	3494	1
5	3494	1
6	3494	1
7	3494	1
8	3494	1
9	3494	1
4	3495	1
5	3495	1
6	3495	1
7	3495	1
8	3495	1
9	3495	1
4	3499	1
5	3499	1
6	3499	1
7	3499	1
8	3499	1
9	3499	1
10	3418	2
11	3418	2
12	3418	2
1	3426	3
2	3426	3
3	3426	3
4	3426	1
5	3426	1
6	3426	1
7	3426	1
8	3426	1
4	3500	1
5	3500	1
6	3500	1
7	3500	1
8	3500	1
9	3500	1
4	3501	1
5	3501	1
6	3501	1
7	3501	1
8	3501	1
9	3501	1
4	3507	1
5	3507	1
6	3507	1
7	3507	1
8	3507	1
9	3507	1
4	3509	1
5	3509	1
6	3509	1
7	3509	1
8	3509	1
9	3509	1
4	3510	1
5	3510	1
6	3510	1
7	3510	1
8	3510	1
9	3510	1
4	3516	1
5	3516	1
6	3516	1
7	3516	1
8	3516	1
9	3516	1
4	3520	1
5	3520	1
6	3520	1
7	3520	1
8	3520	1
9	3520	1
4	3521	1
5	3521	1
6	3521	1
7	3521	1
8	3521	1
9	3521	1
4	3526	1
5	3526	1
6	3526	1
7	3526	1
8	3526	1
9	3526	1
4	3531	1
5	3531	1
6	3531	1
7	3531	1
8	3531	1
9	3531	1
4	3533	1
5	3533	1
6	3533	1
7	3533	1
8	3533	1
9	3533	1
4	3358	1
5	3358	1
6	3358	1
7	3358	1
8	3358	1
9	3358	1
4	3363	1
5	3363	1
6	3363	1
7	3363	1
8	3363	1
9	3363	1
4	1044	1
5	1044	1
6	1044	1
7	1044	1
8	1044	1
9	1044	1
4	3364	1
5	3364	1
6	3364	1
7	3364	1
8	3364	1
9	3364	1
4	3366	1
5	3366	1
6	3366	1
7	3366	1
8	3366	1
9	3366	1
4	3367	1
5	3367	1
6	3367	1
7	3367	1
8	3367	1
9	3367	1
4	3369	1
5	3369	1
6	3369	1
7	3369	1
8	3369	1
9	3369	1
4	3370	1
5	3370	1
6	3370	1
7	3370	1
9	3426	1
10	3426	2
11	3426	2
12	3426	2
1	3429	3
2	3429	3
3	3429	3
4	3429	1
5	3429	1
6	3429	1
7	3429	1
8	3429	1
9	3429	1
10	3429	2
11	3429	2
12	3429	2
1	3430	3
2	3430	3
3	3430	3
4	3430	1
5	3430	1
6	3430	1
7	3430	1
8	3430	1
9	3430	1
10	3430	2
11	3430	2
12	3430	2
1	3431	3
2	3431	3
3	3431	3
4	3431	1
5	3431	1
6	3431	1
7	3431	1
8	3431	1
9	3431	1
10	3431	2
11	3431	2
12	3431	2
1	3432	3
2	3432	3
3	3432	3
4	3432	1
5	3432	1
6	3432	1
7	3432	1
8	3432	1
9	3432	1
10	3432	2
11	3432	2
12	3432	2
1	3433	3
2	3433	3
3	3433	3
4	3433	1
5	3433	1
6	3433	1
7	3433	1
8	3433	1
9	3433	1
10	3433	2
11	3433	2
12	3433	2
1	3435	3
2	3435	3
8	3370	1
9	3370	1
4	3371	1
5	3371	1
6	3371	1
7	3371	1
8	3371	1
9	3371	1
4	3372	1
5	3372	1
6	3372	1
7	3372	1
8	3372	1
9	3372	1
4	3379	1
5	3379	1
6	3379	1
7	3379	1
8	3379	1
9	3379	1
4	3380	1
5	3380	1
6	3380	1
7	3380	1
8	3380	1
9	3380	1
4	3382	1
5	3382	1
6	3382	1
7	3382	1
8	3382	1
9	3382	1
4	3383	1
5	3383	1
6	3383	1
7	3383	1
8	3383	1
9	3383	1
4	3385	1
5	3385	1
6	3385	1
7	3385	1
8	3385	1
9	3385	1
4	1654	1
5	1654	1
6	1654	1
9	3464	1
4	3465	1
5	3465	1
6	3465	1
7	3465	1
8	3465	1
9	3465	1
4	3467	1
5	3467	1
6	3467	1
7	3467	1
8	3467	1
9	3467	1
4	3469	1
5	3469	1
6	3469	1
7	3469	1
8	3469	1
9	3469	1
4	3470	1
5	3470	1
6	3470	1
7	3470	1
8	3470	1
9	3470	1
4	3472	1
5	3472	1
6	3472	1
7	3472	1
8	3472	1
9	3472	1
4	3474	1
5	3474	1
6	3474	1
7	3474	1
8	3474	1
9	3474	1
4	3475	1
5	3475	1
6	3475	1
7	3475	1
8	3475	1
9	3475	1
4	3481	1
5	3481	1
6	3481	1
7	3481	1
8	3481	1
9	3481	1
3	3435	3
4	3435	1
5	3435	1
6	3435	1
4	3482	1
5	3482	1
6	3482	1
7	3482	1
8	3482	1
9	3482	1
4	3484	1
5	3484	1
6	3484	1
7	3484	1
8	3484	1
9	3484	1
7	3435	1
8	3435	1
4	3486	1
5	3486	1
6	3486	1
7	3486	1
8	3486	1
9	3486	1
4	634	1
5	634	1
6	634	1
7	634	1
8	634	1
9	634	1
4	3346	1
5	3346	1
6	3346	1
7	3346	1
8	3346	1
9	3346	1
4	3349	1
9	3435	1
10	3435	2
11	3435	2
5	3349	1
6	3349	1
7	3349	1
8	3349	1
9	3349	1
12	3435	2
1	3436	3
2	3436	3
3	3436	3
4	3436	1
5	3436	1
6	3436	1
7	3436	1
8	3436	1
9	3436	1
10	3436	2
11	3436	2
12	3436	2
1	3437	3
2	3437	3
3	3437	3
4	3437	1
5	3437	1
6	3437	1
7	3437	1
8	3437	1
9	3437	1
10	3437	2
11	3437	2
12	3437	2
1	3439	3
2	3439	3
3	3439	3
4	3439	1
5	3439	1
6	3439	1
7	3439	1
8	3439	1
9	3439	1
10	3439	2
11	3439	2
4	3356	1
5	3356	1
6	3356	1
7	3356	1
8	3356	1
9	3356	1
4	3421	1
5	3421	1
6	3421	1
7	3421	1
8	3421	1
9	3421	1
4	3424	1
5	3424	1
6	3424	1
7	3424	1
8	3424	1
9	3424	1
4	3425	1
5	3425	1
6	3425	1
7	3425	1
8	3425	1
9	3425	1
4	3427	1
5	3427	1
6	3427	1
7	3427	1
8	3427	1
9	3427	1
4	3428	1
5	3428	1
6	3428	1
7	3428	1
8	3428	1
9	3428	1
4	2054	1
5	2054	1
6	2054	1
7	2054	1
8	2054	1
9	2054	1
4	3434	1
5	3434	1
6	3434	1
7	3434	1
8	3434	1
9	3434	1
4	3438	1
5	3438	1
6	3438	1
7	3438	1
8	3438	1
12	3439	2
1	3440	3
2	3440	3
3	3440	3
4	3440	1
9	3438	1
4	3442	1
5	3442	1
6	3442	1
7	3442	1
8	3442	1
9	3442	1
4	3443	1
5	3443	1
6	3443	1
7	3443	1
8	3443	1
9	3443	1
4	3445	1
5	3445	1
6	3445	1
7	3445	1
8	3445	1
9	3445	1
4	3446	1
5	3446	1
6	3446	1
7	3446	1
8	3446	1
9	3446	1
4	3453	1
5	3453	1
6	3453	1
7	3453	1
8	3453	1
9	3453	1
4	3459	1
5	3459	1
6	3459	1
7	3459	1
8	3459	1
9	3459	1
4	3461	1
5	3461	1
6	3461	1
7	3461	1
8	3461	1
9	3461	1
4	3464	1
5	3464	1
6	3464	1
7	3464	1
8	3464	1
4	2162	1
5	2162	1
6	2162	1
7	2162	1
8	2162	1
9	2162	1
4	3397	1
5	3397	1
6	3397	1
7	3397	1
8	3397	1
9	3397	1
4	3399	1
5	3399	1
6	3399	1
7	3399	1
8	3399	1
9	3399	1
4	3400	1
5	3400	1
6	3400	1
7	3400	1
8	3400	1
9	3400	1
4	3402	1
5	3402	1
5	3440	1
6	3440	1
7	3440	1
8	3440	1
9	3440	1
10	3440	2
11	3440	2
12	3440	2
1	3441	1
2	3441	1
3	3441	1
4	3441	2
5	3441	2
6	3441	2
7	3441	2
8	3441	2
9	3441	2
10	3441	2
11	3441	2
12	3441	2
1	3444	3
2	3444	3
3	3444	3
4	3444	1
5	3444	1
6	3444	1
7	3444	1
8	3444	1
9	3444	1
10	3444	2
11	3444	2
12	3444	2
1	3447	3
2	3447	3
3	3447	3
4	3447	1
5	3447	1
6	3447	1
7	3447	1
8	3447	1
9	3447	1
10	3447	2
11	3447	2
12	3447	2
1	3448	3
6	3402	1
7	3402	1
8	3402	1
9	3402	1
4	3405	1
5	3405	1
6	3405	1
7	3405	1
8	3405	1
9	3405	1
4	3406	1
5	3406	1
6	3406	1
7	3406	1
8	3406	1
9	3406	1
4	3407	1
5	3407	1
6	3407	1
7	3407	1
8	3407	1
9	3407	1
4	3409	1
5	3409	1
6	3409	1
7	3409	1
8	3409	1
9	3409	1
4	3410	1
5	3410	1
6	3410	1
2	3448	3
3	3448	3
4	3448	1
7	3410	1
8	3410	1
9	3410	1
4	3412	1
5	3412	1
6	3412	1
7	3412	1
8	3412	1
9	3412	1
4	3413	1
5	3413	1
6	3413	1
7	3413	1
8	3413	1
9	3413	1
4	3416	1
5	3416	1
6	3416	1
7	3416	1
8	3416	1
9	3416	1
4	3417	1
5	3448	1
6	3448	1
7	3448	1
5	3417	1
6	3417	1
7	3417	1
8	3417	1
9	3417	1
4	3419	1
5	3419	1
6	3419	1
7	3419	1
8	3419	1
9	3419	1
6	809	1
7	809	1
8	809	1
9	809	1
4	1897	1
5	1897	1
6	1897	1
8	3448	1
9	3448	1
10	3448	2
11	3448	2
12	3448	2
1	3449	3
7	1897	1
8	1897	1
9	1897	1
4	1710	1
5	1710	1
6	1710	1
7	1710	1
8	1710	1
9	1710	1
4	1040	1
5	1040	1
6	1040	1
7	1040	1
8	1040	1
9	1040	1
4	417	1
5	417	1
6	417	1
7	417	1
8	417	1
9	417	1
2	3449	3
3	3449	3
4	3449	1
4	1023	1
5	1023	1
6	1023	1
7	1023	1
8	1023	1
9	1023	1
4	521	1
5	521	1
6	521	1
7	521	1
8	521	1
9	521	1
4	782	1
5	782	1
6	782	1
7	782	1
8	782	1
9	782	1
4	640	1
5	640	1
6	640	1
7	640	1
8	640	1
9	640	1
4	674	1
5	674	1
6	674	1
7	674	1
8	674	1
9	674	1
4	1792	1
5	1792	1
6	1792	1
7	1792	1
8	1792	1
9	1792	1
4	1742	1
5	1742	1
6	1742	1
7	1742	1
8	1742	1
9	1742	1
4	1707	1
5	1707	1
6	1707	1
7	1707	1
8	1707	1
9	1707	1
4	3388	1
5	3388	1
6	3388	1
7	3388	1
8	3388	1
9	3388	1
4	3389	1
5	3389	1
6	3389	1
7	3389	1
8	3389	1
9	3389	1
4	3394	1
5	3394	1
6	3394	1
7	3394	1
8	3394	1
9	3394	1
4	1191	1
5	1191	1
6	1191	1
7	1191	1
8	1191	1
9	1191	1
4	315	1
5	315	1
6	315	1
7	315	1
8	315	1
9	315	1
4	639	1
5	639	1
6	639	1
7	639	1
8	639	1
9	639	1
4	333	1
5	333	1
6	333	1
7	333	1
8	333	1
9	333	1
4	401	1
5	401	1
6	401	1
7	401	1
8	401	1
9	401	1
4	1381	1
5	1381	1
6	1381	1
7	1381	1
8	1381	1
9	1381	1
4	334	1
5	334	1
6	334	1
7	334	1
8	334	1
9	334	1
4	1059	1
5	1059	1
6	1059	1
7	1059	1
8	1059	1
9	1059	1
4	646	1
5	646	1
6	646	1
7	646	1
8	646	1
9	646	1
4	996	1
5	996	1
6	996	1
7	996	1
8	996	1
9	996	1
4	616	1
5	616	1
6	616	1
7	616	1
8	616	1
9	616	1
4	673	1
5	673	1
6	673	1
7	673	1
8	673	1
9	673	1
4	1133	1
5	1133	1
6	1133	1
7	1133	1
8	1133	1
9	1133	1
4	993	1
5	993	1
6	993	1
7	993	1
8	993	1
9	993	1
4	1318	1
5	1318	1
6	1318	1
7	1318	1
8	1318	1
9	1318	1
4	809	1
5	809	1
8	3583	1
9	3583	1
10	3583	2
11	3583	2
12	3583	2
4	3587	1
5	3587	1
6	3587	1
7	3587	1
8	3587	1
9	3587	1
10	3587	2
11	3587	2
12	3587	2
4	632	1
5	632	1
6	632	1
7	632	1
8	632	1
9	632	1
10	632	2
11	632	2
12	632	2
4	325	1
5	325	1
6	325	1
7	325	1
8	325	1
9	325	1
10	325	2
11	325	2
12	325	2
4	1097	1
5	1097	1
6	1097	1
7	1097	1
8	1097	1
9	1097	1
4	323	1
5	323	1
6	323	1
7	323	1
8	323	1
9	323	1
4	1917	1
5	1917	1
6	1917	1
7	1917	1
8	1917	1
9	1917	1
4	1033	1
5	1033	1
6	1033	1
7	1033	1
8	1033	1
9	1033	1
4	1052	1
5	1052	1
6	1052	1
7	1052	1
8	1052	1
9	1052	1
4	694	1
5	694	1
6	694	1
7	694	1
8	694	1
9	694	1
4	398	1
5	398	1
6	398	1
7	398	1
8	398	1
9	398	1
4	424	1
5	424	1
6	424	1
7	424	1
8	424	1
9	424	1
4	625	1
5	625	1
6	625	1
7	625	1
8	625	1
9	625	1
4	1131	1
5	1131	1
6	1131	1
7	1131	1
8	1131	1
9	1131	1
4	1174	1
5	1174	1
6	1174	1
7	1174	1
8	1174	1
5	3449	1
6	3449	1
7	3449	1
9	1174	1
4	2569	1
5	2569	1
6	2569	1
7	2569	1
8	2569	1
9	2569	1
10	2569	2
11	2569	2
12	2569	2
4	3525	1
5	3525	1
6	3525	1
7	3525	1
8	3525	1
9	3525	1
10	3525	2
11	3525	2
12	3525	2
4	3527	1
5	3527	1
6	3527	1
7	3527	1
8	3527	1
9	3527	1
10	3527	2
11	3527	2
12	3527	2
4	3528	1
5	3528	1
6	3528	1
7	3528	1
8	3528	1
9	3528	1
10	3528	2
11	3528	2
12	3528	2
4	3529	1
5	3529	1
6	3529	1
7	3529	1
8	3529	1
9	3529	1
4	3537	1
5	3537	1
6	3537	1
7	3537	1
8	3537	1
9	3537	1
4	307	1
5	307	1
6	307	1
7	307	1
8	307	1
9	307	1
4	3540	1
5	3540	1
6	3540	1
7	3540	1
8	3540	1
9	3540	1
4	3541	1
5	3541	1
6	3541	1
7	3541	1
8	3541	1
9	3541	1
4	3543	1
5	3543	1
6	3543	1
7	3543	1
8	3543	1
9	3543	1
4	1554	1
5	1554	1
6	1554	1
7	1554	1
8	1554	1
9	1554	1
4	3567	1
5	3567	1
6	3567	1
7	3567	1
8	3567	1
9	3567	1
4	3580	1
5	3580	1
6	3580	1
7	3580	1
8	3580	1
9	3580	1
4	3582	1
5	3582	1
6	3582	1
7	3582	1
8	3582	1
9	3582	1
4	3583	1
5	3583	1
6	3583	1
7	3583	1
10	3496	2
11	3496	2
12	3496	2
4	3497	1
5	3497	1
6	3497	1
7	3497	1
8	3497	1
9	3497	1
10	3497	2
11	3497	2
12	3497	2
4	3502	1
5	3502	1
6	3502	1
7	3502	1
8	3502	1
9	3502	1
10	3502	2
11	3502	2
12	3502	2
4	3503	1
5	3503	1
6	3503	1
7	3503	1
8	3503	1
9	3503	1
10	3503	2
11	3503	2
12	3503	2
4	3504	1
5	3504	1
6	3504	1
7	3504	1
8	3504	1
9	3504	1
10	3504	2
11	3504	2
12	3504	2
4	3508	1
5	3508	1
6	3508	1
7	3508	1
8	3508	1
9	3508	1
10	3508	2
11	3508	2
12	3508	2
4	3511	1
5	3511	1
6	3511	1
7	3511	1
8	3511	1
9	3511	1
10	3511	2
11	3511	2
12	3511	2
4	3512	1
5	3512	1
6	3512	1
7	3512	1
8	3512	1
9	3512	1
10	3512	2
11	3512	2
12	3512	2
4	3514	1
5	3514	1
6	3514	1
7	3514	1
8	3514	1
9	3514	1
8	3449	1
9	3449	1
10	3449	2
11	3449	2
12	3449	2
4	3517	1
5	3517	1
6	3517	1
7	3517	1
8	3517	1
9	3517	1
4	3518	1
5	3518	1
6	3518	1
7	3518	1
1	3450	3
2	3450	3
3	3450	3
4	3450	1
5	3450	1
6	3450	1
8	3518	1
9	3518	1
4	3519	1
5	3519	1
6	3519	1
7	3519	1
8	3519	1
9	3519	1
4	3522	1
5	3522	1
6	3522	1
7	3450	1
8	3450	1
7	3522	1
8	3522	1
9	3522	1
4	3523	1
5	3523	1
6	3523	1
7	3523	1
8	3523	1
9	3523	1
5	3353	1
6	3353	1
7	3353	1
8	3353	1
9	3353	1
10	3353	2
11	3353	2
12	3353	2
4	3354	1
5	3354	1
6	3354	1
7	3354	1
8	3354	1
9	3354	1
10	3354	2
11	3354	2
12	3354	2
4	3355	1
5	3355	1
6	3355	1
7	3355	1
8	3355	1
9	3355	1
10	3355	2
11	3355	2
12	3355	2
4	3362	1
5	3362	1
6	3362	1
7	3362	1
8	3362	1
9	3362	1
10	3362	2
11	3362	2
12	3362	2
4	3373	1
5	3373	1
6	3373	1
7	3373	1
8	3373	1
9	3373	1
4	3374	1
5	3374	1
6	3374	1
7	3374	1
8	3374	1
9	3374	1
4	3375	1
5	3375	1
6	3375	1
7	3375	1
8	3375	1
9	3375	1
4	3378	1
5	3378	1
6	3378	1
7	3378	1
8	3378	1
9	3378	1
4	3381	1
5	3381	1
6	3381	1
7	3381	1
8	3381	1
9	3381	1
4	3384	1
5	3384	1
6	3384	1
7	3384	1
8	3384	1
9	3384	1
4	3386	1
5	3386	1
6	3386	1
7	3386	1
8	3386	1
9	3386	1
4	3387	1
5	3387	1
6	3387	1
7	3387	1
8	3387	1
9	3387	1
4	3489	1
5	3489	1
6	3489	1
7	3489	1
8	3489	1
9	3489	1
4	3491	1
5	3491	1
6	3491	1
7	3491	1
8	3491	1
9	3491	1
4	3496	1
5	3496	1
6	3496	1
7	3496	1
8	3496	1
9	3496	1
12	812	2
4	1167	1
5	1167	1
6	1167	1
7	1167	1
8	1167	1
9	1167	1
10	1167	2
11	1167	2
12	1167	2
4	588	1
5	588	1
6	588	1
7	588	1
8	588	1
9	588	1
10	588	2
11	588	2
12	588	2
4	626	1
5	626	1
6	626	1
7	626	1
8	626	1
9	626	1
10	626	2
11	626	2
12	626	2
4	523	1
5	523	1
6	523	1
7	523	1
8	523	1
9	523	1
10	523	2
11	523	2
4	1095	1
9	3450	1
10	3450	2
11	3450	2
12	3450	2
5	1095	1
6	1095	1
7	1095	1
1	3452	3
2	3452	3
8	1095	1
9	1095	1
4	590	1
5	590	1
6	590	1
7	590	1
8	590	1
9	590	1
4	2245	1
5	2245	1
6	2245	1
7	2245	1
8	2245	1
9	2245	1
4	1602	1
5	1602	1
6	1602	1
7	1602	1
8	1602	1
9	1602	1
4	305	1
5	305	1
6	305	1
7	305	1
8	305	1
9	305	1
4	3347	1
5	3347	1
6	3347	1
7	3347	1
8	3347	1
9	3347	1
4	3344	1
5	3344	1
6	3344	1
7	3344	1
8	3344	1
9	3344	1
4	3350	1
5	3350	1
6	3350	1
7	3350	1
8	3350	1
9	3350	1
4	3348	1
5	3348	1
6	3348	1
7	3348	1
8	3348	1
9	3348	1
4	3352	1
5	3352	1
6	3352	1
7	3352	1
8	3352	1
9	3352	1
4	3353	1
7	1152	1
8	1152	1
9	1152	1
10	1152	2
11	1152	2
12	1152	2
4	817	1
5	817	1
6	817	1
7	817	1
8	817	1
9	817	1
10	817	2
11	817	2
12	817	2
4	1018	1
5	1018	1
6	1018	1
7	1018	1
8	1018	1
9	1018	1
10	1018	2
11	1018	2
3	3452	3
4	3452	1
5	3452	1
6	3452	1
7	3452	1
12	1018	2
4	624	1
5	624	1
6	624	1
7	624	1
8	624	1
9	624	1
10	624	2
11	624	2
12	624	2
4	672	1
5	672	1
6	672	1
7	672	1
8	3452	1
9	3452	1
10	3452	2
8	672	1
9	672	1
10	672	2
11	672	2
12	672	2
4	1099	1
5	1099	1
6	1099	1
7	1099	1
8	1099	1
9	1099	1
10	1099	2
11	1099	2
12	1099	2
4	767	1
5	767	1
6	767	1
7	767	1
8	767	1
9	767	1
10	767	2
11	767	2
12	767	2
4	1096	1
5	1096	1
6	1096	1
7	1096	1
8	1096	1
9	1096	1
10	1096	2
11	1096	2
12	1096	2
4	929	1
5	929	1
6	929	1
7	929	1
8	929	1
9	929	1
4	1109	1
5	1109	1
6	1109	1
7	1109	1
8	1109	1
9	1109	1
4	934	1
5	934	1
6	934	1
7	934	1
8	934	1
9	934	1
4	1416	1
5	1416	1
6	1416	1
7	1416	1
8	1416	1
9	1416	1
4	297	1
5	297	1
6	297	1
7	297	1
8	297	1
9	297	1
4	812	1
5	812	1
6	812	1
7	812	1
8	812	1
11	3452	2
9	812	1
4	3473	1
5	3473	1
6	3473	1
7	3473	1
8	3473	1
9	3473	1
10	3473	2
11	3473	2
12	3473	2
4	3477	1
5	3477	1
6	3477	1
7	3477	1
8	3477	1
9	3477	1
12	3452	2
1	3454	3
2	3454	3
10	3477	2
11	3477	2
12	3477	2
4	3478	1
5	3478	1
6	3478	1
3	3454	3
4	3454	1
5	3454	1
7	3478	1
8	3478	1
9	3478	1
10	3478	2
11	3478	2
12	3478	2
4	3479	1
5	3479	1
6	3479	1
7	3479	1
8	3479	1
9	3479	1
10	3479	2
11	3479	2
12	3479	2
4	3480	1
5	3480	1
6	3480	1
7	3480	1
8	3480	1
9	3480	1
4	3488	1
5	3488	1
6	3488	1
7	3488	1
8	3488	1
9	3488	1
4	3545	1
5	3545	1
6	3545	1
7	3545	1
8	3545	1
9	3545	1
4	2635	1
5	2635	1
6	2635	1
7	2635	1
8	2635	1
9	2635	1
4	299	1
5	299	1
6	299	1
7	299	1
8	299	1
9	299	1
4	3552	1
5	3552	1
6	3552	1
7	3552	1
8	3552	1
9	3552	1
4	3556	1
5	3556	1
6	3556	1
7	3556	1
8	3556	1
9	3556	1
4	3560	1
5	3560	1
6	3560	1
7	3560	1
8	3560	1
9	3560	1
4	689	1
5	689	1
6	689	1
7	689	1
8	689	1
9	689	1
4	1086	1
5	1086	1
6	1086	1
7	1086	1
8	1086	1
9	1086	1
4	1152	1
5	1152	1
6	1152	1
1	3390	3
2	3390	3
3	3390	3
4	3390	1
5	3390	1
6	3390	1
7	3390	1
8	3390	1
9	3390	1
10	3390	2
11	3390	2
12	3390	2
1	3391	3
2	3391	3
3	3391	3
4	3391	1
5	3391	1
6	3391	1
7	3391	1
8	3391	1
9	3391	1
10	3391	2
11	3391	2
12	3391	2
1	3393	3
2	3393	3
3	3393	3
4	3393	1
5	3393	1
6	3393	1
7	3393	1
8	3393	1
9	3393	1
10	3393	2
11	3393	2
12	3393	2
1	3395	3
2	3395	3
3	3395	3
4	3395	1
5	3395	1
6	3395	1
7	3395	1
8	3395	1
9	3395	1
10	3395	2
11	3395	2
12	3395	2
1	3396	3
2	3396	3
3	3396	3
4	3396	1
5	3396	1
6	3396	1
7	3396	1
8	3396	1
9	3396	1
10	3396	2
11	3396	2
12	3396	2
1	3401	3
2	3401	3
3	3401	3
4	3401	1
5	3401	1
6	3401	1
7	3401	1
8	3401	1
9	3401	1
10	3401	2
11	3401	2
12	3401	2
1	3403	3
2	3403	3
3	3403	3
4	3403	1
5	3403	1
6	3403	1
7	3403	1
8	3403	1
9	3403	1
10	3403	2
11	3403	2
12	3403	2
1	3404	3
2	3404	3
3	3404	3
4	3404	1
5	3404	1
6	3404	1
7	3404	1
8	3404	1
9	3404	1
10	3404	2
11	3404	2
12	3404	2
1	3408	3
2	3408	3
3	3408	3
4	3408	1
5	3408	1
6	3408	1
7	3408	1
8	3408	1
9	3408	1
10	3408	2
11	3408	2
12	3408	2
1	3415	3
2	3415	3
3	3415	3
4	3415	1
5	3415	1
6	3415	1
7	3415	1
8	3415	1
9	3415	1
1	758	3
2	758	3
3	758	3
1	3544	3
2	3544	3
3	3544	3
1	1063	3
2	1063	3
3	1063	3
1	3547	3
2	3547	3
3	3547	3
1	3548	3
2	3548	3
6	3454	1
3	3548	3
1	3550	3
2	3550	3
3	3550	3
1	3551	3
2	3551	3
3	3551	3
1	3553	3
2	3553	3
3	3553	3
1	3555	3
2	3555	3
7	3454	1
8	3454	1
3	3555	3
1	3557	3
2	3557	3
3	3557	3
1	3558	3
2	3558	3
3	3558	3
1	3559	3
2	3559	3
3	3559	3
1	631	3
2	631	3
3	631	3
1	449	3
2	449	3
3	449	3
1	1021	3
2	1021	3
3	1021	3
1	677	3
2	677	3
3	677	3
1	1140	3
2	1140	3
3	1140	3
1	1438	3
2	1438	3
3	1438	3
1	3565	3
2	3565	3
3	3565	3
1	444	3
2	444	3
3	444	3
1	3566	3
2	3566	3
3	3566	3
1	3569	3
2	3569	3
3	3569	3
1	3570	3
2	3570	3
3	3570	3
1	3571	3
2	3571	3
3	3571	3
1	3572	3
2	3572	3
3	3572	3
1	3573	3
2	3573	3
3	3573	3
1	3574	3
2	3574	3
3	3574	3
1	3575	3
2	3575	3
3	3575	3
1	3576	3
2	3576	3
3	3576	3
1	3577	3
2	3577	3
3	3577	3
1	3578	3
2	3578	3
3	3578	3
1	3579	3
2	3579	3
3	3579	3
1	3581	3
2	3581	3
3	3581	3
1	3584	3
2	3584	3
3	3584	3
1	3585	3
2	3585	3
9	3454	1
10	3454	2
11	3454	2
3	3585	3
1	3586	3
2	3586	3
3	3586	3
1	3588	3
2	3588	3
3	3588	3
1	3589	3
2	3589	3
3	3589	3
1	3590	3
2	3590	3
3	3590	3
1	3591	3
2	3591	3
3	3591	3
1	3592	3
2	3592	3
3	3592	3
1	408	3
2	408	3
3	408	3
1	1414	3
2	1414	3
3	1414	3
1	973	3
2	973	3
3	973	3
1	1151	3
2	1151	3
3	1151	3
1	1002	3
2	1002	3
3	1002	3
1	837	3
2	837	3
3	837	3
1	432	3
2	432	3
3	432	3
1	1064	3
2	1064	3
3	1064	3
1	425	3
2	425	3
3	425	3
1	824	3
2	824	3
3	824	3
1	1134	3
2	1134	3
3	1134	3
1	467	3
2	467	3
3	467	3
1	1022	3
2	1022	3
3	1022	3
1	1124	3
2	1124	3
3	1124	3
1	762	3
2	762	3
3	762	3
1	1001	3
2	1001	3
3	1001	3
1	1121	3
2	1121	3
3	1121	3
3	2054	3
1	3434	3
2	3434	3
3	3434	3
1	3438	3
2	3438	3
3	3438	3
1	3442	3
2	3442	3
3	3442	3
1	3443	3
2	3443	3
3	3443	3
1	3445	3
2	3445	3
3	3445	3
1	3446	3
2	3446	3
3	3446	3
1	3453	3
2	3453	3
3	3453	3
1	3459	3
2	3459	3
3	3459	3
1	3461	3
2	3461	3
3	3461	3
1	3464	3
2	3464	3
3	3464	3
1	3465	3
2	3465	3
3	3465	3
1	3467	3
2	3467	3
3	3467	3
1	3469	3
2	3469	3
3	3469	3
1	3470	3
2	3470	3
3	3470	3
1	3472	3
2	3472	3
3	3472	3
1	3474	3
2	3474	3
3	3474	3
1	3475	3
2	3475	3
3	3475	3
1	3481	3
2	3481	3
3	3481	3
1	3482	3
2	3482	3
3	3482	3
1	3484	3
2	3484	3
3	3484	3
1	3486	3
2	3486	3
3	3486	3
1	634	3
2	634	3
3	634	3
1	3346	3
2	3346	3
3	3346	3
1	3349	3
2	3349	3
3	3349	3
1	3356	3
2	3356	3
3	3356	3
1	3358	3
2	3358	3
3	3358	3
1	3363	3
2	3363	3
3	3363	3
1	1044	3
2	1044	3
3	1044	3
1	3364	3
2	3364	3
3	3364	3
1	3366	3
2	3366	3
3	3366	3
1	3367	3
2	3367	3
3	3367	3
1	3369	3
2	3369	3
3	3369	3
1	3370	3
2	3370	3
3	3370	3
1	3371	3
2	3371	3
3	3371	3
1	3372	3
2	3372	3
3	3372	3
1	3379	3
2	3379	3
3	3379	3
1	3380	3
2	3380	3
3	3380	3
1	3382	3
2	3382	3
3	3382	3
1	3383	3
2	3383	3
3	3383	3
1	3385	3
2	3385	3
3	3385	3
1	1654	3
2	1654	3
3	1654	3
1	3490	3
2	3490	3
3	3490	3
1	3494	3
2	3494	3
3	3494	3
1	3495	3
2	3495	3
3	3495	3
1	3499	3
2	3499	3
3	3499	3
1	3500	3
2	3500	3
3	3500	3
1	3501	3
2	3501	3
3	3501	3
1	3507	3
2	3507	3
3	3507	3
1	3509	3
2	3509	3
3	3509	3
1	3510	3
2	3510	3
3	3510	3
1	3516	3
2	3516	3
3	3516	3
1	3520	3
2	3520	3
3	3520	3
1	3521	3
2	3521	3
3	3521	3
1	3526	3
2	3526	3
3	3526	3
1	3531	3
2	3531	3
3	3531	3
1	3533	3
2	3533	3
3	3533	3
1	3535	3
2	3535	3
3	3535	3
1	3536	3
2	3536	3
3	3536	3
1	3538	3
2	3538	3
3	3538	3
1	3539	3
2	3539	3
3	3539	3
3	1131	3
1	1174	3
2	1174	3
3	1174	3
1	1191	3
2	1191	3
3	1191	3
1	315	3
2	315	3
3	315	3
1	639	3
2	639	3
3	639	3
1	333	3
2	333	3
3	333	3
1	401	3
2	401	3
3	401	3
1	1381	3
2	1381	3
3	1381	3
1	334	3
2	334	3
3	334	3
1	1059	3
2	1059	3
3	1059	3
1	646	3
2	646	3
3	646	3
1	996	3
2	996	3
3	996	3
1	616	3
2	616	3
3	616	3
1	673	3
2	673	3
3	673	3
1	1133	3
2	1133	3
3	1133	3
1	993	3
2	993	3
3	993	3
1	1318	3
2	1318	3
3	1318	3
1	809	3
2	809	3
3	809	3
1	1897	3
2	1897	3
3	1897	3
1	1710	3
2	1710	3
3	1710	3
1	1040	3
2	1040	3
3	1040	3
1	417	3
2	417	3
3	417	3
1	1023	3
2	1023	3
3	1023	3
1	521	3
2	521	3
3	521	3
1	782	3
2	782	3
3	782	3
1	640	3
2	640	3
3	640	3
1	674	3
2	674	3
3	674	3
1	1792	3
2	1792	3
3	1792	3
1	1742	3
2	1742	3
3	1742	3
1	1707	3
2	1707	3
3	1707	3
1	3388	3
2	3388	3
3	3388	3
1	3389	3
2	3389	3
3	3389	3
1	3394	3
2	3394	3
3	3394	3
1	2162	3
2	2162	3
3	2162	3
1	3397	3
2	3397	3
3	3397	3
1	3399	3
2	3399	3
3	3399	3
1	3400	3
2	3400	3
3	3400	3
1	3402	3
2	3402	3
3	3402	3
1	3405	3
2	3405	3
3	3405	3
1	3406	3
2	3406	3
3	3406	3
1	3407	3
2	3407	3
3	3407	3
1	3409	3
2	3409	3
3	3409	3
1	3410	3
2	3410	3
3	3410	3
1	3412	3
2	3412	3
3	3412	3
1	3413	3
2	3413	3
3	3413	3
1	3416	3
2	3416	3
3	3416	3
1	3417	3
2	3417	3
3	3417	3
1	3419	3
2	3419	3
3	3419	3
1	3421	3
2	3421	3
3	3421	3
1	3424	3
2	3424	3
3	3424	3
1	3425	3
2	3425	3
3	3425	3
1	3427	3
2	3427	3
3	3427	3
1	3428	3
4	998	1
5	998	1
6	998	1
7	998	1
8	998	1
9	998	1
2	3428	3
3	3428	3
1	2054	3
2	2054	3
3	3381	3
1	3384	3
4	980	1
5	980	1
6	980	1
2	3384	3
3	3384	3
1	3386	3
7	980	1
8	980	1
9	980	1
2	3386	3
3	3386	3
1	3387	3
2	3387	3
3	3387	3
1	3489	3
2	3489	3
3	3489	3
1	3491	3
2	3491	3
3	3491	3
1	3496	3
2	3496	3
4	1183	1
5	1183	1
6	1183	1
7	1183	1
8	1183	1
3	3496	3
1	3497	3
2	3497	3
3	3497	3
1	3502	3
2	3502	3
3	3502	3
1	3503	3
2	3503	3
9	1183	1
3	3503	3
1	3504	3
2	3504	3
3	3504	3
1	3508	3
2	3508	3
4	734	1
5	734	1
6	734	1
7	734	1
8	734	1
9	734	1
3	3508	3
1	3511	3
2	3511	3
3	3511	3
1	3512	3
2	3512	3
4	2179	1
5	2179	1
3	3512	3
1	3514	3
2	3514	3
6	2179	1
7	2179	1
8	2179	1
9	2179	1
3	3514	3
1	3517	3
2	3517	3
3	3517	3
1	3518	3
2	3518	3
4	1898	1
5	1898	1
6	1898	1
7	1898	1
8	1898	1
9	1898	1
3	3518	3
1	3519	3
2	3519	3
3	3519	3
1	3522	3
2	3522	3
4	3392	1
5	3392	1
6	3392	1
7	3392	1
8	3392	1
9	3392	1
3	3522	3
1	3523	3
2	3523	3
3	3523	3
1	2569	3
2	2569	3
4	3398	1
5	3398	1
6	3398	1
7	3398	1
8	3398	1
9	3398	1
3	2569	3
1	3525	3
2	3525	3
3	3525	3
1	3527	3
2	3527	3
4	3411	1
5	3411	1
6	3411	1
7	3411	1
8	3411	1
9	3411	1
3	3527	3
1	3528	3
2	3528	3
3	3528	3
1	3529	3
2	3529	3
3	3529	3
1	3537	3
2	3537	3
3	3537	3
1	307	3
2	307	3
4	3414	1
5	3414	1
6	3414	1
7	3414	1
8	3414	1
9	3414	1
3	307	3
1	3540	3
2	3540	3
3	3540	3
1	3541	3
2	3541	3
4	3420	1
5	3420	1
6	3420	1
7	3420	1
8	3420	1
9	3420	1
3	3541	3
1	3543	3
2	3543	3
3	3543	3
1	1554	3
2	1554	3
4	3422	1
5	3422	1
6	3422	1
7	3422	1
8	3422	1
9	3422	1
4	3456	1
5	3456	1
6	3456	1
7	3456	1
8	3456	1
9	3456	1
3	1554	3
1	3567	3
2	3567	3
3	3567	3
1	3580	3
2	3580	3
3	3580	3
1	3582	3
2	3582	3
3	3582	3
1	3583	3
2	3583	3
3	3583	3
1	3587	3
2	3587	3
3	3587	3
1	632	3
2	632	3
3	632	3
1	325	3
2	325	3
3	325	3
1	1097	3
2	1097	3
3	1097	3
1	323	3
2	323	3
3	323	3
1	1917	3
2	1917	3
3	1917	3
1	1033	3
2	1033	3
3	1033	3
1	1052	3
2	1052	3
3	1052	3
1	694	3
2	694	3
3	694	3
1	398	3
2	398	3
3	398	3
1	424	3
2	424	3
3	424	3
1	625	3
2	625	3
3	625	3
1	1131	3
2	1131	3
3	3477	3
1	3478	3
2	3478	3
3	3478	3
1	3479	3
2	3479	3
12	3456	2
1	3457	3
2	3457	3
3	3457	3
4	3457	1
5	3457	1
6	3457	1
7	3457	1
8	3457	1
9	3457	1
10	3457	2
11	3457	2
12	3457	2
1	3458	3
2	3458	3
3	3458	3
4	3458	1
5	3458	1
6	3458	1
3	3479	3
1	3480	3
2	3480	3
3	3480	3
1	3488	3
2	3488	3
3	3488	3
1	3545	3
2	3545	3
3	3545	3
1	2635	3
2	2635	3
7	3458	1
8	3458	1
9	3458	1
10	3458	2
11	3458	2
12	3458	2
1	3460	3
2	3460	3
3	3460	3
4	3460	1
5	3460	1
6	3460	1
7	3460	1
8	3460	1
9	3460	1
10	3460	2
11	3460	2
12	3460	2
1	3462	3
2	3462	3
3	3462	3
4	3462	1
5	3462	1
6	3462	1
7	3462	1
8	3462	1
9	3462	1
10	3462	2
11	3462	2
12	3462	2
1	3463	3
2	3463	3
3	3463	3
4	3463	1
5	3463	1
6	3463	1
7	3463	1
8	3463	1
9	3463	1
10	3463	2
11	3463	2
12	3463	2
3	2635	3
1	299	3
2	299	3
3	299	3
1	3552	3
2	3552	3
3	3552	3
1	3556	3
2	3556	3
3	3556	3
1	3560	3
2	3560	3
1	3466	3
2	3466	3
3	3466	3
4	3466	1
5	3466	1
6	3466	1
3	3560	3
1	689	3
7	3466	1
8	3466	1
9	3466	1
10	3466	2
11	3466	2
12	3466	2
1	3468	3
2	3468	3
3	3468	3
4	3468	1
5	3468	1
6	3468	1
7	3468	1
8	3468	1
9	3468	1
10	3468	2
11	3468	2
12	3468	2
1	3471	3
2	3471	3
3	3471	3
4	3471	1
5	3471	1
6	3471	1
7	3471	1
8	3471	1
9	3471	1
10	3471	2
11	3471	2
12	3471	2
1	3473	3
2	689	3
3	689	3
1	1086	3
2	1086	3
3	1086	3
1	1152	3
4	3423	1
5	3423	1
6	3423	1
7	3423	1
8	3423	1
9	3423	1
2	1152	3
3	1152	3
1	817	3
2	817	3
3	817	3
1	1018	3
4	3451	1
5	3451	1
6	3451	1
7	3451	1
8	3451	1
9	3451	1
2	1018	3
3	1018	3
1	624	3
2	624	3
3	624	3
1	672	3
4	3455	1
5	3455	1
6	3455	1
7	3455	1
8	3455	1
9	3455	1
2	672	3
3	672	3
1	1099	3
2	1099	3
3	1099	3
1	767	3
4	3476	1
5	3476	1
6	3476	1
7	3476	1
2	767	3
3	767	3
8	3476	1
9	3476	1
1	1096	3
2	1096	3
3	1096	3
1	929	3
2	929	3
3	929	3
4	3483	1
5	3483	1
6	3483	1
7	3483	1
8	3483	1
9	3483	1
1	1109	3
2	1109	3
3	1109	3
1	934	3
2	934	3
3	934	3
4	3485	1
5	3485	1
6	3485	1
7	3485	1
8	3485	1
9	3485	1
1	1416	3
2	1416	3
3	1416	3
1	297	3
2	297	3
3	297	3
4	3487	1
5	3487	1
6	3487	1
7	3487	1
8	3487	1
9	3487	1
1	812	3
2	812	3
3	812	3
1	1167	3
2	1167	3
3	1167	3
4	3345	1
5	3345	1
6	3345	1
7	3345	1
8	3345	1
9	3345	1
1	588	3
2	588	3
3	588	3
1	626	3
2	626	3
3	626	3
4	3351	1
5	3351	1
6	3351	1
7	3351	1
8	3351	1
9	3351	1
1	523	3
2	523	3
3	523	3
1	1095	3
2	1095	3
3	1095	3
4	3357	1
5	3357	1
6	3357	1
7	3357	1
8	3357	1
9	3357	1
1	590	3
2	590	3
3	590	3
1	2245	3
2	2245	3
3	2245	3
4	3359	1
5	3359	1
6	3359	1
7	3359	1
8	3359	1
9	3359	1
1	1602	3
2	1602	3
3	1602	3
1	305	3
2	305	3
3	305	3
4	3360	1
5	3360	1
6	3360	1
7	3360	1
8	3360	1
9	3360	1
1	3347	3
2	3347	3
3	3347	3
1	3344	3
2	3344	3
3	3344	3
4	3361	1
5	3361	1
6	3361	1
7	3361	1
8	3361	1
9	3361	1
1	3350	3
2	3350	3
3	3350	3
1	3348	3
2	3348	3
3	3348	3
4	3365	1
5	3365	1
6	3365	1
7	3365	1
8	3365	1
9	3365	1
1	3352	3
2	3352	3
3	3352	3
1	3353	3
2	3353	3
3	3353	3
4	3368	1
5	3368	1
6	3368	1
7	3368	1
8	3368	1
9	3368	1
1	3354	3
2	3354	3
3	3354	3
1	3355	3
2	3355	3
3	3355	3
4	3376	1
5	3376	1
6	3376	1
7	3376	1
8	3376	1
9	3376	1
1	3362	3
2	3362	3
3	3362	3
1	3373	3
2	3373	3
3	3373	3
4	3492	1
5	3492	1
6	3492	1
7	3492	1
8	3492	1
9	3492	1
1	3374	3
2	3374	3
3	3374	3
1	3375	3
2	3375	3
3	3375	3
1	3378	3
4	3493	1
5	3493	1
6	3493	1
7	3493	1
8	3493	1
9	3493	1
2	3378	3
3	3378	3
1	3381	3
2	3381	3
10	1001	2
11	1001	2
12	1001	2
1	998	3
2	998	3
4	3498	1
5	3498	1
6	3498	1
7	3498	1
8	3498	1
9	3498	1
3	998	3
1	980	3
2	980	3
3	980	3
1	1183	3
2	1183	3
4	3505	1
5	3505	1
6	3505	1
7	3505	1
8	3505	1
9	3505	1
3	1183	3
1	734	3
2	734	3
3	734	3
1	2179	3
2	2179	3
4	3506	1
5	3506	1
6	3506	1
7	3506	1
8	3506	1
9	3506	1
3	2179	3
1	1898	3
2	1898	3
3	1898	3
1	3392	3
2	3392	3
4	3513	1
5	3513	1
6	3513	1
7	3513	1
8	3513	1
9	3513	1
3	3392	3
1	3398	3
2	3398	3
3	3398	3
1	3411	3
2	3411	3
4	3515	1
5	3515	1
6	3515	1
7	3515	1
8	3515	1
9	3515	1
3	3411	3
1	3414	3
2	3414	3
3	3414	3
1	3420	3
2	3420	3
4	2464	1
5	2464	1
6	2464	1
7	2464	1
8	2464	1
9	2464	1
3	3420	3
1	3422	3
2	3422	3
3	3422	3
1	3456	3
2	3456	3
4	3524	1
5	3524	1
6	3524	1
7	3524	1
8	3524	1
9	3524	1
3	3456	3
1	3423	3
2	3423	3
3	3423	3
1	3451	3
2	3451	3
4	3530	1
5	3530	1
6	3530	1
7	3530	1
8	3530	1
9	3530	1
3	3451	3
1	3455	3
2	3455	3
3	3455	3
1	3476	3
2	3476	3
4	3532	1
5	3532	1
6	3532	1
7	3532	1
8	3532	1
9	3532	1
3	3476	3
1	3483	3
2	3483	3
3	3483	3
1	3485	3
2	3485	3
4	3534	1
5	3534	1
6	3534	1
7	3534	1
8	3534	1
9	3534	1
3	3485	3
1	3487	3
2	3487	3
3	3487	3
1	3345	3
2	3345	3
4	3542	1
5	3542	1
6	3542	1
7	3542	1
8	3542	1
9	3542	1
3	3345	3
1	3351	3
2	3351	3
3	3351	3
1	3357	3
2	3357	3
4	3546	1
5	3546	1
6	3546	1
7	3546	1
8	3546	1
9	3546	1
10	3546	2
11	3546	2
12	3546	2
1	3549	3
2	3549	3
3	3549	3
4	3549	1
5	3549	1
6	3549	1
7	3549	1
8	3549	1
9	3549	1
10	3549	2
11	3549	2
12	3549	2
1	3554	3
2	3554	3
3	3554	3
4	3554	1
5	3554	1
6	3554	1
7	3554	1
8	3554	1
9	3554	1
10	3554	2
11	3554	2
12	3554	2
1	1648	3
2	1648	3
3	1648	3
4	1648	1
5	1648	1
6	1648	1
7	1648	1
8	1648	1
9	1648	1
10	1648	2
11	1648	2
12	1648	2
1	3568	3
2	3568	3
3	3568	3
4	3568	1
5	3568	1
6	3568	1
7	3568	1
8	3568	1
9	3568	1
10	3568	2
11	3568	2
12	3568	2
1	1179	3
2	1179	3
3	3357	3
4	1179	1
5	1179	1
6	1179	1
7	1179	1
8	1179	1
9	1179	1
10	1179	2
11	1179	2
12	1179	2
1	3359	3
2	3359	3
3	3359	3
4	1042	1
5	1042	1
6	1042	1
7	1042	1
8	1042	1
9	1042	1
10	1042	2
11	1042	2
12	1042	2
1	3360	3
2	3360	3
3	3360	3
4	1196	1
5	1196	1
6	1196	1
7	1196	1
8	1196	1
9	1196	1
10	1196	2
11	1196	2
12	1196	2
1	3361	3
2	3361	3
3	3361	3
4	443	1
5	443	1
6	443	1
7	443	1
8	443	1
9	443	1
10	443	2
11	443	2
12	443	2
1	3365	3
2	3365	3
3	3365	3
4	1079	1
5	1079	1
6	1079	1
7	1079	1
8	1079	1
9	1079	1
10	1079	2
1	3368	3
2	3368	3
3	3368	3
11	1079	2
12	1079	2
1	3376	3
2	3376	3
3	3376	3
4	2630	1
5	2630	1
6	2630	1
7	2630	1
1	3492	3
2	3492	3
8	2630	1
9	2630	1
10	2630	2
11	2630	2
12	2630	2
3	3492	3
1	3493	3
2	3493	3
3	3493	3
1	3498	3
2	3498	3
3	3498	3
1	3505	3
2	3505	3
3	3505	3
1	3506	3
2	3506	3
3	3506	3
1	3513	3
2	3513	3
3	3513	3
1	3515	3
2	3515	3
3	3515	3
1	2464	3
2	2464	3
3	2464	3
1	3524	3
2	3524	3
3	3524	3
1	3530	3
2	3530	3
3	3530	3
1	3532	3
2	3532	3
3	3532	3
1	3534	3
2	3534	3
3	3534	3
1	3542	3
2	3542	3
3	3542	3
1	3546	3
2	3546	3
3	3546	3
3	1179	3
1	1042	3
2	1042	3
3	1042	3
1	1196	3
2	1196	3
3	1196	3
1	443	3
2	443	3
3	443	3
1	1079	3
2	1079	3
3	1079	3
1	2630	3
2	2630	3
10	998	2
3	2630	3
2	3473	3
11	998	2
12	998	2
10	980	2
11	980	2
12	980	2
10	1183	2
11	1183	2
12	1183	2
10	734	2
3	3473	3
1	3477	3
11	734	2
12	734	2
10	2179	2
11	2179	2
12	2179	2
10	1898	2
11	1898	2
12	1898	2
10	3392	2
11	3392	2
12	3392	2
10	3398	2
11	3398	2
12	3398	2
10	3411	2
2	3477	3
11	3538	2
11	3411	2
12	3411	2
10	3414	2
11	3414	2
12	3414	2
10	3420	2
11	3420	2
12	3420	2
12	3454	2
10	3456	2
11	3456	2
10	3422	2
11	3422	2
12	3422	2
10	3423	2
11	3423	2
12	3423	2
10	3451	2
11	3451	2
12	3451	2
10	3455	2
11	3455	2
12	3455	2
10	3476	2
11	3476	2
12	3476	2
10	3483	2
11	3483	2
12	3483	2
10	3485	2
11	3485	2
12	3485	2
10	3487	2
11	3487	2
12	3487	2
10	3345	2
11	3345	2
12	3345	2
10	3351	2
11	3351	2
12	3351	2
10	3357	2
11	3357	2
12	3357	2
10	3359	2
11	3359	2
12	3359	2
10	3360	2
11	3360	2
12	3360	2
10	3361	2
11	3361	2
12	3361	2
10	3365	2
11	3365	2
12	3365	2
10	3368	2
11	3368	2
12	3368	2
10	3376	2
11	3376	2
12	3376	2
10	3492	2
11	3492	2
12	3492	2
10	3493	2
11	3493	2
12	3493	2
10	3498	2
11	3498	2
12	3498	2
10	3505	2
11	3505	2
12	3505	2
10	3506	2
11	3506	2
12	3506	2
10	3513	2
11	3513	2
12	3513	2
10	3515	2
11	3515	2
12	3515	2
10	2464	2
11	2464	2
12	2464	2
10	3524	2
11	3524	2
12	3524	2
10	3530	2
11	3530	2
12	3530	2
10	3532	2
11	3532	2
12	3532	2
10	3534	2
11	3534	2
12	3534	2
10	3542	2
11	3542	2
12	3542	2
10	3480	2
11	3480	2
12	3480	2
10	3488	2
11	3488	2
12	3488	2
10	3545	2
11	3545	2
12	3545	2
10	2635	2
11	2635	2
12	2635	2
10	299	2
11	299	2
12	299	2
10	3552	2
11	3552	2
12	3552	2
10	3556	2
11	3556	2
12	3556	2
10	3560	2
11	3560	2
12	3560	2
10	689	2
11	689	2
12	689	2
10	1086	2
11	1086	2
12	1086	2
10	929	2
11	929	2
12	929	2
10	1109	2
11	1109	2
12	1109	2
10	934	2
11	934	2
12	934	2
10	1416	2
11	1416	2
12	1416	2
10	297	2
11	297	2
12	297	2
10	812	2
11	812	2
12	523	2
10	1095	2
11	1095	2
12	1095	2
12	3538	2
10	3539	2
11	3539	2
12	3539	2
10	590	2
11	590	2
12	590	2
10	2245	2
11	2245	2
12	2245	2
10	1602	2
11	1602	2
12	1602	2
10	305	2
11	305	2
12	305	2
10	3347	2
11	3347	2
12	3347	2
10	3344	2
11	3344	2
12	3344	2
10	3350	2
11	3350	2
12	3350	2
10	3348	2
11	3348	2
12	3348	2
10	3352	2
11	3352	2
12	3352	2
10	3373	2
11	3373	2
12	3373	2
10	3374	2
11	3374	2
12	3374	2
10	3375	2
11	3375	2
12	3375	2
10	3378	2
11	3378	2
12	3378	2
10	3381	2
11	3381	2
12	3381	2
10	3384	2
11	3384	2
12	3384	2
10	3386	2
11	3386	2
12	3386	2
10	3387	2
11	3387	2
12	3387	2
10	3489	2
11	3489	2
12	3489	2
10	3491	2
11	3491	2
12	3491	2
10	3514	2
11	3514	2
12	3514	2
10	3517	2
11	3517	2
12	3517	2
10	3518	2
11	3518	2
12	3518	2
10	3519	2
11	3519	2
12	3519	2
10	3522	2
11	3522	2
12	3522	2
10	3523	2
11	3523	2
10	758	2
11	758	2
12	3523	2
10	3529	2
11	3529	2
12	3529	2
10	3537	2
11	3537	2
12	3537	2
10	307	2
11	307	2
12	307	2
10	3540	2
11	3540	2
12	3540	2
10	3541	2
11	3541	2
12	3541	2
10	3543	2
11	3543	2
12	3543	2
10	1554	2
11	1554	2
12	1554	2
10	3567	2
11	3567	2
12	3567	2
10	3580	2
11	3580	2
12	3580	2
10	3582	2
11	3582	2
12	3582	2
10	1097	2
11	1097	2
12	1097	2
12	758	2
10	3544	2
11	3544	2
12	3544	2
10	1063	2
11	1063	2
12	1063	2
10	3547	2
11	3547	2
12	3547	2
10	3548	2
11	3548	2
10	323	2
11	323	2
12	323	2
10	1917	2
11	1917	2
12	1917	2
10	1033	2
11	1033	2
12	1033	2
10	1052	2
11	1052	2
12	1052	2
10	694	2
11	694	2
12	694	2
10	398	2
11	398	2
12	398	2
10	424	2
11	424	2
12	424	2
10	625	2
11	625	2
12	625	2
10	1131	2
11	1131	2
12	1131	2
10	1174	2
11	1174	2
12	1174	2
10	1191	2
11	1191	2
12	1191	2
10	315	2
11	315	2
12	315	2
12	3548	2
10	3550	2
11	3550	2
12	3550	2
10	3551	2
11	3551	2
12	3551	2
10	3553	2
10	639	2
11	639	2
12	639	2
10	333	2
11	333	2
12	333	2
10	401	2
11	401	2
12	401	2
10	1381	2
11	1381	2
12	1381	2
10	334	2
11	334	2
12	334	2
10	1059	2
11	1059	2
12	1059	2
10	646	2
11	646	2
12	646	2
10	996	2
11	996	2
12	996	2
10	616	2
11	616	2
12	616	2
10	673	2
11	673	2
12	673	2
10	1133	2
11	1133	2
12	1133	2
10	993	2
11	993	2
12	993	2
10	1318	2
11	1318	2
12	1318	2
10	809	2
11	809	2
12	809	2
10	1897	2
11	1897	2
12	1897	2
10	1710	2
11	3553	2
12	3553	2
10	3555	2
11	3555	2
12	3555	2
10	3557	2
11	3557	2
12	3557	2
10	3558	2
11	3558	2
12	3558	2
10	3559	2
11	3559	2
12	3559	2
10	631	2
11	631	2
12	631	2
10	449	2
11	449	2
12	449	2
10	1021	2
11	1021	2
12	1021	2
10	677	2
11	1710	2
12	1710	2
10	1040	2
11	1040	2
12	1040	2
10	417	2
11	417	2
12	417	2
10	1023	2
11	1023	2
12	1023	2
10	521	2
11	521	2
12	521	2
10	782	2
11	782	2
12	782	2
10	640	2
11	640	2
12	640	2
10	674	2
11	674	2
12	674	2
10	1792	2
11	1792	2
12	1792	2
10	1742	2
11	1742	2
12	1742	2
10	1707	2
11	1707	2
12	1707	2
10	3388	2
11	3388	2
12	3388	2
10	3389	2
11	3389	2
12	3389	2
10	3394	2
11	3394	2
12	3394	2
10	2162	2
11	2162	2
12	2162	2
10	3397	2
11	3397	2
12	3397	2
10	3399	2
11	3399	2
12	3399	2
10	3400	2
11	3400	2
12	3400	2
10	3402	2
11	3402	2
12	3402	2
10	3405	2
11	3405	2
12	3405	2
10	3406	2
11	3406	2
12	3406	2
10	3407	2
11	3407	2
12	3407	2
10	3409	2
11	3409	2
12	3409	2
10	3410	2
11	3410	2
12	3410	2
10	3412	2
11	3412	2
12	3412	2
10	3413	2
11	3413	2
12	3413	2
10	3416	2
11	3416	2
12	3416	2
10	3417	2
11	3417	2
12	3417	2
10	3419	2
11	3419	2
12	3419	2
10	3421	2
11	3421	2
12	3421	2
10	3424	2
11	3424	2
12	3424	2
10	3425	2
11	3425	2
12	3425	2
10	3427	2
11	3427	2
12	3427	2
10	3428	2
11	3428	2
12	3428	2
10	2054	2
11	2054	2
12	2054	2
10	3434	2
11	3434	2
12	3434	2
10	3438	2
11	3438	2
12	3438	2
10	3442	2
11	3442	2
12	3442	2
10	3443	2
11	3443	2
12	3443	2
10	3445	2
11	3445	2
12	3445	2
10	3446	2
11	3446	2
12	3446	2
10	3453	2
11	3453	2
12	3453	2
10	3459	2
11	3459	2
12	3459	2
10	3461	2
11	3461	2
12	3461	2
10	3464	2
11	3464	2
12	3464	2
10	3465	2
11	3465	2
12	3465	2
10	3467	2
11	3467	2
12	3467	2
10	3469	2
11	3469	2
12	3469	2
10	3470	2
11	3470	2
12	3470	2
10	3472	2
11	3472	2
12	3472	2
10	3474	2
11	3474	2
12	3474	2
10	3475	2
11	3475	2
12	3475	2
10	3481	2
11	3481	2
12	3481	2
10	3482	2
11	3482	2
12	3482	2
10	3484	2
11	3484	2
12	3484	2
10	3486	2
11	3486	2
12	3486	2
10	634	2
11	634	2
12	634	2
10	3346	2
11	3346	2
12	3346	2
10	3349	2
11	3349	2
12	3349	2
10	3356	2
11	3356	2
12	3356	2
10	3358	2
11	3358	2
12	3358	2
10	3363	2
11	3363	2
12	3363	2
10	1044	2
11	1044	2
12	1044	2
10	3364	2
11	3364	2
12	3364	2
10	3366	2
11	3366	2
12	3366	2
10	3367	2
11	3367	2
12	3367	2
10	3369	2
11	3369	2
12	3369	2
11	677	2
12	677	2
10	3370	2
11	3370	2
12	3370	2
10	3371	2
11	3371	2
12	3371	2
10	1140	2
11	1140	2
12	1140	2
10	3372	2
11	3372	2
12	3372	2
10	3379	2
11	3379	2
12	3379	2
10	3380	2
11	3380	2
12	3380	2
10	3382	2
11	3382	2
12	3382	2
10	3383	2
11	3383	2
12	3383	2
10	3385	2
11	3385	2
12	3385	2
10	1654	2
11	1654	2
12	1654	2
10	3490	2
11	3490	2
12	3490	2
10	3494	2
11	3494	2
12	3494	2
10	3495	2
11	3495	2
12	3495	2
10	3499	2
11	3499	2
10	1438	2
11	1438	2
12	1438	2
10	3565	2
12	3499	2
10	3500	2
11	3500	2
12	3500	2
10	3501	2
11	3501	2
12	3501	2
10	3507	2
11	3507	2
12	3507	2
10	3509	2
11	3509	2
12	3509	2
10	3510	2
11	3510	2
12	3510	2
10	3516	2
11	3516	2
12	3516	2
10	3520	2
11	3520	2
12	3520	2
10	3521	2
11	3521	2
12	3521	2
10	3526	2
11	3526	2
12	3526	2
10	3531	2
11	3531	2
12	3531	2
10	3533	2
11	3533	2
12	3533	2
10	3535	2
11	3535	2
12	3535	2
11	3565	2
12	3565	2
10	444	2
11	444	2
10	3536	2
11	3536	2
12	3536	2
10	3538	2
12	444	2
10	3566	2
11	3566	2
12	3566	2
10	3569	2
11	3569	2
12	3569	2
10	3570	2
11	3570	2
12	3570	2
10	3571	2
11	3571	2
12	3571	2
10	3572	2
11	3572	2
12	3572	2
10	3573	2
11	3573	2
12	3573	2
10	3574	2
11	3574	2
12	3574	2
10	3575	2
11	3575	2
12	3575	2
10	3576	2
11	3576	2
12	3576	2
10	3577	2
11	3577	2
12	3577	2
10	3578	2
11	3578	2
12	3578	2
10	3579	2
11	3579	2
12	3579	2
10	3581	2
11	3581	2
12	3581	2
10	3584	2
11	3584	2
12	3584	2
10	3585	2
11	3585	2
12	3585	2
10	3586	2
11	3586	2
12	3586	2
10	3588	2
11	3588	2
12	3588	2
10	3589	2
11	3589	2
12	3589	2
10	3590	2
11	3590	2
12	3590	2
10	3591	2
11	3591	2
12	3591	2
10	3592	2
11	3592	2
12	3592	2
10	408	2
11	408	2
12	408	2
10	1414	2
11	1414	2
12	1414	2
10	973	2
11	973	2
12	973	2
10	1151	2
11	1151	2
12	1151	2
10	1002	2
11	1002	2
12	1002	2
10	837	2
11	837	2
12	837	2
10	432	2
11	432	2
12	432	2
10	1064	2
11	1064	2
12	1064	2
10	425	2
11	425	2
12	425	2
10	824	2
11	824	2
12	824	2
10	1134	2
11	1134	2
12	1134	2
10	467	2
11	467	2
12	467	2
10	1022	2
11	1022	2
12	1022	2
10	1124	2
11	1124	2
12	1124	2
10	762	2
11	762	2
12	762	2
\.


--
-- TOC entry 2070 (class 0 OID 32817075)
-- Dependencies: 170
-- Data for Name: armario; Type: TABLE DATA; Schema: armario; Owner: comsolid
--

COPY armario (id_armario, nome) FROM stdin;
46	Armário 01
47	Armário 02
48	Armário 03
49	Armário 04
50	Armário 05
51	Armário 06
52	Armário 07
53	Armário 08
54	Armário 09
55	Armário 10
56	Armário 11
57	Armário 12
58	Armário 13
59	Armário 14
60	Armário 15
61	Armário 16
62	Armário 17
63	Armário 18
64	Armário 19
65	Armário 20
67	Armário 22
68	Armário 23
69	Armário 24
70	Armário 25
71	Armário 26
72	Armário 27
73	Armário 28
74	Armário 29
75	Armário 30
76	Armário 31
77	Armário 32
78	Armário 33
79	Armário 34
80	Armário 35
\.


--
-- TOC entry 2071 (class 0 OID 32817081)
-- Dependencies: 171
-- Data for Name: armario_individual; Type: TABLE DATA; Schema: armario; Owner: comsolid
--

COPY armario_individual (id_armario, id_posicao_armario, id_pessoa, codigo_chave) FROM stdin;
56	4	3520	2078
77	4	312	887
78	4	3582	1707
57	4	762	1792
77	5	3543	844
62	4	694	1563
63	4	1152	1766
55	11	3525	1742
64	4	3347	1683
46	4	588	757
46	5	3374	1600
78	5	3426	1530
77	6	3353	822
56	11	305	1903
46	6	3485	754
65	4	3415	1533
62	11	3358	1553
67	4	3350	1595
56	5	3575	1975
57	5	3472	1561
62	5	837	1719
63	5	3446	2063
64	5	1033	1667
65	5	625	1776
67	5	3454	1722
56	6	323	2036
62	6	2245	1598
63	6	3513	1516
64	6	3366	1686
67	6	3452	1747
46	7	677	779
55	7	3584	1677
56	7	3378	1917
62	7	3449	1566
63	7	1043	1944
64	7	3588	1671
65	7	3397	1571
67	7	3589	1771
46	8	3511	759
55	8	1096	1703
56	8	3408	1997
62	8	3345	1528
63	8	3420	1999
64	8	3567	1669
65	8	3401	1790
67	8	3517	1713
46	9	1183	1760
55	9	3373	1676
56	9	3422	2064
62	9	1064	1565
63	9	616	1546
64	9	3396	1674
65	9	689	1518
67	9	3346	1562
55	10	3447	1672
56	10	3371	1923
57	10	3448	1605
58	10	425	1796
61	10	3531	1537
62	10	3497	1560
63	11	1792	1522
63	10	3493	1950
64	10	333	1745
65	10	3365	1529
67	10	3578	1510
64	11	1167	1654
65	11	3537	1585
67	11	3532	1728
55	12	3431	1651
56	12	3566	2079
62	12	3565	1782
63	12	2054	1578
78	6	3524	1609
62	3	\N	1615
64	12	2635	1670
65	12	3457	1761
67	12	973	1589
46	1	325	1724
49	1	1200	1601
53	1	3498	1739
56	1	3551	1850
77	7	929	896
78	7	3354	1597
77	8	3580	778
57	1	639	1755
78	8	3387	1700
63	3	\N	1520
63	1	3469	1720
64	1	634	1655
65	1	3453	1730
67	1	3464	1718
68	1	673	1505
46	2	1191	756
56	2	3381	1891
77	9	824	787
78	9	3399	1545
77	10	3384	855
57	2	3404	1798
78	10	3389	1611
64	3	\N	1772
62	2	3480	1791
63	2	3539	2085
64	2	3481	1661
65	2	3477	1715
67	2	1898	1732
68	2	3400	2128
77	2	\N	1717
77	3	\N	827
77	11	3556	859
77	12	3554	838
78	1	3410	1712
65	3	\N	1740
78	2	\N	1688
78	3	\N	1778
46	3	3344	1729
76	10	3479	1775
80	10	3445	1673
46	11	449	1696
47	11	3501	1787
48	11	809	1649
49	11	3496	1631
50	4	3385	867
51	4	3352	1995
80	2	\N	1764
80	3	\N	1682
50	11	1414	870
51	11	590	2003
57	11	3442	1640
58	11	3482	1773
75	11	3487	770
76	11	3364	771
52	4	1140	760
58	4	3489	1734
59	4	3367	1581
67	3	\N	1618
76	4	523	1762
80	4	2464	1680
49	5	443	1620
50	5	3526	853
51	5	1554	1988
52	5	3507	1612
58	5	3483	1550
59	5	2569	1517
76	5	3359	1751
80	5	646	1690
49	6	3351	1619
50	6	424	848
51	6	3492	2070
52	6	3519	1596
58	6	334	1642
59	6	817	1767
76	6	1151	753
80	6	307	1664
47	7	1602	1779
48	7	1002	751
49	7	3506	1784
80	11	626	1705
47	3	\N	1641
50	7	1022	861
51	7	3530	1969
46	12	3527	1586
47	12	3398	1749
48	12	3473	1644
49	12	3592	1628
48	3	\N	766
52	7	1318	1754
58	7	3388	1783
50	12	3515	880
51	12	734	1936
50	3	\N	852
57	12	3355	1636
58	12	1059	1632
75	12	3512	1799
76	12	1742	762
80	12	1097	1656
48	1	3360	1645
56	3	\N	1879
57	3	\N	1723
68	10	3435	1515
69	10	1901	1504
70	10	3414	1902
50	1	3412	845
71	3	\N	2062
71	10	3572	2057
72	10	3490	2038
73	10	3392	885
74	10	3545	883
75	10	3550	1758
79	10	1023	1580
61	11	682	1577
51	3	\N	2134
51	1	3363	1981
52	1	1001	857
58	1	3576	1726
59	1	417	1591
72	3	\N	1866
68	11	3439	1547
69	11	3460	1501
70	11	1021	1901
71	11	3418	1916
72	11	444	1894
73	11	3488	841
76	1	3455	1731
77	1	3523	899
47	2	1897	1748
52	3	\N	761
48	2	3535	777
73	3	\N	847
74	11	632	866
78	11	3369	1800
79	11	3529	1576
61	12	1044	1593
68	12	1381	1514
69	12	674	1526
49	2	3548	1630
50	2	1132	851
70	12	1416	1811
71	12	467	1873
72	12	398	1899
73	12	3395	806
74	12	3484	876
78	12	1042	1770
51	2	767	2058
52	2	3475	773
58	2	521	1603
59	2	3427	1554
58	3	\N	1531
59	3	\N	1606
79	12	3405	1568
62	1	996	1582
69	1	3571	1555
70	1	812	1934
71	1	3470	1994
72	1	3538	1953
73	1	3553	772
59	7	3583	1538
76	7	1648	1614
49	3	\N	1635
80	7	3458	1704
47	8	3441	1699
48	8	3419	1638
74	1	3443	790
75	1	3587	1625
79	1	672	1549
80	1	3509	1702
69	2	3432	1523
70	2	3581	2185
71	2	3579	2066
49	8	3380	1646
50	8	3478	863
51	8	3586	1910
52	8	3491	1629
57	8	1052	1637
47	1	3394	1786
47	4	3500	1756
47	5	3540	1797
47	6	3372	1785
74	3	\N	843
72	2	1099	1911
73	2	3409	1650
74	2	3569	889
48	4	3546	1681
48	5	758	1709
48	6	1174	1687
49	4	1654	1544
58	8	3383	1795
59	8	3504	1541
76	2	\N	776
76	3	\N	755
76	8	3425	758
80	8	3533	1675
47	9	408	1659
48	9	432	752
49	9	3356	1633
50	9	3413	882
51	9	934	1983
57	9	624	1542
58	9	3379	1639
59	9	3429	1588
76	9	1100	769
80	9	3411	1666
46	10	3406	1647
47	10	3502	1657
48	10	980	768
49	10	3393	1765
53	3	\N	1735
50	10	1710	860
51	10	2179	2045
52	11	998	774
53	11	1179	1788
68	3	\N	1567
69	3	\N	1519
70	3	\N	1986
53	4	3375	1753
68	4	297	1524
69	4	1026	1521
70	4	315	1881
71	4	3440	2083
72	4	3590	1957
73	4	3391	1627
74	4	3486	897
75	4	3451	780
79	4	1121	1559
53	5	3463	1710
68	5	3505	2073
69	5	3467	1507
70	5	3474	1962
71	5	3402	1887
72	5	3456	1898
73	5	3521	775
74	5	2630	894
75	5	3591	767
79	5	3534	1552
53	6	3403	1727
65	6	697	1769
68	6	3461	1536
69	6	3503	1543
70	6	3362	1847
71	6	3386	2017
72	6	782	2076
73	6	3437	811
74	6	1438	881
75	6	3547	1622
79	6	299	1512
53	7	3570	1794
57	7	3459	1613
75	2	\N	1685
75	3	\N	765
68	7	3348	1564
69	7	2162	1527
70	7	3433	2088
71	7	640	1966
72	7	3376	1893
73	7	3552	864
74	7	3349	873
75	7	1109	1752
79	7	3510	1575
68	8	3357	1964
69	8	3424	1503
70	8	1131	2084
71	8	3368	2141
72	8	993	1925
73	8	3468	782
74	8	3559	872
79	2	\N	1513
79	3	\N	1573
75	8	3423	1648
79	8	3544	1557
61	9	3390	1569
68	9	1133	1508
69	9	1040	1511
70	9	3471	2077
71	9	1095	2080
72	9	1124	2071
73	9	3558	788
74	9	3522	871
75	9	3541	764
79	9	3434	1540
60	3	\N	1660
54	11	3516	1579
59	11	3560	1599
60	11	3382	1679
52	12	3518	1634
53	12	1086	1711
54	12	3536	1624
59	12	3370	1572
60	12	3462	1693
54	1	3568	1789
55	1	3514	1668
60	1	3361	1652
61	1	1134	1535
53	2	1063	1701
54	2	3555	1616
55	2	1079	1694
60	2	3430	1653
61	2	3476	1509
54	4	3499	1741
55	4	3450	1706
60	4	3573	1689
61	4	3528	1551
54	5	3542	1574
55	5	1917	1665
57	6	1018	1617
60	5	3436	1698
61	5	3417	1525
54	6	3466	1621
55	6	3421	1759
60	6	401	1662
61	6	1707	1774
54	7	3428	1780
60	7	3416	1592
61	3	\N	1736
61	7	3407	1532
54	3	\N	1590
53	8	3508	1777
54	8	3574	1539
60	8	3438	1708
61	8	631	1570
52	9	3549	1793
53	9	3465	1663
54	9	1196	1587
60	9	3444	1692
52	10	3577	1697
53	10	3495	1691
54	10	3557	1643
59	10	3585	1604
60	10	3494	1556
55	3	\N	1781
\.


--
-- TOC entry 2068 (class 0 OID 32817060)
-- Dependencies: 167
-- Data for Name: posicao_armario; Type: TABLE DATA; Schema: armario; Owner: comsolid
--

COPY posicao_armario (id_posicao_armario, apelido) FROM stdin;
1	A1
2	A2
3	A3
4	B1
5	B2
6	B3
7	C1
8	C2
9	C3
10	D1
11	D2
12	D3
\.


SET search_path = bv, pg_catalog;

--
-- TOC entry 2074 (class 0 OID 34527814)
-- Dependencies: 174
-- Data for Name: bv_pearson; Type: TABLE DATA; Schema: bv; Owner: comsolid
--

COPY bv_pearson (login, nome, email, senha, curso) FROM stdin;
2552727	AJALMAR REGO DA ROCHA NETO	ajalmar@ifce.edu.br	32f1e85845	Servidores
1674404	ANDERSON DE CASTRO LIMA	anderson@ifce.edu.br	b000448b13	Servidores
1641764	CORNELI GOMES FURTADO JúNIOR	cjunior@ifce.edu.br	cd8d997b6b	Servidores
1795291	DANIEL SILVA FERREIRA	daniels@ifce.edu.br	14a24ef1e0	Servidores
1223708	FRANCISCO NIVANDO BEZERRA	nivando_bezerra@yahoo.com	d74719bddc	Servidores
1795290	IGOR RAFAEL SILVA VALENTE	igor@ifce.edu.br	d2c735023a	Servidores
1622296	INáCIO CORDEIRO ALVES	inacioalves@ifce.edu.br	6116b77db3	Servidores
1674463	JEAN MARCELO DA SILVA MACIEL	jeanmdsm@ifce.edu.br	a92db48ad0	Servidores
1612866	OTáVIO ALCâNTARA DE LIMA JUNIOR	otavio@ifce.edu.br	6f11175347	Servidores
1547540	ROBSON DA SILVA SIQUEIRA	siqueira.robson.dasilva@gmail.com	318413da4e	Servidores
2473370	SANDRO CéSAR SILVEIRA JUCá	sandrojuca@ifce.edu.br	53a1453d38	Servidores
1548006	WELLINGTON ARAúJO ALBANO	wellington@ifce.edu.br	5a02001691	Servidores
1856744	AMAURI HOLANDA DE SOUZA JúNIOR	amauriholanda@ymail.com	3b430f9474	Servidores
1570732	ADRIANA MARQUES ROCHA	adrianamr@ifce.edu.br	60507cfed5	Servidores
1811881	ANTôNIO EDSON OLIVEIRA MARQUES	edmarque@ifce.edu.br	13806c5196	Servidores
1666904	BRUNO CéSAR BARROSO SALGADO	brunocesar@ifce.edu.br	dd5035b302	Servidores
1666808	CARLOS RONALD PESSOA WANDERLEY	ronald@ifce.edu.br	11feca439f	Servidores
1674316	CYNARA REIS AGUIAR	cynara@ifce.edu.br	98a0b122b6	Servidores
2316796	EMILIA MARIA ALVES SANTOS	emilia@ifce.edu.br	2c0983cccb	Servidores
1666898	FRANCISCO HUMBERTO DE CARVALHO JúNIOR	humbertojr@ifce.edu.br	9afc4fcf57	Servidores
1352895	GERMANA MARIA MARINHO SILVA	germana@ifce.edu.br	69a77b5bd7	Servidores
200916060279	LETÍCIA DE ARAÚJO ALMEIDA	\N	27b789c638	Licenciatura em Química
269523	JúLIO CéSAR DA COSTA SILVA	jcesar@ifce.edu.br	07bd3f5005	Servidores
1442772	MARIA INêS TEIXEIRA PINHEIRO	inestp@ifce.edu.br	a273bd4228	Servidores
1811837	PEDRO HENRIQUE AUGUSTO MEDEIROS	phamedeiros@ifce.edu.br	8636961c2a	Servidores
269968	ROBERTO ALBUQUERQUE PONTES FILHO	roberto@ifce.edu.br	96d2146ae8	Servidores
3473367	ROSSANA BARROS SILVEIRA	rossana@ifce.edu.br	77247f9887	Servidores
1667576	FRANKLIN ARAGãO GONDIM	aragaofg@ifce.edu.br	f1524fc954	Servidores
1666817	ANA KARINE PESSOA BASTOS 	karinebastos@ifce.edu.br	798f7778e5	Servidores
6053933	ANTôNIA DE ABREU SOUSA	antonia@ifce.edu.br	f646e1e981	Servidores
6269442	ARISTêNIO DE OLIVEIRA MENDES	aristenio@ifce.edu.br	07dbea1986	Servidores
1641778	RAIMUNDA OLíMPIA DE AGUIAR GOMES	olimpiaguiar@ifce.edu.br	21ca5df98f	Servidores
1843014	MARIA CLEIDE DA SILVA BARROSO	ccleide1971@yahoo.com.br	6bb24ff8e9	Servidores
1756407	CAROLINE DE GóES SAMPAIO	carolinesampaio@ifce.edu.br	7acdf63eb9	Servidores
1676089	ANTôNIO CARLOS DE SOUZA	carlosfisica@ifce.edu.br	9de8599257	Servidores
6995006	ANTôNIO OLíVIO SILVEIRA BRITTO JúNIOR	olivio@ifce.edu.br	b6902924f5	Servidores
1674454	NARCéLIO DE ARAúJO PEREIRA	narcelio@ifce.edu.br	fd39ecc116	Servidores
1290570	CARLOS HENRIQUE LIMA 	larna@bol.com.br	756a5645bd	Servidores
1453960	EUGENIO BARRETO SOUSA E SILVA	eugenio@ifce.edu.br	75e389fcc0	Servidores
1544559	TEóFILO ROBERTO DA SIVA	teoroberto@gmail.com	cb54fcef31	Servidores
1545800	DAVID CARNEIRO DE SOUZA	davidcs@ifce.edu.br	5c9264fd2c	Servidores
2550376	DARLAN PORTELA VERAS	darlanpv@ifce.edu.br	7f231727af	Servidores
1550415	JâNIO KLéO DE SOUSA CASTRO	janiokleo@ifce.edu.br	9562e88348	Servidores
1857765	ÉRIKA DA JUSTA TEIXEIRA ROCHA 	erikadajusta@ifce.edu.br	ee2e161e32	Servidores
1679143	AGNES CAROLINE SOUZA PINTO	carolcedro@ifce.edu.br	2fd84b77d5	Servidores
1552994	ANA CARLA CADARçO COSTA	carla@ifce.edu.br	3af34682d8	Servidores
1641862	ANNA HILDA SILVA MELO	anna@ifce.edu.br	c1169afac6	Servidores
1535629	ANTôNIO EVERTON DOS SANTOS GóES	everton.i@ifce.edu.br	7c188d363a	Servidores
1547393	DAVID MOTA DE AQUINO PAZ	david@ifce.edu.br	bdb0be1df1	Servidores
1662547	FRANCISCO WLISSYS LEMOS BORGES	borges@ifce.edu.br	343b32db4f	Servidores
1699938	GISLANE SAMPAIO VASCONCELOS	gislane@ifce.edu.br	11ed3cc402	Servidores
1570466	ISABEL MAGDA SAID PIERRE CARNEIRO	isabelmsaid@ifce.edu.br	3f7dcc6720	Servidores
1583750	JEFFERSON CHAGAS VALE	jefferson@ifce.edu.br	b0efad2322	Servidores
1476985	JORGE MACEDO LOPES	jorge@ifce.edu.br	0096d8a31e	Servidores
1547516	JULIANA CYSNE SOARES GUERRA	juliana@ifce.edu.br	c0c8f387cc	Servidores
1795230	KEYLA DE SOUZA LIMA CRUZ	keylalima@ifce.edu.br	03e9cb7804	Servidores
1666797	FRANSCISCO FREDERICO DOS SANTOS MATOS	ffsmatos@ifce.edu.br	adabcf9901	Servidores
1586384	MARCéU VERíSSIMO RAMOS DOS SANTOS	marceuverissimo@ifce.edu.br	449f636488	Servidores
1675621	MáRCIA LORENA BEZERRA PEIXOTO	marcialorena@ifce.edu.br	fbbd9f62e9	Servidores
1641949	MARCíLIO OLIVEIRA MOURA	marcilio@ifce.edu.br	29158e1712	Servidores
1547504	MARCOS ANDRE DAMASCENO CAVALCANTE	marcosandre@ifce.edu.br	cc30c06d48	Servidores
1641885	RENATA SANTIAGO BEZERRA	renatasl@ifce.edu.br	cb6ff049f6	Servidores
1576780	ROSEANE MICHELLE DE LIMA SILVEIRA	roseane@ifce.edu.br	20fa3f0b00	Servidores
1842852	JOãO OTáVIO SIQUEIRA FILHO	otaviosiqueira@ifce.edu.br	9ce3b10115	Servidores
1842784	FERNANDA ROSALINA DA SILVA MEIRELES	fernanda@ifce.edu.br	e9df749975	Servidores
1891233	MAGDA ALVES VIEIRA	magdavieira@ifce.edu.br	9e5d1082ec	Servidores
1641853	YSRAEL MOURA GARCIA	ysrael@ifce.edu.br	31a89d958d	Servidores
1854501	FRANCISCO AIRTON FORTE FEITOSA	airtonf@ifce.edu.br	ac5a51e8ae	Servidores
1891264	RAUL LENNON MATOS NOGUEIRA	raullennon@ifce.edu.br	0289e3c900	Servidores
1890898	ANDRéIA CAVALCANTE RODRIGUES	andreiacavalcante@ifce.edu.br	d4ec1d2646	Servidores
1841069	IASSODARA FARIAS LEITãO PESSOA	iassodara@ifce.edu.br	32faa7091b	Servidores
1748460	MARFISA CARLA DE ABREU MACIEL	marfisa@ifce.edu.br	9ab5643a79	Servidores
1895183	ADELAIDE MARIA DE SOUSA COSTA	adelaycosta@yahoo.com.br	e5d95a95b6	Servidores
200926060174	TATIANE QUINTELA FONTELES	tatisgirl18@yahoo.com.br	b5fb4d5dc0	Licenciatura em Química
201016060181	THIAGO MATIAS DE SOUSA	thaguinhoczz@hotmail.com	cdd40baa90	Licenciatura em Química
201016060130	TIBÉRIO DAS CHAGAS FERREIRA	tiberioferreira@hotmail.com	429b9ca304	Licenciatura em Química
201116060167	WILLIS BERG LINHARES DE SOUZA	wberg@santanatextiles.com	c59721c0fc	Licenciatura em Química
201016060394	WINSTON EUDERSON LIMA ANASTACIO	winston.tecnico@gmail.com	38d162b36f	Licenciatura em Química
201026060214	ALMIR BARROS DE SOUSA FILHO	absfilho1@hotmail.com	0d631e7018	Licenciatura em Química
200916060228	AMANDA VIANA CAVALCANTE	\N	25a36b7b86	Licenciatura em Química
200926060107	ANA JESSICA PEREIRA BARRETO	anajessicap@yahoo.com.br	bdcf4a8545	Licenciatura em Química
201116060175	ANA KELE ARCANJO DE SOUSA	anakarcanjo@gmail.com	f480a9f5f8	Licenciatura em Química
200926060093	ANA KEZIA FERREIRA DE FRANÇA	bellymel8@hotmail.com	4e77188ebd	Licenciatura em Química
200922310427	VALRENICE NASCIMENTO DA COSTA	valrenice@yahoo.com.br	820a4be3f8	Técnico em Informática
200916060244	ANA MÁRCIA DE MELO AMARAL	\N	266f92ddb9	Licenciatura em Química
201022310445	VICTOR ALISSON MANGUEIRA CORREIA	kurosakivictor@hotmail.com	fb0cc66b3d	Técnico em Informática
20112042310252	VICTOR LUIS VASCONCELOS DA SILVA	vitorluis@hotmail.com	ee404a5800	Técnico em Informática
200822310476	VIVIANE DA COSTA PEREIRA	\N	eea212089b	Técnico em Informática
200822310085	VIVIANE FERREIRA ALMEIDA	\N	bb6012acc7	Técnico em Informática
201012310027	WALLISSON ISAAC FREITAS DE VASCONCELOS	wallissonisaac@gmail.com	8ab328ccdb	Técnico em Informática
20112042310325	WASHINGTON LUIZ DE OLIVEIRA	wasluizoliveira@bol.com.br	35fb50b75b	Técnico em Informática
200822310158	WELLINGTON DOS SANTOS CUNHA	\N	89424acbd4	Técnico em Informática
20112042310260	WIHARLEY FEITOSA NASCIMENTO	wiharleynascimento@hotmail.com	735b4f87c1	Técnico em Informática
20112042310287	WILLIAM CLINTON FREIRE SILVA	willianclinton@hotmail.com	7d1307b565	Técnico em Informática
200822310344	WILLIAM PEREIRA LIMA	\N	30ef735acd	Técnico em Informática
201022310488	WILLIAM VIEIRA BASTOS	will.v.b@hotmail.com	2814a07b89	Técnico em Informática
20112042310279	WILLIANY GOMES NOBRE	williany_gomes@yahoo.com	bdb87c7efc	Técnico em Informática
201112310320	WILQUEMBERTO NUNES PINTO	wilquem_np@hotmail.com	a530c909e5	Técnico em Informática
201022310399	YARA BERNARDO CABRAL	yara-bernardo@hotmail.com	88fff59435	Técnico em Informática
201112310347	YOHANA MARIA SILVA DE ALMEIDA	ravena_xispe@hotmail.com	fe96290119	Técnico em Informática
201012310043	GEORGE GLAIRTON GOMES TIMBÓ	gaga1492@yahoo.com.br	04e8966237	Técnico em Informática
1556624	ADRIANO HOLANDA PEREIRA	holanda@ifce.edu.br	eba0f5fe5e	Servidores
1575034	CELSO ROGéRIO SCHMIDLIN JúNIOR	celso@ifce.edu.br	ba081fd9cc	Servidores
1641803	FáBIO TIMBó BRITO	fabio@ifce.edu.br	b754c5e1eb	Servidores
1467796	FRANCISCO NéLIO COSTA FREITAS	fneliocf@ifce.edu.br	af381f66e9	Servidores
2506874	GERALDO LUIS BEZERRA RAMALHO	gramalho@ifce.edu.br	53c2ccd187	Servidores
2706748	JOSé CIRO DOS SANTOS	ciroifce@gmail.com	8cbb82cb36	Servidores
1442729	JOSé DANIEL DE ALENCAR SANTOS	jdaniel@ifce.edu.br	850e691d25	Servidores
2726212	PEDRO PEDROSA REBOUçAS FILHO	pedrosarf@gmail.com	c21f164388	Servidores
1666792	RODRIGO FREITAS GUIMARãES	rodrigofg@ifce.edu.br	b94563bb39	Servidores
1544450	SAMUEL VIEIRA DIAS	samueldias@ifce.edu.br	44ef6d75ca	Servidores
1842966	LUIZ DANIEL SANTOS BEZERRA	danielbezerra@ifce.edu.br	27c2666f97	Servidores
2635531	FRANCISCO JOSé DOS SANTOS OLIVEIRA	fjoliveira@ifce.edu.br	b488bed6c9	Servidores
201022310259	JOSÉ NATANAEL DE SOUSA	sergiotome28@yahoo.com	daff842a25	Técnico em Informática
201012310183	JOSÉ XAVIER DE LIMA JÚNIOR	xavierxion@hotmail.com	a6980d9bac	Técnico em Informática
201112310193	JULIA SILVA DOS SANTOS	juliasilva_morena@hotmail.com	72503c03ba	Técnico em Informática
200827040272	MAYARA ARRUDA PEREIRA	\N	63857a84b6	Engenharia Ambiental
201012310515	JULIANA BARROS DA SILVA	\N	6ecfc1dae2	Técnico em Informática
200922310281	JULIO CESAR OTAZO NUNES	juliocesar_otazo@hotmail.com	638e10ae55	Técnico em Informática
201012310019	KILVIA RIBEIRO MORAIS	kikig4_192@hotmail.com	d0cde5e016	Técnico em Informática
201012310167	KLEGINALDO GALDINO PAZ	kleginaldopaz@hotmail.com	51c409da0c	Técnico em Informática
201112310207	LAIS EVELYN BERNARDINO ALVES	lais-evelyn@hotmail.com	109ae616f1	Técnico em Informática
201012310108	LEANDRO MENEZES DE SOUSA	leomesou@yahoo.com.br	da47be6c03	Técnico em Informática
201012310205	LEONARDO BARBOSA DE SOUZA	yvensleo@hotmail.com	a316488587	Técnico em Informática
201112310215	LILIAN JACAÚNA LOPES	lilian.jacauna.lopes@hotmail.com	39ad669e93	Técnico em Informática
201012310302	LUAN SIDNEY NASCIMENTO DOS SANTOS	luansidneyseliga@gmail.com	6399ad9892	Técnico em Informática
200912310300	LUANA GOMES DE ANDRADE	j.kluana@gmail.com	fd9185ff2b	Técnico em Informática
201112310223	LUCAS ÁBNER LIMA REBOUÇAS	revpecas@uol.com.br	0fea03ce7e	Técnico em Informática
201112310231	LUCAS SILVA DE SOUSA	lucas.xmusic@hotmail.com	6578daef48	Técnico em Informática
201112310045	LUIZ ALEX PEREIRA CAVALCANTE	alexofcreed@hotmail.com	81e02eafa3	Técnico em Informática
20112042310198	MADSON HENRIQUE DO NASCIMENTO RODRIGUES	madson38@hotmail.com	ff3a94d0b8	Técnico em Informática
201012310361	MAGNA MARIA VITALIANO DA SILVA	magnavitaliano@gmail.com	906f18da29	Técnico em Informática
200822310387	MANOEL ALEKSANDRE FILHO	aleksandref@gmail.com	35000a95a2	Técnico em Informática
201012310540	MANOEL NAZARENO E SILVA	nazarenosp@gmail.com	a074556293	Técnico em Informática
201022310275	MARA JÉSSYCA LIMA BARBOSA	marajessyca@hotmail.com	0221f7700c	Técnico em Informática
201012310418	MARIA ANGELINA FERREIRA PONTES	alngel1994@bol.com.br	75301e3619	Técnico em Informática
201012310345	MARIA CAMILA ALCANTARA DA SILVA	camila.ca27@gmail.com	f886deacb2	Técnico em Informática
201012310140	MARIA JULIANE DA SILVA CHAGAS	julianychagas@gmail.com	512ab2f984	Técnico em Informática
20112042310201	MARIA SIMONE PEREIRA CORDEIRO	simonemanda@hotmail.com	262b8888a5	Técnico em Informática
201022310283	MATHEUS CARVALHO DE FREITAS	matheuscarvalhodf@ymail.com	dc42f36471	Técnico em Informática
201016060114	INARA RIBEIRO MORAIS	inara1931@gmail.com	ebc930d307	Licenciatura em Química
201026060273	INES FABIOLA MACHADO DE ARAÚJO	\N	7794121d4b	Licenciatura em Química
200916060155	ISABEL BENTO DE CASTRO	\N	c4d5ed6533	Licenciatura em Química
201112310240	MAYARA FREITAS SOUSA	mayara_rebeldemia12@hotmail.com	8c45740cf4	Técnico em Informática
201022310291	MAYARA NOGUEIRA BEZERRA	mayara_nb@hotmail.com	d2539546b2	Técnico em Informática
200922310338	MAYARA SUÉLLY HONORATO DA SILVA	mayarasilvah@yahoo.com.br	1aa3f31132	Técnico em Informática
200822310328	MICHELE XAVIER DA SILVA	\N	2a82329408	Técnico em Informática
20112044060148	FERNANDO XIMENES ALVES	riyat_dragonlance@hotmail.com	06ceaf8e2b	Licenciatura em Química
20112044060172	FRANCISCO GABRIEL TEIXEIRA PEREIRA	gabrielt2733@yahoo.com.br	3142d28205	Licenciatura em Química
20112044060156	FRANCISCO LEANDRO DOS REIS DA SILVA	leoreis_heavy@hotmail.com	d5d60db042	Licenciatura em Química
20112044060393	FRANCISCO TIAGO CAMURÇA DA SILVA	thiago.camurca@gmail.com	60b2af3342	Licenciatura em Química
20112044060164	GILMARA DA SILVA PACHECO	gilmara.seliga@gmail.com	a5eb17215c	Licenciatura em Química
20112044060385	HALYSON JOSÉ LIMA DE ALMEIDA	hlquimica@yahoo.com.br	8b852c0683	Licenciatura em Química
20112044060180	JANDINALDO SILVA DE MEDEIROS VALENTE	jandinaldo@hotmail.com	7ef108a5a1	Licenciatura em Química
20112044060199	JOAO ROBERTO CIPRIANO SOUSA	joaorob@gmail.com	67e6de69cb	Licenciatura em Química
20112044060202	JOSE VALDIR DE MENDONCA JUNIOR	valdirmjuno@hotmail.com	0fa0511ff3	Licenciatura em Química
20112044060210	JULIO CESAR RABELO DE MESQUITA FILHO	jcesarbmx@hotmail.com	398dadf942	Licenciatura em Química
20112044060229	KAIO MARCIO DE MEDEIROS COELHO	kaioaskap@hotmail.com	6a03fc4e86	Licenciatura em Química
20112044060407	LEANDRO DOS SANTOS BATISTA	leo_batera_14@hotmail.com	7b692aad01	Licenciatura em Química
20112044060415	LETICIA PAMELA CRUZ ALMEIDA	lety_pamela@hotmail.com	87745eb067	Licenciatura em Química
20112044060237	MARCOS SAMUEL MAGALHAES MENEZES	marcossamuel15@hotmail.com	8aec0f034c	Licenciatura em Química
20112044060253	MAYARA LIMA GOIANA	mayara_goiana@hotmail.com	24fc3fde94	Licenciatura em Química
200826060091	MARCOS DOUGLAS ALMEIDA BRASIL	\N	0aeb1d3577	Licenciatura em Química
20112044060261	MEIRILANE DO NASCIMENTO ARNOU	meirilane_arnou@hotmail.com	1c5b421978	Licenciatura em Química
20112044060270	MELISSA ESTER NOGUEIRA RODRIGUES	meluchoa@hotmail.com	74dd91bd46	Licenciatura em Química
20112044060440	RAFAEL BRAGA DOS SANTOS	rafael_bsantos200@hotmail.com	6d10aee720	Licenciatura em Química
200912310416	NACELIA ALVES DA SILVA	nacelia_alves@hotmail.com	3861dbb5a3	Técnico em Informática
201022310305	NANAXARA DE OLIVEIRA FERRER	nanaxara_oliv@hotmail.com	0d39cdc4ad	Técnico em Informática
201022310020	NEYLLANY ANDRADE FERNANDES	neyllany@hotmail.com	58200bbd02	Técnico em Informática
201112310258	NILTON SILVEIRA DOS SANTOS FILHO	niltinhoconcurseiro@hotmail.com	ff03598ec0	Técnico em Informática
200912310327	NINFA IARA SABINO ROCHA DA SILVA	ninfaiar@hotmail.com	db90267d52	Técnico em Informática
200922310354	OLGA SILVA CASTRO	olga_kastro@hotmail.com	55658f49e1	Técnico em Informática
200822310077	PATRICIA PAULA FEITOSA COSTA	\N	3753282c88	Técnico em Informática
20112042310309	PAULO HENRIQUE COUTO VIEIRA	phzinn@hotmail.com	deea8171f8	Técnico em Informática
20112042310210	PEDRO HENRIQUE GOMES DE OLIVEIRA	henriqueoliveira.r9@hotmail.com	a87e50ebc2	Técnico em Informática
200922310362	PEDRO VINNICIUS VIEIRA ALVES CABRAL	pedro1_3@yahoo.com.br	2a65fb42b1	Técnico em Informática
201022310330	PEDRO VITOR DE SOUSA GUIMARÃES	pedrovitor1@bol.com.br	5fd6af61af	Técnico em Informática
201112310266	RAFAEL RODRIGUES SOUSA	rafaromanrodriguez@gmail.com	6b741c0180	Técnico em Informática
200912310033	RAFAELA DE LIMA SILVA	rafaella02@yahoo.com.br	280559aaa6	Técnico em Informática
20112042310228	RAUL OLIVEIRA SOUSA	rauloliveira14@gmail.com	698d650030	Técnico em Informática
201022310410	RAYLSON SILVA DE LIMA	raylson.silva22@gmail.com	3c701c86d2	Técnico em Informática
201112310274	RAYSA PINHEIRO LEMOS	prisciilarayane_123@hotmail.com	52235e9f22	Técnico em Informática
201012310531	REGINALDO PATRÍCIO DE SOUZA LIMA	moral.reginaldo@hotmail.com	3e3ff2e28e	Técnico em Informática
201112310029	ROBERTA DE SOUZA LIMA	\N	0c42e23af9	Técnico em Informática
200922310370	ROBSON DOUGLAS BARBOZA GONÇALVES	robsondouglasrd@yahoo.com.br	c0be725c0f	Técnico em Informática
200922310400	ROBSON SILVA PORTELA	robgolrsp@hotmail.com	0c599b4906	Técnico em Informática
201112310282	ROGÉRIO QUEIROZ LIMA	rogerio-_2010@hotmail.com	7ba4e1cad4	Técnico em Informática
200822310433	ROMULO DA SILVA GOMES	romulo.ifet@gmail.com	0e80ea9c56	Técnico em Informática
200822310131	RÔMULO SAMINÊZ DO AMARAL	\N	4f46191fff	Técnico em Informática
20112042310236	ROSANABERG PAIXÃO DE LIMA	rosanabergpaixao@hotmail.com	bc815981e3	Técnico em Informática
200912310343	ROSEANNE PAIVA DA SILVA	roseannepaiva@gmail.com	353da32b35	Técnico em Informática
201012310590	ROSINEIDE SILVA DE ARAUJO	\N	33e1a95efc	Técnico em Informática
201022310372	SAMARA SOARES DE LIMA	samara_aunika@hotmail.com	aad6a87663	Técnico em Informática
200912310254	SAMUEL BRUNO HONORATO DA SILVA	\N	33b0494f98	Técnico em Informática
201012310256	SARA PINHEIRO ZACARIAS	\N	adcef51edd	Técnico em Informática
201012310051	SUSANA MARA CATUNDA SOARES	susana.mara17@hotmail.com	8f51b12945	Técnico em Informática
201112310290	TATIANE SOUZA DA SILVA	tat_do@hotmail.com	a91706e58a	Técnico em Informática
200912310335	THIAGO HENRIQUE SILVA DE OLIVEIRA	\N	6d4577b20b	Técnico em Informática
201112310304	TIAGO ALEXANDRE FRANCISCO DE QUEIROZ	lucianaqueiroz2007@yahoo.com.br	f4a3fcd77d	Técnico em Informática
201022310429	TIAGO DE MATOS LIMA	tiago_m_lima@hotmail.com	80cae5102c	Técnico em Informática
20112042310244	TIAGO LINO VASCONCELOS	tlino10@bol.com.br	a76f6bacb4	Técnico em Informática
201112310100	DALILA DE ALENCAR LIMA	dalila8855@hotmail.com	eac97d5bf3	Técnico em Informática
200922310087	DANIEL GOMES CARDOSO	dan-eumesmo@hotmail.com	acb561387c	Técnico em Informática
201012310159	DANIEL HENRIQUE DA COSTA	danieldhc86@hotmail.com	a4552f6005	Técnico em Informática
201022310160	DANIELE DO NASCIMENTO MARQUES	danielemarques1990@hotmail.com	3b787de8cb	Técnico em Informática
20112042310066	DANILO DE OLIVEIRA SOUSA	danilo_oliveirace@hotmail.com	b3545b0ad2	Técnico em Informática
20112042310074	DAURYELLEN MENDES LIMA	daury.seliga@gmail.com	51bf92f367	Técnico em Informática
200912310050	DAVIANNE COELHO VALENTIM	daviannevalentim@oi.com.br	96de4edbab	Técnico em Informática
200922310095	DAVID NASCIMENTO DE ARAUJO	daviddna2007@gmail.com	6f94468553	Técnico em Informática
201112310118	DEYLON SILVA COSTA	deylon_@hotmail.com	a8c9549489	Técnico em Informática
201012310132	DIEGO GUILHERME DE SOUZA MORAES	digui.info@gmail.com	5952a0260e	Técnico em Informática
20112042310317	DIEGO SOARES DA SILVA	\N	2a6138b250	Técnico em Informática
20112042310082	DJALMA DE SÁ RORIZ FILHO	djalmaroriz@yahoo.com.br	d850151ded	Técnico em Informática
20112042310090	EDVANDRO VIEIRA DE ALBUQUERQUE	edvandrovieira@hotmail.com	06d581145c	Técnico em Informática
200922310117	ELINE LIMA DE FREITAS	eline.lim@hotmail.com	2ffc588d6c	Técnico em Informática
201022310178	ELIZABETH DA PAZ SANTOS	ayame.fumetsu@gmail.com	715f3de5a5	Técnico em Informática
201012310485	EMANUEL AGUIAR FREITAS	emanuel_aguiar_f@yahoo.com.br	c6275506ab	Técnico em Informática
20112042310295	EMANUEL ROSEIRA GUEDES	emanuelrguedes@hotmail.com	a858e5c741	Técnico em Informática
20112042310104	EMMILY ALVES DE ALMEIDA	emmly_23@hotmail.com	86fe20bb1e	Técnico em Informática
201012310264	EUDIJUNO SCARCELA DUARTE	charlie_doson@hotmail.com	ae5afb8cfd	Técnico em Informática
200822310190	EVERTON BARBOSA MELO	vertaocnm@gmail.com	d02f63052a	Técnico em Informática
201022310194	FABIANA DE ALBUQUERQUE SIQUEIRA	biazinha_siqueira@hotmail.com	d71ba8b377	Técnico em Informática
201022310208	FABIO SOUZA SANTOS	fabio1993souza@yahoo.com.br	054c765d28	Técnico em Informática
201012310337	FABRICIO DE FREITAS ALVES	alvesmf2@hotmail.com	7a764c6885	Técnico em Informática
20112042310112	FELIPE ALEXSANDER RODRIGUES CHAVES	felipe.alexsander@hotmail.com	328f098a5d	Técnico em Informática
201112550194	ADRIANA MARIA SILVA COSTA	adriana.costa1677@hotmail.com	345d2f2243	Técnico em Redes de Computadores
201112550216	ALEXSANDRO KAUÊ CARVALHO GALDINO	carvalho_3331@hotmail.com	db715ed91b	Técnico em Redes de Computadores
201112550232	ANA FLÁVIA CASTRO ALVES	ilifinivai@gmail.com	59ab4042f6	Técnico em Redes de Computadores
20112042550172	ANDERSON DE SOUZA GABRIEL PEIXOTO	andersonpeixoto1@live.com	e03807cb9d	Técnico em Redes de Computadores
201112550240	ANDERSON PEREIRA GONÇALVES	andersonpr.goncalves@gmail.com	e62b59da99	Técnico em Redes de Computadores
20112042550016	ANDRE ALMEIDA E SILVA	andre8031@ig.com.br	f21a8eba10	Técnico em Redes de Computadores
201112550259	ANTONIA NEY DA SILVA PEREIRA	bibleney@gmail.com	301d9225d4	Técnico em Redes de Computadores
20112042550180	ANTONIO ELSON SANTANA DA COSTA	\N	0ae34df493	Técnico em Redes de Computadores
20112042550024	ANTONIO JULIAM DA SILVA	\N	b08b830396	Técnico em Redes de Computadores
201112550186	CARLOS YURI DE AQUINO FAÇANHA	c_yuri13@hotmail.com	dc354bcd0f	Técnico em Redes de Computadores
201112550178	CÍCERO JOSÉ SOUSA DA SILVA	c1c3ru@hotmail.com	f486f089c2	Técnico em Redes de Computadores
201112550160	DIEGO ALMEIDA CARNEIRO	diegoo_ac@hotmail.com	bef195a38e	Técnico em Redes de Computadores
20112042550032	ELIADE MOREIRA DA SILVA	eliadebol@gmail.com	eb94ed5706	Técnico em Redes de Computadores
20112042550040	EUGENIO REGIS PINHEIRO DANTAS	regis_dant@hotmail.com	0e9052fb47	Técnico em Redes de Computadores
20112042550059	FERNANDO DENES LUZ COSTA	deneslcosta@hotmail.com	a6d3488e59	Técnico em Redes de Computadores
20112042550067	FRANCISCO FERNANDO GONCALVES DA SILVA	fernandogonsilva@yahoo.com.br	a35d9182de	Técnico em Redes de Computadores
20112042550075	GILDEILSON DOS SANTOS MENDONÇA	gildeilsonmendonca@hotmail.com	dea19c33d2	Técnico em Redes de Computadores
201112550143	GLAYDSON RAFAEL MACEDO	glaydsonmacedo@yahoo.com	750420e173	Técnico em Redes de Computadores
20112042550083	GUILHERME DA SILVA BRAGA	heavy_guill@hotmail.com	47b8ce2a4f	Técnico em Redes de Computadores
20112042550091	GUTEMBERG MAGALHAES SOUZA	gmsflp10@hotmail.com.br	280bded011	Técnico em Redes de Computadores
20112042550199	HELCIO WESLEY DE MENEZES LIMA	helciowesley@hotmail.com	7f4c8e6646	Técnico em Redes de Computadores
201112550291	JOSE IVANILDO FIRMINO ALVES	ivanalvesnet@yahoo.com.br	092d4d310e	Técnico em Redes de Computadores
20112042550105	JOSÉ WEVERTON RIBEIRO MONTEIRO	j.weverton@hotmail.com	7fa4065751	Técnico em Redes de Computadores
20112042550113	KAILTON JONATHA VASCONCELOS RODRIGUES	kailtonjonathan@hotmail.com	365ef772aa	Técnico em Redes de Computadores
20112042550202	KEMYSON CAMURÇA AMARANTE	kemysonn@gmail.com	4b22014ba4	Técnico em Redes de Computadores
201112550283	LUCAS FIGUEIREDO SOARES	lucasfigueiredo@hotmail.fr	15adb32476	Técnico em Redes de Computadores
20112042550121	LUCIANO JOSÉ DE ARAÚJO	luciano_geo2007@yahoo.com.br	db827e8709	Técnico em Redes de Computadores
20112042550130	LUIZ ROBERTO DE ALMEIDA FILHO	so.betog@gmail.com	0be7185a57	Técnico em Redes de Computadores
201112550127	MARCOS DA SILVA JUSTINO	marcos.ce8@gmail.com	3d4b3d1084	Técnico em Redes de Computadores
20112042550148	MARIA ELANIA VIEIRA ASEVEDO	elania_vieira@hotmail.com	0d3f520ba6	Técnico em Redes de Computadores
20112042550210	MARIA IZABELA NOGUEIRA SALES	iza-nogueiira@hotmail.com	d2fadbc38a	Técnico em Redes de Computadores
201112550119	MARIA VALDENE PEREIRA DE SOUZA	mvps23@hotmail.com	b4a2a3d6cf	Técnico em Redes de Computadores
20112042550156	MAYARA JESSICA CAVALCANTE FREITAS	mayara_jessica2010@bol.com.br	e7a4005391	Técnico em Redes de Computadores
20112042550229	MÔNICA GUIMARÃES RIBEIRO	monikrg@hotmail.com	a4521439e5	Técnico em Redes de Computadores
201112550097	PAULO ROBSON SANTOS DA COSTA	prscsantos@gmail.com	9cd5912667	Técnico em Redes de Computadores
20112042550237	PEDRO DA SILVA NETO	pedrosneto@hotmail.com.br	da94e15880	Técnico em Redes de Computadores
201112550070	PRISCILA CARDOSO DO NASCIMENTO	prisna.cardoso@hotmail.com	4ead358453	Técnico em Redes de Computadores
20112042550245	REBECA HANNA SANTOS DA SILVA	rebecahannaduarte@hotmail.com	0a67455b1f	Técnico em Redes de Computadores
20112042550300	RENATO LIMA BRAUNA	renato.ifce@gmail.com	e4dec76161	Técnico em Redes de Computadores
201112550046	RICARLOS PEREIRA DE MELO	ricarlosmelo@gmail.com	23d84782b2	Técnico em Redes de Computadores
20112042550253	ROBSON MACIEL DE ANDRADE	robson5647@hotmail.com	16a369f424	Técnico em Redes de Computadores
20112042550261	ROSIANE FERREIRA FREITAS	rosianefreitas@ymail.com	96d11727e3	Técnico em Redes de Computadores
20112042550270	SIMEANE DA SILVA MONTEIRO	simeane@yahoo.com.br	e9a0cc617a	Técnico em Redes de Computadores
20112042550288	THAÍS BARROS SOUSA	jts_net@hotmail.com	8ca4931aca	Técnico em Redes de Computadores
201112550020	TIAGO NASCIMENTO SILVA	tiago.crv@hotmail.com	c684bea28d	Técnico em Redes de Computadores
201112550011	VALDECI ALMEIDA FILHO	valdecifilho94@yahoo.com	47720adf55	Técnico em Redes de Computadores
20112042550296	VLAUDSON DA CRUZ RAMALHO	crvladson@gmail.com	ecb7a82b02	Técnico em Redes de Computadores
201015260020	ADELINO PEREIRA VIANA	adelino_viana@hotmail.com	7f0ecdcc20	Tecnologia em Manutenção Industrial
20112043260011	ÁKILA MELO BARBOZA	akilamelo@yahoo.com.br	70ff295d06	Tecnologia em Manutenção Industrial
200915260169	ALISSON FELIX DA SILVA	gato.felix.cearamor@yahoo.com.br	9606430f89	Tecnologia em Manutenção Industrial
200925260013	ALLAN KAIO DA COSTA SILVA	akdito@gmail.com	43a192f34c	Tecnologia em Manutenção Industrial
201015260012	ANA BEATRIZ SILVA ESTEVES DE HOLLANDA	anabeatriz-esteves@hotmail.com	2b3f0ec446	Tecnologia em Manutenção Industrial
201115260251	ANA PAULA RODRIGUES DO NASCIMENTO BARROSO	appaulabarroso@gmail.com	f7cd10056a	Tecnologia em Manutenção Industrial
200825260119	ANDERSON DOS SANTOS DIAS	asdias7@gmail.com	7c03b8ca21	Tecnologia em Manutenção Industrial
201025260120	ANDERSON OLIVEIRA DA SILVA	anderson_os777@hotmail.com	00201ce5ba	Tecnologia em Manutenção Industrial
201015260292	ANTONIO THIAGO MOREIRA DE ALMEIDA	thiagoifce@hotmail.com	b482d3eb5a	Tecnologia em Manutenção Industrial
20112043260020	ANTONIO WALLACE NERES DA SILVA	wallace_neres@yahoo.com.br	747735753f	Tecnologia em Manutenção Industrial
20112043260038	ARTHUR BRENO DA SILVA CARVALHO	arthurtuf@hotmail.com	31af422b14	Tecnologia em Manutenção Industrial
20112043260267	BRUNO FRANCA LIMA	brunof_10@hotmail.com	df92df213a	Tecnologia em Manutenção Industrial
20112043260283	CARLOS RAFAEL MEDEIROS VIANA	carlosrafael_m@yahoo.com.br	6331461c38	Tecnologia em Manutenção Industrial
200925260021	CLAUDIO BRAGA DUARTE	para.claudio@hotmail.com	d7a14a6c2f	Tecnologia em Manutenção Industrial
201025260244	CLEITON DA SILVA MARINHO	cleitonmarinho@yahoo.com.br	c870d8af64	Tecnologia em Manutenção Industrial
201115260073	DANIEL DE SOUSA VERGA	daniel_verga@live.com	f438b1fac1	Tecnologia em Manutenção Industrial
201115260235	DANIELE DIEB FRAGA	dani_dieb@yahoo.com.br	d8e67477f9	Tecnologia em Manutenção Industrial
20112043260054	DIEGO CHAVES FERREIRA	digaoctx@hotmail.com	863565743c	Tecnologia em Manutenção Industrial
200915260053	EDNARDO DA SILVA MOREIRA	\N	1855d50c1c	Tecnologia em Manutenção Industrial
20112043260062	ELSON CRISTIANO ESTÁCIO DE SOUSA	elson.cristiano@hotmail.com	3b432b8ced	Tecnologia em Manutenção Industrial
201025260210	EMANOEL DA COSTA FARIAS	emannoelfarias@hotmail.com	9495fd9c8b	Tecnologia em Manutenção Industrial
20112043260070	EMERSON SOUSA ROCHA	rainmaker@oi.com.br	3443cc67d3	Tecnologia em Manutenção Industrial
200925260030	ENDERSON ARAÚJO FERNANDES	enderson1508@hotmail.com	548031dfd9	Tecnologia em Manutenção Industrial
201025260139	EZIO MONTEIRO OLIVEIRA	ezio.monteiro@uol.com.br	6e14311d7d	Tecnologia em Manutenção Industrial
200915260177	FABIO MAIA DE SOUSA	fabio.maia.sousa@hotmail.com	d5af3009f8	Tecnologia em Manutenção Industrial
200915260045	FABRÍCIO SOUSA PEREIRA	\N	78789c7121	Tecnologia em Manutenção Industrial
201025260236	FELIPE RODRIGUES DA SILVA	feliperodrigues190@gmail.com	e92fd8c3d1	Tecnologia em Manutenção Industrial
200915260096	FERNANDO HENRIQUE COSTA SABOIA	fernandocosta.ifce@gmail.com	d1702aa467	Tecnologia em Manutenção Industrial
201115260057	FERNANDO LUIZ DE LIMA	fllima@sfiec.org.br	f4230756c0	Tecnologia em Manutenção Industrial
201015260071	FERNANDO PEREIRA DE ARAÚJO	laysapereira@yahoo.com.br	5c64aad675	Tecnologia em Manutenção Industrial
201015260080	FLAVIO RENATO DE HOLANDA FILHO	pegasus_fera@hotmail.com	8f7066d197	Tecnologia em Manutenção Industrial
20112043260089	FRANCISCA AIRLANE ESTEVES DE BRITO	airlaniaesteves@yahoo.com.br	4206d5aed5	Tecnologia em Manutenção Industrial
201115260243	FRANCISCO ALEXANDRE DA CRUZ JÚNIOR	ale_ifet@yahoo.com.br	ac5ca69232	Tecnologia em Manutenção Industrial
201015260128	FRANCISCO DANILO RODRIGUES DA SILVA	rodriguesdanilo69@yahoo.com.br	aecd29b8c5	Tecnologia em Manutenção Industrial
201115260049	FRANCISCO DE ASSIS ALBUQUERQUE PAULINO	francisco@sfiec.org.br	cd735f7038	Tecnologia em Manutenção Industrial
201025260147	FRANCISCO EDSON LOPES DA SILVA	\N	33958765c7	Tecnologia em Manutenção Industrial
200825260011	FRANCISCO FERREIRA DE ARAUJO FILHO	dearaujofilho@hotmail.com	a2c9b1e8d3	Tecnologia em Manutenção Industrial
201025260198	FRANCISCO GILBERTO SILVA DE SOUZA JUNIOR	juniorcana@hotmail.com	974b7ad74b	Tecnologia em Manutenção Industrial
200915260193	FRANCISCO HALYSON FERREIRA GOMES	\N	f1aa005672	Tecnologia em Manutenção Industrial
20112043260186	FRANCISCO JOSÉ MARQUES LOPES	profmarques@gmail.com	2a37be8120	Tecnologia em Manutenção Industrial
200825260160	FRANCISCO PALECI ALVES DA COSTA JUNIOR	palecijunior@hotmail.com	da766719cd	Tecnologia em Manutenção Industrial
201115260103	FRANCISCO PETRUCIO ANDRADE DA SILVA	petruciokeybo@gmail.com	957a4f2c57	Tecnologia em Manutenção Industrial
200825260097	FRANCISCO SÉRGIO TOMÉ RODRIGUES	sergiotome28@yahoo.com	677f8df25e	Tecnologia em Manutenção Industrial
201115260111	FRANCISCO VALBERTO DE OLIVEIRA MOREIRA	valbertus@hotmail.com	3099285bac	Tecnologia em Manutenção Industrial
201115260308	GEYLSON FROTA DE SOUSA	geylson_fs@hotmail.com	8465c588f6	Tecnologia em Manutenção Industrial
20112043260259	GUILHERME ALEXANDRE BRAGA	guilherme_a_2@hotmail.com	c7d1d48c6a	Tecnologia em Manutenção Industrial
201015260110	HENRIQUE SOUZA SILVA	souzasilva.henrique@hotmail.com	8c1c8835c5	Tecnologia em Manutenção Industrial
200915260029	IGOR PORTELA COSTA	portela-costa@hotmail.com	f84a534535	Tecnologia em Manutenção Industrial
201115260065	ISNARD NORONHA BEZERRA	\N	dd7bec7473	Tecnologia em Manutenção Industrial
201115260316	JACKSON DENIS RODRIGUES DA COSTA	jacksondenisrodrigues@gmail.com	18c0508808	Tecnologia em Manutenção Industrial
200825260062	JAIANE DAS CHAGAS RODRIGUES	jaiane.rodrigues@gmail.com	9c1a12d507	Tecnologia em Manutenção Industrial
200825260194	JARDEL DE OLIVEIRA NOBRE	o.jardel@yahoo.com.br	774a53ee45	Tecnologia em Manutenção Industrial
201025260155	JEFFERSON DANTAS MARQUES	jdm_altosom@hotmail.com	88ee074b3c	Tecnologia em Manutenção Industrial
201025260163	JHONI DHEYCSON DOS SANTOS LIMA	frankjhony@gmail.com	37b85e6920	Tecnologia em Manutenção Industrial
20112043260194	JOÃO CARLOS BARBOSA DA SILVA	joao.c.barbosa@hotmail.com	5f793ef787	Tecnologia em Manutenção Industrial
201025260040	JOÃO VICTOR MARTINS RODRIGUES	joaovictormrodrigues@gmail.com	7744c6ca03	Tecnologia em Manutenção Industrial
201025260058	JOHN LENNON MAGALHÃES SOARES	john.magalhaes@hotmail.com	37776504fe	Tecnologia em Manutenção Industrial
20112043260208	JONAS OTHON PINHEIRO	othon.jp@gmail.com	61d6fd2b74	Tecnologia em Manutenção Industrial
200915260010	JONES CESAR OLIVEIRA BARBOSA	jones_barbosa@hotmail	3726ad81ba	Tecnologia em Manutenção Industrial
200915260118	JOSÉ WILSON DO NASCIMENTO JUNIOR	jot.ase@hotmail.com	d152d79ca9	Tecnologia em Manutenção Industrial
20112043260216	JOSIMAR DANTAS MARQUES	josimardantas_112@hotmail.com	3592b80d4e	Tecnologia em Manutenção Industrial
201015260144	JOSYANE DA SILVA SAMPAIO	josyane_sampaio@hotmail.com	8f19128d55	Tecnologia em Manutenção Industrial
201025260171	LEANDRO DE SOUSA DOS SANTOS	leandro_sousa26@yahoo.com.br	e9da15fbd2	Tecnologia em Manutenção Industrial
20112043260224	LEONARDO RODRIGUES MELO	leonardophysics@hotmail.com	e1d5bcaf85	Tecnologia em Manutenção Industrial
201115260324	LUANA DE SOUSA SANTOS	www.luanadesousasantos@yahoo.com.br	cec566beb3	Tecnologia em Manutenção Industrial
200915260037	LUANA LEMOS AMARAL	\N	66f3af50aa	Tecnologia em Manutenção Industrial
20112043260275	LUIZ HILANE VERAS DE ALMEIDA	hilanelhv@hotmail.com	727407acb2	Tecnologia em Manutenção Industrial
201015260306	LYSSA MOREIRA PIMENTA	lya_zinha@yahoo.com.br	b1f97e06f3	Tecnologia em Manutenção Industrial
20112043260232	MAGNA MARIA VITALIANO DA SILVA	magnavitaliano@gmail.com	de1a943b20	Tecnologia em Manutenção Industrial
200825260038	MANOEL ALEKSANDRE FILHO	aleksandref@gmail.com	2788e5ee77	Tecnologia em Manutenção Industrial
201015260179	MARCELO VIEIRA AMARO	marcelovieira.ce@gmail.com	f037c19331	Tecnologia em Manutenção Industrial
201115260014	MARCO CEZAR PINTO DE ARAGÃO	mcaragao@sfiec.org.br	8bed9ff383	Tecnologia em Manutenção Industrial
201115260162	MARCOS SABINO DE OLIVEIRA JUNIOR	msoj@bol.com.br	52f0f23321	Tecnologia em Manutenção Industrial
20112043260178	MARIA GABRIELA FREITAS SOARES	gabriela_bibi1993@hotmail.com	79bee9cc57	Tecnologia em Manutenção Industrial
201115260332	MILTON CÉZAR DA SILVA	miltoncezartfc@hotmail.com	cb70ab4de7	Tecnologia em Manutenção Industrial
20112043260313	MILTON NASCIMENTO DA SILVA FILHO	eumilton@bol.com.br	c88be3e2d4	Tecnologia em Manutenção Industrial
20112043260160	NALINE LI TAI MONTENEGRO GUERRA	naline_litai@hotmail.com	b56e1504dc	Tecnologia em Manutenção Industrial
200915260142	NATASHA LOPES GOMES	\N	4360a32d3a	Tecnologia em Manutenção Industrial
201015260195	NAYARA PEREIRA GOMES	nayaragomesng@gmail.com	1df66e4dd6	Tecnologia em Manutenção Industrial
201025260074	PAULO RICARDO GONÇALVES DA SILVA	ricardo-silvao2@hotmail.com	92a1aac495	Tecnologia em Manutenção Industrial
20112043260151	PEDRO FERNANDES DO NASCIMENTO JÚNIOR	pedro_jr32@hotmail.com	7135000be9	Tecnologia em Manutenção Industrial
201015260209	PHILIPPE GIORDAN AIRES ROCHA	philippe_giordan@hotmail.com	28ea387267	Tecnologia em Manutenção Industrial
200825260020	RAFAEL ALVES SARAIVA BARBOSA	\N	88a56ce5bd	Tecnologia em Manutenção Industrial
201025260228	RAFAEL DA SILVA OLIVEIRA	rafael.eletrica@yahoo.com.br	e6e0087d85	Tecnologia em Manutenção Industrial
20112043260143	RAFAEL MARQUES DA SILVA	theleafar18@hotmail.com	11c6336bcf	Tecnologia em Manutenção Industrial
20112043260291	RENAN DE ARAÚJO FARIAS	renan_araujo21@hotmail.com	875c58329b	Tecnologia em Manutenção Industrial
201015260225	RENATA DA SILVA BARROS	renata_eletro@hotmail.com	f6341c030e	Tecnologia em Manutenção Industrial
200825260143	RENATA IMACULADA SOARES PEREIRA	r.imaculada27@gmail.com	8a4ce6ce4e	Tecnologia em Manutenção Industrial
200825260151	RIBAMAR HOLANDA DO NASCIMENTO	ribamar_holanda@hotmail.com	53064cc5ac	Tecnologia em Manutenção Industrial
201015260233	RICARDO ALVES BATISTA	ricardoalves007@hotmail.com	5974b20272	Tecnologia em Manutenção Industrial
201115260189	RINALDO CARMO SOUZA JUNIOR	rinaldo.carmo@yahoo.com.br	3e72599c9b	Tecnologia em Manutenção Industrial
20112043260135	ROBSON SIMÃO DA CONCEIÇÃO	robyson1213@hotmail.com	cc084b03c5	Tecnologia em Manutenção Industrial
201025260090	RODRIGO SANTOS SILVA	digaozim_13@hotmail.com	23b4137cf0	Tecnologia em Manutenção Industrial
20112043260127	RODRIGO TAVARES DE OLIVEIRA	rodrigotavares_85@hotmail.com	448003b1fc	Tecnologia em Manutenção Industrial
201025260104	SAMUEL AUGUSTO FALCÃO	samuelfalcão@gmail.com	27bca8ca51	Tecnologia em Manutenção Industrial
20112043260119	SÉRGIO MURILO COSTA RIBEIRO	sergio_murilocr@hotmail.com	77d1072ba2	Tecnologia em Manutenção Industrial
20112043260305	TAIS DA SILVA BRASIL	taisbrasilde@hotmail.com	0f7e3ea3b7	Tecnologia em Manutenção Industrial
20112043260330	THALES BRUNO SILVA BORGES	thales-borges@hotmail.com	43265220fa	Tecnologia em Manutenção Industrial
201115260200	THIAGO LIMA SOARES	thiagoslash284@hotmail.com	3582c462f1	Tecnologia em Manutenção Industrial
201015260250	THIAGO ROCHA MOTA BARROS DE SOUZA	thiaguinho_425@hotmail.com	183b7fea9b	Tecnologia em Manutenção Industrial
201015260268	TIAGO RIBEIRO BARBOSA	tiagojovita@hotmail.com	c2e80b981e	Tecnologia em Manutenção Industrial
200825260186	VICTOR HUGO TAVARES DA SILVA	vhts2003@msn.com	dba6161543	Tecnologia em Manutenção Industrial
201115260197	VICTOR IURY LIMA NOGUEIRA	i-ury-2@hotmail.com	631ababdf0	Tecnologia em Manutenção Industrial
20112043260097	VICTOR PINHEIRO DE SOUSA	vitinhu_pinheiro@hotmail.com	28993c4b2e	Tecnologia em Manutenção Industrial
201025260112	VIVIANE COSTA DE SENA	vivianesena36@hotmail.com	ed24d47ef7	Tecnologia em Manutenção Industrial
200925260099	WEBSON BRUNO SANTOS DA SILVA	websonb@hotmail.com	e24e507868	Tecnologia em Manutenção Industrial
200915260070	YURI BRANDÃO DE MORAIS	yuri_deusgrego182@hotmail.com	ae1470bb75	Tecnologia em Manutenção Industrial
201015260101	HEMERSON FURTADO ARRUDA	myssuu@gmail.com	be133d1fee	Tecnologia em Manutenção Industrial
1544405	VENCESLAU XAVIER DE LIMA FILHO	venceslau@ifce.edu.br	d6d923ffd5	Servidores
4619376	FABRíCIO BANDEIRA DA SILVA	fabricio@ifce.edu.br	d32c053bbe	Servidores
200922310141	FELIPE DANIEL DE SOUSA BARBOSA	\N	e4d10a1a7b	Técnico em Informática
201022310216	FERNANDA STHÉFFANY CARDOSO SOARES	nandastheff@hotmail.com	0d3190de9f	Técnico em Informática
20112042310120	FLAVIANA DA SILVA NOGUEIRA LUCAS	alinefernandeslima@gmail.com	1a3ffc1408	Técnico em Informática
201022310038	FLAVIO CESA PEREIRA DA SILVA	t@t	058dfe175e	Técnico em Informática
201112310126	FRANCISCO AMSTERDAN DUARTE DA SILVA	amster1305@hotmail.com	c2d00bb9cf	Técnico em Informática
200922310168	FRANCISCO CLEDSON ARAÚJO OLIVEIRA	\N	1aa0ab560a	Técnico em Informática
20112044060296	RAFAEL FERNANDES DA SILVA	horakullo_solitario@hotmail.com	4916e6cfdf	Licenciatura em Química
20112044060300	RAFAELA DE LIMA SILVA	rafaella02@yahoo.com.br	30d3223c1d	Licenciatura em Química
20112044060318	ROGERIO OLIVEIRA DE SOUSA	ruguebombado@hotmail.com	6324773bb1	Licenciatura em Química
20112044060423	SEBASTIÃO NUNES CHAVES NETO	\N	a8de362232	Licenciatura em Química
20112044060326	SHEILA DA SILVA COSTA	sheyla_cozta@yahoo.com.br	53f18e47d8	Licenciatura em Química
20112044060334	SUANE DE OLIVEIRA SOUZA BRASIL	suane_brasil@hotmail.com	d9c00a2ea4	Licenciatura em Química
20112044060350	SUYANNE DO NASCIMENTO ALMEIDA	suyannenascimento@gmail.com	4be98deeea	Licenciatura em Química
201112330054	ANTONIA VALQUIRIA PEREIRA FIDELIS	valquiriafidelis@yahoo.com.br	d5f238acc5	Técnico em Meio-Ambiente
201112330062	ANTONIO ADRIANO MESQUITA ARAUJO	adriano_mexquita@hotmail.com	8e048acb56	Técnico em Meio-Ambiente
201112330070	BIANCA OLIVEIRA DA SILVA	\N	9394d9348a	Técnico em Meio-Ambiente
201112330089	CARLA AMANDA ROCHA AMARAL	amandinha14@hotmail.com	4c00329173	Técnico em Meio-Ambiente
201112330097	CARLOS EUGÊNIO MENDONÇA DA CUNHA FILHO	kaka5_@hotmail.com	751dda956b	Técnico em Meio-Ambiente
201022330128	CHRISTINA MOREIRA SOARES	chriss.ms@bol.com.br	48bf90d2fb	Técnico em Meio-Ambiente
201022330110	CÍCERO DE ARAÚJO NETO	ciceroaraujo.neto@gmail.com	96910c9c94	Técnico em Meio-Ambiente
201112330119	DANIEL MONTEIRO VASCONCELOS GOMES	danielgomes@mail.com	5979360b4b	Técnico em Meio-Ambiente
201112330127	DANIELA ALMEIDA CARNEIRO	\N	620e6a65f3	Técnico em Meio-Ambiente
201112330135	DAYANE BARROSO LUZ	dayaneblack@hotmail.com	a6fa1c5032	Técnico em Meio-Ambiente
201022330217	DERIK GONÇALVES MUNIZ	thomasderiksud@hotmail.com	bc68282fac	Técnico em Meio-Ambiente
201022330225	DIEGO CAMILO OLIVEIRA	diegocamilodco@gmail.com	e84cf34ae0	Técnico em Meio-Ambiente
201112330143	DIOGO ALVES PEREIRA	diogoalspe@hotmail.com	3114e64746	Técnico em Meio-Ambiente
201022330233	DIONE MARANHÃO DA SILVA	didionems@gmail.com	a5a13229c3	Técnico em Meio-Ambiente
201112330151	ELIZAMAR SILVA DE LIMA	lilikapink20@hotmail.com	882e12ec8a	Técnico em Meio-Ambiente
201112330160	ERBENE MARIA CAMPOS DA SILVA	erbene.campos@tbmtextil.com.br	42d9e52c6c	Técnico em Meio-Ambiente
201112330178	ERICA PEREIRA DA SILVA	erica.god@hotmail.com	adbcb4ff08	Técnico em Meio-Ambiente
201112330186	FRANCISCA ERICA BRITO DA COSTA	ericabrito02@yahoo.com.br	fc00d0a08a	Técnico em Meio-Ambiente
201022330268	FRANCISCO WELLINGTON SOARES OLIVEIRA	wellin2727@hotmail.com	4b7c6ff6eb	Técnico em Meio-Ambiente
201022330071	GENIELEN ANDRADE DA COSTA	genielenac19@gmail.com	0a418e002d	Técnico em Meio-Ambiente
201112330194	HORTENCIA RIBEIRO LIBERATO	hortencia_liberato@yahoo.com.br	77164b777a	Técnico em Meio-Ambiente
201022330080	JANDERSON SOARES SILVA	jhanders2@hotmail.com	13fe097a94	Técnico em Meio-Ambiente
201112330208	JARBAS WELEN DE OLIVEIRA LOURENÇO	ocara77_@hotmail.com	f752058cd6	Técnico em Meio-Ambiente
201112330224	JÉSSICA PEREIRA DE OLIVEIRA	jessica_tutye@hotmail.com	a74daec76f	Técnico em Meio-Ambiente
201022330101	JOICILENE MOREIRA DE LIMA	joiymoreira@yahoo	6fa4a6eb8f	Técnico em Meio-Ambiente
201022330136	JORGE LUIZ DE SOUZA EVARISTO	jl0807@hotmail.com	f763977c7e	Técnico em Meio-Ambiente
201022330152	JULIANA DA SILVA SOUZA	julyanass_93@hotmail.com	ddcc2bf1ed	Técnico em Meio-Ambiente
201112330240	LEIDEMARA NOGUEIRA DA SILVA	leidemaranogueira@yahoo.com.br	dafb8402ff	Técnico em Meio-Ambiente
201112330259	LEIDIANE DE OLIVEIRA BELARMINO	leidianedeoliveirab@gmail.com	2a6d9f64ef	Técnico em Meio-Ambiente
201112330267	LÍVYA THAMARA DE QUEIROZ FEITOSA	livya_feitosa5@hotmail.com	438ba970b8	Técnico em Meio-Ambiente
201112330275	LUIS HENRIQUE NASCIMENTO DE LIMA	luis.lima-93@hotmail.com	f2047b9c35	Técnico em Meio-Ambiente
201022330195	LUSTÓVÃO BEZERRA ARAÚJO	lustovao@hotmail.com	4d74165eb9	Técnico em Meio-Ambiente
201022330276	MARIA DANIELA DE FREITAS OLIVEIRA	daniela_bufy@hotmail.com	8e0ae3433b	Técnico em Meio-Ambiente
201022330284	MARIA ELANE DE MESQUITA ARAUJO	elane_ma@hotmail.com	8c0ef75d3d	Técnico em Meio-Ambiente
201022330292	MARIA EMMANUELLA DO NASCIMENTO	eh.manuh@gmail.com	1a7a51c26b	Técnico em Meio-Ambiente
201022330306	MARIA HELEN DIANE FERREIRA DA COSTA	ellenploct@hotmail.com	8600504f12	Técnico em Meio-Ambiente
201022330314	MARIA RENATA ALVES DA SILVA	rennattaalves@gmail.com.br	5870eccb1a	Técnico em Meio-Ambiente
201112330291	MARYLIA MORAES DE PAULA OLIVEIRA	marilia.moraes736@gmail.com	0967fe6cbb	Técnico em Meio-Ambiente
201112330305	MATEUS VIDAL AMARAL	mateus_vidal@live.com	2f25069d49	Técnico em Meio-Ambiente
201112330313	MAYARA GAMA DA CUNHA	gama.mayara@gmail.com	3aad4eda8d	Técnico em Meio-Ambiente
201112330321	MÉRCIA DO NASCIMENTO SANTOS	merciadonascimento@gmail.com	2df7d04d33	Técnico em Meio-Ambiente
201112330330	MILLENA HIPOLITO FREIRE	milena.hipolito@hotmail.com	4043f5ed77	Técnico em Meio-Ambiente
201022330420	NAIARA LOPES COELHO DE OLIVEIRA	naiara.lopes08@gmail.com	fe4aaffc6c	Técnico em Meio-Ambiente
201022330411	NATHALIA SOTERO RODRIGUES	nathalia.nathaliasotero@gmail.com	cafac6722a	Técnico em Meio-Ambiente
201112330348	NAYANE MARIA BARBOSA DE ARAUJO	nayanearaujo@hotmail.com	3ac66aae7e	Técnico em Meio-Ambiente
201112330356	PATRICIA MARQUES DUARTE	pattylica.vida@hotmail.com	6a4bcec003	Técnico em Meio-Ambiente
201112330372	RAFAELLY NAIRA DA SILVA	rafaellynaira@hotmail.com	b1d7ef7709	Técnico em Meio-Ambiente
201022330403	RAQUEL FERREIRA DA SILVA	raquel_loveyour@hotmail.com	cfc113ef2a	Técnico em Meio-Ambiente
201022330390	ROBSON DOS SANTOS MELO	robson_melo@ymail.com	84bfbf8e47	Técnico em Meio-Ambiente
201022330373	SARA HELLEN RODRIGUES SOUSA	sara_hellenzinha@hotmail.com	892a2276d2	Técnico em Meio-Ambiente
201112330380	SHELIDA CAVALCANTE FREIRE	shelidacavalcante@hotmail.com	6e1a522e70	Técnico em Meio-Ambiente
201022330365	SIMONE DA SILVA RODRIGUES LIMA	silmariapinck@hotmail.com	d8a3c1effe	Técnico em Meio-Ambiente
201112330399	VANESSA LIMA RAMALHO	nessinha_hermana2@hotmail.com	b423835d9b	Técnico em Meio-Ambiente
201022330357	WAGNER LIMA BARROS	wagnerlimb@oi.com.br	9182a0b61d	Técnico em Meio-Ambiente
201022330330	WERCAUTERES DA SILVA GARCES	wercauteres@hotmail.com	f53f2169c2	Técnico em Meio-Ambiente
201022330322	YURI DE JESUS JORGE SOARES	yujeso@yahoo.com	47c258218e	Técnico em Meio-Ambiente
201112330283	MARCIA BATISTA TORRES	marcinha_bt20@hotmail.om	452aa909d1	Técnico em Meio-Ambiente
201022330349	WASLEY CORREIA MARTINHO	\N	aeb9736277	Técnico em Meio-Ambiente
201022330020	ADALIA HIBIA MENDES PORTACIO	ahibiamp@gmail.com	84ea2a3f91	Técnico em Meio-Ambiente
201022330047	ALESSANDRO CAIQUE DA SILVA LIMA	alessandrocaiquedasilvalima3@gmail.com	4aeedcdac4	Técnico em Meio-Ambiente
201112330011	ALYNE BARBOSA JALES	alynne_100pop@hotmailcom	22730d3a4a	Técnico em Meio-Ambiente
201022330055	AMANDA RODRIGUES SANTOS SOARES	amandynha_nota10@hotmail.com	c8db7d045d	Técnico em Meio-Ambiente
201112330038	ANA BEATRIZ FÉLIX SAMPAIO	wan.mayara.cs@gmail.com	4f3e32cf21	Técnico em Meio-Ambiente
201022330098	ANTÔNIA DÁVILA AMARO PIRES	davilaamaro@gmail.com	32d99648df	Técnico em Meio-Ambiente
20112042330016	RAIMUNDO PEREIRA CAVALCANTE NETO	pcnetur27@hotmail.com	a54c9a63b1	Técnico em Meio-Ambiente
200922310621	FRANCISCO DARLILDO SOUZA LIMA	\N	0f501eb26e	Técnico em Informática
200822310018	FRANCISCO DAVID ALVES DOS SANTOS	\N	9869c2e740	Técnico em Informática
201112310355	FRANCISCO FERNANDES DA COSTA NETO	nennencfj@hotmail.com	e4b5594e80	Técnico em Informática
201012310094	FRANCISCO GUSTAVO CAVALCANTE BELO	gustavobelo123@gmail.com	425d0fdfd6	Técnico em Informática
200912310297	FRANCISCO JOAB MAGALHÃES ROCHA	\N	126f6635c5	Técnico em Informática
200912310130	FRANCISCO VENÍCIUS DA SILVA SANTOS	\N	ed02348f1e	Técnico em Informática
200912310157	FRANCISCO WANDERSON VIEIRA FERREIRA	\N	95232295a0	Técnico em Informática
20112042310139	GABRIEL BEZERRA SANTOS	bezerragb@hotmail.com	9ed2f9c9ca	Técnico em Informática
201012310175	GABRIEL DE SOUSA VENÂNCIO	gabriel.saxofone2009@gmail.com	023ae9aa5a	Técnico em Informática
201012310370	GÉFRIS DE LIMA PEREIRA	\N	bd15531f09	Técnico em Informática
201112310134	GIDEÃO SANTANA DE FRANÇA	gideaosf@gmail.com	176de222a8	Técnico em Informática
200922310206	GILMARA LIMA PINHEIRO	gillmarapinheiro@gmail.com	b5ec1b5969	Técnico em Informática
201112310142	GINALDO ARAÚJO DA COSTA JÚNIOR	juniorginaldo@yahoo.com.br	ddecbf3ae9	Técnico em Informática
201112310150	GLAILSON MONTEIRO LEANDRO	kailson_@hotmail.com	3804bcb972	Técnico em Informática
20112042310147	GREGORY CAMPOS BEVILAQUA	gregory-cb@hotmail.com	9251939b74	Técnico em Informática
20112042310155	HALECKSON HENRICK CONSTANTINO CUNHA	henrick_cc@hotmail.com	2ad2274a12	Técnico em Informática
201012310507	HANNAH PRESTAH LEAL RABELO	hannahrabelobol.com.br	4d4a4dc010	Técnico em Informática
200922310214	HELTON ATILAS ALVES DA SILVA	helton.atilas@hotmail.com	cba4c292c0	Técnico em Informática
201112310169	HERBET SILVA CUNHA	herbetsc@hotmail.com	860c0cacc5	Técnico em Informática
200922310222	IENDE REBECA CARVALHO DA SILVA	bekinha-carvalho@hotmail.com	1ba3236f90	Técnico em Informática
201022310364	ILANNA EMANUELLE MUNIZ SILVA	ilanna.emanuelle@hotmail.com	724bc15469	Técnico em Informática
201022310224	ISLAS GIRÃO GARCIA	\N	818dcdc665	Técnico em Informática
201112310037	ITALO DE QUEIROZ MOURA	italo_de_queiroz@hotmail.com	2b5ee5f7fc	Técnico em Informática
201022310470	JACKSON DENIS RODRIGUES DA COSTA	jacksondenisrodrigues@gmail.com	6758288cbb	Técnico em Informática
201112310177	JAMILLE DE AQUINO ARAÚJO NASCIMENTO	jamilles2@hotmail.com	7eebea2e11	Técnico em Informática
200822310220	JEAN LUCK CARDOSO DA SILVEIRA	\N	b9ca5f4735	Técnico em Informática
200922310249	JESSIMARA DE SENA ANDRADE	jessimara@oi.com.br	b19bac7c9e	Técnico em Informática
201012310310	JOÃO HENRIQUE RODRIGUES DOS SANTOS	henriquesantoslinux@gmail.com	6297fe0424	Técnico em Informática
20112042310163	JOÃO LUCAS DE FREITAS MATOS	lucas.freitas.matos@hotmail.com	b6c92a8041	Técnico em Informática
200912310394	JOÃO PEDRO MARTINS SALES	gaiiiatto@hotmail.com	bc719b3572	Técnico em Informática
201012310477	JOÃO RAPHAEL SILVA FARIAS	\N	c02729a511	Técnico em Informática
200922310257	JOÃO VICTOR RIBEIRO GALVINO	joaov777@gmail.com	0a93f8ca72	Técnico em Informática
201012310248	JOELSON FERREIRA DA SILVA	joellson_j@yahoo.com.br	989d82b432	Técnico em Informática
20112042310171	JOELSON FREITAS DE OLIVEIRA	jhoelsonmd@hotmail.com	94a9fb72dc	Técnico em Informática
20112042310180	JONATA ALVES DE MATOS	jonataamatos@hotmail.com	31fff55fe3	Técnico em Informática
201112310185	JONATAS HARBAS ALVES NUNES	jonatasnice@yahoo.co.uk	9925703e63	Técnico em Informática
200812300184	MARCUS HENRIQUE TEIXEIRA LIMA	\N	3b5a966f34	Técnico em Automação Industrial
20112042300192	MARIA IZABEL LIMA DE CARVALHO	mariaizabel_lima@hotmail.com	082f601c9e	Técnico em Automação Industrial
201022300202	MATEUS CAVALCANTE DA SILVA	mateus-cs-@hotmail.com	8f7c1ea0ed	Técnico em Automação Industrial
201012300129	MATHEUS ALVES VIEIRA	\N	0fd63f99bb	Técnico em Automação Industrial
201112300180	MAYARA MACHADO CARVALHO	mayaracarvalho@hotmail.com	bbab1c5cf3	Técnico em Automação Industrial
201022300237	MICAELE MAYRA TORRES HENRIQUE	micaele.mayra@gmail.com	7ae7bc04d3	Técnico em Automação Industrial
201112300198	MIGUEL ARCANJO ALMEIDA GOMES	arcanjorock@bol.com.br	3510323885	Técnico em Automação Industrial
201112300201	NATÁLIA FERNANDES CARVALHO	natalia151928@hotmail.com	6733f5cb99	Técnico em Automação Industrial
201112300210	NILTON CESAR QUINTINO RODRIGUES	niltoncqr@yahoo.com.br	d9a76babfb	Técnico em Automação Industrial
201012300285	OTACELIO GALBER MOTA SOUSA	gla200614@hotmail.com	b4e097d35a	Técnico em Automação Industrial
201112300228	PATRICK DE ARAÚJO SILVA	trick_araujo@hotmail.com	90fe72b2ac	Técnico em Automação Industrial
200912300089	PAULO ALAN MIRANDA DE MOURA	\N	20c02760cd	Técnico em Automação Industrial
201022300210	PAULO GUILHERME MORAES MARTINS	paulo_guil@hotmail.com	acb45bb5c0	Técnico em Automação Industrial
201116060019	JACKELINE CHAVES XAVIER	jackelinekell@yahoo.com.br	af7f141a3f	Licenciatura em Química
201116060027	JANAÍNA LIMA BELO FERNANDES	janabelo@yahoo.com.br	202c1862aa	Licenciatura em Química
200926060034	JEAN GLEISON ANDRADE DO NASCIMENTO	jandradenascimento@gmail.com	bbe72dc67c	Licenciatura em Química
201026060257	JÉSSICA EMILLY CAPISTRANO DE QUEIROZ	emilly.ifce@gmail.com	446c1ab8cd	Licenciatura em Química
201026060060	JÉSSICA MARIA REBOUÇAS DA COSTA	jessika_rebouças@hotmail.com	f00fc9de63	Licenciatura em Química
201016060076	JOAO CARLOS LIMA DE FARIAS	jclfarias@bol.com.br	65d87da789	Licenciatura em Química
200826060016	JONATHAN PAULO FERNANDES FERREIRA	\N	3e1d6b5806	Licenciatura em Química
201016060203	JORGE EDSON PINHEIRO DOS SANTOS	jepsa-015@hotmail.com	1520518df4	Licenciatura em Química
200826060148	JORGE LUIZ FERREIRA DA SILVA	jorgeluizfs@yahoo.com	58f29766c1	Licenciatura em Química
201026060079	JOSÉ MARIA ALMEIDA CAVALCANTE	jmacavalcante@hotmail.com	0aca29c2c9	Licenciatura em Química
201026060281	JOYCE ARGENTINO BARBOSA E ARAGÃO	joyceargentino@gmail.com	077d7b254e	Licenciatura em Química
201026060150	JULIANA DE CASTRO PORTACIO	juliana_portacio@hotmail.com	d1e8cc588b	Licenciatura em Química
201116060345	JULIO CESAR SANTOS ALMEIDA	juliocesar05_22@hotmail.com	884b0e1e8a	Licenciatura em Química
201016060068	KAREN STEFANE VIEIRA GUSMÃO	kstefane@gmail.com	8e12903428	Licenciatura em Química
201116060353	KARLA KELLY LIMA MONTEIRO	karla_black1@hotmail.com	60fe0c939a	Licenciatura em Química
201016060122	KATIANE FERREIRA RODRIGUES	katianerodrigues83@hotmail.com	040c91a046	Licenciatura em Química
201026060087	KEYLA DE SOUSA COSTA	keylacs@yahoo.com.br	780feb653d	Licenciatura em Química
201016060300	LARISSA GONÇALVES LIMA	llarajoe@yahoo.com.br	d1c39f81e3	Licenciatura em Química
200916060260	LARISSA PEREIRA SANTIAGO	larissantiago@hotmail.com	250070f59c	Licenciatura em Química
200926060026	LEIDEMARA NOGUEIRA DA SILVA	leidemaranogueira@yahoo.com.br	cb472fe8e2	Licenciatura em Química
201016060459	LEONARDO FIGUEIREDO SOARES	leo_work_id@hotmail.com	a71e280fb3	Licenciatura em Química
201016060424	LÍGIA CAMPOS CESÁRIO DE CARVALHO	lilicarvalhoo@hotmail.com	4a2a8fe13f	Licenciatura em Química
200826060164	LUCAS DE FRANCISCO DE SOUZA BARROS	\N	f328e2d0fd	Licenciatura em Química
201016060211	LUCIMÁRIO FRANCISCO COSTA BRASIL	lucimariofcb@gmail.com	f6fad016de	Licenciatura em Química
201116060140	LUIS CARLOS DANTAS COSTA	luis.dcosta@hotmail.com	922b8d6c55	Licenciatura em Química
201116060370	MANOEL DE CASTRO MAGALHAES	manoelcm@ymail.com	433d3ff645	Licenciatura em Química
201016060408	MANUEL AGAPITO DE SOUSA NETO	manuel.agapito@yahoo.com.br	d06e96354a	Licenciatura em Química
201026060095	MARCELO DIONÍZIO DOS SANTOS	marcelo_dio@hotmail.com	72bd0c9987	Licenciatura em Química
201016060220	MARIA ALDENIZA LAURENTINO DE LIMA	aldenibiomedicina@hotmail.com	394825c171	Licenciatura em Química
200826060075	MARIA DA GLORIA ARAÚJO COSTA	gloria_costa09@hotmail.com	6dac48ec36	Licenciatura em Química
200926060115	MARIA DO SOCORRO CALDAS TEOTONIO	mariasct@yahoo.com.br	c37502e67d	Licenciatura em Química
200916060015	MARIA GORETTI SABINO CORDEIRO	\N	1e0599f514	Licenciatura em Química
200826060113	MARIA JULIETE FERREIRA DE SOUZA	\N	07ac486ad6	Licenciatura em Química
201026060109	MARIA PRISCILA HOLANDA SANTOS	prisla93@hotmail.com	4df5195d99	Licenciatura em Química
201016060190	MARIA ROSANE DA SILVA RODRIGUES	mrosane1992@hotmail.com	f22d11932e	Licenciatura em Química
200916060295	MARIA ROSANGELA MOURA DE OLIVEIRA	nem_nobre@hotmail.com	647d18eb7a	Licenciatura em Química
200916060201	MARIA ZÉLIA SILVA DE FREITAS	\N	ed9b98938d	Licenciatura em Química
201026060222	MARIA ZENEUDA MOREIRA	mzeneudam@bol.com.br	07d98313da	Licenciatura em Química
201116060221	MARIANE VASCONCELOS BEZERRA	marianee.23@gmail.com	47f2f80042	Licenciatura em Química
201026060117	MARILIA HOSSAINNY BARRETO ARAÚJO DANTAS	\N	e69be9f377	Licenciatura em Química
201116060230	MAYARA MESQUITA SANTIAGO	\N	572d0e38bf	Licenciatura em Química
200826060083	MAYRA PONTES DE QUEIROZ	mayrapqueiroz@hotmail.com	9775ad10e2	Licenciatura em Química
201016060165	MELKA DOURADO RIOS	www.mel.rios@bol.com.br	faef04b810	Licenciatura em Química
201016060327	MILVIA RODRIGUES DA COSTA	mia.rodrigues@yahoo.com.br	4be47d0ee6	Licenciatura em Química
200826060040	MONALISA MARIA TEIXEIRA LIMA	\N	891b98245b	Licenciatura em Química
201026060184	MÔNICA BANDEIRA LOURENÇO	monica.b.l@hotmail.com	528f665b2c	Licenciatura em Química
201026060125	NARAH WELLEN VIRGINIO RODRIGUES DA SILVA SOUSA	narahwellen@hotmail.com	0e4b4139b7	Licenciatura em Química
200826060199	NATHALIA SOTERO RODRIGUES	nathalia.nathaliasotero@gmail.com	c31eedeb63	Licenciatura em Química
201116060159	NYCAELLE MEDEIROS MAIA	nycaelle11@hotmail.com	718d33c4aa	Licenciatura em Química
200926060182	PAULO ELTON COSTA PAIVA	\N	778ca9b7a2	Licenciatura em Química
201016060432	PAULO GIUSEPPE PINÉO ARAÚJO	paulinho.giuseppe@gmail.com	9121cc05c9	Licenciatura em Química
201026060249	PAULO SÉRGIO SILVA DE OLIVEIRA	pauloxathebest@gmail.com	555c0f59e7	Licenciatura em Química
201116060183	RAFAEL MARTINS DE SOUSA	rafaeleminem.martins@gmail.com	800141ae42	Licenciatura em Química
200916060376	RENATO ALAN SILVA DUARTE	renatoalansilvad@hotmail.com	4e2a465a9b	Licenciatura em Química
200926060123	RICARLOS PEREIRA DE MELO	ricarlosmelo@gmail.com	928088a1c6	Licenciatura em Química
200826060067	RYVANA ARAGÃO DE PAIVA	ihellyryvana@yahoo.com.br	3ddc7eca5b	Licenciatura em Química
201116060400	SAMANDA ARIMATEA DE SA	samandapat@hotmail.com	5186ae3bbe	Licenciatura em Química
200916060147	SAMYA MARA HENRIQUE NOBRE	\N	7df5ca43c9	Licenciatura em Química
200926060131	SANDRO ALMEIDA BORÉM	sandroborem@yahoo.co.uk	03f9fb55a3	Licenciatura em Química
200926060140	SÁVIA DUARTE PAIVA	savia.seliga@gmail.com	16c58ff192	Licenciatura em Química
200826060130	SERGIMAR KENNEDY DE PAIVA PINHEIRO	\N	f92b86e711	Licenciatura em Química
200926060166	TACITO TRINDADE DE PAIVA	moiseseudocio@yahoo.com.br	9ea6e74a6b	Licenciatura em Química
200916060392	TAINAH PEREIRA DE ANDRADE	tatah_tpa@hotmail.com	4533b780a3	Licenciatura em Química
200826060024	TÁSSIA PINHEIRO DE SOUSA	taty_piaui@hotmail.com	41c40e4214	Licenciatura em Química
200916060325	ANA LÍDIA DE ARAÚJO GOMES	ana18gomes@gmail.com	d82a181f6a	Licenciatura em Química
201116060108	ANDREA ALMEIDA DE SOUSA	andreaamaris@globo.com	1c4799be5f	Licenciatura em Química
201026060010	ANNE KATIÚSCIA COSTA COUTO	annekatiuscia-bio@yahoo.coom.br	fbdf13bb98	Licenciatura em Química
201016060092	ANTÔNIO CARLOS FERREIRA ALMEIDA	pinbeiros@yahoo.com.br	5ab0a33c70	Licenciatura em Química
200926060085	ANTONIO FABIO SAMPAIO	fabiodoutorx@yahoo.com.br	5e046a897b	Licenciatura em Química
201016060149	ANTONIO GILMÁRCIO RODRIGUES DE LIMA	antoniogilmarcio@hotmail.com	8282b08b65	Licenciatura em Química
200916060252	ANTONIO KLINGEM LEITE DE FREITAS	\N	0232750e17	Licenciatura em Química
201016060416	ANTONIO SERGIO ARAUJO HOLANDA FILHO	sergioruivao@hotmail.com	3dbc8286f3	Licenciatura em Química
201026060028	BRENA BARBOSA DA SILVA	brenna_tex@hotmail.com	e5f04610ac	Licenciatura em Química
201026060036	BRENDA CRISTINE LIMA DE OLIVEIRA	brendalima182@hotmail.com	8d738b5eba	Licenciatura em Química
201116060035	CAIO VICTOR PEREIRA PASCOAL	caiovictorppascoal@gmail.com.br	4e4eb9aa77	Licenciatura em Química
201116060264	CAMILA EVELIN AMORIM FERREIRA	mila-catwca@hotmail.com	699b10ec55	Licenciatura em Química
201116060272	CARLOS AUGUSTO FREITAS DIAS	augustooperacional@yahoo.com	8b71f032a4	Licenciatura em Química
201016060084	CRISTIANO DE GONZAGA SOUSA	sircsousa@yahoo.com.br	360e81363e	Licenciatura em Química
201116060280	CRISTIANO DUARTE	duarte596@gmail.com	adc7a9bbca	Licenciatura em Química
200916060198	CYNTHIA GABRIELLE DA SILVA COSTA	\N	bb20ce8e24	Licenciatura em Química
201016060386	DANIEL MARTINS DE OLIVEIRA	danieldovest@gmail.com	9900c0e045	Licenciatura em Química
201116060299	DANIELE ARAUJO DA SILVA	danynanao@hotmail.com	0109081086	Licenciatura em Química
201016060238	DÉBORA CRISTINA LIMA FERREIRA	deboracristinaferreira@gmail.com	aaab77f3da	Licenciatura em Química
201116060043	DEBORA REIS COSTA	deborareis87@gmail.com	d47f126db1	Licenciatura em Química
200825260208	JOELDO NÁPOLES GOMES	\N	5c40f5c545	Tecnologia em Manutenção Industrial
201026060044	DIEGO VIANA DAMASCENO	vianadamasceno@bol.com.br	8f77e25374	Licenciatura em Química
201026060176	DIONE MARANHÃO DA SILVA	didionems@gmail.com	440743fd1e	Licenciatura em Química
200826060210	EDINEY BERNARDO LIMA	edineybernardo@yahoo.com.br	bf75c0da64	Licenciatura em Química
201016060050	EDIU CARLOS LOPES LEMOS	ediucarlos@yahoo.com.br	ef712780a9	Licenciatura em Química
200826060172	ÉLIDA SOLON DE OLIVEIRA	\N	44eb07e72b	Licenciatura em Química
200916060236	ELIELTON OLIVEIRA BRANDÃO	elielob@hotmail.com	3eb556a05e	Licenciatura em Química
201016060440	EMANUELE PAULA DA SILVA FERREIRA	emanuelepaula@yahoo.com.br	49fd367c5f	Licenciatura em Química
201016060378	EMANUELY OLIVEIRA DOS SANTOS	expedicaofor@facepa.com.br	a1607b1a3b	Licenciatura em Química
200926060050	ERICA YASMINE FERREIRA VERAS	ericayasmine@hotmail.com	6259ffbf14	Licenciatura em Química
200826060105	ERIKA SALES LÔBO DA SILVA	erika@vicunha.com.br	9307f39383	Licenciatura em Química
201116060060	ERLAN DA SILVA NOGUEIRA	erlanstaynight@yahoo.com	418b307f04	Licenciatura em Química
200826060059	EZEQUIEL GOMES CORREIA	\N	595e9ed70b	Licenciatura em Química
200926060042	FELIPE ALVES SILVEIRA	felippecaopg@hotmail.com	7f583bacd3	Licenciatura em Química
201016060262	FELIPE DA SILVA BERNARDO	felipebernardo-lbi@oi.com.br	d178f882c2	Licenciatura em Química
201016060360	FRANCISCA GABRIELA JUCÁ DE MELO	\N	fb7afdd1c6	Licenciatura em Química
201026060192	FRANCISCO DE ASSIS LEMOS DA SILVA	\N	36033a036f	Licenciatura em Química
201016060343	FRANCISCO ERANDIR CORDEIRO	wesllen1717@gmail.com	15c2f0a544	Licenciatura em Química
200826060156	FRANCISCO NARLEYSON BATISTA MOREIRA	narley_2005@hotmail.com	e563989ae1	Licenciatura em Química
201116060086	GABRIELA MOTA CARAPETO	gabrielacarapeto@hotmail.com	c171a79576	Licenciatura em Química
201026060230	GABRIELLY FERREIRA MOTA	gabriellyferreyra@hotmail.com	26afd67e57	Licenciatura em Química
201016060254	GILVANIA OLIVEIRA ALVES	goajc@bol.com.br	807d6a03e8	Licenciatura em Química
201116060094	GREYCIANNE FELIX CAVALCANTE	greycianne.felix@gmail.com	729f048701	Licenciatura em Química
200916060210	INAIÁ LOPES GUERREIRO	naiaeotinha@hotmail.com	47ee609176	Licenciatura em Química
20112042300206	PAULO HENRIQUE SILVA DE LIMA	adrysson_rrr@hotmail.com	3f544f63ac	Técnico em Automação Industrial
201017050023	ADILIO MOURA COSTA	adilio_costa27@yahoo.com.br	25eab8abe0	Ciência da Computação
200917050269	ADONIAS CAETANO DE OLIVEIRA	\N	3630cc1140	Ciência da Computação
20112045050014	ADRIANO DE LIMA SANTOS	adrianoplayer@hotmail.com	4e58928b82	Ciência da Computação
201027050280	AISSE GONÇALVES NOGUEIRA	aissegn@yahoo.com.br	c9c1f3aa1e	Ciência da Computação
201027050018	ALCILIANO DA SILVA LIMA	alci987@hotmail.com	806b0e4888	Ciência da Computação
201017050090	ALDISIO GONÇALVES MEDEIROS	aldisiog@gmail.com	46f2fa6017	Ciência da Computação
201027050298	ALISSON DA SILVA OLIVEIRA	ifor070@terra.com.br	c98d05b989	Ciência da Computação
200917050072	ALISSON SAMPAIO DE CARVALHO ALENCAR	alisson_1945@yahoo.com.br	1f104ed89c	Ciência da Computação
201117050181	AMANDA AZEVEDO DE CASTRO FROTA ARAGAO	amandazevedo_@hotmail.com	d881f5f161	Ciência da Computação
200927050016	AMANDA DIOGENES LUCAS	manda_zita@hotmail.com	174e2d27cc	Ciência da Computação
201117050173	AMAURI AIRES BIZERRA FILHO	liger_i@hotmail.com	476de26557	Ciência da Computação
20112045050022	ANDRE LUIS VIEIRA LEMOS	andre_luis_vieira_lemos@yahoo.com.br	49d0e8e0c2	Ciência da Computação
200827040353	EMANUEL DUARTE SILVA	\N	2bc0ad4200	Engenharia Ambiental
201017040370	LIZ NASCIMENTO CARVALHO	lizncarvalho@yahoo.com.br	069f3224c2	Engenharia Ambiental
200826060180	DEMÉTRIUS BEZERRA ROCHA	\N	9b546c44f9	Licenciatura em Química
20112042300281	ELIARDO DOS SANTOS CHAGAS	\N	96c593c2d2	Técnico em Automação Industrial
201117050165	AMSRANON GUILHERME FELICIO GOMES DA SILVA	amsranon.ag@hotmail.com	81fe606226	Ciência da Computação
20112045050308	ANTONIO RENAN ROGERIO PAZ	antoniorenan@pmenos.com.br	0a84dc5aef	Ciência da Computação
201117050203	ARLEN ITALO DUARTE DE VASCONCELOS	aim_ceara03@hotmail.com	8e68b7d210	Ciência da Computação
201027050123	ARLESSON LIMA DOS SANTOS	lessonpotter@gmail.com	7d9b0123b4	Ciência da Computação
201017050171	ÁTILA CAMURÇA ALVES	camurca.home@gmail.com	e3dfc6cb39	Ciência da Computação
20112045050030	ATILA SOUSA E SILVA	atila.tibiano@hotmail.com	96671e676e	Ciência da Computação
201117050017	AUGUSTO EMANUEL RIBEIRO SILVA	augustoers@gmail.com	c5cc072184	Ciência da Computação
201027050131	BRENDO DE SOUSA ALVES	brendo2008@gmail.com	0628abe77b	Ciência da Computação
20112045050049	BRUNO FERREIRA ALENCAR	bruno_tsunami_8@hotmail.com	1308771332	Ciência da Computação
200927050024	CAMILA LINHARES	linhares.mila@gmail.com	ca71a02a34	Ciência da Computação
200917050030	CARLOS ADAILTON RODRIGUES	adtn700@yahoo.com.br	8905780c46	Ciência da Computação
201117050033	CLAYTON BEZERRA PRIMO	claytonbp@oi.com.br	bc4f9131bf	Ciência da Computação
20112045050294	DANIEL ALVES PAIVA	danielpaiva.alves@gmail.com	8b34798454	Ciência da Computação
201117050157	DANIEL JEAN RODRIGUES VASCONCELOS	cefet_daniel@yahoo.com.br	859a36acc5	Ciência da Computação
200927050040	DANIELE MIGUEL DA SILVA	danyelle.diasd@gmail.com	a8b158ed0d	Ciência da Computação
201027050140	DARIO ABNOR SOARES DOS ANJOS	darioabnor@gmail.com	5ff644015e	Ciência da Computação
20112045050057	DAVI FONSECA SANTOS	ivadlocks@gmail.com	4897244e12	Ciência da Computação
200927050059	DENYS ABNER SANTOS BEZERRA	denys_abner@hotmail.com	d086fd8dca	Ciência da Computação
20112045050073	DIEGO DO NASCIMENTO BRITO	diiego.britto@gmail.com	63217e09d9	Ciência da Computação
20112045050065	DIEGO FARIAS DE OLIVEIRA	diegofarias06@hotmail.com	1703da3b90	Ciência da Computação
201117050149	DIEGO GUILHERME DE SOUZA MORAES	digui.info@gmail.com	d402eb3ae4	Ciência da Computação
200917050021	DIÊGO LIMA CARVALHO GONÇALVES	zyhazz@msn.com	88c2fec6b7	Ciência da Computação
201027050158	EDSON ALVES MELO	edsonbs8@hotmail.com	2e4c0fa47b	Ciência da Computação
201117050041	ELTON NOBRE MORAIS	elton.nobre@live.com	bcc47f794f	Ciência da Computação
200917050102	EMANUEL SILVA DOMINGOS	emanuelsdrock@gmail.com	f423da2ccc	Ciência da Computação
201017050210	EMANUELLA GOMES RIBEIRO	emma.taylor.49@gmail.com	f6114d5a87	Ciência da Computação
200927050067	ÉRICA MARIA GUEDES RODRIGUES	ericaguedes.ifce@gmail.com	f8be221153	Ciência da Computação
200927050075	ERYKA FREIRES DA SILVA	eryka.setec@gmail.com	ffea4934cd	Ciência da Computação
201027050220	FAUSTO SAMPAIO	fausto.cefet@gmail.com	17c04acb12	Ciência da Computação
20112045050081	FELIPE MARCEL DE QUEIROZ SANTOS	kreator6@hotmail.com	6cfc4e971b	Ciência da Computação
20112045050090	FLAVIANA CASTELO BRANCO CARVALHO DE SOUSA	flavi.fairy@gmail.com	1bb97bf7fc	Ciência da Computação
200917050080	FRANCISCO ANDERSON FARIAS MACIEL	andersonfariasm@gmail.com	14e82f7f56	Ciência da Computação
200917050137	FRANCISCO DANIEL BEZERRA DE CARVALHO	vanessacordeiro@oi.com.br	441018a049	Ciência da Computação
20112045050286	FRANCISCO LEANDRO HENRIQUE MOREIRA	flhm.le@oi.com.br	d49214372b	Ciência da Computação
20112045050260	GILLIARD FERREIRA DA SILVA	gil.palmeiras@hotmail.com	a2ae935da6	Ciência da Computação
201027050069	HELIONEIDA MARIA VIANA	helioneida-viana@hotmail.com	04f274d48f	Ciência da Computação
201117050246	IAGO BARBOSA DE CARVALHO LINS	rhcpiagoiron@hotmail.com	31af0d6b26	Ciência da Computação
20112045050103	IENDE REBECA CARVALHO DA SILVA	bekinha-carvalho@hotmail.com	908f485dd8	Ciência da Computação
201117050050	ISAAC THIAGO OLIVEIRA CAVALCANTE	isaaccavalcante@ymail.com	3bbf550ceb	Ciência da Computação
201117050068	ISRAEL SOARES DE OLIVEIRA	liceudecaucaia_2@yahoo.com.br	b60857a0e7	Ciência da Computação
20112045050111	ITALO MESQUITA VIEIRA	italo_mbs@hotmail.com	81be06904b	Ciência da Computação
200927050091	JARDEL DAS CHAGAS RODRIGUES	jardel_19@hotmail.com	2628bf4b88	Ciência da Computação
201117050076	JEFTE SANTOS NUNES	jeftenunes@hotmail.com	d467051284	Ciência da Computação
200927050105	JÉSSICA GOMES PEREIRA	jessk.gms@gmail.com	5b1f3687b4	Ciência da Computação
201117050084	JHON MAYCON SILVA PREVITERA	j_may_con@hotmail.com	0f2f032ecb	Ciência da Computação
200917050145	JOÃO FELIPE SAMPAIO XAVIER DA SILVA	\N	2058f45043	Ciência da Computação
201017050040	JOÃO GOMES DA SILVA NETO	joao.gsneto@gmail.com	e8a4e72ee7	Ciência da Computação
20112045050120	JOÃO GUILHERME COLOMBINI SILVA	joao.guil.xd@gmail.com	b7effec340	Ciência da Computação
200927050113	JOAO OLEGARIO PINHEIRO NETO	olegarioifce@hotmail.com	57c693cd81	Ciência da Computação
200927050121	JOÃO PEDRO MARTINS SALES	gaiiiatto@hotmail.com	e1df2b1202	Ciência da Computação
20112045050138	JOHN DHOUGLAS LIRA FREITAS	johndhouglas@gmail.com	66e91cf964	Ciência da Computação
200917050277	JONAS FEITOSA CAVALCANTE	\N	ca221a66f5	Ciência da Computação
200917050064	JONAS RODRIGUES VIEIRA DOS SANTOS	jonascomputacao@gmail.com	14cfbd3624	Ciência da Computação
201027050301	JORGE FERNANDO RAMOS BEZERRA	marvinjfpg@hotmail.com	0233e66766	Ciência da Computação
200927050130	JOSE BARROSO AGUIAR NETO	jotabe1990@hotmail.com	05157a8689	Ciência da Computação
200917050170	JOSÉ MACEDO DE ARAÚJO FILHO	corujaraylander@hotmail.com	a2a63b47b3	Ciência da Computação
201117050190	JOSÉ PAULINO DE SOUSA NETTO	paulino_netto27@hotmail.com	05c8a0d084	Ciência da Computação
200917050099	JOSÉ TUNAY ARAÚJO	\N	232da07bbb	Ciência da Computação
200927050148	JOSERLEY PAULO TEOFILO DA COSTA	yosef.j@hotmail.com	95559125fc	Ciência da Computação
201017050236	JOVANE AMARO PIRES	jovanepires@ymail.com	160c3de89d	Ciência da Computação
200927050156	JOYCE SARAIVA LIMA	jojosl@hotmail.com	7d085b090b	Ciência da Computação
201027050174	JULIANA LIMA GARÇA	julianagarca@gmail.com	69c792e848	Ciência da Computação
200917050293	JULIANA PEIXOTO SILVA	juliana.compifce@gmail.com	604ed63871	Ciência da Computação
20112045050316	KAIO HEIDE SAMPAIO NOBREGA	kaio.heide@gmail.com	4939b8d261	Ciência da Computação
201027050182	KAUÊ FRANCISCO MARCELINO MENEZES	kaue-menezes@hotmail.com	b5b31d8104	Ciência da Computação
200927050164	KILDARY JUCÁ CAJAZEIRAS	kildarydoido@yahoo.com.br	4916cbfa43	Ciência da Computação
200927050172	KLEBER DE MELO MESQUITA	kleber.kmm@hotmail.com	ad3c33da63	Ciência da Computação
201017050066	KLEVERLAND SOUSA FORMIGA	kleverland@yahoo.com.br	66609eee0f	Ciência da Computação
201027050190	LEANDRO BEZERRA MARINHO	leandrobmarinho@hotmail.com	7162f7372e	Ciência da Computação
201027050204	LEANDRO MENEZES DE SOUSA	leomesou@yahoo.com.br	563d94c126	Ciência da Computação
201117050130	LEEWAN ALVES DE MENESES	leewanalves@hotmail.com	164dc77bdb	Ciência da Computação
200927050180	LEONILDO FERREIRA DE ABREU	leonildoabreu@yahoo.com.br	c27f9cec37	Ciência da Computação
200927050199	LEVI VIANA DE ANDRADE	levi_viana_@hotmail.com	dd3c4fc5b3	Ciência da Computação
201027050271	LÍVIO SIQUEIRA LIMA	lslprogramador@gmail.com	0dcd54937f	Ciência da Computação
201017050112	LUANA DE OLIVEIRA CORREIA	luana.oc@hotmail.com	35741d6318	Ciência da Computação
201017050074	LUANA GOMES DE ANDRADE	j.kluana@gmail.com	16d1f521fd	Ciência da Computação
201117050122	LUCAS SILVA DE SOUSA	lucas.xmusic@hotmail.com	e2a18af6cb	Ciência da Computação
20112045050146	LUCIANA SA DE CARVALHO	lucianasa.jc@gmail.com	61c9c443da	Ciência da Computação
201017050104	LUÉLER PAIVA ELIAS	lueler_elias@hotmail.com	a049d5b903	Ciência da Computação
20112045050154	LUIS CLAUDIO COSTA CAETANO	lcccaetano@yahoo.com.br	4283bdb913	Ciência da Computação
201017050139	LUIS RAFAEL SOUSA FERNANDES	l.rafilx@globomail.com	5eba693731	Ciência da Computação
201017050295	MAGNO BARROSO DE ALBUQUERQUE	mag.albuquerque@gmail.com	9447bd3146	Ciência da Computação
200927050202	MAIARA MARIA PEREIRA BASTOS SOUSA	maiampb@yahoo.com.br	5afa12ff89	Ciência da Computação
201017050120	MAIKON IGOR DA SILVA SOARES	maikonigor@gmail.com	ab05d82991	Ciência da Computação
201017050252	MARCOS PAULO LIMA ALMEIDA	marck_migo@hotmail.com	eb1d48c857	Ciência da Computação
201027050239	MATEUS PEREIRA DE SOUSA	infomateus@hotmail.com	8df7bdfad8	Ciência da Computação
200927050210	MATHEUS ARLESON SALES XAVIER	iceman_nfsu@hotmail.com	645e1f4979	Ciência da Computação
20112045050162	MATHEUS TAVEIRA SOARES	mmetheus@hotmail.com	d4f08d5668	Ciência da Computação
201017050058	MAXSUELL LOPES DE SOUSA BESSA	iniciusx@gmail.com	d07598d2fe	Ciência da Computação
20112045050197	MERCIA OLIVEIRA DE SOUSA	mercia_butterfly@hotmail.com	d9cbe6ce68	Ciência da Computação
201017050287	MOISÉS LOURENÇO BANDEIRA	moresain@hotmail.com	d3fb805ef6	Ciência da Computação
201117050270	MURILLO BARATA RODRIGUES	murillobarata@hotmail.com	8ac7096940	Ciência da Computação
200917050129	NEYLLANY ANDRADE FERNANDES	neyllany@hotmail.com	bb2cadd18c	Ciência da Computação
201117050289	NYKOLAS MAYKO MAIA BARBOSA	nykolasmayko2@globo.com	7fa614bf21	Ciência da Computação
20112045050219	PAULO ANDERSON FERREIRA NOBRE	paulo_anderson14@hotmail.com	172179d022	Ciência da Computação
201027050212	PAULO PEREIRA GUALTER	paulogualter@ig.com.br	4f809ea00a	Ciência da Computação
200927050237	PEDRO ITALO BONFIM LACERDA	pedro.3v@hotmail.com	8c11b2dbfe	Ciência da Computação
200917050013	PÉRICLES HENRIQUE GOMES DE OLIVEIRA	pericles_henrique@yahoo.com.br	4d1e27d70f	Ciência da Computação
200917050242	PHYLLIPE DO CARMO FELIX	phyllipe_do_carmo@hotmail.com	8c8699e8b4	Ciência da Computação
20112045050278	PRISCILA FEITOSA DE FRANÇA	priscilapff@gmail.com	b280cc9617	Ciência da Computação
201027050247	RAFAEL BEZERRA DE OLIVEIRA	rafaelbezerra195@gmail.com.br	d62d754422	Ciência da Computação
201017050015	RAFAEL SILVA DOMINGOS	rafaelsdomingos@gmail.com	3942bfcee3	Ciência da Computação
201017050279	RAFAEL SOARES RODRIGUES	rafael88.soares@hotmail.com	03f9420985	Ciência da Computação
201027050255	RAFAEL VIEIRA MOURA	rafael-.-vieira@hotmail.com	27972da55f	Ciência da Computação
201117050092	RALPH LEAL HECK	imagomundi@hotmail.com	9cf975f782	Ciência da Computação
200927050253	RAPHAEL ARAÚJO VASCONCELOS	rapha_araujo_vasconcelos@hotmail.com	a670f640e7	Ciência da Computação
200917050285	REGINALDO FREITAS SANTOS FILHO	\N	d2f8ce4954	Ciência da Computação
20112045050227	REGINALDO MOTA DE SOUSA	sousa.rmt@gmail.com	e5d015e1d7	Ciência da Computação
200917050048	REGIO FLAVIO DO SANTOS SILVA FILHO	reginho.flavio@gmail.com	d6bbe68dd5	Ciência da Computação
201117050114	RENAN ALMEIDA DA SILVA	renanteclado@yahoo.com.br	9c175b4bde	Ciência da Computação
201017050082	RICARDO VALENTIM DE LIMA	ricardol@chesf.gov.br	1502c130fa	Ciência da Computação
20112045050235	RIMARIA DE OLIVEIRA CASTELO BRANCO	rimaria_ocb@hotmail.com	953d327a27	Ciência da Computação
200917050161	ROMULO LOPES FRUTUOSO	frutuoso.romulo@gmail.com	cf553c4df9	Ciência da Computação
200917050218	SAMIR COUTINHO COSTA	samirfor@gmail.com	a924a330b2	Ciência da Computação
201117050297	SAMUHEL MARQUES REIS	samuhel.e.reis@hotmail.com	248f1fc15a	Ciência da Computação
200927050261	SAULO ANDERSON FREITAS DE OLIVEIRA	saulo.ifet@gmail.com	7366241a99	Ciência da Computação
200917050234	SHARA SHAMI ARAÚJO ALVES	shara.alves@gmail.com	3ee6ec0939	Ciência da Computação
200927050270	STÉFERSON SOUZA DE OLIVEIRA	stefersonsouza@hotmail.com	520808c7f1	Ciência da Computação
201027050107	SYNARA DE FÁTIMA BEZERRA DE LIMA	syfafa@hotmail.com	ebf23cc979	Ciência da Computação
201017050198	THEOFILO DE SOUSA SILVEIRA	lucelia_souto@yahoo.com.br	49c24c8dcd	Ciência da Computação
201027050263	TIAGO CORDEIRO ARAGÃO	tiago.ifet@gmail.com	50c9743b86	Ciência da Computação
201017050309	VALRENICE NASCIMENTO DA COSTA	valrenice@yahoo.com.br	642bfa13e2	Ciência da Computação
201017050260	VICTOR DE OLIVEIRA MATOS	victormanch@hotmail.com	7ae4a54190	Ciência da Computação
200927050288	WAGNER ALCIDES FERNANDES CHAVES	waguimch@yahoo.com.br	80aa05d53b	Ciência da Computação
20112045050251	WAGNER DOUGLAS DO NASCIMENTO E SILVA	wagner.doug@hotmail.com	ca4cf99e5e	Ciência da Computação
200927050296	WALLISSON ISAAC FREITAS DE VASCONCELOS	wallissonisaac@gmail.com	a413870e38	Ciência da Computação
201017050155	WEMILY BARROS NASCIMENTO	wbn.power@hotmail.com	41dcb57a36	Ciência da Computação
200917050153	WILLIAM VIEIRA BASTOS	will.v.b@hotmail.com	d99eabc389	Ciência da Computação
20112045050243	YCARO BRENNO CAVALCANTE RAMALHO	ycarob.cavalcante@hotmail.com	43e6f55ad6	Ciência da Computação
200817040121	MARCELA DE FÁTIMA OLIVEIRA LAVOR	\N	a78b5db55b	Engenharia Ambiental
200917040476	MARCÍLIO OLIVEIRA MOURA	\N	988b09d829	Engenharia Ambiental
200917040301	ADA RACHEL BATISTA FERREIRA 	\N	3b39755d57	Engenharia Ambiental
200917040450	ADELLE AZEVEDO FERREIRA	\N	34ccf584b9	Engenharia Ambiental
200817040210	ADRIANO DO NASCIMENTO CARDOSO	\N	4c5c3c8dc5	Engenharia Ambiental
201117040011	ADRYANE MARQUES MORAES	adryanemm@gmail.com	1b6cb738c9	Engenharia Ambiental
20112045040019	AFONSO VITOR LIMA BEZERRA SOARES	afonsovitor@hotmail.com	7b3f4b565f	Engenharia Ambiental
200927040010	AGLAE SILVEIRA PIO	aglaepio@hotmail.com	6e8ceb6806	Engenharia Ambiental
201117040330	ALANA KAREN DAMASCENO QUEROGA	alanakaren15@hotmail.com	648dab8ceb	Engenharia Ambiental
200927040029	ALANE NASCIMENTO LIMA	enala_17@yahoo.com.br	4a33937b91	Engenharia Ambiental
20112045040035	ALEXSANDRA ANSELMO LOPES	soalexsandra@gmail.com	e441f006dc	Engenharia Ambiental
200917040131	ALINE MARIA BALDEZ CUSTÓDIO	alinebaldez_web@hotmail.com	c46afd39c8	Engenharia Ambiental
200917040247	ALINE MARIA CRUZ MENDES	alinecruzmendes@gmail.com	73d1d0deee	Engenharia Ambiental
200827040230	ALINE MATOS COSTA LIMA	\N	e63ac2fe82	Engenharia Ambiental
201027040217	ALISSON LIMA DE CARVALHO	alissonbene@hotmail.com	45cbec5e29	Engenharia Ambiental
201027040292	ALLISON GURGEL MACAMBIRA	allison.gurgel@gmail.com	0d8b55acf5	Engenharia Ambiental
200917040298	AMANDA FERREIRA DIAS 	amanda_eamb@hotmail.com	405f780f78	Engenharia Ambiental
200927040037	ANA CAMILA PEREIRA DE OLIVEIRA	anacamila_mks@hotmail.com	025029e46b	Engenharia Ambiental
201117040372	ANA CAROLINA RAMOS BANDEIRA	carolina_rband@yahoo.com.br	5de2f1fd5a	Engenharia Ambiental
200817040180	ANA CLÁUDIA CARNEIRO DA SILVA BRAID	cacauaccs@gmail.com	b3a2db3a15	Engenharia Ambiental
200927040045	ANA DEBORAH NUNES FRANÇA	deborahnunesf@yahoo.com.br	b3fd91d245	Engenharia Ambiental
20112045040027	ANA GLÁUCIA FREIRE ALVES	glaucinha_jgt@hotmail.com	016b7e8cf1	Engenharia Ambiental
201117040380	ANA JULIA LIMA OLIVEIRA	ana.julia.14@hotmail.com	aa04694109	Engenharia Ambiental
201027040527	ANA KARINE RODRIGUES DA COSTA	anakarinealencar@yahoo.com.br	286d94ee62	Engenharia Ambiental
201017040311	ANA KAROLINE CARVALHO DE SOUZA	karoline_carvalho18@hotmail.com	548e885e3b	Engenharia Ambiental
200817040083	ANA KAROLLINE NOBRE SILVA	ana_karolline@hotmail.com	18cc72afff	Engenharia Ambiental
201017040052	ANA PATRICIA ALVES BARBOSA	ana_patti@yahoo.com.br	7704ac27b4	Engenharia Ambiental
201117040119	ANDRE FONTENELLE PONTES	andrefp04@hotmail.com	6e2532c358	Engenharia Ambiental
20112045040043	ANDRE FREITAS DA SILVA	andre182freitas@gmail.com	de5f46fc68	Engenharia Ambiental
201117040399	ANDRÉ LUIZ DANTAS RIBEIRO	andre_ldr@hotmail.com	369af008ba	Engenharia Ambiental
200827040310	ANDREIA GONCALVES BATISTA	deiagbatista@hotmail.com	da25e45d51	Engenharia Ambiental
201017040141	ANDREIA LOPES DO MONTE	andrreialopez50@gmail.com	01aa650548	Engenharia Ambiental
201017040117	ANTONIA TATIANA PINHEIRO DO NASCIMENTO	tati16pinheiro@hotmail.com	77458af73b	Engenharia Ambiental
20112045040400	ANTONIO AGLAIUSON HOLANDA SOARES	aglaiusonhs@gmail.com	0461c5acec	Engenharia Ambiental
20112045040051	ANTONIO RUBENS BENEVIDES FILHO	rubensbf@hotmail.com	96c177baad	Engenharia Ambiental
201027040322	ARTHUR LOBO VILELA SALES	arthur_lvs@hotmail.com	fa8f76eb6f	Engenharia Ambiental
201017040010	ARTUR NOÉDIO TORRES FLORAMBEL	arturnoedio@yahoo.com.br	16a1c51709	Engenharia Ambiental
201027040365	ATHALYTA PEIXOTO DIOGENES	athalyta@hotmail.com	7ffe88d4ce	Engenharia Ambiental
201017040257	BARBARA KELLY RIBEIRO MACIEL BARROS	barbarakelly100@yahoo.com.br	64a3db1859	Engenharia Ambiental
201117040259	BIANCA BEZERRA DO REAL	bibihreal@hotmail.com	acf9d4dfc7	Engenharia Ambiental
200917040212	BRUNA PINTO MOURA	brunapintomoura@hotmail.com	79162c6324	Engenharia Ambiental
200827040094	BRUNA SALES DE AGUIAR	bruh_sales@hotmail,com	56d3a3d3d4	Engenharia Ambiental
201027040330	BRUNO CRISTOVÃO VASCONCELOS MORAIS	brunovasconcelosmorais@gmail.com	d9198501ef	Engenharia Ambiental
200827040078	BRUNO MAGALHÃES ALEXANDRE	brunomal_ex@hotmail.com	e2ca855f05	Engenharia Ambiental
200827040221	BRUNO SILVA PEREIRA	brunobarak@gmail.com	3551797a83	Engenharia Ambiental
201027040233	BYBYANNE ADIENEV MATIAS LOPES LEMOS	bianelemos@hotmail.com	90cdfbeb0b	Engenharia Ambiental
20112045040060	CALLEBE FERREIRA SOUTO	callebe_fs91@yahoo.com.br	33b611522f	Engenharia Ambiental
200927040061	CAMILA CRISTINA SOUZA LIRA	camilamixu@hotmail.com	82386ff4bf	Engenharia Ambiental
201027040284	CAMILA MORAES SIEBRA	camila.siebra@hotmail.com	dd3158906c	Engenharia Ambiental
201027040500	CAMILA RAQUEL FONTINELE TEIXEIRA	\N	ee20b594d4	Engenharia Ambiental
201017040184	CAMYLLA RACHELLE AGUIAR ARAÚJO	camyllarachelle@hotmail.com	670b94891c	Engenharia Ambiental
20112045040078	CARLA ISONEIDE ARAUJO DA SILVA	carla_silva1601@yahoo.com.br	84ffd9c7e5	Engenharia Ambiental
201117040038	CARLA JAMILE SOBREIRA DE OLIVEIRA	carlajamile19@yahoo.com.br	246da70185	Engenharia Ambiental
200827040086	CARLOS HENRIQUE BASTOS SILVA	henrique_k9@hotmail.com	eb9b1d678c	Engenharia Ambiental
201117040127	CARLOS HUGO CARVALHO SILVA	chugo_cs1@hotmail.com	d4fcd22000	Engenharia Ambiental
20112045040086	CAROLINA BARBOSA PENTEADO	anjinha.sinha@gmail.com	b6820a90ad	Engenharia Ambiental
201117040364	CAROLINA DE SOUSA DUARTE	carolina_dsd@hotmail.com	a26fc0d932	Engenharia Ambiental
201117040135	CHARLES TAVARES DE ALENCAR	charles.alenncar@hotmail.com	3fcfb48502	Engenharia Ambiental
200727040033	CIRO ADAMS OLIVEIRA DE LIMA	adams.ciro@gmail.com	ae4afd9cb0	Engenharia Ambiental
200817040202	CLEMERSON DE CASTRO MOURA	clemesonmoura@hotmail.com	e3fa9309e4	Engenharia Ambiental
200927040088	CRISTIANO CUNHA LIMA	jkvideo@terra.com.br	54842c8dfd	Engenharia Ambiental
201117040143	CRISTIANO DE JESUS CASTRO DE AGUIAR	cristiano_1012@hotmail.com	f99f71663e	Engenharia Ambiental
201027040020	DANIEL HORTÊNCIO BATISTA	\N	968e3275c5	Engenharia Ambiental
200912300038	PEDRO HENRIQUE DA COSTA DE PAULO	\N	558e99d443	Técnico em Automação Industrial
200817040148	DAVID HARISSON SANTOS BEZERRA	david.harisson@hotmail.com	09f106df39	Engenharia Ambiental
20112045040094	DAYANA KELLY FELIPE SILVA	dayakellyf@gmail.com	b149d67a96	Engenharia Ambiental
201117040151	DÉBORAH PAMELA FREIRE DE SOUSA	deborahpamelaf@yahoo.com.br	102260476b	Engenharia Ambiental
201117040070	DIAGLEDSON PINHEIRO LIMA	diagledson@hotmail.com	4927b46456	Engenharia Ambiental
20112045040426	DIANA GREICY NASCIMENTO LIMA	dianagnlima@hotmail.com	e12c15fab8	Engenharia Ambiental
201017040354	DIEGO ANDRADE ALMEIDA	diego_aalmeida@hotmail.com	c7e678fabb	Engenharia Ambiental
200827040183	DIEGO CARLOS CAMPELO 	diego.campelo@hotmail.com.br	4ea9b5b64d	Engenharia Ambiental
201117040267	DOUGLAS MOURA UCHOA	douglasmoura12@hotmail.com	6674109dd8	Engenharia Ambiental
200827040418	EDGAR MADEIRO JUNIOR	edgarmadeiro@yahoo.com.br	a472df1524	Engenharia Ambiental
201027040268	EDIVANIA MENEZES DE SA	edivaniamenezes40@hotmail.com	ef03ae51fc	Engenharia Ambiental
201027040306	EDSON SILVA DE ARAUJO	edson870@gmail.com	d3266e8954	Engenharia Ambiental
200827040213	ELIE REGINA FEDEL MARQUES	\N	17bb2d92f2	Engenharia Ambiental
200917040263	ELLEN RUTE CARNEIRO PORTELA	m@m	d1520a7146	Engenharia Ambiental
201027040560	EMILLY MARLEY SARAIVA SILVA	emilly_marley@hotmail.com	65638eef14	Engenharia Ambiental
201017040036	ERICA VIEIRA DE PAULA SOUZA	ericavieira86@yahoo.com.br	b5158d1e6b	Engenharia Ambiental
201017040419	ESPEDITO LUIZ PEREIRA MATOS JUNIOR	espeditozunior@hotmail.com	a4b81f527a	Engenharia Ambiental
201017040435	EVLA VIVIA COSTA DE FREITAS	\N	83acaf0fe3	Engenharia Ambiental
200817040024	FABIENNE DA SILVA SOARES	fabiennesoares@gmail.com	11f664976f	Engenharia Ambiental
20112045040108	FÁTIMA ALICE ARRUDA SILVA	fatimaalice2009@hotmail.com	a12e2882b1	Engenharia Ambiental
200827040329	FELIPE BEZERRA COLOMBO	colombofb@gmail.com	4bd0fa96c0	Engenharia Ambiental
200817040040	FELIPE MENDES PORTACIO	\N	c83016614d	Engenharia Ambiental
20112045040396	FELIPE NICOLAS DE MORAIS GARCIA	felipenicolas@r7.com	6eb858a77b	Engenharia Ambiental
200927040452	FERNANDO HENRIQUE RIBEIRO HOLANDA	\N	ce9e3a67ba	Engenharia Ambiental
201027040403	FRANCISCA DALILA MENEZES DE SOUSA	meneze.dalila@gmail.com	7836fce797	Engenharia Ambiental
201017040346	FRANCISCA NADJA CAMPOS DE MELO	dinha_nady@hotmail.com	b60bc84338	Engenharia Ambiental
201027040047	FRANCISCA RAQUEL FERREIRA BRAGA	kelzinha-29@hotmail.com	f84b16ff36	Engenharia Ambiental
200827040426	FRANCISCA SILVANIA GOMES OLIVEIRA	ninhapinshow@yahoo.com.br	9a0b0d2d43	Engenharia Ambiental
200917040069	FRANCISCO CAMPELO MATOS NETO	vulgonebila@hotmail.com	5066daca15	Engenharia Ambiental
200727040017	FRANCISCO DELFABIO TEIXEIRA DE OLIVEIRA	\N	3354f46876	Engenharia Ambiental
200817040130	FRANCISCO EMANOEL FERREIRA DOS SANTOS	emanoel.f@hotmail.com	538a1c09de	Engenharia Ambiental
200727040289	FRANCISCO FERNANDES DA COSTA NETO	nennencfj@hotmail.com	6e4a358155	Engenharia Ambiental
20112045040361	FRANCISCO GILBERLANIO DE ARAUJO	gilberlanio@coelce.com.br	12ded5c100	Engenharia Ambiental
20112045040116	FRANCISCO HENRIQUE XIMENES DA CRUZ	henrique.xc.he@gmail.com	1205157575	Engenharia Ambiental
201117040410	FRANCISCO ORLANDO HOLANDA COSTA FILHO	orlando120609@hotmail.com	c1f67cbbd5	Engenharia Ambiental
200927040118	FRANCISCO THALES AGUIAR PARENTE	xicao_5@hotmail.com	ee27e8ef6b	Engenharia Ambiental
200727040092	FRANCISCO THIAGO RODRIGUES ALMEIDA	thiagobioo@hotmail.com	6cf4855309	Engenharia Ambiental
20112045040124	GABRIEL ZANELLA HERMES	gab.kev@hotmail.com	8af61add29	Engenharia Ambiental
201027040195	GABRIELA SILVA BEZERRA	gabrielamart61@hotmail.com	bf261ff855	Engenharia Ambiental
201117040429	GABRIELLE AMARAL DE FIGUEIRÊDO	gabyzinhah92@yahoo.com.br	51859df387	Engenharia Ambiental
201117040160	GILLIARD BRASILINO DE MORAIS	gilliardbrasilino@hotmail.com	f3597110ff	Engenharia Ambiental
201017040400	GILMAR CARNEIRO FEITOSA	gilmar_cpm@hotmail.com	1c0b53c49d	Engenharia Ambiental
200727040157	GLAUBER NORBERTO DE FREITAS GOMES	\N	f54a0ae005	Engenharia Ambiental
200727040211	GLEYCIANE NOBRE ROCHA	gleyciane.nobre@yahoo.com.br	0df3f184ba	Engenharia Ambiental
200927040126	GLORIA REGINA DE OLIVEIRA MARTINS	gloria_regina_@hotmail.com	5803d23bf5	Engenharia Ambiental
200927040134	GUILHERME TELES SARAIVA	guilhermet.saraiva@yahoo.com.br	ae4ed3939d	Engenharia Ambiental
200727040041	GUSTAVO GUIMARÃES ÁVILA	gustavo.555@gmail.com	f71c76b95c	Engenharia Ambiental
201017040427	HALINA ALVES DE AMORIM	hallina_taua@hotmail.com	646d001e55	Engenharia Ambiental
200827040035	HARLESON BRUNO OLIVEIRA ARRUDA	harlesonb@bol.com.br	60cd1a51e8	Engenharia Ambiental
201117040356	HEITOR LOIOLA SILVEIRA CAMARA GOMES	heitor19rs@hotmail.com	c89d552db2	Engenharia Ambiental
200917040328	HEITOR RIBEIRO ANTUNES	heitor.r.antunes@gmail.com	35198fc2ac	Engenharia Ambiental
20112045040345	HELÂNIO ALEXANDRE ALVES	aahalexandrehaa@hotmail.com	17669897d1	Engenharia Ambiental
201027040179	HILDANE BEZERRA SALES DE ALMEIDA	hildane@gmail.com	1141c448ac	Engenharia Ambiental
200827040205	IDELLUANE MENEZES CAMURÇA CARDOSO	\N	3ed62d9f70	Engenharia Ambiental
200917040174	ISABELE CAMURÇA UCHOA	bele_uchoa@hotmail.com	7ad9cad75f	Engenharia Ambiental
200927040398	ISMAEL DA SILVA SALES	ismael.sales1@hotmail.com	4047bc06a3	Engenharia Ambiental
200727040246	ISRAEL ALVES MENDES DE ARAUJO	isr_mendes@hotmail.com	7378c173dd	Engenharia Ambiental
200927040142	ÍTALO HERBERT DE VASCONCELOS	itherbet@bol.com.br	30a2decdb7	Engenharia Ambiental
200817040164	ITAMICE MELO MACHADO	itamicemelo@hotmail.com	d087acf7bc	Engenharia Ambiental
201027040314	IURY LEITE DA CRUZ	iuryleitecruz@hotmail.com	0086cb3e87	Engenharia Ambiental
200917040107	JAIR DE OLIVEIRA SANTOS	jair_oliveirasantos@hotmail.com	c4847f2b36	Engenharia Ambiental
201027040160	JANACINTA NOGUEIRA DE SOUZA	jana_zac@hotmail.com	e5d5d483c4	Engenharia Ambiental
201027040055	JANDERSON SOARES SILVA	jhanders2@hotmail.com	a6fbd5d9c4	Engenharia Ambiental
200927040169	JANINE BRANDÃO DE FARIAS MESQUITA	janine.mesquita@yahoo.com.br	235bedae0f	Engenharia Ambiental
200827040043	JEAN FILIPPE GOMES RIBEIRO	jeanfilippe@yahoo.com.br	422471e50b	Engenharia Ambiental
200827040108	JEFANIA SOUSA BRAGA	\N	c0430113f9	Engenharia Ambiental
201117040437	JESSICA ASSUNÇÃO JATAÍ	jessica_jatay@hotmail.com	5caba5a19a	Engenharia Ambiental
200927040177	JÉSSICA BESERRA ALEXANDRE	jessicahellokitty_1@hotmail.com	68c4b6b339	Engenharia Ambiental
201117040283	JESSICA MARIA CAVALCANTE FREIRES	jessicacavalcantejc@gmail.com	e435d71778	Engenharia Ambiental
201017040451	JÉSSICA MARIA DE PAIVA ABREU	jessica_ifce@yahoo.com.br	94b83e8cbb	Engenharia Ambiental
201017040206	JHANES DENIN DOS SANTOS LIMA	jhanes_denin@hotmail.com	dd89aaa313	Engenharia Ambiental
200817040318	JOANYA PEREIRA DE LIMA	\N	12dc4f6732	Engenharia Ambiental
200917040158	JOÃO DAVID GONÇALVES MACIEL DE DEUS	j_davidmaciel@hotmail.com	19f1d62db9	Engenharia Ambiental
200827040191	JOÃO WESLEY BARBOSA LIMA	wesleylima77@yahoo.com.br	8a3a62f263	Engenharia Ambiental
20112045040353	JONATHAN LIMA CORDEIRO BARBOSA	jonathanlima.cb@hotmail.com	4f177d7e09	Engenharia Ambiental
200927040428	JORGE FILIPE PINHEIRO ALVES	\N	3603a85270	Engenharia Ambiental
200927040185	JOSE ADI CARNEIRO BASTOS NETO	adineto@hotmail.com	9b595ecd0b	Engenharia Ambiental
200727040114	JOSÉ ALEXANDRE ARAÚJO LOPES JÚNIOR	\N	8a9d6aa876	Engenharia Ambiental
20112045040132	JOSE BRUNO MARQUES FERNANDES	brunofernandesb@bol.com.br	c37e86ead0	Engenharia Ambiental
201027040241	JOSE DEUSIMAR MENDES FILHO	jdeusimarfilho@hotmail.com	09be3dbcb1	Engenharia Ambiental
200827040302	JOSÉ ELIAS TEIXEIRA RODRIGUES	\N	eef011e265	Engenharia Ambiental
201117040178	JOSÉ IGO GOMES DA SILVA	igosilva@bol.com.br	514561edee	Engenharia Ambiental
201117040488	JOSE JEFFERSON DO CARMO AZEVEDO	jeffersonazevedo1@hotmail.com	c18b4132c3	Engenharia Ambiental
200917040417	JOSÉ RIBAMAR LINHARES LAGES FILHO	\N	e3089cee03	Engenharia Ambiental
200817040172	JOSE WELLINGTON JUCA DE QUEIROZ FERNANDES	wellingtonqueiroz225@gmail.com	83f81d383c	Engenharia Ambiental
200727040203	JOSENEIDE OLIVEIRA CAITANO	joseneide_oliveira@hotmail.com	acb73e05c4	Engenharia Ambiental
201027040349	JOSUÉ MARTINS FERREIRA FILHO	josuefilho2010@bol.com.br	9715590460	Engenharia Ambiental
201017040125	SHYSLANE NUNES DE SOUSA	shys_sousa@hotmail.com	6aa3bc66e9	Engenharia Ambiental
200817040075	SILVIO CESAR SOARES DE OLIVEIRA	\N	f7c17131b3	Engenharia Ambiental
200727040238	STÊNYA DANIELE BRITO DE SOUSA	stenya_bsousa@yahoo.com.br	5f2b37473e	Engenharia Ambiental
200727040084	STÉPHANIE AMANDA BERNARDO GURGEL	\N	50b592b2c8	Engenharia Ambiental
201017040095	STEPHANIE NELY DUARTE DE SOUZA CUNHA	stephanienely@hotmail.com	76376a8983	Engenharia Ambiental
201117040062	SUELEN FERREIRA DE ARAUJO	su.cofort@gmail.com	818e225b99	Engenharia Ambiental
200817040067	SUYANE FERREIRA LOPES	\N	4c96ce6057	Engenharia Ambiental
200917040344	TAINÁ SOUSA DA PENHA	tainakindly@hotmail.com	f5919c944e	Engenharia Ambiental
201027040454	TALYTA ANGELO CRUZ	talesancruz@bol.com.br	d307d73cc8	Engenharia Ambiental
200917040050	TATIANE MESQUITA FREIRE	tatimf21@hotmail.com	850bd2d8ff	Engenharia Ambiental
201117040232	TAYANE BEZERRA DE SOUZA	tay_bezerra@hotmail.com	add3b58fa1	Engenharia Ambiental
201017040397	THAINA RAYANNE SOARES	thainasoares90@gmail.com	022d860281	Engenharia Ambiental
200917040042	THAIS COSTA NASCIMENTO	taihs_costa@hotmail.com	4ffcdee2a2	Engenharia Ambiental
20112045040302	THAIS RODRIGUES ALMEIDA	bananinha_morena@hotmail.com	3017fbe15d	Engenharia Ambiental
201027040276	THAISSA COSTA MARQUES	thaissa_188@hotmail.com	4505521d0f	Engenharia Ambiental
201027040080	THALES BRUNO RODRIGUES LIMA	thales_bruno92@hotmail.com	ba1f14ceed	Engenharia Ambiental
201017040192	THALES EMANUEL FONTENELE ARAUJO	thales.emanuel@hotmail.com	c944a48bff	Engenharia Ambiental
200727040270	THIAGO DE FREITAS DOS SANTOS	\N	a7cefb4e33	Engenharia Ambiental
200817040288	THIAGO ROMÁRIO SOARES PAULINO	\N	67147f67c2	Engenharia Ambiental
200827040159	THOMAS LÍVIO SANTOS COELHO	\N	318491d1ca	Engenharia Ambiental
201017040109	TIAGO CIRINEU GOMES RAFAEL	thiiagogomes@hotmail.com	c9839c8cf3	Engenharia Ambiental
201027040381	VALDILENE DE MELO ALVES	valdilene.melo@gmail.com	1cf421010e	Engenharia Ambiental
200827040345	VALTER MARQUES DE MIRANDA JUNIOR	valtinho_marques@hotmail.com	8a713b4994	Engenharia Ambiental
200927040339	VANESSA SOUZA DA SILVEIRA	nessinha_g3_7@hotmail.com	11c92fdc51	Engenharia Ambiental
201117040089	VICTOR FORTE FEIJÓ DE OLIVEIRA COSTA	surfbrasileiro@hotmail.com	005d60fb53	Engenharia Ambiental
200927040347	VICTOR HUGO SIMOES DA SILVA	victorhugosimoes@yahoo.com.br	fb3680c34e	Engenharia Ambiental
200917040280	VINICIUS CESAR DE ALMEIDA ALVES	raiauzemi@hotmail.com	57b9300bfa	Engenharia Ambiental
201117040240	VITOR HUGO DE GOES SAMPAIO	vitor_hugo002@yahoo.com.br	3a99634d3d	Engenharia Ambiental
201117040097	VIVIANE SOARES DE FRANÇA	vivisf10yahoo.com.br	12b5d0d409	Engenharia Ambiental
201027040098	WALTER JHAMESON XAVIER PEREIRA	walter_jhamesoon12@hotmail.com	5d64ecace0	Engenharia Ambiental
20112045040310	WESLEY ELDERSON DIÓGENES NOGUEIRA	wesley.diogenes@yahoo.com.br	546be6b173	Engenharia Ambiental
200927040363	WILLENA ALESSANDRA DE OLIVEIRA	willenaalessandra@hotmail.com	8d282913e8	Engenharia Ambiental
200917040310	WLADNEY ALCÂNTARA DE OLIVEIRA	wladney.alcantara@gmail.com	a1f12db543	Engenharia Ambiental
201117040470	YOULIA MILENA LOPES LIMA	lia_milena@hotmail.com	9c043da20e	Engenharia Ambiental
201027040535	YURI VASCONCELOS E CUNHA	yuricunha1776@hotmail.com	f21e4ef7d1	Engenharia Ambiental
201027040373	JUANA ANGELICA FELIPE FERNANDES	jaff294@hotmail.com	375786f2cd	Engenharia Ambiental
200917040220	JUCELIANE GONÇALVES FIGUEIREDO	juceliane@ig.com.br	cf3305b9d5	Engenharia Ambiental
200927040193	JULI LAGE DE SOUZA SILVA	juli-lss@hotmail.com	4429c05920	Engenharia Ambiental
201117040186	JULIANA MARQUES ALVES	jully_malves@hotmail.com	6b8315a500	Engenharia Ambiental
201017040222	JULLIANA SOARES BASTOS	jullianabastos@hotmail.com	d5718d7155	Engenharia Ambiental
201017040060	KALLINE NÓBREGA DAMASCENO	knine_22@hotmail.com	d9719499ec	Engenharia Ambiental
200917040190	KARLA THAYNÃ MARTINS DE SOUZA	t_yna@hotmail.com	6c41d507d6	Engenharia Ambiental
20112045040140	KAROLINE CORDEIRO PINHEIRO	karolzinha_cordeiro@hotmail.com	7abd796c09	Engenharia Ambiental
201027040152	KATIA WALESKA DE ANDRADE NUNES	katiawalesk@hotmail.com	c8fe6e511e	Engenharia Ambiental
20112045040159	KLYCIA TELES SIEBRA	klyciasiebra_1@hotmail.com	b2db5954b6	Engenharia Ambiental
201017040150	LAILA CRISTINA LIMA SOARES	laila.ifce@gmail.com	6af70876ec	Engenharia Ambiental
20112045040167	LAIS EVELYN BERNARDINO ALVES	lais-evelyn@hotmail.com	758660ec9a	Engenharia Ambiental
201027040071	LARISSA DE ARAÚJO CHAVES	larissachaves123@hotmail.com	c65c9a86cb	Engenharia Ambiental
20112044060016	ADRIANA MARA DE ALMEIDA DE SOUZA	adrianayhrar@gmail.com	c1a5334cfd	Licenciatura em Química
201117040046	LARISSA MARIA PINTO MESQUITA	larissapmesquita@yahoo.com.br	7443579dec	Engenharia Ambiental
201017040079	LARYSSA PINHEIRO VASCONCELOS	lerytz@gmail.com	e073bb4447	Engenharia Ambiental
200927040215	LAYANE PAULA PEREIRA ESTEVES	layaneesteves@hotmail.com	3d9c5f5e91	Engenharia Ambiental
200827040264	LÉA MORAES NUNES TEIXEIRA	leamoraes@hotmail.com	48fc005a87	Engenharia Ambiental
200927040223	LÉA PONTES QUEIROZ	leapontesq@gmail.com	c3bfdbe5d0	Engenharia Ambiental
201017040290	LEANDRO DANUBIO DA SILVA	leandrodanubio@hotmail.com	c190594f58	Engenharia Ambiental
201117040305	LEONARDO LIMA BANDEIRA	leonardolband@hotmail.com	c0a98f0cb2	Engenharia Ambiental
201017040265	LIAMARTA AGUIAR COSTA	liamartaaguiar@gmail.com	467326fbcc	Engenharia Ambiental
201017040249	LIGIA DE NAZARE AGUIAR SILVA	ligiaaguiarsilva@gmail.com	1e1b5d9296	Engenharia Ambiental
200917040468	LIGIANE RODRIGUES DE MESQUITA	ligianerodrigues@gmail.com	16903b68ae	Engenharia Ambiental
201027040543	LILIA SOUZA SAMPAIO	a_noiva_cadaver@hotmail.com	325d694a7e	Engenharia Ambiental
200927040231	LIVIA XAVIER FRANCO	livia_xfranco@hotmail.com	201d0ce49e	Engenharia Ambiental
201117040194	LUCAS ALVES GIRAO	lucasgirao_@hotmail.com	c3f0cb58c7	Engenharia Ambiental
201117040313	LUCAS QUEIROZ BARBOSA	luksqb@hotmail.com	4659c1b148	Engenharia Ambiental
200827040167	LUCIANA KAMILA RODRIGUES FERREIRA	\N	9933ea7f8d	Engenharia Ambiental
201117040445	LUCIMARA RODRIGUES VASCONCELOS	luciiimara@hotmail.com	7a82632aa6	Engenharia Ambiental
200817040032	LUDMILLA SILVA FREITAS	jcam@fortalnet.com.br	ebddf12e1b	Engenharia Ambiental
201027040489	LUZIANE MARQUES DE SOUZA	luziane.marques@yahoo.com.br	5aa095ed64	Engenharia Ambiental
201027040551	MAIRA CAROLINE CARLOTO LOPES	mairacarloto@ymail.com	747b03541a	Engenharia Ambiental
201027040225	MAIRA KELLY VIANA DO NASCIMENTO	mairakelly15@hotmail.com	ccc7d19e23	Engenharia Ambiental
200817040156	MANUELA GOMES VASCONCELOS DELFINO	\N	8ea3a029a5	Engenharia Ambiental
200927040240	MARCEL CARVALHO DA ROCHA	marcel-mc@hotmail.com	cb2ac34190	Engenharia Ambiental
201027040519	MARIA CIBELY LIMA MOURA	cibely_lima@yahoo.com.br	8be18e997d	Engenharia Ambiental
200917040360	MARIA EMILIA CAVALCANTE COSTA	mariaemilia_cc@hotmail.com	29affc0765	Engenharia Ambiental
201027040250	MARIA EUGENIA AMORA DE ARAUJO	sheradaze_amora@hotmail.com	8812f65a15	Engenharia Ambiental
20112045040183	MARIA GABRIELA OLIVEIRA LEITE	gabriela-bc@bol.com.br	c7ebdacfb5	Engenharia Ambiental
200727040076	MARIA JOSÉ GONÇALVES DE OLIVEIRA CONRADO	\N	5c35f843d1	Engenharia Ambiental
200917040441	MARIA NATALIA CASTRO DE SOUSA	natalia22castro@hotmail.com	6d53d797b4	Engenharia Ambiental
201017040028	MARIA REGIANE ARAUJO CAVALCANTE	regi_cavalcante@yahoo.com.br	3080c031ea	Engenharia Ambiental
20112045040191	MARIANA PRACIANO TEIXEIRA	mari_praciano@hotmail.com	463f903293	Engenharia Ambiental
20112045040205	MARINA MACIEL MARQUES	marina.seliga@gmail.com	50be8e9b91	Engenharia Ambiental
201027040144	MAYRA DE FREITAS GONCALVES SILVA	may.fgs@hotmail.com	6c31dbe15e	Engenharia Ambiental
201017040168	MÁYRA SANTIAGO DE FREITAS LOPES	mayralopes1@gmail.com	3e7e037827	Engenharia Ambiental
20112045040213	MELISSA GURGEL DE ABREU MACHADO	melgurgel@gmail.com	a80ec2c33b	Engenharia Ambiental
201017040230	MICHELLE KILVIA BEZERRA ALVES	michellekilvia@gmail.com	e00df19d6c	Engenharia Ambiental
200827040116	MILENE GOMES DA SILVA	\N	b5bd186410	Engenharia Ambiental
200917040255	MIRELLA SOBRAL MACIEL	mirellamaciel25@hotmail.com	a80c9de63b	Engenharia Ambiental
201027040446	MONALISA MENDES NASCIMENTO	monalisamn@hotmail.com	1a149e37bb	Engenharia Ambiental
200727040149	MONEIDE RIBEIRO RODRIGUES	moneiderodrigues@yahoo.com.br	e2532a3412	Engenharia Ambiental
20112045040388	MYRNA DE FREITAS MARCELINO	myrna_dfreitas@hotmail.com	ecf6fa490a	Engenharia Ambiental
200917040085	NANDIARA ARAUJO SANTANA	\N	8a00441440	Engenharia Ambiental
200917040204	NATALIA GOUVEIA GORDIANO	natuzinhagouveia@hotmail.com	1cb6df3b74	Engenharia Ambiental
201117040453	NATALIA HOLANDA MAIA CAVALCANTI	natyhmc@hotmail.com	73cfc7c623	Engenharia Ambiental
200927040444	NATANAEL PINHEIRO BARROSO	natanael_barroso@hotmail.com	8cf2d98eba	Engenharia Ambiental
20112045040221	NAYANA MARIA DE SOUSA DO AMARAL	nayanaamaral@hotmail.com	4cb5d1fed0	Engenharia Ambiental
200727040165	NAYARA GUEDES HOLANDA	\N	79f57e3647	Engenharia Ambiental
20112045040230	NUNO DANIEL VERAS FIRMIANO	nunodaniel.vf@gmail.com	ef94273446	Engenharia Ambiental
200827040140	PATRICIA MENDES BARROSO	\N	59a500c11c	Engenharia Ambiental
20112045040418	PAULO CESAR RODRIGUES CAMARINHO	\N	c2c1135291	Engenharia Ambiental
201017040362	PAULO RAFAEL PEREIRA RODRIGUES	paulorafael04@hotmail.com	4c4f25de8d	Engenharia Ambiental
201117040208	PAULO ROBERTO DE SOUZA PEREIRA FILHO	pauloroberto_v2@hotmail.com	0c6c908004	Engenharia Ambiental
200827040370	PAULO ROBERTO OLIVEIRA DA SILVA	\N	33137e6ac4	Engenharia Ambiental
200727040319	PEDRO ANDRE ALEXANDRINO DELMONDES	\N	cc87877214	Engenharia Ambiental
200927040274	PEDRO HENRIQUE FERREIRA GOMES	pfjat@hotmail.com	581d3a8bed	Engenharia Ambiental
201017040176	PEDRO HENRIQUE MENDES ALBUQUERQUE	ph12_mendes@hotmail.com	d363719368	Engenharia Ambiental
200917040123	PRISCILA KELLY SOBREIRA BRITO	priscilakellystar@yahoo.com.br	4220583ef4	Engenharia Ambiental
201027040128	PRISCILA OLIVEIRA DO VALE ARAUJO	pri_valearaujo@hotmail.com	7617d7c662	Engenharia Ambiental
200927040282	PRISCILA RODRIGUES DA COSTA	pri.la2@hotmail.com	7e58b135ea	Engenharia Ambiental
20112045040248	RACHEL FÁTIMA CAMPOS JUSTINO	racheljustino1@hotmail.com	d2a472754a	Engenharia Ambiental
201017040303	RAFAEL DA SILVA CASTRO	castrorafs@gmail.com	aeed21c0bd	Engenharia Ambiental
201017040281	RAFAELA DE SOUSA LIBERATO	rafaela.liberato@hotmail.com	72b53e303f	Engenharia Ambiental
200827040388	RAISSA ALINE CARNEIRO SANTIAGO	raissa_a_santiago@hotmail.com	cfda567eb8	Engenharia Ambiental
201117040321	RAISSA MARIA CORDEIRO GONDIM DE AMORIM	rara_gondim@hotmail.com	a291a52157	Engenharia Ambiental
201027040110	RAPHAEL ALVES CARDEAL	raphael_tuf@hotmail.com	347d6e339b	Engenharia Ambiental
200817040016	RAQUEL MARINHO CUNHA MARTINS	raquel.cefetce@yahoo.com.br	9f6e9ead69	Engenharia Ambiental
200917040271	RAUL MÁRIO OLIVEIRA GIFONI	rgifoni@hotmail.com	ef998b529f	Engenharia Ambiental
20112045040256	RAUL RIBEIRO MENESES	rauladm@live.com	35bcb371e5	Engenharia Ambiental
20112044060032	AMINADAB NASCIMENTO CRUZ	aminedani@hotmail.com	e5c5a44135	Licenciatura em Química
200817040245	REGIANE DA SILVA LUZ	regianesluz@hotmail.com	9318f2e0b7	Engenharia Ambiental
20112044060040	ANA CAROLINA SOARES DE SOUSA	carolinassousa@yahoo.com.br	59d50cdc98	Licenciatura em Química
20112044060067	ANGELO LOPES DE MELLO	angelmello_82@yahoo.com.br	3b57338929	Licenciatura em Química
20112044060059	ANNA PAULA TEIXEIRA CIRINO	gregory-cb@hotmail.com	696de191bb	Licenciatura em Química
20112044060075	ANTONIO REGINALDO TEIXEIRA SILVA	reginaldo_teixeira@hotmail.com	d939115996	Licenciatura em Química
1642017	ODARA SENA DOS SANTOS	odara@ifce.edu.br	053c5c53bc	Servidores
20112044060083	ANTONIO ROBERTO DE FREITAS JUNIOR	robertoo-junior@hotmail.com	b2f3a54fe2	Licenciatura em Química
20112044060091	BIANCA FERREIRA MENEZES MONTE	biazinha.fmm@hotmail.com	1e08f97e35	Licenciatura em Química
20112044060105	CAROLINE CAETANO DA SILVA MACEDO	camacedoo@gmail.com	9dbe8fd952	Licenciatura em Química
20112044060431	CAROLINE MARILIA SOUSA SILVA	\N	8eea1fcc6b	Licenciatura em Química
20112044060113	CHRISTINA MOREIRA SOARES	chriss.ms@bol.com.br	0bc5637cf7	Licenciatura em Química
20112044060369	DANILO MAGALHÃES FEITOSA	jarfeitosa@gmail.com	bb04047bea	Licenciatura em Química
20112044060377	DAYANE RODRIGUES ALEXANDRE	dayaneralexandre@gmail.com	cdec0315d4	Licenciatura em Química
20112044060121	ELIOENAY SOCRATES CAVALCANTE ELOY	ney.747@hotmail.com	cea30e3825	Licenciatura em Química
20112044060130	FERNANDO GARRITO	fgoperador@yahoo.com.br	6ae0301b1e	Licenciatura em Química
20112045040264	RENAN ARAÚJO ALMEIDA	renan_arauju@hotmail.com	ac301e86c3	Engenharia Ambiental
200727040254	RENATA FONTES CAVALCANTE 	rfontesc@gmail.com	880a0c70c4	Engenharia Ambiental
200827040299	RENATA PEREIRA ALVES	\N	a562db0ec1	Engenharia Ambiental
201027040497	RENATO DE ALBUQUERQUE MENDES	\N	abcadf3196	Engenharia Ambiental
200827040337	ROBERTA DE LIMA ROLIM	robertalimarf@gmail.com	e7cbeff3e8	Engenharia Ambiental
201027040420	ROBERTO ALLYSON ABREU SILVA	robertoallyson@yahoo.com.br	ae92c96c5d	Engenharia Ambiental
20112045040329	ROBSON MATHEUS FERREIRA DOS SANTOS	robsondez@hotmail.com	1c2769c7c7	Engenharia Ambiental
200917040093	ROCASSIANA ALVES CARLOS	rocassiana_ce@hotmail.com	8725520752	Engenharia Ambiental
200727040025	RODRIGO MENDES RODRIGUES	\N	bf407d9ffc	Engenharia Ambiental
201017040133	ROSELANE MIRLEY DE LIMA SILVEIRA	roselane.mirley@hotmail.com	46230f4a4a	Engenharia Ambiental
200917040034	ROVAN ROCHA SANDERS	rovansanders@hotmail.com	489bde779e	Engenharia Ambiental
201117040461	SAMARA RÉGIA DE ANDRADE	samararegia_2525@hotmail.com	e84b87fb94	Engenharia Ambiental
20112045040280	SAMIA BESSA DE MORAES	samia_bessa@hotmail.com	5a456c9862	Engenharia Ambiental
200927040312	SAMYA NUNES VIEIRA	samyya_vieira@hotmail.com	bb36f7aad5	Engenharia Ambiental
201017040273	SASHA GABRIELLE DA COSTA SILVA	sashagabrielle@hotmail.com	f9658173b5	Engenharia Ambiental
20112045040370	SAULO ALBERTO DA SILVEIRA FERREIRA GOMES	sauloasfg@hotmail.com	630965fa5c	Engenharia Ambiental
20112045040299	SAYONARA DA SILVA BARROS	sayonara_bsil@hotmail.com	2b8d03543b	Engenharia Ambiental
200827040027	SERGIO THEOPHILO SOARES JUNIOR	sergiotheosjr@hotmail.com	9c778acde5	Engenharia Ambiental
201117040216	SERGIO VITOR DA SILVA VIEIRA	vitor_s.v@hotmail.com	52925208dc	Engenharia Ambiental
200917040409	SHELIDA CAVALCANTE FREIRE	shelidacavalcante@hotmail.com	7444021e00	Engenharia Ambiental
200812300150	DAYANE LIMA MOURA	\N	f1d260a8cb	Técnico em Automação Industrial
201112300015	ADAILTON DOS SANTOS HOLANDA	adailtondsh@hotmail.com	c9a922670d	Técnico em Automação Industrial
201022300016	ADIEL RODRIGUES CASTELO BRANCO	adielcastelobranco@hotmail.com	49eb22ad06	Técnico em Automação Industrial
200912300160	AGENOR DO NASCIMENTO AMORIM	agenor.amorim@hotmail.com	0c2c008d83	Técnico em Automação Industrial
20112042300265	AILTON RIBEIRO DOS SANTOS	ailton_ghost@hotmail.com	70d2d82ebd	Técnico em Automação Industrial
201022300261	ALEXANDRE MOREIRA DE ALCÂNTARA	alexandre.alcantara93@gmail.com	49afe77f03	Técnico em Automação Industrial
200922300022	ALISSON MONTEIRO CARLOS	monteiroalisson@hotmail.com	b755501ba5	Técnico em Automação Industrial
201012300161	AMANDA DE SOUSA RIBEIRO	amanda-tampa@hotmail.com	117c5f15dc	Técnico em Automação Industrial
200912300020	ANA CAROLINE MENDES GADELHA	carol-gadelha@hotmail.com	d4b98247af	Técnico em Automação Industrial
201022300024	ANA KAROLINA MOURA COELHO	pirada_cpm@hotmail.com	6665ff182b	Técnico em Automação Industrial
201112300023	ANDEFERSON QUEIROZ MENDES	andeferson.cm@hotmail.com	a9eb677df8	Técnico em Automação Industrial
20112042300010	ANDRE OLIVEIRA DOS SANTOS	andre_live2@hotmail.com	64333a74a8	Técnico em Automação Industrial
20112042300028	ANDRÉ VICTOR DE SOUZA SIQUEIRA	andre_tricolorvitor@hotmail.com	e9f7d43773	Técnico em Automação Industrial
200912300070	ANTONIA JACINTA FARIAS DA SILVA	jacintalf@hotmail.com	069852b22b	Técnico em Automação Industrial
200912300275	ANTONIO DENNES PAULO DE MORAES	\N	366f683037	Técnico em Automação Industrial
200822300080	ANTONIO DERYCK VERISSIMO DE ANDRADE	derykeverissimo@yahoo.com.br	c0cd183c3f	Técnico em Automação Industrial
201012300242	ANTONIO GETULIO AGOSTINHO DO VALE	getuliovale@gmail.com	c064ed3463	Técnico em Automação Industrial
200822300209	ANTONIO JUNIOR DA COSTA PEREIRA	\N	e929225546	Técnico em Automação Industrial
201112300031	ANTÔNIO YTALO GOMES MOURÃO	ytalo.mourao@yahoo.com.br	2ee9321055	Técnico em Automação Industrial
20112042300273	ARLAN ICARO DUARTE VASCONCELOS	arlan_ceara@hotmail.com	40c360ade4	Técnico em Automação Industrial
201022300032	ARTUR DE PAULA CAVALCANTE NETO	arturdepaulag3@gmail	2c29068c37	Técnico em Automação Industrial
200922300081	ARTUR REURE SILVA DE FREITAS	arturjazzbass@yahoo.com.br	5474b1ca1c	Técnico em Automação Industrial
201112300040	BRUNO BANDEIRA CASTRO	brunobandeira7@hotmail.com	02c698be79	Técnico em Automação Industrial
201112300058	CARLOS AFONSO FONTELES	afonsofonteles_@hotmail.com	b2229d8324	Técnico em Automação Industrial
201022300040	CARLOS EUGENIO CABRAL DO NASCIMENTO	\N	7494f34d0b	Técnico em Automação Industrial
201112300066	CLEICIANA DE SOUSA SANTOS	cleicianadesousa@gmail.com	d14061224a	Técnico em Automação Industrial
201022300067	DANIEL COSTA ALVES	daniel.costa91@yahoo.com.br	0322162bb8	Técnico em Automação Industrial
201112300090	DANIEL JUNIOR DE AGUIAR	toc-junior@hotmail.com	6f1786d4dc	Técnico em Automação Industrial
20112042300036	DAVI TEIXEIRA GOMES	ivad.ivad@gmail.com	75386676f1	Técnico em Automação Industrial
200912300046	DAVID WANDERSON DE ANDRADE NOGUEIRA	davidwa_@hotmail.com	198d64af9d	Técnico em Automação Industrial
20112042300044	DÉBORA BRENDA DA SILVA RODRIGUES	deborah_brenda@hotmail.com	ac65d915e3	Técnico em Automação Industrial
201022300075	DÉBORA PONTES DE OLIVEIRA	deborapontes.seliga@gmail.com	af6874e502	Técnico em Automação Industrial
20112042300052	DIRCEU HOLANDA OLIVEIRA	dirceu1988@hotmail.com	58ada470d1	Técnico em Automação Industrial
20112042300060	EDNARDO FARIAS DE LIMA	ed.nardo.lima@hotmail.com	bf9033c4ac	Técnico em Automação Industrial
200922300103	EDSON SOARES VIEIRA	edsonsoares15@hotmail.com	d9931ba12b	Técnico em Automação Industrial
201112300104	EDVANIA ALICE SOUSA DA COSTA	edv12@hotmail.com	8e8f6191ac	Técnico em Automação Industrial
20112042300079	ELIARDO CANAFÍSTULA ARAÚJO	eliardo85@gmail.com	58a890fb4d	Técnico em Automação Industrial
200822300101	ELISA MESQUITA ALVES	\N	e4081db28d	Técnico em Automação Industrial
201012300102	EMANUELY JENNYFER GOMES DA SILVA	resetthehate@yahoo.com.br	d1cfe21375	Técnico em Automação Industrial
201022300083	ERBESON FERREIRA DE AGUIAR	\N	474d6a0fae	Técnico em Automação Industrial
20112042300095	FABRICIO AZEVEDO FURTADO	furtado_fabricio@yahoo.com	67235eb4f2	Técnico em Automação Industrial
200822300039	FELIPE KELRE FERREIRA DA SILVA	\N	7b3f281449	Técnico em Automação Industrial
201112300112	FELIPE RODRIGUES DA SILVA	feliperodrigues190@gmail.com	db3c92a51b	Técnico em Automação Industrial
201022300091	FERNANDO OLIVEIRA CAITANO JUNIOR	juninhofield@gmail.com	a305bcf18d	Técnico em Automação Industrial
201112300120	FILIPE FREITAS NOBRE	felipef321@gmail.com	13c36cf2fa	Técnico em Automação Industrial
200922300111	FRANCISCO BASTOS DE MESQUITA	mesquitarefri96@hotmail.com	a986f0a79f	Técnico em Automação Industrial
20112042300109	FRANCISCO CARLOS FERREIRA DE SOUZA	carlostyler6@hotmail.com	2f4990783b	Técnico em Automação Industrial
200912300151	FRANCISCO DE ASSIS MENDES PINTO JÚNIOR	fraciscomendes@hotmail.com	a5281bffbf	Técnico em Automação Industrial
201022300105	FRANCISCO DE ASSIS SOUSA ALVES	miztetlan@yahoo.com.br	5b5d75f4dd	Técnico em Automação Industrial
201112300279	FRANCISCO DIEGO LIMA MOREIRA	diegu.moreira@hotmail.com	09dc547593	Técnico em Automação Industrial
20112042300117	FRANCISCO GILMAR FERREIRA DE ARAUJO	\N	9f4fd297f1	Técnico em Automação Industrial
201112300287	FRANCISCO HENRIQUE XIMENES DA CRUZ	henrique.xc.he@gmail.com	90ee58a54d	Técnico em Automação Industrial
201112300295	FRANCISCO PETRUCIO ANDRADE DA SILVA	petruciokeybo@gmail.com	62b6831799	Técnico em Automação Industrial
20112042300125	FRANCISCO RAFAEL DA COSTA NOBRE	fd.nobre@hotmail.com	3caa884430	Técnico em Automação Industrial
201022300113	FRANCISCO RAFAEL SOARES SALES	fael_educador_social@hotmail.com	7c5737f61e	Técnico em Automação Industrial
201022300270	FRANCISCO VENICIO DOS SANTOS SOUSA	veniciosantos.ce@gmail.com	40436ba3d0	Técnico em Automação Industrial
201022300121	GEORGE CLEY RODRIGUES FEIJÃO	g-cley@hotmail.com	7213d21b36	Técnico em Automação Industrial
200812300133	GLAUBER QUEIROZ SAMPAIO	\N	cfda348634	Técnico em Automação Industrial
20112042300133	GLEANDRO GOMES DA SILVA LIMA	gleandrolds@hotmail.com	9149999ca0	Técnico em Automação Industrial
201022300130	GLEISER SOARES SILVA	gleiser_master@hotmail.com	9ca8866501	Técnico em Automação Industrial
200912300305	HÁLEX KRISTCHEN MENEZES PAIVA	\N	8ba309f0f7	Técnico em Automação Industrial
200722300177	HARON CHARLES VENÂNCIO DO NASCIMENTO	\N	7114f699ee	Técnico em Automação Industrial
201022300148	HÉLIO PEIXOTO MACIEL JÚNIOR	helio1919_@hotmail.com	f21a55ac66	Técnico em Automação Industrial
20112042300290	HERIC HERCULANO SOUSA	cadeteherculano@gmail.com	7a97c02fd6	Técnico em Automação Industrial
200812300028	HÉRILO SALDANHA DE OLIVEIRA	herilosaldanha@bol.com.br	4421bea6c7	Técnico em Automação Industrial
201012300188	IDELCASTRO DA SILVA CORDEIRO	idel06@gmail.com	110f0546ce	Técnico em Automação Industrial
201112300309	ÍNGRID DE OLIVEIRA MAGALHÃES	gridkat@msn.com	660dc33c2d	Técnico em Automação Industrial
201112300139	IVAN ALVES DE SOUSA FILHO	ivanfilhodapaju@yahoo.com.br	ae0314f5a4	Técnico em Automação Industrial
200822300276	IVANA IARA VIANA TARGINO	\N	3110991214	Técnico em Automação Industrial
200922300138	JACQUELINE SOARES VIEIRA	jack_soares14@hotmail.com	5eddf2df4e	Técnico em Automação Industrial
201012300110	JANSEN NOGUEIRA CONSTANTINO DE SOUZA	\N	b9b89f192c	Técnico em Automação Industrial
201022300156	JEFFERSON SILVA ALMEIDA	jefferson.seliga@gmail.com	a9c476e113	Técnico em Automação Industrial
201022300164	JHONI DHEYCSON DOS SANTOS LIMA	frankjhony@gmail.com	866e52c7b1	Técnico em Automação Industrial
201012300269	JOAN LIMA DA SILVA	joan_lima@hotmail.com	5978e8420d	Técnico em Automação Industrial
200722300100	JOÃO CARLOS BARBOSA DA SILVA	joao.c.barbosa@hotmail.com	3ea0e77a93	Técnico em Automação Industrial
20112042300141	JOAO MARCLEITON FERREIRA	joao.marcleiton@yahoo.com.br	1d0fe5d152	Técnico em Automação Industrial
20112042300150	JOHN HERMESON DE LIMA RODRIGUES	johnpcn@hotmail.com	247e23ec04	Técnico em Automação Industrial
20112042300168	JOHN LENNON MAGALHÃES SOARES	john.magalhaes@hotmail.com	6457ef2fab	Técnico em Automação Industrial
201012300200	JONAS ARAÚJO DE MEDEIROS	jonas_techno@hotmail.com	dd0afa3d92	Técnico em Automação Industrial
20112042300176	JOSE LEONARDO BARRETO ARAUJO	helano_jesus@hotmail.com	ed6a08bac6	Técnico em Automação Industrial
201012300234	JOSÉ MARTINS MACÊDO NETO	josemartinsmneto@gmail.com	01b4783979	Técnico em Automação Industrial
201012300064	JOSE PEREIRA DE LIMA NETO	\N	ac7d8d6628	Técnico em Automação Industrial
201012300056	JULIANA OLIVEIRA SOUSA	juliana_madeiro@hotmail.com	f3fba4ae77	Técnico em Automação Industrial
201012300145	KAROLINE LIMA VIEIRA	karoline.lima32@gmail.com	5822942390	Técnico em Automação Industrial
20112042300184	KAYRON ROGERS ALVES NUNES	kayron.rogers91@yahoo.com.br	dcc4ed25dc	Técnico em Automação Industrial
201112300147	KÊNIO MONTELES UCHÔA	keniomonteles@hotmail.com	fdf2d68826	Técnico em Automação Industrial
201012300277	LAYANE DE ARAUJO GOMES	\N	70fba22420	Técnico em Automação Industrial
201022300245	LEILIANE ALVES CARNEIRO	\N	31f2bab946	Técnico em Automação Industrial
201112300155	LEOMÁCIO NUNES DOS SANTOS	leomacionunes@hotmail.com	a59a2b8e25	Técnico em Automação Industrial
201022300172	LUCAS RIBEIRO PEREIRA	lucas.ribeiro.pereira@hotmail.com	2fddf51d80	Técnico em Automação Industrial
201112300171	LUCIANO TOMAZ LIMA DE OLIVEIRA	lucianotlo25@hotmail.com	5e1a35181c	Técnico em Automação Industrial
201012300293	LUINEY FELIPE DE SOUSA CASTRO	luineygol@hotmail.com	2032de1f66	Técnico em Automação Industrial
201012300013	MARCELO DE OLIVEIRA JUNIOR	\N	a9b75a25db	Técnico em Automação Industrial
201012300250	MARCELO DOS SANTOS MACIEL	marcelosantos2010@hotmail.com	333dc4f1b1	Técnico em Automação Industrial
201022300199	MARCELO LOPES DE MELLO FILHO	mlopes_mello@yahoo.com	40d059544d	Técnico em Automação Industrial
20112042300303	PEDRO IVO SANTANA SALES	pedro_milos@hotmail.com	55a75823c0	Técnico em Automação Industrial
201012300196	RAFAEL DE SOUSA NUNES	rafinhaliceu@gmail.com	7fc57b810c	Técnico em Automação Industrial
201112300236	RAFAEL DUARTE VIANA	rafaelviana@fisica.ufc.br	f943f890a8	Técnico em Automação Industrial
200912300216	RAFAEL DUTRA BARBOSA	\N	d8b2b9f909	Técnico em Automação Industrial
201112300244	RAFAEL SILVA DO NASCIMENTO	rafael_silvan@bol.com.br	dd2d159659	Técnico em Automação Industrial
200922300235	RAIMUNDO FLAVIO GOMES DE MOURA	raiflavio@vicunha.com.br	4e5a18079a	Técnico em Automação Industrial
20112042300214	ROMEU CASTRO DE OLIVEIRA	rommeu_castro@hotmail.com	4714d3539b	Técnico em Automação Industrial
201012300048	ROSIMARY BRITO SOMBRA	rosy_brito@yahoo.com.br	e84c369f9b	Técnico em Automação Industrial
201022300229	SAMANTA FREITAS DE OLIVEIRA	samanta.freitas@hotmail.com	6b31d4eff8	Técnico em Automação Industrial
200922300251	SAMIA DANTAS DE OLIVEIRA	samiaddo@gmail.com	2c10192065	Técnico em Automação Industrial
200822300250	SILVANO SILVESTRE DA SILVA	silvanosilvestre@hotmail.com	2d13b72685	Técnico em Automação Industrial
20112042300222	THIAGO CHRISTOFERSON COSTA FIRMO	thiago_cavalcante.advocacia@hotmail.com	66298752d8	Técnico em Automação Industrial
201112300252	THINALLY RIBEIRO ABREU	nallyribeiro@hotmail.com	8d88db41f5	Técnico em Automação Industrial
200922300278	TIAGO DO NASCIMENTO RIBEIRO	tiagg0@yahoo.com.br	3d8d3b389e	Técnico em Automação Industrial
201112300260	TIAGO MALHEIROS CARLOS	tiagocarlos05@hotmail.com	bba5a6395e	Técnico em Automação Industrial
20112042300230	VINICIUS LIMA SABOIA RIBEIRO	diff_dombosco@hotmail.com	3ae291a208	Técnico em Automação Industrial
20112042300249	WALBER FLORENCIO DE ALMEIDA	\N	490eda7f36	Técnico em Automação Industrial
201012300170	WALESON HUDSON LIMA DA SILVA	walesonhudson@hotmail.com	c417574137	Técnico em Automação Industrial
201022300253	WANDERSON DANTAS OLIVEIRA SANTANA	\N	dca5517880	Técnico em Automação Industrial
201012300226	WANDERSON MAGALHÃES DA COSTA	wandersonmagalhaesdacosta@yahoo.com.br	d7b1abf1ad	Técnico em Automação Industrial
20112042300257	WENDEL DE SOUSA TERCEIRO	\N	eb93f49be4	Técnico em Automação Industrial
200812300192	YARA LIVIA BARROS NASCIMENTO	\N	b5f86e8855	Técnico em Automação Industrial
201012310493	ADNISE NATALIA MOURA DOS REIS	\N	b3a22c5663	Técnico em Informática
201022310062	ADRIANA MARA DE ALMEIDA DE SOUZA	adrianayhrar@gmail.com	b0e02c8874	Técnico em Informática
201012310396	ADRIANA OLIVEIRA DE LIMA	adrianabsb7@gmail.com	a356899b4b	Técnico em Informática
201022310070	ADRYSSON DE LIMA GARÇA	adrysson_rrr@hotmail.com	bfe44acbf9	Técnico em Informática
20112042310015	ALEXSANDRO DA SILVA FREITAS	www.alexsandroidilio@yahoo.com	1a0dcdf395	Técnico em Informática
201012310124	ANA BÁRBARA CRUZ SILVA	babi_anahi2@hotmail.com	80e5d28822	Técnico em Informática
20112042310023	ANA BEATRIZ FREITAS LEITE	aninha_beatriz_109@hotmail.com	0617ff0dde	Técnico em Informática
200922310028	ANA LARISSA XIMENES BATISTA	ronaldo@cagece.com.br	b46aacae58	Técnico em Informática
201112310053	ANDRE TEIXEIRA DE QUEIROZ	andre.teixera@hotmail.com	b4d5f99a49	Técnico em Informática
201022310097	ANDRESSA MAILANNY SOUZA DA SILVA	silvaandressa64@gmail.com	05e14e43fc	Técnico em Informática
20112042310031	ANTONIA CLEITIANE HOLANDA PINHEIRO	\N	400b6d916e	Técnico em Informática
201112310061	ANTONIO DE LIMA FERREIRA	johnnyrude@hotmail.com	2831d79e1c	Técnico em Informática
201022310100	ANTONIO EVERTON RODRIGUES TORRES	evertonrodrigues3@hotmail.com	ce6e53e3ce	Técnico em Informática
201022310119	ANTONIO JEFERSON PEREIRA BARRETO	russo.xxx@hotmail.com	6e2493f1d1	Técnico em Informática
201012310116	ANTONIO LOPES DE OLIVEIRA JÚNIOR	junior4000po@hotmail.com	f6435126b9	Técnico em Informática
201012310450	ANTONIO MARCIO RIBEIRO DA SILVA	\N	7937d09c19	Técnico em Informática
200822310379	ARILSON MENDONÇA DO NASCIMENTO	\N	a93ec844a0	Técnico em Informática
201112310070	ARLEN ITALO DUARTE DE VASCONCELOS	aim_ceara03@hotmail.com	ee1954a17f	Técnico em Informática
20112042310040	BRUNO BARBOSA AMARAL	bruno_k16@yahoo.com.br	77b449531d	Técnico em Informática
201012310213	CARLOS ANDERSON FERREIRA SALES	saycor_13_gpb@hotmail.com	c7a5e64d49	Técnico em Informática
201112310088	CARLOS HENRIQUE NOGUEIRA DE CARVALHO	carlos-tetra@hotmail.com	a59b67ee82	Técnico em Informática
20112042310058	CARLOS THAYNAN LIMA DE ANDRADE	thaynan.seliga@gmail.com	5a6c70b13b	Técnico em Informática
201022310135	CAROLINE SANDY REGO DE OLIVEIRA	htadobairro@hotmail.com	3ad6e2b611	Técnico em Informática
201012310523	CATARINA GOMES DA SILVA	\N	4ee0fd9181	Técnico em Informática
200922310079	CLEILSON SOUSA MESQUITA	cleilson.crazy@gmail.com	f192b68676	Técnico em Informática
201112310096	CRISTINA ALMEIDA DE BRITO	cristina.seliga@gmail.com	b484dff864	Técnico em Informática
\.


SET search_path = public, pg_catalog;

--
-- TOC entry 2044 (class 0 OID 23525608)
-- Dependencies: 129
-- Data for Name: caravana; Type: TABLE DATA; Schema: public; Owner: comsolid
--

COPY caravana (id_caravana, nome_caravana, apelido_caravana, id_municipio, id_instituicao, criador) FROM stdin;
50	AS Malucas do novo	new maluc	1	2	328
51	IFCE COMSOLiD	IFSolid	101	3	304
53	Técnico em Informática ETM	Tec ETM	101	61	297
54	Parque Jeruzalém	Jeruzalém	182	1	819
\.


--
-- TOC entry 2045 (class 0 OID 23525611)
-- Dependencies: 130
-- Data for Name: caravana_encontro; Type: TABLE DATA; Schema: public; Owner: comsolid
--

COPY caravana_encontro (id_caravana, id_encontro, responsavel, validada) FROM stdin;
50	1	328	f
51	1	304	f
53	1	297	f
54	1	819	f
\.


--
-- TOC entry 2046 (class 0 OID 23525622)
-- Dependencies: 132
-- Data for Name: dificuldade_evento; Type: TABLE DATA; Schema: public; Owner: comsolid
--

COPY dificuldade_evento (id_dificuldade_evento, descricao_dificuldade_evento) FROM stdin;
1	Básico
2	Intermediário
3	Avançado
\.


--
-- TOC entry 2047 (class 0 OID 23525627)
-- Dependencies: 133
-- Data for Name: encontro; Type: TABLE DATA; Schema: public; Owner: comsolid
--

COPY encontro (id_encontro, nome_encontro, apelido_encontro, data_inicio, data_fim, ativo) FROM stdin;
1	4o. Encontro da COMSOLiD	COMSOLiD^4	2011-11-09	2011-11-12	f
2	5� Encontro da COMSOLID	COMSOLiD+5	2012-12-06	2012-12-08	t
\.


--
-- TOC entry 2048 (class 0 OID 23525631)
-- Dependencies: 134
-- Data for Name: encontro_horario; Type: TABLE DATA; Schema: public; Owner: comsolid
--

COPY encontro_horario (id_encontro_horario, descricao, hora_inicial, hora_final) FROM stdin;
1	Hor�rio 01 - Manh�	08:30:00	09:20:00
2	Intervalo - Manh�	09:20:00	10:00:00
3	Hor�rio 02 - Manh�	10:00:00	10:50:00
4	Hor�rio 03 - Manh�	11:00:00	11:50:00
5	Hor�rio 01 - Tarde	13:30:00	14:20:00
6	Hor�rio 02 - Tarde	14:30:00	15:20:00
7	Intervalo - Tarde	15:20:00	16:00:00
8	Hor�rio 03 - Tarde	16:00:00	16:50:00
\.


--
-- TOC entry 2049 (class 0 OID 23525639)
-- Dependencies: 137
-- Data for Name: encontro_participante; Type: TABLE DATA; Schema: public; Owner: comsolid
--

COPY encontro_participante (id_encontro, id_pessoa, id_instituicao, id_municipio, id_caravana, id_tipo_usuario, validado, data_validacao, data_cadastro, confirmado, data_confirmacao) FROM stdin;
1	2685	194	182	\N	3	f	\N	2011-11-30 01:17:45.621344	f	\N
1	807	3	32	\N	3	f	\N	2011-11-14 15:26:01.184381	t	2011-11-25 09:38:18.128542
1	812	3	182	\N	3	f	\N	2011-11-14 18:33:15.950958	f	\N
1	817	3	182	\N	3	f	\N	2011-11-14 22:05:00.779498	f	\N
1	2571	21	101	\N	3	f	\N	2011-11-25 12:08:10.320071	t	2011-11-25 15:28:16.916165
1	829	72	101	\N	3	f	\N	2011-11-15 13:10:47.058556	f	\N
1	836	1	182	\N	3	f	\N	2011-11-15 16:41:31.450242	f	\N
1	841	62	101	\N	3	f	\N	2011-11-15 19:06:25.311182	f	\N
1	846	198	182	\N	3	f	\N	2011-11-15 19:39:45.889856	f	\N
1	851	192	182	\N	3	f	\N	2011-11-16 09:24:36.857228	f	\N
1	857	194	182	\N	3	f	\N	2011-11-16 10:33:03.24012	f	\N
1	887	194	182	\N	3	f	\N	2011-11-16 11:12:21.190553	f	\N
1	907	1	182	\N	3	f	\N	2011-11-16 12:33:34.445784	f	\N
1	2400	1	101	\N	3	f	\N	2011-11-24 14:30:19.519398	t	2011-11-24 14:31:02.205879
1	929	3	101	\N	3	f	\N	2011-11-16 15:15:51.504715	f	\N
1	2199	1	1	\N	3	f	\N	2011-11-23 20:35:18.034381	f	\N
1	942	194	182	\N	3	f	\N	2011-11-16 22:46:26.2307	f	\N
1	957	192	182	\N	3	f	\N	2011-11-17 09:17:33.923175	f	\N
1	972	192	182	\N	3	f	\N	2011-11-17 11:47:59.994481	f	\N
1	977	1	101	\N	3	f	\N	2011-11-17 15:16:30.923372	t	2011-11-24 08:52:51.454986
1	2590	1	182	\N	3	f	\N	2011-11-25 15:33:40.329374	t	2011-11-25 15:33:54.604516
1	987	3	101	\N	3	f	\N	2011-11-17 22:18:40.689231	f	\N
1	2213	3	182	\N	3	f	\N	2011-11-23 21:41:26.452277	f	\N
1	999	21	101	\N	3	f	\N	2011-11-18 12:11:20.517724	f	\N
1	1006	194	182	\N	3	f	\N	2011-11-18 15:16:16.929999	f	\N
1	1011	21	101	\N	3	f	\N	2011-11-18 17:03:03.746009	f	\N
1	1016	1	101	\N	3	f	\N	2011-11-18 18:50:59.181113	f	\N
1	2231	41	101	\N	3	f	\N	2011-11-23 23:43:51.638096	f	\N
1	1028	1	182	\N	3	f	\N	2011-11-18 20:26:38.198265	f	\N
1	2591	1	101	\N	3	f	\N	2011-11-25 15:35:50.740007	t	2011-11-25 15:38:46.798141
1	1040	3	182	\N	3	f	\N	2011-11-19 00:29:44.537665	t	2011-11-24 09:40:34.603817
1	1047	1	182	\N	3	f	\N	2011-11-19 11:55:23.250087	f	\N
1	706	1	54	\N	3	f	\N	2011-11-10 22:07:11.591121	t	2011-11-25 15:35:51.165847
1	710	1	54	\N	3	f	\N	2011-11-10 22:10:24.274188	t	2011-11-25 15:36:08.003768
1	1064	3	125	\N	3	f	\N	2011-11-19 19:36:25.094327	f	\N
1	803	1	182	\N	3	f	\N	2011-11-14 12:53:20.053551	f	\N
1	2537	101	182	\N	3	f	\N	2011-11-24 23:38:52.756272	t	2011-11-25 09:16:19.420802
1	823	41	182	\N	3	f	\N	2011-11-15 09:57:43.104724	f	\N
1	832	72	101	\N	3	f	\N	2011-11-15 13:13:42.973775	f	\N
1	2248	3	101	\N	3	f	\N	2011-11-24 08:56:44.681937	t	2011-11-24 09:12:55.968255
1	842	21	101	\N	3	f	\N	2011-11-15 19:07:52.530345	f	\N
1	847	1	182	\N	3	f	\N	2011-11-15 22:42:09.215391	f	\N
1	852	194	182	\N	3	f	\N	2011-11-16 10:24:08.863948	t	2011-11-26 10:54:59.018283
1	858	194	182	\N	3	f	\N	2011-11-16 10:42:23.848331	t	2011-11-26 10:56:05.914717
1	888	194	182	\N	3	f	\N	2011-11-16 11:13:35.669859	f	\N
1	908	1	101	\N	3	f	\N	2011-11-16 13:36:33.509093	f	\N
1	915	194	182	\N	3	f	\N	2011-11-16 14:44:25.548111	f	\N
1	931	1	164	\N	3	f	\N	2011-11-16 15:45:11.234561	f	\N
1	938	1	101	\N	3	f	\N	2011-11-16 21:03:55.249724	f	\N
1	943	3	182	\N	3	f	\N	2011-11-17 03:00:49.438004	f	\N
1	958	192	182	\N	3	f	\N	2011-11-17 09:18:13.277631	f	\N
1	978	3	182	\N	3	f	\N	2011-11-17 15:18:32.168227	f	\N
1	983	3	101	\N	3	f	\N	2011-11-17 20:40:50.743125	f	\N
1	988	1	101	\N	3	f	\N	2011-11-17 22:37:22.065009	f	\N
1	1000	1	182	\N	3	f	\N	2011-11-18 14:14:48.538447	f	\N
1	1007	21	101	\N	3	f	\N	2011-11-18 15:42:10.729297	t	2011-11-25 15:39:57.840509
1	1012	21	101	\N	3	f	\N	2011-11-18 17:08:46.574817	f	\N
1	1017	77	101	\N	3	f	\N	2011-11-18 18:51:00.031742	f	\N
1	1022	3	101	\N	3	f	\N	2011-11-18 19:19:34.259833	f	\N
1	1029	75	101	\N	3	f	\N	2011-11-18 20:31:01.43677	f	\N
1	1034	21	101	\N	3	f	\N	2011-11-18 21:29:32.462998	f	\N
1	1041	3	101	\N	3	f	\N	2011-11-19 00:43:42.305405	t	2011-11-24 09:50:22.931269
1	1048	1	182	\N	3	f	\N	2011-11-19 12:30:45.47491	f	\N
1	1060	1	182	\N	3	f	\N	2011-11-19 17:33:32.511852	f	\N
1	804	194	182	\N	3	f	\N	2011-11-14 13:30:40.347024	f	\N
1	814	3	101	\N	3	f	\N	2011-11-14 19:44:16.726635	f	\N
1	825	3	101	\N	3	f	\N	2011-11-15 10:03:32.80333	f	\N
1	833	194	56	\N	3	f	\N	2011-11-15 15:04:46.046527	f	\N
1	838	21	101	\N	3	f	\N	2011-11-15 17:58:46.998596	f	\N
1	843	3	101	\N	3	f	\N	2011-11-15 19:21:10.407503	f	\N
1	848	192	182	\N	3	f	\N	2011-11-15 23:27:46.407396	f	\N
1	853	194	182	\N	3	f	\N	2011-11-16 10:28:31.370572	f	\N
1	859	194	182	\N	3	f	\N	2011-11-16 10:43:33.903967	f	\N
1	901	194	182	\N	3	f	\N	2011-11-16 11:37:47.267099	f	\N
1	909	41	182	\N	3	f	\N	2011-11-16 14:02:00.296756	f	\N
1	916	194	182	\N	3	f	\N	2011-11-16 14:44:43.359531	f	\N
1	2258	1	182	\N	3	f	\N	2011-11-24 09:55:00.899576	t	2011-11-24 09:55:23.395589
1	939	1	125	\N	3	f	\N	2011-11-16 21:17:59.535381	f	\N
1	946	194	182	\N	3	f	\N	2011-11-17 09:02:27.848532	f	\N
1	969	194	182	\N	3	f	\N	2011-11-17 09:44:39.674402	f	\N
1	974	1	101	\N	3	f	\N	2011-11-17 12:36:34.336005	f	\N
1	979	1	101	\N	3	f	\N	2011-11-17 15:21:25.350163	t	2011-11-24 08:52:34.797013
1	984	21	101	\N	3	f	\N	2011-11-17 21:00:45.622299	f	\N
1	989	21	101	\N	3	f	\N	2011-11-17 23:26:46.084834	f	\N
1	996	3	182	\N	3	f	\N	2011-11-18 11:52:18.044453	f	\N
1	1001	3	182	\N	3	f	\N	2011-11-18 14:36:56.710654	f	\N
1	1013	194	101	\N	3	f	\N	2011-11-18 17:13:19.714545	f	\N
1	1781	1	182	\N	3	f	\N	2011-11-23 10:14:15.48932	t	2011-11-24 10:03:50.78217
1	1023	3	182	\N	3	f	\N	2011-11-18 19:26:41.224203	t	2011-11-24 09:05:26.274546
1	1030	21	101	\N	3	f	\N	2011-11-18 20:47:42.051939	f	\N
1	1035	72	101	\N	3	f	\N	2011-11-18 21:31:51.541993	f	\N
1	1042	3	101	\N	3	f	\N	2011-11-19 01:08:10.17065	f	\N
1	1049	102	102	\N	3	f	\N	2011-11-19 12:32:20.231922	t	2011-11-26 11:25:30.695136
1	2417	1	182	\N	3	f	\N	2011-11-24 15:34:22.401125	t	2011-11-24 15:36:39.102369
1	1061	21	101	\N	3	f	\N	2011-11-19 17:43:33.746327	f	\N
1	819	194	182	\N	3	f	\N	2011-11-14 22:15:09.927311	f	\N
1	810	131	32	\N	3	f	\N	2011-11-14 16:44:41.494062	f	\N
1	815	21	125	\N	3	f	\N	2011-11-14 20:46:20.237031	f	\N
1	821	194	182	\N	3	f	\N	2011-11-14 22:25:36.802964	f	\N
1	2291	1	182	\N	3	f	\N	2011-11-24 10:16:12.901318	f	\N
1	856	194	182	\N	3	f	\N	2011-11-16 10:31:54.143913	t	2011-11-24 10:16:49.590667
1	1628	102	102	\N	3	f	\N	2011-11-22 20:37:56.194422	t	2011-11-24 10:18:43.794437
1	2251	130	32	\N	3	f	\N	2011-11-24 09:06:42.415222	t	2011-11-25 09:39:46.68361
1	2553	1	182	\N	3	f	\N	2011-11-25 09:46:43.509648	t	2011-11-25 09:46:51.779728
1	761	194	182	\N	3	f	\N	2011-11-11 21:17:26.592269	f	\N
1	827	3	101	\N	3	f	\N	2011-11-15 10:34:40.100093	t	2011-11-28 16:10:34.175125
1	834	3	101	\N	3	f	\N	2011-11-15 16:21:35.521635	f	\N
1	839	21	101	\N	3	f	\N	2011-11-15 18:00:27.128654	f	\N
1	844	3	101	\N	3	f	\N	2011-11-15 19:22:16.796786	t	2011-11-26 12:00:45.004555
1	849	192	182	\N	3	f	\N	2011-11-15 23:33:27.4418	f	\N
1	2401	67	101	\N	3	f	\N	2011-11-24 14:30:29.305074	t	2011-11-24 14:30:38.33058
1	860	194	182	\N	3	f	\N	2011-11-16 10:48:44.030208	f	\N
1	902	1	182	\N	3	f	\N	2011-11-16 12:11:51.531903	f	\N
1	704	1	54	\N	3	f	\N	2011-11-10 22:06:04.346484	t	2011-11-25 15:39:41.043979
1	918	194	182	\N	3	f	\N	2011-11-16 14:48:02.422464	f	\N
1	320	1	54	\N	3	f	\N	2011-10-14 20:54:37.333334	t	2011-11-25 15:39:03.921714
1	2214	1	182	\N	3	f	\N	2011-11-23 22:12:38.890913	t	2011-11-25 09:38:26.516673
1	947	194	182	\N	3	f	\N	2011-11-17 09:05:21.433986	f	\N
1	970	3	101	\N	3	f	\N	2011-11-17 09:54:57.964787	f	\N
1	975	21	101	\N	3	f	\N	2011-11-17 14:07:08.15467	t	2011-11-24 08:53:11.474583
1	2232	65	101	\N	3	f	\N	2011-11-24 00:08:40.352842	f	\N
1	2515	3	101	\N	3	f	\N	2011-11-24 20:38:07.889985	t	2011-11-25 09:24:37.73081
1	985	21	125	\N	3	f	\N	2011-11-17 22:05:02.359279	f	\N
1	990	101	101	\N	3	f	\N	2011-11-17 23:41:43.75936	f	\N
1	997	21	101	\N	3	f	\N	2011-11-18 11:58:34.416165	f	\N
1	1002	3	125	\N	3	f	\N	2011-11-18 14:40:40.063403	t	2011-11-25 14:23:45.340798
1	2592	136	101	\N	3	f	\N	2011-11-25 15:41:49.567665	t	2011-11-25 15:42:23.701499
1	1014	194	182	\N	3	f	\N	2011-11-18 17:21:23.481752	f	\N
1	1019	3	101	\N	3	f	\N	2011-11-18 18:56:35.585628	f	\N
1	2249	3	101	\N	3	f	\N	2011-11-24 08:57:35.81158	t	2011-11-24 09:24:51.245613
1	1031	3	101	\N	3	f	\N	2011-11-18 20:52:52.042486	f	\N
1	1036	71	101	\N	3	f	\N	2011-11-18 22:40:22.438243	f	\N
1	1043	3	101	\N	3	f	\N	2011-11-19 11:09:19.536878	f	\N
1	1050	61	102	\N	3	f	\N	2011-11-19 12:42:51.581745	t	2011-11-26 10:39:37.916319
1	1057	1	182	\N	3	f	\N	2011-11-19 16:01:01.799863	f	\N
1	1062	1	101	\N	3	f	\N	2011-11-19 17:46:06.990404	f	\N
1	2618	41	182	\N	3	f	\N	2011-11-26 01:54:07.579739	t	2011-11-26 11:54:59.836601
1	321	1	54	\N	3	f	\N	2011-10-14 20:55:19.24889	f	\N
1	322	3	182	\N	3	f	\N	2011-10-14 23:52:14.496813	f	\N
1	324	3	125	\N	3	f	\N	2011-10-15 01:19:32.362143	f	\N
1	325	3	182	\N	3	f	\N	2011-10-15 09:43:24.296862	f	\N
1	298	1	182	\N	3	f	\N	2011-10-13 18:24:41.773394	f	\N
1	763	3	182	\N	3	f	\N	2011-11-11 22:20:48.691619	f	\N
1	301	1	182	\N	3	f	\N	2011-10-13 20:39:26.992664	f	\N
1	1051	61	102	\N	3	f	\N	2011-11-19 12:43:38.354197	t	2011-11-26 11:32:53.99535
1	328	3	101	\N	3	f	\N	2011-10-15 10:10:09.949636	f	\N
1	329	3	182	\N	3	f	\N	2011-10-15 12:08:25.218063	f	\N
1	296	1	101	\N	3	f	\N	2011-10-12 23:49:00.468359	t	2011-11-25 14:42:09.583767
1	303	1	101	\N	3	f	\N	2011-10-14 13:19:19.263867	f	\N
1	305	3	101	\N	3	f	\N	2011-10-14 13:46:46.290655	f	\N
1	2418	199	182	\N	3	f	\N	2011-11-24 15:34:53.480097	t	2011-11-24 15:36:27.612758
1	308	3	1	\N	3	f	\N	2011-10-14 14:55:23.206773	f	\N
1	309	2	124	\N	3	f	\N	2011-10-14 15:07:06.470144	f	\N
1	310	1	182	\N	3	f	\N	2011-10-14 15:18:07.70981	f	\N
1	312	3	101	\N	3	f	\N	2011-10-14 16:46:12.390301	f	\N
1	313	3	101	\N	3	f	\N	2011-10-14 17:01:53.939236	f	\N
1	314	1	102	\N	3	f	\N	2011-10-14 17:55:22.630283	f	\N
1	315	3	101	\N	3	f	\N	2011-10-14 18:00:57.379024	f	\N
1	317	1	182	\N	3	f	\N	2011-10-14 19:09:37.71781	f	\N
1	318	1	182	\N	3	f	\N	2011-10-14 19:12:50.609865	f	\N
1	330	1	101	\N	3	f	\N	2011-10-15 13:11:41.832621	t	2011-11-24 09:22:14.914032
1	327	3	101	50	3	f	\N	2011-10-15 10:06:46.366232	f	\N
1	331	1	182	\N	3	f	\N	2011-10-15 17:38:27.701254	t	2011-11-24 14:57:53.114832
1	332	3	101	\N	3	f	\N	2011-10-16 12:06:59.272359	t	2011-11-24 10:07:53.620791
1	635	3	101	\N	3	f	\N	2011-11-08 20:40:15.422504	f	\N
1	334	3	101	\N	3	f	\N	2011-10-16 15:14:55.918327	f	\N
1	337	1	102	\N	3	f	\N	2011-10-17 12:23:26.785996	f	\N
1	338	3	182	\N	3	f	\N	2011-10-17 12:30:44.838198	f	\N
1	339	2	159	\N	3	f	\N	2011-10-17 12:32:38.050206	f	\N
1	340	1	182	\N	3	f	\N	2011-10-17 12:45:02.295345	f	\N
1	2432	1	182	\N	3	f	\N	2011-11-24 15:47:17.286196	t	2011-11-24 15:47:27.113743
1	343	2	182	\N	3	f	\N	2011-10-17 13:17:31.701165	f	\N
1	344	2	182	\N	3	f	\N	2011-10-17 13:20:03.481579	f	\N
1	345	2	182	\N	3	f	\N	2011-10-17 13:45:28.404515	f	\N
1	346	1	182	\N	3	f	\N	2011-10-17 14:12:02.954796	t	2011-11-24 09:57:44.075445
1	347	1	101	\N	3	f	\N	2011-10-17 14:14:27.814937	f	\N
1	348	1	182	\N	3	f	\N	2011-10-17 14:38:24.96798	f	\N
1	349	1	182	\N	3	f	\N	2011-10-17 15:04:25.316944	f	\N
1	350	2	146	\N	3	f	\N	2011-10-17 15:04:31.632401	f	\N
1	351	3	101	\N	3	f	\N	2011-10-17 15:20:13.628682	f	\N
1	352	2	182	\N	3	f	\N	2011-10-17 16:38:28.523557	f	\N
1	353	1	182	\N	3	f	\N	2011-10-17 16:44:48.1503	f	\N
1	354	1	182	\N	3	f	\N	2011-10-17 16:50:03.431749	f	\N
1	355	2	182	\N	3	f	\N	2011-10-17 17:03:50.718762	f	\N
1	356	1	39	\N	3	f	\N	2011-10-17 17:08:18.159799	f	\N
1	357	3	101	\N	3	f	\N	2011-10-17 17:28:30.448817	f	\N
1	359	1	182	\N	3	f	\N	2011-10-17 18:28:06.858718	f	\N
1	360	2	112	\N	3	f	\N	2011-10-17 19:27:38.5761	f	\N
1	362	1	182	\N	3	f	\N	2011-10-17 20:06:44.659635	f	\N
1	363	1	32	\N	3	f	\N	2011-10-17 20:16:39.732074	f	\N
1	364	3	182	\N	3	f	\N	2011-10-17 20:17:54.631479	f	\N
1	365	1	32	\N	3	f	\N	2011-10-17 20:19:02.350302	f	\N
1	2445	1	182	\N	3	f	\N	2011-11-24 15:51:36.299846	t	2011-11-24 15:52:03.044725
1	2459	1	182	\N	3	f	\N	2011-11-24 16:15:20.621644	t	2011-11-24 16:15:42.946459
1	369	1	182	\N	3	f	\N	2011-10-17 20:22:36.939862	f	\N
1	370	3	182	\N	3	f	\N	2011-10-17 21:24:48.948229	f	\N
1	371	3	182	\N	3	f	\N	2011-10-17 22:12:46.746807	f	\N
1	372	3	101	\N	3	f	\N	2011-10-17 22:51:20.30048	f	\N
1	373	3	182	\N	3	f	\N	2011-10-18 09:07:59.138755	f	\N
1	374	3	182	\N	3	f	\N	2011-10-18 09:14:59.968665	t	2011-11-24 14:57:51.512076
1	375	1	182	\N	3	f	\N	2011-10-18 09:54:22.933572	f	\N
1	2259	1	182	\N	3	f	\N	2011-11-24 09:58:43.965425	f	\N
1	2266	1	182	\N	3	f	\N	2011-11-24 10:04:25.09848	t	2011-11-24 10:04:34.87093
1	2538	1	95	\N	3	f	\N	2011-11-25 00:48:28.652322	f	\N
1	2550	1	182	\N	3	f	\N	2011-11-25 09:41:52.98039	t	2011-11-25 09:42:04.300975
1	2512	1	146	\N	3	f	\N	2011-11-24 20:17:51.048785	t	2011-11-25 09:47:14.978153
1	1306	1	182	\N	3	f	\N	2011-11-22 10:22:29.781076	t	2011-11-25 09:54:27.582114
1	376	1	108	\N	3	f	\N	2011-10-18 10:37:54.959527	f	\N
1	377	1	106	\N	3	f	\N	2011-10-18 10:48:47.099664	f	\N
1	378	1	159	\N	3	f	\N	2011-10-18 10:54:07.884433	f	\N
1	379	1	182	\N	3	f	\N	2011-10-18 11:58:41.330463	f	\N
1	380	1	182	\N	3	f	\N	2011-10-18 13:37:03.567588	f	\N
1	381	1	101	\N	3	f	\N	2011-10-18 14:12:27.068064	f	\N
1	382	2	42	\N	3	f	\N	2011-10-18 14:30:03.410136	f	\N
1	383	1	101	\N	3	f	\N	2011-10-18 14:38:24.259655	f	\N
1	384	3	182	\N	3	f	\N	2011-10-18 15:50:37.827304	f	\N
1	385	1	102	\N	3	f	\N	2011-10-18 19:23:19.990244	f	\N
1	387	1	182	\N	3	f	\N	2011-10-19 10:00:09.439739	f	\N
1	388	2	42	\N	3	f	\N	2011-10-19 13:37:27.137405	t	2011-11-25 14:36:03.640749
1	358	2	182	\N	3	f	\N	2011-10-17 18:22:29.517444	f	\N
1	389	2	182	\N	3	f	\N	2011-10-19 14:21:22.438069	f	\N
1	390	1	182	\N	3	f	\N	2011-10-19 15:34:11.420454	f	\N
1	391	3	102	\N	3	f	\N	2011-10-19 17:58:33.566354	f	\N
1	392	3	124	\N	3	f	\N	2011-10-19 23:32:37.322843	f	\N
1	393	1	96	\N	3	f	\N	2011-10-20 00:02:51.479951	f	\N
1	394	1	22	\N	3	f	\N	2011-10-20 08:25:20.649852	f	\N
1	395	1	182	\N	3	f	\N	2011-10-20 09:22:26.934898	f	\N
1	396	1	182	\N	3	f	\N	2011-10-20 09:36:15.356978	f	\N
1	397	2	42	\N	3	f	\N	2011-10-20 11:08:34.528286	t	2011-11-25 14:36:27.508878
1	398	3	182	\N	3	f	\N	2011-10-20 18:18:22.577374	f	\N
1	2402	41	34	\N	3	f	\N	2011-11-24 14:35:54.247503	t	2011-11-25 09:40:51.97121
1	400	1	101	\N	3	f	\N	2011-10-20 18:30:59.450573	f	\N
1	401	3	101	\N	3	f	\N	2011-10-20 18:34:22.612192	f	\N
1	2201	101	101	\N	3	f	\N	2011-11-23 20:43:33.639225	f	\N
1	406	3	32	\N	3	f	\N	2011-10-20 18:48:28.020939	f	\N
1	407	3	101	\N	3	f	\N	2011-10-20 18:50:40.493355	f	\N
1	408	3	182	\N	3	f	\N	2011-10-20 21:00:50.225138	f	\N
1	2619	203	182	\N	3	f	\N	2011-11-26 01:55:41.930267	t	2011-11-26 11:54:35.278245
1	410	3	42	\N	3	f	\N	2011-10-20 21:55:40.711766	f	\N
1	411	1	182	\N	3	f	\N	2011-10-21 21:02:34.130201	f	\N
1	412	3	182	\N	3	f	\N	2011-10-21 21:42:05.929619	f	\N
1	413	1	101	\N	3	f	\N	2011-10-22 12:46:08.163751	f	\N
1	414	3	182	\N	3	f	\N	2011-10-22 15:18:35.179575	f	\N
1	415	1	101	\N	3	f	\N	2011-10-22 15:37:37.476046	f	\N
1	416	1	101	\N	3	f	\N	2011-10-23 19:24:04.158308	f	\N
1	2593	1	182	\N	3	f	\N	2011-11-25 15:50:13.284752	t	2011-11-25 15:50:29.959696
1	418	3	101	\N	3	f	\N	2011-10-23 21:48:10.218424	f	\N
1	419	3	101	\N	3	f	\N	2011-10-23 21:51:06.143256	f	\N
1	420	2	125	\N	3	f	\N	2011-10-23 23:17:53.521513	f	\N
1	421	1	42	\N	3	f	\N	2011-10-23 23:18:45.104515	f	\N
1	422	1	125	\N	3	f	\N	2011-10-24 10:04:51.16304	f	\N
1	423	1	182	\N	3	f	\N	2011-10-24 10:46:28.721555	f	\N
1	424	3	182	\N	3	f	\N	2011-10-24 13:11:46.091424	f	\N
1	2250	96	42	\N	3	f	\N	2011-11-24 09:02:44.772348	t	2011-11-24 09:09:22.643114
1	426	3	182	\N	3	f	\N	2011-10-24 15:07:49.15197	f	\N
1	427	2	101	\N	3	f	\N	2011-10-24 17:01:55.610792	f	\N
1	428	1	182	\N	3	f	\N	2011-10-24 19:34:48.154026	f	\N
1	429	1	182	\N	3	f	\N	2011-10-24 21:11:04.640099	f	\N
1	430	1	182	\N	3	f	\N	2011-10-24 23:13:16.087866	f	\N
1	431	1	182	\N	3	f	\N	2011-10-25 18:22:58.002647	f	\N
1	432	3	101	\N	3	f	\N	2011-10-25 21:42:01.887441	f	\N
1	2594	1	182	\N	3	f	\N	2011-11-25 15:50:59.862215	t	2011-11-25 15:51:56.009452
1	434	1	42	\N	3	f	\N	2011-10-25 23:52:54.598675	f	\N
1	435	1	10	\N	3	f	\N	2011-10-26 10:54:28.868107	f	\N
1	436	1	182	\N	3	f	\N	2011-10-26 13:28:50.762868	f	\N
1	437	1	182	\N	3	f	\N	2011-10-26 17:37:30.231462	f	\N
1	438	3	101	\N	3	f	\N	2011-10-26 19:09:23.225316	f	\N
1	439	3	101	\N	3	f	\N	2011-10-27 13:16:21.527035	f	\N
1	440	1	182	\N	3	f	\N	2011-10-27 13:50:01.418599	f	\N
1	441	1	182	\N	3	f	\N	2011-10-27 19:29:13.048623	f	\N
1	443	3	182	\N	3	f	\N	2011-10-29 01:53:03.321978	f	\N
1	444	3	101	\N	3	f	\N	2011-10-29 11:18:21.214674	t	2011-11-24 09:45:58.992507
1	445	1	101	\N	3	f	\N	2011-10-29 22:26:27.208853	f	\N
1	446	3	124	\N	3	f	\N	2011-10-31 14:45:46.291043	f	\N
1	447	3	182	\N	3	f	\N	2011-10-31 15:21:35.902296	f	\N
1	448	3	101	\N	3	f	\N	2011-10-31 15:21:39.859831	f	\N
1	449	3	182	\N	3	f	\N	2011-10-31 15:22:11.662222	f	\N
1	2516	101	101	\N	3	f	\N	2011-11-24 20:44:47.722147	t	2011-11-25 09:21:54.053175
1	451	3	101	\N	3	f	\N	2011-10-31 16:33:56.273624	f	\N
1	452	3	101	\N	3	f	\N	2011-10-31 17:41:17.004322	f	\N
1	2260	1	182	\N	3	f	\N	2011-11-24 09:58:46.99463	t	2011-11-24 09:59:14.521196
1	639	3	182	\N	3	f	\N	2011-11-08 22:42:15.319594	f	\N
1	456	1	101	\N	3	f	\N	2011-10-31 18:34:51.774935	f	\N
1	457	3	182	\N	3	f	\N	2011-10-31 19:22:41.132554	f	\N
1	458	2	182	\N	3	f	\N	2011-10-31 20:49:25.076732	f	\N
1	459	1	101	\N	3	f	\N	2011-10-31 23:03:05.8731	f	\N
1	460	1	182	\N	3	f	\N	2011-11-01 15:16:13.600869	f	\N
1	462	3	101	\N	3	f	\N	2011-11-01 16:50:55.505754	f	\N
1	463	1	101	\N	3	f	\N	2011-11-02 11:58:48.411437	f	\N
1	464	1	182	\N	3	f	\N	2011-11-02 12:29:39.177724	f	\N
1	465	3	182	\N	3	f	\N	2011-11-02 13:38:49.650302	f	\N
1	466	3	101	\N	3	f	\N	2011-11-02 13:50:03.991611	f	\N
1	471	3	101	\N	3	f	\N	2011-11-02 19:18:30.210639	f	\N
1	2267	1	182	\N	3	f	\N	2011-11-24 10:06:08.005111	t	2011-11-24 10:07:06.988478
1	2539	41	182	\N	3	f	\N	2011-11-25 03:34:52.092891	f	\N
1	474	1	182	\N	3	f	\N	2011-11-03 09:18:58.651788	f	\N
1	476	1	182	\N	3	f	\N	2011-11-03 09:23:48.608751	t	2011-11-24 15:43:01.474708
1	477	1	182	\N	3	f	\N	2011-11-03 09:25:16.664865	f	\N
1	478	1	182	\N	3	f	\N	2011-11-03 09:25:36.091016	f	\N
1	479	2	182	\N	3	f	\N	2011-11-03 09:25:46.819313	f	\N
1	480	1	182	\N	3	f	\N	2011-11-03 09:26:20.885779	f	\N
1	481	1	182	\N	3	f	\N	2011-11-03 09:26:28.21244	f	\N
1	482	1	182	\N	3	f	\N	2011-11-03 09:28:10.331618	f	\N
1	483	1	182	\N	3	f	\N	2011-11-03 09:28:10.479742	f	\N
1	484	1	182	\N	3	f	\N	2011-11-03 09:28:48.818742	f	\N
1	487	1	182	\N	3	f	\N	2011-11-03 09:29:35.340325	f	\N
1	519	2	158	\N	3	f	\N	2011-11-03 10:28:48.001368	f	\N
1	520	2	158	\N	3	f	\N	2011-11-03 10:33:04.610397	f	\N
1	521	3	182	\N	3	f	\N	2011-11-03 11:41:55.197748	f	\N
1	522	2	182	\N	3	f	\N	2011-11-03 11:43:03.320371	f	\N
1	2419	172	25	\N	3	f	\N	2011-11-24 15:36:01.684447	f	\N
1	1282	1	182	\N	3	f	\N	2011-11-22 09:55:51.908913	t	2011-11-25 09:42:49.816883
1	523	3	182	\N	3	f	\N	2011-11-03 12:19:58.687108	t	2011-11-26 13:13:55.645755
1	524	1	146	\N	3	f	\N	2011-11-03 12:46:48.207189	f	\N
1	525	2	182	\N	3	f	\N	2011-11-03 13:58:30.15612	f	\N
1	526	3	101	\N	3	f	\N	2011-11-03 16:21:47.737727	f	\N
1	527	1	101	\N	3	f	\N	2011-11-03 16:32:37.648185	f	\N
1	528	2	160	\N	3	f	\N	2011-11-03 17:30:12.204265	f	\N
1	529	3	101	\N	3	f	\N	2011-11-03 20:43:13.199457	f	\N
1	530	3	101	\N	3	f	\N	2011-11-03 20:47:07.053619	f	\N
1	531	3	101	\N	3	f	\N	2011-11-03 21:01:07.532749	f	\N
1	532	1	182	\N	3	f	\N	2011-11-03 22:12:54.828905	f	\N
1	2202	101	101	\N	3	f	\N	2011-11-23 20:47:46.364772	t	2011-11-25 09:20:50.591185
1	534	3	182	\N	3	f	\N	2011-11-04 08:58:35.785045	f	\N
1	2620	1	182	\N	3	f	\N	2011-11-26 08:53:01.328619	t	2011-11-26 08:53:46.012551
1	2596	1	101	\N	3	f	\N	2011-11-25 15:54:51.447021	t	2011-11-25 15:56:06.239286
1	537	3	182	\N	3	f	\N	2011-11-04 09:00:19.464902	f	\N
1	2637	1	101	\N	3	f	\N	2011-11-26 12:03:38.084794	t	2011-11-26 12:04:15.830737
1	2597	21	101	\N	3	f	\N	2011-11-25 16:10:07.394206	f	\N
1	2403	1	182	\N	3	f	\N	2011-11-24 14:49:08.197444	t	2011-11-24 15:00:17.769047
1	541	3	182	\N	3	f	\N	2011-11-04 09:00:42.804989	f	\N
1	542	3	182	\N	3	f	\N	2011-11-04 09:00:46.916292	f	\N
1	2648	1	22	\N	3	f	\N	2011-11-26 14:05:10.362348	t	2011-11-26 14:05:54.62941
1	544	3	182	\N	3	f	\N	2011-11-04 09:01:53.521862	f	\N
1	545	3	182	\N	3	f	\N	2011-11-04 09:02:29.647025	f	\N
1	546	3	182	\N	3	f	\N	2011-11-04 09:04:02.119984	f	\N
1	547	3	182	\N	3	f	\N	2011-11-04 09:04:18.996614	f	\N
1	549	3	182	\N	3	f	\N	2011-11-04 09:04:23.60953	f	\N
1	2598	1	101	\N	3	f	\N	2011-11-25 16:39:27.831036	t	2011-11-25 16:40:04.571554
1	556	3	182	\N	3	f	\N	2011-11-04 09:06:47.924851	f	\N
1	557	3	182	\N	3	f	\N	2011-11-04 09:06:59.439062	f	\N
1	558	3	182	\N	3	f	\N	2011-11-04 09:08:31.140453	f	\N
1	560	3	182	\N	3	f	\N	2011-11-04 09:09:17.964947	f	\N
1	561	3	182	\N	3	f	\N	2011-11-04 09:09:37.161904	f	\N
1	794	61	102	\N	3	f	\N	2011-11-13 12:38:33.163035	t	2011-11-26 14:25:11.774161
1	2599	1	101	\N	3	f	\N	2011-11-25 16:41:54.702271	t	2011-11-25 16:42:24.365672
1	1655	21	101	\N	3	f	\N	2011-11-22 21:26:55.128372	t	2011-11-26 15:04:34.140308
1	565	2	159	\N	3	f	\N	2011-11-04 09:12:50.572772	f	\N
1	569	3	182	\N	3	f	\N	2011-11-04 09:15:58.804283	f	\N
1	573	3	182	\N	3	f	\N	2011-11-04 09:19:38.557883	f	\N
1	574	3	182	\N	3	f	\N	2011-11-04 09:20:19.771775	f	\N
1	2670	1	125	\N	3	f	\N	2011-11-26 15:20:13.328349	t	2011-11-26 15:20:22.394113
1	2600	1	101	\N	3	f	\N	2011-11-25 16:42:13.921273	t	2011-11-25 16:42:41.451214
1	577	1	101	\N	3	f	\N	2011-11-04 11:18:10.696052	f	\N
1	578	1	101	\N	3	f	\N	2011-11-04 11:21:55.7866	f	\N
1	579	3	182	\N	3	f	\N	2011-11-04 13:35:52.706198	f	\N
1	580	1	182	\N	3	f	\N	2011-11-04 15:11:48.004794	t	2011-11-24 14:52:50.526023
1	2676	1	101	\N	3	f	\N	2011-11-26 15:49:39.777545	t	2011-11-26 15:50:20.894161
1	581	1	32	\N	3	f	\N	2011-11-04 21:48:41.64616	f	\N
1	585	3	101	\N	3	f	\N	2011-11-06 00:26:33.998035	f	\N
1	586	2	182	\N	3	f	\N	2011-11-07 09:29:27.354015	f	\N
1	583	1	32	\N	3	f	\N	2011-11-04 21:58:30.045634	f	\N
1	587	2	182	\N	3	f	\N	2011-11-07 12:02:32.091297	f	\N
1	588	3	125	\N	3	f	\N	2011-11-07 14:51:05.549578	f	\N
1	582	1	32	\N	3	f	\N	2011-11-04 21:49:16.158345	f	\N
1	589	2	182	\N	3	f	\N	2011-11-07 15:21:30.734132	f	\N
1	590	3	101	\N	3	f	\N	2011-11-07 16:39:33.317404	f	\N
1	591	1	69	\N	3	f	\N	2011-11-07 16:41:34.203561	f	\N
1	595	3	101	\N	3	f	\N	2011-11-07 18:18:49.387268	f	\N
1	596	3	101	\N	3	f	\N	2011-11-07 18:36:49.532318	t	2011-11-25 17:37:09.742581
1	454	1	101	\N	3	f	\N	2011-10-31 18:27:19.821842	f	\N
1	2420	104	125	\N	3	f	\N	2011-11-24 15:37:41.317391	f	\N
1	608	3	182	\N	3	f	\N	2011-11-07 21:47:43.607825	f	\N
1	609	3	182	\N	3	f	\N	2011-11-07 21:48:28.235234	f	\N
1	612	3	182	\N	3	f	\N	2011-11-07 21:50:44.369926	f	\N
1	613	3	101	\N	3	f	\N	2011-11-07 22:39:08.936244	t	2011-11-25 11:55:20.215925
1	614	3	101	\N	3	f	\N	2011-11-07 23:02:49.829515	f	\N
1	615	3	101	\N	3	f	\N	2011-11-07 23:30:57.064224	f	\N
1	616	3	101	\N	3	f	\N	2011-11-08 01:35:32.871615	f	\N
1	617	2	182	\N	3	f	\N	2011-11-08 08:07:30.989561	f	\N
1	618	1	101	\N	3	f	\N	2011-11-08 09:07:48.604479	f	\N
1	619	3	101	\N	3	f	\N	2011-11-08 10:18:24.71656	f	\N
1	620	1	64	\N	3	f	\N	2011-11-08 10:37:59.577255	f	\N
1	621	1	182	\N	3	f	\N	2011-11-08 11:56:06.009774	f	\N
1	622	1	182	\N	3	f	\N	2011-11-08 11:57:43.759863	f	\N
1	623	3	125	\N	3	f	\N	2011-11-08 12:05:08.336013	f	\N
1	624	3	101	\N	3	f	\N	2011-11-08 13:40:36.439241	t	2011-11-24 08:37:26.372034
1	2239	1	101	\N	3	f	\N	2011-11-24 01:00:33.942468	f	\N
1	626	3	101	\N	3	f	\N	2011-11-08 15:34:19.906815	t	2011-11-25 15:26:28.965599
1	627	3	150	\N	3	f	\N	2011-11-08 15:50:37.98393	f	\N
1	628	3	182	\N	3	f	\N	2011-11-08 16:04:40.755645	t	2011-11-25 09:02:38.345769
1	629	3	101	\N	3	f	\N	2011-11-08 16:48:59.693111	f	\N
1	630	3	182	\N	3	f	\N	2011-11-08 18:49:38.907203	f	\N
1	632	3	101	\N	3	f	\N	2011-11-08 19:33:05.281306	f	\N
1	633	1	101	\N	3	f	\N	2011-11-08 19:38:40.901959	t	2011-11-24 09:21:47.339379
1	2261	1	182	\N	3	f	\N	2011-11-24 09:58:54.752653	t	2011-11-24 09:59:16.583083
1	2517	1	25	\N	3	f	\N	2011-11-24 20:47:13.122937	t	2011-11-25 09:37:21.75084
1	642	1	101	\N	3	f	\N	2011-11-08 23:41:29.03008	f	\N
1	643	3	101	\N	3	f	\N	2011-11-08 23:43:05.268869	f	\N
1	644	3	182	\N	3	f	\N	2011-11-09 01:41:06.728352	f	\N
1	645	1	101	\N	3	f	\N	2011-11-09 09:30:30.28339	f	\N
1	646	3	101	\N	3	f	\N	2011-11-09 10:27:55.197417	f	\N
1	647	1	182	\N	3	f	\N	2011-11-09 11:39:02.284235	f	\N
1	648	1	182	\N	3	f	\N	2011-11-09 11:39:04.664045	f	\N
1	649	1	182	\N	3	f	\N	2011-11-09 11:40:11.286017	f	\N
1	650	1	182	\N	3	f	\N	2011-11-09 11:40:27.692116	f	\N
1	651	1	159	\N	3	f	\N	2011-11-09 11:41:12.756833	f	\N
1	652	1	182	\N	3	f	\N	2011-11-09 11:41:45.143575	f	\N
1	653	1	182	\N	3	f	\N	2011-11-09 11:46:33.682165	f	\N
1	654	2	2	\N	3	f	\N	2011-11-09 11:46:34.505946	f	\N
1	655	1	182	\N	3	f	\N	2011-11-09 11:52:38.159471	f	\N
1	656	3	101	\N	3	f	\N	2011-11-09 11:52:45.68485	f	\N
1	657	1	45	\N	3	f	\N	2011-11-09 11:53:23.509128	f	\N
1	658	1	182	\N	3	f	\N	2011-11-09 12:07:29.413866	f	\N
1	659	1	101	\N	3	f	\N	2011-11-09 13:33:16.954128	f	\N
1	2268	101	101	\N	3	f	\N	2011-11-24 10:07:25.992875	t	2011-11-25 09:20:21.765405
1	660	1	182	\N	3	f	\N	2011-11-09 14:25:47.787844	f	\N
1	662	1	182	\N	3	f	\N	2011-11-09 14:27:38.386021	f	\N
1	663	1	182	\N	3	f	\N	2011-11-09 14:28:55.521327	f	\N
1	669	1	182	\N	3	f	\N	2011-11-09 14:42:19.997088	f	\N
1	670	3	182	\N	3	f	\N	2011-11-09 18:55:07.846336	f	\N
1	671	3	101	\N	3	f	\N	2011-11-09 19:10:19.824234	t	2011-11-24 14:33:47.731235
1	672	3	101	\N	3	f	\N	2011-11-09 19:18:52.596452	f	\N
1	2601	3	101	\N	3	f	\N	2011-11-25 16:45:18.492958	f	\N
1	674	3	101	\N	3	f	\N	2011-11-09 21:22:27.145494	t	2011-11-26 12:48:54.994597
1	675	2	182	\N	3	f	\N	2011-11-09 22:11:54.459804	f	\N
1	676	3	182	\N	3	f	\N	2011-11-10 00:00:04.708127	f	\N
1	2404	1	182	\N	3	f	\N	2011-11-24 14:49:27.573867	t	2011-11-24 14:49:37.692331
1	678	3	101	\N	3	f	\N	2011-11-10 06:33:49.398151	f	\N
1	679	1	101	\N	3	f	\N	2011-11-10 09:40:47.235808	f	\N
1	680	3	182	\N	3	f	\N	2011-11-10 10:27:41.421935	f	\N
1	2621	1	182	\N	3	f	\N	2011-11-26 08:56:00.155881	t	2011-11-26 08:56:15.131477
1	682	3	101	\N	3	f	\N	2011-11-10 13:33:56.942952	f	\N
1	2240	1	32	\N	3	f	\N	2011-11-24 01:15:47.679886	t	2011-11-25 09:52:46.849806
1	2252	130	32	\N	3	f	\N	2011-11-24 09:19:53.146408	t	2011-11-25 09:52:26.242813
1	2262	1	182	\N	3	f	\N	2011-11-24 10:00:04.213864	t	2011-11-24 10:00:36.84469
1	686	1	182	\N	3	f	\N	2011-11-10 14:09:21.84055	f	\N
1	687	1	182	\N	3	f	\N	2011-11-10 14:11:35.459129	f	\N
1	688	1	101	\N	3	f	\N	2011-11-10 15:31:13.522136	f	\N
1	689	3	101	\N	3	f	\N	2011-11-10 16:06:03.543246	f	\N
1	690	2	159	\N	3	f	\N	2011-11-10 17:14:31.999751	f	\N
1	691	1	182	\N	3	f	\N	2011-11-10 17:19:43.734321	f	\N
1	2602	1	101	\N	3	f	\N	2011-11-25 17:53:33.36009	t	2011-11-25 17:55:35.283305
1	693	2	101	\N	3	f	\N	2011-11-10 17:40:10.244946	f	\N
1	694	3	101	\N	3	f	\N	2011-11-10 19:48:00.255734	f	\N
1	2606	74	101	\N	3	f	\N	2011-11-25 18:13:05.48639	f	\N
1	697	3	182	\N	3	f	\N	2011-11-10 20:28:54.293715	f	\N
1	698	3	182	\N	3	f	\N	2011-11-10 20:47:18.882538	f	\N
1	699	3	101	\N	3	f	\N	2011-11-10 20:54:31.473393	t	2011-11-24 15:12:43.950137
1	700	3	101	\N	3	f	\N	2011-11-10 21:06:23.441666	t	2011-11-24 15:13:20.874652
1	701	3	54	\N	3	f	\N	2011-11-10 22:03:47.038967	f	\N
1	702	1	54	\N	3	f	\N	2011-11-10 22:05:35.52561	f	\N
1	703	1	54	\N	3	f	\N	2011-11-10 22:05:37.256118	t	2011-11-25 15:34:04.267554
1	2608	74	101	\N	3	f	\N	2011-11-25 18:13:29.200841	t	2011-11-26 15:14:08.570717
1	2610	102	102	\N	3	f	\N	2011-11-25 18:17:27.222616	t	2011-11-26 09:41:50.596408
1	708	1	54	\N	3	f	\N	2011-11-10 22:09:59.944754	f	\N
1	2638	1	101	\N	3	f	\N	2011-11-26 12:05:26.791006	t	2011-11-26 12:05:36.768914
1	712	1	54	\N	3	f	\N	2011-11-10 22:11:30.934717	f	\N
1	713	1	54	\N	3	f	\N	2011-11-10 22:11:44.610832	f	\N
1	714	1	54	\N	3	f	\N	2011-11-10 22:12:24.234612	f	\N
1	715	1	54	\N	3	f	\N	2011-11-10 22:13:14.845476	f	\N
1	717	1	54	\N	3	f	\N	2011-11-10 22:14:05.686324	f	\N
1	719	1	54	\N	3	f	\N	2011-11-10 22:14:54.681301	t	2011-11-25 15:33:52.162202
1	722	1	54	\N	3	f	\N	2011-11-10 22:16:29.515945	f	\N
1	728	1	54	\N	3	f	\N	2011-11-10 22:20:58.447112	f	\N
1	729	1	54	\N	3	f	\N	2011-11-10 22:22:27.559247	f	\N
1	730	3	101	\N	3	f	\N	2011-11-10 22:48:36.033189	f	\N
1	731	3	101	\N	3	f	\N	2011-11-11 00:26:05.392677	f	\N
1	733	1	54	\N	3	f	\N	2011-11-11 00:48:28.295555	t	2011-11-25 15:35:17.447253
1	734	3	101	\N	3	f	\N	2011-11-11 02:15:21.882255	t	2011-11-24 14:59:20.436797
1	735	21	101	\N	3	f	\N	2011-11-11 09:17:53.658844	f	\N
1	736	1	182	\N	3	f	\N	2011-11-11 10:37:48.783793	f	\N
1	737	3	101	\N	3	f	\N	2011-11-11 12:11:37.396887	f	\N
1	738	1	182	\N	3	f	\N	2011-11-11 12:15:57.383451	f	\N
1	2611	102	102	\N	3	f	\N	2011-11-25 18:28:31.094339	t	2011-11-26 09:42:04.408926
1	745	1	101	\N	3	f	\N	2011-11-11 14:52:48.72154	f	\N
1	746	3	101	\N	3	f	\N	2011-11-11 15:31:28.95995	f	\N
1	748	21	101	\N	3	f	\N	2011-11-11 15:50:15.865561	f	\N
1	749	1	101	\N	3	f	\N	2011-11-11 15:51:56.612032	f	\N
1	750	3	125	\N	3	f	\N	2011-11-11 16:08:41.26916	f	\N
1	2612	74	101	\N	3	f	\N	2011-11-25 18:31:43.270647	f	\N
1	752	3	182	\N	3	f	\N	2011-11-11 17:05:15.407481	f	\N
1	2614	1	101	\N	3	f	\N	2011-11-25 18:35:05.207123	t	2011-11-25 18:35:26.962022
1	2541	1	101	\N	3	f	\N	2011-11-25 08:59:54.941289	t	2011-11-25 09:00:08.371654
1	756	21	101	\N	3	f	\N	2011-11-11 18:46:39.437575	f	\N
1	783	3	101	\N	3	f	\N	2011-11-12 20:59:17.537433	t	2011-11-26 09:16:09.586324
1	753	101	125	\N	3	f	\N	2011-11-11 17:28:54.527884	f	\N
1	762	3	101	\N	3	f	\N	2011-11-11 21:19:28.154973	f	\N
1	767	3	101	\N	3	f	\N	2011-11-12 02:22:30.637438	f	\N
1	771	191	182	\N	3	f	\N	2011-11-12 08:56:45.107155	f	\N
1	773	1	182	\N	3	f	\N	2011-11-12 12:35:46.54492	f	\N
1	2421	199	182	\N	3	f	\N	2011-11-24 15:38:08.780133	f	\N
1	775	194	182	\N	3	f	\N	2011-11-12 15:00:08.240006	f	\N
1	776	194	182	\N	3	f	\N	2011-11-12 15:02:03.736978	f	\N
1	777	194	182	\N	3	f	\N	2011-11-12 15:03:57.68827	f	\N
1	778	1	182	\N	3	f	\N	2011-11-12 15:48:38.675697	f	\N
1	779	54	182	\N	3	f	\N	2011-11-12 15:52:28.064158	f	\N
1	780	60	176	\N	3	f	\N	2011-11-12 16:44:25.967933	f	\N
1	781	60	159	\N	3	f	\N	2011-11-12 16:49:12.759718	f	\N
1	782	3	182	\N	3	f	\N	2011-11-12 19:34:48.167155	f	\N
1	784	194	182	\N	3	f	\N	2011-11-12 21:01:14.899389	f	\N
1	785	192	182	\N	3	f	\N	2011-11-12 22:35:30.261377	f	\N
1	786	194	182	\N	3	f	\N	2011-11-12 23:09:16.904175	f	\N
1	788	65	101	\N	3	f	\N	2011-11-13 04:16:35.003953	f	\N
1	789	77	101	\N	3	f	\N	2011-11-13 04:19:28.282309	f	\N
1	2649	1	39	\N	3	f	\N	2011-11-26 14:08:40.614507	t	2011-11-26 14:09:04.478339
1	792	3	101	\N	3	f	\N	2011-11-13 11:34:32.666642	f	\N
1	2433	1	182	\N	3	f	\N	2011-11-24 15:47:27.456128	t	2011-11-24 15:47:42.382019
1	2446	1	182	\N	3	f	\N	2011-11-24 15:51:49.253282	t	2011-11-24 15:52:05.577392
1	796	1	182	\N	3	f	\N	2011-11-13 18:21:16.884811	f	\N
1	597	3	182	\N	3	f	\N	2011-11-07 21:41:59.636901	t	2011-11-25 14:22:22.509607
1	797	21	101	\N	3	f	\N	2011-11-13 19:34:31.741331	f	\N
1	2460	1	182	\N	3	f	\N	2011-11-24 16:17:47.598282	t	2011-11-24 16:18:04.259823
1	799	60	159	\N	3	f	\N	2011-11-13 21:08:16.579793	f	\N
1	806	1	101	\N	3	f	\N	2011-11-14 14:51:44.816085	t	2011-11-24 15:15:48.137161
1	1301	1	182	\N	3	f	\N	2011-11-22 10:11:42.445197	t	2011-11-25 09:42:50.148067
1	2514	1	146	\N	3	f	\N	2011-11-24 20:27:52.982171	t	2011-11-25 09:48:01.619247
1	1440	104	125	\N	3	f	\N	2011-11-22 16:47:10.46632	t	2011-11-25 09:55:04.355945
1	2021	1	148	\N	3	f	\N	2011-11-23 15:30:55.076787	t	2011-11-25 09:57:29.811263
1	2615	1	101	\N	3	f	\N	2011-11-25 19:08:45.004337	t	2011-11-26 09:57:13.997785
1	822	194	182	\N	3	f	\N	2011-11-14 22:25:49.457625	f	\N
1	2405	1	182	\N	3	f	\N	2011-11-24 14:50:13.961695	t	2011-11-24 14:50:45.969379
1	757	194	182	\N	3	f	\N	2011-11-11 18:50:07.611007	f	\N
1	461	3	101	\N	3	f	\N	2011-11-01 16:41:19.575288	t	2011-11-25 19:52:42.379862
1	828	3	101	\N	3	f	\N	2011-11-15 12:04:52.742446	f	\N
1	835	3	101	\N	3	f	\N	2011-11-15 16:29:48.981154	f	\N
1	840	3	1	\N	3	f	\N	2011-11-15 18:12:17.667477	f	\N
1	845	3	101	\N	3	f	\N	2011-11-15 19:22:57.120401	f	\N
1	850	192	182	\N	3	f	\N	2011-11-16 06:24:05.82574	f	\N
1	2616	1	101	\N	3	f	\N	2011-11-25 19:54:14.444827	t	2011-11-25 19:54:29.227158
1	863	194	182	\N	3	f	\N	2011-11-16 10:50:00.561277	f	\N
1	906	1	182	\N	3	f	\N	2011-11-16 12:27:22.333283	t	2011-11-25 15:54:20.812688
1	911	194	182	\N	3	f	\N	2011-11-16 14:39:28.25703	f	\N
1	922	194	182	\N	3	f	\N	2011-11-16 14:55:11.489655	f	\N
1	936	21	101	\N	3	f	\N	2011-11-16 20:58:14.03243	f	\N
1	941	3	182	\N	3	f	\N	2011-11-16 21:56:55.020327	f	\N
1	791	3	101	\N	3	f	\N	2011-11-13 09:44:37.837919	t	2011-11-25 19:59:22.905472
1	986	62	101	\N	3	f	\N	2011-11-17 22:10:41.974482	f	\N
1	695	194	182	\N	3	f	\N	2011-11-10 20:06:06.59623	f	\N
1	971	1	182	\N	3	f	\N	2011-11-17 10:35:18.796416	f	\N
1	976	194	182	\N	3	f	\N	2011-11-17 15:01:22.956227	f	\N
1	981	21	101	\N	3	f	\N	2011-11-17 17:07:47.790345	f	\N
1	991	136	39	\N	3	f	\N	2011-11-17 23:45:34.284496	f	\N
1	2204	114	27	\N	3	f	\N	2011-11-23 20:56:43.598563	f	\N
1	1003	194	182	\N	3	f	\N	2011-11-18 15:00:32.561228	f	\N
1	2636	1	64	\N	3	f	\N	2011-11-26 10:55:57.389957	t	2011-11-26 10:56:10.552019
1	1015	1	182	\N	3	f	\N	2011-11-18 17:49:19.422565	f	\N
1	1020	1	182	\N	3	f	\N	2011-11-18 19:12:30.86776	f	\N
1	1027	3	182	\N	3	f	\N	2011-11-18 20:19:24.529695	f	\N
1	1032	21	101	\N	3	f	\N	2011-11-18 21:04:35.313498	f	\N
1	1037	3	101	\N	3	f	\N	2011-11-18 22:58:26.906386	f	\N
1	1044	3	125	\N	3	f	\N	2011-11-19 11:09:36.694851	t	2011-11-24 14:53:30.348699
1	1058	3	101	\N	3	f	\N	2011-11-19 16:46:56.636687	f	\N
1	2241	1	182	\N	3	f	\N	2011-11-24 01:52:14.450929	f	\N
1	1068	41	182	\N	3	f	\N	2011-11-19 22:52:46.919129	t	2011-11-25 09:02:27.765803
1	1069	3	101	\N	3	f	\N	2011-11-19 23:30:34.381398	f	\N
1	1072	41	32	\N	3	f	\N	2011-11-20 01:57:21.626785	f	\N
1	1073	1	182	\N	3	f	\N	2011-11-20 07:56:31.226792	f	\N
1	2519	1	25	\N	3	f	\N	2011-11-24 20:54:23.849037	t	2011-11-25 09:38:04.592263
1	1075	1	182	\N	3	f	\N	2011-11-20 10:30:24.758507	t	2011-11-24 09:06:19.300042
1	1076	3	182	\N	3	f	\N	2011-11-20 11:04:09.718925	f	\N
1	1079	3	101	\N	3	f	\N	2011-11-20 14:36:14.809742	f	\N
1	1080	3	182	\N	3	f	\N	2011-11-20 15:00:00.885451	f	\N
1	1081	3	101	\N	3	f	\N	2011-11-20 15:39:36.944764	t	2011-11-26 08:43:29.523359
1	1082	21	101	\N	3	f	\N	2011-11-20 15:46:10.626928	f	\N
1	1083	1	101	\N	3	f	\N	2011-11-20 18:07:14.696447	f	\N
1	1085	3	182	\N	3	f	\N	2011-11-20 18:35:20.304783	f	\N
1	1086	3	101	\N	3	f	\N	2011-11-20 18:52:20.716429	f	\N
1	1087	72	101	\N	3	f	\N	2011-11-20 19:33:08.21941	f	\N
1	1088	21	101	\N	3	f	\N	2011-11-20 20:42:16.846207	f	\N
1	1089	1	101	\N	3	f	\N	2011-11-20 20:44:55.664742	f	\N
1	1465	62	101	\N	3	f	\N	2011-11-22 16:58:21.102362	t	2011-11-24 09:20:57.023726
1	1091	3	101	\N	3	f	\N	2011-11-20 22:51:14.067744	f	\N
1	1092	3	101	\N	3	f	\N	2011-11-20 23:55:36.008464	f	\N
1	1093	21	101	\N	3	f	\N	2011-11-21 00:16:13.037042	f	\N
1	1094	1	182	\N	3	f	\N	2011-11-21 02:52:18.147461	f	\N
1	1095	3	182	\N	3	f	\N	2011-11-21 09:11:46.891135	t	2011-11-23 15:05:23.252472
1	1096	3	101	\N	3	f	\N	2011-11-21 09:12:04.544026	t	2011-11-24 10:02:36.602396
1	2263	1	182	\N	3	f	\N	2011-11-24 10:00:28.881966	t	2011-11-24 10:00:40.981718
1	1098	71	101	\N	3	f	\N	2011-11-21 09:21:49.882447	f	\N
1	1100	3	101	\N	3	f	\N	2011-11-21 10:14:38.370951	t	2011-11-25 09:25:25.311901
1	1102	1	101	\N	3	f	\N	2011-11-21 10:18:18.916631	f	\N
1	1104	3	101	\N	3	f	\N	2011-11-21 10:21:03.885333	f	\N
1	1107	1	124	\N	3	f	\N	2011-11-21 10:32:39.865693	f	\N
1	1108	3	182	\N	3	f	\N	2011-11-21 10:40:35.991377	t	2011-11-24 10:02:24.590172
1	1109	3	182	\N	3	f	\N	2011-11-21 10:43:03.394794	f	\N
1	1110	1	182	\N	3	f	\N	2011-11-21 10:55:30.115905	t	2011-11-24 10:03:12.921075
1	1111	1	182	\N	3	f	\N	2011-11-21 10:57:02.844146	f	\N
1	1170	1	182	\N	3	f	\N	2011-11-21 20:42:55.864938	t	2011-11-25 15:50:29.770395
1	1113	1	182	\N	3	f	\N	2011-11-21 11:01:23.940487	t	2011-11-24 10:03:41.141168
1	2422	1	182	\N	3	f	\N	2011-11-24 15:38:17.870478	t	2011-11-24 15:38:46.853526
1	1119	41	32	\N	3	f	\N	2011-11-21 11:10:14.45634	t	2011-11-25 09:47:05.356983
1	1122	1	182	\N	3	f	\N	2011-11-21 12:33:37.924252	f	\N
1	1123	1	101	\N	3	f	\N	2011-11-21 12:40:11.500147	f	\N
1	1126	65	101	\N	3	f	\N	2011-11-21 13:19:35.149632	f	\N
1	1131	3	182	\N	3	f	\N	2011-11-21 15:01:14.933238	f	\N
1	1133	3	125	\N	3	f	\N	2011-11-21 15:13:15.272083	f	\N
1	1134	3	101	\N	3	f	\N	2011-11-21 15:17:35.148062	f	\N
1	1135	3	101	\N	3	f	\N	2011-11-21 15:35:13.73603	t	2011-11-24 10:03:03.851887
1	1136	77	101	\N	3	f	\N	2011-11-21 15:39:15.374469	f	\N
1	1138	194	182	\N	3	f	\N	2011-11-21 15:53:58.181979	f	\N
1	1139	194	182	\N	3	f	\N	2011-11-21 15:56:53.544641	f	\N
1	1140	3	101	\N	3	f	\N	2011-11-21 16:08:04.823754	f	\N
1	2434	1	182	\N	3	f	\N	2011-11-24 15:47:57.356103	t	2011-11-24 15:48:10.045169
1	1145	3	101	\N	3	f	\N	2011-11-21 16:18:18.169075	f	\N
1	1146	1	101	\N	3	f	\N	2011-11-21 16:28:20.280613	f	\N
1	1147	61	101	\N	3	f	\N	2011-11-21 16:43:19.860985	t	2011-11-26 09:39:28.459913
1	1148	75	182	\N	3	f	\N	2011-11-21 16:49:00.413511	f	\N
1	1149	3	182	\N	3	f	\N	2011-11-21 16:52:06.37928	f	\N
1	1150	3	101	\N	3	f	\N	2011-11-21 17:18:43.069378	f	\N
1	1152	3	101	\N	3	f	\N	2011-11-21 17:45:37.098164	f	\N
1	1153	1	101	\N	3	f	\N	2011-11-21 17:59:42.352024	f	\N
1	1154	72	101	\N	3	f	\N	2011-11-21 18:16:58.108968	f	\N
1	1158	1	101	\N	3	f	\N	2011-11-21 18:55:23.260057	t	2011-11-26 10:12:45.330383
1	1174	3	101	\N	3	f	\N	2011-11-21 20:45:45.886739	f	\N
1	1176	3	101	\N	3	f	\N	2011-11-21 20:57:53.617105	t	2011-11-24 15:13:36.42215
1	2447	1	182	\N	3	f	\N	2011-11-24 15:52:18.577109	t	2011-11-24 15:55:34.631524
1	2461	1	101	\N	3	f	\N	2011-11-24 16:19:11.597158	t	2011-11-24 16:19:50.4802
1	2542	1	182	\N	3	f	\N	2011-11-25 09:01:56.736486	t	2011-11-25 09:02:07.180166
1	1302	1	182	\N	3	f	\N	2011-11-22 10:14:04.413264	t	2011-11-25 09:43:06.284868
1	2554	1	148	\N	3	f	\N	2011-11-25 09:49:54.882562	t	2011-11-25 09:50:05.399857
1	2622	1	101	\N	3	f	\N	2011-11-26 09:10:05.808955	t	2011-11-26 09:10:16.167574
1	1162	3	182	\N	3	f	\N	2011-11-21 19:25:35.390734	f	\N
1	1166	155	162	\N	3	f	\N	2011-11-21 20:00:22.343595	f	\N
1	2205	1	182	\N	3	f	\N	2011-11-23 21:01:12.39574	f	\N
1	2647	1	101	\N	3	f	\N	2011-11-26 13:26:33.889628	t	2011-11-26 13:26:42.375054
1	2406	1	182	\N	3	f	\N	2011-11-24 14:50:30.381636	t	2011-11-24 14:50:52.357025
1	2659	1	1	\N	3	f	\N	2011-11-26 14:24:30.229604	t	2011-11-26 14:24:47.97351
1	2423	133	25	\N	3	f	\N	2011-11-24 15:39:30.480352	f	\N
1	2435	1	182	\N	3	f	\N	2011-11-24 15:48:05.46812	t	2011-11-24 15:48:20.007332
1	1177	21	101	\N	3	f	\N	2011-11-21 21:42:32.395013	f	\N
1	1178	1	182	\N	3	f	\N	2011-11-21 21:50:50.660785	f	\N
1	1179	3	101	\N	3	f	\N	2011-11-21 22:01:22.003839	f	\N
1	1180	3	182	\N	3	f	\N	2011-11-21 22:18:07.133549	f	\N
1	2242	3	101	\N	3	f	\N	2011-11-24 02:52:02.706473	f	\N
1	1184	41	182	\N	3	f	\N	2011-11-21 22:43:14.572852	f	\N
1	1185	1	84	\N	3	f	\N	2011-11-21 22:43:29.987762	f	\N
1	948	21	101	\N	3	f	\N	2011-11-17 09:06:48.982852	t	2011-11-26 14:49:11.65744
1	2669	1	125	\N	3	f	\N	2011-11-26 15:18:27.307159	t	2011-11-26 15:18:41.482718
1	2617	1	101	\N	3	f	\N	2011-11-25 23:21:25.383628	t	2011-11-26 12:06:44.541035
1	1190	193	182	\N	3	f	\N	2011-11-21 23:03:31.092387	f	\N
1	1191	3	182	\N	3	f	\N	2011-11-21 23:04:28.043243	t	2011-11-24 14:37:54.561884
1	641	3	182	\N	3	f	\N	2011-11-08 23:16:11.16956	f	\N
1	1192	3	182	\N	3	f	\N	2011-11-21 23:08:57.845612	f	\N
1	2253	3	101	\N	3	f	\N	2011-11-24 09:21:15.181852	t	2011-11-24 09:21:26.782045
1	1195	1	101	\N	3	f	\N	2011-11-21 23:28:50.868806	f	\N
1	2675	1	101	\N	3	f	\N	2011-11-26 15:48:05.634553	t	2011-11-26 16:02:08.577754
1	1197	1	101	\N	3	f	\N	2011-11-21 23:34:30.819183	f	\N
1	1198	41	101	\N	3	f	\N	2011-11-22 00:41:12.265964	f	\N
1	1199	1	182	\N	3	f	\N	2011-11-22 00:53:22.399407	f	\N
1	1200	3	101	\N	3	f	\N	2011-11-22 01:30:27.716866	f	\N
1	1201	1	84	\N	3	f	\N	2011-11-22 02:10:06.422082	f	\N
1	1794	1	182	\N	3	f	\N	2011-11-23 10:22:57.421227	t	2011-11-24 10:01:11.424584
1	1203	21	101	\N	3	f	\N	2011-11-22 07:49:21.360898	f	\N
1	1204	1	84	\N	3	f	\N	2011-11-22 08:54:09.778994	f	\N
1	1205	3	101	\N	3	f	\N	2011-11-22 08:59:25.254896	f	\N
1	2679	1	101	\N	3	f	\N	2011-11-26 16:03:51.659153	t	2011-11-26 16:06:01.210024
1	1220	155	162	\N	3	f	\N	2011-11-22 09:32:27.979588	f	\N
1	1221	155	162	\N	3	f	\N	2011-11-22 09:32:41.901478	f	\N
1	1222	1	84	\N	3	f	\N	2011-11-22 09:33:20.302507	f	\N
1	1223	155	162	\N	3	f	\N	2011-11-22 09:33:27.738436	f	\N
1	1224	155	162	\N	3	f	\N	2011-11-22 09:33:30.863552	f	\N
1	1225	155	162	\N	3	f	\N	2011-11-22 09:33:41.125306	f	\N
1	1226	155	162	\N	3	f	\N	2011-11-22 09:33:49.140412	f	\N
1	1227	155	162	\N	3	f	\N	2011-11-22 09:34:05.84757	f	\N
1	1228	155	162	\N	3	f	\N	2011-11-22 09:34:13.315008	f	\N
1	1229	155	162	\N	3	f	\N	2011-11-22 09:34:25.965945	f	\N
1	1230	155	162	\N	3	f	\N	2011-11-22 09:34:36.074952	f	\N
1	1231	155	162	\N	3	f	\N	2011-11-22 09:34:47.744107	f	\N
1	1232	155	162	\N	3	f	\N	2011-11-22 09:34:59.10382	f	\N
1	1233	155	162	\N	3	f	\N	2011-11-22 09:35:04.198378	f	\N
1	1234	155	162	\N	3	f	\N	2011-11-22 09:35:08.47078	f	\N
1	1235	155	162	\N	3	f	\N	2011-11-22 09:35:13.633519	f	\N
1	1236	155	162	\N	3	f	\N	2011-11-22 09:36:01.404512	f	\N
1	1237	155	162	\N	3	f	\N	2011-11-22 09:36:19.677506	f	\N
1	1238	155	162	\N	3	f	\N	2011-11-22 09:36:43.207125	f	\N
1	1239	155	162	\N	3	f	\N	2011-11-22 09:36:54.281612	f	\N
1	1240	155	162	\N	3	f	\N	2011-11-22 09:37:05.551165	f	\N
1	1244	155	162	\N	3	f	\N	2011-11-22 09:38:55.151565	f	\N
1	1246	155	162	\N	3	f	\N	2011-11-22 09:39:26.329898	f	\N
1	1247	155	162	\N	3	f	\N	2011-11-22 09:39:27.78743	f	\N
1	1248	155	162	\N	3	f	\N	2011-11-22 09:39:45.920833	f	\N
1	1249	155	162	\N	3	f	\N	2011-11-22 09:40:02.182642	f	\N
1	1250	155	162	\N	3	f	\N	2011-11-22 09:41:04.794988	f	\N
1	1251	155	162	\N	3	f	\N	2011-11-22 09:41:04.865702	f	\N
1	1252	155	162	\N	3	f	\N	2011-11-22 09:41:08.059629	f	\N
1	1253	155	162	\N	3	f	\N	2011-11-22 09:41:46.404557	f	\N
1	1254	155	162	\N	3	f	\N	2011-11-22 09:41:59.829111	f	\N
1	1255	155	162	\N	3	f	\N	2011-11-22 09:42:19.989996	f	\N
1	1256	155	162	\N	3	f	\N	2011-11-22 09:43:08.572967	f	\N
1	1257	1	182	\N	3	f	\N	2011-11-22 09:43:52.91034	t	2011-11-25 09:41:22.758278
1	1258	155	162	\N	3	f	\N	2011-11-22 09:44:14.516413	f	\N
1	705	61	101	\N	3	f	\N	2011-11-10 22:06:15.5592	t	2011-11-26 14:10:09.745359
1	1260	1	84	\N	3	f	\N	2011-11-22 09:44:51.362286	f	\N
1	1261	1	182	\N	3	f	\N	2011-11-22 09:45:06.341304	f	\N
1	1263	155	162	\N	3	f	\N	2011-11-22 09:45:26.227964	f	\N
1	1264	1	182	\N	3	f	\N	2011-11-22 09:45:40.446191	f	\N
1	1268	155	162	\N	3	f	\N	2011-11-22 09:46:43.934073	f	\N
1	1270	1	84	\N	3	f	\N	2011-11-22 09:48:18.184679	f	\N
1	1274	1	84	\N	3	f	\N	2011-11-22 09:50:22.250403	f	\N
1	1275	155	162	\N	3	f	\N	2011-11-22 09:52:14.925084	f	\N
1	2661	1	182	\N	3	f	\N	2011-11-26 14:26:59.148756	t	2011-11-26 14:27:27.867548
1	2453	1	101	\N	3	f	\N	2011-11-24 15:55:45.454539	t	2011-11-24 15:55:55.043798
1	1626	1	182	\N	3	f	\N	2011-11-22 20:32:23.271203	f	\N
1	1285	155	162	\N	3	f	\N	2011-11-22 09:58:54.914893	f	\N
1	1286	155	162	\N	3	f	\N	2011-11-22 10:00:07.14722	f	\N
1	1291	155	162	\N	3	f	\N	2011-11-22 10:02:55.310246	f	\N
1	1292	155	162	\N	3	f	\N	2011-11-22 10:05:20.421535	f	\N
1	2665	1	101	\N	3	f	\N	2011-11-26 15:06:10.934519	t	2011-11-26 15:06:20.325265
1	1299	1	182	\N	3	f	\N	2011-11-22 10:11:12.233047	t	2011-11-25 09:42:29.461139
1	1300	1	182	\N	3	f	\N	2011-11-22 10:11:16.472094	f	\N
1	2671	1	182	\N	3	f	\N	2011-11-26 15:21:31.414388	t	2011-11-26 15:21:39.699861
1	1303	3	101	\N	3	f	\N	2011-11-22 10:16:33.322699	f	\N
1	1310	1	182	\N	3	f	\N	2011-11-22 10:24:07.072665	t	2011-11-25 09:42:17.622686
1	1311	65	101	\N	3	f	\N	2011-11-22 10:30:31.891372	f	\N
1	2543	105	101	\N	3	f	\N	2011-11-25 09:18:04.713678	t	2011-11-25 09:18:14.070409
1	1314	1	84	\N	3	f	\N	2011-11-22 10:45:43.635859	f	\N
1	1315	131	32	\N	3	f	\N	2011-11-22 10:55:54.17155	f	\N
1	1317	131	32	\N	3	f	\N	2011-11-22 10:58:41.400046	f	\N
1	1318	3	182	\N	3	f	\N	2011-11-22 10:59:09.444928	t	2011-11-26 10:59:25.324322
1	1323	131	32	\N	3	f	\N	2011-11-22 11:01:58.834541	f	\N
1	1324	132	155	\N	3	f	\N	2011-11-22 11:02:34.097542	f	\N
1	1630	1	85	\N	3	f	\N	2011-11-22 20:39:33.241621	f	\N
1	341	3	182	\N	3	f	\N	2011-10-17 12:48:21.120346	t	2011-11-24 10:09:30.571237
1	2677	1	101	\N	3	f	\N	2011-11-26 15:49:51.576636	t	2011-11-26 16:04:58.351344
1	1325	133	25	\N	3	f	\N	2011-11-22 11:02:52.458383	t	2011-11-25 09:31:36.706592
1	1326	131	32	\N	3	f	\N	2011-11-22 11:04:04.349696	f	\N
1	2681	1	101	\N	3	f	\N	2011-11-26 16:12:12.443703	t	2011-11-26 16:12:32.254973
1	1328	1	102	\N	3	f	\N	2011-11-22 11:05:22.63377	f	\N
1	2206	101	101	\N	3	f	\N	2011-11-23 21:08:52.412476	t	2011-11-25 09:21:17.287505
1	1332	132	155	\N	3	f	\N	2011-11-22 11:05:50.957296	f	\N
1	1336	61	101	\N	3	f	\N	2011-11-22 11:07:29.201437	f	\N
1	2200	102	102	\N	3	f	\N	2011-11-23 20:42:00.057386	f	\N
1	2407	1	182	\N	3	f	\N	2011-11-24 14:52:35.714392	t	2011-11-24 14:52:46.38194
1	1339	191	25	\N	3	f	\N	2011-11-22 11:11:42.75732	t	2011-11-25 09:32:00.262183
1	1340	1	101	\N	3	f	\N	2011-11-22 11:15:25.351523	f	\N
1	1350	132	155	\N	3	f	\N	2011-11-22 11:30:00.556066	f	\N
1	1351	3	182	\N	3	f	\N	2011-11-22 11:31:57.514822	t	2011-11-24 09:25:36.595682
1	1352	1	25	\N	3	f	\N	2011-11-22 11:41:06.672439	t	2011-11-25 09:31:05.804724
1	2683	1	101	\N	3	f	\N	2011-11-26 16:35:31.79591	t	2011-11-26 16:36:20.125492
1	2689	1	182	\N	3	f	\N	2011-12-29 12:08:14.56036	f	\N
1	1355	131	32	\N	3	f	\N	2011-11-22 11:50:55.940717	f	\N
1	2424	1	12	\N	3	f	\N	2011-11-24 15:41:50.07457	t	2011-11-25 09:32:19.66642
1	2436	1	182	\N	3	f	\N	2011-11-24 15:48:51.265108	t	2011-11-24 15:49:34.917235
1	824	3	125	\N	3	f	\N	2011-11-15 09:57:48.587851	f	\N
1	1359	131	32	\N	3	f	\N	2011-11-22 11:57:45.381241	f	\N
1	1360	41	42	\N	3	f	\N	2011-11-22 12:00:13.966017	f	\N
1	450	1	182	\N	3	f	\N	2011-10-31 16:14:24.57579	t	2011-11-26 15:15:30.994662
1	1362	21	101	\N	3	f	\N	2011-11-22 12:01:08.42762	f	\N
1	2462	1	182	\N	3	f	\N	2011-11-24 16:19:22.928844	f	\N
1	2469	1	182	\N	3	f	\N	2011-11-24 17:07:35.363024	f	\N
1	2479	101	101	\N	3	f	\N	2011-11-24 18:35:06.454401	t	2011-11-25 09:14:15.652767
1	2491	72	101	\N	3	f	\N	2011-11-24 19:12:38.623518	f	\N
1	2496	3	101	\N	3	f	\N	2011-11-24 19:30:26.269541	f	\N
1	2521	105	101	\N	3	f	\N	2011-11-24 21:07:31.330922	t	2011-11-25 09:21:30.685464
1	2559	1	148	\N	3	f	\N	2011-11-25 10:01:47.22613	t	2011-11-25 10:02:14.144771
1	1370	131	32	\N	3	f	\N	2011-11-22 12:16:40.46563	f	\N
1	1371	1	12	\N	3	f	\N	2011-11-22 12:25:26.179948	t	2011-11-25 09:31:49.879824
1	1372	62	101	\N	3	f	\N	2011-11-22 12:35:30.732205	f	\N
1	1373	1	182	\N	3	f	\N	2011-11-22 12:44:47.553269	f	\N
1	1374	155	162	\N	3	f	\N	2011-11-22 12:48:37.970656	f	\N
1	1375	1	182	\N	3	f	\N	2011-11-22 13:00:09.149596	f	\N
1	1376	1	101	\N	3	f	\N	2011-11-22 13:04:57.976458	f	\N
1	1377	72	101	\N	3	f	\N	2011-11-22 13:12:05.030331	f	\N
1	1378	155	165	\N	3	f	\N	2011-11-22 14:03:49.282597	f	\N
1	2623	1	101	\N	3	f	\N	2011-11-26 09:38:06.546138	t	2011-11-26 09:39:42.410242
1	1380	41	182	\N	3	f	\N	2011-11-22 14:15:31.449876	f	\N
1	1381	3	101	\N	3	f	\N	2011-11-22 14:16:32.569896	t	2011-11-24 14:36:09.376091
1	1383	21	101	\N	3	f	\N	2011-11-22 14:20:13.93443	f	\N
1	1385	3	101	\N	3	f	\N	2011-11-22 14:26:35.897386	f	\N
1	1386	155	165	\N	3	f	\N	2011-11-22 14:27:08.735128	f	\N
1	1394	1	148	\N	3	f	\N	2011-11-22 14:32:27.788821	t	2011-11-25 09:46:34.684624
1	2243	41	32	\N	3	f	\N	2011-11-24 03:06:04.656888	t	2011-11-25 13:31:02.398678
1	1396	1	101	\N	3	f	\N	2011-11-22 14:41:07.852676	f	\N
1	1397	1	101	\N	3	f	\N	2011-11-22 14:47:59.42193	f	\N
1	1398	3	64	\N	3	f	\N	2011-11-22 14:48:30.736995	f	\N
1	1399	1	101	\N	3	f	\N	2011-11-22 14:50:14.149502	f	\N
1	1400	1	182	\N	3	f	\N	2011-11-22 14:55:10.942221	f	\N
1	1663	1	101	\N	3	f	\N	2011-11-22 21:38:46.256348	t	2011-11-24 09:21:46.052366
1	1403	1	148	\N	3	f	\N	2011-11-22 15:26:59.350344	t	2011-11-25 09:50:33.894345
1	1404	1	148	\N	3	f	\N	2011-11-22 15:27:34.784588	t	2011-11-25 09:46:59.651634
1	1405	3	182	\N	3	f	\N	2011-11-22 15:33:54.177922	f	\N
1	1406	67	101	\N	3	f	\N	2011-11-22 15:46:52.902558	f	\N
1	1408	67	101	\N	3	f	\N	2011-11-22 15:49:09.446284	f	\N
1	1409	3	101	\N	3	f	\N	2011-11-22 15:49:27.182797	f	\N
1	2639	61	102	\N	3	f	\N	2011-11-26 12:08:34.983296	t	2011-11-26 12:17:54.638176
1	1411	1	101	\N	3	f	\N	2011-11-22 16:07:47.207501	f	\N
1	1412	3	182	\N	3	f	\N	2011-11-22 16:08:39.280749	f	\N
1	1413	3	101	\N	3	f	\N	2011-11-22 16:31:50.42607	t	2011-11-24 15:11:20.431279
1	1414	3	101	\N	3	f	\N	2011-11-22 16:32:35.909901	t	2011-11-24 14:50:20.132915
1	1415	101	101	\N	3	f	\N	2011-11-22 16:35:01.35846	t	2011-11-25 08:57:20.50145
1	1418	1	101	\N	3	f	\N	2011-11-22 16:41:54.051903	t	2011-11-25 15:24:08.293729
1	1419	101	101	\N	3	f	\N	2011-11-22 16:42:15.670318	t	2011-11-25 09:17:29.176984
1	1420	101	101	\N	3	f	\N	2011-11-22 16:42:22.853826	t	2011-11-25 09:11:13.030148
1	1421	101	101	\N	3	f	\N	2011-11-22 16:42:27.159962	t	2011-11-25 09:25:25.389222
1	1422	101	101	\N	3	f	\N	2011-11-22 16:42:30.232136	t	2011-11-25 09:11:46.882581
1	1423	101	101	\N	3	f	\N	2011-11-22 16:42:45.067614	t	2011-11-25 09:27:11.359727
1	1424	105	101	\N	3	f	\N	2011-11-22 16:42:59.232646	t	2011-11-25 09:24:49.652051
1	1425	101	101	\N	3	f	\N	2011-11-22 16:43:02.837947	t	2011-11-25 09:11:07.697883
1	1426	105	101	\N	3	f	\N	2011-11-22 16:43:30.795043	f	\N
1	2650	1	42	\N	3	f	\N	2011-11-26 14:12:47.092198	t	2011-11-26 14:13:05.375823
1	1429	101	101	\N	3	f	\N	2011-11-22 16:44:41.096805	t	2011-11-25 09:11:36.172018
1	1432	101	101	\N	3	f	\N	2011-11-22 16:45:07.594132	f	\N
1	787	1	182	\N	3	f	\N	2011-11-13 00:51:13.360127	t	2011-11-26 14:41:26.678141
1	1435	101	101	\N	3	f	\N	2011-11-22 16:45:46.51676	t	2011-11-25 09:15:41.726237
1	2666	1	101	\N	3	f	\N	2011-11-26 15:08:21.689815	t	2011-11-26 15:09:05.702521
1	1437	3	101	\N	3	f	\N	2011-11-22 16:45:54.547931	t	2011-11-25 09:22:56.08069
1	2672	61	101	\N	3	f	\N	2011-11-26 15:27:05.971944	t	2011-11-26 15:27:16.104018
1	1441	101	101	\N	3	f	\N	2011-11-22 16:47:22.516556	t	2011-11-25 09:22:05.95894
1	1442	105	101	\N	3	f	\N	2011-11-22 16:47:54.482938	f	\N
1	1443	104	125	\N	3	f	\N	2011-11-22 16:48:17.368787	f	\N
1	1448	105	101	\N	3	f	\N	2011-11-22 16:49:37.081128	t	2011-11-25 09:26:32.75702
1	1449	101	42	\N	3	f	\N	2011-11-22 16:50:35.948912	t	2011-11-25 08:57:56.553704
1	1450	1	182	\N	3	f	\N	2011-11-22 16:50:41.174321	f	\N
1	1451	1	182	\N	3	f	\N	2011-11-22 16:51:08.16919	f	\N
1	1452	101	101	\N	3	f	\N	2011-11-22 16:51:10.491316	t	2011-11-25 09:11:29.893662
1	1453	41	182	\N	3	f	\N	2011-11-22 16:51:52.240786	f	\N
1	1454	104	125	\N	3	f	\N	2011-11-22 16:51:56.119008	f	\N
1	1455	1	182	\N	3	f	\N	2011-11-22 16:52:19.814519	f	\N
1	1456	105	101	\N	3	f	\N	2011-11-22 16:52:36.368072	t	2011-11-25 09:13:10.790596
1	1457	101	101	\N	3	f	\N	2011-11-22 16:52:38.677793	t	2011-11-25 09:27:40.059287
1	1459	1	182	\N	3	f	\N	2011-11-22 16:54:33.860885	f	\N
1	1462	101	101	\N	3	f	\N	2011-11-22 16:54:52.06175	t	2011-11-25 09:15:22.527298
1	2544	101	101	\N	3	f	\N	2011-11-25 09:20:02.788008	t	2011-11-25 09:20:16.478406
1	2348	1	182	\N	3	f	\N	2011-11-24 11:25:27.474553	t	2011-11-25 09:43:08.972009
1	1463	101	101	\N	3	f	\N	2011-11-22 16:55:34.66119	t	2011-11-25 09:13:37.111999
1	1464	101	101	\N	3	f	\N	2011-11-22 16:55:42.979495	f	\N
1	811	131	32	\N	3	f	\N	2011-11-14 16:57:16.030114	t	2011-11-25 10:02:15.570743
1	1467	101	101	\N	3	f	\N	2011-11-22 16:59:14.235578	t	2011-11-25 09:11:57.336332
1	2624	1	125	\N	3	f	\N	2011-11-26 09:41:11.29603	t	2011-11-26 09:41:20.068087
1	1471	101	101	\N	3	f	\N	2011-11-22 17:01:47.883611	f	\N
1	2560	90	125	\N	3	f	\N	2011-11-25 10:02:02.695396	t	2011-11-25 10:02:17.965577
1	1476	103	125	\N	3	f	\N	2011-11-22 17:03:29.386084	t	2011-11-25 09:54:32.948592
1	1480	101	101	\N	3	f	\N	2011-11-22 17:03:57.237893	t	2011-11-25 09:26:23.083928
1	2640	1	101	\N	3	f	\N	2011-11-26 12:19:11.328773	t	2011-11-26 12:19:22.178931
1	1485	101	101	\N	3	f	\N	2011-11-22 17:04:38.28314	t	2011-11-25 09:23:41.819142
1	1491	96	125	\N	3	f	\N	2011-11-22 17:05:19.192559	f	\N
1	2456	1	182	\N	3	f	\N	2011-11-24 16:10:04.836942	t	2011-11-25 10:02:33.269561
1	2651	1	182	\N	3	f	\N	2011-11-26 14:19:08.090884	t	2011-11-26 14:19:24.677673
1	1497	103	125	\N	3	f	\N	2011-11-22 17:06:15.096767	f	\N
1	1498	104	125	\N	3	f	\N	2011-11-22 17:06:18.602813	t	2011-11-25 09:50:59.627331
1	1501	104	125	\N	3	f	\N	2011-11-22 17:06:45.112434	f	\N
1	808	131	32	\N	3	f	\N	2011-11-14 15:28:05.205922	t	2011-11-25 10:02:35.140537
1	1503	104	125	\N	3	f	\N	2011-11-22 17:07:02.122671	t	2011-11-25 09:52:32.789477
1	1504	103	125	\N	3	f	\N	2011-11-22 17:07:19.072248	t	2011-11-25 09:55:29.846795
1	1505	101	101	\N	3	f	\N	2011-11-22 17:07:52.094168	t	2011-11-25 09:13:49.25226
1	1506	103	125	\N	3	f	\N	2011-11-22 17:08:11.242977	f	\N
1	1507	104	125	\N	3	f	\N	2011-11-22 17:08:42.342013	t	2011-11-25 09:56:54.437485
1	1508	104	125	\N	3	f	\N	2011-11-22 17:08:53.321825	t	2011-11-25 09:56:22.186613
1	1509	104	125	\N	3	f	\N	2011-11-22 17:09:02.779865	t	2011-11-25 09:54:53.094603
1	1514	104	125	\N	3	f	\N	2011-11-22 17:11:16.642948	f	\N
1	1515	101	101	\N	3	f	\N	2011-11-22 17:11:34.327594	f	\N
1	1517	103	125	\N	3	f	\N	2011-11-22 17:13:12.28799	t	2011-11-25 09:55:52.546676
1	1518	101	101	\N	3	f	\N	2011-11-22 17:13:16.880326	t	2011-11-25 09:12:08.22951
1	1519	104	125	\N	3	f	\N	2011-11-22 17:13:48.652043	t	2011-11-25 09:55:51.587033
1	2408	1	182	\N	3	f	\N	2011-11-24 14:54:08.880975	t	2011-11-24 14:54:16.915289
1	1528	155	162	\N	3	f	\N	2011-11-22 17:16:10.760245	f	\N
1	1532	1	1	\N	3	f	\N	2011-11-22 17:16:37.901257	t	2011-11-24 15:00:01.997872
1	1537	104	125	\N	3	f	\N	2011-11-22 17:20:15.204455	f	\N
1	1544	3	54	\N	3	f	\N	2011-11-22 17:23:49.976003	t	2011-11-25 14:17:53.056953
1	1547	1	101	\N	3	f	\N	2011-11-22 17:26:13.147725	t	2011-11-25 15:16:54.644354
1	1548	3	182	\N	3	f	\N	2011-11-22 17:26:24.694169	t	2011-11-25 14:16:54.794264
1	1551	155	162	\N	3	f	\N	2011-11-22 17:27:57.39527	f	\N
1	1553	1	1	\N	3	f	\N	2011-11-22 17:28:48.800143	t	2011-11-25 16:38:36.466774
1	1554	3	182	\N	3	f	\N	2011-11-22 17:29:49.28854	t	2011-11-23 15:11:35.469429
1	1565	1	101	\N	3	f	\N	2011-11-22 17:34:32.610534	f	\N
1	2299	130	32	\N	3	f	\N	2011-11-24 10:26:42.312126	t	2011-11-25 10:02:58.150151
1	1568	1	101	\N	3	f	\N	2011-11-22 17:35:38.426116	f	\N
1	1571	104	125	\N	3	f	\N	2011-11-22 17:37:31.140852	f	\N
1	1573	1	101	\N	3	f	\N	2011-11-22 17:38:56.991634	f	\N
1	1574	1	101	\N	3	f	\N	2011-11-22 17:40:17.83114	f	\N
1	1578	1	101	\N	3	f	\N	2011-11-22 17:50:29.349685	t	2011-11-25 16:39:15.489257
1	1579	3	101	\N	3	f	\N	2011-11-22 17:51:24.213959	f	\N
1	1582	1	101	\N	3	f	\N	2011-11-22 17:53:31.232559	f	\N
1	1583	1	101	\N	3	f	\N	2011-11-22 17:54:15.492578	f	\N
1	1584	3	182	\N	3	f	\N	2011-11-22 17:59:14.363162	t	2011-11-24 15:15:29.617088
1	1585	3	101	\N	3	f	\N	2011-11-22 18:00:39.400064	f	\N
1	1586	1	101	\N	3	f	\N	2011-11-22 18:05:06.311601	f	\N
1	1587	1	101	\N	3	f	\N	2011-11-22 18:08:32.517528	f	\N
1	1588	1	101	\N	3	f	\N	2011-11-22 18:15:50.876849	f	\N
1	1589	1	101	\N	3	f	\N	2011-11-22 18:17:22.787866	f	\N
1	1590	1	101	\N	3	f	\N	2011-11-22 18:20:13.327172	f	\N
1	1591	1	101	\N	3	f	\N	2011-11-22 18:21:56.035881	f	\N
1	1592	21	101	\N	3	f	\N	2011-11-22 18:22:11.388846	f	\N
1	1593	1	25	\N	3	f	\N	2011-11-22 18:24:16.252649	f	\N
1	1594	102	102	\N	3	f	\N	2011-11-22 18:36:47.118384	t	2011-11-24 10:14:07.193165
1	2014	1	1	\N	3	f	\N	2011-11-23 15:27:06.822192	t	2011-11-25 10:03:01.587145
1	2425	1	182	\N	3	f	\N	2011-11-24 15:42:47.764932	t	2011-11-24 15:43:00.351854
1	2437	1	182	\N	3	f	\N	2011-11-24 15:48:59.530682	t	2011-11-24 15:49:18.729913
1	1600	1	101	\N	3	f	\N	2011-11-22 19:08:00.05238	f	\N
1	1601	1	101	\N	3	f	\N	2011-11-22 19:09:18.13288	f	\N
1	1603	1	101	\N	3	f	\N	2011-11-22 19:10:30.644302	f	\N
1	1604	1	101	\N	3	f	\N	2011-11-22 19:11:59.245504	f	\N
1	1605	21	102	\N	3	f	\N	2011-11-22 19:18:15.958828	f	\N
1	1606	1	182	\N	3	f	\N	2011-11-22 19:32:36.753097	t	2011-11-24 14:46:39.035967
1	1607	102	102	\N	3	f	\N	2011-11-22 19:43:46.213526	f	\N
1	2454	1	101	\N	3	f	\N	2011-11-24 16:01:20.223761	t	2011-11-24 16:01:36.569584
1	1074	3	101	\N	3	f	\N	2011-11-20 09:08:16.025271	t	2011-11-24 16:40:25.776418
1	2468	1	101	\N	3	f	\N	2011-11-24 17:07:16.559766	t	2011-11-24 17:08:05.595189
1	2481	101	101	\N	3	f	\N	2011-11-24 18:40:26.633471	t	2011-11-25 09:20:40.546261
1	980	3	101	\N	3	f	\N	2011-11-17 16:05:51.390327	t	2011-11-24 19:12:56.98169
1	1614	1	182	\N	3	f	\N	2011-11-22 20:11:20.870165	f	\N
1	2497	105	101	\N	3	f	\N	2011-11-24 19:35:54.633128	f	\N
1	2528	101	101	\N	3	f	\N	2011-11-24 21:48:54.68301	t	2011-11-25 09:21:00.932655
1	1618	1	182	\N	3	f	\N	2011-11-22 20:19:24.277853	f	\N
1	1619	1	182	\N	3	f	\N	2011-11-22 20:19:31.369159	f	\N
1	1622	1	85	\N	3	f	\N	2011-11-22 20:27:06.66102	f	\N
1	1625	101	101	\N	3	f	\N	2011-11-22 20:32:15.287215	t	2011-11-25 09:12:23.923799
1	1627	1	101	\N	3	f	\N	2011-11-22 20:36:51.489825	t	2011-11-25 13:42:57.133898
1	1632	102	102	\N	3	f	\N	2011-11-22 20:43:36.368802	f	\N
1	1636	3	182	\N	3	f	\N	2011-11-22 20:48:08.815847	f	\N
1	2662	103	125	\N	3	f	\N	2011-11-26 14:45:22.66037	t	2011-11-26 14:45:56.458064
1	2226	130	146	\N	3	f	\N	2011-11-23 23:10:39.042929	f	\N
1	1427	105	101	\N	3	f	\N	2011-11-22 16:44:13.445563	t	2011-11-25 09:23:08.53207
1	1277	1	182	\N	3	f	\N	2011-11-22 09:53:57.750462	t	2011-11-25 09:43:49.256695
1	1648	3	101	\N	3	f	\N	2011-11-22 21:06:45.109576	f	\N
1	1652	155	162	\N	3	f	\N	2011-11-22 21:14:09.262829	f	\N
1	1653	72	101	\N	3	f	\N	2011-11-22 21:19:05.359444	f	\N
1	1430	90	101	\N	3	f	\N	2011-11-22 16:44:46.784216	t	2011-11-25 09:51:58.223773
1	1186	104	125	\N	3	f	\N	2011-11-21 22:43:46.856017	t	2011-11-25 09:55:13.417672
1	2235	1	182	\N	3	f	\N	2011-11-24 00:20:41.561077	t	2011-11-25 09:57:34.197822
1	2667	72	125	\N	3	f	\N	2011-11-26 15:10:41.108117	t	2011-11-26 15:11:02.795803
1	2673	1	101	\N	3	f	\N	2011-11-26 15:46:17.391827	t	2011-11-26 15:46:26.861787
1	2678	1	101	\N	3	f	\N	2011-11-26 15:51:59.068874	t	2011-11-26 16:02:53.845738
1	1654	3	101	\N	3	f	\N	2011-11-22 21:21:09.968279	f	\N
1	2561	1	146	\N	3	f	\N	2011-11-25 10:03:30.937518	t	2011-11-25 10:19:14.670723
1	1656	152	101	\N	3	f	\N	2011-11-22 21:28:27.071165	f	\N
1	1657	1	101	\N	3	f	\N	2011-11-22 21:29:42.428306	f	\N
1	2409	1	182	\N	3	f	\N	2011-11-24 14:54:44.850346	t	2011-11-24 14:55:02.722569
1	1659	1	101	\N	3	f	\N	2011-11-22 21:32:19.292232	f	\N
1	1660	1	101	\N	3	f	\N	2011-11-22 21:33:47.200591	f	\N
1	1661	1	101	\N	3	f	\N	2011-11-22 21:34:51.969928	f	\N
1	1726	3	182	\N	3	f	\N	2011-11-23 09:06:12.911991	t	2011-11-25 10:21:54.374056
1	475	2	182	\N	3	f	\N	2011-11-03 09:20:22.222941	t	2011-11-24 15:43:40.132775
1	1664	114	27	\N	3	f	\N	2011-11-22 21:40:15.782497	f	\N
1	2438	1	182	\N	3	f	\N	2011-11-24 15:49:07.0374	t	2011-11-24 15:49:19.590491
1	1674	104	125	\N	3	f	\N	2011-11-22 21:42:03.511139	f	\N
1	536	3	182	\N	3	f	\N	2011-11-04 09:00:13.883409	t	2011-11-25 10:22:31.173758
1	1682	1	101	\N	3	f	\N	2011-11-22 21:58:45.648612	f	\N
1	818	1	182	\N	3	f	\N	2011-11-14 22:13:39.930414	t	2011-11-24 16:03:37.622624
1	2463	3	101	\N	3	f	\N	2011-11-24 16:49:25.337102	t	2011-11-24 16:53:25.566706
1	1685	1	101	\N	3	f	\N	2011-11-22 22:04:50.909608	f	\N
1	1686	61	101	\N	3	f	\N	2011-11-22 22:06:14.99749	f	\N
1	539	3	182	\N	3	f	\N	2011-11-04 09:00:38.209587	t	2011-11-25 10:23:18.194703
1	1688	3	125	\N	3	f	\N	2011-11-22 22:20:13.567352	t	2011-11-26 10:26:07.680272
1	1689	155	162	\N	3	f	\N	2011-11-22 22:29:29.274145	f	\N
1	2470	1	34	\N	3	f	\N	2011-11-24 17:15:41.043393	t	2011-11-25 09:35:18.521789
1	1691	1	182	\N	3	f	\N	2011-11-22 22:35:49.969523	t	2011-11-24 09:06:47.280726
1	1692	155	162	\N	3	f	\N	2011-11-22 22:43:19.968256	f	\N
1	1693	102	102	\N	3	f	\N	2011-11-22 22:59:54.292844	f	\N
1	754	3	101	\N	3	f	\N	2011-11-11 17:46:48.241681	t	2011-11-24 18:44:14.476014
1	1695	114	27	\N	3	f	\N	2011-11-22 23:13:53.075953	f	\N
1	1696	1	182	\N	3	f	\N	2011-11-22 23:14:31.440356	f	\N
1	1697	1	101	\N	3	f	\N	2011-11-22 23:15:55.587523	f	\N
1	2208	1	101	\N	3	f	\N	2011-11-23 21:13:27.274317	f	\N
1	1699	143	166	\N	3	f	\N	2011-11-22 23:36:44.123218	f	\N
1	2492	3	101	\N	3	f	\N	2011-11-24 19:17:15.0595	f	\N
1	2498	105	101	\N	3	f	\N	2011-11-24 19:42:31.903512	t	2011-11-25 09:20:04.454442
1	2529	104	125	\N	3	f	\N	2011-11-24 21:59:26.180618	t	2011-11-25 09:55:40.028378
1	2635	1	182	\N	3	f	\N	2011-11-26 10:53:31.77019	t	2011-11-26 10:53:50.03027
1	1704	1	182	\N	3	f	\N	2011-11-22 23:49:12.591819	f	\N
1	1439	3	101	\N	3	f	\N	2011-11-22 16:46:23.405087	t	2011-11-25 09:23:23.046654
1	1706	1	182	\N	3	f	\N	2011-11-23 00:00:58.649783	f	\N
1	1707	3	101	\N	3	f	\N	2011-11-23 00:04:46.496182	t	2011-11-23 15:08:50.122194
1	2244	133	12	\N	3	f	\N	2011-11-24 08:29:11.210352	t	2011-11-25 09:32:18.964367
1	1710	3	182	\N	3	f	\N	2011-11-23 00:14:34.19277	t	2011-11-23 16:44:37.562969
1	1713	95	42	\N	3	f	\N	2011-11-23 00:47:42.425545	f	\N
1	316	1	182	\N	3	f	\N	2011-10-14 18:36:49.44144	f	\N
1	1714	1	1	\N	3	f	\N	2011-11-23 01:28:18.94273	f	\N
1	1715	3	101	\N	3	f	\N	2011-11-23 03:44:00.002141	f	\N
1	1718	103	125	\N	3	f	\N	2011-11-23 07:14:50.040133	t	2011-11-25 09:51:28.831716
1	1720	104	125	\N	3	f	\N	2011-11-23 08:13:12.09179	f	\N
1	1721	104	125	\N	3	f	\N	2011-11-23 08:17:12.709469	t	2011-11-25 09:56:15.691036
1	1259	1	182	\N	3	f	\N	2011-11-22 09:44:17.298903	t	2011-11-25 09:44:34.196585
1	1723	82	102	\N	3	f	\N	2011-11-23 08:57:30.571854	f	\N
1	2629	1	26	\N	3	f	\N	2011-11-26 09:51:48.507746	t	2011-11-26 09:51:59.942314
1	1728	96	42	\N	3	f	\N	2011-11-23 09:21:58.354479	t	2011-11-24 09:06:03.783547
1	1729	96	42	\N	3	f	\N	2011-11-23 09:22:11.221716	t	2011-11-24 09:04:17.065908
1	1730	96	42	\N	3	f	\N	2011-11-23 09:23:02.010134	t	2011-11-24 09:02:03.544636
1	1731	96	42	\N	3	f	\N	2011-11-23 09:24:44.680882	f	\N
1	1732	95	42	\N	3	f	\N	2011-11-23 09:25:22.712996	t	2011-11-24 09:01:45.7562
1	1733	96	42	\N	3	f	\N	2011-11-23 09:26:44.348426	t	2011-11-24 09:00:19.688579
1	1734	96	42	\N	3	f	\N	2011-11-23 09:26:45.986874	t	2011-11-24 09:01:06.653851
1	1736	95	42	\N	3	f	\N	2011-11-23 09:27:04.735763	t	2011-11-24 09:06:21.360925
1	1737	96	42	\N	3	f	\N	2011-11-23 09:27:24.850392	f	\N
1	1740	96	42	\N	3	f	\N	2011-11-23 09:29:29.243586	f	\N
1	1742	3	101	\N	3	f	\N	2011-11-23 09:29:39.375324	f	\N
1	1746	96	42	\N	3	f	\N	2011-11-23 09:30:05.913327	t	2011-11-24 09:05:28.000304
1	1747	96	42	\N	3	f	\N	2011-11-23 09:30:12.84264	t	2011-11-24 09:01:38.923634
1	1749	96	42	\N	3	f	\N	2011-11-23 09:31:10.668984	f	\N
1	1754	95	42	\N	3	f	\N	2011-11-23 09:31:27.453259	t	2011-11-24 09:01:08.017626
1	1757	96	42	\N	3	f	\N	2011-11-23 09:33:01.454877	t	2011-11-24 09:05:21.297442
1	1758	96	42	\N	3	f	\N	2011-11-23 09:33:11.421326	t	2011-11-24 09:05:32.262913
1	1759	95	42	\N	3	f	\N	2011-11-23 09:33:22.979263	t	2011-11-24 09:06:18.110404
1	1760	96	42	\N	3	f	\N	2011-11-23 09:33:23.554266	f	\N
1	1762	96	42	\N	3	f	\N	2011-11-23 09:34:28.063544	t	2011-11-24 09:02:25.210254
1	1764	95	42	\N	3	f	\N	2011-11-23 09:34:37.629603	t	2011-11-24 09:06:50.381999
1	1765	96	42	\N	3	f	\N	2011-11-23 09:35:06.838527	t	2011-11-24 09:02:50.271852
1	1769	96	42	\N	3	f	\N	2011-11-23 09:37:19.84899	t	2011-11-24 09:03:44.639769
1	1770	96	42	\N	3	f	\N	2011-11-23 09:37:23.718352	t	2011-11-24 09:04:45.191102
1	1771	96	42	\N	3	f	\N	2011-11-23 09:37:53.087227	f	\N
1	2220	3	101	\N	3	f	\N	2011-11-23 22:25:54.787909	t	2011-11-25 09:52:37.533972
1	1775	3	101	\N	3	f	\N	2011-11-23 09:56:57.51842	f	\N
1	1458	103	125	\N	3	f	\N	2011-11-22 16:53:59.961824	t	2011-11-25 09:55:22.80364
1	1777	1	1	\N	3	f	\N	2011-11-23 10:13:14.546483	f	\N
1	1779	1	182	\N	3	f	\N	2011-11-23 10:13:40.840448	f	\N
1	1786	96	42	\N	3	f	\N	2011-11-23 10:17:51.971651	t	2011-11-24 09:00:11.672592
1	1791	96	42	\N	3	f	\N	2011-11-23 10:22:32.924858	f	\N
1	1470	103	125	\N	3	f	\N	2011-11-22 17:01:16.0799	t	2011-11-25 09:57:39.879176
1	1795	82	102	\N	3	f	\N	2011-11-23 10:24:31.22203	f	\N
1	1796	1	182	\N	3	f	\N	2011-11-23 10:26:27.983766	f	\N
1	2225	81	146	\N	3	f	\N	2011-11-23 23:09:27.473952	t	2011-11-25 09:58:51.49434
1	1801	96	42	\N	3	f	\N	2011-11-23 10:29:09.66168	f	\N
1	1802	1	182	\N	3	f	\N	2011-11-23 10:29:39.325361	f	\N
1	1803	82	102	\N	3	f	\N	2011-11-23 10:29:42.154135	f	\N
1	1804	1	182	\N	3	f	\N	2011-11-23 10:29:46.077273	f	\N
1	1805	1	182	\N	3	f	\N	2011-11-23 10:29:56.44051	t	2011-11-25 09:41:37.270531
1	1806	1	182	\N	3	f	\N	2011-11-23 10:30:03.259018	f	\N
1	1808	1	182	\N	3	f	\N	2011-11-23 10:30:48.985032	f	\N
1	2254	130	32	\N	3	f	\N	2011-11-24 09:24:25.636383	t	2011-11-25 09:39:39.24186
1	1473	104	125	\N	3	f	\N	2011-11-22 17:02:48.101627	t	2011-11-25 10:00:07.547746
1	681	3	182	\N	3	f	\N	2011-11-10 12:00:40.767076	t	2011-11-25 10:00:56.417968
1	1502	104	125	\N	3	f	\N	2011-11-22 17:06:53.203439	t	2011-11-25 10:01:05.655233
1	2641	1	101	\N	3	f	\N	2011-11-26 12:20:29.563441	t	2011-11-26 12:20:48.537702
1	2646	1	64	\N	3	f	\N	2011-11-26 12:42:37.073924	t	2011-11-26 12:42:46.638585
1	2660	1	182	\N	3	f	\N	2011-11-26 14:24:31.455739	t	2011-11-26 14:24:40.764922
1	1812	1	23	\N	3	f	\N	2011-11-23 10:33:47.572727	f	\N
1	2664	1	101	\N	3	f	\N	2011-11-26 14:49:02.050652	t	2011-11-26 14:49:54.295837
1	1814	1	182	\N	3	f	\N	2011-11-23 10:36:12.088789	f	\N
1	1817	1	182	\N	3	f	\N	2011-11-23 10:36:31.280091	f	\N
1	2410	1	182	\N	3	f	\N	2011-11-24 14:55:27.081229	t	2011-11-24 14:55:37.021152
1	1842	132	155	\N	3	f	\N	2011-11-23 10:53:27.734751	f	\N
1	1843	132	155	\N	3	f	\N	2011-11-23 10:54:08.992643	f	\N
1	2209	1	32	\N	3	f	\N	2011-11-23 21:14:02.224414	t	2011-11-25 09:38:38.921086
1	1784	96	42	\N	3	f	\N	2011-11-23 10:16:24.79091	t	2011-11-24 09:03:47.542022
1	1860	96	42	\N	3	f	\N	2011-11-23 11:09:25.424972	t	2011-11-24 09:03:18.855925
1	2426	1	182	\N	3	f	\N	2011-11-24 15:44:00.2747	t	2011-11-24 15:44:10.493469
1	1871	1	182	\N	3	f	\N	2011-11-23 11:29:29.966021	f	\N
1	1872	67	101	\N	3	f	\N	2011-11-23 11:50:53.491654	f	\N
1	1873	1	32	\N	3	f	\N	2011-11-23 11:54:06.798942	f	\N
1	1874	1	182	\N	3	f	\N	2011-11-23 11:54:51.066702	f	\N
1	1875	41	32	\N	3	f	\N	2011-11-23 11:55:12.284905	t	2011-11-25 09:38:48.815677
1	1883	1	182	\N	3	f	\N	2011-11-23 12:04:31.964557	t	2011-11-25 09:37:28.546606
1	1890	3	101	\N	3	f	\N	2011-11-23 12:08:24.460406	f	\N
1	1891	133	12	\N	3	f	\N	2011-11-23 12:08:35.232151	t	2011-11-25 09:30:38.225908
1	1892	67	101	\N	3	f	\N	2011-11-23 12:33:28.990526	t	2011-11-24 14:59:22.122144
1	1893	1	182	\N	3	f	\N	2011-11-23 12:35:09.792802	f	\N
1	1894	3	101	\N	3	f	\N	2011-11-23 12:43:10.136503	f	\N
1	1897	3	101	\N	3	f	\N	2011-11-23 12:53:56.983311	f	\N
1	1898	1	1	\N	3	f	\N	2011-11-23 12:56:58.103421	f	\N
1	1901	3	101	\N	3	f	\N	2011-11-23 12:58:21.611056	f	\N
1	1902	1	182	\N	3	f	\N	2011-11-23 13:02:39.070312	t	2011-11-24 14:52:41.842483
1	1903	1	182	\N	3	f	\N	2011-11-23 13:03:47.079535	t	2011-11-24 14:53:21.129947
1	1904	1	182	\N	3	f	\N	2011-11-23 13:04:24.246099	t	2011-11-24 14:52:50.525754
1	1905	1	182	\N	3	f	\N	2011-11-23 13:04:29.077247	f	\N
1	1906	1	182	\N	3	f	\N	2011-11-23 13:04:51.778657	t	2011-11-24 14:51:59.863181
1	1907	71	101	\N	3	f	\N	2011-11-23 13:06:24.561291	f	\N
1	1908	1	125	\N	3	f	\N	2011-11-23 13:14:24.353174	f	\N
1	1909	41	42	\N	3	f	\N	2011-11-23 13:31:52.656916	t	2011-11-25 14:38:50.888826
1	2439	1	182	\N	3	f	\N	2011-11-24 15:50:00.589834	t	2011-11-24 15:50:09.525518
1	1910	1	101	\N	3	f	\N	2011-11-23 14:04:59.099455	f	\N
1	2630	1	101	\N	3	f	\N	2011-11-26 10:08:39.849125	t	2011-11-26 10:08:52.557461
1	1912	105	101	\N	3	f	\N	2011-11-23 14:26:43.076686	t	2011-11-25 09:27:46.996357
1	1913	101	101	\N	3	f	\N	2011-11-23 14:28:49.622807	f	\N
1	1915	101	101	\N	3	f	\N	2011-11-23 14:31:09.674261	t	2011-11-25 09:39:42.014288
1	1917	3	101	\N	3	f	\N	2011-11-23 14:34:46.235224	t	2011-11-25 09:31:52.847334
1	1918	1	182	\N	3	f	\N	2011-11-23 14:37:36.131171	f	\N
1	1919	101	101	\N	3	f	\N	2011-11-23 14:38:21.592297	f	\N
1	1920	101	101	\N	3	f	\N	2011-11-23 14:38:45.876927	t	2011-11-25 09:18:55.004172
1	1921	101	101	\N	3	f	\N	2011-11-23 14:39:54.669907	f	\N
1	1923	105	101	\N	3	f	\N	2011-11-23 14:40:10.504681	t	2011-11-25 09:15:05.491581
1	1924	21	101	\N	3	f	\N	2011-11-23 14:40:13.987459	f	\N
1	1926	101	101	\N	3	f	\N	2011-11-23 14:40:19.927737	t	2011-11-25 09:12:37.037544
1	1927	65	101	\N	3	f	\N	2011-11-23 14:43:23.239681	f	\N
1	1928	101	101	\N	3	f	\N	2011-11-23 14:44:02.090416	f	\N
1	1929	1	1	\N	3	f	\N	2011-11-23 14:44:04.486097	f	\N
1	1932	101	101	\N	3	f	\N	2011-11-23 14:47:20.262131	t	2011-11-25 09:18:02.735669
1	1933	101	101	\N	3	f	\N	2011-11-23 14:47:49.453196	t	2011-11-25 09:15:16.89841
1	1938	1	1	\N	3	f	\N	2011-11-23 14:49:13.933116	f	\N
1	1939	101	101	\N	3	f	\N	2011-11-23 14:50:06.0537	t	2011-11-25 09:22:23.02888
1	1940	101	101	\N	3	f	\N	2011-11-23 14:50:23.937024	f	\N
1	1942	101	101	\N	3	f	\N	2011-11-23 14:51:02.233675	t	2011-11-25 09:13:23.062782
1	1943	105	101	\N	3	f	\N	2011-11-23 14:51:14.917711	f	\N
1	1944	101	101	\N	3	f	\N	2011-11-23 14:52:01.472276	t	2011-11-25 09:16:27.456102
1	1953	101	101	\N	3	f	\N	2011-11-23 14:54:39.779299	t	2011-11-25 09:12:34.119099
1	2530	104	1	\N	3	f	\N	2011-11-24 22:02:13.412184	f	\N
1	1954	101	101	\N	3	f	\N	2011-11-23 14:55:28.737253	t	2011-11-25 09:16:48.733835
1	1958	105	101	\N	3	f	\N	2011-11-23 14:56:09.3649	t	2011-11-25 09:28:04.280666
1	1962	101	101	\N	3	f	\N	2011-11-23 14:56:52.53551	t	2011-11-25 09:24:43.648769
1	1963	101	101	\N	3	f	\N	2011-11-23 14:57:01.444649	t	2011-11-25 09:18:18.778841
1	2228	62	68	\N	3	f	\N	2011-11-23 23:35:01.483787	f	\N
1	1964	1	1	\N	3	f	\N	2011-11-23 15:00:41.335294	f	\N
1	1965	1	1	\N	3	f	\N	2011-11-23 15:02:19.047264	f	\N
1	1977	1	1	\N	3	f	\N	2011-11-23 15:03:15.439665	f	\N
1	1978	1	1	\N	3	f	\N	2011-11-23 15:04:09.3549	f	\N
1	684	3	182	\N	3	f	\N	2011-11-10 14:01:03.690978	t	2011-11-23 15:04:14.229951
1	1979	21	101	\N	3	f	\N	2011-11-23 15:04:58.366449	t	2011-11-23 15:07:13.582722
1	1009	3	101	\N	3	f	\N	2011-11-18 16:31:12.171281	t	2011-11-23 15:05:35.130754
1	1981	1	1	\N	3	f	\N	2011-11-23 15:06:00.956072	f	\N
1	1132	3	101	\N	3	f	\N	2011-11-21 15:04:35.236333	t	2011-11-23 15:06:37.472205
1	683	3	101	\N	3	f	\N	2011-11-10 13:56:58.597763	t	2011-11-23 15:06:32.222061
1	837	3	182	\N	3	f	\N	2011-11-15 17:08:30.07648	t	2011-11-23 15:06:42.537489
1	1985	1	1	\N	3	f	\N	2011-11-23 15:07:15.905394	f	\N
1	1986	3	101	\N	3	f	\N	2011-11-23 15:07:18.357356	t	2011-11-23 15:11:02.762529
1	1331	61	102	\N	3	f	\N	2011-11-22 11:05:49.115267	t	2011-11-23 15:07:44.660602
1	993	3	182	\N	3	f	\N	2011-11-18 09:18:26.10386	t	2011-11-23 15:08:13.703609
1	1097	3	182	\N	3	f	\N	2011-11-21 09:15:53.279655	t	2011-11-23 15:08:17.744136
1	417	3	182	\N	3	f	\N	2011-10-23 19:32:57.944197	t	2011-11-23 15:08:48.182926
1	1099	3	182	\N	3	f	\N	2011-11-21 10:08:19.67001	t	2011-11-23 15:08:51.911897
1	1992	101	101	\N	3	f	\N	2011-11-23 15:10:05.474259	f	\N
1	634	3	182	\N	3	f	\N	2011-11-08 20:21:52.105949	t	2011-11-23 15:10:06.899924
1	1792	3	182	\N	3	f	\N	2011-11-23 10:22:42.943524	t	2011-11-23 15:11:26.252949
1	1993	3	182	\N	3	f	\N	2011-11-23 15:11:28.628109	t	2011-11-23 15:12:57.721451
1	442	3	182	\N	3	f	\N	2011-10-28 22:54:32.001839	t	2011-11-23 15:11:55.053985
1	1018	3	182	\N	3	f	\N	2011-11-18 18:53:50.91309	t	2011-11-23 15:12:07.345966
1	1121	3	101	\N	3	f	\N	2011-11-21 12:23:24.681451	t	2011-11-23 15:13:01.443058
1	1124	3	101	\N	3	f	\N	2011-11-21 12:59:39.111531	t	2011-11-23 15:14:16.81958
1	2245	3	182	\N	3	f	\N	2011-11-24 08:47:07.217937	f	\N
1	2255	130	32	\N	3	f	\N	2011-11-24 09:29:28.411384	t	2011-11-25 09:39:11.708395
1	2264	1	182	\N	3	f	\N	2011-11-24 10:01:13.445199	t	2011-11-24 10:01:39.127058
1	2545	1	182	\N	3	f	\N	2011-11-25 09:31:17.001653	t	2011-11-25 09:31:32.090325
1	2642	61	101	\N	3	f	\N	2011-11-26 12:21:23.178398	t	2011-11-26 12:21:39.375556
1	1756	61	150	\N	3	f	\N	2011-11-23 09:31:59.405008	t	2011-11-26 14:20:11.782817
1	625	3	101	\N	3	f	\N	2011-11-08 14:47:33.538477	t	2011-11-23 15:14:28.311572
1	1996	1	1	\N	3	f	\N	2011-11-23 15:15:12.236187	f	\N
1	1059	3	125	\N	3	f	\N	2011-11-19 17:30:45.300108	t	2011-11-23 15:15:39.4067
1	758	3	182	\N	3	f	\N	2011-11-11 19:02:21.616989	t	2011-11-23 15:15:49.415058
1	640	3	101	\N	3	f	\N	2011-11-08 23:09:43.816554	t	2011-11-23 15:15:53.958242
1	1026	3	182	\N	3	f	\N	2011-11-18 19:53:42.749773	t	2011-11-23 15:16:10.928123
1	1845	3	101	\N	3	f	\N	2011-11-23 10:56:02.803452	t	2011-11-23 15:16:33.939834
1	2001	1	1	\N	3	f	\N	2011-11-23 15:16:57.752137	f	\N
1	2003	3	101	\N	3	f	\N	2011-11-23 15:17:14.476652	t	2011-11-23 15:18:32.227106
1	2668	61	101	\N	3	f	\N	2011-11-26 15:14:26.295856	t	2011-11-26 15:15:06.553532
1	2674	1	101	\N	3	f	\N	2011-11-26 15:46:45.341772	t	2011-11-26 16:05:25.573334
1	1446	3	182	\N	3	f	\N	2011-11-22 16:49:03.140358	t	2011-11-23 15:18:32.528897
1	2005	41	32	\N	3	f	\N	2011-11-23 15:19:01.256098	f	\N
1	1120	75	125	\N	3	f	\N	2011-11-21 12:02:15.09179	t	2011-11-26 16:01:12.156
1	685	3	101	\N	3	f	\N	2011-11-10 14:06:24.605524	t	2011-11-23 15:19:47.240562
1	1735	96	42	\N	3	f	\N	2011-11-23 09:26:47.715488	t	2011-11-24 09:04:12.212304
1	409	3	182	\N	3	f	\N	2011-10-20 21:02:03.415854	t	2011-11-23 15:21:17.142787
1	2009	1	1	\N	3	f	\N	2011-11-23 15:23:38.236701	f	\N
1	2010	1	1	\N	3	f	\N	2011-11-23 15:23:57.577371	f	\N
1	631	3	101	\N	3	f	\N	2011-11-08 18:53:20.945709	t	2011-11-23 15:24:28.791228
1	405	3	101	\N	3	f	\N	2011-10-20 18:35:46.765204	t	2011-11-23 15:24:49.512142
1	795	3	101	\N	3	f	\N	2011-11-13 14:08:34.778389	t	2011-11-23 15:25:46.608366
1	1056	3	101	\N	3	f	\N	2011-11-19 14:40:55.374896	f	\N
1	2631	1	101	\N	3	f	\N	2011-11-26 10:12:06.717735	t	2011-11-26 10:12:17.460675
1	1053	3	101	\N	3	f	\N	2011-11-19 14:38:02.751172	t	2011-11-23 15:27:52.314068
1	2016	101	101	\N	3	f	\N	2011-11-23 15:28:34.433332	t	2011-11-25 09:17:31.031786
1	2643	1	101	\N	3	f	\N	2011-11-26 12:28:26.225026	t	2011-11-26 12:28:38.782793
1	2022	1	1	\N	3	f	\N	2011-11-23 15:30:55.096976	t	2011-11-25 09:38:44.279183
1	934	3	42	\N	3	f	\N	2011-11-16 18:12:22.936075	t	2011-11-23 15:32:51.405319
1	2411	1	182	\N	3	f	\N	2011-11-24 14:57:11.078101	t	2011-11-24 14:57:29.766586
1	1008	3	101	\N	3	f	\N	2011-11-18 16:24:28.409358	t	2011-11-23 15:35:06.194291
1	636	3	182	\N	3	f	\N	2011-11-08 21:17:43.16446	t	2011-11-23 15:35:41.197184
1	2027	1	101	\N	3	f	\N	2011-11-23 15:36:01.035767	f	\N
1	2029	21	101	\N	3	f	\N	2011-11-23 15:40:28.751105	t	2011-11-23 16:57:39.364215
1	809	3	101	\N	3	f	\N	2011-11-14 16:30:35.477413	t	2011-11-23 15:40:39.973949
1	2427	1	182	\N	3	f	\N	2011-11-24 15:45:16.14438	t	2011-11-24 15:45:24.210238
1	673	3	125	\N	3	f	\N	2011-11-09 20:52:12.802505	t	2011-11-23 15:43:52.211552
1	2229	1	182	\N	3	f	\N	2011-11-23 23:35:59.366595	t	2011-11-24 09:12:47.673191
1	774	3	101	\N	3	f	\N	2011-11-12 13:17:27.947032	t	2011-11-23 15:44:30.746242
1	1090	3	101	\N	3	f	\N	2011-11-20 21:12:16.04893	t	2011-11-23 15:45:21.507661
1	2031	1	32	\N	3	f	\N	2011-11-23 15:48:32.686378	t	2011-11-25 09:40:26.485616
1	2032	1	32	\N	3	f	\N	2011-11-23 15:51:43.137916	t	2011-11-25 09:40:49.371731
1	973	3	101	\N	3	f	\N	2011-11-17 12:26:21.367156	t	2011-11-23 15:51:44.63273
1	992	3	182	\N	3	f	\N	2011-11-18 00:37:31.893925	t	2011-11-23 15:57:02.520267
1	2033	132	155	\N	3	f	\N	2011-11-23 15:58:34.226154	f	\N
1	2440	1	182	\N	3	f	\N	2011-11-24 15:50:00.948817	t	2011-11-24 15:50:22.853388
1	2038	1	101	\N	3	f	\N	2011-11-23 16:12:27.058326	f	\N
1	1402	3	101	\N	3	f	\N	2011-11-22 15:23:59.550868	t	2011-11-23 16:12:53.378265
1	2039	1	182	\N	3	f	\N	2011-11-23 16:14:10.077301	f	\N
1	940	62	101	\N	3	f	\N	2011-11-16 21:44:43.224635	t	2011-11-24 14:27:38.44643
1	937	3	182	\N	3	f	\N	2011-11-16 20:59:50.417532	t	2011-11-23 16:17:09.347892
1	982	1	182	\N	3	f	\N	2011-11-17 18:27:49.257987	t	2011-11-24 16:04:37.933589
1	425	3	101	\N	3	f	\N	2011-10-24 14:57:56.38271	t	2011-11-23 16:21:43.664706
1	1084	1	182	\N	3	f	\N	2011-11-20 18:18:52.453047	t	2011-11-24 16:11:19.472099
1	2246	22	101	\N	3	f	\N	2011-11-24 08:48:15.791297	t	2011-11-24 08:48:26.798048
1	935	1	182	\N	3	f	\N	2011-11-16 19:14:55.867871	t	2011-11-24 16:12:05.986436
1	1168	84	182	\N	3	f	\N	2011-11-21 20:08:30.865892	t	2011-11-23 16:27:42.264856
1	472	3	182	\N	3	f	\N	2011-11-02 20:24:46.441408	t	2011-11-23 16:27:56.645267
1	1167	3	182	\N	3	f	\N	2011-11-21 20:05:35.163636	t	2011-11-23 16:28:00.591112
1	2048	131	32	\N	3	f	\N	2011-11-23 16:28:49.676231	f	\N
1	1395	3	182	\N	3	f	\N	2011-11-22 14:33:28.719124	t	2011-11-23 16:34:21.036108
1	2054	3	182	\N	3	f	\N	2011-11-23 16:34:54.770303	t	2011-11-23 16:48:50.564441
1	2055	1	182	\N	3	f	\N	2011-11-23 16:35:49.39486	t	2011-11-24 14:23:46.076733
1	2057	131	32	\N	3	f	\N	2011-11-23 16:42:23.970947	f	\N
1	1698	61	101	\N	3	f	\N	2011-11-22 23:28:11.921403	t	2011-11-23 16:49:44.490298
1	1379	21	101	\N	3	f	\N	2011-11-22 14:07:53.803911	t	2011-11-23 16:51:29.272564
1	2546	1	12	\N	3	f	\N	2011-11-25 09:34:21.352643	t	2011-11-25 09:34:42.109224
1	1151	3	1	\N	3	f	\N	2011-11-21 17:42:01.123853	t	2011-11-23 16:53:25.365429
1	2062	1	101	\N	3	f	\N	2011-11-23 16:55:38.190952	f	\N
1	692	2	101	\N	3	f	\N	2011-11-10 17:36:38.192231	t	2011-11-23 16:57:11.594987
1	2064	1	182	\N	3	f	\N	2011-11-23 16:59:41.784191	t	2011-11-23 17:00:00.150976
1	2065	1	1	\N	3	f	\N	2011-11-23 16:59:42.946549	t	2011-11-23 17:00:21.88692
1	467	3	182	\N	3	f	\N	2011-11-02 17:34:21.592705	t	2011-11-23 16:59:55.017682
1	2066	1	101	\N	3	f	\N	2011-11-23 16:59:55.339651	f	\N
1	1021	3	101	\N	3	f	\N	2011-11-18 19:16:39.788809	t	2011-11-23 17:00:58.574351
1	306	3	101	\N	3	f	\N	2011-10-14 14:29:01.405895	t	2011-11-23 17:01:02.349034
1	297	3	101	51	3	f	\N	2011-10-13 16:54:56.049301	t	2011-11-23 17:01:08.284521
1	304	3	101	\N	3	f	\N	2011-10-14 13:28:50.541718	t	2011-11-23 17:01:16.836805
1	326	21	101	\N	3	f	\N	2011-10-15 09:54:25.937655	t	2011-11-23 17:02:04.863395
1	696	3	102	\N	3	f	\N	2011-11-10 20:21:42.393681	t	2011-11-23 17:02:10.86505
1	1708	1	101	\N	3	f	\N	2011-11-23 00:06:49.765183	t	2011-11-23 17:03:27.709344
1	1709	62	101	\N	3	f	\N	2011-11-23 00:12:40.410882	t	2011-11-23 17:03:51.443747
1	2067	73	101	\N	3	f	\N	2011-11-23 17:03:58.529414	f	\N
1	2068	1	182	\N	3	f	\N	2011-11-23 17:04:26.416085	t	2011-11-24 14:51:16.848823
1	2256	1	101	\N	3	f	\N	2011-11-24 09:31:56.894934	t	2011-11-24 09:32:41.964747
1	2265	21	101	\N	3	f	\N	2011-11-24 10:02:05.423593	t	2011-11-25 18:48:42.07578
1	1613	82	102	\N	3	f	\N	2011-11-22 20:10:59.33615	t	2011-11-24 10:14:17.32416
1	1599	102	102	\N	3	f	\N	2011-11-22 18:57:14.420231	t	2011-11-24 10:15:18.799944
1	1616	1	182	\N	3	f	\N	2011-11-22 20:14:50.756539	t	2011-11-24 10:16:08.507857
1	1641	102	102	\N	3	f	\N	2011-11-22 20:53:36.907151	t	2011-11-24 10:16:23.383066
1	598	2	182	\N	3	f	\N	2011-11-07 21:42:55.271328	t	2011-11-24 10:18:28.926084
1	540	1	182	\N	3	f	\N	2011-11-04 09:00:38.897489	t	2011-11-24 10:18:59.997578
1	1608	102	102	\N	3	f	\N	2011-11-22 19:49:52.703224	t	2011-11-24 10:19:10.307701
1	2551	1	148	\N	3	f	\N	2011-11-25 09:44:46.972735	t	2011-11-25 09:45:03.367889
1	1433	104	125	\N	3	f	\N	2011-11-22 16:45:18.362992	t	2011-11-25 09:52:50.827241
1	1189	104	125	\N	3	f	\N	2011-11-21 22:54:55.828443	t	2011-11-25 09:55:30.299235
1	2652	1	101	\N	3	f	\N	2011-11-26 14:21:28.801303	t	2011-11-26 14:22:01.061628
1	2069	3	101	\N	3	f	\N	2011-11-23 17:04:42.861479	f	\N
1	1196	3	101	\N	3	f	\N	2011-11-21 23:33:01.856965	t	2011-11-23 17:04:53.539042
1	1063	3	182	\N	3	f	\N	2011-11-19 19:13:45.190375	t	2011-11-23 17:06:02.595599
1	2070	135	26	\N	3	f	\N	2011-11-23 17:08:37.123439	t	2011-11-26 09:45:33.831199
1	2680	1	125	\N	3	f	\N	2011-11-26 16:05:41.8609	t	2011-11-26 16:06:33.230758
1	813	3	101	\N	3	f	\N	2011-11-14 19:43:55.090935	t	2011-11-23 17:13:03.84724
1	2072	1	1	\N	3	f	\N	2011-11-23 17:13:12.546398	t	2011-11-26 09:52:40.572291
1	1183	3	101	\N	3	f	\N	2011-11-21 22:39:31.400605	t	2011-11-23 17:14:35.194319
1	2075	135	26	\N	3	f	\N	2011-11-23 17:16:19.364445	f	\N
1	2077	1	182	\N	3	f	\N	2011-11-23 17:16:53.786814	f	\N
1	1602	1	101	\N	3	f	\N	2011-11-22 19:09:45.980141	t	2011-11-23 17:17:16.142065
1	2078	1	101	\N	3	f	\N	2011-11-23 17:17:37.549051	f	\N
1	2079	1	182	\N	3	f	\N	2011-11-23 17:18:43.801284	f	\N
1	2080	1	182	\N	3	f	\N	2011-11-23 17:23:15.550717	t	2011-11-24 15:01:39.305208
1	2081	1	182	\N	3	f	\N	2011-11-23 17:23:15.974606	t	2011-11-24 14:51:25.919081
1	2084	1	182	\N	3	f	\N	2011-11-23 17:27:37.584888	t	2011-11-24 14:46:23.829798
1	2045	3	182	\N	3	f	\N	2011-11-23 16:26:38.120309	t	2011-11-23 17:32:32.550319
1	2091	138	124	\N	3	f	\N	2011-11-23 17:32:34.705996	f	\N
1	453	3	101	\N	3	f	\N	2011-10-31 17:42:21.662343	t	2011-11-23 17:33:52.641574
1	533	3	101	\N	3	f	\N	2011-11-03 23:32:22.421281	t	2011-11-23 17:34:17.545899
1	1010	3	101	\N	3	f	\N	2011-11-18 16:33:14.029471	t	2011-11-23 17:34:29.000381
1	2093	101	101	\N	3	f	\N	2011-11-23 17:35:55.106313	t	2011-11-25 09:18:57.882056
1	2096	101	101	\N	3	f	\N	2011-11-23 17:39:14.895811	f	\N
1	2198	82	102	\N	3	f	\N	2011-11-23 20:30:07.973514	t	2011-11-26 16:30:54.692288
1	1194	3	182	\N	3	f	\N	2011-11-21 23:19:48.75085	t	2011-11-23 17:45:31.954178
1	2117	1	182	\N	3	f	\N	2011-11-23 17:54:42.135732	f	\N
1	2118	1	182	\N	3	f	\N	2011-11-23 17:55:04.231277	t	2011-11-24 14:49:15.23545
1	2119	1	182	\N	3	f	\N	2011-11-23 17:57:30.719519	f	\N
1	2120	1	182	\N	3	f	\N	2011-11-23 17:59:21.726464	f	\N
1	2121	101	101	\N	3	f	\N	2011-11-23 17:59:41.249198	t	2011-11-25 09:13:02.621738
1	2122	101	101	\N	3	f	\N	2011-11-23 18:00:03.083013	t	2011-11-25 09:15:49.094463
1	2123	1	182	\N	3	f	\N	2011-11-23 18:00:32.598692	f	\N
1	563	3	182	\N	3	f	\N	2011-11-04 09:10:44.806262	t	2011-11-25 10:23:08.29271
1	2127	101	102	\N	3	f	\N	2011-11-23 18:02:10.024237	t	2011-11-25 09:15:26.384848
1	2130	1	32	\N	3	f	\N	2011-11-23 18:02:40.458196	t	2011-11-25 09:40:22.803706
1	2131	1	182	\N	3	f	\N	2011-11-23 18:03:34.607902	t	2011-11-24 14:49:44.645468
1	2132	1	32	\N	3	f	\N	2011-11-23 18:03:47.868903	t	2011-11-25 09:39:59.227321
1	2135	1	182	\N	3	f	\N	2011-11-23 18:06:35.472896	f	\N
1	2682	1	101	\N	3	f	\N	2011-11-26 16:33:08.617909	t	2011-11-26 16:34:30.200952
1	311	3	68	\N	3	f	\N	2011-10-14 16:03:17.96049	t	2011-11-23 18:09:06.015128
1	2212	101	101	\N	3	f	\N	2011-11-23 21:24:25.341316	t	2011-11-25 09:20:02.390704
1	2684	1	101	\N	3	f	\N	2011-11-26 17:38:43.938499	t	2011-11-26 17:40:48.488752
1	2413	41	182	\N	3	f	\N	2011-11-24 15:00:09.781507	t	2011-11-24 15:00:28.500225
1	564	3	182	\N	3	f	\N	2011-11-04 09:12:13.389433	t	2011-11-25 10:23:56.26082
1	575	3	182	\N	3	f	\N	2011-11-04 09:20:22.006498	t	2011-11-25 10:24:40.265416
1	2428	1	182	\N	3	f	\N	2011-11-24 15:45:29.62865	t	2011-11-24 15:45:51.548184
1	2441	1	182	\N	3	f	\N	2011-11-24 15:50:21.855054	t	2011-11-24 15:50:48.523528
1	473	3	182	\N	3	f	\N	2011-11-03 02:01:12.328606	t	2011-11-24 16:04:39.524793
1	2464	3	101	\N	3	f	\N	2011-11-24 16:50:00.134301	t	2011-11-26 12:21:51.239922
1	2471	1	182	\N	3	f	\N	2011-11-24 17:56:52.34653	t	2011-11-24 17:57:13.911155
1	2487	101	101	\N	3	f	\N	2011-11-24 18:50:08.24816	t	2011-11-25 09:16:39.320651
1	2501	3	101	\N	3	f	\N	2011-11-24 19:44:04.730083	f	\N
1	2532	3	101	\N	3	f	\N	2011-11-24 22:07:22.91746	f	\N
1	2161	1	101	\N	3	f	\N	2011-11-23 18:49:07.695111	t	2011-11-23 18:49:59.543417
1	2162	3	101	\N	3	f	\N	2011-11-23 18:57:56.767793	t	2011-11-24 09:23:25.375497
1	998	3	101	\N	3	f	\N	2011-11-18 12:08:46.954662	t	2011-11-23 19:00:44.455624
1	2163	101	101	\N	3	f	\N	2011-11-23 19:06:56.462908	t	2011-11-25 09:23:26.034148
1	2166	101	101	\N	3	f	\N	2011-11-23 19:08:37.730454	f	\N
1	2168	101	101	\N	3	f	\N	2011-11-23 19:12:51.194762	t	2011-11-25 09:16:13.291197
1	2169	101	101	\N	3	f	\N	2011-11-23 19:14:33.987533	t	2011-11-25 09:19:41.991724
1	2170	101	101	\N	3	f	\N	2011-11-23 19:30:03.903928	t	2011-11-25 09:21:50.772075
1	2177	3	101	\N	3	f	\N	2011-11-23 19:38:58.680715	f	\N
1	2179	1	101	\N	3	f	\N	2011-11-23 19:41:30.506366	t	2011-11-23 19:41:52.317096
1	2181	105	101	\N	3	f	\N	2011-11-23 19:44:15.28425	f	\N
1	2182	41	182	\N	3	f	\N	2011-11-23 19:44:38.531285	t	2011-11-26 09:29:21.433572
1	2183	191	182	\N	3	f	\N	2011-11-23 19:46:49.885258	t	2011-11-26 09:29:54.028187
1	2186	3	101	\N	3	f	\N	2011-11-23 19:56:36.599989	t	2011-11-23 19:57:03.146466
1	2187	101	101	\N	3	f	\N	2011-11-23 20:04:05.339751	f	\N
1	2188	101	101	\N	3	f	\N	2011-11-23 20:06:38.389152	t	2011-11-25 09:15:04.49007
1	2189	1	101	\N	3	f	\N	2011-11-23 20:08:31.333864	t	2011-11-25 09:40:17.923051
1	2190	1	1	\N	3	f	\N	2011-11-23 20:11:40.260658	f	\N
1	2191	1	148	\N	3	f	\N	2011-11-23 20:13:19.147505	t	2011-11-25 09:46:01.278451
1	2193	101	101	\N	3	f	\N	2011-11-23 20:13:47.940877	t	2011-11-25 09:17:56.30946
1	2195	3	101	\N	3	f	\N	2011-11-23 20:15:59.159143	f	\N
1	2196	41	32	\N	3	f	\N	2011-11-23 20:16:24.82429	t	2011-11-25 09:46:34.695264
1	2230	1	32	\N	3	f	\N	2011-11-23 23:39:20.255497	t	2011-11-25 09:45:56.535102
1	2247	21	101	\N	3	f	\N	2011-11-24 08:53:08.218302	t	2011-11-24 08:54:43.699274
1	2257	1	101	\N	3	f	\N	2011-11-24 09:33:01.659179	t	2011-11-24 09:33:12.672329
1	1416	3	182	\N	3	f	\N	2011-11-22 16:39:41.224935	t	2011-11-24 10:03:13.440497
1	1828	1	182	\N	3	f	\N	2011-11-23 10:39:39.331447	t	2011-11-24 10:14:25.284805
1	1597	102	102	\N	3	f	\N	2011-11-22 18:50:02.472046	t	2011-11-24 10:15:21.732641
1	755	194	182	\N	3	f	\N	2011-11-11 18:42:21.736785	t	2011-11-24 10:18:39.36583
1	2222	1	32	\N	3	f	\N	2011-11-23 22:40:10.268597	t	2011-11-25 09:57:01.272859
1	1821	82	102	\N	3	f	\N	2011-11-23 10:37:11.03588	t	2011-11-24 10:19:14.26319
1	793	194	182	\N	3	f	\N	2011-11-13 11:36:35.813673	t	2011-11-24 10:19:27.254355
1	2294	1	182	\N	3	f	\N	2011-11-24 10:19:34.675777	t	2011-11-24 10:19:54.351846
1	854	194	182	\N	3	f	\N	2011-11-16 10:30:41.344781	t	2011-11-24 10:20:30.340981
1	2227	1	182	\N	3	f	\N	2011-11-23 23:16:30.821263	t	2011-11-24 10:20:44.196197
1	1621	102	102	\N	3	f	\N	2011-11-22 20:21:03.675198	t	2011-11-24 10:21:07.469562
1	1694	114	27	\N	3	f	\N	2011-11-22 23:01:09.594887	t	2011-11-24 10:21:10.038393
1	1811	82	102	\N	3	f	\N	2011-11-23 10:33:17.721327	t	2011-11-24 10:21:36.897925
1	2547	1	12	\N	3	f	\N	2011-11-25 09:34:50.401297	t	2011-11-25 09:35:01.024094
1	2552	1	182	\N	3	f	\N	2011-11-25 09:45:27.283623	t	2011-11-25 09:45:37.908519
1	2221	61	101	\N	3	f	\N	2011-11-23 22:28:39.459564	t	2011-11-25 09:53:12.402885
1	1188	104	125	\N	3	f	\N	2011-11-21 22:52:39.723865	t	2011-11-25 09:55:53.579733
1	2632	1	101	\N	3	f	\N	2011-11-26 10:51:40.796319	t	2011-11-26 10:51:52.784015
1	2295	1	182	\N	3	f	\N	2011-11-24 10:21:54.592849	t	2011-11-24 10:33:19.271139
1	1658	82	102	\N	3	f	\N	2011-11-22 21:30:59.509909	t	2011-11-24 10:22:07.510057
1	1799	82	102	\N	3	f	\N	2011-11-23 10:27:37.329682	t	2011-11-24 10:22:22.500988
1	1813	82	102	\N	3	f	\N	2011-11-23 10:35:13.257286	t	2011-11-24 10:22:53.241272
1	2296	1	182	\N	3	f	\N	2011-11-24 10:22:54.487449	f	\N
1	2297	82	102	\N	3	f	\N	2011-11-24 10:23:00.240559	t	2011-11-24 10:24:30.693841
1	1651	114	27	\N	3	f	\N	2011-11-22 21:13:30.004656	t	2011-11-24 10:23:37.609913
1	1684	114	27	\N	3	f	\N	2011-11-22 22:03:22.356131	t	2011-11-24 10:24:20.143362
1	535	3	182	\N	3	f	\N	2011-11-04 09:00:10.119176	t	2011-11-25 10:24:42.597818
1	319	3	101	\N	3	f	\N	2011-10-14 20:15:33.255429	t	2011-11-24 10:24:50.83663
1	1639	114	27	\N	3	f	\N	2011-11-22 20:50:09.835564	t	2011-11-24 10:25:24.37624
1	1877	41	32	\N	3	f	\N	2011-11-23 11:59:30.892871	t	2011-11-24 10:25:53.834053
1	2298	1	182	\N	3	f	\N	2011-11-24 10:26:00.362068	t	2011-11-24 10:26:10.623297
1	1711	114	27	\N	3	f	\N	2011-11-23 00:15:16.719884	t	2011-11-24 10:26:02.133798
1	2167	114	27	\N	3	f	\N	2011-11-23 19:11:26.347895	t	2011-11-24 10:26:07.456498
1	538	3	182	\N	3	f	\N	2011-11-04 09:00:28.544607	t	2011-11-25 10:25:37.264456
1	367	1	32	\N	3	f	\N	2011-10-17 20:21:07.477447	t	2011-11-24 10:26:11.887009
1	1598	114	27	\N	3	f	\N	2011-11-22 18:53:34.797529	t	2011-11-24 10:26:20.156458
1	386	1	32	\N	3	f	\N	2011-10-18 20:14:09.458258	t	2011-11-24 10:26:32.767177
1	816	3	182	\N	3	f	\N	2011-11-14 20:53:51.719247	t	2011-11-25 10:27:06.578449
1	1615	1	32	\N	3	f	\N	2011-11-22 20:13:48.988325	t	2011-11-24 10:26:46.444733
1	1671	114	27	\N	3	f	\N	2011-11-22 21:41:18.298224	t	2011-11-24 10:27:08.208008
1	342	1	32	\N	3	f	\N	2011-10-17 12:56:07.807314	t	2011-11-24 10:27:10.779199
1	2028	191	182	\N	3	f	\N	2011-11-23 15:39:48.26179	t	2011-11-24 10:27:11.543378
1	1861	114	27	\N	3	f	\N	2011-11-23 11:23:54.852561	t	2011-11-24 10:27:12.660306
1	1633	1	32	\N	3	f	\N	2011-11-22 20:45:14.800684	t	2011-11-24 10:27:19.639449
1	2207	114	27	\N	3	f	\N	2011-11-23 21:11:04.555238	t	2011-11-24 10:27:58.015808
1	2006	114	27	\N	3	f	\N	2011-11-23 15:19:21.041368	t	2011-11-24 10:28:13.316842
1	2061	114	27	\N	3	f	\N	2011-11-23 16:52:41.370242	t	2011-11-24 10:28:27.325692
1	2211	114	27	\N	3	f	\N	2011-11-23 21:18:59.832639	t	2011-11-24 10:28:28.421893
1	2224	114	1	\N	3	f	\N	2011-11-23 23:06:10.794029	t	2011-11-24 10:28:39.702078
1	2300	1	182	\N	3	f	\N	2011-11-24 10:29:05.615537	t	2011-11-24 10:46:04.027999
1	1033	3	42	\N	3	f	\N	2011-11-18 21:11:28.382424	t	2011-11-24 10:29:11.645124
1	1683	114	27	\N	3	f	\N	2011-11-22 21:59:16.071762	t	2011-11-24 10:29:33.39506
1	2397	21	101	\N	3	f	\N	2011-11-24 13:08:49.228511	f	\N
1	1662	114	27	\N	3	f	\N	2011-11-22 21:35:18.600527	t	2011-11-24 10:30:28.550627
1	1727	114	27	\N	3	f	\N	2011-11-23 09:11:16.455158	t	2011-11-24 10:30:56.317033
1	1914	114	27	\N	3	f	\N	2011-11-23 14:29:10.554644	t	2011-11-24 10:31:46.194631
1	2283	1	182	\N	3	f	\N	2011-11-24 10:13:53.082276	t	2011-11-24 10:31:50.407925
1	1722	102	102	\N	3	f	\N	2011-11-23 08:40:10.594814	t	2011-11-24 10:32:00.385553
1	2287	1	182	\N	3	f	\N	2011-11-24 10:14:28.88783	t	2011-11-24 10:32:20.981433
1	2302	130	32	\N	3	f	\N	2011-11-24 10:32:47.916927	f	\N
1	2288	1	182	\N	3	f	\N	2011-11-24 10:15:14.975371	t	2011-11-24 10:33:01.32255
1	2540	1	182	\N	3	f	\N	2011-11-25 07:35:06.220039	t	2011-11-25 10:27:26.241678
1	2290	191	182	\N	3	f	\N	2011-11-24 10:16:00.395797	t	2011-11-24 10:33:50.792498
1	2284	191	42	\N	3	f	\N	2011-11-24 10:13:55.42899	t	2011-11-24 10:34:02.889117
1	2303	1	101	\N	3	f	\N	2011-11-24 10:34:14.417824	t	2011-11-24 10:34:30.708869
1	2280	191	182	\N	3	f	\N	2011-11-24 10:12:29.266255	t	2011-11-24 10:34:21.065674
1	2275	191	69	\N	3	f	\N	2011-11-24 10:11:15.492344	t	2011-11-24 10:34:27.754584
1	2277	1	182	\N	3	f	\N	2011-11-24 10:11:57.978345	t	2011-11-24 10:34:40.726718
1	1595	191	42	\N	3	f	\N	2011-11-22 18:43:42.246824	t	2011-11-24 10:34:44.321869
1	2293	1	182	\N	3	f	\N	2011-11-24 10:16:26.904827	t	2011-11-24 10:34:54.938
1	2270	1	182	\N	3	f	\N	2011-11-24 10:09:38.198587	t	2011-11-24 10:35:00.081369
1	2278	1	182	\N	3	f	\N	2011-11-24 10:12:07.860431	t	2011-11-24 10:35:15.058886
1	2281	1	182	\N	3	f	\N	2011-11-24 10:12:56.647524	t	2011-11-24 10:35:31.858345
1	2269	191	182	\N	3	f	\N	2011-11-24 10:08:42.336673	t	2011-11-24 10:35:47.031395
1	1643	132	155	\N	3	f	\N	2011-11-22 20:57:50.735666	t	2011-11-24 10:36:30.631836
1	368	2	32	\N	3	f	\N	2011-10-17 20:21:12.449866	t	2011-11-24 10:37:14.434587
1	2203	132	155	\N	3	f	\N	2011-11-23 20:51:11.239595	t	2011-11-24 10:37:38.534963
1	1831	82	102	\N	3	f	\N	2011-11-23 10:40:44.296536	t	2011-11-24 10:37:50.600127
1	2304	199	182	\N	3	f	\N	2011-11-24 10:38:05.647881	t	2011-11-24 10:39:16.066677
1	2030	132	155	\N	3	f	\N	2011-11-23 15:41:23.783819	t	2011-11-24 10:38:14.369296
1	366	1	32	\N	3	f	\N	2011-10-17 20:20:30.400212	t	2011-11-24 10:40:00.931221
1	2305	1	182	\N	3	f	\N	2011-11-24 10:40:04.107634	t	2011-11-24 10:40:15.724106
1	2306	199	182	\N	3	f	\N	2011-11-24 10:40:41.037535	t	2011-11-24 10:41:09.071931
1	2307	1	182	\N	3	f	\N	2011-11-24 10:42:22.278186	t	2011-11-24 10:42:38.451151
1	2308	199	182	\N	3	f	\N	2011-11-24 10:42:27.216595	t	2011-11-24 10:42:45.909119
1	2309	199	182	\N	3	f	\N	2011-11-24 10:42:30.766699	t	2011-11-24 10:42:44.636006
1	2310	1	182	\N	3	f	\N	2011-11-24 10:43:06.203352	t	2011-11-24 10:43:22.957845
1	2311	3	101	\N	3	f	\N	2011-11-24 10:43:06.973981	t	2011-11-24 10:43:54.047326
1	2313	199	182	\N	3	f	\N	2011-11-24 10:43:12.329037	t	2011-11-24 10:43:59.008853
1	2314	199	182	\N	3	f	\N	2011-11-24 10:44:05.454035	t	2011-11-24 10:44:27.121085
1	2315	199	182	\N	3	f	\N	2011-11-24 10:44:46.029203	t	2011-11-24 10:45:01.275916
1	1596	102	102	\N	3	f	\N	2011-11-22 18:45:26.854644	t	2011-11-24 10:45:03.138427
1	2317	1	182	\N	3	f	\N	2011-11-24 10:45:12.590114	t	2011-11-24 10:45:24.321335
1	2318	1	54	\N	3	f	\N	2011-11-24 10:45:16.042824	t	2011-11-24 10:45:28.506551
1	2319	199	182	\N	3	f	\N	2011-11-24 10:45:36.661601	t	2011-11-24 10:45:55.357306
1	2320	199	182	\N	3	f	\N	2011-11-24 10:45:55.802256	t	2011-11-24 10:46:09.431798
1	2321	199	182	\N	3	f	\N	2011-11-24 10:46:21.68807	t	2011-11-24 10:46:34.230163
1	2414	67	101	\N	3	f	\N	2011-11-24 15:01:58.472776	t	2011-11-24 15:02:19.449155
1	1629	102	102	\N	3	f	\N	2011-11-22 20:38:42.459702	t	2011-11-24 10:47:07.073119
1	2429	1	182	\N	3	f	\N	2011-11-24 15:45:37.465656	t	2011-11-24 15:45:56.953413
1	2442	1	182	\N	3	f	\N	2011-11-24 15:50:34.721298	t	2011-11-24 15:50:50.884382
1	2465	101	101	\N	3	f	\N	2011-11-24 16:50:57.063525	f	\N
1	2472	101	101	\N	3	f	\N	2011-11-24 18:15:52.139762	t	2011-11-25 09:13:50.088014
1	2488	105	101	\N	3	f	\N	2011-11-24 18:52:13.63457	t	2011-11-25 09:24:04.664117
1	2493	101	101	\N	3	f	\N	2011-11-24 19:22:42.626496	t	2011-11-25 09:17:10.88546
1	2502	102	102	\N	3	f	\N	2011-11-24 19:46:24.359714	f	\N
1	2534	104	125	\N	3	f	\N	2011-11-24 22:24:39.223223	t	2011-11-25 09:56:55.393351
1	2548	1	101	\N	3	f	\N	2011-11-25 09:36:49.122454	t	2011-11-25 09:37:01.906156
1	1911	1	146	\N	3	f	\N	2011-11-23 14:22:02.849997	t	2011-11-25 09:45:33.870058
1	1436	1	101	\N	3	f	\N	2011-11-22 16:45:51.721962	t	2011-11-25 09:53:12.66015
1	2531	104	125	\N	3	f	\N	2011-11-24 22:05:35.63892	t	2011-11-25 09:56:27.05082
1	2335	1	52	\N	3	f	\N	2011-11-24 11:08:14.406249	t	2011-11-25 09:58:10.727121
1	1401	1	148	\N	3	f	\N	2011-11-22 15:09:01.662267	t	2011-11-25 09:59:17.711217
1	2558	1	125	\N	3	f	\N	2011-11-25 10:00:03.831101	t	2011-11-25 10:00:19.29259
1	2323	1	182	\N	3	f	\N	2011-11-24 10:46:54.531379	t	2011-11-24 10:47:11.112808
1	2324	199	182	\N	3	f	\N	2011-11-24 10:47:21.880319	f	\N
1	1624	102	102	\N	3	f	\N	2011-11-22 20:31:04.201392	t	2011-11-24 10:48:03.18212
1	2326	199	182	\N	3	f	\N	2011-11-24 10:48:10.640599	t	2011-11-24 10:48:19.283294
1	562	3	182	\N	3	f	\N	2011-11-04 09:10:44.262546	t	2011-11-25 10:28:01.904484
1	1774	102	102	\N	3	f	\N	2011-11-23 09:49:44.267557	t	2011-11-24 10:48:50.023276
1	2327	1	182	\N	3	f	\N	2011-11-24 10:49:09.742261	t	2011-11-24 10:49:42.950877
1	2301	1	182	\N	3	f	\N	2011-11-24 10:29:39.567905	t	2011-11-24 10:49:10.410256
1	543	3	182	\N	3	f	\N	2011-11-04 09:01:21.990158	t	2011-11-25 10:28:13.822683
1	1687	80	101	\N	3	f	\N	2011-11-22 22:17:25.936975	t	2011-11-24 10:49:45.590749
1	2328	199	182	\N	3	f	\N	2011-11-24 10:50:00.078696	t	2011-11-24 10:50:15.22928
1	2633	1	101	\N	3	f	\N	2011-11-26 10:53:19.538091	t	2011-11-26 10:53:32.458747
1	1369	1	101	\N	3	f	\N	2011-11-22 12:14:54.38295	t	2011-11-24 10:50:33.680211
1	802	41	182	\N	3	f	\N	2011-11-14 11:11:18.474779	t	2011-11-24 10:50:34.438342
1	584	2	32	\N	3	f	\N	2011-11-04 22:25:26.472289	t	2011-11-24 10:51:47.407323
1	2329	1	182	\N	3	f	\N	2011-11-24 10:51:56.598602	t	2011-11-24 10:52:16.205311
1	2330	1	182	\N	3	f	\N	2011-11-24 10:52:43.033884	t	2011-11-24 10:53:01.303112
1	2331	1	182	\N	3	f	\N	2011-11-24 10:54:23.906875	t	2011-11-24 10:54:38.219799
1	399	3	101	\N	3	f	\N	2011-10-20 18:18:36.750374	t	2011-11-24 10:56:22.304665
1	1712	143	166	\N	3	f	\N	2011-11-23 00:39:04.780383	t	2011-11-24 10:57:05.932969
1	1144	143	166	\N	3	f	\N	2011-11-21 16:13:34.582998	t	2011-11-24 10:57:52.87117
1	2197	1	32	\N	3	f	\N	2011-11-23 20:24:33.055474	t	2011-11-24 10:57:55.77649
1	1916	73	101	\N	3	f	\N	2011-11-23 14:34:27.153788	t	2011-11-24 10:58:03.953027
1	1702	143	166	\N	3	f	\N	2011-11-22 23:42:10.892386	t	2011-11-24 10:58:55.087673
1	2223	143	166	\N	3	f	\N	2011-11-23 22:47:42.199216	t	2011-11-24 10:59:28.6648
1	1705	143	166	\N	3	f	\N	2011-11-22 23:54:30.044585	t	2011-11-24 10:59:52.857005
1	1700	143	166	\N	3	f	\N	2011-11-22 23:37:14.574402	t	2011-11-24 10:59:55.434822
1	1703	143	166	\N	3	f	\N	2011-11-22 23:43:33.538857	t	2011-11-24 11:00:19.658649
1	1701	143	166	\N	3	f	\N	2011-11-22 23:41:06.912874	t	2011-11-24 11:00:36.430565
1	1172	142	152	\N	3	f	\N	2011-11-21 20:43:26.160504	t	2011-11-24 11:01:06.431225
1	2100	1	11	\N	3	f	\N	2011-11-23 17:39:39.735949	t	2011-11-24 11:01:32.200678
1	1169	142	152	\N	3	f	\N	2011-11-21 20:41:20.812084	t	2011-11-24 11:01:42.939329
1	1202	1	84	\N	3	f	\N	2011-11-22 03:29:14.001367	t	2011-11-24 11:02:05.121696
1	1175	142	152	\N	3	f	\N	2011-11-21 20:54:15.741622	t	2011-11-24 11:02:16.247703
1	1523	1	11	\N	3	f	\N	2011-11-22 17:15:32.204147	t	2011-11-24 11:02:24.463804
1	1313	1	84	\N	3	f	\N	2011-11-22 10:41:31.184752	t	2011-11-24 11:02:33.490746
1	1566	1	85	\N	3	f	\N	2011-11-22 17:34:48.308814	t	2011-11-24 11:02:43.346105
1	1173	142	152	\N	3	f	\N	2011-11-21 20:44:56.374241	t	2011-11-24 11:02:43.477606
1	1312	1	84	\N	3	f	\N	2011-11-22 10:40:00.443434	t	2011-11-24 11:03:01.188571
1	1210	1	84	\N	3	f	\N	2011-11-22 09:07:49.422967	t	2011-11-24 11:03:46.969023
1	1610	1	85	\N	3	f	\N	2011-11-22 20:07:42.972726	t	2011-11-24 11:03:59.471806
1	1609	1	85	\N	3	f	\N	2011-11-22 20:07:12.784231	t	2011-11-24 11:04:12.366855
1	1611	1	85	\N	3	f	\N	2011-11-22 20:09:32.522717	t	2011-11-24 11:04:19.875041
1	1617	1	85	\N	3	f	\N	2011-11-22 20:18:01.681681	t	2011-11-24 11:04:23.280837
1	2333	1	11	\N	3	f	\N	2011-11-24 11:04:40.726251	t	2011-11-24 11:04:52.82803
1	1631	1	85	\N	3	f	\N	2011-11-22 20:40:26.569569	t	2011-11-24 11:04:54.658887
1	1620	1	85	\N	3	f	\N	2011-11-22 20:20:34.613311	t	2011-11-24 11:05:04.069611
1	2334	1	152	\N	3	f	\N	2011-11-24 11:05:26.566133	t	2011-11-24 11:05:47.457898
1	1612	1	85	\N	3	f	\N	2011-11-22 20:10:07.790631	t	2011-11-24 11:05:45.590257
1	2644	61	101	\N	3	f	\N	2011-11-26 12:29:17.700779	t	2011-11-26 12:29:53.316478
1	2336	41	101	\N	3	f	\N	2011-11-24 11:12:48.514826	t	2011-11-25 09:19:28.271854
1	751	1	182	\N	3	f	\N	2011-11-11 16:40:37.270709	t	2011-11-24 11:12:57.627913
1	759	194	182	\N	3	f	\N	2011-11-11 20:18:01.160627	t	2011-11-24 11:13:13.057418
1	743	1	182	\N	3	f	\N	2011-11-11 14:20:50.332587	t	2011-11-24 11:13:36.567877
1	805	194	182	\N	3	f	\N	2011-11-14 14:12:19.271793	t	2011-11-24 11:13:55.420443
1	1642	132	155	\N	3	f	\N	2011-11-22 20:57:27.38678	t	2011-11-24 11:13:59.144532
1	1640	82	102	\N	3	f	\N	2011-11-22 20:50:38.696255	t	2011-11-24 11:14:20.104312
1	2071	132	155	\N	3	f	\N	2011-11-23 17:09:23.431271	t	2011-11-24 11:14:20.729858
1	1681	102	102	\N	3	f	\N	2011-11-22 21:58:02.734183	t	2011-11-24 11:14:38.200679
1	912	194	182	\N	3	f	\N	2011-11-16 14:40:35.641612	t	2011-11-24 11:14:44.177303
1	1137	194	182	\N	3	f	\N	2011-11-21 15:52:28.577316	t	2011-11-24 11:14:48.233168
1	1338	132	101	\N	3	f	\N	2011-11-22 11:09:44.416	t	2011-11-24 11:15:23.740896
1	910	194	182	\N	3	f	\N	2011-11-16 14:38:38.640076	t	2011-11-24 11:15:25.567205
1	1690	102	102	\N	3	f	\N	2011-11-22 22:35:48.004992	t	2011-11-24 11:15:44.045609
1	1776	102	102	\N	3	f	\N	2011-11-23 10:09:13.729131	t	2011-11-24 11:16:01.418178
1	1644	132	1	\N	3	f	\N	2011-11-22 20:58:24.292633	t	2011-11-24 11:16:01.859456
1	744	194	182	\N	3	f	\N	2011-11-11 14:30:59.642668	t	2011-11-24 11:16:09.265547
1	1623	102	102	\N	3	f	\N	2011-11-22 20:30:17.449312	t	2011-11-24 11:16:13.204167
1	1337	132	101	\N	3	f	\N	2011-11-22 11:07:34.424296	t	2011-11-24 11:16:40.755264
1	1171	142	152	\N	3	f	\N	2011-11-21 20:43:06.545868	t	2011-11-24 11:16:56.489559
1	1353	132	155	\N	3	f	\N	2011-11-22 11:42:56.470827	t	2011-11-24 11:17:00.629886
1	2023	132	155	\N	3	f	\N	2011-11-23 15:31:08.620039	t	2011-11-24 11:17:15.807719
1	1393	132	155	\N	3	f	\N	2011-11-22 14:31:38.701841	t	2011-11-24 11:17:51.990341
1	2024	132	155	\N	3	f	\N	2011-11-23 15:32:07.508849	t	2011-11-24 11:18:14.111512
1	1327	132	155	\N	3	f	\N	2011-11-22 11:04:24.453717	t	2011-11-24 11:18:19.534177
1	2338	133	25	\N	3	f	\N	2011-11-24 11:18:24.850687	t	2011-11-25 09:32:16.088274
1	1844	132	155	\N	3	f	\N	2011-11-23 10:55:33.713762	t	2011-11-24 11:18:41.811154
1	1810	82	102	\N	3	f	\N	2011-11-23 10:31:15.427392	t	2011-11-24 11:20:44.13873
1	2342	82	102	\N	3	f	\N	2011-11-24 11:20:57.828577	t	2011-11-24 11:21:12.833177
1	2343	132	155	\N	3	f	\N	2011-11-24 11:21:04.67781	t	2011-11-24 11:21:39.61659
1	1789	102	102	\N	3	f	\N	2011-11-23 10:21:48.230991	t	2011-11-24 11:21:32.568268
1	2657	1	182	\N	3	f	\N	2011-11-26 14:22:43.263653	t	2011-11-26 14:23:02.05802
1	2344	1	182	\N	3	f	\N	2011-11-24 11:21:51.316874	t	2011-11-24 11:22:06.111677
1	2346	82	102	\N	3	f	\N	2011-11-24 11:23:10.003884	t	2011-11-24 11:23:22.618931
1	2398	1	182	\N	3	f	\N	2011-11-24 14:16:11.218669	f	\N
1	2349	74	101	\N	3	f	\N	2011-11-24 11:35:55.661635	f	\N
1	2415	1	101	\N	3	f	\N	2011-11-24 15:20:55.840111	t	2011-11-24 15:21:24.1867
1	2430	1	182	\N	3	f	\N	2011-11-24 15:45:39.482437	t	2011-11-24 15:45:48.105838
1	2443	1	182	\N	3	f	\N	2011-11-24 15:50:35.445612	t	2011-11-24 15:50:44.152213
1	2457	21	101	\N	3	f	\N	2011-11-24 16:10:33.291892	t	2011-11-24 16:10:52.137519
1	2466	1	32	\N	3	f	\N	2011-11-24 17:03:04.291475	f	\N
1	2473	105	101	\N	3	f	\N	2011-11-24 18:26:59.059348	t	2011-11-25 09:13:46.169836
1	2489	1	74	\N	3	f	\N	2011-11-24 18:56:58.354307	f	\N
1	2494	101	101	\N	3	f	\N	2011-11-24 19:26:24.074697	t	2011-11-25 09:22:17.04793
1	2663	1	125	\N	3	f	\N	2011-11-26 14:46:09.730907	t	2011-11-26 14:46:21.580756
1	2549	1	32	\N	3	f	\N	2011-11-25 09:37:46.75897	t	2011-11-25 09:38:09.192574
1	2351	1	84	\N	3	f	\N	2011-11-24 11:45:13.923953	t	2011-11-24 14:24:52.198386
1	2347	102	102	\N	3	f	\N	2011-11-24 11:24:01.62268	t	2011-11-24 11:45:50.371261
1	2352	1	182	\N	3	f	\N	2011-11-24 11:45:58.946625	t	2011-11-24 11:46:50.822149
1	772	194	182	\N	3	f	\N	2011-11-12 09:53:40.416148	t	2011-11-24 11:46:35.565599
1	1161	3	101	\N	3	f	\N	2011-11-21 18:59:58.132323	t	2011-11-25 10:30:33.276336
1	2353	1	182	\N	3	f	\N	2011-11-24 11:48:16.883689	t	2011-11-24 11:48:50.961112
1	2355	61	182	\N	3	f	\N	2011-11-24 11:53:40.589327	t	2011-11-25 10:30:57.088413
1	433	3	101	\N	3	f	\N	2011-10-25 22:05:21.489388	t	2011-11-24 11:48:53.443389
1	307	3	182	\N	3	t	\N	2011-10-14 14:43:03.756161	t	2011-11-24 10:50:05
1	2563	1	182	\N	3	f	\N	2011-11-25 10:32:37.857582	t	2011-11-25 10:32:57.334947
1	1366	131	32	\N	3	f	\N	2011-11-22 12:10:51.168742	t	2011-11-24 11:52:19.810664
1	2136	130	32	\N	3	f	\N	2011-11-23 18:08:01.551835	t	2011-11-24 11:52:33.078978
1	1365	131	32	\N	3	f	\N	2011-11-22 12:08:33.91252	t	2011-11-24 11:52:33.087963
1	2035	131	32	\N	3	f	\N	2011-11-23 16:08:42.466654	t	2011-11-24 11:52:47.672421
1	2034	131	32	\N	3	f	\N	2011-11-23 16:03:12.651504	t	2011-11-24 11:53:12.095517
1	2056	131	32	\N	3	f	\N	2011-11-23 16:36:05.403238	t	2011-11-24 11:53:28.604881
1	2124	131	32	\N	3	f	\N	2011-11-23 18:01:12.615189	t	2011-11-24 11:53:33.286506
1	1354	131	32	\N	3	f	\N	2011-11-22 11:49:35.823428	t	2011-11-24 11:53:38.309162
1	1358	131	32	\N	3	f	\N	2011-11-22 11:55:37.565185	t	2011-11-24 11:53:45.18645
1	1363	131	32	\N	3	f	\N	2011-11-22 12:04:42.834263	t	2011-11-24 11:54:00.486061
1	2063	131	32	\N	3	f	\N	2011-11-23 16:57:12.815359	t	2011-11-24 11:54:06.056652
1	1368	131	32	\N	3	f	\N	2011-11-22 12:14:43.213561	t	2011-11-24 11:54:18.25262
1	1364	131	32	\N	3	f	\N	2011-11-22 12:06:10.826805	t	2011-11-24 11:54:22.999387
1	1367	131	32	\N	3	f	\N	2011-11-22 12:13:34.488409	t	2011-11-24 11:54:23.001637
1	1357	131	32	\N	3	f	\N	2011-11-22 11:53:43.02666	t	2011-11-24 11:54:28.965855
1	2158	115	30	\N	3	f	\N	2011-11-23 18:44:20.983556	t	2011-11-24 11:54:53.021839
1	2040	131	32	\N	3	f	\N	2011-11-23 16:17:20.968055	t	2011-11-24 11:55:00.66326
1	2156	115	30	\N	3	f	\N	2011-11-23 18:40:54.815059	t	2011-11-24 11:55:18.231532
1	1356	131	32	\N	3	f	\N	2011-11-22 11:52:28.247476	t	2011-11-24 11:55:24.738859
1	1361	131	32	\N	3	f	\N	2011-11-22 12:00:44.773375	t	2011-11-24 11:55:28.010698
1	2157	115	30	\N	3	f	\N	2011-11-23 18:42:58.5048	t	2011-11-24 11:55:31.651222
1	2159	115	30	\N	3	f	\N	2011-11-23 18:46:41.951934	t	2011-11-24 11:55:53.089692
1	2037	131	32	\N	3	f	\N	2011-11-23 16:10:54.552586	t	2011-11-24 11:56:02.234388
1	2145	115	30	\N	3	f	\N	2011-11-23 18:27:36.946319	t	2011-11-24 11:56:07.991286
1	2150	115	30	\N	3	f	\N	2011-11-23 18:33:52.363358	t	2011-11-24 11:56:09.128166
1	2155	115	30	\N	3	f	\N	2011-11-23 18:39:36.595274	t	2011-11-24 11:56:30.295874
1	2154	115	30	\N	3	f	\N	2011-11-23 18:38:19.33714	t	2011-11-24 11:56:41.010652
1	2152	115	30	\N	3	f	\N	2011-11-23 18:36:13.175472	t	2011-11-24 11:56:41.263949
1	2148	115	30	\N	3	f	\N	2011-11-23 18:31:50.804443	t	2011-11-24 11:56:45.026135
1	2151	115	30	\N	3	f	\N	2011-11-23 18:34:56.945043	t	2011-11-24 11:56:47.806572
1	2160	115	30	\N	3	f	\N	2011-11-23 18:47:56.62625	t	2011-11-24 11:57:15.037644
1	2358	1	30	\N	3	f	\N	2011-11-24 11:57:41.167836	t	2011-11-24 11:57:53.082283
1	2153	115	30	\N	3	f	\N	2011-11-23 18:37:18.744443	t	2011-11-24 11:57:45.236885
1	2146	115	30	\N	3	f	\N	2011-11-23 18:29:21.667175	t	2011-11-24 11:58:29.649098
1	798	21	101	\N	3	f	\N	2011-11-13 19:40:15.107385	t	2011-11-24 11:58:35.238433
1	2360	1	30	\N	3	f	\N	2011-11-24 11:59:38.376154	t	2011-11-24 12:00:17.322922
1	2361	3	101	\N	3	f	\N	2011-11-24 11:59:41.128543	t	2011-11-24 12:00:14.125319
1	2362	1	30	\N	3	f	\N	2011-11-24 12:00:16.905629	t	2011-11-24 12:00:28.911151
1	2364	1	30	\N	3	f	\N	2011-11-24 12:01:55.350473	t	2011-11-24 12:02:07.206212
1	2365	1	30	\N	3	f	\N	2011-11-24 12:01:57.799455	t	2011-11-24 12:02:11.498339
1	2366	1	30	\N	3	f	\N	2011-11-24 12:02:18.461873	t	2011-11-24 12:02:30.080352
1	2367	1	182	\N	3	f	\N	2011-11-24 12:02:24.213976	t	2011-11-24 12:02:38.28875
1	2368	1	30	\N	3	f	\N	2011-11-24 12:02:58.752654	t	2011-11-24 12:03:21.852788
1	2369	1	30	\N	3	f	\N	2011-11-24 12:03:29.821884	t	2011-11-24 12:05:25.466318
1	2372	1	30	\N	3	f	\N	2011-11-24 12:03:52.650563	t	2011-11-24 12:04:10.080637
1	2375	1	30	\N	3	f	\N	2011-11-24 12:04:21.673306	t	2011-11-24 12:04:41.824642
1	2376	1	30	\N	3	f	\N	2011-11-24 12:04:37.917846	t	2011-11-24 12:05:05.963776
1	677	3	101	\N	3	f	\N	2011-11-10 02:32:33.614841	t	2011-11-23 15:33:57.158762
1	2380	1	101	\N	3	f	\N	2011-11-24 12:05:33.518111	t	2011-11-26 10:13:42.576798
1	2381	1	30	\N	3	f	\N	2011-11-24 12:05:51.554737	t	2011-11-24 12:06:33.822849
1	2147	115	30	\N	3	f	\N	2011-11-23 18:30:21.321803	t	2011-11-24 12:07:08.784453
1	2384	1	30	\N	3	f	\N	2011-11-24 12:08:17.953977	t	2011-11-24 12:08:38.631045
1	2386	1	101	\N	3	f	\N	2011-11-24 12:15:06.412772	t	2011-11-24 12:15:22.313446
1	2387	3	101	\N	3	f	\N	2011-11-24 12:17:18.497124	t	2011-11-24 12:17:40.367015
1	2388	1	182	\N	3	f	\N	2011-11-24 12:17:48.215411	t	2011-11-24 12:18:09.165212
1	2389	1	30	\N	3	f	\N	2011-11-24 12:20:00.324739	t	2011-11-24 12:21:05.054838
1	2392	1	101	\N	3	f	\N	2011-11-24 12:23:21.167121	t	2011-11-24 13:21:45.116875
1	2393	1	182	\N	3	f	\N	2011-11-24 12:24:16.901083	t	2011-11-24 12:24:28.475303
1	2394	1	182	\N	3	f	\N	2011-11-24 12:25:21.246606	t	2011-11-24 12:25:44.495526
1	2395	1	102	\N	3	f	\N	2011-11-24 12:30:22.193125	t	2011-11-24 12:31:01.18252
1	2399	1	182	\N	3	f	\N	2011-11-24 14:24:00.095431	t	2011-11-24 14:24:15.318225
1	2416	1	101	\N	3	f	\N	2011-11-24 15:22:48.696411	t	2011-11-24 15:22:58.195179
1	2431	1	182	\N	3	f	\N	2011-11-24 15:45:53.588077	t	2011-11-24 15:46:04.950446
1	2444	1	182	\N	3	f	\N	2011-11-24 15:51:27.071305	t	2011-11-24 15:51:41.832785
1	2458	1	101	\N	3	f	\N	2011-11-24 16:12:31.131378	t	2011-11-24 16:12:51.662272
1	2513	1	122	\N	3	f	\N	2011-11-24 20:25:33.362363	t	2011-11-25 09:52:00.908602
1	2467	1	182	\N	3	f	\N	2011-11-24 17:06:31.524969	f	\N
1	2474	101	101	\N	3	f	\N	2011-11-24 18:30:13.201661	t	2011-11-25 09:21:03.620973
1	2490	101	101	\N	3	f	\N	2011-11-24 19:07:50.661887	t	2011-11-25 09:20:21.525533
1	2495	3	101	\N	3	f	\N	2011-11-24 19:27:58.751093	f	\N
1	2536	101	101	\N	3	f	\N	2011-11-24 23:24:58.909095	t	2011-11-25 09:34:04.43544
1	2535	1	133	\N	3	f	\N	2011-11-24 23:15:26.08664	t	2011-11-25 09:39:16.032881
1	2520	131	32	\N	3	f	\N	2011-11-24 21:00:35.556881	t	2011-11-25 09:46:14.263942
1	2557	1	125	\N	3	f	\N	2011-11-25 09:54:12.815178	t	2011-11-25 09:54:28.234336
1	1410	1	148	\N	3	f	\N	2011-11-22 16:06:32.354395	t	2011-11-25 09:57:03.82514
1	2518	1	146	\N	3	f	\N	2011-11-24 20:50:09.994688	t	2011-11-25 09:58:32.54851
1	1482	104	125	\N	3	f	\N	2011-11-22 17:04:19.000485	t	2011-11-25 09:59:43.250568
1	1493	104	125	\N	3	f	\N	2011-11-22 17:05:25.045386	t	2011-11-25 10:00:27.11591
1	1417	104	125	\N	3	f	\N	2011-11-22 16:41:50.785799	t	2011-11-25 10:00:58.817875
1	1297	1	182	\N	3	f	\N	2011-11-22 10:09:57.774263	t	2011-11-25 10:01:27.383153
1	1496	90	125	\N	3	f	\N	2011-11-22 17:05:55.978469	t	2011-11-25 10:01:29.425373
1	2634	61	125	\N	3	f	\N	2011-11-26 10:53:28.687961	t	2011-11-26 10:53:43.254721
1	2455	1	182	\N	3	f	\N	2011-11-24 16:04:00.981613	t	2011-11-25 10:01:57.471437
1	2645	1	101	\N	3	f	\N	2011-11-26 12:30:19.100502	t	2011-11-26 12:30:35.597854
1	3593	191	182	\N	3	f	\N	2012-04-29 12:26:27.961808	f	\N
1	3594	65	101	\N	3	f	\N	2012-06-06 21:18:28.990123	f	\N
1	3596	54	146	\N	3	f	\N	2012-07-09 21:43:58.048471	f	\N
1	3598	1	125	\N	3	f	\N	2012-07-12 23:38:56.871887	f	\N
1	576	3	182	\N	3	f	\N	2011-11-04 09:21:12.215145	t	2011-11-25 10:01:25.797396
1	3599	98	64	\N	3	f	\N	2012-09-28 11:37:12.948995	f	\N
1	3600	98	125	\N	3	f	\N	2012-10-01 08:39:09.176452	f	\N
1	3601	1	182	\N	3	f	\N	2012-10-10 15:31:14.16264	f	\N
1	3602	3	182	\N	3	f	\N	2012-10-13 19:06:00.924361	f	\N
1	3603	1	182	\N	3	f	\N	2012-10-29 23:15:56.972907	f	\N
1	333	3	101	\N	3	f	\N	2011-10-16 13:35:21.700643	t	2011-11-23 17:51:10.658021
1	3604	3	182	\N	3	f	\N	2012-11-02 10:13:05.530846	f	\N
2	307	3	182	\N	3	f	\N	2012-11-19 11:04:46.671259	f	\N
2	328	3	101	\N	3	f	\N	2012-11-17 17:43:09.011009	f	\N
2	672	3	101	\N	3	f	\N	2012-11-17 18:15:57.49961	f	\N
1	1438	3	125	\N	3	f	\N	2011-11-22 16:46:22.066317	t	2011-11-25 10:34:10.964287
1	550	3	182	\N	3	f	\N	2011-11-04 09:04:28.48115	t	2011-11-25 10:34:22.280408
1	336	1	182	\N	3	f	\N	2011-10-17 12:21:34.8845	t	2011-11-25 10:42:40.77858
1	1052	3	101	\N	3	f	\N	2011-11-19 14:00:38.838496	t	2011-11-25 10:49:28.491028
1	2564	1	182	\N	3	f	\N	2011-11-25 10:49:44.516971	t	2011-11-25 10:50:00.287652
1	2565	1	182	\N	3	f	\N	2011-11-25 10:50:16.657833	t	2011-11-25 10:50:58.948736
1	1638	41	182	\N	3	f	\N	2011-11-22 20:49:59.820409	t	2011-11-25 10:52:11.840181
1	2567	1	146	\N	3	f	\N	2011-11-25 11:14:13.765168	t	2011-11-25 11:15:09.540368
1	2568	1	101	\N	3	f	\N	2011-11-25 11:14:14.155638	f	\N
1	299	1	101	53	3	f	\N	2011-10-13 19:14:47.697442	t	2011-11-25 11:20:04.058759
1	2569	3	101	\N	3	f	\N	2011-11-25 11:32:12.265401	f	\N
1	2570	1	1	\N	3	f	\N	2011-11-25 11:42:53.374068	f	\N
1	2572	1	101	\N	3	f	\N	2011-11-25 13:08:09.872374	t	2011-11-25 14:16:58.621135
1	2573	204	32	\N	3	f	\N	2011-11-25 13:35:57.174926	f	\N
1	2574	3	101	\N	3	f	\N	2011-11-25 13:55:39.849006	t	2011-11-25 13:55:58.448832
1	2575	1	182	\N	3	f	\N	2011-11-25 13:57:02.099514	f	\N
1	2576	1	101	\N	3	f	\N	2011-11-25 14:16:01.231377	t	2011-11-25 14:16:30.311228
1	2577	80	101	\N	3	f	\N	2011-11-25 14:16:28.422785	t	2011-11-25 14:16:39.352415
1	2578	1	101	\N	3	f	\N	2011-11-25 14:18:57.072426	t	2011-11-25 14:19:13.921414
1	2579	3	101	\N	3	f	\N	2011-11-25 14:21:41.494836	t	2011-11-25 14:22:22.500799
1	2580	3	101	\N	3	f	\N	2011-11-25 14:25:18.636994	t	2011-11-25 14:25:44.659996
1	2581	1	42	\N	3	f	\N	2011-11-25 14:39:41.616363	t	2011-11-25 14:41:17.324347
1	302	3	101	\N	3	f	\N	2011-10-13 20:43:29.01891	t	2011-11-25 14:44:31.912283
1	2582	1	125	\N	3	f	\N	2011-11-25 15:06:28.349098	t	2011-11-25 15:06:43.31426
1	2583	1	101	\N	3	f	\N	2011-11-25 15:08:07.406706	t	2011-11-25 15:09:20.865492
1	2584	1	125	\N	3	f	\N	2011-11-25 15:10:12.519297	t	2011-11-25 15:10:22.022946
1	2586	1	101	\N	3	f	\N	2011-11-25 15:12:10.482251	t	2011-11-25 15:13:54.613218
1	2588	1	101	\N	3	f	\N	2011-11-25 15:21:47.63331	t	2011-11-25 15:23:05.465366
1	323	3	101	\N	3	f	\N	2011-10-15 00:01:28.109928	t	2011-11-25 15:27:09.839256
\.


--
-- TOC entry 2050 (class 0 OID 23525644)
-- Dependencies: 138
-- Data for Name: estado; Type: TABLE DATA; Schema: public; Owner: comsolid
--

COPY estado (id_estado, nome_estado, codigo_estado) FROM stdin;
1	Cear�	CE
\.


--
-- TOC entry 2051 (class 0 OID 23525649)
-- Dependencies: 140
-- Data for Name: evento; Type: TABLE DATA; Schema: public; Owner: comsolid
--

COPY evento (id_evento, nome_evento, id_tipo_evento, id_encontro, validada, resumo, responsavel, data_validacao, data_submissao, curriculum, id_dificuldade_evento, perfil_minimo, preferencia_horario) FROM stdin;
46	INTRODUÇÃO AO JAVA	1	1	f	javaaaaajavaaaaajavaaaaajavaaaaa	328	2011-10-29 12:06:32.544812	2011-10-15 16:07:13.09426	javaaaaajavaaaaajavaaaaajavaaaaa	1	javaaaaa javaaaaajavaaaaajavaaaaajavaaaaajavaaaaa	\N
60	Campeonato de Xadrez	2	1	f	Interesse na tecnologi e cultura anime	780	2011-11-15 10:42:02.633305	2011-11-12 17:10:42.821147	Bolsista de iniciação ciêntifica, Professor de informatica comercial, aluno do IFCE Umirm.	2	Atualmente bolsista pelo CNpq, curso Agropecuária no IFCE Umirim, tenho 17 anos.	\N
61	Robênia	2	1	f	juarez távora	912	\N	2011-11-16 15:01:04.127042	tecnica em informatica	3	meu nome é robênia vieira de almeida, estuda na escola EEEP Juarez tavora e faço o curso tecnico de informatica.	\N
63	Robênia	1	1	f	informatica	912	\N	2011-11-16 15:13:17.386778	tecnica em informatica	3	meu nome é robênia vieira de almeida, estuda na escola EEEP Juarez tavora e faço o curso tecnico de informatica.	\N
65	Amanda 	2	1	f	estudo na escola profissionalizante juarez tavora.	915	\N	2011-11-16 15:45:51.153753	Faço curso de informatica.	1	 Eu me chamo Amanda Sousa Ramos, e estudo na escola EEEPjuarez tavora e faço o curso de informatica. 	\N
50	COMO NAVEGAR NA INTERNET DE MANEIRA QUASE SEGURA	1	1	f	O objetivo principal da palestra é passar aos participantes noções de segurança da informação, criando um ambiente computacional seguro. Criar uma cultura que considere Pessoas, Processos e Tecnologias,\r\npilares fundamentais da segurança, para que se alcancem os objetivos individuais e da sociedade.\r\n	451	\N	2011-10-31 19:09:04.314175	Graduado em Análise de Sistemas Informatizados (FIC - 2004), Especialista em Políticas e\r\nGestão em Segurança Pública pela Secretaria Nacional de Segurança Pública(FIC/SENASP - 2009), Curso especial de inteligência pela Secretaria de Segurança Pública e Defesa Social - SSPDS e UECE, Programa especial de Inteligência pela SSPDS, Ciclo de Estudos de Segurança Orgânica pela Agência Brasileira de Inteligência ABIN/DF, Curso uso da Informação na gestão de Segurança Pública pela Secretaria Nacional de Segurança Pública – SENASP. Atuou como Assessor Técnico da Divisão de Análise e Estatística da CIOPS, Agente de Inteligência e Adjunto ao Diretor do Departamento de Contra-Inteligência da Coordenadoria de Inteligência\r\n(COIN), Assessor Técnico da Coordenadoria da Tecnologia da Informação da SSPDS. Tem as\r\nseguintes linhas de atuação e pesquisa: Inteligência, Segurança da Informação, Políticas de\r\nSegurança Pública e Gestão Administrativa.\r\n	1	Graduado em Análise de Sistemas Informatizados (FIC - 2004), Especialista em Políticas e\r\nGestão em Segurança Pública pela Secretaria Nacional de Segurança Pública(FIC/SENASP - 2009).\r\n	\N
51	APLICATIVOS  UBUNTU COMSOLID	1	1	f	Uma breve introdução aos aplicativos da distribuição Ubuntu COMSOLiD.	451	\N	2011-10-31 19:18:32.565769	Técnico em Informática pelo IFCE - Campus Maracanaú. Bacharelando em Ciência da Computação pelo IFCE - Campus Maracanaú.	1	Bacharelando em Ciência da Computação pelo IFCE - Campus Maracanaú	\N
52	IMPLANTANDO HELPDESK UTILIZANDO O GLPI	1	1	f	O GLPI é uma solução web Open-source completa para gestão de ativos e helpdesk. O mesmo programa gerência inventário de ativos, hardwares e softwares.\r\nTrabalha muito bem com o suporte a usuários, padrão (helpdesk). \r\nExibe relatórios completos de produtividade e gerencia com qualidade empréstimo de equipamento bem como outras funções.\r\nA palestra vai apresentar com satisfação as principais funções do programa, requisitos para instalação e gerenciamento básico das principais funções bem como dicas de implementação em uma empresa.	451	\N	2011-11-01 15:54:02.269492	Pós-graduação em Governança de Tecnologia pela faculdade Estácio FIC e atua como instrutor na TRENIL informática ministrando os cursos de Administração de Sistemas Linux, Administração de Servidores Linux e Redes Cabeadas e Wireless. Trabalha ainda como Gerente de Tecnologia do Colégio Antares onde vem desempenhando um papel de fundamental importância na área de tecnologia promovendo inovações nessa entidade.	1	Pós-graduação em Governança de Tecnologia pela faculdade Estácio FIC.	\N
53	TI VERDE A TI MAIS CONSCIENTE	1	1	f	A palestra contará com uma introdução, na qual serão mostrados os conceitos que permeiam a TI Verde. Em seguida os conceitos serão aprofundados e mostradas quais tecnologias dão suporte aos conceitos de TI Verde. Para concluir serão mostrados estudos de caso que mostram a importancia da TI Verde.	451	\N	2011-11-01 16:23:59.432417	* Tecnico em conectividade com extensão em desenvolvimento de software - IFCE.\r\n* Graduando em Telemática - IFCE.\r\n* LPI nível 1.\r\n* Curso Cisco CCNA - Lanlink.\r\n* Novell CLA.\r\n* Ex-professor da Prefeitura Municipal de Fortaleza. 	1	Tecnico em conectividade com extensão em desenvolvimento de software - IFCE.	\N
54	EMPREENDEDORISMO DIGITAL	1	1	f	Apresentar oportunidades de negócio na área de TI com software livre	451	\N	2011-11-04 16:21:00.922638	Professor IFCE de empreendedorismo, Mestre em Administração pela UECE.	1	Professor do IFCE de empreendedorismo.	\N
59	SOFTWARE LIVRE PORQUE USAR	1	1	f	Durante a palestra será explicado de uma forma bem objetiva as vantagens de usar softwares e sistemas de código aberto.	451	\N	2011-11-10 17:04:42.717606	- Cursando Tecnico em Informatica no IFCE Campus Maracanaú.\r\n- Cursando Gestão de Tecnologia da Informação na FATENE.\r\n- Membro da COMSOLiD.\r\n- Entusiasta e Tradutor de Software Livre.	1	Cursando Tecnico em Informatica no IFCE Campus Maracanaú	\N
74	Filmagem e edição básica de video	3	1	f	Já fiz cursos de fotografia e câmeras de vídeo , portanto sei suar e também aprendi a editar no programa premier.	2239	\N	2011-11-24 01:31:01.147733	.edição premier\r\n.Curso de fotografia e câmeras de vídeo	1	pequena oficina de filmagem ensinando alguma stecnicas de filmagem e aprender a usar o editor de video de um softwre livre.	\N
67	Duvidas as 10 Mais sobre GNU Linux 	1	1	f	Essa palestra consiste basicamente em tirar as dúvidas sobre softwares e sistemas livres, A idéia é fazer com que os participantes saiam com uma visão bem firme em relação ao S.O GNU/Linux e passe a aproveitar todas as possibilidades de qualquer distribuição!	451	\N	2011-11-16 16:45:58.338979	- Cursando Tecnico em Informatica no IFCE Campus Maracanaú.\r\n- Cursando Gestão de Tecnologia da Informação na FATENE.\r\n- Membro da COMSOLiD.\r\n- Entusiasta e Tradutor de Software Livre.	1	Cursando Tecnico em Informatica no IFCE Campus Maracanaú.	\N
68	Introdução ao Sistema Operacional Linux	2	1	f	interessado em linux	934	\N	2011-11-18 20:04:03.844203	estudante de computação	1	Homem, bonito, desenrolado	\N
69	Oficina de hardware	3	1	f	interessado	934	\N	2011-11-18 20:07:12.62308	estudante de computação	2	homem, bonito e desenorolado	\N
70	 Suporte em Hardware I FETEC E Jovem	3	1	f	interessado	934	\N	2011-11-18 20:09:41.579376	estudante de computação	2	homem, bonito e desenrolado	\N
71	Oficina Planejamento e Design de Jogos	3	1	f	interessado	934	\N	2011-11-18 20:10:46.256563	estudante de computação	1	homem, bonito e desenrolado	\N
72	Empregabilidade e Postura Profissional 	1	1	f	INTERESSE NAS PALESTRAS	1108	\N	2011-11-21 10:49:59.005928	IFCE MARACANAU - ENG. AMB.\r\nE-JOVEM EDUCADORA	1	NIVEL SUPERIOR INCOMPLETO\r\nEDUCADORA PTPS	\N
73	Robótica	3	1	f	Dia 24: Sala Virgo\t	1523	\N	2011-11-23 14:03:40.318313	Aluana Barbosa de Freitas, moro em Aracati-ce.	2	Estudante do Módulo II do Projeto e-Jovem	\N
55	GERENCIANDO NUVENS PRIVADAS COM O XEN CLOUD PLATFORM	1	1	f	O Xen Cloud Platform (XCP) é uma plataforma aberta para virtualização de servidores e plataforma de computação em nuvem, entregando o Xen Hypervisor, com suporte para uma variedade de sistemas operacionais convidados, incluindo o Windows e Linux. O XCP atende às necessidades dos provedores de nuvem, serviços de hospedagem e centros de dados, combinando as capacidades de isolamento e multi-tenancy do hypervisor Xen, com maior segurança, armazenamento e tecnologias de virtualização de rede para oferecer um rico conjunto de serviços em nuvem virtual de infra-estrutura. A plataforma também deve oferecer segurança, desempenho, disponibilidade e isolamento em nuvens privadas e públicas.	451	\N	2011-11-04 16:33:15.101773	Graduando em Gestão de TI pela FIC.Trabalha com T.I há mais de 8 anos. Especialista em soluções de Virtualização em Tecnologias Microsoft, Citrix e Xen Community com o XCP (Xen Cloud Platform). Hoje gerencia o Datacenter da Wirelink Internet.	1	Graduando em Gestão de TI pela FIC.	\N
56	INTRODUCAO AO SISTEMA OPERACIONAL LINUX	2	1	f	Temos como objetivo mostrar aos participantes algumas funcionalidades do sistema para que os mesmos saibam explorar o ambiente Linux de forma dinâmica além de conceitos básicos. Utilizaremos como material de apoio o 'foca linux' e alguns links além de elaborarmos um material com comandos do shell script.\r\nTemos como roteiro as atividades seguintes:\r\n• Conceitos básicos do Linux;\r\n• Comandos básicos do Linux;\r\n• Introdução ao shell;\r\n• Dúvidas e perguntas;\r\n• Roteiro de atividades para os participantes;	451	\N	2011-11-04 17:17:31.855045	Adnilson Santos: Técnico em informática, formado pelo IFCE-Campus Maracanaú. Sócio da Lemury TI : www.lemuryti.com /\r\nwww.lanuncio.com\r\nInstrutor de Informática Voluntário na escola José Dantas Sobrinho.\r\nCamila Alcântara: cursando o Técnico em informática no IFCE-Campus Maracanaú. Participação voluntária no Comsolid\r\nLuana Gomes: Cursando Técnico em\r\nInformática e Ciências da\r\nComputação, IFCE–Campus Maracanaú.\r\nParticipei do projeto corredores digitais pela empresa Lemury TI –\r\n www.lemuryti.com.\r\n\r\n	1	Adnilson Santos: Técnico em informática, formado pelo IFCE-Campus Maracanaú.\r\nCamila Alcântara: cursando o Técnico em informática no IFCE-Campus Maracanaú.\r\nLuana Gomes: Cursando Ciências da\r\nComputação, IFCE–Campus Maracanaú.\r\n\r\n\r\n	\N
57	PERDENDO O MEDO DO VIM	2	1	f	Mostrar recursos e dicas do vim, através de anotações, scripts, links, videos, fornecendo aos integrantes do mini-curso. Os meios de aumentarem seus conhecimentos no vim de modo a poder usa-lo como editor padrão em seu dia-a-dia.	451	\N	2011-04-11 00:00:00	já trabalhei com suporte técnico no Detran-CE, na SECULTFOR (Secretatira de Cultura de Fortaleza).\r\nmantenho um blog intitulado vivaotux: http://vivaotux.blogspot.com no \r\nqual abordo inúmeros temas mas com foco principal em Software Livre.\r\nContribuições mais relevantes para a comunidade:\r\n- Blog pessoal com centenas de artigos e dicas.\r\n- Manual do inkscape no site nou-rau da unicamp.\r\n- Vide-aulas de inkscape no site Inkscape Brasil.\r\n- Livro em português sobre o editor vim (vimbook). \r\n- Inúmeros cliparts no site openclipart.	1	já trabalhei com suporte técnico no Detran-CE, na SECULTFOR (Secretatira de Cultura de Fortaleza)	\N
48	SOFTWARE LIVRE PARA ESTUDANTE	1	1	f	A palestra mostrará como os estudantes devem se preparar para encarar o mercado de trabalho usando Softwares Livres. Indicando locais de pesquisa e de conhecimento para adicionar ao currículo.	316	2011-11-15 10:43:31.542195	2011-10-31 18:39:25.373736	Graduado em Marketing. Consultor de informática da Open-Ce Tecnologias e Serviços. Já atuou como consultor em Softwares Livres para diversas empresas e instituições como: Marisol, Marquise, Lojas Esplanada, Grupo J. Macêdo, IFCE, PMF, dentre outras. Escritor.	1	Graduado em Marketing. Consultor de informática da Open-Ce Tecnologias e Serviços.	\N
58	INTRODUCAO AO BLENDER 3D	2	1	f	O mini-curso irá ensinar como Modelar um personagem, animação e criação de um jogo simples.	451	\N	2011-11-10 16:45:42.987972	Denis Oliveira: Cursando Técnico em Informática - IFCE Campus Maracanaú. Sócio do Estúdio ArtTech 3D.\r\nLeandro de Sousa: Cursando Bacharelado em Ciência da Computação e Técnico em informática - IFCE Campus Maracanaú. Sócio do Estúdio ArtTech 3D.\r\nLuan Sidney: Cursando Técnico em Informática - IFCE Campus Maracanaú. Sócio do Estúdio ArtTech 3D.	2	Denis Oliveira: Cursando Técnico em Informática - IFCE Campus Maracanaú.\r\nLeandro de Sousa: Cursando Bacharelado em Ciência da Computação - IFCE Campus Maracanaú.\r\nLuan Sidney: Cursando Técnico em Informática - IFCE Campus Maracanaú.	\N
47	PLANEJANDO E DESIGN DE JOGOS	3	1	f	O objetivo principal da oficina é mostrar os primeiros passos para quem quer desenvolver jogos e conseguir criá-los de maneira mais profissional. Para isso a oficina abordará teorias e práticas de concepção de projetos de jogos, sejão eles eletrônicos ou não.\r\n\r\nA oficina será dividida em 3 momentos:\r\nO que é o Desing de jogos e como se da o processo de criação;\r\nProjeto de Jogo (Concepção e Documentação);\r\nPrática de desenvolvimento do plano de jogo;	451	\N	2011-10-31 18:21:34.613819	Formado em Desenvolvimento de Software e atualmente cursando Ciências da Computação, ambos pelo IFCE, vem desenvolvendo projetos de pesquisa na área de entretenimento digital com ênfase em criações de jogos virtuais utilizando em grande parte programas OPENSource.\r\nEm 2009 venceu a etapa regional do Prêmio Técnico Empreendedor, com um projeto de criação de Edugames (games educativos) e Inclusão Digital. Atualmente gerente de criação da Lamdia Entretenimento Digital, empresa criada por ele e incubada em um projeto do Instituto em parcerias com outros órgãos. A empresa é responsável por transmissões de áudio ao vivo (Web Rádios) utilizando tecnologias livres e criação de games para web.	1	Formado em Desenvolvimento de Software e atualmente cursando Ciências da Computação,	\N
49	CONHECA O LIBREOFFICE	1	1	f	A palestra mostrará algumas ferramentas do pacote para escritório LibreOffice citando casos de problemas encontrados em algumas das consultorias já realizadas pela empresa.	451	2011-11-15 10:43:45.771119	2011-10-31 18:43:11.126247	Graduado em Marketing. Consultor de informática da Open-Ce Tecnologias e Serviços. Já atuou como consultor em Softwares Livres para diversas empresas e instituições como: Marisol, Marquise, Lojas Esplanada, Grupo J. Macêdo, IFCE, PMF, dentre outras. Escritor.	1	Graduado em Marketing. Consultor de informática da Open-Ce Tecnologias e Serviços.	\N
76	DEDA CESTAS	1	1	f	Artesanato	2582	\N	2011-11-25 15:08:00.890514	Artesanato	1	Artesanato	\N
75	WEB Aperfeicoamento de sites e HTML 5	3	1	f	Não informado.	2581	\N	2011-11-25 14:56:44.409326	Não informado.	1	Não informado.	\N
62	Robênia	3	1	f	informatica	912	\N	2011-11-16 15:11:02.142527	tecnica em informática	2	meu nome é robênia vieira de almeida, estuda na escola EEEP Juarez tavora e faço o curso tecnico de informatica.	\N
64	Amanda 	1	1	f	estudo na escola profissionalizante juarez tavora.	915	\N	2011-11-16 15:41:47.209731	Curso de Informatica	2	Eu me chamo Amanda Sousa Ramos, estudo na escola EEEPjuarez tavora e faço curso de informatica. 	\N
66	Amanda 	3	1	f	estudo na escola profissionalizante juarez tavora.	915	\N	2011-11-16 16:36:42.434906	faço curso de informatica.	1	Eu me chamo Amanda Sousa Ramos, e estudo na escola EEEPjuarez tavora e faço o curso de informatica. 	\N
77	Ubuntu COMSOLiD 5	1	2	f	Quais as características da distro da COMSOLiD	672	\N	2012-11-17 18:20:45.966594	estudante do IFCE Campus Maracanaú, estudante de Ciência da Computação	1	usuário iniciante ou intermediário de linux	\N
\.


--
-- TOC entry 2052 (class 0 OID 23525662)
-- Dependencies: 142
-- Data for Name: evento_arquivo; Type: TABLE DATA; Schema: public; Owner: comsolid
--

COPY evento_arquivo (id_evento_arquivo, id_evento, nome_arquivo, arquivo, nome_arquivo_md5) FROM stdin;
\.


--
-- TOC entry 2053 (class 0 OID 23525667)
-- Dependencies: 143
-- Data for Name: evento_demanda; Type: TABLE DATA; Schema: public; Owner: comsolid
--

COPY evento_demanda (evento, id_pessoa, data_solicitacao) FROM stdin;
\.


--
-- TOC entry 2054 (class 0 OID 23525674)
-- Dependencies: 145
-- Data for Name: evento_palestrante; Type: TABLE DATA; Schema: public; Owner: comsolid
--

COPY evento_palestrante (id_evento, id_pessoa) FROM stdin;
\.


--
-- TOC entry 2055 (class 0 OID 23525677)
-- Dependencies: 146
-- Data for Name: evento_participacao; Type: TABLE DATA; Schema: public; Owner: comsolid
--

COPY evento_participacao (evento, id_pessoa) FROM stdin;
\.


--
-- TOC entry 2056 (class 0 OID 23525680)
-- Dependencies: 147
-- Data for Name: evento_realizacao; Type: TABLE DATA; Schema: public; Owner: comsolid
--

COPY evento_realizacao (evento, id_evento, id_sala, data, hora_inicio, hora_fim, descricao) FROM stdin;
\.


--
-- TOC entry 2057 (class 0 OID 23525686)
-- Dependencies: 149
-- Data for Name: evento_realizacao_multipla; Type: TABLE DATA; Schema: public; Owner: comsolid
--

COPY evento_realizacao_multipla (evento_realizacao_multipla, evento, data, hora_inicio, hora_fim) FROM stdin;
\.


--
-- TOC entry 2058 (class 0 OID 23525692)
-- Dependencies: 151
-- Data for Name: instituicao; Type: TABLE DATA; Schema: public; Owner: comsolid
--

COPY instituicao (id_instituicao, nome_instituicao, apelido_instituicao) FROM stdin;
202	EMEIF - Paulo Sarasate	EMEIF - Paulo Sarasate
203	Lourenço Filho	Lourenço Filho
1	-------------	-----------------
85	EEFM EUNICE WEAVER 	EEFM EUNICE WEAVER 
70	EEFM JOSÉ DE BORBA VASCONCELOS 	EEFM JOSÉ DE BORBA VASCONCELOS 
86	EEFM LUIZ GIRÃO 	EEFM LUIZ GIRÃO 
71	EEFM PROFESSOR EDMILSON PINHEIRO 	EEFM PROFESSOR EDMILSON PINHEIRO 
72	EEFM TENENTE MÁRIO LIMA 	EEFM TENENTE MÁRIO LIMA 
87	EEM ANTÔNIO LUIS COELHO 	EEM ANTÔNIO LUIS COELHO 
73	EEM CARNEIRO DE MENDONÇA 	EEM CARNEIRO DE MENDONÇA 
74	EEM JOSE MILTON DE VASCONCELOS DIAS	EEM JOSE MILTON DE VASCONCELOS DIAS
75	EEM PROFESSOR ANTÔNIO MARTINS FILHO	EEM PROFESSOR ANTÔNIO MARTINS FILHO
76	EEM PROFESSOR CLODOALDO PINTO	EEM PROFESSOR CLODOALDO PINTO
77	EEM PROFESSOR FLÁVIO PONTES 	EEM PROFESSOR FLÁVIO PONTES 
130	EEEP CAPELÃO FREI ORLANDO	EEEP CAPELÃO FREI ORLANDO
199	EEEP COMENDADOR MIGUEL GURGEL	EEEP COMENDADOR MIGUEL GURGEL
132	EEEP CORONEL MANOEL RUFINO MAGALHÃES	EEEP CORONEL MANOEL RUFINO MAGALHÃES
146	EEEP DAVID VIEIRA DA SILVA	EEEP DAVID VIEIRA DA SILVA
78	EEM PROFESSORA EUDES VERAS 	EEM PROFESSORA EUDES VERAS 
164	EEEP DE ARARIPE 	EEEP DE ARARIPE 
89	EEP DE PACATUBA	EEP DE PACATUBA
90	EEP PROFESSORA LUIZA DE TEODORO VIEIRA	EEP PROFESSORA LUIZA DE TEODORO VIEIRA
91	EFM CASIMIRO LEITE DE OLIVEIRA	EFM CASIMIRO LEITE DE OLIVEIRA
92	EFM DEPUTADO FAUSTO AGUIAR ARRUDA	EFM DEPUTADO FAUSTO AGUIAR ARRUDA
93	EFM DESEMBARGADOR RAIMUNDO CARVALHO LIMA	EFM DESEMBARGADOR RAIMUNDO CARVALHO LIMA
61	Escola Técnica de Maracanaú	Escola Técnica de Maracanaú
42	IFCE - Campus Acaraú	IFCE-Acaraú
43	IFCE - Campus Aracati	IFCE-Aracati
44	IFCE - Campus Camocim	IFCE-Camocim
45	IFCE - Campus Caucaia	IFCE-Caucaia
46	IFCE - Campus Cedro	IFCE-Cedro
47	IFCE - Campus Crateús	IFCE-Crateús
48	IFCE - Campus Crato	IFCE-Crato
41	IFCE - Campus Fortaleza	IFCE-Fortaleza
49	IFCE - Campus Iguatu	IFCE-Iguatu
50	IFCE - Campus Jaguaribe	IFCE-Jaguaribe
51	IFCE - Campus Juazeiro do Norte	IFCE-Juazeiro do Norte
52	IFCE - Campus Limoeiro do Norte	IFCE-Limoeiro do Norte
3	IFCE - Campus Maracanaú	IFCE-Maracanaú
53	IFCE - Campus Morada Nova	IFCE-Morada Nova
54	IFCE - Campus Quixadá	IFCE-Quixadá
62	Centro de Línguas de Maracanaú	Centro de Línguas de Maracanaú
55	IFCE - Campus Sobral	IFCE-Sobral
64	EDEFM DE CHUÍ	EDEFM DE CHUÍ
56	IFCE - Campus Tabuleiro do Norte	IFCE-Tabuleiro do Norte
57	IFCE - Campus Tauá	IFCE-Tauá
58	IFCE - Campus Tianguá	IFCE-Tianguá
59	IFCE - Campus Ubajara	IFCE-Ubajara
60	IFCE - Campus Umirim	IFCE-Umirim
9	JOAQUIM AGUIAR - EEF	JOAQUIM AGUIAR - EEF
21	Liceu Estadual de Maracanaú	Liceu Estadual de Maracanaú
22	Liceu Municipal de Maracanaú	Liceu Municipal de Maracanaú
95	EEEP DE CAUCAIA 	EEEP DE CAUCAIA 
167	EEEP DE CRATO 	EEEP DE CRATO 
97	EEEP DE EUSÉBIO 	EEEP DE EUSÉBIO 
116	EEEP DE GRANJA 	EEEP DE GRANJA 
117	EEEP DE GRANJA GUILHERME GOUVEIA	EEEP DE GRANJA GUILHERME GOUVEIA
80	CAIC SENADOR CARLOS JEREISSATI 	CAIC SENADOR CARLOS JEREISSATI 
81	COLÉGIO ESTADUAL ANCHIETA	COLÉGIO ESTADUAL ANCHIETA
118	EEEP DE GUARACIABA DO NORTE 	EEEP DE GUARACIABA DO NORTE 
124	EEEP DE HIDROLÂNDIA 	EEEP DE HIDROLÂNDIA 
161	EEEP DE ICÓ 	EEEP DE ICÓ 
150	EEEP DE IPUEIRAS 	EEEP DE IPUEIRAS 
99	EEEP DE ITAITINGA 	EEEP DE ITAITINGA 
140	EEEP DE JAGUARUANA 	EEEP DE JAGUARUANA 
88	DEFM ITA-ARA ALDEIA INDIGENA MONGUBA 	DEFM ITA-ARA ALDEIA INDIGENA MONGUBA 
171	EEEP DE JARDIM 	EEEP DE JARDIM 
173	EEEP DE JUAZEIRO DO NORTE 	EEEP DE JUAZEIRO DO NORTE 
65	EEEP DE MARACANAÚ 	EEEP DE MARACANAÚ 
178	EEEP DE MILAGRES 	EEEP DE MILAGRES 
141	EEEP DE MORADA NOVA 	EEEP DE MORADA NOVA 
94	EEEP DE AQUIRAZ 	EEEP DE AQUIRAZ 
151	EEEP DE NOVA RUSSAS 	EEEP DE NOVA RUSSAS 
103	EEEP DE PACATUBA 	EEEP DE PACATUBA 
108	EEEP DE PARACURU 	EEEP DE PARACURU 
156	EEEP DE PARAMBU 	EEEP DE PARAMBU 
154	EEEP DE PEDRA BRANCA 	EEEP DE PEDRA BRANCA 
165	EEEP DE ASSARÉ 	EEEP DE ASSARÉ 
110	EEEP DE PENTECOSTE	EEEP DE PENTECOSTE
145	EEEP DE PEREIRO 	EEEP DE PEREIRO 
127	EEEP DE SANTANA DO ACARAÚ 	EEEP DE SANTANA DO ACARAÚ 
155	EEEP DE SENADOR POMPEU	EEEP DE SENADOR POMPEU
128	EEEP DE SOBRAL 	EEEP DE SOBRAL 
106	EEEP ADRIANO NOBRE	EEEP ADRIANO NOBRE
121	EEEP DE TIANGUÁ 	EEEP DE TIANGUÁ 
112	EEEP DE TRAIRI 	EEEP DE TRAIRI 
163	EEEP DE VARZEA ALEGRE 	EEEP DE VARZEA ALEGRE 
175	EEEP DE AURORA 	EEEP DE AURORA 
111	EEEP ADELINO CUNHA ALCÂNTARA	EEEP ADELINO CUNHA ALCÂNTARA
179	EEEP DOM LUSTOSA 	EEEP DOM LUSTOSA 
129	EEEP DOM WALFRIDO TEIXEIRA VIEIRA	EEEP DOM WALFRIDO TEIXEIRA VIEIRA
185	EEEP DONA CREUSA DO CARMO ROCHA	EEEP DONA CREUSA DO CARMO ROCHA
148	EEEP DR. JOSÉ ALVES DA SILVEIRA	EEEP DR. JOSÉ ALVES DA SILVEIRA
136	EEEP EDSON QUEIROZ	EEEP EDSON QUEIROZ
131	EEEP DE CANINDÉ 	EEEP DE CANINDÉ 
170	EEEP DE CARIRIAÇU 	EEEP DE CARIRIAÇU 
109	EEEP FLÁVIO GOMES GRANJEIRO	EEEP FLÁVIO GOMES GRANJEIRO
126	EEEP FRANCISCA CASTRO DE MESQUITA	EEEP FRANCISCA CASTRO DE MESQUITA
160	EEEP FRANCISCA DE ALBUQUERQUE MOURA	EEEP FRANCISCA DE ALBUQUERQUE MOURA
204	IFCE - Campus Canindé	IFCE-Canindé
125	EEEP FRANCISCA NEILYTA CARNEIRO ALBUQUERQUE	EEEP FRANCISCA NEILYTA CARNEIRO ALBUQUERQUE
119	EEEP ANTONIO TARCÍSIO ARAGÃO	EEEP ANTONIO TARCÍSIO ARAGÃO
101	EEEP GOVERNADOR LUIZ GONZAGA DA FONSECA MOTA	EEEP GOVERNADOR LUIZ GONZAGA DA FONSECA MOTA
168	EEEP GOVERNADOR VIRGÌLIO TÁVORA	EEEP GOVERNADOR VIRGÌLIO TÁVORA
122	EEEP GOVERNADOR WALDEMAR ALCÂNTARA	EEEP GOVERNADOR WALDEMAR ALCÂNTARA
120	EEEP ISAIAS GONÇALVES DAMASCENO	EEEP ISAIAS GONÇALVES DAMASCENO
180	EEEP ITAPERI 	EEEP ITAPERI 
181	EEEP JARDIM IRACEMA 	EEEP JARDIM IRACEMA 
189	EEEP JOAQUIM ANTÔNIO ALBANO	EEEP JOAQUIM ANTÔNIO ALBANO
193	EEEP JOAQUIM MOREIRA DE SOUSA	EEEP JOAQUIM MOREIRA DE SOUSA
191	EEEP JOAQUIM NOGUEIRA	EEEP JOAQUIM NOGUEIRA
200	EEEP JOSÉ DE BARCELOS	EEEP JOSÉ DE BARCELOS
98	EEEP JOSÉ IVANILTON NOCRATO	EEEP JOSÉ IVANILTON NOCRATO
138	EEEP JOSÉ MARIA FALCÃO	EEEP JOSÉ MARIA FALCÃO
123	EEEP JOSÉ VICTOR FONTENELLE FILHO	EEEP JOSÉ VICTOR FONTENELLE FILHO
133	EEEP DE ARACOIABA 	EEEP DE ARACOIABA 
134	EEEP ADOLFO FERREIRA DE SOUSA	EEEP ADOLFO FERREIRA DE SOUSA
194	EEEP JUAREZ TÁVORA	EEEP JUAREZ TÁVORA
192	EEEP JÚLIA GIFFONI	EEEP JÚLIA GIFFONI
114	EEEP JÚLIO FRANÇA	EEEP JÚLIO FRANÇA
162	EEEP LAVRAS DA MANGABEIRA 	EEEP LAVRAS DA MANGABEIRA 
105	EEEP LUIZ GONZAGA FONSECA MOTA	EEEP LUIZ GONZAGA FONSECA MOTA
149	EEEP MANOEL MANO	EEEP MANOEL MANO
147	EEEP MARIA CAVALCANTE COSTA	EEEP MARIA CAVALCANTE COSTA
137	EEEP MARIA DOLORES ALCÂNTARA E SILVA	EEEP MARIA DOLORES ALCÂNTARA E SILVA
143	EEEP AVELINO MAGALHÃES	EEEP AVELINO MAGALHÃES
190	EEEP MARIA JOSÉ MEDEIROS	EEEP MARIA JOSÉ MEDEIROS
186	EEEP MARVIN	EEEP MARVIN
115	EEEP MONSENHOR JOSÉ AUGUSTO DA SILVA	EEEP MONSENHOR JOSÉ AUGUSTO DA SILVA
157	EEEP MONSENHOR ODORICO DE ANDRADE	EEEP MONSENHOR ODORICO DE ANDRADE
201	EEEP MÁRIO ALENCAR	EEEP MÁRIO ALENCAR
169	EEEP OTÍLIA CORREIA SARAIVA	EEEP OTÍLIA CORREIA SARAIVA
177	EEEP PADRE JOÃO BOSCO LIMA	EEEP PADRE JOÃO BOSCO LIMA
187	EEEP PAULO PETROLA	EEEP PAULO PETROLA
152	EEEP ANTONIO MOTA FILHO	EEEP ANTONIO MOTA FILHO
195	EEEP PAULO VI	EEEP PAULO VI
135	EEEP PEDRO DE QUEIROZ LIMA	EEEP PEDRO DE QUEIROZ LIMA
144	EEEP POETA SINÓ PINHEIRO	EEEP POETA SINÓ PINHEIRO
166	EEEP PRESIDENTE MÉDICI	EEEP PRESIDENTE MÉDICI
188	EEEP PRESIDENTE ROOSEVELT	EEEP PRESIDENTE ROOSEVELT
158	EEEP ALFREDO NUNES DE MELO	EEEP ALFREDO NUNES DE MELO
159	EEEP AMÉLIA FIGUEIREDO DE LAVOR	EEEP AMÉLIA FIGUEIREDO DE LAVOR
197	EEEP PROFESSOR CÉSAR CAMPELO	EEEP PROFESSOR CÉSAR CAMPELO
174	EEEP PROFESSOR MOREIRA DE SOUSA	EEEP PROFESSOR MOREIRA DE SOUSA
198	EEEP PROFESSOR ONÉLIO PORTO	EEEP PROFESSOR ONÉLIO PORTO
153	EEEP PROFESSOR PLÁCIDO ADERALDO CASTELO	EEEP PROFESSOR PLÁCIDO ADERALDO CASTELO
142	EEEP PROFESSOR WALQUER CAVALCANTE MAIA	EEEP PROFESSOR WALQUER CAVALCANTE MAIA
139	EEEP PROFESSORA ELSA MARIA PORTO COSTA LIMA	EEEP PROFESSORA ELSA MARIA PORTO COSTA LIMA
104	EEEP PROFESSORA LUIZA DE TEODORO VIEIRA	EEEP PROFESSORA LUIZA DE TEODORO VIEIRA
96	EEEP PROFESSORA MARLY FERREIRA MARTINS	EEEP PROFESSORA MARLY FERREIRA MARTINS
107	EEEP RITA AGUIAR BARBOSA	EEEP RITA AGUIAR BARBOSA
102	EEEP SANTA RITA	EEEP SANTA RITA
82	EEEP SANTA RITA 	EEEP SANTA RITA 
182	EEEP SIQUEIRA 	EEEP SIQUEIRA 
172	EEEP ADERSON BORGES DE CARVALHO	EEEP ADERSON BORGES DE CARVALHO
183	EEEP TANCREDO NEVES 	EEEP TANCREDO NEVES 
113	EEEP TOMAZ POMPEU DE SOUSA BRASIL	EEEP TOMAZ POMPEU DE SOUSA BRASIL
184	EEEP VILA UNIÃO 	EEEP VILA UNIÃO 
176	EEEP BALBINA VIANA ARRAIS	EEEP BALBINA VIANA ARRAIS
196	EEEP ÍCARO DE SOUSA MOREIRA	EEEP ÍCARO DE SOUSA MOREIRA
83	EEF CLÓVIS MONTEIRO 	EEF CLÓVIS MONTEIRO 
67	EEFM ADAHIL BARRETO CAVALCANTE	EEFM ADAHIL BARRETO CAVALCANTE
68	EEFM ALBANIZA ROCHA SARASATE	EEFM ALBANIZA ROCHA SARASATE
84	EEFM ANTONIO MARQUES DE ABREU 	EEFM ANTONIO MARQUES DE ABREU 
2	Escola Estadual de Ensino Fundamental e Médio Adauto Bezerra	EEFM Adauto Bezerra
69	EEFM ENÓE BRANDÃO SANFORD 	EEFM ENÓE BRANDÃO SANFORD 
205	Outros	Outros
\.


--
-- TOC entry 2059 (class 0 OID 23525697)
-- Dependencies: 153
-- Data for Name: mensagem_email; Type: TABLE DATA; Schema: public; Owner: comsolid
--

COPY mensagem_email (id_encontro, id_tipo_mensagem_email, mensagem, assunto, link) FROM stdin;
3	2	<table width="597px" style="font-family: Arial, Helvetica, sans-serif; font-size: 13px; color: #555555; margin: 0;">\n<tr><td><img src="http://comsolid.org/armario/public/imagens/banner_telematica.jpg" /></td></tr>\n<tr><td><img src="http://comsolid.org/images/bg_corpo_sige.png" /></td></tr>\n<tr background="#" width="597px" border="2">\n<td style="float:left;padding-left:20px; width:545px; margin-top: -230px;">                     \n\tOl� <b><nome><b><br><br>\n\tSua nova senha foi gerada com sucesso!<br><br>\n\tSeu login �: <b><email></b><br><br>\n\tSua senha padr�o �: <b><senha></b><br><br>\n\tAtenciosamente,<br><br>\n\tCoordena��o da Telem�tica.<br>\n\tsite:<a href="http://comsolid.org/armario/public/login/login" target="_blank">Clique aqui</a><br>\n\tProf. Robson da Silva Siqueira.<br>\n</td>\n</tr>\n<tr><td><img src="http://comsolid.org/images/rodape-email.jpg" /></td></tr>\n</table>	TELEM�TICA: Recupera��o	http://comsolid.org/armario/public/login/login
1	1	<table width="597px" style="font-family: Arial, Helvetica, sans-serif; font-size: 13px; color: #555555; margin: 0;">\n<tr><td><img src="http://comsolid.org/images/topo-email.jpg" /></td></tr>\n<tr><td><img src="http://comsolid.org/images/bg_corpo_sige.png" /></td></tr>\n<tr background="#" width="597px" border="2">\n<td style="float:left;padding-left:20px; width:545px; margin-top: -230px;">                     \n\tOl� <b><nome><b><br><br>\n\tSeu cadastro foi efetuado com sucesso!<br><br>\n\tSeu login �: <b><email></b><br><br>\n\tSua senha padr�o �: <b><senha></b><br><br>\n\t<a href="<href_link>" target="_blank"><b>Clique aqui</b></a> para ativar seu cadastro.<br><br>\n\tUse seu login e a senha acima.<br><br>\n\tAproveite para atualizar seus dados, verificar a programa��o e indicar os eventos nos quais vai participar.<br><br>\n\tVenha fazer parte desta TRANSFORMA��O.<br><br>\n\tAtenciosamente,<br><br>\n\tCoordena��o da COMSOLiD - Comunidade Maracanauense de Software Livre e Inclus�o Digital<br>\n\tsite:<a href="http://comsolid.org" target="_blank">www.comsolid.org</a><br>\n\temail: comsolid@comsolid.org / ifce.comsolid@gmail.com<br>\n\ttwitter: <a href="http://twitter.com/comsolid/" target="_blank">twitter.com/comsolid/</a><br>\n\tfacebook: <a href="http://www.facebook.com/comsolid/" target="_blank">facebook.com/comsolid/</a><br><br>\n</td>\n</tr>\n<tr><td><img src="http://comsolid.org/images/rodape-email.jpg" /></td></tr>\n</table>	COMSOLiD^4: Cadastro no Evento	http://sige.comsolid.org/login/login
1	2	<table width="597px" style="font-family: Arial, Helvetica, sans-serif; font-size: 13px; color: #555555; margin: 0;">\n<tr><td><img src="http://comsolid.org/images/topo-email.jpg" /></td></tr>\n<tr><td><img src="http://comsolid.org/images/bg_corpo_sige.png" /></td></tr>\n<tr background="#" width="597px" border="2">\n<td style="float:left;padding-left:20px; width:545px; margin-top: -230px;">                     \n\tOl� <b><nome><b><br><br>\n\tSua nova senha foi gerada com sucesso!<br><br>\n\tSeu login �: <b><email></b><br><br>\n\tSua senha padr�o �: <b><senha></b><br><br>\n\tAproveite para atualizar seus dados, verificar a programa��o e indicar os eventos nos quais vai participar.<br><br>\n\tVenha fazer parte desta TRANSFORMA��O.<br><br>\n\tAtenciosamente,<br><br>\n\tCoordena��o da COMSOLiD - Comunidade Maracanauense de Software Livre e Inclus�o Digital<br>\n\tsite:<a href="http://comsolid.org" target="_blank">www.comsolid.org</a><br>\n\temail: comsolid@comsolid.org / ifce.comsolid@gmail.com<br>\n\ttwitter: <a href="http://twitter.com/comsolid/" target="_blank">twitter.com/comsolid/</a><br>\n\tfacebook: <a href="http://www.facebook.com/comsolid/" target="_blank">facebook.com/comsolid/</a><br><br>\n</td>\n</tr>\n<tr><td><img src="http://comsolid.org/images/rodape-email.jpg" /></td></tr>\n</table>	COMSOLiD^4: Recupera��o de Senha	http://sige.comsolid.org/login/login
2	1	<table width="597px" style="font-family: Arial, Helvetica, sans-serif; font-size: 13px; color: #555555; margin: 0;">\n<tr><td><img src="http://comsolid.org/images/topo-email.jpg" /></td></tr>\n<tr><td><img src="http://comsolid.org/images/bg_corpo_sige.png" /></td></tr>\n<tr background="#" width="597px" border="2">\n<td style="float:left;padding-left:20px; width:545px; margin-top: -230px;">                     \n\tOl� <b><nome><b><br><br>\n\tSeu cadastro foi efetuado com sucesso!<br><br>\n\tSeu login �: <b><email></b><br><br>\n\tSua senha padr�o �: <b><senha></b><br><br>\n\t<a href="<href_link>" target="_blank"><b>Clique aqui</b></a> para ativar seu cadastro.<br><br>\n\tUse seu login e a senha acima.<br><br>\n\tAproveite para atualizar seus dados, verificar a programa��o e indicar os eventos nos quais vai participar.<br><br>\n\tVenha fazer parte desta TRANSFORMA��O.<br><br>\n\tAtenciosamente,<br><br>\n\tCoordena��o da COMSOLiD - Comunidade Maracanauense de Software Livre e Inclus�o Digital<br>\n\tsite:<a href="http://comsolid.org" target="_blank">www.comsolid.org</a><br>\n\temail: comsolid@comsolid.org / ifce.comsolid@gmail.com<br>\n\ttwitter: <a href="http://twitter.com/comsolid/" target="_blank">twitter.com/comsolid/</a><br>\n\tfacebook: <a href="http://www.facebook.com/comsolid/" target="_blank">facebook.com/comsolid/</a><br><br>\n</td>\n</tr>\n<tr><td><img src="http://comsolid.org/images/rodape-email.jpg" /></td></tr>\n</table>	COMSOLiD+5: Cadastro no Evento	http://sige.comsolid.org/login/login
2	2	<table width="597px" style="font-family: Arial, Helvetica, sans-serif; font-size: 13px; color: #555555; margin: 0;">\n<tr><td><img src="http://comsolid.org/images/topo-email.jpg" /></td></tr>\n<tr><td><img src="http://comsolid.org/images/bg_corpo_sige.png" /></td></tr>\n<tr background="#" width="597px" border="2">\n<td style="float:left;padding-left:20px; width:545px; margin-top: -230px;">                     \n\tOl� <b><nome><b><br><br>\n\tSua nova senha foi gerada com sucesso!<br><br>\n\tSeu login �: <b><email></b><br><br>\n\tSua senha padr�o �: <b><senha></b><br><br>\n\tAproveite para atualizar seus dados, verificar a programa��o e indicar os eventos nos quais vai participar.<br><br>\n\tVenha fazer parte desta TRANSFORMA��O.<br><br>\n\tAtenciosamente,<br><br>\n\tCoordena��o da COMSOLiD - Comunidade Maracanauense de Software Livre e Inclus�o Digital<br>\n\tsite:<a href="http://comsolid.org" target="_blank">www.comsolid.org</a><br>\n\temail: comsolid@comsolid.org / ifce.comsolid@gmail.com<br>\n\ttwitter: <a href="http://twitter.com/comsolid/" target="_blank">twitter.com/comsolid/</a><br>\n\tfacebook: <a href="http://www.facebook.com/comsolid/" target="_blank">facebook.com/comsolid/</a><br><br>\n</td>\n</tr>\n<tr><td><img src="http://comsolid.org/images/rodape-email.jpg" /></td></tr>\n</table>	COMSOLiD+5: Recupera��o de Senha	http://sige.comsolid.org/login/login
\.


--
-- TOC entry 2060 (class 0 OID 23525703)
-- Dependencies: 154
-- Data for Name: municipio; Type: TABLE DATA; Schema: public; Owner: comsolid
--

COPY municipio (id_municipio, nome_municipio, id_estado) FROM stdin;
143	Potengi	1
144	Potiretama	1
145	Quiterianópolis	1
146	Quixadá	1
147	Quixelô	1
148	Quixeramobim	1
149	Quixeré	1
150	Redenção	1
151	Reriutaba	1
152	Russas	1
153	Saboeiro	1
154	Salitre	1
155	Santa Quitéria	1
156	Santana do Acaraú	1
157	Santana do Cariri	1
162	Senador Pompeu	1
163	Senador Sá	1
164	Sobral	1
165	Solonópole	1
159	São Gonçalo do Amarante	1
160	São João do Jaguaribe	1
161	São Luís do Curu	1
158	São benedito	1
166	Tabuleiro do Norte	1
167	Tamboril	1
168	Tarrafas	1
169	Tauá	1
170	Tejuçuoca	1
171	Tianguá	1
172	Trairi	1
173	Tururu	1
174	Ubajara	1
175	Umari	1
176	Umirim	1
177	Uruburetama	1
178	Uruoca	1
179	Varjota	1
181	Viçosa do Ceará	1
180	Várzea Alegre	1
97	Jucás	1
98	Lavras da Mangabeira	1
99	Limoeiro do Norte	1
100	Madalena	1
101	Maracanaú	1
102	Maranguape	1
103	Marco	1
104	Martinópole	1
105	Massapê	1
106	Mauriti	1
107	Meruoca	1
108	Milagres	1
109	Milhã	1
110	Miraíma	1
111	Missão Velha	1
112	Mucambo	1
113	Mombaça	1
114	Monsenhor Tabosa	1
115	Morada Nova	1
116	Moraújo	1
117	Morrinhos	1
118	Mulungu	1
119	Nova Olinda	1
120	Nova Russas	1
121	Novo Oriente	1
122	Ocara	1
123	Orós	1
124	Pacajús	1
125	Pacatuba	1
126	Pacoti	1
127	Pacujá	1
128	Palhano	1
129	Palmácia	1
130	Paracuru	1
131	Paraipaba	1
132	Parambu	1
133	Paramoti	1
134	Pedra branca	1
135	Penaforte	1
136	Pentecoste	1
137	Pereiro	1
138	Pindoretama	1
139	Piquet Carneiro	1
140	Pires Ferreira	1
141	Poranga	1
142	Porteiras	1
43	Cedro	1
44	Chaval	1
46	Chorozinho	1
45	Choró	1
47	Coreaú	1
48	Crateús	1
49	Crato	1
50	Croatá	1
51	Cruz	1
52	Dep.Irapuan Pinheiro	1
53	Ererê	1
54	Eusébio	1
55	Farias brito	1
56	Forquilha	1
182	Fortaleza	1
57	Fortim	1
58	Frecheirinha	1
59	General Sampaio	1
61	Granja	1
62	Granjeiro	1
60	Graça	1
63	Groaíras	1
64	Guaiúba	1
65	Guaraciaba do Norte	1
66	Guaramiranga	1
67	Hidrolândia	1
68	Horizonte	1
69	Ibaretama	1
70	Ibiapina	1
71	Ibicuitinga	1
72	Icapuí	1
73	Icó	1
74	Iguatu	1
75	Independência	1
76	Ipaporanga	1
77	Ipaumirim	1
79	Ipueiras	1
78	Ipú	1
80	Iracema	1
82	Irauçuba	1
81	Itaitinga	1
83	Itaiçaba	1
84	Itapajé	1
85	Itapipoca	1
86	Itapiúna	1
87	Itarema	1
88	Itatira	1
89	Jaguaretama	1
90	Jaguaribara	1
91	Jaguaribe	1
92	Jaguaruana	1
93	Jardim	1
94	Jati	1
95	Jijoca de Jericoacoara	1
96	Juazeiro do Norte	1
1	Acaraú	1
2	Acopiara	1
3	Aiuaba	1
4	Alcântaras	1
5	Altaneira	1
6	Alto Santo	1
7	Amontada	1
8	Antonina do Norte	1
9	Apuiarés	1
10	Aquiraz	1
11	Aracati	1
12	Aracoiaba	1
13	Ararendá	1
14	Araripe	1
15	Aratuba	1
16	Arneiroz	1
17	Assaré	1
18	Aurora	1
19	Baixio	1
20	Banabuiú	1
21	Barbalha	1
22	Barreira	1
23	Barro	1
24	Barroquinha	1
25	Baturité	1
26	Beberibe	1
27	Bela Cruz	1
28	Boa Viagem	1
29	Brejo Santo	1
30	Camocim	1
31	Campos Sales	1
32	Canindé	1
33	Capistrano	1
34	Caridade	1
35	Cariré	1
36	Caririaçú	1
37	Cariús	1
38	Carnaubal	1
39	Cascavel	1
40	Catarina	1
41	Catunda	1
42	Caucaia	1
\.


--
-- TOC entry 2061 (class 0 OID 23525708)
-- Dependencies: 156
-- Data for Name: pessoa; Type: TABLE DATA; Schema: public; Owner: comsolid
--

COPY pessoa (id_pessoa, nome, email, apelido, twitter, endereco_internet, senha, cadastro_validado, data_validacao_cadastro, data_cadastro, id_sexo, nascimento, telefone, administrador, facebook, email_enviado) FROM stdin;
586	Beatriz Machado	bia_princess2106@hotmail.com	Biazinha	@		47840c2db8903f4f14224a5ce4e01e62	t	2011-11-07 09:43:27.0466	2011-11-07 09:29:27.354015	2	1994-01-01	\N	f	bia_princess2106@hotmail.com	t
301	Reyson Barros do Nascimento	reyson_barros@hotmail.com	Reyson	@Reyson1991		85787a7434fad944a39f0b2d72d9f5e3	t	2011-10-13 20:43:24.530758	2011-10-13 20:39:26.992664	1	1991-01-01	\N	f	reyson_barros@hotmail.com	t
316	Anderson Ávila	andersonmufc@gmail.com	Anderson Ávila	@andersonxavila		625712c5523f0769e1eb4fa127eace1a	t	2011-10-14 18:40:37.782995	2011-10-14 18:36:49.44144	1	1988-01-01	\N	f	andersonmufc@gmail.com	t
635	Alessandra	barbielp@hotmail.com	Alessandra	@lessandra3		f2f786dee2773ba268fa679a371f8619	f	\N	2011-11-08 20:40:15.422504	2	1994-01-01	\N	f	barbielp@hotmail.com	t
356	Renan Brito Almeida	renan_brito_almeida@hotmail.com	RenanTi	@		c60392813f696638c23e456b4dfa0454	f	\N	2011-10-17 17:08:18.159799	1	1991-01-01	\N	f	renan_brito_almeida@hotmail.com	t
816	Thays dos Santos Sales	santosthays1@gmail.com	thaysxiinha	@		c8f3ae235fd8bf96a4d4ee93d82305aa	t	2011-11-16 21:53:28.605411	2011-11-14 20:53:51.719247	2	1993-01-01	\N	f	thaysxiinha@gmail.com	t
598	francisco edson da silva alves	edsonfakewarnnig@gmail.com	edsonzim	@		fac7492b390f3652d3d248cd089cb64a	f	\N	2011-11-07 21:42:55.271328	1	1992-01-01	\N	f		t
1132	WIHARLEY FEITOSA NASCIMENTO	wiharleynascimento@hotmail.com	wiharley	@		051e36c2d5338d6c1d30de9ed1b3c479	t	2012-01-18 15:23:50.143061	2011-11-21 15:04:35.236333	1	1995-01-01	\N	f	wiharleynascimento@hotmail.com	t
298	CINCINATO FURTADO	cincinatofurtado@gmail.com	Cincinato	@		ee2e1fa1a75fc6a823f754ab42efc28f	f	\N	2011-10-13 18:24:41.773394	1	1987-01-01	\N	f		t
697	WILLIAM VIEIRA BASTOS	will.v.b@hotmail.com	Willvb	@willvb		8a43e978e2d1f9943ee2fb7cc37693dc	t	2012-01-15 17:42:56.012329	2011-11-10 20:28:54.293715	1	1990-01-01	\N	f	will.v.b@hotmail.com	t
782	WILLIANY GOMES NOBRE	williany_gomes@yahoo.com	willyzinha	@		30e2ba164df6abf155378e7edac2bad4	f	\N	2011-11-12 19:34:48.167155	2	1994-01-01	\N	f	williany_gomes@yahoo.com	t
640	YARA BERNARDO CABRAL	yara-bernardo@hotmail.com	Yara C.	@diariofrenetica	http://diariodeumafrenetica.blogspot.com/	b7365147eb467266128babba3773b5fa	t	2012-01-17 11:47:51.881439	2011-11-08 23:09:43.816554	2	1989-01-01	\N	f	yara-bernardo@hotmail.com	t
1255	Pedro Erico Pinheiro	erico.pep@hotmail.com	Pedro Erico	@		955b2714f15028d0d965030e806c9bea	t	2011-11-22 09:44:07.498156	2011-11-22 09:42:19.989996	1	1993-01-01	\N	f		t
322	Luiz Herik Ferreira Da Silva	herik_flu@hotmail.com	pó de arroz	@		7da81500dd5849abf5e8cdf59185ae45	t	2011-10-14 23:55:41.06192	2011-10-14 23:52:14.496813	1	1992-01-01	\N	f		t
365	Antonia Merelania Silva Pereira	merelaniapereira@gmail.com	Merynha	@		1f91f6be34c21d2afee0d61164d847b8	t	2011-10-17 20:26:24.500958	2011-10-17 20:19:02.350302	2	1992-01-01	\N	f	merynha_sp@hotmail.com	t
2543	genicio nascimento sousa	ghenilsomm13@gmail.com	genicio	@		d3c6dc973f56a9d615e3d346a0787ab6	f	\N	2011-11-25 09:18:04.713678	1	1997-01-01	\N	f		t
337	vicente de paulo honorio de abreu	VPAULOABREU@HOTMAIL.COM	paulo abreu	@		cd4e7c69f4729a3a81d611238e3d7f5d	t	2011-10-17 12:26:22.965225	2011-10-17 12:23:26.785996	1	1984-01-01	\N	f		t
359	allan sérgio modesto da silva	allan.sergios@gmail.com	allanxisd	@		f028a9af9b535749594c65faa469a4f6	t	2011-10-17 18:30:03.932499	2011-10-17 18:28:06.858718	1	2011-01-01	\N	f	allan.sergios@gmail.com	t
303	Tiago Barbosa Melo	tiagotele@gmail.com	tiagotele	@tiagotele		423939e76fe9e425e0bea0f69825a6dc	f	\N	2011-10-14 13:19:19.263867	1	1985-01-01	\N	f	tiagotele@gmail.com	t
382	Jocastra	jocatraguiar@gmail.com	joquinha	@jocastraguiar		ad8c81f9eb0990d9ea989d77ce97c649	f	\N	2011-10-18 14:30:03.410136	2	1990-01-01	\N	f	dudacatshow@hotmail.com	t
386	Francisca Isone Rodrigues Ferreira 	isonerodriguesf@gmail.com	isonny	@		ff5cc3d1fc0d0b03eab805d7d8782abc	t	2011-10-18 20:24:51.797313	2011-10-18 20:14:09.458258	2	1990-01-01	\N	f	isony1@hotmail.com	t
305	EMANUEL SILVA DOMINGOS	emanuel@fortalnet.com.br	Emanuel Domingos	@EmanuelDomingos		7934e32312c666700f8f1fb38cd4e95e	t	2012-01-13 08:14:15.118094	2011-10-14 13:46:46.290655	1	1990-01-01	\N	f	emanuelsdrock@gmail.com	t
340	Jefferson Rocha	jeffersonrochagt@gamil.com	Tux'Rocha	@conexaorocha		4a2999135a047531d8d273ae9652d68f	f	\N	2011-10-17 12:45:02.295345	1	1991-01-01	\N	f	mustang-gp@hotmail.com	t
306	Joao Gomes da Silva Neto	joao_neto@ymail.com	@joao_neto	@joao_neto	http://www.joaoneto.blog.br	737a832f07b1d9afd74a96769c2dea32	t	2011-10-24 12:18:07.119381	2011-10-14 14:29:01.405895	1	1990-01-01	\N	f	joao_neto@ymail.com	t
394	Frankyston Lins Nogueira	frankyston@gmail.com	Frankyston	@frankyston	http://www.franat.com.br	f336488f72c2ba0b010dfeef302ab200	t	2011-10-20 08:25:51.766638	2011-10-20 08:25:20.649852	1	1987-01-01	\N	f	frankyston@hotmail.com	t
429	João Vitor de Souza	jvsconnect@hotmail.com	João Vitor	@	http://www.jvsconnect.com.br	ae5b1b9986a3d3783cd056505b08ee89	f	\N	2011-10-24 21:11:04.640099	1	1985-01-01	\N	f	joao.souza@jvsconect.com.br	t
331	Francisco Alessandro Feitoza da Silva	alessandro.feitoza.silva@gmail.com	Alessandro	@		6d5ffe5b1327001046511579b05c8c8e	t	2011-10-15 18:27:24.176037	2011-10-15 17:38:27.701254	1	1995-01-01	\N	f	Alessandro.eu@hotmail.com	t
343	THIAGO VERAS DE ALMEIDA	thgveras@gmail.com	TVERAS	@thiagoverass		18fc0acdbcd3fb4ef0d4723cf872c744	t	2011-10-17 13:23:57.571238	2011-10-17 13:17:31.701165	1	1990-01-01	\N	f	thgveras@gmail.com	t
362	Enilton Angelim	enilton.angelim@gmail.com	Enilton	@	http://technolivre.blogspot.com/	6c44d9791d5bf6fae60fb54d97df48a0	t	2011-10-17 20:33:10.699166	2011-10-17 20:06:44.659635	1	1989-01-01	\N	f		t
368	francisco janailson ferreira gomes	janailsonferreira@yahoo.com.br	nailson	@		3470e06fb765e9b91a1159904752dba5	t	2011-10-17 20:39:54.140215	2011-10-17 20:21:12.449866	1	1992-01-01	\N	f	janailsonferreira@yahoo.com.br	t
1257	isaias de lima sousa	isaiasdelima1@gmail.com	MegaThrasher	@		b312503b2202e1ad3cc2dba66a3065d9	t	2011-11-22 09:48:36.855544	2011-11-22 09:43:52.91034	1	1993-01-01	\N	f	isaias_Drummer@hotmail.com	t
849	Hitalo Sousa	pivete20112011@hotmail.com	Hitalo pivete	@		c3e43433abe43ac97a3b0f08c0ce1fa7	f	\N	2011-11-15 23:33:27.4418	1	2011-01-01	\N	f	pivete20112011@hotmail.com	t
349	david tomás ferreira da silva	davidtomas.ilustracoes@hotmail.com	davidtomas	@davidtomasilust	http://davidtomasilustracoes.blogspot.com/	c3508e54ab254573de959b5d8e9728f6	f	\N	2011-10-17 15:04:25.316944	1	2011-01-01	\N	f	davidtomas.ilustracoes@hotmail.com	t
390	Robson Santiago	robim85@gmail.com	robson	@RobsonSanti		8b015a32ed520400242bac51e9efc22f	t	2011-10-19 15:39:30.838845	2011-10-19 15:34:11.420454	1	2011-01-01	\N	f	robim_85@hotmail.com	t
2618	Roberto Sousa da Silva Junior	betinhox3@hotmail.com	Bigaoo	@		5eeb1a80afe7f4dd882cc0b1cbf8156a	f	\N	2011-11-26 01:54:07.579739	1	1993-01-01	\N	f	bigaoo@hotmail.com	t
371	Matheus Arleson	matheusarleson@gmail.com	Matheus	@		2fdb00bc8031ec909469135ddf7ca412	t	2011-10-17 22:14:06.877917	2011-10-17 22:12:46.746807	1	1991-01-01	\N	f	matheusarleson@gmail.com	t
416	Luciana Gomes de Andrade	luciana.bonek.gomesdeandrade@gmail.com	Luluzinha	@		feb7e34146d4382590e3d07d5eb21877	t	2011-11-11 16:11:37.425146	2011-10-23 19:24:04.158308	2	1994-01-01	\N	f	luciana.bonek.gomesdeandrade@gmail.com	t
420	FRANCISCO ALEXANDRE PEREIRA DE SOUSA	franciscoalexandre92@gmail.com	ALEXANDRE	@		4f7f448ac12af4db01a1cb4f98fe9c31	t	2011-10-23 23:26:52.913765	2011-10-23 23:17:53.521513	1	1992-01-01	\N	f		t
433	Francisco David	david.xbox01@gmail.com	F David	@		86f114a653abb0d6e5e3db972b9f4455	t	2011-11-23 13:48:37.9804	2011-10-25 22:05:21.489388	1	1986-01-01	\N	f	fd_xbox@hotmail.com	t
448	JUNIOR MENDES	franciscomendes@bol.com.br	JUNIOR MENDES	@		b0299b6f0d85da51b3169dfbb05b6551	f	\N	2011-10-31 15:21:39.859831	1	1993-01-01	\N	f		t
614	Rimária de Oliveira Castelo Branco	rimaria_100@hotmail.com	Rimária	@		f70ebdec2f8738b1a91d15c50043eb7a	t	2011-11-16 23:52:42.99146	2011-11-07 23:02:49.829515	2	1991-01-01	\N	f	rimaria_100@hotmail.com	t
2619	chagas carvalho teixeira de oliveira junior	junior.ce@live.com	junior	@		97724e4b64b43fac28b7ee1bdb977aee	f	\N	2011-11-26 01:55:41.930267	1	2011-01-01	\N	f	junior.ce@live.com	t
674	YOHANA MARIA SILVA DE ALMEIDA	ravena_xispe@hotmail.com	Ravena	@		30a94be9920bac763d60a4b54ab7b8c6	t	2012-01-10 18:26:31.892498	2011-11-09 21:22:27.145494	2	1995-01-01	\N	f	ravena_xispe@hotmail.com	t
308	Jose Cleudes da Silva	jcleudess@gmail.com	Cleudes	@		e3d3a7ac295b60a71a9044eda4a48e09	t	2011-10-14 15:07:25.16484	2011-10-14 14:55:23.206773	1	1988-01-01	\N	f	cleudes_maximo@hotmail.com	t
314	PEDRO HENRIQUE FEITOZA DA SILVA	FEITOZA.PEDRO@GMAIL.COM	PEDROH	@pedrofeitoza_	https://www.facebook.com/#!/profile.php?id=100002141256624	b49433d7c4ec05e0dfc79bd8bc802909	t	2011-10-14 18:03:23.575703	2011-10-14 17:55:22.630283	1	1988-01-01	\N	f	ph_tuf@hotmail.com	t
320	Anderson dos Santos	anderson.dsf@hotmail.com	Anderson dsf	@	http://www.andersondsf.xpg.com.br	e19d5cd5af0378da05f63f891c7467af	t	2011-10-14 20:59:57.08353	2011-10-14 20:54:37.333334	1	1993-01-01	\N	f	anderson.dsf@hotmail.com	t
332	Rafael Bezerra	rafaelbezerra195@gmail.com	Rafael	@bezerra_rafael		aad7b10f15a8896e4904280d4b8c7d8e	t	2012-01-18 19:33:55.160331	2011-10-16 12:06:59.272359	1	1992-01-01	\N	f		t
309	Marcos Paulo Roque Pio	marcospauloroquepio@gmail.com	Rkpio13	@		fee18b146ed91b416737c2800d334ca3	t	2011-10-14 15:20:13.969642	2011-10-14 15:07:06.470144	1	1982-01-01	\N	f	marcosproquepio@hotmail.com	t
1026	ROSANABERG PAIXÃO DE LIMA	rosanabergpaixao@hotmail.com	Rosana	@		d63c14d354abc8697ce71b81c5ec949d	t	2012-01-15 23:03:08.986354	2011-11-18 19:53:42.749773	2	1991-01-01	\N	f	rosanabergpaixao@hotmail.com	t
317	Ana Gabrielly Lustosa	gabylustosa@hotmail.com	Gaby Lustosa	@		4c1f4acf526a745f91658687d9d3ea2f	f	\N	2011-10-14 19:09:37.71781	2	1994-01-01	\N	f	gabylustosa@hotmail.com	t
1100	ROSINEIDE SILVA DE ARAUJO	rosineide.s.araujo@gmail.com	Rosineide	@		89a785212b29a2c7d675b4c7bd34c6d9	f	\N	2011-11-21 10:14:38.370951	2	1989-01-01	\N	f	rosineide.s.araujo@gmail.com	t
338	Junior Lopes	junior777_lopes@hotmail.com	Junior Lopes	@junior777_lopes		e495932e673d22725e7e8170db819d3b	t	2011-10-17 12:31:18.466043	2011-10-17 12:30:44.838198	1	1993-01-01	\N	f		t
1096	SAMUHEL MARQUES REIS	samuhel.e.reis@hotmail.com	Samuhel	@		db8a169949322f1449b974898119a17b	t	2012-01-10 18:26:29.18168	2011-11-21 09:12:04.544026	1	1988-01-01	\N	f	samuhel.e.reis@hotmail.com	t
357	gustavo santos	gustavosantosk1@gmail.com	gustavo	@		26d343adf899b5472c474fff659e347d	t	2011-10-17 17:32:23.971414	2011-10-17 17:28:30.448817	1	2011-01-01	\N	f	gusta.moreno@hotmail.com	t
363	Antonia Adriana Sousa Maciel	adrianasousa1990@gmail.com	Adriana	@		a0fc74a9bdfa1d784e303068200311d8	t	2011-10-17 20:23:51.383657	2011-10-17 20:16:39.732074	2	1990-01-01	\N	f		t
2689	Helder Sampaio de Magalhaes	heldersm5@hotmail.com	heldersm	@heldersm		dc1ff982eacba2919594d51181642a03	f	\N	2011-12-29 12:08:14.56036	1	1976-01-01	\N	f	heldersm5@hotmail.com	t
341	André Luis Vieira Lemos	andre.luis.vieira.lemos@gmail.com	andre_eofim	@		8167e7ceb145b2c382e5fbc4967aed1a	t	2011-10-17 12:50:37.009606	2011-10-17 12:48:21.120346	1	1990-01-01	\N	f	andre_eofim@hotmail.com	t
526	reenan	stuart-tuf@hotmail.com	infowayw	@		4358a67f0af2964b6e442a7a52e185ca	t	2011-11-03 16:27:17.676675	2011-11-03 16:21:47.737727	1	1994-01-01	\N	f	renanroocha@hotmail.com	t
2207	Maria Carlene dos Santos	loraleny@hotmail.com	carlene	@		eee4c21c773a203d8120a041ad40550e	f	\N	2011-11-23 21:11:04.555238	2	1991-01-01	\N	f		t
383	Antonio Everardo Silva Diniz	everardovpr@gmail.com	everardo	@everardovpr		41cdd250ba5257efe0c1edfa682ffb9a	t	2011-10-18 14:40:09.254798	2011-10-18 14:38:24.259655	1	1989-01-01	\N	f		t
360	Lucilio	luciliogomes_100@hotmail.com	Lucilio Gomes	@		c7df7cd16fb853734d85c78bc9074c76	t	2011-10-17 19:29:19.083955	2011-10-17 19:27:38.5761	1	1986-01-01	\N	f	luciliogomes_100@hotmail.com	t
344	Joelia de Souza Rodrigues	joelia.srodrigues@gmail.com	Joelia	@		2a18daf7b2043a69c3fe6e179066bca2	t	2011-10-17 13:21:28.106001	2011-10-17 13:20:03.481579	2	1993-01-01	\N	f	jojo_joelia@hotmail.com	t
387	Estevão	estevaovs@gmail.com	Olyver Vongola	@Estevao_vs		68e54efd311e8817d826b9858a833b9d	t	2011-10-19 10:02:03.768485	2011-10-19 10:00:09.439739	1	1994-01-01	\N	f	estevaovs@vs.com.br	t
366	João Paulo Costa Moreno	j.paulo_cor@yahoo.com.br	________	@		90acf54b52e74cc7979ef566005d8b26	t	2011-10-17 20:25:15.075949	2011-10-17 20:20:30.400212	1	1991-01-01	\N	f		t
347	Charlenny Freitas	mylcha@hotmail.com	Charlenny	@mylcha		770851948539d76a3597f3320544f879	f	\N	2011-10-17 14:14:27.814937	2	1976-01-01	\N	f	mylcha@hotmail.com	t
395	alan barros	alanbmx_01@hotmail.com	alanbarros	@		a1e677bf265d76b9113aa178febe447c	t	2011-10-20 09:23:29.321265	2011-10-20 09:22:26.934898	1	1990-01-01	\N	f	alanbmx_01@hotmail.com	t
350	Antonio José Castelo da Silva	antoniojosecdd@gmail.com	Antonio José	@antonioqx	http://www.wlmaster.com	4abd5a8a639656ba8855ea57f7a4d87e	f	\N	2011-10-17 15:04:31.632401	1	1985-01-01	\N	f	antoniojosecdd@gmail.com	t
409	João Victor Ribeiro Galvino	joaovictor777@yahoo.com.br	João Victor	@		740b9c2a17774293a1e97dc27e7f4aec	t	2011-10-20 21:03:09.812971	2011-10-20 21:02:03.415854	1	1991-01-01	\N	f		t
369	Keliane Rocha	kelianerocha27@gmail.com	Keliane Rocha	@		b877cc368d3bd8e49a7760920a09fb1d	t	2011-10-17 20:29:02.460711	2011-10-17 20:22:36.939862	2	1990-01-01	\N	f		t
352	Jonas Bazilio Pereira	jonasbazilio@gmail.com	bazilio	@		221882814dca7c389a85b9399df6bdc2	t	2011-10-17 16:39:44.510551	2011-10-17 16:38:28.523557	1	1993-01-01	\N	f	jonasbazilio@gmail.com	t
354	Jedson	jedsonguedes@yahoo.com.br	JedsonGuedes	@jedsonguedes	http://jedsonguedes.wordpress.com	bde25ab206c6fc4ed6011613ff3ff0e9	t	2011-10-17 16:51:23.897544	2011-10-17 16:50:03.431749	1	1992-01-01	\N	f	jedsonguedes@yahoo.com.br	t
413	Marcelo Sá	marcelo.filefox@hotmail.com	Marcelo	@		4667ee68cfb44492694b03dffb4b28e2	f	\N	2011-10-22 12:46:08.163751	1	1986-01-01	\N	f	marcelo.filefox@hotmail.com	t
372	Barboza	cleidiane.maria@gmail.com	Barboza	@		3f9c5c7b0aa9362f095d34432dbb2a8d	t	2011-10-17 23:03:40.83919	2011-10-17 22:51:20.30048	2	1990-01-01	\N	f		t
391	Adairton Freire	adairton_freire@yahoo.com.br	Adairton	@adairton		2aac68fd8537db1894e1d78ac891dbcc	f	\N	2011-10-19 17:58:33.566354	1	1978-01-01	\N	f	adairton_freire@yahoo.com.br	t
421	Harissonn Ferreira Holanda	harissonferreiraholanda@gmail.com	Harisson	@harissonholanda	http://www.harissonholanda.blogspot.com	2f5de6fe853b14c371789488e8f217c6	t	2011-10-23 23:23:31.680253	2011-10-23 23:18:45.104515	1	1993-01-01	\N	f	harissonferreiraholanda@gmail.com	t
430	flanduyar	flanduyar@gmail.com	download	@		1abc9cba0113b3042a18850be94204d1	f	\N	2011-10-24 23:13:16.087866	1	1986-01-01	\N	f	flanduyar@gmail.com	t
434	Allef Bruno	bnrunotk_gb@hotmail.com	Allef Br	@		3f3279d43c2329c3749fbd3aa014ea18	f	\N	2011-10-25 23:52:54.598675	1	1993-01-01	\N	f	brunotk_gb@hotmail.com	t
696	Neyllany	neyllany@gmail.com	Neyllany	@Neyllany		44dd1ac9dddc04efcb00b59520bb499d	t	2012-01-17 22:29:10.178997	2011-11-10 20:21:42.393681	2	1991-01-01	\N	f	neyllany@gmail.com	t
440	Patricia Pierre Barbosa	patriciapierre00@gmail.com	Pierre	@		66f09e2e115a54b481fadcf5b31916bb	t	2011-10-27 13:51:39.745865	2011-10-27 13:50:01.418599	2	1993-01-01	\N	f	patriciapierre00@gmail.com	t
437	Wesley Coelho Silva	coelho.w@alu.ufc.br	Coelho	@		76a6744cfc6f228e94c539f0a1452ccf	t	2011-10-26 17:39:29.146059	2011-10-26 17:37:30.231462	2	1992-01-01	\N	f		t
442	jorge fernando	jorgefernandorb@hotmail.com	jorge fernando	@jorgefernandu		245a63382e68333dab137dd019c449a3	t	2011-10-28 22:58:02.651705	2011-10-28 22:54:32.001839	1	1988-01-01	\N	f	marvinjfpg@hotmail.com	t
445	 Ana Camila	kakazinhamix@hotmail.com	Camila	@		6a67e071db5a47888d6b58abe69c0cc5	t	2011-10-29 22:33:18.268991	2011-10-29 22:26:27.208853	2	1988-01-01	\N	f		t
531	francisco jailson alves felix	fjalvesfelix@gmail.com	Jailson	@		1ce63cb603aa5b1c92d47e465624f7e2	f	\N	2011-11-03 21:01:07.532749	1	1993-01-01	\N	f	jailson_kbca@hotmail.com	t
310	Camila	milamlima@gmail.com	Camila	@		bc7e2f23169a62706a1b4268ef597147	t	2011-10-14 15:19:06.617174	2011-10-14 15:18:07.70981	2	1987-01-01	\N	f		t
929	THEOFILO DE SOUSA SILVEIRA	theofilo.silveira@gmail.com	Theófilo	@theo_silveira		0a85ccb247d1c641f7c2572d4c8e08e8	f	\N	2011-11-16 15:15:51.504715	1	1985-01-01	\N	f		t
321	Emanuel Pereira de Souza	manix1992ago@gmail.com	Emanuel	@		9da9dd9f2a0df61f924372a829f058a6	t	2011-10-14 21:01:16.988615	2011-10-14 20:55:19.24889	1	1992-01-01	\N	f	manix1992ago@gmail.com	t
1200	TIAGO DE MATOS LIMA	tiago_m_lima@hotmail.com	TiagoMattos	@		b5dd857ffc9ce783af392ab4c24996af	t	2012-01-10 18:26:29.953056	2011-11-22 01:30:27.716866	1	1986-01-01	\N	f	tiago_m_lima@hotmail.com	t
311	josé macedo de araujo	rocklee.jiraia@gmail.com	strategia	@		25c9bf68343db897bbd8afce9754ef3c	t	2011-10-14 16:59:17.890375	2011-10-14 16:03:17.96049	1	2011-01-01	\N	f	rocklee.jiraia@gmail.com	t
752	Eugênio Barreto	eugeniobarreto@gmail.com	Eugênio	@		5a1fef13f0a4e6fccd155e8b729b4870	t	2011-11-24 11:53:52.379528	2011-11-11 17:05:15.407481	1	1975-01-01	\N	f		t
318	Ana Gabrielly Lustosa	fofa-gaby@hotmail.com	Gaby Lustosa	@		0cb5bd5c29c3779de866a3b1f70614c6	t	2011-10-14 19:16:34.571626	2011-10-14 19:12:50.609865	2	1994-01-01	\N	f	gabylustosa@hotmail.com	t
336	Geovanio Carlos Bezerra Rodrigues	geovanioufc@gmail.com	Geovanio	@geovanioc		f2be7097da09f3b4dbdf648179b17d25	f	\N	2011-10-17 12:21:34.8845	1	1987-01-01	\N	f	geovanioufc@gmail.com	t
2630	VALDECI ALMEIDA FILHO	valdecifilho94@yahoo.com	Alexandre	@		513fa7fe78d6dada8eb6e431dd24521c	f	\N	2011-11-26 10:08:39.849125	1	1980-01-01	\N	f		t
364	MARIA NILBA DOS SANTOS PAIVA	mnilbapaiva2@gmail.com	nilbapaiva	@		5ca6a76fb54657f19768b03ed316f363	t	2011-10-17 21:11:26.819061	2011-10-17 20:17:54.631479	2	1958-01-01	\N	f	mnilbapaiva2@gmail.com	t
1109	WAGNER ALCIDES FERNANDES CHAVES	waguimch@yahoo.com.br	wagner	@Wagnercomedy		9d2e07412994a909d06fc5b18ef0e069	t	2012-01-10 18:26:30.990073	2011-11-21 10:43:03.394794	1	1988-01-01	\N	f	waguimch@hotmail.com	t
934	WAGNER DOUGLAS DO NASCIMENTO E SILVA	wagner.doug@hotmail.com	Thantoo	@		53f43d5ae2d950bc8d60328eb409eda6	t	2012-01-10 18:26:31.043852	2011-11-16 18:12:22.936075	1	1990-01-01	\N	f		t
313	José Natanael de Sousa	sousanatanael@rocketmail.com	Natanael Sousa	@		2aab6c91e5a686e6ef9877cc6d948508	t	2011-10-15 16:45:43.481854	2011-10-14 17:01:53.939236	1	1990-01-01	\N	f	natanlean@hotmail.com	t
2512	Iva mara Silva Fernandes	ivamara1@hotmail.com	ivamara	@		d1f3555286e7eb20ec3a7cad053d1dbc	f	\N	2011-11-24 20:17:51.048785	2	1990-01-01	\N	f	ivamara1@hotmail.com	t
418	Mayara Arruda Pereira	mayara_hina@hotmail.com	Mayara	@		a357379d456d091df1d163b7eec9ac83	t	2011-10-23 21:49:14.605099	2011-10-23 21:48:10.218424	2	1990-01-01	\N	f		t
327	Ana Kézia França	kezia.ninha@gmail.com	ana kezia	@ninha_java	http://www.plixie.com.br/	07bf8d97a6e81aa92119716935694032	f	\N	2011-10-15 10:06:46.366232	2	1988-01-01	\N	f	kezia.ninha@gmail.com	t
330	Mariana Lima Garça	mariana_rukia@hotmail.com	Mari Pompom	@mari_shadows		c44e0fb43b0a5579b0e508c8b3f6e9bc	f	\N	2011-10-15 13:11:41.832621	2	1993-01-01	\N	f	mariana_rukia@hotmail.com	t
342	Keziane Silva Pinto	kezianesilva@gmail.com	Keziane	@		3391b78a333b43f1641217e28e11d8aa	t	2011-10-17 15:19:28.610279	2011-10-17 12:56:07.807314	2	1992-01-01	\N	f	kezianesilva@ymail.com	t
358	Leonardo Alves de Moura	leonardo_moura61@hotmail.com	Leonardo	@		a7c4e020509a37978797f8079c479fc4	t	2011-10-19 13:48:57.141523	2011-10-17 18:22:29.517444	1	1991-01-01	\N	f	leonardo_moura61@hotmail.com	t
384	Juliana Feliz Nogueira Ribeiro	juliribeiro.ju@gmail.com	Juliana 	@Juliana2Ribeiro		2a7c5f641be5d88a505f184b39292805	t	2011-10-18 15:53:18.403818	2011-10-18 15:50:37.827304	2	1992-01-01	\N	f	juliribeiro.ju@hotmail.com	t
345	Cícero Wilame	cwilame@yahoo.com.br	Cícero	@		356185d7cbe52937c461d4186d33db4b	t	2011-10-17 13:46:14.303969	2011-10-17 13:45:28.404515	1	1975-01-01	\N	f		t
388	Ana Valeria de Souza Queiroz	anavalerias64@gmail.com	lelinha	@		3acb8a895e0135a0853472ec9bf2b460	t	2011-10-19 13:41:17.809639	2011-10-19 13:37:27.137405	2	1988-01-01	\N	f	jennifer_lelinha@hotmail.com	t
392	jose djavan soeiro araujo	jdjavan@gmail.com	Djavan	@		3a9d9dbac29238a05ece74463fc41ed7	t	2011-10-20 09:32:31.550197	2011-10-19 23:32:37.322843	1	1976-01-01	\N	f	jdjavan@hotmail.com	t
348	Amanda Duarte Lima	adlejovem@gmail.com	mandinha	@		8e9ed05e7f86244df6ef4517929f929f	t	2011-10-17 14:41:27.088615	2011-10-17 14:38:24.96798	2	1989-01-01	\N	f	lidumanda@hotmail.com	t
367	Brena Dielle Anastacio De Sousa	brenadielle@gmail.com	Dielle	@		5aa72a2e670d638f43701b15f059bd02	t	2011-10-17 20:26:37.6538	2011-10-17 20:21:07.477447	2	1992-01-01	\N	f		t
410	Aristoteles Vieira	aristotelesvieira@gmail.com	tottivieira	@		09eb6bf8c3b30e7d88c8d74413103850	t	2011-10-20 21:57:13.696808	2011-10-20 21:55:40.711766	1	1990-01-01	\N	f	tottivieira02@yahoo.com.br	t
351	Raquel Barroso da Costa e Silva	rcostaesilva2009@gmail.com	Raquel	@RaquelBarroso1		d47783fc478122161a6233dca818e271	t	2011-10-17 15:23:09.312545	2011-10-17 15:20:13.628682	2	1985-01-01	\N	f		t
414	Fernando Gomes Rodrigues	fernandogr@fernandogr.com.br	fernandogr	@fernandodivac	http://fernandogr.com.br/blog	b181e43c872340be07d0d5dd16d2eda7	t	2011-10-22 21:06:38.296181	2011-10-22 15:18:35.179575	1	1971-01-01	\N	f	fernandogr@uol.com.br	t
353	Philipe Quintiliano	philipequintiliano@gmail.com	Philipe	@Philipequit		cf7fa4805ade24e40f83ba1a7c828711	t	2011-10-17 17:18:16.002918	2011-10-17 16:44:48.1503	1	1987-01-01	\N	f	philipe.quit@hotmail.com	t
355	alexsandra da rocha Oliveira	sandraneto_oliveira@hotmail.com	sandrinha	@		f5f36a6a7d16068036b7a9b3d32690b2	f	\N	2011-10-17 17:03:50.718762	2	1974-01-01	\N	f		t
370	Adonis Martins Pessoa Filho	adonis.filho@gmail.com	Adonis Filho	@		960eff7bc04cf3dce4dc62ec93ca759f	t	2011-10-17 21:27:17.66482	2011-10-17 21:24:48.948229	1	1981-01-01	\N	f	adonis.filho@gmail.com	t
374	Jonathan	jw.silva2@gmail.com	jhonne	@Jhonewilliam		011af046c3b6d6800a0adc8d4b32d954	t	2011-10-18 09:18:10.593645	2011-10-18 09:14:59.968665	1	1990-01-01	\N	f	jhone_gatog3@hotmail.com	t
396	RAFAEL DE ALMEIDA MATIAS	rafaelitpro@gmail.com	Rafael	@RafaelItpro	http://vidadesysadmin.wordpress.com/	2468e9f3bf3cfbfe907664a20caa8e32	t	2011-10-20 09:57:32.683961	2011-10-20 09:36:15.356978	1	1983-01-01	\N	f	rafaelitpro@gmail.com	t
373	GEORGE BRITO DE SOUZA	georgegiany@gmail.com	George	@		377b286a78205a96d4a63ba974ada238	t	2011-10-18 09:22:17.764691	2011-10-18 09:07:59.138755	1	1978-01-01	\N	f	georgegiany@gmail.com	t
431	Marlon Silva de Vasconcelos	marlon_s_v@hotmail.com	marlon_s_v	@		7b61c20f6b7122e229ba6ebfdfa102eb	t	2011-10-25 18:23:43.211752	2011-10-25 18:22:58.002647	1	1989-01-01	\N	f	marlon_s_v@hotmail.com	t
435	Antonio Gerardo de castro costa filho	Hyuuga_nerd@hotmail.com	Nerdz1	@		ce36d969a3712d1b8d29a19636cc0861	t	2011-10-26 10:59:54.046976	2011-10-26 10:54:28.868107	1	1992-01-01	\N	f	Hyuuga_nerd@hotmail.com	t
412	Paulo Anderson Ferreira Nobre	paulo-nobre18@hotmail.com	Paulo Anderson	@		6b88d98da5b31fb7c96548b3b4f77338	t	2011-11-21 20:11:38.469865	2011-10-21 21:42:05.929619	1	1993-01-01	\N	f	paulo-nobre18@hotmail.com	t
422	José Rudney Novais da Silva	rudneynovais@gmail.com	Rudney	@		96c541289a4a473e171034b78559fd12	t	2011-10-24 10:10:00.98146	2011-10-24 10:04:51.16304	1	1991-01-01	\N	f		t
446	Francisca Claudiane Oliveira de Souza 	friendnany14@hotmail.com	Dianne 	@		4360b74ea5b9be8698b49ce6bbf8a0db	t	2011-10-31 14:50:07.023315	2011-10-31 14:45:46.291043	2	1994-01-01	\N	f		t
459	KLAUS FISCHER GOMES SANTANA	klausfgsantana@gmail.com	klausfgsantana	@klausfgsantana		f47ff017d38fbd4adbc4f69121382a48	t	2011-10-31 23:12:46.218776	2011-10-31 23:03:05.8731	1	1977-01-01	\N	f	klausfgsantana@gmail.com	t
439	Viviane Costa	vivicosttaa@gmail.com	Vivi Costa	@vivicostta		6082dac5e55b3f86dc9d4bf927cd12ef	t	2011-11-03 21:51:17.864681	2011-10-27 13:16:21.527035	2	1989-01-01	\N	f		t
375	Romano Reinaldo Saraiva	romano.saraivas@gmail.com	Romano	@		3084447114f8fba7fa790f99758ab5de	t	2011-10-18 10:04:20.766909	2011-10-18 09:54:22.933572	1	1990-01-01	\N	f		t
376	Diego Furtado da Silva	diegof.webdesigner@gmail.com	DiegoKel	@	http://www.tecmauriti.com.br	a46454419bf7474b151d6844caef4f1e	t	2011-10-18 21:54:21.968486	2011-10-18 10:37:54.959527	1	1985-01-01	\N	f		t
381	Francilio Araújo da Costa	francilioaraujo@gmail.com	francilioaraujo	@		30b29ce5d8cb1a1516e51e6d43145875	t	2011-10-18 14:17:10.487059	2011-10-18 14:12:27.068064	1	1993-01-01	\N	f		t
393	José Alday Pinheiro Alves	aldaypinheiro2@gmail.com	aldaypinheiro	@aldaypinheiro		f49bd771501784ee4cbb94f46f7391d3	f	\N	2011-10-20 00:02:51.479951	1	1994-01-01	\N	f	aldaypinheiro@facebook.com	t
377	Aélia de Sousa Januario	aeliasousa@hotmail.com	Aélia	@		8710e5cd4697c6a5e3d846c8619ea9a3	f	\N	2011-10-18 10:48:47.099664	2	1992-01-01	\N	f	aeliasousa@hotmai.com	t
406	Luiza Domingos Araujo	luizadomix@gmail.com	Luiza Domix	@luizadomix		ee84b81dc55d6b40799b612f559a303d	t	2011-10-20 18:53:08.069323	2011-10-20 18:48:28.020939	2	1991-01-01	\N	f	luiza_araujo91@hotmail.com	t
312	WALLISSON ISAAC FREITAS DE VASCONCELOS	wallissonisaac@gmail.com	Wallisson	@		2cbcd3b748427da010980fe5685585cf	t	2012-01-17 14:32:02.694652	2011-10-14 16:46:12.390301	1	1989-01-01	\N	f	wallissonisaac@gmail.com	t
378	maria ely	elyalcantara2@gmail.com	maria ely	@bybyely		6fa87a2f3d237d5212cf86baf928863d	t	2011-10-18 10:55:45.65043	2011-10-18 10:54:07.884433	2	1983-01-01	\N	f	ely.alcantara2@facebook.com	t
1121	RAFAEL RODRIGUES SOUSA	rafaromanrodriguez@gmail.com	Rafael	@		ae63f774b76f273b56fdf1bfe5765ab5	t	2012-01-16 11:45:27.950702	2011-11-21 12:23:24.681451	1	1991-01-01	\N	f	rafaromanrodriguez@gmail.com	t
389	Ruan Alif Mendes de Lima	ruanalif@gmail.com	Ruan Alif	@		9d0d37c0bcaf354c540bb74a318578cb	t	2011-10-19 14:27:57.257778	2011-10-19 14:21:22.438069	1	2011-01-01	\N	f	ruan.alif@facebook.com	t
1901	RAUL OLIVEIRA SOUSA	rauloliveira14@gmail.com	Raul Oliveira	@		862056486a4921748610475d491b5fc2	f	\N	2011-11-23 12:58:21.611056	1	1990-01-01	\N	f	rauloliveira14@gmail.com	t
1043	RAYLSON SILVA DE LIMA	raylson.silva22@gmail.com	Raylson	@	http://www.facebook.com/profile.php?id=100002981289654	5222b578107a82b8e221f44c1aef563c	t	2012-01-18 17:02:44.599636	2011-11-19 11:09:19.536878	1	1994-01-01	\N	f	raylson.silva22@gmail.com	t
379	DIEGO ARAUJO PEREIRA	diegoyusuki@gmail.com	Yusuki	@diego_yusuki		cde997e129ea4ef2c593b6aa5acbf6f5	t	2011-10-18 11:59:49.427908	2011-10-18 11:58:41.330463	1	1991-01-01	\N	f	diegoyusuki@gmail.com	t
385	Alexandre	alefrei26@gmail.com	Alexandre	@		e3ecbdeb713ed580cd60423d10f5e0cb	t	2011-10-18 19:27:33.57823	2011-10-18 19:23:19.990244	1	1981-01-01	\N	f		t
380	Mark Alleson Silva Lima	markalleson@gmail.com	Mark Alleson	@markalleson		d42adbd3c0b23933b9aa8468a5a242fa	t	2011-10-18 13:39:14.656071	2011-10-18 13:37:03.567588	1	1983-01-01	\N	f	markalleson@gmail.com	t
397	Denylson Santos de Oliveira	densdeoliveira@hotmail.com	denys86	@		8e5ba776ad43c72f2a284a884c9a1557	t	2011-10-20 11:54:04.851143	2011-10-20 11:08:34.528286	1	1986-01-01	\N	f	densdeoliveira@hotmail.com	t
411	George Santos	georgesantos169@gmail.com	George	@georgesanto		c7af520291d0ad0e083f43b8da6ae610	t	2011-10-21 21:08:06.771013	2011-10-21 21:02:34.130201	1	1988-01-01	\N	f	judogeorge@hotmail.com	t
3344	ADILIO MOURA COSTA	adilio_costa27@yahoo.com.br	ADILIO MOU	\N	\N	e7d908ec300d16b1fe39c2d765109eec	f	\N	2012-01-10 18:25:40.966063	0	1980-01-01	\N	f	\N	f
419	david Der	d.avid.h@hotmail.com	David_Der	@		6b3214b6418eb40ab4d70487c8633216	t	2011-10-23 21:52:23.679007	2011-10-23 21:51:06.143256	1	1994-01-01	\N	f	d.avid.h@hotmail.com	t
415	Bryan Ávila Cavalcante	bryancavalcante@hotmail.com	PeDeChiclete	@		afaafece09cebb62075d27965e5d5b80	t	2011-10-22 15:39:00.837227	2011-10-22 15:37:37.476046	1	1996-01-01	\N	f	bryancavalcante@hotmail.com	t
3345	ADRIANA MARIA SILVA COSTA	adriana.costa1677@hotmail.com	ADRIANA MA	\N	\N	52720e003547c70561bf5e03b95aa99f	f	\N	2012-01-10 18:25:41.413707	0	1980-01-01	\N	f	\N	f
400	Luciana Gomes de Andrade	luciana.bonekgomesandrade@gmail.com	Luluzinha	@		dbdc06d802b7bbda38014a1097628916	f	\N	2011-10-20 18:30:59.450573	2	1994-01-01	\N	f	luciana.bonekgomesandrade@gmail.com	t
3346	ADRIANA OLIVEIRA DE LIMA	adrianabsb7@gmail.com	ADRIANA OL	\N	\N	70a87a8908c3a0cdef1e64cf3f4859c0	f	\N	2012-01-10 18:25:41.546128	0	1980-01-01	\N	f	\N	f
423	Ana Elizabeth Muniz de Souza	anamuniz1@hotmail.com	Aninha	@AnaElizabeth01		9a00b42593ce6f837b331ace27dec3c9	t	2011-10-25 09:09:35.62921	2011-10-24 10:46:28.721555	2	1981-01-01	\N	f	anamuniz1@hotmail.com	t
405	Cristina Almeida de Brito	cris_somoral@hotmail.com	Ruivinha	@cristinabritoo	http://diariodacriis.blogspot.com	bc123b7068abbe31f2ac46a02ee988e8	t	2011-10-20 18:43:32.268209	2011-10-20 18:35:46.765204	2	1993-01-01	\N	f	cristina.seliga@gmail.com	t
436	Darlinson Alves	darlison_alves@hotmail.com	Darlison	@		a26fd50f89ab7498ca6a87eea88100de	t	2011-10-26 13:31:33.092367	2011-10-26 13:28:50.762868	1	1992-01-01	\N	f	darlison.7@hotmail.com	t
3347	ADRIANO DE LIMA SANTOS	adrianoplayer@hotmail.com	ADRIANO DE	\N	\N	1141938ba2c2b13f5505d7c424ebae5f	f	\N	2012-01-10 18:25:41.677513	0	1980-01-01	\N	f	\N	f
407	Alisson Monteiro	monteiroalisson@hotmail.com	Hollyfield	@		245eadc6c0865b4af31a8c98aacdce86	t	2011-10-20 18:51:20.406631	2011-10-20 18:50:40.493355	1	1992-01-01	\N	f		t
441	HONIERISON	honnyrifane@gmail.com	rifane	@		c99ba0a2dfa5ea8c4f8e051fa734addb	t	2011-10-27 19:41:28.375599	2011-10-27 19:29:13.048623	1	1990-01-01	\N	f	honnypotter@hotmial.com	t
427	dercio	dercioalves@gmail.com	dercinho	@dercioaq		cf929f8c9e87190964b1720087cb5e8c	t	2011-10-24 17:03:32.862876	2011-10-24 17:01:55.610792	1	2011-01-01	\N	f	dercioalves@gmail.com	t
447	Caio Victor 	caiovictorppascoal@gmail.com	dartskill	@		207a708aef25caab4634b14f19a92297	t	2011-10-31 15:30:45.715848	2011-10-31 15:21:35.902296	1	1993-01-01	\N	f	caio_toupeira@hotmail.com	t
428	Jalles Pereira Veras	jalles_pereira@hotmail.com	Jalouco	@		b4e00b32eff42def47a9a7b4fdf1e12c	t	2011-10-24 19:36:57.077969	2011-10-24 19:34:48.154026	1	1988-01-01	\N	f		t
438	Kayenna Silva	kayennak@gmail.com	Kayenna	@		4ecec7ebbe796e0e20da7eb4cd405ce7	t	2011-10-27 12:03:29.525071	2011-10-26 19:09:23.225316	2	1992-01-01	\N	f	kayennak@gmail.com	t
460	Raul Costa de Oliveira	raulcosta.oliveira@gmail.com	raulroots	@		26f941265f0a2b2d2abbd1165341e41e	f	\N	2011-11-01 15:16:13.600869	1	1993-01-01	\N	f		t
465	ANA KAROLINE CARVALHO DE SOUZA	karoline_carvalho18@hotmail.com	karoline	@		ce9c473be08c239ddcefebd3a59fc480	f	\N	2011-11-02 13:38:49.650302	2	1990-01-01	\N	f	karoline_carvalho18@hotmail.com	t
462	Lília Souza	liliasouzas2@gmail.com	LíliaS	@		e10adc3949ba59abbe56e057f20f883e	t	2011-11-01 16:52:37.619393	2011-11-01 16:50:55.505754	2	1992-01-01	\N	f		t
1168	Lucas Otacílio	otacilio2712@hotmail.com	Lucas MP	@		e10adc3949ba59abbe56e057f20f883e	t	2011-11-21 20:13:21.120427	2011-11-21 20:08:30.865892	1	2011-01-01	\N	f		t
2620	João de Sousa	tiojoao10@gmail.com	João de Souza	@		3049a6009334a09d58542dc5f4f1d7c8	f	\N	2011-11-26 08:53:01.328619	1	1976-01-01	\N	f		t
527	darlene	darlene_016@hotmail.com	dadazinha	@		8109eefe85c104896a1279b647763933	f	\N	2011-11-03 16:32:37.648185	2	1993-01-01	\N	f	darlene_016@hotmail.com	t
636	José Paulino de Sousa Netto	zehpaulino@gmail.com	José Paulino	@zehpaulino		0699670d3ebd91eb13a440e11c8fb4b6	t	2011-11-08 21:26:11.887183	2011-11-08 21:17:43.16446	1	1993-01-01	\N	f	paulino_netto27@hotmail.com	t
1362	paulo roberto baia lima	flampaulo@hotmail.com	paulinho	@		97094d73ae8ea3c82b3d9fbdc4147d08	f	\N	2011-11-22 12:01:08.42762	1	1994-01-01	\N	f	flampaulo@hotmail.com	t
2644	Laercio dos Santos Sampaio	laercio_sampaio18@hotmail.com	Laercio	@		afb61046765d956fe94ddb35168e9bbb	f	\N	2011-11-26 12:29:17.700779	1	1992-01-01	\N	f		t
818	Caike Damião	caikedamiao@gmail.com	Dike  	@caikedamiao		332f9d150797a5f86954f5096a851c7b	t	2011-11-15 06:26:52.574187	2011-11-14 22:13:39.930414	1	1994-01-01	\N	f	caikedamiao@gmail.com	t
450	Bruno Harrison Santos de Souza	brunoharrisonstecnico@gmail.com	Bruno Harrison	@brunoharrisons		56ed0a28fa3eb8d5dd7d8c28d7b203b4	t	2011-11-24 15:56:42.089025	2011-10-31 16:14:24.57579	1	1990-01-01	\N	f	brunoharrisonstecnico@gmail.com	t
451	Wiliana Paiva	wilianapaiva@hotmail.com	Wiliana	@		57cd0516a2f132c8f0500c46d6215ac2	t	2011-11-10 17:25:34.566464	2011-10-31 16:33:56.273624	2	1990-01-01	\N	f	wilianapaiva@hotmail.com	t
458	anderson rodrigues vieira	andersonr.vieira01@gmail.com	anderson	@		61fa2bf299845f9f08a4ef7cb667ae08	t	2011-10-31 20:56:28.346636	2011-10-31 20:49:25.076732	1	1990-01-01	\N	f		t
463	Leandro Nascimento	ordnael.nascimento@yahoo.com.br	Leandro	@LeandroDkf		a79941a60e395edc4c94590f5176e923	t	2011-11-02 12:02:11.826905	2011-11-02 11:58:48.411437	1	1988-01-01	\N	f	ordnael.love@hotmail.com	t
473	Osvaldo Modesto Silva Filho	osvaldofilho.redes@gmail.com	Osvaldo Filho	@osvaldofilho	http://osvaldofilho.wordpress.com	7daae96c925373dbcab3d6b70682c74e	t	2011-11-03 02:06:16.336156	2011-11-03 02:01:12.328606	1	1986-01-01	\N	f	osvaldofilho.redes@gmail.com	t
676	Milene Gomes da Silva	mile-artes@hotmail.com	Milene	@		a779ee5c40b5b5f334eb6df89619c585	t	2011-11-10 00:02:18.384507	2011-11-10 00:00:04.708127	2	1989-01-01	\N	f		t
682	RAYSA PINHEIRO LEMOS	raysarpl@gmail.com	Raysa'	@		c73eaa80dc760f3e460919f08a01152f	t	2012-01-15 18:47:03.83572	2011-11-10 13:33:56.942952	2	1993-01-01	\N	f	raysarpl@gmail.com	t
466	RAPHAEL SANTOS DA SILVA	rsdsfec@yahoo.com.br	SANTOS	@phaels		b5fa0c6127798cb58465b463efd79067	t	2011-11-02 13:51:32.731459	2011-11-02 13:50:03.991611	1	1986-01-01	\N	f	rsdsfec@yahoo.com.br	t
452	Narah Wellen	narahwellen@gmail.com	Lelinha	@		522f0579328986ee3933355c579ef442	t	2011-10-31 17:46:16.663997	2011-10-31 17:41:17.004322	2	1992-01-01	\N	f		t
767	RIMARIA DE OLIVEIRA CASTELO BRANCO	rimaria_ocb@hotmail.com	Rimária	@MariihCastelo		a3b582b38317a8335090a953eb205e2e	f	\N	2011-11-12 02:22:30.637438	2	1991-01-01	\N	f	rimaria_100@hotmail.com	t
698	Lucas Nunes Araujo	lucasnunesaraujo_ce@hotmail.com	luquinha	@		6d2cc8fc23c8bdf46049f838e5ea99f0	f	\N	2011-11-10 20:47:18.882538	1	1994-01-01	\N	f		t
453	Emmily Queiroz	emilly.ifce@gmail.com	Emmily	@emmilyqueiroz		4ab40053e6de94108a7198da3b163db9	t	2011-11-04 15:08:07.709841	2011-10-31 17:42:21.662343	2	1990-01-01	\N	f	jeskah_emilly@hotmail.com	t
461	Davi Gomes	davi-gomes20@hotmail.com	MS-DOS	@		9e06a8039f8b544ae4f66f580dcd62ec	t	2011-11-01 16:42:34.527899	2011-11-01 16:41:19.575288	1	1993-01-01	\N	f		t
583	maria Lúcia	maria_caninde@hotmail.com	Maria Lu	@		3dd8e9e146aa762787f75d4d9649b54e	t	2011-11-04 22:00:14.210634	2011-11-04 21:58:30.045634	2	1991-01-01	\N	f	maria_caninde@hotmail.com	t
625	MURILLO BARATA RODRIGUES	murillobarata@hotmail.com	Barata	@murillobarata		04a6b96acc80362dacb72133d4474b68	f	\N	2011-11-08 14:47:33.538477	1	1993-01-01	\N	f		t
454	Agapito Alves de Freitas Filho	agapitohunter@hotmail.com	!!!!!!	@		48d507c4001ef4f255964af5894e0ece	t	2011-11-07 20:45:01.808387	2011-10-31 18:27:19.821842	1	1992-01-01	\N	f	agapitohunter@hotmail.com	t
1029	David Silva DUarte	davidcearaamor@hotmail.com	Davidsilva	@		dd754785b715ace5d32ce2f0f01f32c7	t	2011-11-18 20:34:33.384704	2011-11-18 20:31:01.43677	1	1993-01-01	\N	f	davidcearaamor@hotmail.com	t
1022	NACELIA ALVES DA SILVA	nacelia_alves@hotmail.com	Nacelia	@		ae6c52416202bd5f26587bb8bef79149	t	2012-01-16 20:20:24.688646	2011-11-18 19:19:34.259833	2	1988-01-01	\N	f	nacelia_alves@hotmail.com	t
1131	NARA THWANNY ANASTACIO CARVALHO DE OLIVEIRA	naraanny@hotmail.com	Thwanny	@		54c4e1e06e7fb76ad840108dacfa073d	t	2012-01-10 18:26:25.924609	2011-11-21 15:01:14.933238	2	1993-01-01	\N	f		t
1033	LUÉLER PAIVA ELIAS	lueler_elias@hotmail.com	Luéler	@		248a140a6a752d9dca79601991114d2d	t	2012-01-10 18:26:23.826244	2011-11-18 21:11:28.382424	1	1988-01-01	\N	f	lueler_elias@hotmail.com	t
456	Agapito Alves de Freitas Filho	agapito.seliga@gmail.com	gostoso, lol	@		95ebf8d271f6f120922cd4168c4c50bb	f	\N	2011-10-31 18:34:51.774935	1	1992-01-01	\N	f	agapitohunter@hotmail.com	t
475	ana camila araujo veras	anacamilaaraujoveras9@gmail.com	mila araujo	@		0e3d3ce3febc0dd853b3f7a1d4dcc1ec	t	2011-11-03 09:23:19.812631	2011-11-03 09:20:22.222941	2	1993-01-01	\N	f		t
471	Ana Caroline Mendes Gadelha	carol-gadelha@hotmail.com	Caroline	@carol9317	http://www.facebook.com/profile.php?id=100001977031203	af7ff7cbda938810769e46c2e4ea6262	f	\N	2011-11-02 19:18:30.210639	2	1993-01-01	\N	f	carol-gadelha@hotmail.com	t
642	Yuri Lima	yurilima91@hotmail.com	Yurilima911	@YuriLimaSUC	http://quantaignorancia.com	16c3358f541a1d47e1cdb2f672f96225	t	2011-11-08 23:42:35.060577	2011-11-08 23:41:29.03008	1	1991-01-01	\N	f	yurilima91@hotmail.com	t
457	Mércia do Nascimento	merciadonascimento@hotmail.com	Mércia	@mercianasci		2456b3507ce3f13950c219a497889a81	t	2011-10-31 19:25:34.472193	2011-10-31 19:22:41.132554	2	2011-01-01	\N	f	merciadonascimento@facebook.com	t
984	Tayna Kelly dos Santos Silva	taynakellyabsoluta2009@hotmail.com	Kelinha	@TaynaKelly15		658694d37e72e0cfc2b7bcbf33a5fc30	t	2011-11-17 21:13:22.888557	2011-11-17 21:00:45.622299	2	1995-01-01	\N	f	taynakellyabsoluta2009@hotmail.com	t
474	Bruno souza	brunosouza.silva1987@gmail.com	bruno souza	@		1a9f772a9280a9fb36e9b26c6489650e	t	2011-11-03 09:23:54.627905	2011-11-03 09:18:58.651788	1	1987-01-01	\N	f		t
2513	Jarvys Exoda de Oliveira	jarvys_exoda@hotmail.com	Jarvys	@		2e918273fb1ce2c00d82636598bdfc8d	f	\N	2011-11-24 20:25:33.362363	2	1993-01-01	\N	f	jarvys_exoda@hotmail.com	t
477	Jessyca siqueira cunha	Jessycasiqueira201@gmail.com	brankinha	@		11ea7cd655a13c53e7a914e2d41ba3f7	f	\N	2011-11-03 09:25:16.664865	2	1991-01-01	\N	f		t
2544	Ary Davis Batista de Oliveira	aryjr77@hotmail.com	Ary Davis	@		83e0c056b814f643380c0438a8c6affa	f	\N	2011-11-25 09:20:02.788008	1	1997-01-01	\N	f		t
479	juliete angel	angel.juliete7@gmail.com	nee-chan	@		a45d60b8eb7b2af86e4e2a042e673e65	f	\N	2011-11-03 09:25:46.819313	2	1995-01-01	\N	f		t
480	Ana Beatriz	beatrizverasf@gmail.com	bibibi	@Beatriz_verasf		bc86a8c57e57a8e61e9c603ad5deebe0	f	\N	2011-11-03 09:26:20.885779	2	1994-01-01	\N	f	beatrizhta2009@hotmail.com	t
541	Karine Vasconcelos	ana_karine_15@hotmail.com	Karine	@		94eeba75f56faed0ceb26e9e220783a2	f	\N	2011-11-04 09:00:42.804989	2	1994-01-01	\N	f		t
481	Mariana Oliveira Fontenele	marianafontenele11@gmail.com	gelinho	@		c98f6a54ed603b45feddb995d632b827	f	\N	2011-11-03 09:26:28.21244	2	1994-01-01	\N	f		t
547	João Rodrigues	johnnyKlink@hotmail.com	Klink Loafer	@GarotoUngido		69141b921e7cb856be8c64f82054bbce	t	2011-11-04 09:34:06.638355	2011-11-04 09:04:18.996614	1	1994-01-01	\N	f	johnnyKlink@hotmail.com	t
647	Heitor Lopes Castro	heitorlc@hotmail.com	Wanderer	@		5fe6db443546302f532bd0013e1fa11d	f	\N	2011-11-09 11:39:02.284235	1	1985-01-01	\N	f		t
609	Edson da silva	alessandroeusoumaiseu@gmail.com	sdfadadasd	@		99be1aa55f69bbf6a0697702c1aa8345	f	\N	2011-11-07 21:48:28.235234	2	1992-01-01	\N	f		t
532	mayco mendes de almeida	mykebatera@hotmail.com	miketrack	@		2309c79af6666e98d1d028457bffa6c2	t	2011-11-04 11:49:42.005798	2011-11-03 22:12:54.828905	1	1983-01-01	\N	f	mykebatera@hotmail.com	t
652	maria valquiria gomes sales	mariavalquiria@hotmail.com.br	valquiria	@		fae7bbc8bf786798ee9621ad26208076	t	2011-11-09 11:46:37.694675	2011-11-09 11:41:45.143575	2	1967-01-01	\N	f		t
704	Antônio Lucas Lima Paz	luquinhaspaz@windowslive.com	Lucas Paz	@luquinhaspaz		59244b8371b7251fee2d3a22d763737e	t	2011-11-10 22:07:40.618007	2011-11-10 22:06:04.346484	1	1994-01-01	\N	f	luquinhaspaz@windowslive.com	t
675	Maria Mickaelle Gomes Monteiro	mickaellegmonteiro_1992@hotmail.com	Mika monteiro	@MickaGM	http://ainconquistavel.blogspot.com/	2a09312cfb397aa8c83b08e8c171a3e4	t	2011-11-10 14:51:40.402612	2011-11-09 22:11:54.459804	2	1992-01-01	\N	f	mickaellegmonteiro_1992@hotmail.com	t
483	emilania cordeiro dos santos	emilaniacordeiro@gmail.com	emilania	@		ff50f22b366ef3b8487c5f7b756585ac	t	2011-11-03 09:35:37.415104	2011-11-03 09:28:10.479742	2	1996-01-01	\N	f	emilania_gata_12@hotmail.com	t
484	lidia marinho de oliveira	lidiadeoliveira16@gmail.com	lidinha	@		b16be14fdf1bec0c7ae4b2e962d74b67	t	2011-11-03 10:28:30.421033	2011-11-03 09:28:48.818742	2	1995-01-01	\N	f		t
524	Reyk Alencar	reykalencar@live.com	Reyk Alencar	@		6e9f56bbe8a018f84a3231dde1ff51b0	t	2011-11-03 12:47:57.918802	2011-11-03 12:46:48.207189	1	1994-01-01	\N	f	reykalencar@live.com	t
529	Ray Alves dos Santos	ray28956522@gmail.com	Ray A'	@		924c0a77b9ea54dc82084e5ef43b1cc0	t	2011-11-03 20:50:07.775674	2011-11-03 20:43:13.199457	1	1993-01-01	\N	f	ray_ads@hotmail.com	t
1124	NILTON SILVEIRA DOS SANTOS FILHO	niltinhoconcurseiro@hotmail.com	Nilton	@		911ef240b3b393a7083fc243eda3e0f2	f	\N	2011-11-21 12:59:39.111531	1	1980-01-01	\N	f	niltinhoforrozeiro@hotmail.com	t
574	Karine Vasconcelos	karinevasconcellos.15@gmail.com	Karine	@		29c482d44b63462693ec919ae6c66054	t	2011-11-04 09:29:31.917956	2011-11-04 09:20:19.771775	2	1994-01-01	\N	f		t
478	alex da silva gonçalves	alex.d4.silva@gmail.com	alexdasilva	@		67c323dd1a915e3d789f50bec16b5f93	t	2011-11-03 09:29:29.436072	2011-11-03 09:25:36.091016	1	1995-01-01	\N	f		t
487	rafaela torres moraes	rafaela.torres.moraes@gmail.com	rafaelinha	@		a0456f963adab644714d2b8770896f61	f	\N	2011-11-03 09:29:35.340325	2	1995-01-01	\N	f		t
762	OLGA SILVA CASTRO	olga_kastro@hotmail.com	OLGA CASTRO	@olgascastro		f1ce484fd645f6fb196b7b8954c556b2	t	2012-01-10 18:26:26.228833	2011-11-11 21:19:28.154973	2	2011-01-01	\N	f	olga_kastro@hotmail.com	t
1001	PAULO HENRIQUE COUTO VIEIRA	phzinn@hotmail.com	Paulo Couto	@phzinncouto	http://www.facebook.com/phzinncouto	a404b0bef5a5db4c437b9e3e860effa4	t	2012-01-16 16:01:13.747906	2011-11-18 14:36:56.710654	1	1992-01-01	\N	f	phzinn@hotmail.com	t
1196	LUCIANO JOSÉ DE ARAÚJO	luciano_geo2007@yahoo.com.br	Luciano	@		561f9fbd1b07b3310bdbaa86b7d82995	t	2012-01-16 11:20:58.103582	2011-11-21 23:33:01.856965	1	1988-01-01	\N	f	luciano_geo2007@yahoo.com.br	t
784	Francisco Rafael Alves de Oliveira	thinodomas@hotmail.com	Rafa22	@drafael18	http://vampirerafa18.blogspot.com/	b03d5bc273bd671cea6b09d7780b55dd	t	2011-11-12 21:02:03.762902	2011-11-12 21:01:14.899389	1	1992-01-01	\N	f	thinodomas@hotmail.com	t
536	CAMILA DA COSTA	camilasousa172011@hotmail.com	camila	@		8effa82b05f5509e9f780e7ce7640094	t	2011-11-04 09:12:23.35954	2011-11-04 09:00:13.883409	2	1994-01-01	\N	f	camilasousa172011@hotmail.com	t
579	GEORGE GLAIRTON GOMES TIMBÓ	g3timbo@gmail.com	George	@		c6f94723f580ee11753560db05062266	t	2012-01-13 21:15:32.679804	2011-11-04 13:35:52.706198	1	1992-01-01	\N	f	g3timbo@gmail.com	t
582	Alexandre	alexandrekenpachimaster@gmail.com	Alexandre kenpachi 	@		984ac10ccb4ab9aa92a6929f3cc5ad1f	t	2011-11-04 22:05:52.042425	2011-11-04 21:49:16.158345	1	1992-01-01	\N	f	alexandrekenpachimaster@gmail.com	t
539	Priscila Luana Bezerra Araújo	priscilaluana.lba@gmail.com	zitrone	@		1e5f3f5ff2052c4a6292d3d6ee395d24	t	2011-11-04 09:11:34.156598	2011-11-04 09:00:38.209587	2	1994-01-01	\N	f	priscilaluana.lba@gmail.com	t
482	elisebety de sena lima	elisabetysena95@gmail.com	betinha	@		434b4fcb7d01109c7e73dd6154d567de	t	2011-11-03 09:35:30.878474	2011-11-03 09:28:10.331618	2	1995-01-01	\N	f		t
542	robson	robson.gospel@hotmail.com	robson	@		6a4d6a69ee8c47b2b7a2b1b46205ee20	f	\N	2011-11-04 09:00:46.916292	1	1992-01-01	\N	f	robson.gospel@hotmail.com	t
545	Daniele Souza de Araújo	danielesouzadearaujo@gmail.com	Daniele	@		e9de2f52bed2b78d46c9bf1e127dd897	t	2011-11-04 11:13:18.361311	2011-11-04 09:02:29.647025	2	1982-01-01	\N	f		t
589	Wendel Barros Vieira	wendel_bar@hotmail.com	Wendel	@		19879ef859ba3cee5907da2afb018aed	t	2011-11-07 15:24:19.992042	2011-11-07 15:21:30.734132	1	1983-01-01	\N	f		t
615	Reginaldo Patrício de Souza Lima	reginaldopslima@gmail.com	Reginaldo	@reginaldopslima		b5e1315f31f28d03281011403d5e6d5d	t	2012-01-15 17:48:56.66157	2011-11-07 23:30:57.064224	1	1990-01-01	\N	f	reginaldopslima@gmail.com	t
699	JOYCE SOARES DE ANDRADE	joycesoares.com@gmail.com	jojoyce	@joyce_seliga		334bde7ce55a0946f3dd0a1c723fb5c1	t	2011-11-10 21:04:09.351213	2011-11-10 20:54:31.473393	2	1992-01-01	\N	f	joycesoares.com@gmail.com	t
643	Lívya Thamara de Queiroz Feitosa	livya_feitosa5@hotmail.com	livyaa	@		2befc4f33a05a523343442a7e2c54cda	t	2011-11-08 23:53:04.960037	2011-11-08 23:43:05.268869	2	1991-01-01	\N	f	livya_feitosa5@hotmail.com	t
556	Shayllingne de Oliveira Ferreira 	ShayllingneOliveiraaa@Gmail.com	Liguelig	@		93b752f1a178025fdac4f9796618c874	f	\N	2011-11-04 09:06:47.924851	2	1990-01-01	\N	f		t
558	anderson	ndrsnmatias228@gmail.com	rock lee	@		52022df81a78d80e95e46ef418ebff23	t	2011-11-04 09:20:23.716293	2011-11-04 09:08:31.140453	1	1993-01-01	\N	f		t
754	lidiane de oliveira magalhaes	lidiane_anelove@hotmail.com	lidiane	@		fbf01f9c4203e8c01c6e92a382a6b87f	t	2011-11-16 21:52:11.603842	2011-11-11 17:46:48.241681	2	1997-01-01	\N	f	lidiane_anelove@hotmail.com	t
620	Leonardo pereira Vieira	leonardolp.92@gmail.com	leonardo	@		3a3c1581634ac5d69764eb7743a7b402	f	\N	2011-11-08 10:37:59.577255	1	1992-01-01	\N	f		t
560	Natalia Sousa de Melo	nathi_sousa@hotmail.com	Natthi	@		b54c225fb7a6787cc0b23bcb90dbeee1	f	\N	2011-11-04 09:09:17.964947	2	1992-01-01	\N	f		t
683	MICHELE VERAS DE SOUSA	meekaveras@hotmail.com	miKaos	@mikaveras		d9e76624a5713bc1f4019ed240adb7b9	f	\N	2011-11-10 13:56:58.597763	2	1990-01-01	\N	f	mikaveras@hotmail.com	t
623	José Willams Andrade de Sousa	willamsandradecdd@gmail.com	Willams Andrade	@		55e8c8de40f99fb5093d95f9f795935c	t	2011-11-08 12:21:56.798679	2011-11-08 12:05:08.336013	1	1998-01-01	\N	f	willams_andrade@hotmail.com	t
648	Francisco Joé Frota Melo	franciscojose_sf@hotmail.com	franze	@		d473018b14a22410c97a9bde9e99c9f7	t	2011-11-09 11:41:11.792159	2011-11-09 11:39:04.664045	1	1991-01-01	\N	f	franciscojose_sf@hotmail.com	t
763	Pedro Henrique	pedro.costa_ph@hotmail.com	Pedro Henrique	@	http://teste.freevar.com	c90dcb8a8eeea99f99987a7917e591ad	f	\N	2011-11-11 22:20:48.691619	1	1989-01-01	\N	f	pedro.costa_ph@hotmail.com	t
688	Lídia Maria Conde Gouveia	lidia.gouveia@hotmail.com	Lídia	@		c12aac01eead547ab502f86d9ee8b7b0	t	2011-11-10 21:47:24.448832	2011-11-10 15:31:13.522136	2	1994-01-01	\N	f	lidiapytty14@hotmail.com	t
628	Rafael Vieira Moura	tenshirafael@gmail.com	tenshirafael	@rafael___moura		0db6f4b2d10b6d4eb7b0c0f35f8895ef	t	2011-11-08 20:54:58.261449	2011-11-08 16:04:40.755645	1	1990-01-01	\N	f	tenshirafael@gmail.com	t
653	Francisca Elica Viana dos Santos	elicavianna@gmail.com	ariana	@		46b18f9e255a3cb63a3946d4f6c68886	f	\N	2011-11-09 11:46:33.682165	2	1993-01-01	\N	f	elicavianna@hotmail.com	t
1028	Anderson Monteiro de Oliveira	b.boyzek2hgoce@gmail.com	Zek Vox	@		560a18d59585afb731f852bdf11f8b8b	t	2011-11-18 20:34:36.459558	2011-11-18 20:26:38.198265	1	1986-01-01	\N	f		t
792	Jovane Amaro Pires	jovane.amaro.pires@gmail.com	Jovane	@_menino		d92fb86e22149d24bad0079612bb10a3	t	2011-11-13 11:37:38.97378	2011-11-13 11:34:32.666642	1	1992-01-01	\N	f	jovane.amaro.pires@gmail.com	t
657	lucas oliveira frança de melo	lukas-lin@hotmail.com	oliveira	@		a12818a98862b3d40c414bd4d815fc11	f	\N	2011-11-09 11:53:23.509128	1	1993-01-01	\N	f		t
1363	JEDERSON SECUNDINO DE ALMEIDA	jedersonsecundino@hotmail.com	JEDERSON	@		0802e9b570b5c9fed08c9a7432ebb3c0	t	2011-11-22 22:10:05.137938	2011-11-22 12:04:42.834263	1	1995-01-01	\N	f		t
705	Chrisley Oliveira Bessa	chrisley-lely@hotmail.com	Chrisinha	@		cabd2441077db9789af3348a21c469bf	t	2011-11-14 09:30:44.204494	2011-11-10 22:06:15.5592	2	1990-01-01	\N	f	chrisley-lely@hotmail.com	t
771	Sérgio Luiz Araújo Silva	voyeg3r@gmail.com	voyeg3r	@voyeg3r	http://vivaotux.blogspot.com/	a705e8e25fe8d9c1262e12da35baf779	t	2011-11-12 08:57:45.202063	2011-11-12 08:56:45.107155	1	1968-01-01	\N	f	voyeg3r@gmail.com	t
802	Atila da Silva Lima	atilasilvalima@gmail.com	atilasilvalima	@atilasilvalima		ef97c94397fae7cc6de2d5960a70298c	f	\N	2011-11-14 11:11:18.474779	1	1984-01-01	\N	f	atilasilvalima@gmail.com	t
519	isaias	isaiasjunior777@gmail.com	nii-chan	@		0a44608075cdc8e76a4039ec97bcb259	f	\N	2011-11-03 10:28:48.001368	1	1996-01-01	\N	f		t
520	leonardo	leonardosantos1016@gmail.com	leo1234	@		19264d862db0ff3b0c38e2193d1f8874	f	\N	2011-11-03 10:33:04.610397	1	1995-01-01	\N	f		t
525	Marcello de Souza	marcellodesouza@gmail.com	marcello	@marcellodesouza	http://www.treinolivre.com	83990a0938b2d01337b95d73158d575d	f	\N	2011-11-03 13:58:30.15612	1	1972-01-01	\N	f	marcellodesouza@gmail.com	t
432	LUIZ ALEX PEREIRA CAVALCANTE	alexofcreed@hotmail.com	Luiz Alex	@		f060117f2c77d2adee0cc4c9b8063418	f	\N	2011-10-25 21:42:01.887441	1	1988-01-01	\N	f	alexofcreed@hotmail.com	t
3348	AISSE GONÇALVES NOGUEIRA	aissegn@yahoo.com.br	AISSE GON�	\N	\N	ebfce94b4bfe188bfc82b4d775a8bffa	f	\N	2012-01-10 18:25:42.107677	0	1980-01-01	\N	f	\N	f
530	Isac Barros 	isactuf@hotmail.com	Isackim	@		9eef51cfc64f3a5d49a0df0c75bd89bd	t	2011-11-06 22:10:57.736693	2011-11-03 20:47:07.053619	1	1991-01-01	\N	f	luckzaki@gmail.com	t
443	LUIZ ROBERTO DE ALMEIDA FILHO	so.betog@gmail.com	Betinho	@		83a6a462b593aa21e1266cfb44465dd2	t	2012-01-16 21:46:11.433527	2011-10-29 01:53:03.321978	1	1989-01-01	\N	f	so.betog@gmail.com	t
522	FRANCISCA EVELYNE CARNEIRO LIMA	evelynelima_11@yahoo.com.br	Evelyne	@		e592c9c086ba71b4be4b8886709f9d3a	t	2011-11-03 12:09:36.706223	2011-11-03 11:43:03.320371	2	1994-01-01	\N	f	evelynelima_11@yahoo.com.br	t
1064	MAGNA MARIA VITALIANO DA SILVA	magnavitaliano@gmail.com	Magna Vitaliano	@Magna_rock8		0a1a259221a68e7de0ffedcc7163bfcd	t	2012-01-18 16:47:41.007689	2011-11-19 19:36:25.094327	2	1994-01-01	\N	f		t
1052	MAGNO BARROSO DE ALBUQUERQUE	mag.albuquerque@gmail.com	Magno Albuquerque	@		3de0e314d9c68a50e6f013390422b33e	t	2012-01-15 19:15:42.955862	2011-11-19 14:00:38.838496	1	1989-01-01	\N	f		t
3349	ALEXSANDRO DA SILVA FREITAS	www.alexsandroidilio@yahoo.com	ALEXSANDRO	\N	\N	dbe272bab69f8e13f14b405e038deb64	f	\N	2012-01-10 18:25:42.749558	0	1980-01-01	\N	f	\N	f
534	Michel	michel.barros94@hotmail.com	michel	@		23769b9881a6ca49588c0aa1f502a834	t	2011-11-04 09:10:53.969026	2011-11-04 08:58:35.785045	1	1994-01-01	\N	f	michel.barros94@hotmail.com	t
694	MAIKON IGOR DA SILVA SOARES	maikonigor@gmail.com	maikon igor	@maikonigor		c9e6ae4b8001603cceb85e461154e8b6	f	\N	2011-11-10 19:48:00.255734	1	1990-01-01	\N	f	maikonigor@gmail.com	t
575	robson	robsonoliveira.r@gmail.com	robson	@		69727fef27a967e0f67cfece8fd225b8	t	2011-11-04 09:31:59.45321	2011-11-04 09:20:22.006498	1	1992-01-01	\N	f	robson.gospel@hotmail.com	t
580	Robson William	robson.william65@hotmail.com	Robson William	@dattebayoRob		8c5b67109ac5f74e4e1e804206a696da	t	2011-11-04 15:17:50.404917	2011-11-04 15:11:48.004794	1	2011-01-01	\N	f	robson.william65@hotmail.com	t
3350	ALISSON DA SILVA OLIVEIRA	ifor070@terra.com.br	ALISSON DA	\N	\N	30f39aad6f0bb058ac003198e527b60d	f	\N	2012-01-10 18:25:43.05245	0	1980-01-01	\N	f	\N	f
537	Thiago Martins	thiago-santos-martins@hotmail.com	thiago	@		f77b420bd9aad1aa74aea845c74bcf68	f	\N	2011-11-04 09:00:19.464902	1	1994-01-01	\N	f	thiago-santos-martins@hotmail.com	t
584	Antonio Francisco Marques Freire	freiremarques@ymail.com	Tchê Marks	@		7d0da9020e588c410fe297ac9b83230d	f	\N	2011-11-04 22:25:26.472289	1	1990-01-01	\N	f		t
540	Daniel de Oliveira	Tidanielferreira@gmail.com	H-Hero	@		81c284532850b86e093041da19438424	t	2011-11-04 09:12:23.659606	2011-11-04 09:00:38.897489	1	1993-01-01	\N	f		t
543	antônio gregório brandão júnior	greg-jr2010@hotmail.com	junior	@		b0aa9b0ac2bfc0617a08d488d2e802bc	t	2011-11-04 09:18:31.235392	2011-11-04 09:01:21.990158	1	1990-01-01	\N	f		t
546	Thalis Jordy Gonçalves Braz	thalisjordygoncalves@gmail.com	TeeJay	@thalisjordy		e7f9cd650381ac3152366a2f3c73fbc7	f	\N	2011-11-04 09:04:02.119984	1	1994-01-01	\N	f	tj-braz@hotmail.com	t
678	Herbet Cunha	herbetSC@hotmail.com	Herbet	@HerbetCunha		6cd75893f207cbc0c0d43b583bf04688	t	2011-11-10 06:38:49.565104	2011-11-10 06:33:49.398151	1	1993-01-01	\N	f	herbetSC@hotmail.com	t
3351	ALISSON DO NASCIMENTO LIMA	alisson-nas@hotmail.com	ALISSON DO	\N	\N	e5cd56b5ba6c160ff03df15e4ca6a650	f	\N	2012-01-10 18:25:43.213861	0	1980-01-01	\N	f	\N	f
595	JUNIOR MENDES	fraciscomendes@bol.com.br	JUNIOR MENDES'	@		f7dd8281bd1cfa5392dd3e31e4311108	t	2011-11-07 18:22:36.398547	2011-11-07 18:18:49.387268	1	1993-01-01	\N	f	fraciscomendes@bol.com.br	t
851	Francisco Hítalo de Sousa Luz	htfsosite@hotmail.com	cabeça	@		1ae611550bc3b83d17fa218e88f87d0e	t	2011-11-16 09:27:08.156686	2011-11-16 09:24:36.857228	1	1995-01-01	\N	f	piveti20112011@hotmail.com	t
644	Ricardo Beiruth de Oliveira	ricardobeiruth@hotmail.com	Beiruth	@		31a8d39f6fbaa2f65783033d52c17701	t	2011-11-17 01:02:07.202733	2011-11-09 01:41:06.728352	1	1959-01-01	\N	f		t
619	Mayra Pontes de Queiroz	mayrapqueiroz@hotmail.com	Mayra Queiroz	@MayraQueiroz		ad26ed4323e3088c2a3638a0f1723144	t	2011-11-08 10:47:29.035796	2011-11-08 10:18:24.71656	2	1990-01-01	\N	f	mayrapqueiroz@hotmail.com	t
528	Edson Freire Caetano	edsonfreiredev@gmail.com	EdsonFreire	@edsonfreiredev		a9ff5e6d03a31a8a82bdcc2e99eb88a4	t	2011-11-08 12:06:33.66141	2011-11-03 17:30:12.204265	1	1991-01-01	\N	f		t
538	Natanael Pereira	natanaelgaita@yahoo.com.br	Natanael	@		665b935403c68c2bba15dd214816ed86	t	2011-11-04 09:09:26.788843	2011-11-04 09:00:28.544607	1	1995-01-01	\N	f	natanaelgaita@yahoo.com.br	t
562	Janderson da Silva Santos	jandersonovosom@gmail.com	Warrior Knife 	@		e7c65a0666f47e727b62bc7d39188684	t	2011-11-04 09:28:22.765717	2011-11-04 09:10:44.262546	1	1992-01-01	\N	f		t
700	ERINETE	tatidao@gmail.com	hoshi chan	@tsunda_hoshi		0d62bcfcb352985dbf03c88e35229449	t	2011-11-10 21:07:57.470482	2011-11-10 21:06:23.441666	2	1994-01-01	\N	f		t
2208	ary lima	aascville@gmail.com	deus da guerra	@		26deafca6b5dbeaeaca1cd95de72753c	f	\N	2011-11-23 21:13:27.274317	1	1987-01-01	\N	f		t
629	Haleckson Henrick Constantino Cunha	henrick_cc@yahoo.com.br	Haleckson	@haleckson		8f236742e7b8b8cfd24210978b1d22b6	t	2011-11-08 16:53:54.675877	2011-11-08 16:48:59.693111	1	1993-01-01	\N	f	henrick_cc@yahoo.com.br	t
649	Edivandro Guilherme dos SANTOS	vandinho.sud@hotmail.com	vandinho	@		7e4f7846abc379be4bc5347cf99d010a	f	\N	2011-11-09 11:40:11.286017	1	1972-01-01	\N	f		t
565	Daniel	danielguns1987@hotmail.com	Daniel	@		89924d64c86e44ff65cd28657a8e176c	f	\N	2011-11-04 09:12:50.572772	1	2011-01-01	\N	f		t
755	marilia Barreto	lika_barreto_cavalcante@hotmail.com	likacb	@		27207cb4878db52cc4df4374cb5cfb78	t	2011-11-11 18:44:08.296471	2011-11-11 18:42:21.736785	2	1995-01-01	\N	f	lika_barreto_cavalcante@hotmail.com	t
654	iury gomes da silva 	i.gomes10@hotmail.com	gaibú	@		70f326ea8ef860670d77046091fe04ab	f	\N	2011-11-09 11:46:34.505946	1	2011-01-01	\N	f		t
658	Bruno Augusto A da Silva	onurbsilva@hotmail.com	Bruno Alcântara 	@Onurb_Silva		0ffb94e7cc7b0cac8b1c66380c82ea95	t	2011-11-09 12:29:48.744186	2011-11-09 12:07:29.413866	1	1983-01-01	\N	f	onurbsilva@hotmail.com	t
684	Wilquemberto Nunes Pinto Pinto	wilkem.work@gmail.com	Wilkem	@		8dd47493461c884fa2b9d00af94c9ae0	t	2012-01-16 23:31:01.674089	2011-11-10 14:01:03.690978	1	1993-01-01	\N	f	wilquem_np@hotmail.com	t
785	Juan Cosmo da Penha	juanc.penha@hotmail.com	JuanCPenha	@		c4209047ee7906b86f24dadac00fd7ae	t	2011-11-12 22:44:24.688497	2011-11-12 22:35:30.261377	1	1993-01-01	\N	f	jcp.lei@hotmail.com	t
772	João Lucas Cruz Lopes	lucas_cruz.infor@yahoo.com.br	Lucas Cruz	@John_Luks		b7a1636edcaefd29497c019c45c7486d	t	2011-11-12 09:55:28.265208	2011-11-12 09:53:40.416148	1	1995-01-01	\N	f	lucas_cruz_530@hotmail.com	t
803	Francisco Thiago de Sousa Crispim	thiagoejovem@gmail.com	Thiago	@		c653afc16f7aa7f1216af4d7966699eb	t	2011-11-14 13:15:46.433653	2011-11-14 12:53:20.053551	1	1990-01-01	\N	f	thiagoscrispim@gmail.com	t
819	Alan Moreira Teixeira	alan_mt95@hotmail.com	Alan''  =D	@		51e2353677ec247d12ac65608eb73f20	t	2011-11-19 20:33:57.942658	2011-11-14 22:15:09.927311	1	1995-01-01	\N	f		t
1098	Carlos Kervin	kervin_goo@hotmail.com	Kervin	@KervinVI		a781d4c6fc432955bc2ec9db8f02d642	t	2011-11-21 09:30:02.209504	2011-11-21 09:21:49.882447	1	1995-01-01	\N	f	kervin_goo@hotmail.com	t
549	Jéssica	r_bd_j@hotmail.com	'jessy'	@JssicaB		741fedb304688937b77c0feba0f6d327	t	2011-11-04 09:12:53.808165	2011-11-04 09:04:23.60953	2	1994-01-01	\N	f	r_bdj@hotmail.com	t
585	ITALO DE OLIVEIRA SANTOS	italo_07_@hotmail.com	italo oliveira	@italo_07		9843ab9da9e79e94fceae533b9857265	t	2011-11-06 23:11:22.462178	2011-11-06 00:26:33.998035	1	2011-01-01	\N	f	italo_07_@hotmail.com	t
557	Thalis Jordy Gonçalves Braz	tj-braz@hotmail.com	TeeJay	@thalisjordy		d126207eadec477bd9f4d1460dd270c1	t	2011-11-04 09:13:31.510294	2011-11-04 09:06:59.439062	1	1994-01-01	\N	f	tj-braz@hotmail.com	t
577	Antonio Ailton Gomes da Silva	aagomes63@gmail.com	Ailton	@	http://ticnewszumbi.blogspot.com/	e769bdd3ddb981270f87545c38ee149f	t	2011-11-04 11:35:01.498039	2011-11-04 11:18:10.696052	1	1963-01-01	\N	f	aagomes63@gmail.com	t
564	Thiago Martins	thiagomartins444@gmail.com	thiago	@		fd264cc234e277072dba365ce3476bab	t	2011-11-04 09:15:11.056511	2011-11-04 09:12:13.389433	1	1994-01-01	\N	f	thiago-santos-martins@hotmail.com	t
550	junior	diisalesjunior@gmail.com	yudiii	@		92837e9e5a53dc97ee4d079d0e26b98f	t	2011-11-04 09:15:04.939884	2011-11-04 09:04:28.48115	1	1993-01-01	\N	f		t
425	MANOEL ALEKSANDRE FILHO	aleksandref@gmail.com	Lex Aleksandre	@aleksandre	http://debianmaniaco.blogspot.com	4e90d6fe6bca1758146a378f7b79223a	t	2012-01-10 18:26:24.340552	2011-10-24 14:57:56.38271	1	1974-01-01	\N	f	aleksandref@gmail.com	t
398	MARCOS PAULO LIMA ALMEIDA	marck_migo@hotmail.com	M.Paulo	@		4556c0f57577b07acabb177725d9b909	t	2012-01-16 17:34:49.106925	2011-10-20 18:18:22.577374	1	1991-01-01	\N	f	marck_migo@hotmail.com	t
563	José Raimundo de Araújo Neto	neto0147@hotmail.com	neto0147	@		afe43989b8bb2b1b51acf5d61c387320	t	2011-11-24 11:21:44.68811	2011-11-04 09:10:44.806262	1	1992-01-01	\N	f	neto0147@gmail.com	t
824	MARIA CAMILA ALCANTARA DA SILVA	camila.ca27@gmail.com	CAMILA ALCANTARA	@		bae18e916bdd91af9f6df7b65c68f870	t	2012-01-17 09:29:38.646835	2011-11-15 09:57:48.587851	2	1992-01-01	\N	f	camila.ca27@gmail.com	t
1079	MARIA IZABELA NOGUEIRA SALES	iza-nogueiira@hotmail.com	Izabela	@iza_alone		b49dcddff16509fc5ca1520c569ab60a	t	2012-01-15 23:05:58.858861	2011-11-20 14:36:14.809742	2	1992-01-01	\N	f	iza-nogueiira@hotmail.com	t
591	Edson Gustavo de Freitas Queiroz	gustavotecno1@hotmail.com	Crash@	@		259179fddc7a425b06e6e99d4c860c58	t	2011-11-07 16:43:57.204917	2011-11-07 16:41:34.203561	1	1990-01-01	\N	f	ed-queiroz@hotmail.com	t
612	edson da silva	gallgml@hotmail.com	edsongall	@		11f9ae1dd040f1b37718234d28f03f34	t	2011-11-07 21:53:28.84569	2011-11-07 21:50:44.369926	1	1992-01-01	\N	f	gallgml@hotmail.com	t
679	Flávio Dias	flaviodiasd@gmail.com	Flávio Dias	@phlaviodiasd		38484a971e96ba7065661c2f5912e8e7	t	2011-11-10 09:47:53.005936	2011-11-10 09:40:47.235808	1	1990-01-01	\N	f	flaviodiasd@gmail.com	t
596	João Raphael Silva Farias	metal.raphael@gmail.com	Raphael Farias	@	http://www.youtube.com/user/metalraphael	da6401d315eb7fc696180b9b679d3668	t	2011-11-07 18:42:34.115569	2011-11-07 18:36:49.532318	1	1987-01-01	\N	f	metal.raphael@gmail.com	t
756	adeline louise	adeline.12@hotmail.com	deline	@		461e872ac53573f6040494bb84c71d3a	f	\N	2011-11-11 18:46:39.437575	2	1995-01-01	\N	f	adeline.12@hotmail.com	t
617	Ingrid Ruana Lobo E Silva	ingrid.ruanna@gmail.com	Flávia	@		53f54c2789ec0799a31b66541d31ed34	t	2011-11-08 08:13:48.081422	2011-11-08 08:07:30.989561	2	1993-01-01	\N	f	ingrid-poderosa@hotmail.com	t
645	Herculano Filho	herculanogfilho@yahoo.com.br	Laninho	@herculanogfilho		9b0529a36ec6f3e3badc52095a7620de	f	\N	2011-11-09 09:30:30.28339	1	1989-01-01	\N	f	laninho_boyy@yahoo.com.br	t
621	Eduardo Costa Rafael	edudunove@hotmail.com	edudunove	@		d76af5c647077d3f8593b7163294f64b	f	\N	2011-11-08 11:56:06.009774	1	1982-01-01	\N	f		t
786	Thayanne de Sousa Ribeiro	taya_sousa@hotmail.com	ThaTah	@ThaTah_XD		9ca32378bfc3576855e81773d07bc9ce	t	2011-11-12 23:10:38.881953	2011-11-12 23:09:16.904175	2	1993-01-01	\N	f	taya_sousa@hotmail.com	t
319	Halina Alves de Amorim	hallina_taua@hotmail.com	nininha	@		b70bd724d1efb8b2acfd8414732295cf	t	2011-11-08 12:08:41.810528	2011-10-14 20:15:33.255429	2	1989-01-01	\N	f	hallina_taua@hotmail.com	t
650	Douglas Rodrigues Albuquerque da Silva	awakeh3@hotmail.com	waking	@		8c983f2eb590628dcf67ed2487e21ec0	f	\N	2011-11-09 11:40:27.692116	1	1991-01-01	\N	f		t
935	Iken Jander Damasceno Santos	guerreiroaraucano@hotmail.com	Sir. Iken	@		c11fa255d0a3fe7b1d16a62ead3a7624	t	2011-11-21 02:00:40.711559	2011-11-16 19:14:55.867871	1	1987-01-01	\N	f	guerreiroaraucano@hotmail.com	t
630	Luciana Sá de Carvalho	lucianasa.jc@hotmail.com	Luciana	@luciana_sa		09cb3ef7025f04a4f85a05d1e21e021e	f	\N	2011-11-08 18:49:38.907203	2	1984-01-01	\N	f	lucianasa.jc@gmail.com	t
633	Arnóbio Inácio Ferreira Lima	nobsaga@hotmail.com	Nob Saga	@nobsaga		f26a5cb2f00c08524db9215111e34ecf	t	2011-11-08 19:45:45.987587	2011-11-08 19:38:40.901959	1	1984-01-01	\N	f	nobsaga@hotmail.com	t
655	Daniel Soares da Rocha	daniel.soares7@hotmail.com	Daniel	@		a053fe566cd089eadc3b7570539a1368	f	\N	2011-11-09 11:52:38.159471	1	1988-01-01	\N	f	polvilho.cebolinha@hotmail.com	t
659	Charliane Costa de Almeida	charlianecostafdj@gmail.com	Charly	@		77397b4be7ffa187686976e6dfdd9712	t	2011-11-09 13:49:05.22236	2011-11-09 13:33:16.954128	2	1991-01-01	\N	f		t
685	Dalila de Alencar Lima	dalila_alencar_lima@hotmail.com	Dalila	@		911591e2a9576781f85bb03d5bb3165a	t	2011-11-10 14:13:16.315094	2011-11-10 14:06:24.605524	2	1993-01-01	\N	f	dalila_alencar_lima@hotmail.com	t
761	Hadriel Lima	hadriellimah@gmail.com	Limahhadriel	@limahhadriel		de6dcb32ce9e2658f9eca30e309a6a34	t	2011-11-12 10:39:38.925331	2011-11-11 21:17:26.592269	1	1995-01-01	\N	f		t
660	Mateus Irving	mateus.irving@gmail.com	Chuck Norris Jr	@mateusirving1	http://sige.comsolid.org/participante/add	967ffcd6a41e0813701cdefe97092ec9	f	\N	2011-11-09 14:25:47.787844	1	1995-01-01	\N	f	mateusirvingdemoraes@gmail.com	t
714	lucas cavalcante de queiroz	lucaseuacreditoemdeus@hotmail.com	lukinhas	@		658027ae78b4574757136d54b6d04686	f	\N	2011-11-10 22:12:24.234612	1	1994-01-01	\N	f	lucaseuacreditoemdeus@hotmail.com	t
693	Mateus Nascimento dos Santos	negodossantos_13@hotmail.com	black ops	@		43d9eeed1c141805cee4301bcca6415e	f	\N	2011-11-10 17:40:10.244946	1	1994-01-01	\N	f		t
717	Maurilio Bandeira	maurilio.naruto@hotmail.com	Maurilio	@		c509fcbe063336208151d24cc3374903	f	\N	2011-11-10 22:14:05.686324	1	1993-01-01	\N	f		t
777	Wilderson de Azevedo Marreiro	wildersonazevedo@yahoo.com.br	Wilre'z	@		a38189ca864e2bc44e05404f8f457355	t	2011-11-13 00:16:36.226486	2011-11-12 15:03:57.68827	1	1995-01-01	\N	f	wildersonazevedo@yahoo.com.br	t
804	Saulo de Oliveira Ribeiro	saulo95sor@gmail.com	Saulueh	@		d5ebfc62dca1f2dd70c74e8a737bff25	f	\N	2011-11-14 13:30:40.347024	1	1995-01-01	\N	f	saulo_phantom@hotmail.com	t
1072	FRANCISCO JOSÉ MARTINS MACHADO FILHO	franciscojose.filho@hotmail.com	FRANZÉ	@fj_filho		74aa65376d1755043d3e30af036706d7	t	2011-11-20 02:00:33.175994	2011-11-20 01:57:21.626785	1	1993-01-01	\N	f	franciscojose.filho@hotmail.com	t
715	Thiago Carvalho Walraven da Cunha	thiagowalraven@hotmail.com	Thiago Walraven	@		49e47578ca21ed280eece9d2ad6f4c1f	t	2011-11-10 22:15:53.310769	2011-11-10 22:13:14.845476	1	1995-01-01	\N	f	thiagowalraven@yahoo.com.br	t
793	Mayra  Cavalcante Barreto	may.ra.13@hotmail.com	Mayra Barreto	@		2a1bbaadce37b90f9e0439ba31d935b8	t	2011-11-13 11:39:36.584577	2011-11-13 11:36:35.813673	2	1993-01-01	\N	f	may.ra.13@hotmail.com	t
811	FRANCISCO JANAEL COELHO	mello_bds@hotmail.com	Luciano Melo	@		b87473608776f148a91f19114134a83c	t	2011-11-15 21:59:40.773612	2011-11-14 16:57:16.030114	1	1992-01-01	\N	f		t
823	Josberto Francisco Barbosa Vieira	josberto.esperanto@gmail.com	Josberto	@		99fc42c3079e227b4d7d5822e47d3295	t	2011-11-15 10:25:38.095785	2011-11-15 09:57:43.104724	1	1978-01-01	\N	f		t
1030	andresa clarice gomes de sá	andresagomes14@hotmail.com	andresa	@		00e8ae679e40cd01065c5f6662782d55	f	\N	2011-11-18 20:47:42.051939	2	1997-01-01	\N	f		t
569	Daniel	danielguns1987@gmail.com	Daniel	@		5adefd7902500b71bc2b78ec0cee507c	t	2011-11-04 09:27:40.205384	2011-11-04 09:15:58.804283	1	1994-01-01	\N	f		t
581	Hélio	kurosaki1@hotmail.com	Hélio Lee	@		1ce08439531cf49f7cc1636841e8a40b	t	2011-11-04 21:53:11.799292	2011-11-04 21:48:41.64616	1	1987-01-01	\N	f		t
573	João Rodrigues Santos Filho	johnnyklink@hotmail.com	KlinkLoafer	@		1cbece43e60462c471623cd266bbc19e	f	\N	2011-11-04 09:19:38.557883	1	1994-01-01	\N	f	johnnyklink@hotmail.com	t
561	francisco	paulo.bands@hotmail.com	neguim	@		5a88fbab1d1ac3ebd2313377ca2f219f	t	2011-11-04 09:16:38.805873	2011-11-04 09:09:37.161904	1	1989-01-01	\N	f	paulo.bands@hotmail.com	t
1134	MARIA SIMONE PEREIRA CORDEIRO	simonemanda@hotmail.com	simone	@		9007aa3e1fe3b30e09b40a3be25bed3c	t	2012-01-20 11:33:30.641033	2011-11-21 15:17:35.148062	2	1975-01-01	\N	f	simonemanda@hotmail.com	t
424	MAXSUELL LOPES DE SOUSA BESSA	iniciusx@gmail.com	Inicius	@		79b82cb2386c8bcffdb5290154ccab73	f	\N	2011-10-24 13:11:46.091424	1	2011-01-01	\N	f	iniciusx@gmail.com	t
597	Emanuely Jennyfer	emanuelyjennyfer@gmail.com	emadinny	@		1e855d841574ae2cc4cda5400c1b4675	t	2011-11-13 18:24:19.571087	2011-11-07 21:41:59.636901	2	2011-01-01	\N	f	emanuelyjennyfer@gmail.com	t
467	MAYARA FREITAS SOUSA	mayara_rebeldemia12@hotmail.com	MAYARA	@		8c45740cf4da30af77169bf8c09d6f56	t	2012-01-10 18:26:25.27822	2011-11-02 17:34:21.592705	2	1994-01-01	\N	f	mayara_rebeldemia12@hotmail.com	t
578	Núcleo de Tecnologia Educacional de Maracanaú	ntmmaracanau@gmail.com	NUTEM Maracanaú	@	http://ntmmaracanau.blogspot.com/	d0c14d7666601f351d5d113814615b19	t	2011-11-04 11:33:30.918787	2011-11-04 11:21:55.7866	1	2008-01-01	\N	f	ntmmaracanau@gmail.com	t
632	JULIANA LIMA GARÇA	julianagarca@gmail.com	Juh Yuki	@JuhYuki		fc3e11e239d064e906eacec81a7d9355	t	2012-01-15 17:59:21.018796	2011-11-08 19:33:05.281306	2	1990-01-01	\N	f	juliana_yuki@hotmail.com	t
3353	AMANDA DIOGENES LUCAS	manda_zita@hotmail.com	AMANDA DIO	\N	\N	ede7e2b6d13a41ddf9f4bdef84fdc737	f	\N	2012-01-10 18:25:43.586899	0	1980-01-01	\N	f	\N	f
325	JULIANA PEIXOTO SILVA	juliana.compifce@gmail.com	Juliana	@		0cd399de1e1e05b97a836a1fb83f79ba	t	2012-01-16 21:36:23.451752	2011-10-15 09:43:24.296862	2	1986-01-01	\N	f	juliana_1945@hotmail.com	t
472	Hewerson Alves Freitas	hewerson.freitas@gmail.com	Hewerson	@hewersonfreitas	http://www.falaqueeucodifico.blogspot.com	3a05961d450c4065f8996d0b70bfd208	t	2011-11-04 17:06:54.253976	2011-11-02 20:24:46.441408	1	1990-01-01	\N	f	h_alvesf@yahoo.com.br	t
634	Caroline Sandy Rego de Oliveira	caroline-sandy@hotmail.com	Caroll	@		d5803a3fec88de7eba4f8a9e2dc03146	f	\N	2011-11-08 20:21:52.105949	2	1993-01-01	\N	f	caroline-sandy@hotmail.com	t
805	Débora Valéria Nascimento Gomes	debora_valeria01@hotmail.com	Débora	@		24f4d30d328526ee4a7591527a6e01e2	f	\N	2011-11-14 14:12:19.271793	2	1994-01-01	\N	f	debora_valeria01@hotmail.com	t
680	Cinthya Maia Alves	cinthyahw@gmail.com	ciicyhw	@		19a4613843ff7170468b3b7f8aa7790b	f	\N	2011-11-10 10:27:41.421935	2	2011-01-01	\N	f	cinthyahw@gmail.com	t
613	FRANCOES DA SILVA PEREIRA	franssuar.silva@gmail.com	Franssuar	@		5dc15c7c37c3bbdb53899e32966b0f29	t	2011-11-08 14:45:27.889625	2011-11-07 22:39:08.936244	1	1985-01-01	\N	f		t
618	Vanderlucia Rodrigues da Silva	vanderluciarodrigues@yahoo.com.br	Vander	@		3295f6b26406d26f426db7381608e1b8	t	2011-11-08 09:09:54.783719	2011-11-08 09:07:48.604479	2	1977-01-01	\N	f	vanderluciarodrigues@yahoo.com.br	t
1258	Amanda Patricia Coelho da Silva	amanda_28@hotmail.com	Amanda	@		5c94e615c15532e742445403467b2db6	f	\N	2011-11-22 09:44:14.516413	2	1994-01-01	\N	f		t
757	Júlio César Baltazar Alves	juliocesar.jcba@gmail.com	julio cesar	@		cb1ec00a12e8207ccd2a23496715b218	t	2011-11-11 18:50:56.937558	2011-11-11 18:50:07.611007	1	1995-01-01	\N	f	juliocesar.jcba@gmail.com	t
622	Eduardo Costa	eduardocosta@marquise.com.br	Edu Costa	@		d431895bc1bdc7f4a59729428dd15570	t	2011-11-08 11:59:21.812452	2011-11-08 11:57:43.759863	1	1982-01-01	\N	f		t
686	Francisco Halesson de Menezes Araujo	halessonmenezes0@gmail.com	massive	@		7219af9bfec2b35c35c12c7aadbcf689	f	\N	2011-11-10 14:09:21.84055	1	1995-01-01	\N	f	halessonmenezes0@gmail.com	t
608	Maria Pamela Viana Monte	pamelamaria.vianamonte252@gmail.com	pamela	@maria_mela		b2dbb4081aa0120cba33983c0ad6d700	t	2011-11-08 13:11:38.774179	2011-11-07 21:47:43.607825	2	1997-01-01	\N	f	pamaria@hotmail.com	t
1364	FRANCISCO FELIPE MOREIRA SOUSA	felipetms_1202@hotmail.com	FELIPE	@		82bd0d093c2f6c1c0f43e752bbf2c4dc	f	\N	2011-11-22 12:06:10.826805	1	1995-01-01	\N	f		t
627	JONAS OTHON PINHEIRO	othon.jp@gmail.com	OTHON00	@othon_jp		e0d9d3976e0170b98e2652016c08f571	t	2011-11-08 16:08:43.063241	2011-11-08 15:50:37.98393	1	1993-01-01	\N	f	othon.jp@gmail.com	t
1170	Francisco Ivan de Oliveira	ivan_ufc@yahoo.com.br	Ivan de Oliveira	@ProfIvan13		21099adb0aab9a6f2cafba3556078731	t	2011-11-21 20:48:38.465004	2011-11-21 20:42:55.864938	1	2011-01-01	\N	f	ivan_ufc@yahoo.com.br	t
787	DIEGO ARAUJO PEREIRA	diegoaraujpereira@gmail.com	Yusuki	@diego_yusuki		35845433b60d03ba7948c6b54dbbe249	f	\N	2011-11-13 00:51:13.360127	1	1991-01-01	\N	f	diegoyusuki@gmail.com	t
690	tayná rayssa lima araujo	tayna1931@live.com	Tupizinha	@		2844af164ac771f0b10ac90fb52c8d46	f	\N	2011-11-10 17:14:31.999751	2	2011-01-01	\N	f	tayna15love@hotmail.com	t
1374	Aretha Vieira Magalhaes	arethahta29@hotmail.com	aretha	@		bee676d0eef528e1109007b38796ef49	f	\N	2011-11-22 12:48:37.970656	2	1994-01-01	\N	f		t
651	Aglair Silvia Alcântara Dos Santos	aglairsantos@gmail.com	Aglair	@		d644a9e83420beca1a80cc5ffaad50a6	f	\N	2011-11-09 11:41:12.756833	2	1975-01-01	\N	f		t
773	phelipe wesley	phelipe_cloude@hotmail.com	wesley	@		02d4e29f333492808993479cf2f22c09	t	2011-11-12 12:37:30.211161	2011-11-12 12:35:46.54492	1	1991-01-01	\N	f		t
656	Jefferson Miranda de Souza	jmirandasouza2010@bol.com.br	Jefferson	@		48e902a5a53cf2257490d33d5f8e67bd	f	\N	2011-11-09 11:52:45.68485	1	2011-01-01	\N	f	jmirandasouza2010@bol.com.br	t
426	PAULO BRUNO LOPES DA SILVA	paulobruno.ls.fr@gmail.com	paulobruno	@_paulobruno_		a6dce770e89c4a77df57387bcc84d710	t	2011-11-09 14:17:20.022674	2011-10-24 15:07:49.15197	1	1990-01-01	\N	f	paulin_15@hotmail.com	t
708	luiz felipe de oliveira ferro	felipe.ferro2@hotmail.com	luiz felipe	@		484ef1527dcbb64856a127f564fd1a48	t	2011-11-10 22:12:57.68768	2011-11-10 22:09:59.944754	1	1994-01-01	\N	f	felipe.ferro2@hotmail.com	t
3355	AMSRANON GUILHERME FELICIO GOMES DA SILVA	amsranon.ag@hotmail.com	AMSRANON G	\N	\N	6ea2ef7311b482724a9b7b0bc0dd85c6	f	\N	2012-01-10 18:25:43.861558	0	1980-01-01	\N	f	\N	f
712	Darling Oliveira Ferro	darling_oliveira@hotmail.com	Darling	@		f725318eab1ed1d133af59112c5e119c	t	2011-11-10 22:13:28.438642	2011-11-10 22:11:30.934717	1	1988-01-01	\N	f	darling_oliveira@hotmail.com	t
794	Rodrigo de Lima Silva	rodrigo.lima.sti@gmail.com	Rodrigo	@		3c80940a28a16cf79e19f231b27d820c	t	2011-11-13 12:43:54.524464	2011-11-13 12:38:33.163035	1	1991-01-01	\N	f	rodrigo.lima.sti@gmail.com	t
778	Antônio Carlos	carlos@e-deas.com.br	Carlinhos Gileade	@carlosgileade	http://www.e-deas.com.br	a90e670143eb9a30201a15ccb56bc1f8	f	\N	2011-11-12 15:48:38.675697	1	1993-01-01	\N	f		t
783	Antonio Wallace Neres da Silva	wallace_neres@yahoo.com.br	Wallace	@		0f6563df073373614662e9f4767db23d	t	2011-11-14 18:18:06.963531	2011-11-12 20:59:17.537433	1	1990-01-01	\N	f	wallace_neres@yahoo.com.br	t
853	mario ricardo	nicolalau@hotmail.com	harry potter	@		c1e11644509dd3e18578b3ded41cfa47	t	2011-11-16 10:37:27.113621	2011-11-16 10:28:31.370572	1	1994-01-01	\N	f		t
936	Sebastião widson	Diwdi@hotmail.com	Widson	@Wid_lopes		1b2bcfd313498eef38f7e6fbdfec2585	f	\N	2011-11-16 20:58:14.03243	1	1995-01-01	\N	f	Diwdi@hotmail.com	t
1031	Danel Victor Almeida do Nascimento	danielvictor_hp_dan@hotmail.com	Dan'Boy	@DanielVictor08		fb27c1b9b5fbd9ef7ffc42d2950eb10c	f	\N	2011-11-18 20:52:52.042486	1	1992-01-01	\N	f	danielvictor_hp_dan@hotmail.com	t
663	Mateus Irving	mateusirvingdemoraes@gmail.com	Mateus	@		e038aa6b7cbed85b201bcd8e51c81b0f	t	2011-11-09 14:40:06.191024	2011-11-09 14:28:55.521327	1	1995-01-01	\N	f	mateusirvingdemorase@gmail.com	t
662	Kévin Allan Sales Rodrigues	kevin.allan.sales@hotmail.com	kevinn	@		e28e9b2242e579f40bc78d08628c7297	t	2011-11-09 14:35:20.990781	2011-11-09 14:27:38.386021	1	1994-01-01	\N	f		t
1179	KAILTON JONATHA VASCONCELOS RODRIGUES	kailtonjonathan@hotmail.com	RolfScar	@BlackMageRolf		2330dc01f856fed2595a8c0a4d299312	t	2012-01-10 18:26:19.256245	2011-11-21 22:01:22.003839	1	1993-01-01	\N	f	kailtonjonathan@hotmail.com	t
3356	ANA BÁRBARA CRUZ SILVA	babi_anahi2@hotmail.com	ANA BÁRBA	\N	\N	d96b7e705cef90b079a8b73129fad206	f	\N	2012-01-10 18:25:43.999787	0	1980-01-01	\N	f	\N	f
703	Jocieldo do Nascimento Abreu	jocieldo-hiphop@hotmail.com	Street	@jocieldo_		634d98ffd35539553a0c0380e2896ccd	t	2011-11-10 22:07:26.655388	2011-11-10 22:05:37.256118	1	1992-01-01	\N	f	jocieldo-hiphop@hotmail.com	t
2209	Antonio Alberto Silva Souza	albertojjnvu@gmail.com	Alberto	@		95e4a5cecfb9948f63b177424f716494	f	\N	2011-11-23 21:14:02.224414	1	2011-01-01	\N	f	albertojjnvu@gmail.com	t
1097	KAIO HEIDE SAMPAIO NOBREGA	kaio.heide@gmail.com	Kaio '-'	@kaioheide		8d945d7bf288a8561fc4dc55c193e622	t	2012-01-16 00:24:44.004527	2011-11-21 09:15:53.279655	1	1993-01-01	\N	f	bladerwarriorangel@hotmail.com	t
669	Felipe dos Santos Alves	felipe_santos_9@live.com	Felipe	@FelipeSantos		9e3c47f4c278670c023c9abb09e4daae	f	\N	2011-11-09 14:42:19.997088	1	1995-01-01	\N	f	felipe_santos_9@live.com	t
3357	ANA FLÁVIA CASTRO ALVES	ilifinivai@gmail.com	ANA FLÁVI	\N	\N	cdb902eab5c00651ede9072ae2f1c26d	f	\N	2012-01-10 18:25:44.730579	0	1980-01-01	\N	f	\N	f
323	KAUÊ FRANCISCO MARCELINO MENEZES	kaue.menezes191@gmail.com	Kauê Menezes	@_kauemenezes		7c6a81a8a055674e44b128673e6dcb4c	t	2012-01-17 23:44:11.142311	2011-10-15 00:01:28.109928	1	1991-01-01	\N	f	kaue.menezes191@gmail.com	t
670	Carlos Henrique Silva Sales	chss.ce@gmail.com	Henrique	@henriquepardal		d2ce5c875e55ffaf46b45b463615498b	t	2011-11-09 19:40:38.80518	2011-11-09 18:55:07.846336	1	1981-01-01	\N	f	chss.ce@facebook.com	t
1365	HIANDRA RAMOS PEREIRA	hiandra_ramos@hotmail.com	HIANDRA	@		3f1aabc3dbb3276eb67118e90d873ec9	f	\N	2011-11-22 12:08:33.91252	2	1995-01-01	\N	f		t
671	Jean Gleison Andrade do Nascimento	jandradenascimento@gmail.com	jnascimento	@		ad682987640b7300eac0ef577a55f248	t	2011-11-09 19:13:40.788869	2011-11-09 19:10:19.824234	1	1986-01-01	\N	f	jandradenascimento@gmail.com	t
1626	Rúben Alves	rubenlobao@gmail.com	Lobão	@		13782ca2d6d36f66c5c9bf683e00c82f	f	\N	2011-11-22 20:32:23.271203	1	1995-01-01	\N	f		t
687	Thiago Lucas de Souza Pinheiro	thiagopanic@hotmail.com	T.Lucaas	@		a808c9d90b95231922ec5112ba0cea24	f	\N	2011-11-10 14:11:35.459129	1	1994-01-01	\N	f		t
788	Daniel Ferreira de França	daniel.fer1992@hotmail.com	.Bilu.	@		d7c624cabe7fa6e9613968f043cde57b	f	\N	2011-11-13 04:16:35.003953	2	2011-01-01	\N	f		t
986	Keliane da Silva Santos	Kellyane-pink@hotmail.com	Kellynha	@		f3674879f5e18c7989e02235da302cc9	t	2011-11-17 22:20:20.679821	2011-11-17 22:10:41.974482	2	1997-01-01	\N	f		t
695	tayná rayssa lima araujo	tayna15love@hotmail.com	Rayssa	@		0544a0ce3ea0becff9d4c018900ddf1c	t	2011-11-17 09:21:45.629369	2011-11-10 20:06:06.59623	2	1996-01-01	\N	f	tayna15love@hotmail.com	t
713	Maurilio Bandeira	maurilio.naruto057@gmail.com	Maurilio	@		baf25364f35b97b7324dac48ee1cb2ef	t	2011-11-10 22:21:59.9087	2011-11-10 22:11:44.610832	1	1993-01-01	\N	f		t
3359	ANDERSON DE SOUZA GABRIEL PEIXOTO	andersonpeixoto1@live.com	ANDERSON D	\N	\N	c74e6b44efa5a7bc52c79c5994dbf023	f	\N	2012-01-10 18:25:45.313767	0	1980-01-01	\N	f	\N	f
2136	FRANCISCO JARDEL SOUSA PINHO	jardel.sousa346@gmail.com	JARDEL	@		1c79a38e392864f8bd878146014bcdbb	f	\N	2011-11-23 18:08:01.551835	1	1994-01-01	\N	f		t
774	Rafael Duarte Viana	rafaelviana@fisica.ufc.br	Rafael Duarte	@		d8319e266782cf989e4d4d3a2dde6702	t	2011-11-12 13:36:16.115842	2011-11-12 13:17:27.947032	1	1987-01-01	\N	f		t
706	jociele 	jociele12_@hotmail.com	Ciele Neves	@ciele_neves		7cc95c1f63909371dc717e10812301fa	t	2011-11-10 22:14:30.332329	2011-11-10 22:07:11.591121	2	1995-01-01	\N	f	jociele12_@hotmail.com	t
806	PAMELA	pamela.pinheiro91@gmail.com	PÂMELA	@		f659a2a7e7c67dbf9ca95ab37a76de47	t	2011-11-14 14:58:15.671278	2011-11-14 14:51:44.816085	2	1991-01-01	\N	f	pamela-pinheiro91@hotmail.com	t
795	MARIA VALDENE PEREIRA DE SOUZA	mvps23@hotmail.com	VAL....... 	@		364a813c7e1a8e8d2eaaebc1c9e8bba1	t	2011-11-13 14:09:35.379783	2011-11-13 14:08:34.778389	2	1987-01-01	\N	f	mvps23@hotmail.com	t
779	Isabelle Lopes Severiano	isabelleseveriano@gmail.com	belinha	@		300b01445ffc8ce2b699262c6e6a31eb	f	\N	2011-11-12 15:52:28.064158	2	1993-01-01	\N	f		t
992	Francisco Diego Lima Moreira	diegu.moreira@hotmail.com	Diego Moreira	@diegumoreira		7688146908b830df124d8e2d7df87458	t	2011-11-18 00:42:42.811361	2011-11-18 00:37:31.893925	1	1993-01-01	\N	f	diegu.moreira@hotmail.com	t
1032	camilla souza albuquerque	camylla1414@hotmail.com	camilla	@		81ecbbd73c3b8029f371643e6d67d8c0	f	\N	2011-11-18 21:04:35.313498	2	1996-01-01	\N	f		t
728	jose ivanilson cordeiro almeida junior	jicajunior@yahoo.com.br	junior	@		557725f5add906a1f2c6a3767c61905e	f	\N	2011-11-10 22:20:58.447112	1	1994-01-01	\N	f	ivanjunior_james@hotmail.com	t
701	thiago jose dos santos ferreira 	thiagojose94@hotmail.com	thiaguinho	@		bb8bebaebc99ea4c9f8b26b29622b958	t	2011-11-10 22:21:07.242776	2011-11-10 22:03:47.038967	1	2011-01-01	\N	f		t
719	Julia Suellen Vieira Monteiro	juliasuellen@hotmail.com	Juh Monteiro	@juhVmonteiro		3818c1b2c54782b714194b30806e2ced	t	2011-11-10 22:22:02.815404	2011-11-10 22:14:54.681301	2	1994-01-01	\N	f	juliasuellen@hotmail.com	t
710	Jéssica Santos de Araujo	jessika_kitinha@hotmail.com	Jéssica	@4raujo		c79a7de4d1cba01a9c8ce302082bfa04	t	2011-11-10 22:22:17.751882	2011-11-10 22:10:24.274188	2	1995-01-01	\N	f	jessika_kitinha@hotmail.com	t
729	Thiago Oliveira Sá	thsoliveirasa@gmail.com	thiagão	@		cd3c8c984192a295e0f5603861aaccd1	t	2011-11-10 22:24:10.938716	2011-11-10 22:22:27.559247	1	1992-01-01	\N	f	thsoliveirasa@gmail.com	t
1073	Marcelo Melo	marcelolaranjeira@hotmail.com	Marcelo	@marcelorange	http://arduino-ce.blogspot.com/	c5da6ab2a2520d06af83668d0e064640	t	2011-11-20 07:58:16.134394	2011-11-20 07:56:31.226792	1	1979-01-01	\N	f	marcelolaranjeira@hotmail.com	t
722	Adolfo Alves da Silveira	adolfoalves_@hotmail.com	Adolfo	@		d0907393795d7e92f2e9d9fb29dcd460	t	2011-11-10 22:27:51.57786	2011-11-10 22:16:29.515945	1	1994-01-01	\N	f	adolfoalves_@hotmail.com	t
825	Dêmora Bruna	bruna.seliga@gmail.com	Dêmora Bruna	@dbruna_sousa		06f44ad56ed4df752ba2ee751a86c095	t	2011-11-15 10:04:06.482481	2011-11-15 10:03:32.80333	2	1992-01-01	\N	f	bruna.seliga@gmail.com	t
828	Adnilson	adnilsonssilva@gmail.com	Adnilson	@adnilsonssilva	http://www.lemuryti.com	82913736b138faa3097c086812f3a80e	t	2011-11-15 12:05:44.365659	2011-11-15 12:04:52.742446	1	1987-01-01	\N	f	adnilsonssilv@hotmail.com	t
832	Paulo Sergio Ferreira de França	psergio_franca@hotmail.com	sergio	@		aaa3e5d720bef42d103ab3cfdfe49e83	t	2011-11-17 21:29:00.37953	2011-11-15 13:13:42.973775	1	1990-01-01	\N	f	sergio_franca90@oi.com.br	t
3358	ANA LARISSA XIMENES BATISTA	larissa_ximenees@hotmail.com	ANA LARISS	\N	\N	dedfe641766cda3abc84e35894d3f1fb	f	\N	2012-01-10 18:25:45.077592	0	1980-01-01	\N	f	\N	f
836	Thiago Ramos Rodrigues 	thramos_467@hotmail.com	Thiaguin	@		97401dad162c6845f9918e682da60e05	f	\N	2011-11-15 16:41:31.450242	1	1983-01-01	\N	f		t
1081	Leandro Menezes de Sousa	leomesou@gmail.com	Leandro	@		d17a10332cafa633364e52c0287b5c97	t	2012-01-18 12:33:24.056053	2011-11-20 15:39:36.944764	1	1992-01-01	\N	f	leomesou@facebook.com	t
1171	Marcílio José Pontes	marciliopoint@hotmail.com	marcilio	@		5ce870a614542af3aaf69b84fde47f49	f	\N	2011-11-21 20:43:06.545868	1	1981-01-01	\N	f	marciliopoint@hotmail.com	t
730	Natan Oliveira de Sousa	nato_oliveira81@hotmail.com	Nato81	@		c17f404a3d9b797e6a833a78fa4aab97	t	2011-11-10 22:51:17.564177	2011-11-10 22:48:36.033189	1	1992-01-01	\N	f	nato_oliveira81@hotmail.com	t
759	Alexandre de Menezes Gomes	alexandre_m5@hotmail.com	Alexandre	@Allexandre_M		d34b9c0b505df2441e3ce0e24ced8793	t	2011-11-11 20:55:08.6967	2011-11-11 20:18:01.160627	1	1994-01-01	\N	f		t
789	ELBIS TERDANY DA SILVA FERREIRA	terdan_@gmail.com	Terdany	@ElbisTerdany	http://super-sincero.tumblr.com	10a8cfc5a3fb857fbcee6f0f42680e1b	f	\N	2011-11-13 04:19:28.282309	1	1994-01-01	\N	f	terdany_@hotmail.com	t
1042	KEMYSON CAMURÇA AMARANTE	kemysonn@gmail.com	Kemyson	@Kemyson		ac002b12b7f315d1f4a299d78bf1bab1	t	2012-01-10 18:26:21.17451	2011-11-19 01:08:10.17065	1	1994-01-01	\N	f	kemysonn@gmail.com	t
702	Thiago Carvalho Walraven da Cunha	thiagowalraven@yahoo.com.br	Thiago Walraven	@		221d03bbdf9c4c8ac112a26d40290603	t	2011-11-10 23:30:21.480218	2011-11-10 22:05:35.52561	1	1995-01-01	\N	f	thiagowalraven@yahoo.com.br	t
731	Clemilton Rodrigues de Freitas	clemilton.rodrigues@hotmail.com	Clemilton	@clemilton1		57f9b413860568ae0af7dfdd1e276ec3	f	\N	2011-11-11 00:26:05.392677	1	1988-01-01	\N	f	clemilton.rodrigues@hotmail.com	t
807	FRANCISCO EBSON GOMES SOUSA	ebsongomes@yahoo.com.br	Ebson Gomes	@e_bsongomes		0b751d6b3e8199f835063b7785a7e6cc	t	2011-11-14 15:31:25.132931	2011-11-14 15:26:01.184381	1	1992-01-01	\N	f	ebsongomes@yahoo.com.br	t
1002	KLEGINALDO GALDINO PAZ	kleginaldopaz@hotmail.com	Kleginaldo Paz	@kleginaldopaz		e839932cde9946b5e242e72281952675	t	2012-01-10 18:26:21.379893	2011-11-18 14:40:40.063403	1	1993-01-01	\N	f	kleginaldopaz@hotmail.com	t
1917	LEANDRO BEZERRA MARINHO	leandrobezerramarinho@gmail.com	leandrobmarinho	@		72a4d073e6a4fa030c30a9c252e3dd40	f	\N	2011-11-23 14:34:46.235224	1	1992-01-01	\N	f	leandrobmarinho@hotmail.com	t
733	José Rodrigo Lopes Lima	rodlm777@gmail.com	Rodrigo	@		16effd8b16405d9c9991a35d90a0d88b	t	2011-11-11 00:50:25.216464	2011-11-11 00:48:28.295555	1	1981-01-01	\N	f	rodlm777@gmail.com	t
444	JOÃO PEDRO MARTINS SALES	joaopedro_89@hotmail.com	jpedro	@		9cf38e02d3ae12e563a0469087109a80	t	2012-01-10 18:26:15.024781	2011-10-29 11:18:21.214674	1	1989-01-01	\N	f		t
3360	ANDERSON PEREIRA GONÇALVES	andersonpr.goncalves@gmail.com	ANDERSON P	\N	\N	5807a685d1a9ab3b599035bc566ce2b9	f	\N	2012-01-10 18:25:45.574206	0	1980-01-01	\N	f	\N	f
2621	Antônio Lisboa Coutinho Júnior	lisboajr@gmail.com	Lisboa	@		4446465c3c6aa70501c0b2520147f40b	f	\N	2011-11-26 08:56:00.155881	1	1974-01-01	\N	f		t
3361	ANDRE ALMEIDA E SILVA	andre8031@ig.com.br	ANDRE ALME	\N	\N	58238e9ae2dd305d79c2ebc8c1883422	f	\N	2012-01-10 18:25:46.499999	0	1980-01-01	\N	f	\N	f
735	Jefferson	Jefferson-_-rocking@hotmail.com	Jeffin	@_Jeffersoncm_		3745c335e8f170cb6a923aead983810e	f	\N	2011-11-11 09:17:53.658844	1	1995-01-01	\N	f	Jefferson-_-rocking@hotmail.com	t
780	Giliard	giliardbrbs@gmail.com	GiliardSousa	@GillyardS		9422b35cc5790fb1af97c11b63a36dba	t	2011-11-12 17:06:16.270651	2011-11-12 16:44:25.967933	1	1994-01-01	\N	f	giliardbrbs@hotmail.com	t
736	Jose Jairo Viana de Sousa	jairojj@gmail.com	jairojj	@jairojj		5407ab9a62087517f7634fce3a98d374	f	\N	2011-11-11 10:37:48.783793	1	1986-01-01	\N	f	jairojj@gmail.com	t
796	Deivith Silva Matias de Oliveira	deivitholiveira@gmail.com	Deivith	@		94db80029a17a7f5e3952ede03dfd8b6	f	\N	2011-11-13 18:21:16.884811	1	1992-01-01	\N	f	deivitholiveira@gmail.com	t
737	lysnara ingrid de oliveira nascimento	narynha123@hotmail.com	narynha	@		b6a550e821287f53aba22aad8b1fb8ac	f	\N	2011-11-11 12:11:37.396887	2	1997-01-01	\N	f		t
822	renan de sousa nogueira	remaro1@hotmail.com	remaro	@		9791e1af4be6478ff7f2dcf1737db20e	t	2011-11-16 10:48:43.64024	2011-11-14 22:25:49.457625	1	1994-01-01	\N	f	remaro1@hotmail.com	t
738	Kessiane Hilário	kessianehilario@gmail.com	Kessii	@Kessii_H		28fa55720c83197b52adfc1a7ab632bf	t	2011-11-11 12:19:44.517213	2011-11-11 12:15:57.383451	2	1994-01-01	\N	f	kessiane_otaku@hotmail.com	t
987	Wanderson Dantas Oliveira Santana	waldivia100www@hotmail.com	XxSoulxX	@		f3674879f5e18c7989e02235da302cc9	t	2011-11-17 22:21:49.2563	2011-11-17 22:18:40.689231	1	1992-01-01	\N	f		t
743	Iasmim de Menezes Rabelo	iasmim.rabelo@hotmail.com	Iasmim	@		0cccea331704127cd87dd145f6005819	t	2011-11-11 14:22:46.022527	2011-11-11 14:20:50.332587	2	1994-01-01	\N	f		t
744	Nil Késede Araújo Queiroz	nilkesede@gmail.com	Késede	@nilkesede		ddc52bc9ff7c48076226a9d4630bea33	t	2011-11-13 14:29:36.706448	2011-11-11 14:30:59.642668	1	2011-01-01	\N	f	nilkesede@gmail.com	t
813	Hildane Sales	hildane@gmail.com	Lenneth	@		8b864c803980e6aa4000dbc5819f3d14	t	2011-11-14 20:03:51.843374	2011-11-14 19:43:55.090935	1	1987-01-01	\N	f		t
829	Paulo Sergio Ferreira de França	sergio_franca90@oi.com.br	sergio	@		b0bc73139cbf047d86ce9ce41064cb5c	f	\N	2011-11-15 13:10:47.058556	1	2011-01-01	\N	f	sergio_franca90@oi.com.br	t
860	monique	moniqueenxzero@hotmail.com	perfeitinha	@		31f1c2f39bcb06656062b55dfc5e747f	t	2011-11-17 09:51:59.074335	2011-11-16 10:48:44.030208	2	1995-01-01	\N	f	moniqueenxzero@hotmail.com	t
833	jose wilker carneiro paiva	wilkertwitter@gmail.com	wilker	@		425c18fc11f33354ee70bfe6133644c8	t	2011-11-15 15:07:41.547921	2011-11-15 15:04:46.046527	1	1994-01-01	\N	f		t
3362	ANDRE LUIS VIEIRA LEMOS	andre_luis_vieira_lemos@yahoo.com.br	ANDRE LUIS	\N	\N	acf1c902d5789dee185e3e219ecb0f59	f	\N	2012-01-10 18:25:47.020494	0	1980-01-01	\N	f	\N	f
850	Francisco Hítalo de Sousa Luz	piveti20112011@hotmail.com	cabeça	@		fa988f529f64ebfc028ed9bcfb7ba797	t	2011-11-20 07:58:27.285359	2011-11-16 06:24:05.82574	1	2011-01-01	\N	f	piveti20112011@hotmail.com	t
3363	ANDRESSA MAILANNY SOUZA DA SILVA	silvaandressa64@gmail.com	ANDRESSA M	\N	\N	a163ea462fd9cf6d08f27d709d3ff0a5	f	\N	2012-01-10 18:25:47.599619	0	1980-01-01	\N	f	\N	f
946	Lucas Vasconcelos de Assis	lucasvasconcelos95@hotmail.com	Vasconcelos	@		7219ff493f2ca6bee8a795df363bd879	f	\N	2011-11-17 09:02:27.848532	1	1995-01-01	\N	f	lucasvasconcelos95@hotmail.com	t
839	Rafaela Braz de Souza	rafabraz@live.com	rafaela	@		c0bbea2d26121a9d479c7511b93d1755	t	2011-11-16 15:56:01.44993	2011-11-15 18:00:27.128654	2	1995-01-01	\N	f	rafabraz_sdc@hotmail.com	t
842	Mary Craicy	mary-gleicy@hotmail.com	maryzinha	@		7bb9fd433cff410b73e220f2c164ef7f	t	2011-11-15 19:10:12.951621	2011-11-15 19:07:52.530345	2	1994-01-01	\N	f		t
999	Matheus Rodrigues	matheusrodriguescbjr@hotmail.com	zimcbjr	@		e7b7803a57341425e08c347ecf4e3b72	f	\N	2011-11-18 12:11:20.517724	1	2011-01-01	\N	f	matheusrodriguescbjr@hotmail.com	t
1082	Aline Isabelle	aline_carvalho@hotmail.com	Aline Isabelle	@alineisabelle		fd3e53e145479f19a675a8690bfaea9e	t	2011-11-20 15:50:33.712519	2011-11-20 15:46:10.626928	2	1995-01-01	\N	f		t
1172	Mayra Silva Rabelo	mayra.ejovem@gmail.com	Mayra Rabelo	@MayraRabello	http://facebook.com/mayra.rabelo	66e49ef28d7982619d10d38f5429b787	t	2011-11-21 20:48:44.6776	2011-11-21 20:43:26.160504	2	1992-01-01	\N	f	mayra_silva_rabelo@hotmail.com	t
887	Marcos Henrique	henriqueakatsuki@hotmail.com	zarakin-san	@		7b02f8d3ccf8376d142d42636d6feaac	t	2011-11-18 09:44:11.340125	2011-11-16 11:12:21.190553	1	1993-01-01	\N	f	henriqueakatsuki@hotmail.com	t
1008	Pedro Vitor de Sousa Guimarães	pedrovitorti@gmail.com	Pedro Vitor	@		64758d52d3faa09e94b4154fa829e2c5	f	\N	2011-11-18 16:24:28.409358	1	1990-01-01	\N	f		t
1088	Alan Rael Gomes dos Santos	raelalan@hotmail.com	Alan Rael	@Alanrael1		55436196436004c82692325119f62fbb	f	\N	2011-11-20 20:42:16.846207	1	1997-01-01	\N	f	raelalan@hotmail.com	t
1260	Luciana Ramos Sales	luciana17sales@hotmail.com	luluzinhar	@		f8d36881ba790d1671dbf859ab16013a	f	\N	2011-11-22 09:44:51.362286	2	1991-01-01	\N	f		t
1366	LUCAS DIONEY SANTOS VIEIRA	lucasdsv12@hotmail.com	DIONEY	@		0a245e747e525a71f33243bc64037a2a	f	\N	2011-11-22 12:10:51.168742	1	1994-01-01	\N	f		t
1625	Nathalia Marques	natty-neres1@hotmail.com	natthy	@		2d187546ae05e2c428aa283709f38dd6	t	2011-11-22 20:34:11.159123	2011-11-22 20:32:15.287215	2	1995-01-01	\N	f		t
745	Walbert Sousa Sabino	walbertsabino.ce@gmail.com	Walbert'	@		00474a9f14ea9b7cee1e0338f2b8fde5	t	2011-11-11 14:53:37.426687	2011-11-11 14:52:48.72154	1	1990-01-01	\N	f	walbert.sabino@facebook.com	t
837	LUCAS SILVA DE SOUSA	lucas.xmusic@hotmail.com	Lucass	@Lucas_xmusic		d3fe76099ccfe2f30054ce08a7ed6eba	t	2012-01-15 23:29:21.95366	2011-11-15 17:08:30.07648	1	1993-01-01	\N	f	lucas.xmusic@hotmail.com	t
1554	JEFTE SANTOS NUNES	jeftenunes@hotmail.com	Jéééfs	@jefte27		214e514adaca438a5122042daa232c59	f	\N	2011-11-22 17:29:49.28854	1	1993-01-01	\N	f	jeftenunes@hotmail.com	t
746	Mateus Pereira de Sousa	infomateus2@gmail.com	InfoMateus	@		837662f41ab01f65bc7238d336e81379	t	2011-11-11 15:45:16.095287	2011-11-11 15:31:28.95995	1	1984-01-01	\N	f		t
750	lilian	lilianjl.seliga@gmail.com	lilian	@		8581fbf513b44b625a3ba6a894b29b72	t	2012-01-19 20:45:34.591298	2011-11-11 16:08:41.26916	2	1993-01-01	\N	f		t
988	Edmo Jeová Silva de Lima	edmo@solucaosistemas.net	EdmoJeova	@edmojeova		df94ad8473aa05b81f861ff7f695336d	t	2011-11-17 22:39:22.617724	2011-11-17 22:37:22.065009	1	1991-01-01	\N	f	edmojeova@gmail.com	t
808	FRANCISCO JANAEL COELHO GOMES	janaelcoelho@yahoo.com.br	Janael Coelho	@		a5aac6f54ea23733ce14647da4906b5d	t	2011-11-15 11:00:09.119174	2011-11-14 15:28:05.205922	1	2011-01-01	\N	f		t
775	Camilla Catsro	camillacastro123@yahoo.com.br	Camillinha	@		d099a879b936e1e8a3ad8cacb4c02b52	t	2011-11-17 09:54:41.67543	2011-11-12 15:00:08.240006	2	1995-01-01	\N	f	puca_07camila@hotmail.com	t
797	Marcos Calixto Duarte	mcalixtod@hotmail.com	Calixto	@		37986275c800185460c4bc9db2998257	f	\N	2011-11-13 19:34:31.741331	1	1996-01-01	\N	f		t
799	Renato Ivens Gomes Feijó	ivensgomes@r7.com	Renato Ivens	@renatoivens		f70f920f398cf2567fbe9e9ec4100d6c	t	2011-11-15 00:48:12.954179	2011-11-13 21:08:16.579793	1	1996-01-01	\N	f	renato.gomes08@gmail.com	t
781	Renato Ivens Gomes Feijó	ivens.gomes08@hotmail.com	Renato Ivens	@renatoivens		fa3aeeefff27b0055ac574cbfd1a068b	f	\N	2011-11-12 16:49:12.759718	1	2011-01-01	\N	f	renato.gomes08@gmail.com	t
847	THAMYRES RAUPP DE ARAUJO	thamy_raupp@hotmail.com	Ursinha	@		80d79acf5c19af4cc9fe9d44f54a021d	t	2011-11-15 22:49:04.605671	2011-11-15 22:42:09.215391	2	1991-01-01	\N	f	thamy_raupp@hotmail.com	t
814	Rogério Queiroz Lima	rogerseliga@gmail.com	Rogerio	@		3c1b3d790e3320bd76eb04b83737e3b4	t	2011-11-14 19:47:45.333588	2011-11-14 19:44:16.726635	1	1994-01-01	\N	f	rogerio-_2010@hotmail.com	t
827	Ana Kézia	anakezia_franca8@hotmail.com	ninhafranca	@ninha_java		e10adc3949ba59abbe56e057f20f883e	t	2011-11-15 10:36:49.546857	2011-11-15 10:34:40.100093	2	1988-01-01	\N	f	kezia.ninha@gmail.com	t
939	Alessandra Estevam	alessandraestevam@live.com	Alessandra	@		5213004eed2b8264a8570d87d2642883	f	\N	2011-11-16 21:17:59.535381	2	1995-01-01	\N	f	alessandraestevam@live.com	t
1367	YAGO AUGUSTO COSTA PEREIRA	cave.raya@hotmail.com	AUGUSTO	@		9469e9aa25dcc2679a27cd05895a1111	f	\N	2011-11-22 12:13:34.488409	1	1995-01-01	\N	f		t
834	Marcelo Lessa Martins	marcelo_ifce@r7.com	Celinho	@Marcelo__Lessa		c10e6a9ef2843c4d5ce00f6b7c051e34	f	\N	2011-11-15 16:21:35.521635	1	1994-01-01	\N	f	marcellolessamartins@hotmail.com	t
856	Paulo Gabriel Pinheiro Vieira	paulinbiel@hotmail.com	Gabriel	@G_Gab		fd28cbb8195a49ec21f98c80ce0ead94	t	2011-11-17 08:47:20.083851	2011-11-16 10:31:54.143913	1	1995-01-01	\N	f	paulinbiel@hotmail.com	t
810	Pedro Gerlyson Batista Xavier	gerly_aqua@hotmail.com	Pedro 	@		e88fc7137dedd2865df03445667245ce	t	2011-11-15 17:29:31.90567	2011-11-14 16:44:41.494062	1	1992-01-01	\N	f		t
840	Lucas Félix Magalhães	lucas_felix10@hotmail.com	Lucas Félix	@		0eda13b91ea076072e8a3cfa99781bc0	t	2011-11-15 18:14:41.951933	2011-11-15 18:12:17.667477	1	1995-01-01	\N	f	lucas_felix10@hotmail.com	t
1089	Jailson Pessoa Pereira Filho	jailsontakiminase@gmail.com	Taki Minase	@Takiminase		fe140c7a11210d69d967d633af424db8	t	2011-11-20 20:51:39.417423	2011-11-20 20:44:55.664742	1	1991-01-01	\N	f		t
1074	Thiago André Cardoso Silva	thiagoandrecadoso@gmail.com	ThiagoQI	@qignorancia	http://www.quantaignorancia.com/	41d2cfab1eef3096964a74f84577b2b8	f	\N	2011-11-20 09:08:16.025271	1	1987-01-01	\N	f	aerosmith-so@hotmail.com	t
1459	Marcos Teixeira Marques Filho	marquinhos_14cearamor@hotmail.com	Marcos	@		e2e64a0f4ddbedadca84102499e4c90f	f	\N	2011-11-22 16:54:33.860885	1	1995-01-01	\N	f	marquinhos_14cearamor@hotmail.com	t
843	Stefhanie Gama	stefhanie.gama@hotmail.com	Thefyy	@stefhaniieg		494609f80f5a615aeebaa4cd9bf47c80	t	2011-11-17 14:43:29.336451	2011-11-15 19:21:10.407503	2	1994-01-01	\N	f	stefhanie.gama@hotmail.com	t
846	Aluisio Rodrigues	aluisio0919@hotmail.com	Aluisio	@		8fb5c330af19b0f8af387f651704e626	t	2011-11-15 19:40:54.689747	2011-11-15 19:39:45.889856	1	1994-01-01	\N	f	aluisio0919@hotmail.com	t
947	Rafael Freitas Rodrigues Viana	rafaelviana70@yahoo.com.br	Viiana '-'	@		e3da615b6ddceedca071673916a96d97	t	2011-11-17 09:10:08.796101	2011-11-17 09:05:21.433986	1	1994-01-01	\N	f	rafaelnaparada@hotmail.com	t
854	Bruna Caroline Xavier Gomes 	brunagomes365@hotmail.com	bruna gomes	@		48010a8994cc781dec74efba9be4f3ef	t	2011-11-16 10:57:42.096117	2011-11-16 10:30:41.344781	2	1995-01-01	\N	f	brunagomes365@hotmail.com	t
1041	anna paula	anna_pauliinha@hotmail.com	paulinha	@		039347a98500499a83a6d1a6fc2eaf7a	f	\N	2011-11-19 00:43:42.305405	2	1993-01-01	\N	f	anna_pauliinha@hotmail.com	t
1000	Jéssica Brito da Silva	jessica16jordison@hotmail.com	Jéh Jordison	@jjordison_01		8d569177bd709b21f3aaa98f37f95282	t	2011-11-18 14:31:24.427304	2011-11-18 14:14:48.538447	2	1991-01-01	\N	f	jessica16jordison@hotmail.com	t
1589	Junior Vasconcelos	cardozoqueiroz@hotmail.com	b-boy Bob	@		be571c6636f20722ef59acefa44e6462	f	\N	2011-11-22 18:17:22.787866	1	1995-01-01	\N	f		t
859	walter barbosa	wthummel@hotmail.com	Binladen	@		61669c4f41c341cb917a2571a6a52670	t	2011-11-16 11:01:59.412482	2011-11-16 10:43:33.903967	1	1995-01-01	\N	f	wthummel@hotmail.com	t
1261	Alysson Martins	alyssonmartins13_@hotmail.com	Vaskin	@vaskin_pxpxcx		6f99bca242e384a49c197051e53ec591	f	\N	2011-11-22 09:45:06.341304	1	1991-01-01	\N	f	alyssonmartins13_@hotmail.com	t
1044	JEAN LUCK CARDOSO DA SILVEIRA	janusrock@hotmail.com	euthanatos	@		f8abdee5310b6e44369d0948877d9ad5	t	2012-01-10 18:26:12.947566	2011-11-19 11:09:36.694851	1	1992-01-01	\N	f	janusrock@hotmail.com	t
972	halesson	halessonmenezes0@hotmail.com	massive	@		9fb10d125a03d2b9d7780cbe87accb9e	t	2011-11-17 11:51:31.468893	2011-11-17 11:47:59.994481	1	1995-01-01	\N	f	halessonmenezes0@gmail.com	t
326	AlysonMello	Alyson27@gmail.com	Triplomaster	@Alyson_Mello		8ae8483a4f4ddb0d4451d3f801229c53	t	2011-11-17 14:58:21.147421	2011-10-15 09:54:25.937655	1	2011-01-01	\N	f	Alysonmello_2011@hotmail.com	t
863	Bruno Celiio	brunoceliio@hotmail.com	BrunoCeliio#	@		be7b053ca729a45fe38cef462b78fd5a	t	2011-11-16 11:34:28.897137	2011-11-16 10:50:00.561277	1	1995-01-01	\N	f	brunoceliio@hotmail.com	t
901	Carlos Matheus Chaves de Gois	carlos_matheush01@yahoo.com.br	skid RM	@		b41dba9db2e4f11abf3a7eaa0941fc71	t	2011-11-16 11:44:54.382958	2011-11-16 11:37:47.267099	1	1995-01-01	\N	f	matheus_gdx@hotmail.com	t
979	Levi Pires de Gois	levipiresgois@hotmail.com	katekyu	@		ef1bc753815beb298ef12b5f3e226504	f	\N	2011-11-17 15:21:25.350163	1	1995-01-01	\N	f		t
692	lucas Araujo da Silva	lucas._.araujo@hotmail.com	the dark knight	@		0dd96cfb29657c68e25d938a60a0d0a8	t	2011-11-18 16:29:35.028517	2011-11-10 17:36:38.192231	1	1995-01-01	\N	f	lucas._.araujo@hotmail.com	t
1012	Leticia fernandes	lehfernandes@hotmail.com	leeeeh	@		809edf53fabb12d2014876bbcedce2a0	f	\N	2011-11-18 17:08:46.574817	2	1996-01-01	\N	f		t
1120	Paulo Rafael da Silva Cavalcante	rafaeljigsaw_@hotmail.com	rafael sinx	@		1f2aef49bf21f02a37aba50bde45a43d	f	\N	2011-11-21 12:02:15.09179	1	1994-01-01	\N	f		t
2211	Francisco Jonas Ferreira	jonnascr7@LIVE.COM	jonasferr	@		95183eccbc41d7beccf46c272ea948ca	f	\N	2011-11-23 21:18:59.832639	1	1990-01-01	\N	f		t
748	isaac bruno	isaac.bruno@hotmail.com	bruno10	@		c6fcc0dedd4250a3ef8c5cc5fdc09503	t	2011-11-11 15:56:58.303016	2011-11-11 15:50:15.865561	1	1994-01-01	\N	f		t
749	Darlilson Lima	darlildo.cefetce@gmail.com	Darlilson	@		6b4b7d6300fb3385f5fb4ec91bc745d9	t	2011-11-11 16:05:57.252725	2011-11-11 15:51:56.612032	1	2000-01-01	\N	f		t
408	JOÃO VICTOR RIBEIRO GALVINO	joaov777@gmail.com	João Victor	@		3284dbb877a0a0d129bbba353687cc3b	t	2012-01-10 18:26:15.233517	2011-10-20 21:00:50.225138	1	1991-01-01	\N	f		t
753	Miquéias Amaro Evangelista	miqueiasinformatica@gmail.com	Miquéias Amaro	@miqueiasamaro		200820e3227815ed1756a6b531e7e0d2	t	2011-11-11 20:20:09.109391	2011-11-11 17:28:54.527884	1	2011-01-01	\N	f	iceblaze2010@hotmail.com	t
1414	JONATA ALVES DE MATOS	jonataamatos@hotmail.com	jonata	@jonata08matos		1d04054ec1abb85e0421a6e6f2cac538	t	2012-01-16 11:28:21.970509	2011-11-22 16:32:35.909901	1	1986-01-01	\N	f	jonataamatos@hotmail.com	t
751	Leandro Silva de Sousa	tricolor.leandro@gmail.com	Leandro	@leossousa	http://sistemaozileo.blogspot.com	ed2f0d39f4964bc294d5ffa9e50f427d	t	2011-11-11 16:45:12.07433	2011-11-11 16:40:37.270709	1	1974-01-01	\N	f	tricolor.leandro@gmail.com	t
791	Mônica	monica.b.l@hotmail.com	Mônica	@monica_angel		51044394289de849bf0a2cb1ddc654b7	t	2011-11-13 10:11:46.317703	2011-11-13 09:44:37.837919	2	1988-01-01	\N	f	monica.bandeira.lourenco@gmail.com	t
776	Carlos Eduardo de Oliveira	kaduoliveira13@hotmail.com	Kaduzinho	@		c1c892138543dee118a5a43cd65c7be0	f	\N	2011-11-12 15:02:03.736978	1	1994-01-01	\N	f	kaduoliveira13@hotmail.com	t
3364	ANTONIA MARIANA OLIVEIRA LIMA	mariana.lima91@hotmail.com	ANTONIA MA	\N	\N	9ab0d88431732957a618d4a469a0d4c3	f	\N	2012-01-10 18:25:48.115129	0	1980-01-01	\N	f	\N	f
973	JONATAS HARBAS ALVES NUNES	jonatasnice@yahoo.co.uk	harbas	@		dfbc016e41f1957968a68ccedf19a013	t	2012-01-16 19:28:17.628469	2011-11-17 12:26:21.367156	1	1993-01-01	\N	f	jonatasnice@yahoo.co.uk	t
1151	JOSÉ XAVIER DE LIMA JÚNIOR	xavierxion@hotmail.com	Zyegfreed	@		908ec83844397d4df4f605743a3f7184	t	2012-01-10 18:26:18.092088	2011-11-21 17:42:01.123853	1	1988-01-01	\N	f	xavierxion@hotmail.com	t
3365	ANTONIA NEY DA SILVA PEREIRA	bibleney@gmail.com	ANTONIA NE	\N	\N	644593a6096a12d57271d31515d06bbf	f	\N	2012-01-10 18:25:48.319241	0	1980-01-01	\N	f	\N	f
815	ana claudia	ana.cnarujo@hotmail.com	aninha	@		18862362c266237811f11624db053c06	f	\N	2011-11-14 20:46:20.237031	2	1994-01-01	\N	f	ana.cnaraujo@hotmail.com	t
993	GABRIEL BEZERRA SANTOS	bezerragb@hotmail.com	Gabriel	@Erupoldaner		d8059c5dfe4bbc60f0d0f6bd69b8accb	t	2012-01-16 12:48:56.649725	2011-11-18 09:18:26.10386	1	1991-01-01	\N	f	bezerragb@hotmail.com	t
1075	Marcos Gabriel Santos Freitas	gb_tinho@hotmail.com	VesgoMaker	@Gabriel_Screamo	http://envenenado.tumblr.com/	277dbf3be51fc5b3b18860b0f1014fa2	t	2011-11-24 11:53:45.397738	2011-11-20 10:30:24.758507	1	1993-01-01	\N	f	gb_tinho@hotmail.com	t
798	Marcos Calixto Duarte	mcalixtod@bol.com.br	Calixto	@		796278a4e151e7e05049c425030c0e13	t	2011-11-22 22:43:33.049886	2011-11-13 19:40:15.107385	1	1996-01-01	\N	f		t
3366	ANTONIA SIDIANE DE SOUSA GONDIM	sidiane_cindy@hotmail.com	ANTONIA SI	\N	\N	e555ebe0ce426f7f9b2bef0706315e0c	f	\N	2012-01-10 18:25:48.618342	0	1980-01-01	\N	f	\N	f
329	Carlos Henrique 	carlos-tuf@hotmail.com	carlinhos	@		29c0140c11ef9f7abbbf81c7f237879a	t	2011-11-15 01:38:34.48918	2011-10-15 12:08:25.218063	1	1993-01-01	\N	f	carlos-tuf@hotmail.com	t
940	Hércules	herculessantana1@hotmail.com	Hércules	@herculessant1		0c39ff860c7740962d334327f559d95b	t	2011-11-16 21:47:49.514576	2011-11-16 21:44:43.224635	1	1997-01-01	\N	f	herculessantana1@hotmail.com	t
835	Márcia Caroline Germano Pereira	marcia___caroline@hotmail.com	Carolzinha	@marcia_caroline		e56ee9b8b30e6ad9e50a155b3e4e871a	t	2011-11-15 16:35:33.836129	2011-11-15 16:29:48.981154	2	1994-01-01	\N	f	marcia___caroline@hotmail.com	t
989	Aline Isabelle	alineisabelle@bol.com.br	Aline Isabelle	@alineisabelle		e3c68baa8a32fd328864588eb99c85ae	f	\N	2011-11-17 23:26:46.084834	2	1995-01-01	\N	f	alineisabelle@bol.com.br	t
1174	Darlildo Lima	darlildo17@hotmail.com	Darlildo	@darlildo	http://darlildo.wordpress.com/	e6072eb614506728167864e5cfdbf168	f	\N	2011-11-21 20:45:45.886739	1	1989-01-01	\N	f	darlildo.cefetce@gmail.com	t
838	Fabiana Larissa Barbosa da Silva	flarissasilva@hotmail.com	fabiana	@		c0aedde73e52a867ea2e432052dfc3e4	f	\N	2011-11-15 17:58:46.998596	2	1993-01-01	\N	f	flarissasilva@hotmail.com	t
857	Karine Vieira Queiroz	karine_fofaa@hotmail.com	Kazinha	@		f8def8dbeffe7de925d3efbc5a10174b	t	2011-11-16 10:43:11.202093	2011-11-16 10:33:03.24012	2	1994-01-01	\N	f	karine_foffa@hotmail.com	t
841	João Ferreira	joaogato07@hotmail.com	joaoferreiratorres	@DepositoJacome		908c9b1fe76d776304eb59dc02cd534f	f	\N	2011-11-15 19:06:25.311182	1	1997-01-01	\N	f	joaogato07@hotmail.com	t
1035	Antonio Herlanio Pinheiro Lacerda	herlanio_lacerda@hotmail.com	herlanio	@Fercodine		2946ac642dc502bc700556fc98cfde69	t	2011-11-18 21:35:08.595635	2011-11-18 21:31:51.541993	1	1996-01-01	\N	f	herlanio_17x@hotmail.com	t
844	Bensonhedges de Sousa Gama	benson_black_star@hotmail.com	Benzoo	@		dc5842cf06261ea146ddf341a2573317	f	\N	2011-11-15 19:22:16.796786	1	1996-01-01	\N	f		t
948	Raul de Souza Ferreira	hw_raul95@yahoo.com.br	>pipoca<	@		f2baddc6b3305042b40a6479f225639e	t	2011-11-17 09:19:01.829256	2011-11-17 09:06:48.982852	1	1995-01-01	\N	f		t
3367	ANTONIO DE LIMA FERREIRA	johnnyrude@hotmail.com	ANTONIO DE	\N	\N	22ac3c5a5bf0b520d281c122d1490650	f	\N	2012-01-10 18:25:48.801679	0	1980-01-01	\N	f	\N	f
1083	Michael Lourenço Bezerra	jesussave.podecrer@hotmail.com	Só Jesus Salva.	@		d5a66bdb0d7cc4ca5159d58666242c9e	t	2011-11-20 18:19:19.023112	2011-11-20 18:07:14.696447	1	1992-01-01	\N	f	jesussave.podecrer@hotmail.com	t
969	Monique Farias Abreu	monique_salvatore16@hotmail.com	perfeiktinha	@		0fcd0734cde1d0e51ea4c433dfec7d5a	f	\N	2011-11-17 09:44:39.674402	2	1995-01-01	\N	f		t
691	adrielly gomes oliveira	adriellydrika2009@hotmail.com	lily gomes	@adrielygomez		6caebb8d29bd69a9a694b1dabfdc005d	t	2011-11-23 11:00:28.750002	2011-11-10 17:19:43.734321	2	1996-01-01	\N	f	adriellydrika2009@hotmail.com	t
3368	ANTONIO ELSON SANTANA DA COSTA	elsonsan@yahoo.com.br	ANTONIO EL	\N	\N	277261b31167f604df82fd5926297e9a	f	\N	2012-01-10 18:25:48.943544	0	1980-01-01	\N	f	\N	f
845	samuel jodson nunes ponte	samukacearamor@hotmail.com	samuca	@		c1acdd3b0d152c94eac96ed49834049d	t	2011-11-19 00:58:19.647037	2011-11-15 19:22:57.120401	1	1994-01-01	\N	f		t
821	Daniel Abner Sousa dos Santos	abnersousa2009@hotmail.com	daniel	@		c670bbbd9eebc9f48756c6668fd59091	t	2011-11-16 11:23:23.654417	2011-11-14 22:25:36.802964	1	1995-01-01	\N	f	abnersousa2009@hotmail.com	t
858	jhonathan davi alves da silva	jhon-davi@hotmail.com	jhon-jhon	@		08d927976fc9fdd1888d08d29bc408c3	t	2011-11-16 11:30:43.256012	2011-11-16 10:42:23.848331	1	1995-01-01	\N	f	jhon-davi@hotmail.com	t
1368	WILKER BEZERRA LUCIO	wilker100wbl@hotmail.com	WILKER	@		3e9c9d97bd066d5c86a54533c47c3df3	t	2011-11-22 21:46:32.937454	2011-11-22 12:14:43.213561	1	1995-01-01	\N	f		t
938	Mikaelly Ribeiro da Silva	Mikaelly.r.s@gmail.com	Mikaelly	@		4af4e24481f01b54c7d219994b698c87	t	2011-11-17 15:40:26.049044	2011-11-16 21:03:55.249724	2	1992-01-01	\N	f	Mikaelly.r.s@gmail.com	t
1009	francisco wanderson	wandinholoves2@gmail.com	chuck norris	@wandinholoves2		2a1a53f122d915737c096a5b67a10203	f	\N	2011-11-18 16:31:12.171281	1	1994-01-01	\N	f	wandinholoves2@hotmail.com	t
1048	Deise Dayane	deisinha_tuf@hotmail.com	Deisinha	@		17232c911601f062447a9d94d99f0344	t	2011-11-19 12:38:46.391978	2011-11-19 12:30:45.47491	2	1993-01-01	\N	f	deisinha_tuf@hotmail.com	t
1274	Alexandro Santos de Oliveira	alexandroliveira2009@hotmail.com	alex Lón	@		4aec9e75419f74553cc14f2a3f2fd08e	f	\N	2011-11-22 09:50:22.250403	1	1989-01-01	\N	f		t
1590	Cesinha	vania.rosivania@gmail.com	Cesiha	@		589d8e28f7443c2584d26309d1a35043	f	\N	2011-11-22 18:20:13.327172	1	1993-01-01	\N	f		t
902	Samuel Jerônimo Dantas	samueljeronimo@hotmail.com	Samuel	@samjeronimo		a8557714848b2cdcaa119210345cdca2	t	2011-11-16 12:31:34.877418	2011-11-16 12:11:51.531903	1	1991-01-01	\N	f	samueljeronimo@hotmail.com	t
941	maria samia andrade oliveira	saklb@hotmail.com	samia19	@		a22c2723d47d3e0b6792bf5c2cdf4eb3	t	2011-11-18 23:02:27.145239	2011-11-16 21:56:55.020327	2	1992-01-01	\N	f	samia.andrade.oliveira@gmail.com	t
1318	GABRIEL DE SOUSA VENÂNCIO	gabriel.saxofone2009@gmail.com	Gabriel Venancio	@gabrielseliga		810ae82f135f7eb98d0486e965461c7a	t	2012-01-16 09:19:29.866925	2011-11-22 10:59:09.444928	1	1922-01-01	\N	f	gabriel.saxofone2009@gmail.com	t
990	jonathan santos	jonatha_igor@hotmail.com	kanda yuu	@jonahigor		ad4b5edbe64deabf32b653dfb809e852	t	2011-11-17 23:46:48.732943	2011-11-17 23:41:43.75936	1	1993-01-01	\N	f	jonatha_igor@hotmail.com	t
1076	João Guilherme Colombini Silva	Joao.Guil.xD@gmail.com	Guilherme	@		bd635174e4d3e05ad7a0d53d9204254e	t	2011-11-20 11:09:13.315219	2011-11-20 11:04:09.718925	1	1993-01-01	\N	f	Joao.Guil.xD@hotmail.com	t
3369	ANTONIO EVERTON RODRIGUES TORRES	evertonrodrigues3@hotmail.com	ANTONIO EV	\N	\N	a90c78175e9684f6865c849fc2b69757	f	\N	2012-01-10 18:25:49.071834	0	1980-01-01	\N	f	\N	f
906	Samuel Jerônimo Dantas	samueljeronimo27@gmail.com	Samuel	@samjeronimo		daacbf40ffd7e39e50aa96b32fa53cde	f	\N	2011-11-16 12:27:22.333283	1	1991-01-01	\N	f	samueljeronimo@hotmail.com	t
957	RAIMUNDO IGOR SILVA BRAGA	hunknow1337@gmail.com	Hunknow	@		e31c6bf63ba8a5afb6291153cdddfcb2	t	2011-11-17 09:25:26.428057	2011-11-17 09:17:33.923175	1	1995-01-01	\N	f		t
809	GIDEÃO SANTANA DE FRANÇA	gideaosf@gmail.com	Gideao	@		57d956497db6a547cb8ed3d1e840dd58	t	2012-01-16 17:15:32.185926	2011-11-14 16:30:35.477413	1	1993-01-01	\N	f	gideaosf@gmail.com	t
3370	ANTONIO JEFERSON PEREIRA BARRETO	russo.xxx@hotmail.com	ANTONIO JE	\N	\N	7af684c7e0b74b6d88743b06fc2ae108	f	\N	2012-01-10 18:25:49.20635	0	1980-01-01	\N	f	\N	f
2245	GILLIARD FERREIRA DA SILVA	gil.palmeiras@hotmail.com	Giliard	@		b7a8528753296124667d74d5d0a8b7b4	f	\N	2011-11-24 08:47:07.217937	1	1990-01-01	\N	f		t
907	Fernanda 	fernandaos12@gmail.com	nandaoliveira	@nandaoliveira7		5b83d8137f56d2382a770b8d2e6dffee	t	2011-11-16 12:42:50.275899	2011-11-16 12:33:34.445784	2	1983-01-01	\N	f	fernandaos12@gmail.com	t
908	EDSON RODRIGUES DE ARAUJO	edhunter_edson@hotmail.com	edhunter	@		8fdf4376c11d7fd189b92a4952be7a39	t	2011-11-22 18:20:26.676519	2011-11-16 13:36:33.509093	1	1989-01-01	\N	f	edhunter_edson@hotmail.com	t
970	Deryck Veríssimo	derykeverissimo@yahoo.com.br	Deryck	@		c41e7fa1f307817e39a9f9c61df9bbe2	t	2011-11-17 10:00:10.30	2011-11-17 09:54:57.964787	1	1991-01-01	\N	f	derykeverissimo@yahoo.com.br	t
909	Alisson Lemos Porfirio	alissonlemosporfirio@yahoo.com.br	Alissonlp	@		6df60057a839cc2a43322beed13e46d8	t	2011-11-16 14:12:50.235463	2011-11-16 14:02:00.296756	1	1988-01-01	\N	f	alisson_llemos@hotmail.com	t
3371	ANTONIO LOPES DE OLIVEIRA JÚNIOR	junior4000po@hotmail.com	ANTONIO LO	\N	\N	bc3427a68f57a1219b61f8b87760f5b8	f	\N	2012-01-10 18:25:49.57567	0	1980-01-01	\N	f	\N	f
910	larissa de oliveira araújo	larissinha1462@hotmail.com	larissa	@		c0b51e5a78ae8d8251beb5bdd440cdb0	t	2011-11-16 15:44:47.905852	2011-11-16 14:38:38.640076	2	1994-01-01	\N	f	larissinha1462@hotmail.com	t
974	Amsterdan Nascimento Gomes	amsterdan_gomes@hotmail.com	Amsterdan	@aamsterdan		1ec4b53ba679fd348abc10cf2a89dac4	t	2011-11-18 09:19:29.536598	2011-11-17 12:36:34.336005	1	1988-01-01	\N	f	amsterdan_gomes@hotmail.com	t
1169	UILLIANE DE FREITAS PONTES	uillianepontes@hotmail.com	Uilliane	@		badac769e76ccd19ee7546160311da48	t	2011-11-21 20:49:15.739233	2011-11-21 20:41:20.812084	2	1991-01-01	\N	f	uillianepontes@hotmail.com	t
911	Allef melo silva	allef.mad@gmail.com	negão	@		e7b5834087226bc53829619a71ebe8bc	f	\N	2011-11-16 14:39:28.25703	1	1994-01-01	\N	f	allef_mad@hotmail.com	t
977	Lucas Pires de Gois	lucaspiresgois@hotmail.com	lukazz	@		249a8f5f345596afabab464b390cd364	f	\N	2011-11-17 15:16:30.923372	1	1994-01-01	\N	f		t
3372	ARLEN ITALO DUARTE DE VASCONCELOS	aim_ceara03@hotmail.com	ARLEN ITAL	\N	\N	ac836ec424cf00ccf3bb2ec21d43fb90	f	\N	2012-01-10 18:25:50.306147	0	1980-01-01	\N	f	\N	f
916	YAGO SALES	yago_cesar1@yahoo.com	YAGOOOL	@yagosales		78c8c5882931f83c2460c20f248dc548	t	2011-11-17 14:52:56.167717	2011-11-16 14:44:43.359531	1	1992-01-01	\N	f	yago_cesar1@yahoo.com	t
982	Sergio Filho	serginho.negodrama@hotmail.com	Serginho	@		d658edfedf70cc0d231173bb3d42416d	f	\N	2011-11-17 18:27:49.257987	1	1995-01-01	\N	f	serginho.negodrama@hotmail.com	t
1006	Andre Luiz G de Araujo	algaprof@bol.com.br	Andre_Luiz	@		0d68f051aa36061ebc43b881474dfa78	f	\N	2011-11-18 15:16:16.929999	1	1975-01-01	\N	f		t
1104	Cândido Félix de Oliveira Júnior	andersonseliga@gmail.com	Júnior	@		1ab0e0d56b06780f5b3a69b19874ef7d	f	\N	2011-11-21 10:21:03.885333	1	1990-01-01	\N	f		t
1010	Francisco Fernandes da Costa Neto	fernandescnf@gmail.com	Nennen	@nennen11	http://www.facebook.com/fernandescnf	cc57b7aea56d26307d90c63cadac9745	t	2011-11-18 23:10:40.154933	2011-11-18 16:33:14.029471	1	1988-01-01	\N	f	fernandescnf@gmail.com	t
1013	Saulo Davi	saulodavi_@hotmail.com	Blaide2000	@Saulo_David	http://sige.comsolid.org/participante/add	27c7ded75c9b4302af59a8f7d2b4434a	t	2011-11-20 20:19:46.8826	2011-11-18 17:13:19.714545	1	1995-01-01	\N	f	saulodavi_@hotmail.com	t
1084	david tomás	davidtomas.instrutor@gmail.com	davidilustracoes	@davidtomasilust	http://davidtomasilustracoes.blogspot.com/	ba72ab08d6a340a7c06b850ea3169b17	f	\N	2011-11-20 18:18:52.453047	1	1987-01-01	\N	f	davidtomas.ilustracoes@hotmail.com	t
1186	david Weslley Costa de Oliveira	david.weslley8@gmail.com	DeeH'Oliveira	@		a4b8adb97fc5ad87d1015a8ad1d3b01b	t	2011-11-21 22:48:45.76903	2011-11-21 22:43:46.856017	1	1995-01-01	\N	f	davidd_BMB@hotmail.com	t
1015	Renayra	renayralopes@hotmail.com	Renayra	@		16dc119f4d9e0e53b24b88e4281e9ba1	f	\N	2011-11-18 17:49:19.422565	2	1990-01-01	\N	f		t
1049	Rafael Gomes da Costa	hop_R@hotmail.com	DJ Rafael Gomes	@DJRafael_Gomes	http://facebook.com/rafael.gomes123	c18981d54e4a31e7051445483a428ff1	t	2011-11-20 14:16:58.216939	2011-11-19 12:32:20.231922	1	1990-01-01	\N	f	hop_r@hotmail.com	t
1110	FRANCILINA PRISCILLA RIBEIRO HOLANDA	francilinapriscillaejovem.pris@gmail.com	priscilla	@		0582520609c151f284ee16546e01082d	t	2011-11-21 11:18:44.864012	2011-11-21 10:55:30.115905	2	1993-01-01	\N	f		t
302	Michael Guimarães	guimaraes.miweb@gmail.com	Michael	@mgaweb		771f49bc0c791af29265b979aa82f2f7	t	2011-11-19 12:53:34.068391	2011-10-13 20:43:29.01891	1	1992-01-01	\N	f	guimaraes.miweb@facebook.com	t
1263	Fernando Oliveira Rodrigues	oliveiraenois09@hotmail.com	fernando	@		8018b5fc1476d6f50bc8d203fe72cf2a	t	2011-11-22 09:48:01.90318	2011-11-22 09:45:26.227964	1	1995-01-01	\N	f		t
1369	Caique Carvalho Laurentino	wilianati@gmail.com	Caique	@		adf6c18c237a7b2c916d5923e6de3206	f	\N	2011-11-22 12:14:54.38295	1	2003-01-01	\N	f		t
1375	Thiago Vieira da Paz	programadorpaz@gmail.com	thiagopaz	@thiago_java_php	http://www.thiagopaz.com.br	1c7bbdd5ffcd06c5e084c3a32be37954	t	2011-11-22 13:00:46.967342	2011-11-22 13:00:09.149596	1	1991-01-01	\N	f	thyagogameover@hotmail.com	t
1275	Amanda Patricia Coelho da Silva 	amandapatricia94@gmail.com	Amanda	@		b2cb10e895805298f27f7cf6544670b8	f	\N	2011-11-22 09:52:14.925084	2	1994-01-01	\N	f		t
1328	henrique amaro de sousa	has3@pop.com.br	henrique	@		16cd3d665ebfcd3f3dd11ee9f7091aa9	f	\N	2011-11-22 11:05:22.63377	1	1970-01-01	\N	f		t
1591	Keslei	valeriamaria1982@live.com	b-boy 	@		ad47c284fd0db73acd84c7b8b2d24ff5	f	\N	2011-11-22 18:21:56.035881	1	1996-01-01	\N	f		t
2117	douglas	douglaskonox1@gmail.com	bernardo	@nenhum		a502a66c5f35994853ba3ae930c666cc	f	\N	2011-11-23 17:54:42.135732	1	1994-01-01	\N	f	douglasomx@gmail.com	t
2187	charlly gabriel	charlly_tuf_12@hotmail.com	bielzim	@		d0572f0444ffa89e4dc0b69b9549e9c5	f	\N	2011-11-23 20:04:05.339751	1	1996-01-01	\N	f		t
912	Robênia Vieira de Almeida	robenia_almeida@hotmail.com	Neninha	@		6cec55050f5906b646a176f70daa1003	t	2011-11-16 14:47:48.804907	2011-11-16 14:40:35.641612	2	1993-01-01	\N	f	robenia_almeida@hotmail.com	t
918	Felipe De Sousa	sousa.felipe06@gmail.com	Joby..	@		bfad04102d2039a67440e9bc32bc5224	t	2011-11-16 15:18:21.845335	2011-11-16 14:48:02.422464	1	2011-01-01	\N	f	felipe.nagato@hotmail.com	t
1897	GILMARA LIMA PINHEIRO	gillmarapinheiro@gmail.com	Gilmara Pinheiro	@gilpinheiro		e10adc3949ba59abbe56e057f20f883e	f	\N	2011-11-23 12:53:56.983311	2	1989-01-01	\N	f	gillmarapinheiro@gmail.com	t
1710	GINALDO ARAÚJO DA COSTA JÚNIOR	juniorginaldo@yahoo.com.br	Biscoito	@		0423d3f3c6c0f258e559ed134ae3e71b	f	\N	2011-11-23 00:14:34.19277	1	1993-01-01	\N	f	juniorginaldo@facebook.com	t
931	diego alcantara de maria	diegoalcantaram@hotmail.com	diegoam	@		de0bea73f180adefff7c98a3a3eece87	t	2011-11-16 15:46:24.896287	2011-11-16 15:45:11.234561	1	2011-01-01	\N	f	diegoalcantaram@hotmail.com	t
942	matheus sabino portela	matheussabino_11@hotmail.com	sabino	@		df2b261016c9cd742f4ebbeb4bf1a805	t	2011-11-16 22:48:21.88937	2011-11-16 22:46:26.2307	1	1995-01-01	\N	f	sabino.cabal@hotmail.com	t
2514	Sandra Mendes De Oliveira	sandramendesccd@gmail.com	sandrinha	@		a81f7232fa8b22e2cdbaa77f0f01f542	f	\N	2011-11-24 20:27:52.982171	2	1984-01-01	\N	f		t
922	Allef melo silva	allef_mad@hotmail.com	allef melo	@		fbb748b7e00705f779ae69df9cdeefb4	t	2011-11-16 15:44:17.261914	2011-11-16 14:55:11.489655	1	2011-01-01	\N	f	allef_mad@hotmail.com	t
1040	GREGORY CAMPOS BEVILAQUA	gregory-cb@hotmail.com	Gregory	@		04c8fc11188c19e44f41bf0f67961278	t	2012-01-16 10:58:21.344193	2011-11-19 00:29:44.537665	1	1993-01-01	\N	f		t
1036	Daniel de sousa torres pereira	daniel_x-mem@hotmail.com	Just Of Hell	@JustOfHell		aa47f8215c6f30a0dcdb2a36a9f4168e	t	2011-11-23 13:35:50.434259	2011-11-18 22:40:22.438243	1	1992-01-01	\N	f	daniel_x-mem@hotmail.com	t
915	Amanda Sousa Ramos 	amanda_ramos16@live.com	Amandinha	@		8071a287759f2d3befd4614090622d45	t	2011-11-16 15:02:40.313395	2011-11-16 14:44:25.548111	2	1994-01-01	\N	f	amanda_ramos16@live.com	t
734	HELCIO WESLEY DE MENEZES LIMA	helciowesley@hotmail.com	HELCIO	@		c3e6244324d91af30a29631e46fe0777	f	\N	2011-11-11 02:15:21.882255	1	2011-01-01	\N	f	HELCIOMILENA@HOTMAIL.COM	t
2622	Maria Darlice Souza Lima	mac.strategia@hotmail.com	Darlice	@		ffeaa43be260b6beab731e5a4db384d4	f	\N	2011-11-26 09:10:05.808955	2	2002-01-01	\N	f		t
958	Clodoaldo Lopes Albuquerque	clodoaldo.lopes.10@hotmail.com	cloo'h	@		60bd8155c4108f08be3e6b777eaf8e5a	t	2011-11-17 09:24:37.440867	2011-11-17 09:18:13.277631	1	1995-01-01	\N	f		t
991	wilker costa da silva	wilkerlancelot@hotmail.com	lancelot	@		8fa79caaff3ebddf2f2c73ef6b34b6ec	t	2011-11-17 23:51:55.496217	2011-11-17 23:45:34.284496	1	1990-01-01	\N	f	wilkerlancelot@hotmail.com	t
1627	Adriana Maria Silva Costa	drizinha_santinha@hotmail.com	drizinha	@		32928b22f2e114ec3bd80c420d52872c	f	\N	2011-11-22 20:36:51.489825	2	1977-01-01	\N	f	drizinha_santinha@hotmail.com	t
417	IENDE REBECA CARVALHO DA SILVA	bekinha-carvalho@hotmail.com	Bekinha	@		b3e877ec7e411a70afb727db8b280c2a	t	2012-01-16 08:41:21.18171	2011-10-23 19:32:57.944197	2	1991-01-01	\N	f	bekinha-carvalho@hotmail.com	t
1085	WALTER JHAMESON XAVIER PEREIRA	walterjhamesoon@gmail.com	walterjxp	@walterjhameson		1637b1ec40f59a00324cc634b3e890ff	t	2011-11-20 18:36:12.260926	2011-11-20 18:35:20.304783	1	2011-01-01	\N	f	walterjhamesoon@gmail.com	t
971	Halley da silva pinto	keydash_1@hotmail.com	Keydash	@		07a1097effdf7a6298a6aae5f507f5ab	f	\N	2011-11-17 10:35:18.796416	1	1985-01-01	\N	f	keydash_1@hotmail.com	t
975	Lucas Castro de Aquino	lucacastro22@hotmail.com	Lucas Dx	@		55e9fb759e308d9ee58e28decb5ba1b8	t	2011-11-17 14:08:27.437068	2011-11-17 14:07:08.15467	1	1996-01-01	\N	f	lucacastro22@hotmail.com	t
997	Tiago Bezerra	tiago.tt@hotmail.com	sinnes7k^	@MALDITOHANTARO		13dbe1c0b967db9e33257bfd8db88fd8	t	2011-11-18 12:01:26.368528	2011-11-18 11:58:34.416165	1	1994-01-01	\N	f	tiago.tt@hotmail.com	t
1912	Paulo Sérgio	paulo.15@hotmail.com	Paulo Sérgio	@		67c00bc147d9905833e8518e199e5bb1	f	\N	2011-11-23 14:26:43.076686	1	1994-01-01	\N	f		t
978	Kleverland Sousa	kleverland@gmail.com	klever	@		5c49c15dea510f989fb67cce0a9f7f37	t	2011-11-17 15:20:48.325205	2011-11-17 15:18:32.168227	1	1990-01-01	\N	f		t
1007	Ana Erika Rodrigues Torres	ana_erika12@hotmail.com	aninha	@anaerikaoficial		305fd0f21850f76ee8370a6109303181	t	2011-11-18 16:57:06.033201	2011-11-18 15:42:10.729297	2	1996-01-01	\N	f		t
981	tanila	tanila_martins6@hotmail.com	tanizinha	@tanilasilva		900bf37798631c3bb7303b3541660a45	t	2011-11-17 17:12:38.391394	2011-11-17 17:07:47.790345	2	1992-01-01	\N	f	tanila_martins6@hotmail.com	t
1708	joao vitor sena de souza	osjonathas@yahoo.com.br	joao vitor	@		14b12c553017496e28e589139ca56016	f	\N	2011-11-23 00:06:49.765183	1	2000-01-01	\N	f		t
937	Valrenice Nascimnto da Costa	valrenicec@gmail.com	Valrenice	@valrenice		656c84def6260f34bc4b99e32efa094a	t	2012-01-13 20:43:39.682876	2011-11-16 20:59:50.417532	2	2011-01-01	\N	f	valrenice@yahoo.com.br	t
1011	Virginia Mariano	vivi_-_12@hotmail.com	Viiiih	@		30bead993bcb28b1572a62a11f0e4cd5	f	\N	2011-11-18 17:03:03.746009	2	1996-01-01	\N	f	vivi_-_12@hotmail.com	t
1092	Ana Karolina Moura Coelho	ana.karolina.moura@hotmail.com	karolzinha	@		4883354013f88db30e5f0cd78d094521	t	2011-11-21 00:00:00.469024	2011-11-20 23:55:36.008464	2	1993-01-01	\N	f	ana.karolina.moura@hotmail.com	t
1014	Lucas Alencar dos Santos Alves	lukff23@rocketmail.com	Lucas Alencar	@		17a44817ae7abaa9bfd53568a8238ef7	t	2011-11-20 21:16:45.030889	2011-11-18 17:21:23.481752	1	1995-01-01	\N	f		t
1370	PEDRO RODRIGUES DOS SANTOS NETO	pedro.neto_santos@hotmail.com	PEDRO NETO	@		27a31720015a9a34250bb65b19f1d281	f	\N	2011-11-22 12:16:40.46563	1	1995-01-01	\N	f		t
2212	Paloma Cunha Severino	palomaguedes03@hotmail.com	Paloma	@		ba5d2ec539a539dedaace0dc5af6052d	f	\N	2011-11-23 21:24:25.341316	2	1995-01-01	\N	f	palomaguedes03@hotmail.com	t
2250	Francisco Mateus Sousa Paz	Matewspaz19@hotmail.com	Mateus	@		946a45214fbcec6c0ccaa6c2b9117b61	f	\N	2011-11-24 09:02:44.772348	1	1994-01-01	\N	f		t
1056	Elizabeth 	ayame.fumetsu@gmail.com	Bethhh	@		b4c61caaf5c055e1cda928a6f72b2400	t	2011-11-24 11:53:47.058642	2011-11-19 14:40:55.374896	2	1992-01-01	\N	f		t
1111	Francisca Patricia da Silva Campelo	patricia.campy@gmail.com	Patricia	@		3050fe47a8cc4f9b17bf53d5f856162d	t	2011-11-21 11:22:00.460843	2011-11-21 10:57:02.844146	2	1995-01-01	\N	f		t
976	Antônio César de Castro Lima Filho	cesar.c.lima@hotmail.com	cesinha	@c_lima5		35cbdb53350fed8229addcebfa8f97d0	t	2011-11-19 15:21:42.637943	2011-11-17 15:01:22.956227	1	1994-01-01	\N	f	cesar.c.lima@hotmail.com	t
641	Arthur Breno	arthurtuf@hotmail.com	Tutu  	@		0dbac7fa8e98f864d0703507a1947e73	t	2011-11-21 23:07:22.122939	2011-11-08 23:16:11.16956	1	1993-01-01	\N	f	arthurtuf@hotmail.com	t
1462	Adynna Tévina de Castro Silva	adynnatevina@hotmail.com	Tévina	@AdyTete		2c4ebe7efd3b4a386d3a1ccf46caa146	f	\N	2011-11-22 16:54:52.06175	2	1995-01-01	\N	f		t
1122	Tallisson Italo Ferreira De Sousa	Tallissom16@yahoo.com.br	Italo.	@		4214e79f297126e4198f8e084f3bfbf3	f	\N	2011-11-21 12:33:37.924252	1	1989-01-01	\N	f	Tallissom16@yahoo.com.br	t
1126	Josué Keven da Silva Galvão	josue_sana@hotmail.com	Keven22	@		8153dfce41607f8cb4629e6d3c5bc5cf	t	2011-11-21 13:34:58.036384	2011-11-21 13:19:35.149632	1	1996-01-01	\N	f		t
1256	Janne Keully da Silva Lopes	emimsette@live.com	janne keully	@		14170c9c3eb08adf57e1139552ffb15b	t	2011-11-22 09:56:20.469191	2011-11-22 09:43:08.572967	2	1994-01-01	\N	f	emimsette@live.com	t
1376	RONIERE AZEVEDO DA SILVA	ronierea@hotmail.com	RoniAzvdo	@ronierea		e5ddd115012b7873b9afcc6bf37d8180	t	2011-11-22 13:13:49.349131	2011-11-22 13:04:57.976458	1	1984-01-01	\N	f	ronierea@hotmail.com	t
1592	Gabriella Lima	gabriellalima_13@hotmail.com	Gabriella	@		323725f401e38197199433bb978f6d8f	t	2011-11-22 18:25:42.453688	2011-11-22 18:22:11.388846	2	1995-01-01	\N	f	gabriellalima_13@hotmail.com	t
1016	EMERSON DUARTE	emersonduarte1@gmail.com	MERSIN	@		0030e00c925d012f574ff43cd1569f1f	t	2011-11-18 18:54:29.256667	2011-11-18 18:50:59.181113	1	1988-01-01	\N	f	emersonduarte1@gmail.com	t
3373	AUGUSTO EMANUEL RIBEIRO SILVA	augustoers@gmail.com	AUGUSTO EM	\N	\N	e61fac163753e5f5696bf7f720da1e7d	f	\N	2012-01-10 18:25:51.258696	0	1980-01-01	\N	f	\N	f
1017	JENILSON BORGES NASCIMENTO	jenylson.borges@hotmail.com	JENYLSON	@JENYLSOBN		3a66390928b7e0d4058157bc1ebc8dd1	t	2011-11-18 18:54:44.772209	2011-11-18 18:51:00.031742	1	1990-01-01	\N	f	JENYLSON.BORGES@HOTMAIL.COM	t
1019	Allan Kaio	akdito@gmail.com	AKdito 47	@		465aec1a178ab76780787e563b4be62a	f	\N	2011-11-18 18:56:35.585628	1	1990-01-01	\N	f	akdito@gmail.com	t
1027	francisco eliivaldo cruz araujo	elivaldocruzaraujo@gmail.com	araujo	@		4443263005c9f5ca5b51eaf0c02ac02f	t	2011-11-18 20:31:29.296178	2011-11-18 20:19:24.529695	1	1992-01-01	\N	f		t
1023	ISLAS GIRÃO GARCIA	islasg.garcia@gmail.com	Islash	@		ec1fd0603ad457fdca554a42f922c837	t	2012-01-16 12:35:17.596809	2011-11-18 19:26:41.224203	1	1994-01-01	\N	f	islasgarcia@live.com	t
1020	Gilfran Ribeiro	contato@gilfran.net	Gilfran	@Gilfran	http://blog.gilfran.net	e41e9876e54581a02d46990accf98e7c	t	2011-11-18 19:13:06.446053	2011-11-18 19:12:30.86776	1	2011-01-01	\N	f	eu@gilfran.net	t
521	JACKSON DENIS RODRIGUES DA COSTA	jacksondenisrodrigues@gmail.com	jdkitom	@		9c646f146e16ee2c5d87011e27d09125	t	2012-01-16 21:21:27.454469	2011-11-03 11:41:55.197748	1	1990-01-01	\N	f		t
1093	Deyvison Ximenes Nobre	deyvison.ximenes@hotmail.com	Ximenes	@		77c9192ac008dc696c5c2ade8aaf3b3e	f	\N	2011-11-21 00:16:13.037042	1	1996-01-01	\N	f		t
646	EMANUEL ROSEIRA GUEDES	emanuelrguedes@hotmail.com	Emanuel	@emanuelrguedes	http://www.orkut.com.br/Main#Profile?uid=9432035428913907001	0b00eed09f7690adb58596b7f81571fb	t	2012-01-15 21:37:36.696395	2011-11-09 10:27:55.197417	1	1995-01-01	\N	f	emanuelrguedes@hotmail.com	t
3374	BRENDO DE SOUSA ALVES	brendo2008@gmail.com	BRENDO DE 	\N	\N	ea0cd4d78f24719a89ddd4ef51c2158e	f	\N	2012-01-10 18:25:51.453355	0	1980-01-01	\N	f	\N	f
996	EMMILY ALVES DE ALMEIDA	emmly_23@hotmail.com	Emmily	@		7ba100171ea3d50620063b041dd31ea5	t	2012-01-18 13:32:31.639104	2011-11-18 11:52:18.044453	2	1994-01-01	\N	f	emmly_23@hotmail.com	t
588	ERYKA FREIRES DA SILVA	eryka.setec@gmail.com	Eryka Freires	@		b8a720f7e05d9df63606d81d5004a393	t	2012-01-15 21:06:59.663283	2011-11-07 14:51:05.549578	2	1990-01-01	\N	f		t
3375	CARLOS ADAILTON RODRIGUES	adtn700@yahoo.com.br	CARLOS ADA	\N	\N	e49b8b4053df9505e1f48c3a701c0682	f	\N	2012-01-10 18:25:52.341918	0	1980-01-01	\N	f	\N	f
1037	Péricles Henrique Gomes de Oliveira	pericles_h@hotmail.com	Pericles	@pericleshenriq		45ddefed2d9e682bd6da90a11f67747d	t	2011-11-18 22:59:59.603346	2011-11-18 22:58:26.906386	1	1990-01-01	\N	f	pericles_h@hotmail.com	t
980	EUGENIO REGIS PINHEIRO DANTAS	regis_dant@hotmail.com	regisdantas	@		77744b4b713115f77d4aa39ae385eabb	t	2012-01-19 16:22:02.058001	2011-11-17 16:05:51.390327	1	1984-01-01	\N	f		t
3376	CARLOS YURI DE AQUINO FAÇANHA	c_yuri13@hotmail.com	CARLOS YUR	\N	\N	40805b9b0fb1ae92ff692eebef39f9c5	f	\N	2012-01-10 18:25:54.482031	0	1980-01-01	\N	f	\N	f
1176	José Smith Batista dos Santos	josesmithbatistadossantos@gmail.com	sumisu	@sumisu_sama		d66b468c43e7f616ae277bbf2bfb2d91	t	2011-11-21 21:02:14.979246	2011-11-21 20:57:53.617105	1	1992-01-01	\N	f	josesmithbatistadossantos@gmail.com	t
533	Hannah Leal Rabelo	hannah.rabelo@gmail.com	hannah	@hannahrabelo		ab2e739265bcfc7abf996c0fb0569e66	t	2012-01-19 20:46:02.699387	2011-11-03 23:32:22.421281	2	1990-01-01	\N	f	hannah.rabelo@gmail.com	t
1003	Andre Luiz G de Araujo	andinformatica@yahoo.com.br	AndreLuiz	@		32f00e32f91c784f2cb7e474d15ee943	t	2011-11-19 08:58:48.880323	2011-11-18 15:00:32.561228	1	1975-01-01	\N	f		t
1047	Raíssa Aragão Araújo	rhay.araujoo@hotmail.com	pequena	@littlerhaay		9691237d3c9f75dc731365f5b36aa2c7	t	2011-11-19 11:58:25.370188	2011-11-19 11:55:23.250087	2	1994-01-01	\N	f	rhay.araujoo@hotmail.com	t
1371	Rafael Oliveira	rafael@originaldesigner.com.br	Grande Rafa	@portaloriginal	http://www.originaldesigner.com.br	c9ef12a98b0f57e1e8da9ade8508884e	f	\N	2011-11-22 12:25:26.179948	1	1986-01-01	\N	f		t
1463	Breno Barroso Rodrigues	breno_barroso12@hotmail.com	brenin	@breno_barroso		f48a113d40974b677454331d52185a02	t	2011-11-22 16:56:34.37981	2011-11-22 16:55:34.66119	1	1995-01-01	\N	f		t
3378	CLAYTON BEZERRA PRIMO	claytonbp@oi.com.br	CLAYTON BE	\N	\N	4a6f57c68f8280a164ea0b2782e82a8f	f	\N	2012-01-10 18:25:55.85234	0	1980-01-01	\N	f	\N	f
1051	Franklin Gonçalves Rodrigues	franklin201121@hotmail.com	frankl	@		6fef42b707ee98f3e32b283a12db402a	t	2011-11-19 12:48:28.42001	2011-11-19 12:43:38.354197	1	1991-01-01	\N	f	franklin201121@hotmail.com	t
1123	Tiago Bezerra Sales de Almeida	tiagosales9@gmail.com	Tiaguito	@LeTiaguito		1bc427198b055c38357079e27206b2f4	t	2011-11-21 12:44:00.678931	2011-11-21 12:40:11.500147	1	1988-01-01	\N	f	tiagosales9@gmail.com	t
346	wesley jorge gomes de souza	millenium_guitar@hotmail.com	wesley loureiro	@		b5ee046698134ded6c1f923048345d48	t	2011-11-19 14:17:13.155471	2011-10-17 14:12:02.954796	1	1988-01-01	\N	f		t
1184	André Victor de Souza Siqueira	elyson_011@hotmail.com	André	@		b8f8bee7c9e40eb003b1b101bdb4a3c6	t	2011-11-21 22:47:29.746188	2011-11-21 22:43:14.572852	1	2011-01-01	\N	f		t
1053	Elizabeth da Paz Santos	ame.uchiha@gmail.com	Beth Uchiha	@BethUchiha	http://theculturainutil.wordpress.com	b4c61caaf5c055e1cda928a6f72b2400	t	2011-11-19 14:57:43.483649	2011-11-19 14:38:02.751172	2	1992-01-01	\N	f	ame.uchiha@gmail.com	t
1190	Davi Miranda	davimiranda96@hotmail.com	Paulista	@Davi_dh	http://www.davilinks.xpg.com.br/	e59b8c708c3c5cfc7735b530389e62a4	t	2011-11-21 23:07:47.796405	2011-11-21 23:03:31.092387	1	1996-01-01	\N	f	davimiranda96@hotmail.com	t
1057	Roberta Maciel Santana	robertahtadobj@hotmail.com	Roberta	@		9ab34fb660e1b15469f0c747b2008bdb	t	2011-11-19 16:09:18.467893	2011-11-19 16:01:01.799863	2	1994-01-01	\N	f	robertahtadobj@hotmail.com	t
1197	Ivanilson da Silva Lima	ivanilson.isl@gmail.com	Ivanilson Lima	@ivanilson_lima	http://ivanilsonlima.wordpress.com	80945966549fcd8bafad0381bb6c499c	f	\N	2011-11-21 23:34:30.819183	1	1985-01-01	\N	f	ivanilson.isl@gmail.com	t
1058	Mailton da Cruz Silva	msilva_rc06@hotmail.com	Mailton	@m_cruz82		259790bef50cdb67067504831e7c668d	t	2011-11-19 17:05:30.516719	2011-11-19 16:46:56.636687	1	1982-01-01	\N	f	msilva_rc06@hotmail.com	t
1285	Amanda Patricia Coelho da Silva	pauloricardomaster@hotmail.com	Amanda	@		806bfba1f24f122d0f83028a3d6978a1	f	\N	2011-11-22 09:58:54.914893	2	1994-01-01	\N	f		t
1202	Camila Brena	camilabrena@hotmail.com	Camila	@Camilabga		c746a021d6e8e3200c499c098a8e865d	t	2011-11-22 03:30:38.922459	2011-11-22 03:29:14.001367	2	1991-01-01	\N	f	camilabrena@hotmail.com	t
1291	Amanda Patrícia Coelho da Silva	paulinhoricardo22@hotmail.com	Amanda	@		fd97e160d24612cabba7b54f458cab98	t	2011-11-22 10:06:08.715218	2011-11-22 10:02:55.310246	2	1994-01-01	\N	f		t
1377	Francisco Gildevanio Bezerra Sales Junior	juniordusdificeis@hotmail.com	Júnior	@	https://www.facebook.com/profile.php?id=100002287412456	8a39551e0ba3741f6e70380b90a75bbe	f	\N	2011-11-22 13:12:05.030331	1	1995-01-01	\N	f	juniordusdificeis@Hotmail.com	t
1593	Francimilia Pamela Narkilia da Silva	pamela_pv007@hotmail.com	pamela	@		3c9b83741e1af6e9a79ee7e821baa48c	t	2011-11-22 18:26:27.425656	2011-11-22 18:24:16.252649	2	1988-01-01	\N	f		t
1311	tiago nobre	morcegodomal@hotmail.com	Little Bastard	@		1700dbfab5d7326fcc7e7c354e0480e1	f	\N	2011-11-22 10:30:31.891372	1	1993-01-01	\N	f	morcegodomal@hotmail.com	t
1628	Eudázio Lima da Silva	dazoamanari@hotmail.com	eudazio	@		e36b2061a9dd31412749e786e3bba4b7	f	\N	2011-11-22 20:37:56.194422	1	1995-01-01	\N	f		t
1605	Matheus Martins de Menezes	Matheusmh2o@hotmail.com	Vicent Soldin	@		e0ed467d2284c59b548d1f777491c136	f	\N	2011-11-22 19:18:15.958828	1	1996-01-01	\N	f		t
1640	Aurelícia Rodrigues	aurelicia_eu@hotmail.com	Licinha	@		d00b53279eb60eac34755aacc507e0cb	t	2011-11-22 21:24:37.154556	2011-11-22 20:50:38.696255	2	1995-01-01	\N	f	aurelicia_eu@hotmail.com	t
1060	Samuel Ramon	samuelrbo@gmail.com	samuelrbo	@samuelrbo	http://phpcafe.com.br/autor/samuelrbo/	c604308cd47085ab70a087cdb90d9910	t	2011-11-19 17:35:13.500649	2011-11-19 17:33:32.511852	1	1985-01-01	\N	f	samuelrbo@gmail.com	t
1068	Saulo Vasconcelos Cruz	saulo.-.cruz@hotmail.com	SauloXp	@Saulo_xp		ea52462bc399852759b674343b9772bf	t	2011-11-19 23:09:21.366393	2011-11-19 22:52:46.919129	1	1992-01-01	\N	f	saulo.-.cruz@hotmail.com	t
1094	João Parente	joaoparente.design@gmail.com	Tonhão	@juanparente	http://www.wix.com/joaoparentedesign/fotografia#!	77b2c08dbc9b174265331a39b58d3f2d	t	2011-11-21 02:54:28.698273	2011-11-21 02:52:18.147461	1	1988-01-01	\N	f	joaomanowar@hotmail.com	t
1177	Cleonice Batista de Oliveira Neta	cleopusculo@gmail.com	Cleo   	@		90636552beebdaca4746e37e24641d9c	f	\N	2011-11-21 21:42:32.395013	2	1995-01-01	\N	f		t
616	EVERTON BARBOSA MELO	vertaocnm@gmail.com	Evertonbrbs	@vertaocnm		5cb9497be721830566c42e14627e5fdd	t	2012-01-10 18:26:01.587784	2011-11-08 01:35:32.871615	1	1990-01-01	\N	f	vertaocnm@gmail.com	t
1372	Day maciel Souza	doce.d@live.com	Daymaciel	@		3e4f92cbdbf7ac807f32126ad0f3fa7a	t	2011-11-22 12:40:04.34105	2011-11-22 12:35:30.732205	2	1992-01-01	\N	f	day_deliciaa@hotmail.com	t
626	FAUSTO SAMPAIO	fausto.cefet@gmail.com	Fausto	@faustosampaio		2c9d4e37d5fdd3b5fd845b353c41f9a4	t	2012-01-15 23:39:31.594304	2011-11-08 15:34:19.906815	1	1987-01-01	\N	f	fausto.cefet@gmail.com	t
3379	CLEILSON SOUSA MESQUITA	cleilson.crazy@gmail.com	CLEILSON S	\N	\N	912d2b1c7b2826caf99687388d2e8f7c	f	\N	2012-01-10 18:25:55.983059	0	1980-01-01	\N	f	\N	f
523	FELIPE MARCEL DE QUEIROZ SANTOS	kreator6@hotmail.com	felip.drakkan	@felipdrakkan		741679251c4470ccab05fca376c703b4	t	2012-01-16 11:01:47.474819	2011-11-03 12:19:58.687108	1	1989-01-01	\N	f	kreator6@hotmail.com	t
2515	Daniela	danielinha_gsd@hotmail.com	Daniela	@		882eb40853149803b2b08b11bb51d6e8	f	\N	2011-11-24 20:38:07.889985	2	2011-01-01	\N	f	danielinha_gsd@hotmail.com	t
673	FERNANDA STHÉFFANY CARDOSO SOARES	nandastheff@hotmail.com	Nanda'S	@nandascsoares	http://universodosbabados.blogspot.com/	5f1b5092e4188596638cbb59db428b83	t	2012-01-15 22:17:42.318477	2011-11-09 20:52:12.802505	2	1990-01-01	\N	f	nandastheff@hotmail.com	t
1087	Mateus	mateussued@hotmail.com	Mateus	@teusvieira		8108e45f70dbaaacd9d3cde24c9c9aa2	t	2011-11-20 19:34:07.262756	2011-11-20 19:33:08.21941	1	1995-01-01	\N	f	mateussued@hotmail.com	t
2545	Camila Moraes Siebra	camila.siebra@hotmail.com	Camila	@		a6571c5a11f6ce897369e2a397365380	f	\N	2011-11-25 09:31:17.001653	2	1989-01-01	\N	f		t
1113	Francisca Patricia da Silva Campelo	patynhacampelo@hotmail.com	Patricia	@		571827ddaae4773ec708d6120f5fb016	f	\N	2011-11-21 11:01:23.940487	2	1995-01-01	\N	f		t
1192	Josimar Dantas Marques	josimardantas_112@hotmail.com	LooksXD	@JosimarXD		63f1aadeed1f4c288fb89b2a8c72b16d	t	2011-11-21 23:19:20.084633	2011-11-21 23:08:57.845612	1	1993-01-01	\N	f	josimardantas_112@hotmail.com	t
1119	Francisca Jessica Sousa Moura	jmoura82@yahoo.com	Jessica	@		e99d7a9c0a0f0fe60c27932cc6b43b03	f	\N	2011-11-21 11:10:14.45634	2	1991-01-01	\N	f	jmoura82@yahoo.com	t
1464	Flávio de Oliveira	flaviooliveira.jgt@gmail.com	Flávio	@		30b6328dcd49e885d39c5b1b61bac8d6	f	\N	2011-11-22 16:55:42.979495	1	1994-01-01	\N	f	flaviotuf90@hotmail.com	t
3380	DALILA DE ALENCAR LIMA	dalila8855@hotmail.com	DALILA DE 	\N	\N	8e296a067a37563370ded05f5a3bf3ec	f	\N	2012-01-10 18:25:56.231778	0	1980-01-01	\N	f	\N	f
2572	Reydon Gadelha Moreira	eu_sempre_fui_ocao@hotmail.com	Reydondon	@		3f799421ef7899732573f474113fbaf9	f	\N	2011-11-25 13:08:09.872374	1	1992-01-01	\N	f	eu_sempre_fui_ocao@hotmail.com	t
1286	Ana Paula Pinheiro Barbosa	aniiinhaak@hotmail.com	Aninha	@		d1cc26ae2b51ce56934d6bcde975dd7d	t	2011-11-22 20:30:58.04193	2011-11-22 10:00:07.14722	2	1994-01-01	\N	f		t
3381	DANIEL ALVES PAIVA	danielpaiva.alves@gmail.com	DANIEL ALV	\N	\N	606a63ca8a201e370b917274bd79392e	f	\N	2012-01-10 18:25:56.33576	0	1980-01-01	\N	f	\N	f
1198	Alan Ponte Parente	alanponte@yahoo.com.br	Alanzinho	@		347e3fb95ea3ba1c7468dc2c31cc59b4	t	2011-11-22 01:00:42.624308	2011-11-22 00:41:12.265964	1	1991-01-01	\N	f	alanponte@yahoo.com.br	t
3382	DANIEL GOMES CARDOSO	dan-eumesmo@hotmail.com	DANIEL GOM	\N	\N	e4c5e82828ec464c48cf80c2ee6e62e9	f	\N	2012-01-10 18:25:56.429215	0	1980-01-01	\N	f	\N	f
1136	Ailson Girão Pinto Filho	ailsongirao@bol.com.br	McDavis	@		81b8768e0e97e4504d653ea24656ffcf	f	\N	2011-11-21 15:39:15.374469	1	1985-01-01	\N	f	ailson.mcdavis@bol.com.br	t
1594	joaquim gomes dos santos neto	joaquim-mpe@hotmail.com	coiote	@joakimswing		863f2bc3c6f3461d2fd390282494a977	t	2011-11-22 19:02:13.642743	2011-11-22 18:36:47.118384	1	1994-01-01	\N	f	joaquim-mpe@hotmail.com	t
1138	maycon de araújo matos	maycondearaujomatos@Gmail.com	Maycon	@		66223e4bd738bb1d5e5ed256fac39b05	f	\N	2011-11-21 15:53:58.181979	1	1993-01-01	\N	f		t
1709	Igor Sena de Oliveira	osjonathas@gmail.com	Igor Sena	@		a275e48fa484b68d3948ee92b30b1ac6	f	\N	2011-11-23 00:12:40.410882	1	1997-01-01	\N	f		t
1292	Janne Keully da Silva Lopes	jannekeully23@hotmail.com	janne keully	@		c76d60fb5dbf4ebad5070605e932bad2	f	\N	2011-11-22 10:05:20.421535	2	1994-01-01	\N	f	jannekeully23@hotmail.com	t
1203	wevergton magalhães	wevergton-costha@hotmail.com	wevergton	@		72a87c7ea18acaac80144bd48dd99679	f	\N	2011-11-22 07:49:21.360898	1	1994-01-01	\N	f		t
1173	EMANOEL CARLOS SILVA ARAÚJO	manu_araujo2009@hotmail.com	Carlin	@manoaraujo		e02b7c3d94bd46d2fc5c4d365aa714ed	t	2011-11-22 13:16:32.500915	2011-11-21 20:44:56.374241	1	1991-01-01	\N	f	manu_araujo2009@hotmail.com	t
681	daiane sinara	dayanesynara@gmail.com	sinara	@		4be9d8b0e2f9e8e3836e3f40a861fef3	t	2011-11-22 10:07:23.677589	2011-11-10 12:00:40.767076	2	1988-01-01	\N	f		t
1299	savio thales	saviothales@hotmail.com	poker face	@saviothales		64188394e969cf793175eca93db51602	f	\N	2011-11-22 10:11:12.233047	1	1992-01-01	\N	f	saviothales@hotmail.com	t
1312	Rayanne Sampaio	rayannesampaio123@hotmail.com	Rayanne	@rayanne_sampaio		9f637664c6525b9c20898d741be8a033	f	\N	2011-11-22 10:40:00.443434	2	1989-01-01	\N	f	rayannesampaio123@hotmail.com	t
1398	Paulo Giuseppe Pineo  Araújo	paulinho.giuseppe@gmail.com	Paulinho	@		250ef105bc629472b3d940df4ff745fc	t	2011-11-22 15:05:55.720817	2011-11-22 14:48:30.736995	1	1992-01-01	\N	f		t
1405	carlos rafael medeiros viana	carlosrafael118@gmail.com	carlos rafael	@		02e0c60405ef079e1e0b63d06987c139	f	\N	2011-11-22 15:33:54.177922	1	1988-01-01	\N	f	carlosrafael118@gmail.com	t
1491	Francisco Anderson Silvino Mendes	franciscoandersonas@hotmail.com	Montanhão	@		d47821cb6c1b00fdc23a6cd02ca733e9	f	\N	2011-11-22 17:05:19.192559	1	1991-01-01	\N	f	franciscoanderson@hotmail.com	t
1412	Nycaelle Medeiros Maia	nycaelle11@hotmail.com	Nyca Nyca	@		c0dbc34538838097778e767af6f65d06	t	2011-11-22 16:13:39.666743	2011-11-22 16:08:39.280749	2	1993-01-01	\N	f	nycaelle11@hotmail.com	t
1606	Francisco Daniel Gomes de Oliveira	franciscodaniel.18@gmail.com	Daniel	@		a75ff56d110bd69930ce66ecc4462e51	t	2011-11-22 19:51:26.847687	2011-11-22 19:32:36.753097	1	1979-01-01	\N	f		t
2091	Lucas paulino Silva do Nascimento	lucasmissaomudial@hotmail.com	lucas_linux	@		bd6291a1a1a36ec0d910bf0a4367bc4d	f	\N	2011-11-23 17:32:34.705996	1	1989-01-01	\N	f		t
1731	kevin marlon santos almeida	kevinsantos15@hotmail.com	marlon	@		e11c66e444d52d6ca9559b6562150755	f	\N	2011-11-23 09:24:44.680882	1	1994-01-01	\N	f		t
1759	Régia	regiaoliveirainfo@yahoo.com.br	Reginha	@		5b67008d70c07dba27cda60c6068c00b	f	\N	2011-11-23 09:33:22.979263	2	1994-01-01	\N	f		t
1771	Henrique Mateus Chaves da Silva Martins	henryk.zetsu@gmail.com	tobinho	@		7a0183393516cc7682b0b79ee5a61249	f	\N	2011-11-23 09:37:53.087227	1	1995-01-01	\N	f		t
2232	Pedro Henrique Uchoa do Amarante	pedrohenriqamarante@gmail.com	Pedro Amarante	@PedroAmarante18		a131e5eff55a98f683838662a1681fba	f	\N	2011-11-24 00:08:40.352842	1	1991-01-01	\N	f	pedro.amarante1@facebook.com	t
1061	Matheus Lima	limatheus@oromail.com	Matheus	@		4d0dfac643678b6dcec2f86fa6f7f6c4	t	2011-11-19 17:44:56.163638	2011-11-19 17:43:33.746327	1	1997-01-01	\N	f		t
1069	Carlos Yuri	carlos.yuri.black@gmail.com	carloosyuuri	@		a9b179efa4d41c5790f00443e14bc877	t	2011-11-19 23:54:43.023698	2011-11-19 23:30:34.381398	1	1995-01-01	\N	f	c_yuri13@hotmail.com	t
3383	DANIEL HENRIQUE DA COSTA	danieldhc86@hotmail.com	DANIEL HEN	\N	\N	122625158b08dc301be395412ee89f95	f	\N	2012-01-10 18:25:56.569654	0	1980-01-01	\N	f	\N	f
1095	FLAVIANA CASTELO BRANCO CARVALHO DE SOUSA	flavi.fairy@gmail.com	flavicastelo	@tarjabranca		eff0dc9e12844d33a20f25181e51cb2b	t	2012-01-15 22:33:51.075434	2011-11-21 09:11:46.891135	2	1990-01-01	\N	f	flavianacastelo@yahoo.com.br	t
1062	Raquel	raquelrocharodrigues@hotmail.com	Raquel	@quelrrocha		e793f7c70eb326eeeabae1b4af47b2c1	t	2011-11-19 17:49:35.041348	2011-11-19 17:46:06.990404	2	1988-01-01	\N	f	raquelrocharodrigues@hotmail.com	t
1178	Douglas Silva de Sousa	douglas.tiago.potter@gmail.com	dougts	@dougts		8a296f2e829e56b89758ee9fe60d4961	t	2011-11-22 00:35:09.422742	2011-11-21 21:50:50.660785	1	1993-01-01	\N	f	douglas.tiago.potter@hotmail.com	t
1133	FLAVIANA DA SILVA NOGUEIRA LUCAS	flavia.nogueyra@gmail.com	Flavia	@		ea5138e6a39b011a8da9d13d4c565fc0	f	\N	2011-11-21 15:13:15.272083	2	1984-01-01	\N	f		t
590	FRANCISCO ANDERSON FARIAS MACIEL	andersonfariasm@gmail.com	Anderson	@		05810f068168bc1d19180fb8cd04025e	t	2012-01-14 22:46:02.764721	2011-11-07 16:39:33.317404	1	1991-01-01	\N	f	andersonfariasm@gmail.com	t
848	sarah batista	sarahcharmyebarros@hotmail.com	sarah batista	@sarahbcosta		2e2d3638154696e88cf1d5720ffccf08	t	2011-11-19 18:18:36.189696	2011-11-15 23:27:46.407396	2	2011-01-01	\N	f	sarahcharmyebarros@hotmail.com	t
1373	Julian	julianleno@gmail.com	Julian Leno	@JulianLeno	http://www.dizaew.com.br	d5c149cfc0c886c62cc6c25f9c90fd00	t	2011-11-22 12:50:13.136692	2011-11-22 12:44:47.553269	1	1991-01-01	\N	f	julianleno@gmail.com	t
1080	mayara mesquita santiago	mazinha29_@hotmail.com	mazinha	@		09694b0ca4dd9da622b224e2d597ee32	f	\N	2011-11-20 15:00:00.885451	2	1992-01-01	\N	f	mazinha29_@hotmail.com	t
1595	Isabela Amnoá Medeiros Sampaio	isabelamnoa.tech@live.com	Bella, Bel	@IsabelaAmnoa		afc7812ccf591426cff312bb08770183	t	2011-11-22 19:59:29.743803	2011-11-22 18:43:42.246824	2	1995-01-01	\N	f	isabelamnoa.tech@live.com	t
3384	DANIEL JEAN RODRIGUES VASCONCELOS	cefet_daniel@yahoo.com.br	DANIEL JEA	\N	\N	71442b689327b3d764432f32b4d4accd	f	\N	2012-01-10 18:25:56.724311	0	1980-01-01	\N	f	\N	f
3385	DANIELE DO NASCIMENTO MARQUES	danielemarques1990@hotmail.com	DANIELE DO	\N	\N	16838b999f9e5680bb56a901834e03a7	f	\N	2012-01-10 18:25:56.831713	0	1980-01-01	\N	f	\N	f
888	Carlos augusto	bart-caldas@hotmail.com	Carlão	@		d4ac90c7a9b87af573ac0f6b27cf039b	t	2011-11-20 19:57:33.32804	2011-11-16 11:13:35.669859	1	1993-01-01	\N	f	bar-caldas@hotmail.com	t
1732	Elisabete	silvaelisabete11@yahoo.com.br	Bete Nascimento	@Bete_Na		3ec8c8fe596509dd2f3537487a35ea21	f	\N	2011-11-23 09:25:22.712996	2	1995-01-01	\N	f	silvaelisabete11@yahoo.com.br	t
1630	FRANCISCO ERNANDO DE SOUSA RODRIGUES JUNIOR	ernaqndolive@hotmail.com	junior	@		dfc7b52e862657bb15d89d9be54dcb9e	f	\N	2011-11-22 20:39:33.241621	1	2011-01-01	\N	f	junior02livr@gmail.com	t
3386	DANIELE MIGUEL DA SILVA	danyelle.diasd@gmail.com	DANIELE MI	\N	\N	456bfdb80a06338cdbf2dccbf2fdc1c2	f	\N	2012-01-10 18:25:56.991333	0	1980-01-01	\N	f	\N	f
1718	Paulo Welderson Santiago da Silva	paulinhoplay157@hotmail.com	Dante Sparda	@		b4c777b50583f0ea07c84b99a33a8406	f	\N	2011-11-23 07:14:50.040133	1	1995-01-01	\N	f		t
1102	FRANCISCO EVILASIO FERREIRA DA SILVA FILHO	evilasio.ti@hotmail.com	Evilasio	@		986819b38e5a18c8e39fa729534498d6	t	2011-11-21 11:52:43.767126	2011-11-21 10:18:18.916631	1	1989-01-01	\N	f		t
1199	Eder Clayton Medeiros Gomes	eder.comp.uece@gmail.com	EderClayton	@		3c1b3d790e3320bd76eb04b83737e3b4	t	2011-11-22 09:55:19.044742	2011-11-22 00:53:22.399407	1	1992-01-01	\N	f	eder.comp.uece@gmail.com	t
1913	Victor Iuri C Sousa	andersonmenezesamd@gmail.com	Iuri Sousa	@		6547d931682a92c638a9b7ecd8470d38	f	\N	2011-11-23 14:28:49.622807	1	2011-01-01	\N	f	iuriflamengo@hotmail.com	t
1378	Eden pinheiro	eden122007@hotmail.com	Edinho	@		5f8a2e8b71a78531d100c06601799a8b	t	2011-11-22 14:15:07.640402	2011-11-22 14:03:49.282597	1	1995-01-01	\N	f		t
3387	DARIO ABNOR SOARES DOS ANJOS	darioabnor@gmail.com	DARIO ABNO	\N	\N	64b51cf38f83b017d4c34d633fd840d5	f	\N	2012-01-10 18:25:57.435458	0	1980-01-01	\N	f	\N	f
1135	CLAYTON BEZERRA PRIMO	CLAYTONBP@OI.COM.BR	CLAYTON	@		a1805380fec4ce6fd59a61137e70a9d0	t	2011-11-21 15:56:48.869494	2011-11-21 15:35:13.73603	1	1989-01-01	\N	f	CLAYTONBP@OI.COM.BR	t
1204	IRAN SOUSA LIMA	iranlima222009@hotmail.com	iranzim	@iran_sousa		6f5ea6ebebb1c12f805672518534cb6e	f	\N	2011-11-22 08:54:09.778994	1	1990-01-01	\N	f	iranlima222009@hotmail.com	t
1137	Alison Monteiro	alisonmonteiro.10@gmail.com	Alison	@alisonbf		41dcdf8100ce9a801e8205ab6f4f0cf6	f	\N	2011-11-21 15:52:28.577316	1	1995-01-01	\N	f		t
1300	Anderson	anderson_uchiha@hotmail.com	Dhedaa	@Dheda10		f0c1c5ef6bd53f40bf641a9609d09ab3	f	\N	2011-11-22 10:11:16.472094	1	1994-01-01	\N	f	anderson_uchiha@hotmail.com	t
2516	maria alessandra costa	alessandra_gtb@hotmail.com	alessandra	@		60682da96be04cc773856e9b57b99088	f	\N	2011-11-24 20:44:47.722147	2	1996-01-01	\N	f		t
1607	Francisco Thiago Pessoa da Silva	liviamaria95@hotmail.com	Thiago	@		acb81fa5b421649d1fe636e1551a0cac	f	\N	2011-11-22 19:43:46.213526	1	1994-01-01	\N	f		t
1144	Francisco Edson Alves de Lima	e.alves13@gmail.com	Edson Alves	@		cb23929069eb0bbc1faf666973ceccc9	t	2011-11-21 16:15:46.842576	2011-11-21 16:13:34.582998	1	1991-01-01	\N	f	e.alves13@gmail.com	t
1306	karline	carline_vando@yahoo.com.br	kakazinha	@carline_vando		b71af9d141adacac52e59798817eedd9	f	\N	2011-11-22 10:22:29.781076	2	1992-01-01	\N	f	carlinegoncalves@hotmail.com	t
1313	ALINE MARIA RODRIGUES	ali.ny.jesus@hotmail.com	linizinha	@		01debccdf50b2aa012f1cec13b84c461	t	2011-11-22 10:53:18.663778	2011-11-22 10:41:31.184752	2	1991-01-01	\N	f	ali.ny.jesus@hotmail.com	t
1385	Ana Paula Rodrigues do Nascimento Barroso	appaulabarroso@gmail.com	Ana Paula	@		7aa52bf997476fce06d82e9a4618021c	t	2011-11-22 14:55:32.029508	2011-11-22 14:26:35.897386	2	1991-01-01	\N	f	appaulabarroso@gmail.com	t
1399	Vânia Luz Barroso	vanialuzbarroso@gmail.com	Vania Luz	@		a1c81eef1600a47a7be31ea5c24f983d	f	\N	2011-11-22 14:50:14.149502	1	1987-01-01	\N	f		t
1324	ANTONIA ALINE SOUSA BARBOSA	alinesousa1997@hotmail.com	lininha	@		5d313f23a95d10c31c90fb472a619930	f	\N	2011-11-22 11:02:34.097542	2	1997-01-01	\N	f		t
1502	João Felipe Alves Sousa do Nascimento	joaofelipealves2010@hotmail.com	felipe	@lipehardstyle		d7198f908125155dc882858b84397901	t	2011-11-22 17:12:55.784659	2011-11-22 17:06:53.203439	1	1995-01-01	\N	f	joaofelipealves2010@hotmail.com	t
1406	Andressa Marques Rocha	ndressamarquesrochaandressa@gmail.com	Andressa	@		23bdd16efc77a22a3ff0b2a4fabe9c5b	f	\N	2011-11-22 15:46:52.902558	2	1994-01-01	\N	f	andressa.soushow@hotmail.com	t
1615	Maria Suely Dos Santos Sales	suely.sales1@gmail.com	suely sales	@		95998a5c3a860aad5af32fec4af8b781	f	\N	2011-11-22 20:13:48.988325	2	1991-01-01	\N	f		t
1642	osmael de sousa braga 	osmaelsousa1994@hotmail.com	osmael	@		58f8c6488c0e00290497173db92d2be6	t	2011-11-22 21:00:40.631007	2011-11-22 20:57:27.38678	1	1994-01-01	\N	f	osmaelfla94@gmail.com	t
1361	HIAGO GOMES SILVA	hiagogomes50@hotmail.com	HIAGO GOMES	@		1b6e5079833ba2293312cec69258fc53	f	\N	2011-11-22 12:00:44.773375	1	1995-01-01	\N	f		t
1746	Maria Lindomara dos Santos	mara.marilyn@hotmail.com	Lindomara	@		9108e01f3a165caa2158f713d9d93cb1	f	\N	2011-11-23 09:30:05.913327	2	1994-01-01	\N	f		t
2118	brena  késsia de sousa dias	dollzinhaskoldberg1@gmail.com	dollzinha	@		ffc401bd82a63fc0642eec58557f479a	f	\N	2011-11-23 17:55:04.231277	2	1994-01-01	\N	f		t
1145	LUIS CARLOS DANTAS COSTA	luis.dcosta@hotmail.com	luis01	@luisedaiane		ce181aa37561a4f7e922bd4ba4ff41f8	t	2011-11-21 16:30:17.486759	2011-11-21 16:18:18.169075	1	1993-01-01	\N	f	luis.dcosta@hotmail.com	t
1166	Paulo Ricado do Nascimento Lima	paulomombaca@gmail.com	Prof. Paulo	@		a0d0be7e14c9ca03d5353a10cfa86eaa	t	2011-11-21 20:04:30.811412	2011-11-21 20:00:22.343595	1	1987-01-01	\N	f		t
1146	Joel Santos	joelsan90@hotmail.com	Joelsan90	@joelsan90		c4fdc90ae5f299031672d0faebe7c1a2	t	2011-11-21 16:30:30.36182	2011-11-21 16:28:20.280613	1	1990-01-01	\N	f	joelsan90@facebook.com	t
1183	FRANCISCO FERNANDO GONCALVES DA SILVA	fernandogonsilva@yahoo.com.br	Fernando	@		a5c99599e059c11e043cba4b8dd639e0	t	2012-01-16 22:59:46.318157	2011-11-21 22:39:31.400605	1	1982-01-01	\N	f		t
1268	Romario Rodrigues Saraiva	romariokrodrigues@gmail.com	romario	@		42fb9dc4ea5c00b7c98ebe8ca23ffeba	t	2011-11-22 10:02:33.49981	2011-11-22 09:46:43.934073	1	1995-01-01	\N	f	romariosfc_@hotmail.com	t
401	CRISTINA ALMEIDA DE BRITO	cristina.seliga@gmail.com	Ruivinha	@cristinabritoo	http://diariodacriis.blogspot.com	d68d11727bcc6f2422b294f68309c5e2	f	\N	2011-10-20 18:34:22.612192	2	1993-01-01	\N	f	cristina.seliga@gmail.com	t
1379	FELIPE EVERTON OLIVEIRA COELHO	felipe-everton-@hotmail.com	Raspleura	@felipebodyboard		7bd392fd158e723156a23fd703dcf72e	t	2011-11-22 14:46:02.860124	2011-11-22 14:07:53.803911	1	1988-01-01	\N	f	felipe-everton-@hotmail.com	t
1381	DANILO DE OLIVEIRA SOUSA	danilo_oliveirace@hotmail.com	Danilo	@Danilompe		4b8f68a7780800dcba725c60f5d2e3a5	t	2012-01-10 18:25:57.242825	2011-11-22 14:16:32.569896	1	1981-01-01	\N	f		t
334	DAURYELLEN MENDES LIMA	daury.seliga@gmail.com	Daurynha	@Daurynha		f8a1a097075ce6d9373ea604cb8f9149	t	2012-01-15 18:35:38.669249	2011-10-16 15:14:55.918327	2	1988-01-01	\N	f	dauryellen@hotmail.com	t
1147	Ana Carolina Magalhães de Andrade	carolina.tecnicaemti@gmail.com	Carol M	@carolbreca		4860e44b63695b96169e8887be6811a7	t	2011-11-22 14:20:26.437922	2011-11-21 16:43:19.860985	2	1989-01-01	\N	f		t
812	DAVI FONSECA SANTOS	ivadlocks@gmail.com	tvihost	@tvihost	http://www.tvihost.net	bab8c359c4b3480421dcc2d62ab097fe	t	2012-01-16 08:56:29.056404	2011-11-14 18:33:15.950958	1	1992-01-01	\N	f	ivadlocks@gmail.com	t
1596	Ismael Martins da Silva	i.m715@hotmail.com	ismael	@		16c96aa18efda6e374a7840a51acbf32	t	2011-11-22 18:54:53.363354	2011-11-22 18:45:26.854644	1	2011-01-01	\N	f		t
1148	Thiago Fernando	thiafe@ig.com.br	Brainiac	@thiagoferrer		718d08b990bf3e9d8dfbe57ccf5fb2e2	f	\N	2011-11-21 16:49:00.413511	1	1983-01-01	\N	f	thiafe@ig.com.br	t
1189	Rafaelson Marques	rafaelsonradicalg3@hotmail.com	Faelson	@		f5a233fdb0d476e080863d3e9ee88431	t	2011-11-21 23:01:14.799912	2011-11-21 22:54:55.828443	1	1995-01-01	\N	f	rafaelsonradicalg3@hotmail.com	t
1711	Weslei Frank Rios	wesleirios@gmail.com	Weslei Rios	@wesleirios	http://wesleidark.blogspot.com/	15a0af959a2345f7e09ffdff584d6661	f	\N	2011-11-23 00:15:16.719884	1	1992-01-01	\N	f	wesleidark@otmail.com	t
1480	Diego Jeferson	diegojeferson95@hotmail.com	Dieguito	@		6e4b8e6dd4decbbb8dea58b767ea156b	f	\N	2011-11-22 17:03:57.237893	1	1995-01-01	\N	f	diegojeferson95@hotmail.com	t
1150	FLAVIO RENATO DE HOLANDA FILHO	flaviorenato2010@bol.com.br	Renatinho	@		2af00db4098cddcff2914a5922a9fd25	f	\N	2011-11-21 17:18:43.069378	1	1991-01-01	\N	f	flaviorenato08@yahoo.com.br	t
1631	Abna Oliveira da Silva	abnnasmith03@gmail.com	Ábnna oliveira	@		514e41f062b136dc7c0195f2d6a8f7fc	t	2011-11-22 20:57:02.627637	2011-11-22 20:40:26.569569	2	1991-01-01	\N	f		t
1194	William Vieira Bastos	will.lokky@gmail.com	willvb	@willvb		211bdb3d2959b942f3ebfa29d5b7ede3	t	2012-01-15 17:43:05.278544	2011-11-21 23:19:48.75085	1	1990-01-01	\N	f		t
2093	Gabriel Menezes	biel_tuf_12@hotmail.com	biielgm7	@51pedroisidio		e4e9044a6bd018f5400d2ca81374e87d	f	\N	2011-11-23 17:35:55.106313	1	1996-01-01	\N	f	pedroisidio1@hotmail.com	t
1153	Amanda Sousa	amanda.sousab@gmail.com	Amanda	@amanda_sousab		19f68f023afdd90fc3ee2f120302e2d4	f	\N	2011-11-21 17:59:42.352024	2	1989-01-01	\N	f	amanda.sousab@gmail.com	t
1154	Francisco Helio Santiago de Almeida Junior	helioplay2009@hotmail.com	Helio junior	@juninho		3681c9552f3e888c5cceae4a46c6937c	f	\N	2011-11-21 18:16:58.108968	1	1997-01-01	\N	f	helioplay2009@hotmail.com	t
1301	germano oliveira	gehprojecto@gmail.com	Geholiveira	@		8132ec0977065af6fd90072b33d60680	t	2011-11-22 10:21:22.962894	2011-11-22 10:11:42.445197	1	1989-01-01	\N	f	gehprojecto@gmail.com	t
1386	Kelyson 	kelisonpinheiro@hotmail.com	Kessim	@		eccc9c669c44a5fe06e11a3a92fec73b	t	2011-11-22 14:57:36.50755	2011-11-22 14:27:08.735128	1	1994-01-01	\N	f		t
2214	Kelvin Dias Lopes	kelvin_ramza@hotmail.com	Ramza 	@kelvin_ramza		57c49131c1c1861b47dc52a13687ac87	f	\N	2011-11-23 22:12:38.890913	1	1992-01-01	\N	f	kelvin_ramza@hotmail.com	t
1205	maryla moraes de paula oliveira	marilia.moraes736@gmail.com	marylia	@		d86f49d85cc6e8cf7279656aa10255e9	f	\N	2011-11-22 08:59:25.254896	2	1987-01-01	\N	f		t
1210	IRAN SOUSA LIMA	iransousa222@gmail.com	iranzim	@iran_sousa		76b202c071c1ff47117d5947d7843080	t	2011-11-22 09:12:20.993654	2011-11-22 09:07:49.422967	1	1990-01-01	\N	f	iranlima222009@hotmail.com	t
1314	Luis César	luiiscesar@gmail.com	cesinha	@		6ea7332ae4529733fe2606354e8d7c47	t	2011-11-22 10:54:14.81135	2011-11-22 10:45:43.635859	1	1990-01-01	\N	f	luiiscesar@gmail.com	t
1393	ANTONIA ALINE SOUSA BARBOSA	antoniaalinesousa@hotmail.com	lininha	@		78df201ec37409a87b05d4a4dcd431a0	t	2011-11-22 14:36:28.197512	2011-11-22 14:31:38.701841	2	1997-01-01	\N	f		t
1608	Francisco Thiago Pessoa da Silva	eudaziosampaio@hotmail.com	Thiago	@		8c278462dc2f486dd9697edc17eff391	t	2011-11-22 19:58:32.94882	2011-11-22 19:49:52.703224	1	1994-01-01	\N	f		t
1503	Marília Barroso da Silva	marilia2009@hotmailyaool.br	Ninha0	@		429e42d199388d372de7014b9137f1de	f	\N	2011-11-22 17:07:02.122671	2	1995-01-01	\N	f	marilia2009_9@hotmail.com	t
1325	Luan Henrique de Aguiar	luan.pro@hotmail.com	garapa	@		9ea2b53cc45aa958fae4c3132f71c5db	t	2011-11-22 11:06:49.413906	2011-11-22 11:02:52.458383	1	1990-01-01	\N	f	mardonio.pro@hotmail.com	t
1914	Joel Anderson Rocha Araujo	joelandersonfc@gmail.com	Anderson	@joelandersonfc		0ded474332ee701b69f4a073a28774b3	f	\N	2011-11-23 14:29:10.554644	1	1992-01-01	\N	f	viewtifuljoe_bc@hotmail.com	t
1400	caroline Siqueira Guerra	carolinesiqguerra@gmail.com	Carol Guerra	@		d97e48fd9b2255aa3fdc4af371f16053	f	\N	2011-11-22 14:55:10.942221	2	2011-01-01	\N	f		t
1338	Cesar Arnô Ferreira Da Silva	cesar-arno@hotmail.com	Cesinha	@		f4c5d09690c63a0b26f2c057cd2c7538	t	2011-11-22 11:14:54.152008	2011-11-22 11:09:44.416	1	1992-01-01	\N	f	cesar-arno@hotmail.com	t
1465	Júlia fernandes	juliaalberice@hotmail.com	Júlhinha'	@		4de2abb510173c07f33287b388e9b12f	t	2011-11-22 17:15:05.609963	2011-11-22 16:58:21.102362	2	1998-01-01	\N	f		t
1458	Ana Kesia Almeida	kesiaalmeidainf@gmail.com	Kesinha	@		f1f89fbc05535f25bbcbca1657586775	t	2011-11-22 17:20:12.160463	2011-11-22 16:53:59.961824	2	1995-01-01	\N	f		t
2251	Francisco Marcelo Gomes da Silva	marceloprf2007@gmail.com	Marcelo Silva	@		79913c55f04245747edcee0b7ccbd13a	f	\N	2011-11-24 09:06:42.415222	1	1985-01-01	\N	f		t
1643	Francisca Cacilia Maciel André	kaciliaandre@yahoo.com	não tenho	@		5ac54b47b3508b8dff14b877a768e505	f	\N	2011-11-22 20:57:50.735666	2	1990-01-01	\N	f		t
1747	Rayson	rayson4@hotmail.com	RSLKalar	@		acd0f886f36c6d5b0b43a4042ceb073a	f	\N	2011-11-23 09:30:12.84264	1	1995-01-01	\N	f		t
1928	Ana kimberly	kimberlly_dazgatinhas@hotmail.com	kimberly	@		c4f02de059263944e6d654ef292b601e	f	\N	2011-11-23 14:44:02.090416	2	1995-01-01	\N	f		t
2623	Sheldon Guimarães de Almeida	sheldongui2009@hotmail.com	Sheldon	@		fb4962e91e83f3f933408b9695ae6f99	f	\N	2011-11-26 09:38:06.546138	1	1998-01-01	\N	f		t
2645	Francisco Alexandre de Sousa 	alexandre.sousa1978@gmail.com	alexandre	@		db290063234c8cf377f85c92082ba73c	f	\N	2011-11-26 12:30:19.100502	1	1978-01-01	\N	f		t
1158	Jocélio Cunha Morais	joceliocunha@hotmail.com	Jocélio	@		dc5a101dea3b8c7224750aa323a7cbec	t	2011-11-21 18:57:43.622031	2011-11-21 18:55:23.260057	1	1988-01-01	\N	f	joceliocunha@hotmail.com	t
1059	DEYLON SILVA COSTA	deylon_@hotmail.com	Freddy	@		fe9e5c52ad38ed721f368d4ae9ec145f	t	2012-01-10 18:25:58.449226	2011-11-19 17:30:45.300108	1	1988-01-01	\N	f	deylon_@hotmail.com	t
1180	André Victor de Souza Siqueira	andre_tricolorvitor@hotmail.com	André	@		c258a83d9da09ee2b164fc0052a27f57	f	\N	2011-11-21 22:18:07.133549	1	2011-01-01	\N	f		t
1167	DIEGO FARIAS DE OLIVEIRA	diegofarias06@hotmail.com	Diego Farias	@		c0e8c1f59e562a8f1d46acd501170af3	t	2012-01-16 21:51:28.593578	2011-11-21 20:05:35.163636	1	1993-01-01	\N	f	diegofarias06@hotmail.com	t
1140	ANTONIA CLEITIANE HOLANDA PINHEIRO	cleitypinheiro_wonderfulgirl@hotmail.com	cleity	@		4e0cd06b506c380409411a6cc2dd0145	f	\N	2011-11-21 16:08:04.823754	2	1994-01-01	\N	f	cleitypinheiro_wonderfulgirl@hotmail.com	t
1161	Ingrid de Oliveira Magalhães	gridkat@msn.com	Gridzinha	@		a8eec21667e33fcc23697c1611e04603	t	2011-11-21 19:04:24.781869	2011-11-21 18:59:58.132323	2	1994-01-01	\N	f	gridkat@msn.com	t
1018	ANTONIO RENAN ROGERIO PAZ	antoniorenan@pmenos.com.br	ANTONIO RENAN	@		4f33d3d9334bd11f40b9ed5319ba2f96	t	2012-01-15 18:15:28.639824	2011-11-18 18:53:50.91309	1	1985-01-01	\N	f	ananerrp@hotmail.com	t
1162	WESLEY SILVA SARAIVA	wesley_sr@hotmail.com	foxwss	@		575380f5fb45817846c473d1805ceeff	t	2011-11-21 19:27:42.352796	2011-11-21 19:25:35.390734	1	1988-01-01	\N	f	wesley.sr7@gmail.com	t
1185	Horácio Alves Moura	halvesmoura@gmail.com	Horácio Alves	@horacioalves		2ef54970efa9d78327a8903bf02bcba7	t	2011-11-21 22:58:38.310597	2011-11-21 22:43:29.987762	1	1989-01-01	\N	f	halvesmoura@gmail.com	t
1195	Rafaela batista da silva	rafabs1000@gmail.com	Rafaela	@RafaelaB_		0d88ca97a68ab776244162dcd0920424	f	\N	2011-11-21 23:28:50.868806	2	1992-01-01	\N	f	rafabs1000@gmail.com	t
1380	Lucas Vieira Peixoto	lucasvpeixoto@gmail.com	lucasvpeixoto	@		5e235b4f961a7937d7ba99306b01f5c0	t	2011-11-22 14:16:46.329479	2011-11-22 14:15:31.449876	1	1990-01-01	\N	f	lucasvpeixoto@gmail.com	t
1201	Alberto Soares de Sales Filho	albertossfilho@hotmail.com	Alberto Filho	@		6a61a4fdbd193c45efa5810c640295f6	t	2011-11-22 02:13:03.840039	2011-11-22 02:10:06.422082	1	2011-01-01	\N	f		t
1467	Daniel Bento de Castro	daniel___castro@hotmail.com	Dan Castro	@		2f575fe2fd465cbbe83cdea99da98762	t	2011-11-22 17:05:57.416943	2011-11-22 16:59:14.235578	1	1995-01-01	\N	f	daniel___castro@hotmail.com	t
1597	Maria silva	mari.silva12@hotmail.com	Felícia	@maria_silvaflor		01b8dd85725004b7a589fc8567326dc0	t	2011-11-22 18:52:38.608153	2011-11-22 18:50:02.472046	2	1996-01-01	\N	f	mari.silva12@hotmail.com	t
1302	Luiany	luiany_morena@hotmail.com	Luh Rocha	@luiany_rocha		60b7834c2b8a532d1c665e18086017d7	t	2011-11-22 10:21:24.960696	2011-11-22 10:14:04.413264	2	2011-01-01	\N	f	luiany_morena@hotmail.com	t
1632	antonia sabrina demetrio de sousa	sabrinabnka11@hotmail.com	nariguda	@		1b84bcc754bbc11fba6f9d591a9c1a30	t	2011-11-22 21:20:24.337895	2011-11-22 20:43:36.368802	2	1995-01-01	\N	f		t
1220	Francisco Lopes Daniel Filho	dielfilho@hotmail.com	Daniel Filho	@D_DielF		5416c523342823bbf1e2636d077bba87	t	2011-11-22 09:33:03.469554	2011-11-22 09:32:27.979588	1	1995-01-01	\N	f	dielfilho@hotmail.com	t
1394	Antonio Sidney Barbosa de Almeida	sidneyalmeida89@gmail.com	SidneyAlmeida	@		4e196444f65a4579a025e5b431a7217f	f	\N	2011-11-22 14:32:27.788821	1	1992-01-01	\N	f	sidneysenso@hotmail.com	t
1223	Francisco Carlos Siqueira de Oliveira	carlos_eusouocara@hotmail.com	Carlinhos	@		5ae7353709823f4530de42ee366fcbe4	f	\N	2011-11-22 09:33:27.738436	1	1995-01-01	\N	f	carlos_eusouocara@hotmail.com	t
1712	walison alves lima	walisonalveslima@gmail.com	chinas	@		516dfa78bd618a2e697d53bcc54887c9	f	\N	2011-11-23 00:39:04.780383	1	1987-01-01	\N	f	walisonlima2008@hotmail.com	t
1315	AMANDA ARAGAO ABREU	FELIPE_JORGE_@HOTMAIL.COM	AMANADA	@		03637ccd3e84ec705a4f03933fe08ca3	f	\N	2011-11-22 10:55:54.17155	2	1994-01-01	\N	f		t
1401	Paulo Rogério Barbosa da Silva	prbs2010@gmail.com	Rogerio	@		2a42f152e1263b8589d6e3c8bfa6e407	f	\N	2011-11-22 15:09:01.662267	1	1989-01-01	\N	f		t
1326	JOSE EDILAN PONCIANO COSTA	madsonddias@hotmail.com	EDILAN	@		f7aecca6d2687a0440c162aea15e33d6	f	\N	2011-11-22 11:04:04.349696	1	1994-01-01	\N	f		t
1229	Fernando Oliveira Rodrigues	oliveiraenoi09@hotmail.com	fernando	@		7ddd9269dcb9d8884172c257e519ec50	f	\N	2011-11-22 09:34:25.965945	1	1995-01-01	\N	f		t
1230	Karla Tamirys Belarmino da Silva 	tataedmais@gmail.com	 Karla Tatá	@		0d7a6a5934d4fbb9870a9561d3d3a509	f	\N	2011-11-22 09:34:36.074952	2	1994-01-01	\N	f		t
1331	carlos henrique de oliveira	pb.carloshenrique@gmail.com	carlim	@		584234d18135eb06f3643d3075e5a124	f	\N	2011-11-22 11:05:49.115267	1	1987-01-01	\N	f	pb.carloshenrique@gmail.com	t
1222	Karina Carneiro Lira	karinalira10@gmail.com	Karina 	@KariinaLira		43e78aba91cab914ab6d6dece3ac32cc	t	2011-11-22 09:34:57.883432	2011-11-22 09:33:20.302507	2	1992-01-01	\N	f	karinalira10@gmail.com	t
1336	Kahena Kévya Moura Coelho	kahena_kevya@hotmail.com	Kahena	@kahenamoura		99927c78ced79e7412476c19073c34e6	t	2011-11-22 11:12:50.983428	2011-11-22 11:07:29.201437	2	1993-01-01	\N	f	kahena_kevya@hotmail.com	t
1408	Monalisa Silva de Araújo	andressa.soushow@hotmail.com	Mona Silva	@		c7f78b8e3e929ce57ab8f1f3a920bb6d	f	\N	2011-11-22 15:49:09.446284	2	1993-01-01	\N	f		t
1175	kelvia paloma costa nascimento	kelvia.loma@gmail.com	paloma	@		5411621bd33f0255f0bf3e8893874ccf	t	2011-11-22 19:56:34.117725	2011-11-21 20:54:15.741622	2	1991-01-01	\N	f	kelvia.loma@gmail.com	t
1339	Davi ferreira souto	davisolza29@hotmail.com	devid solto	@		ecffc1c3703fb56861ef53060acb232c	t	2011-11-22 13:01:25.589777	2011-11-22 11:11:42.75732	1	1992-01-01	\N	f	davisolza29@hotmail.com	t
1413	Everton Rodrigues	evertonrodrigues2@gmail.com	Everton?!	@Ton1992	http://theculturainutil.wordpress.com/	2f36ba40aadc3c109f5e38a851844c6c	t	2011-11-22 16:37:32.56624	2011-11-22 16:31:50.42607	1	1992-01-01	\N	f	evertonrodrigues3@hotmail.com	t
1617	Nikson Allef Martins De Sousa	nikson.allef@gmail.com	Nikson	@		349008658d95c265a88a738d45b6bc5a	t	2011-11-22 20:21:20.179299	2011-11-22 20:18:01.681681	1	1992-01-01	\N	f		t
1915	Victor Iuri C Sousa	iuriflamengo@hotmail.com	Iuri Sousa	@		e2b8d6e719710ad4b8df5dbc46fac334	f	\N	2011-11-23 14:31:09.674261	1	2011-01-01	\N	f	iuriflamengo@hotmail.com	t
1417	Juliana Vidal Dutra	Juliana1_0@hotmail.com.br	Julynha	@		88f883e73414f9bc26372e8ff564d617	f	\N	2011-11-22 16:41:50.785799	2	1995-01-01	\N	f	Juliana1_0@hotmail.com.br	t
1514	Karolaine Matos De Moraes	x.k.r.lorak@adventure.com	karolzinha	@		3b0c8480ca775fddbd39426a010e9c24	f	\N	2011-11-22 17:11:16.642948	2	1994-01-01	\N	f	x.k.r.karol@email.com	t
1523	Aluana Barbosa de Freitas	aluana-bf@hotmail.com	Aluana	@		2de1bd15af53b3a8856b21b2c7b70315	f	\N	2011-11-22 17:15:32.204147	2	1990-01-01	\N	f		t
1720	Thomas Jefferson Ferrer da Silva	jeff_559_@gmail.com	jefferson	@		5ea16c0b1a3f84ba7c9f5dc3deeaeb05	f	\N	2011-11-23 08:13:12.09179	1	1996-01-01	\N	f	tjefferson1996@hotmail.com	t
1652	Isaac James Mangueira do Nascimento	isaacsupergato@hotmail.com	Isaac James	@		af1bcc0a3761884210e9d292da4ab14a	t	2011-11-22 21:18:56.604136	2011-11-22 21:14:09.262829	1	1995-01-01	\N	f	isaacsupergato@hotmail.com	t
1734	Alyson Araújo Barroso da Silva	alisonjk82@hotmail.com	Cristiano Alyson	@		c50cb395a5ae84b358ef63efc3cb0d23	f	\N	2011-11-23 09:26:45.986874	1	1995-01-01	\N	f	alisonjk82@hotmail.com	t
1659	Maryana Almeida	maryanaalmida42@gmail.com	Maryana'	@		18b6d5fb5e49e4620e66209eea89ad15	f	\N	2011-11-22 21:32:19.292232	2	2011-01-01	\N	f		t
1760	Andrêza Hanna Mesquita De Almeida	a.hanna95@yahoo.com.br	Hanna montanna	@		2729a03b4b5918352d9c2396d92639cf	f	\N	2011-11-23 09:33:23.554266	2	1995-01-01	\N	f		t
2119	douglas	douglasribeirovasconcelos@gmail.com	ribeiro 	@		38a02cbee89cb97bb9c7aa52124fbd6f	f	\N	2011-11-23 17:57:30.719519	1	1994-01-01	\N	f		t
1233	Kerley de Sousa Dantas	swatk_k@hotmail.com	Kerley Dantas	@		4545176d82f096db3faed5773ba568a3	f	\N	2011-11-22 09:35:04.198378	1	1995-01-01	\N	f	swatk_k@hotmail.com	t
624	ARLESSON LIMA DOS SANTOS	lessonpotter@gmail.com	Arlesson	@		78560872782bae8115d6017f4634ea8c	t	2012-01-10 18:25:50.671971	2011-11-08 13:40:36.439241	1	1992-01-01	\N	f		t
1234	Rayanna Medeiros Da Silva	rayanaght@hotmail.com	Rayanne	@		24d46f89718f37dc379baad367857682	t	2011-11-22 09:38:50.447334	2011-11-22 09:35:08.47078	2	1995-01-01	\N	f		t
1253	Lucas da Silva Campos	Lucassodeboa1@gmail.com	Lukinhas	@		77e72fd1df628bd647d2344c44551bd1	t	2011-11-22 09:44:07.613392	2011-11-22 09:41:46.404557	1	1994-01-01	\N	f		t
1235	Carolina Balbino da Silva	carolinabalbino18@hotmail.com	Carol Balbino	@		73b1a9974536734d046823287a4e8408	t	2011-11-22 09:37:06.437731	2011-11-22 09:35:13.633519	2	1995-01-01	\N	f		t
1099	ATILA SOUSA E SILVA	atila.tibiano@hotmail.com	royuken	@		97d6e7462f9280d9104327224e8fc5e0	t	2012-01-10 18:25:51.074622	2011-11-21 10:08:19.67001	1	1993-01-01	\N	f	atila.tibiano@hotmail.com	t
1598	Alan Jefferson Ximenes Sampaio	alanjxs@hotmail.com	Alanjxs	@alanjxs	http://alanjxs.blogspot.com/	05ff3393d3a46849641cb8f235c5bc8b	t	2011-11-22 21:26:43.757015	2011-11-22 18:53:34.797529	1	1988-01-01	\N	f	alanjxs@hotmail.com	t
1221	Sheilla Pinheiro de Lima	sheillinha_pinheiro@hotmail.com	Sheilla	@		ef736e0d26055d87827d1115b1fa8574	t	2011-11-22 09:35:31.434073	2011-11-22 09:32:41.901478	2	1995-01-01	\N	f		t
1224	David Daniel Ribeiro de Queiroz	david-que-roz@hotmail.com	Queiroz	@_DavidQueiroz_		c3b20642efe79e9db9d9398622eaaa8d	t	2011-11-22 09:35:44.864114	2011-11-22 09:33:30.863552	1	1995-01-01	\N	f		t
2517	Felinto Fábio Rufino de Souza	felintofabio9@gmail.com	Fábio	@FabioFelinto		da7714a7336b24b78811cb06ce0c9e8b	f	\N	2011-11-24 20:47:13.122937	1	1991-01-01	\N	f	felintofabio9@gmail.com	t
1228	Elaine Venâncio de Novais	elaine.novais-28@hotmail.com	Elaine Novais	@		5cbd80299e42e9c52fd02bbd5f2c2977	t	2011-11-22 09:36:14.833634	2011-11-22 09:34:13.315008	2	1995-01-01	\N	f		t
1237	Lucas da Silva Campos	Lucassoeboa1@gmail.com	Lukinhas	@		72bf9045b07804402705b2fc321326dc	f	\N	2011-11-22 09:36:19.677506	1	1994-01-01	\N	f		t
1264	abraão alves souza	abraaokad@gmail.com	kad.web	@abraaokad		9eec5ba3e651e8d88e2e0929f7d681b3	t	2011-11-22 10:02:15.780453	2011-11-22 09:45:40.446191	1	1989-01-01	\N	f	abraaokad@gmail.com	t
1232	Francisco Ednaldo Marcelino	edinhosette@live.com	Ednardo	@		1032d51d9a1a9545fb0f3a65094a76d0	t	2011-11-22 09:36:23.931433	2011-11-22 09:34:59.10382	1	1994-01-01	\N	f	edinhosette@live.com	t
1227	Francisco Wemerson Moreno Monteiro	wemersonmoreno_13@hotmail.com	Wemerson	@		b1a94fe06d2f1817195312cf0b28571a	t	2011-11-22 09:36:36.171974	2011-11-22 09:34:05.84757	1	1994-01-01	\N	f		t
1238	Francisco Ygor De Sousa Linhares	ygorlinhares7@gmail.com	Ygor Linhares	@		8363ecf3fe1cc63befb01b3029ada42c	t	2011-11-22 09:38:07.229053	2011-11-22 09:36:43.207125	1	1994-01-01	\N	f		t
1633	Maria Glaudiane Freitas Cunha	fiama_freitas@hotmail.com	glaudiane	@		68b8606efb5b275f9701e8c285e0e4ac	t	2011-11-22 20:50:42.410457	2011-11-22 20:45:14.800684	2	1992-01-01	\N	f		t
1395	Mercia Oliveira de Sousa	merciaoliveira3@gmail.com	Mercia	@		cc2398d149f4f18522b08c5490e9f451	f	\N	2011-11-22 14:33:28.719124	2	1982-01-01	\N	f		t
1713	Marcos Álvaro Rocha Farias	dan-tex@hotmail.com	sparda	@		63c3c3e92bffcc2b1c689a1e5ddb2eb1	f	\N	2011-11-23 00:47:42.425545	1	1992-01-01	\N	f		t
1240	Romário Rodrigues Saraiva	romariokrodrigues@hotmail.com	ROMARIO	@		e9d9fd054da14150aff03a068c8a464e	f	\N	2011-11-22 09:37:05.551165	1	1995-01-01	\N	f	romariosfc_@hotmail.com	t
1327	Jackson Xavier Rodrigues	jacksonxxr@hotmail.com	jackson	@		4c098771859d3271589a09a083ce1f1e	f	\N	2011-11-22 11:04:24.453717	1	1994-01-01	\N	f		t
1402	SUYANNE DO NASCIMENTO ALMEIDA	suyannenascimento@gmail.com	suyanne	@SuyNascimento		39b3cdf76f7a30b4a8e5661660afa6a6	t	2011-11-22 15:26:42.838121	2011-11-22 15:23:59.550868	2	1990-01-01	\N	f	suylink@hotmail.com	t
1226	Karla Ramirys Belarmino da Silva	karlagata27@hotmail.com	Milla Silva	@		313c7c2ad7167484db031a7cab1c4850	t	2011-11-22 09:37:11.302182	2011-11-22 09:33:49.140412	2	1994-01-01	\N	f		t
1332	Leonardo Sousa Pires	marcelaborges2000@gmail.com	leonardo	@		5e11758dd08a19993b5c5ba4ad58ad69	f	\N	2011-11-22 11:05:50.957296	1	1997-01-01	\N	f		t
1231	Danilo da Silva Pinheiro	danilopinheiro17@hotmail.com	Danilo	@		0df529aa15a293e8b82fbad49c1f4945	t	2011-11-22 09:38:37.292624	2011-11-22 09:34:47.744107	1	1994-01-01	\N	f		t
1337	Lucas Gomes da Silva	lucasgomesilva@hotmail.com	Avatar	@		b306c55f6a51ebeaf5f52f3648d2a965	t	2011-11-22 11:13:04.105755	2011-11-22 11:07:34.424296	1	1995-01-01	\N	f		t
2546	Francisca Joseli  Freitas de Sousa 	joselisousa2010@hotmail.com	Joseli	@		21daa4dc1a28d6d56a8a4f84cf93688d	f	\N	2011-11-25 09:34:21.352643	2	1993-01-01	\N	f		t
1246	Karla Tamirys Belarmino da Silva 	tamitigresa@hotmail.com	 Karla Tatá	@		21e826a11b4d73911c94075c230b154f	t	2011-11-22 09:41:28.351218	2011-11-22 09:39:26.329898	2	1994-01-01	\N	f		t
1409	juliana de castr portacio	juliana_portacio@hotmail.com	july_portacio	@julianaportacio		41cb222013707c34609bafb4d76acbf7	t	2011-11-22 16:26:03.300008	2011-11-22 15:49:27.182797	2	1991-01-01	\N	f	julianaportacio@facebook.com	t
1505	Dayane Abreu de sousa	dayanesobrenatural@hotmail.com	dadada	@		cbb35238dbca374b9e4c1d1418ed835c	t	2011-11-22 17:09:04.773251	2011-11-22 17:07:52.094168	2	1995-01-01	\N	f		t
2573	DOMINGOS SAVIO SOARES FELIPE	savioup@gmail.com	Sávio	@saviofelipe		fdb09ba2856aabc0ce2c2094ca00971e	f	\N	2011-11-25 13:35:57.174926	1	1985-01-01	\N	f	savioup@gmail.com	t
1609	Francisco Jadson de lima	Jadsoon.lima@gmail.com	Jadson	@		835f340f2434e72f26c5d4ce9ea1c8d2	t	2011-11-22 20:18:28.097577	2011-11-22 20:07:12.784231	1	1992-01-01	\N	f		t
1034	Daniel Sales	danielstifler8@gmail.com	Dani Sty	@		3f2c0333c28defebf507afd6d1f1aa2f	t	2011-11-22 11:29:25.942541	2011-11-18 21:29:32.462998	1	1996-01-01	\N	f		t
2624	Lucas Ferreira Monteiro	lukasben10@yahoo.com.br	Lucas Ferreira 	@		156e5bf33dea21f0a4f199cad5705abd	f	\N	2011-11-26 09:41:11.29603	1	1999-01-01	\N	f		t
1721	Thomas Jefferson Ferrer da Silva	jeff_5591@hotmail.com	jefferson	@		521d90be068e83cbc2ccd6ce45e5f2d5	f	\N	2011-11-23 08:17:12.709469	1	1996-01-01	\N	f	tjefferson1996@hotmail.com	t
1618	José Gerismar Santos	jsgrsmrsnts@gmail.com	Gerismar	@		f3f006f836232e7612e1e6fa50c95221	t	2011-11-22 20:23:15.551501	2011-11-22 20:19:24.277853	1	1994-01-01	\N	f		t
1149	KARLA KELLY LIMA MONTEIRO	karla_black1@hotmail.com	perfeita	@		69e87435be00bfb59306fbe3325d3294	f	\N	2011-11-21 16:52:06.37928	2	1992-01-01	\N	f	karla_black1@hotmail.com	t
2120	leonardo viana	leonardoviana18@gmail.com	carvalho 	@maetosexy		92835ae03035f741d25a0a3f099af63c	f	\N	2011-11-23 17:59:21.726464	1	1992-01-01	\N	f	leo17.thegame@hotmail.com	t
2235	wermyson	wermyson.ti@gmail.com	Wermyson	@		dd3b30d56190ba1f616dad36cf61ebb0	f	\N	2011-11-24 00:20:41.561077	1	1992-01-01	\N	f		t
1916	Maria Alessa Alexandre da Silva	lessa_rih08@hotmail.com	Alessiinha	@Alessiinha		0876f8303a103a8be43aba0e91899e1d	f	\N	2011-11-23 14:34:27.153788	2	1994-01-01	\N	f	lessa_rih08@hotmail.com	t
1749	Thais da Frota de Souza	obr-thais@live.com	ThaisFrota	@		28349cb238dab3cce60101f1b66bbd7e	f	\N	2011-11-23 09:31:10.668984	2	1994-01-01	\N	f	obr-thais@live.com	t
2252	Antônia Noélia Uchôa Nogueira	noelia_now@hotmail.com	noelia	@		ceac60dff76806d90560aa4e30de09fb	f	\N	2011-11-24 09:19:53.146408	2	1992-01-01	\N	f	noeliapink@hotmail.com	t
2267	francisco marlis gomes da costa	gomesmarlis53@gmail.com	gomes.	@		6e0e3d50871d480d2a1c91e56cdae6e5	f	\N	2011-11-24 10:06:08.005111	1	1985-01-01	\N	f		t
1247	Maria Rosiane Moreira Canuto	rosiane-canuto@hotmail.com	Rosiane	@		fd0f00833ac4adf124b283038a870ff3	t	2011-11-22 09:44:25.11357	2011-11-22 09:39:27.78743	2	1994-01-01	\N	f		t
1248	Tiago de Gois Silva	tiagogois2011@gmail.com	Tiago Gois	@		5e176a2fe54454ff7821065f88d3808b	t	2011-11-22 09:41:21.207762	2011-11-22 09:39:45.920833	1	1994-01-01	\N	f		t
1191	BRUNO BARBOSA AMARAL	bruno_k16@yahoo.com.br	Brunn0	@		6203ae48eec4efb06fa05d74456d6b64	t	2012-01-16 18:31:30.246569	2011-11-21 23:04:28.043243	1	1990-01-01	\N	f		t
1359	MARIA RENATA ARRUDA COELHO	renata_s2@hotmail.com	RENATA	@		3b9536b0565e023d07b5d7148b1ae955	f	\N	2011-11-22 11:57:45.381241	2	1994-01-01	\N	f		t
1239	Ikaro Robson Pinho Lopes	ikarorobson25@hotmail.com	ikaro Robson	@		78e3779504310b1a31e8f6e036c2c5cc	t	2011-11-22 09:39:57.509246	2011-11-22 09:36:54.281612	1	1994-01-01	\N	f		t
1249	Kerley de Sousa Dantas	kerleysol@hotmail.com	Kerley Dantas	@		4eed6e4763f1702dbb20e4bd20ead9d7	t	2011-11-22 09:41:08.825189	2011-11-22 09:40:02.182642	1	1995-01-01	\N	f		t
1254	Ana Paula Pinheiro Barbosa	ana_paula_xuxa@hotmail.com	Aninha 	@		3c1b9afd3d03de50b801694b4939e4dd	f	\N	2011-11-22 09:41:59.829111	2	1994-01-01	\N	f		t
2518	valbelene  perreira de araujo	valzinha.araujo-flor@hotmail.com	belene	@		33a5f270b21edcd3bcccd127018cd9b3	f	\N	2011-11-24 20:50:09.994688	2	1991-01-01	\N	f		t
1244	Saiane Silva Lins	saahlins@hotmail.com	Sáh Lins	@		fc4758e3686ba18cddd03f3754d4f869	t	2011-11-22 09:40:09.025737	2011-11-22 09:38:55.151565	2	1995-01-01	\N	f		t
1236	Antonio William Vitoriano Sindeaux	william_sindeaux@hotmail.com	william sindeaux	@		7b3b7734a3b838936d6fc85bea9f42f9	t	2011-11-22 09:40:47.48386	2011-11-22 09:36:01.404512	1	1995-01-01	\N	f		t
1250	Francisco Anacleto Alves Dos Santos Filho	anacleto-alves@hotmail.com	Anacleto Filho	@		3fade403e2e9531e30c30f9f637fa2f7	t	2011-11-22 09:49:35.528376	2011-11-22 09:41:04.794988	1	1994-01-01	\N	f		t
1251	Francisco Carlos Siqueira de Oliveira	ericopep@hotmail.com	Carlinhos	@		dc267c186ad6e61ad68d3e8f5bab18fd	t	2011-11-22 09:42:30.393719	2011-11-22 09:41:04.865702	1	1995-01-01	\N	f		t
1416	BRUNO FERREIRA ALENCAR	brunofalencar@hotmail.com	brunofalencar	@brunoalencar2		8d13ed81f15ff53688df90dd38cbd6d6	t	2012-01-10 18:25:51.865742	2011-11-22 16:39:41.224935	1	1993-01-01	\N	f	bruno_tsunami_8@hotmail.com	t
998	CÍCERO JOSÉ SOUSA DA SILVA	c1c3ru@hotmail.com	cicero	@		e14005106bd0e03ea0056e5e38d8a220	t	2012-01-10 18:25:55.619703	2011-11-18 12:08:46.954662	1	1984-01-01	\N	f		t
1599	Jéssica Samanta Silva Santos	samantinha.santos@yahoo.com.br	samantinha	@		ba48a6103fe019c08b4f862ee9c3eb78	t	2011-11-22 19:11:30.772032	2011-11-22 18:57:14.420231	2	1995-01-01	\N	f		t
1714	Francisco Gleilton Oliveira Costa	gleiltonoliveira@hotmail.com	Gleilton Oliveira	@		83a879a56e590ddcbfeba178b9b34b73	f	\N	2011-11-23 01:28:18.94273	1	1988-01-01	\N	f	gleiltonoliveira@hotmail.com	t
1270	Rosiane Sávia Nunes Rodrigues	savia.bells@gmail.com	rosiana	@		45ee5d97db625b48fd83a52a848c4dd2	f	\N	2011-11-22 09:48:18.184679	2	1989-01-01	\N	f		t
1282	abraao alves souza	a.abraao@yahoo.com.br	kad.web	@abraaokad	http://www.orkut.com.br/Main#Profile?uid=16433461141951438794	9f0e6a4a0c8c18ee54bfe73b5254bb24	f	\N	2011-11-22 09:55:51.908913	1	1989-01-01	\N	f	abraaokad@gmail.com	t
1496	Alexson Kerven Alves Bezerra	alexsonkerven@hotmail.com	Kerven	@AlexsonKerven		2f3d3ffd20604ee97b1f8ad9619c073c	f	\N	2011-11-22 17:05:55.978469	1	1995-01-01	\N	f	focobabraespkalangos@hotmail.com	t
1297	Yasmim da Silva Moreira	yasmimsilva18@gmail.com	Yasmim Äpdsï|	@		6f7f6bca434aec744d07e029793b29b0	t	2011-11-24 19:22:33.695887	2011-11-22 10:09:57.774263	2	1992-01-01	\N	f	yasmimsilva18@gmail.com	t
1396	Ailton Luz Barroso	ailtonluzbarroso@gmail.com	Ailton Luz	@		f4e92306bb76fe8999aac99c32b45631	f	\N	2011-11-22 14:41:07.852676	1	1987-01-01	\N	f		t
1610	Antonio Nildevan Araujo Pires	niildevan@gmail.com	Nildevan	@		5f1c801196c3fa1ff7c410c089c42b0a	t	2011-11-22 20:18:36.271443	2011-11-22 20:07:42.972726	1	1992-01-01	\N	f		t
2547	auricélio sousa	auricelios59@hotmail.com	auricélio	@		779f0716355b1a9b4759258f019b22f2	f	\N	2011-11-25 09:34:50.401297	1	1994-01-01	\N	f		t
1303	Everton Barbosa	evertonbrbs@gmail.com	Evertonbrbs	@Vertaocnm		3056a8850328e965250cae94ff23d299	t	2011-11-22 10:23:50.104535	2011-11-22 10:16:33.322699	1	1990-01-01	\N	f	Vertaocnm@gmail.com	t
1403	Ricardo Bruno de Oliveira Cordeiro	bruno_oc94@hotmail.com	benooc	@brunooc94		3fd8d2f5750606c4b66024254ce2ecac	t	2011-11-22 15:29:12.539625	2011-11-22 15:26:59.350344	1	1993-01-01	\N	f	bruno_oc94@hotmail.com	t
1310	Robson	robsonfail@gmail.com	Das treva	@robinfail		e03e5b77f64a3da4451c096d0c5c7b58	t	2011-11-22 13:58:09.112471	2011-11-22 10:24:07.072665	1	1995-01-01	\N	f	robinxp_mf_@hotmail.com	t
1506	Paulo Welderson Santiago da Silva	Paulo_Welderson@hotmail.com	Welderson	@		b190c18f5cb1969a02fad9fb95d59af1	f	\N	2011-11-22 17:08:11.242977	1	1995-01-01	\N	f		t
1317	GABRIELA FERREIRA SALES DIAS	felipe_jorge_@hotmail.com	GABRIELA	@		fbfe4d02d88dbce996673d8aa2ce2eb0	f	\N	2011-11-22 10:58:41.400046	2	1994-01-01	\N	f		t
1323	NATHALYA SILVA ALMEIDA	MADSONDDIAS@HOTMAIL.COM	NATHALYA	@		6c759bd95e8187607c7ae723b799f31f	f	\N	2011-11-22 11:01:58.834541	2	1995-01-01	\N	f		t
1410	fernando cesar lemos junior	juniorlemos_oi@hotmail.com	junior lemos	@juniorlemosguns		6e84b0aff4a88be4cee046aed7076fbf	f	\N	2011-11-22 16:06:32.354395	1	1990-01-01	\N	f	juniorlemos_oi@hotmail.com	t
1415	amandasantos	mandasantos93@hotmail.com	mandethe	@		4b5e580ee2b5261b973269a808fc13d3	t	2011-11-22 16:38:57.619756	2011-11-22 16:35:01.35846	2	1993-01-01	\N	f		t
1653	ROSANE DE PAULA JERONIMO	rosaneseliga2010@gmail.com	rosanepaula	@rosaneseliga2010		b95aaeab741c00beceb668cc4968b664	f	\N	2011-11-22 21:19:05.359444	2	1991-01-01	\N	f	rosaneseliga2010@gmail.com	t
2096	charlly gabriel	biel_tuf@hotmail.com	biielgm77	@51pedroisidio		b6702b9a11654974bac11e326dc6a4e5	f	\N	2011-11-23 17:39:14.895811	1	2011-01-01	\N	f	pedroisidio1@hotmail.com	t
1537	Yago Barbosa Teixeira	yagoteixeira_16@hotmail.com	Yago Barbosa	@		e4efa6749c2382f113acc3910372783e	t	2011-11-22 17:21:22.245403	2011-11-22 17:20:15.204455	1	1995-01-01	\N	f		t
1619	MARIANA DA SILVA NOGUEIRA	marianasombra.silva72@gmail.com	mariana	@		2e4f32271a76505924f1d6b70ed1768a	t	2011-11-22 20:23:24.255246	2011-11-22 20:19:31.369159	2	1995-01-01	\N	f		t
1660	tayane da mata	gatatayane@gmail.com	tayane'	@		20569516c3f9521520eaa305f5feebaf	f	\N	2011-11-22 21:33:47.200591	2	1997-01-01	\N	f		t
1722	FRANCISCO OTÁVIO DE MENEZES FILHO	otavio.ce@gmail.com	Otávio	@		fc3df23f2c4987872e667d0a16e18e21	f	\N	2011-11-23 08:40:10.594814	1	2011-01-01	\N	f		t
1671	Gisele Silveira Lima	giselesilveira_bc@hotmail.com	gisele	@gigisilveira8		bcea9fc633c7f7f38797e1e6ba46c09b	t	2011-11-22 21:44:38.783359	2011-11-22 21:41:18.298224	2	1992-01-01	\N	f	giselesilveira_bc@hotmail.com	t
2574	Wendel Sousa Terceiro	wtesousatrcenro@yahoo.com.br	Wendel	@		dce94b693322e6bebaebd55b9237232b	f	\N	2011-11-25 13:55:39.849006	1	1952-01-01	\N	f		t
1762	Davi Alves Leitao	davi_alle@hotmail.com	leitao	@		ac0f56fed9921e64d84d8f1057e8fdba	f	\N	2011-11-23 09:34:28.063544	1	1994-01-01	\N	f	davialle@hotmail.com	t
1929	charl gabriel tavares rodrigues 	charllygabriel99@hotmail.com	charlly	@		31d09e544e8900f5b974fa592fb8e0c4	f	\N	2011-11-23 14:44:04.486097	1	2011-01-01	\N	f		t
2253	Valdeci Almeida Filho	valdecifilho21@gmail.com	valdeci	@		63301a337e4dcc67264397ce00e4748e	f	\N	2011-11-24 09:21:15.181852	1	2011-01-01	\N	f		t
2268	Ana Kelly Rodrigues Miranda	anakelly.rodrigues08@gmail.com	Kellynha	@		4c84a20d9123c23433256197ad299e11	f	\N	2011-11-24 10:07:25.992875	2	1996-01-01	\N	f	anakelly.rodrigues08@gmail.com	t
1350	Leonardo Sousa 	marcelaborges2000@hotmail.com	Leonardo	@		2947c2b9b06ca45f9a02733464944481	f	\N	2011-11-22 11:30:00.556066	1	1997-01-01	\N	f		t
315	CARLOS ANDERSON FERREIRA SALES	saycor_13_gpb@hotmail.com	Desordem	@AndersonNimb		06e23bf3b9a133d5459c1da743989aa7	t	2012-01-10 18:25:53.657326	2011-10-14 18:00:57.379024	1	2011-01-01	\N	f	saycor_13_gpb@hotmail.com	t
1351	Diego do Nascimento Brito	Diiego.Britto@gmail.com	Diego Brito	@DieegoBritto		af7ed36e657e920af9f4db6c2bd101b9	t	2012-01-15 21:47:48.879071	2011-11-22 11:31:57.514822	1	1993-01-01	\N	f	Diiego_x1@hotmail.com	t
1360	Francisca Joamila Brito do Nascimento	joamilabrito@yahoo.com.br	Joamila	@joamila		822e9b64115eda8f9fd2407773217ba3	t	2011-11-22 12:06:29.68218	2011-11-22 12:00:13.966017	2	1991-01-01	\N	f	joamilabrito@yahoo.com.br	t
1470	Rosiane de Melo	rosianed4@gmail.com	Rosi melo	@		bd514a8cb2f7584175ff38963d33e5ed	t	2011-11-22 17:08:40.644492	2011-11-22 17:01:16.0799	2	1996-01-01	\N	f		t
1352	Sofia Regina Paiva Ribeiro	sofiarpr@bol.com.br	Sophia	@		7e0cee4bcab67d83a4638724d5175085	f	\N	2011-11-22 11:41:06.672439	2	1974-01-01	\N	f	sofiarpr@bol.com.br	t
1600	SERIANO	irisaprendendo@gmail.com	popo b boy	@		49f2f879d2e49728f1af2a14d65f8ad8	f	\N	2011-11-22 19:08:00.05238	1	1997-01-01	\N	f		t
639	CARLOS HENRIQUE NOGUEIRA DE CARVALHO	carlos-tetra@hotmail.com	Bolinha	@	http://pt-br.facebook.com/	0c56f434f1493b1cb309dd8284ebcb77	f	\N	2011-11-08 22:42:15.319594	1	1993-01-01	\N	f	carlos-tuf@hotmail.com	t
1353	Leonardo Sousa Pires	leonardosousapires@hotmail.com	leonardo	@		bd86cf97a173750918b76e4279b0e5ee	t	2011-11-22 11:44:39.317312	2011-11-22 11:42:56.470827	1	1997-01-01	\N	f		t
672	ÁTILA CAMURÇA ALVES	camurca.home@gmail.com	atilacamurca	@atilacamurca	http://mad3linux.blogspot.com	7503fe11d34471577d41a7ce96ff3934	t	2012-11-12 17:39:14.158429	2011-11-09 19:18:52.596452	1	1988-01-01	\N	f	camurca.home@gmail.com	t
1354	FRANCISCO DANIEL MORAIS BASTOS	daniel.morais.d13@hotmail.com	DANIEL	@		6b0d9ea8d832f46c940755394e9c2a15	f	\N	2011-11-22 11:49:35.823428	1	1993-01-01	\N	f		t
1383	mariana de castro portácio	mariana_portacio@hotmail.com	mary_portacio	@		c118ec5ea5e06ae7b3c7910733ea3911	f	\N	2011-11-22 14:20:13.93443	2	1995-01-01	\N	f		t
1355	ANTONIO AUREMY SILVA COSTA	auremycosta@hotmail.com	AUREMY	@		b7cae41bca3f6de145bf3038ec802dc0	f	\N	2011-11-22 11:50:55.940717	1	1994-01-01	\N	f		t
1356	JORDI LUCAS CRUZ DOS SANTOS	jordi_caninde@hotmail.com	JORDI LUCAS	@		b170ec9cc9e8051bbe2fbe10e65ee945	f	\N	2011-11-22 11:52:28.247476	1	1993-01-01	\N	f		t
1357	GRACIELE GOMES SOUSA	gracielegomess@hotmail.com	GRACIELE	@		b4d7a7f567cf31d4809a5bd85e111784	f	\N	2011-11-22 11:53:43.02666	2	1994-01-01	\N	f		t
1497	Thomas Jefferson Ferrer da Silva	tjefferson1996@hotmail.com	jefferson	@		4e22c271e80017932428d3087fb8fd74	f	\N	2011-11-22 17:06:15.096767	1	1996-01-01	\N	f	tjefferson1996@hotmail.com	t
1358	LILIA NATIELLE UMBRELINO LOBO	lilianathy02@hotmail.com	LILIA NATY	@		d18308c6384a231e6afda9aa431638f9	f	\N	2011-11-22 11:55:37.565185	2	1994-01-01	\N	f		t
1397	Cláudio Bezerra Barbosa	claudiobarbosa1987@yahoo.com	Cláudio	@		080d4f28c542bb6c0889b4532cc86578	f	\N	2011-11-22 14:47:59.42193	1	1987-01-01	\N	f		t
1611	MARIA SOCORRO DE SOUSA	cliksocorro@yahoo.com.br	socorrosousa	@		eac5f81c438ec7e5536782627914568d	t	2011-11-22 20:40:40.207968	2011-11-22 20:09:32.522717	2	1979-01-01	\N	f	clicsocorro@hotmail.com	t
1404	Mariana Lane Freitas dos Santos	mariana.enalfreitas@gmail.com	Mariana Lane	@Mari125Freitas		6d69894dc8baa8754cb04ccdf0a77f50	f	\N	2011-11-22 15:27:34.784588	2	1992-01-01	\N	f	mariana.enalfreitas@gmail.com	t
1411	josafa martins dos santos	tecjosafa@gmail.com	Josafa	@		7f839886e11ca4873315440b3ffc1eab	t	2011-11-22 16:23:13.074032	2011-11-22 16:07:47.207501	1	2011-01-01	\N	f		t
1507	Francisco Anderson Farias da Silva	anderson-farias20@hotmail.com	Farias	@		069e556c2920ac0025d33e7440a61760	f	\N	2011-11-22 17:08:42.342013	1	1995-01-01	\N	f		t
1517	Maria Caroline da Silva	carolsilva010@gmail.com	McMcMc	@		ef77bc77f6effb2b0a1c89da314cf8c7	f	\N	2011-11-22 17:13:12.28799	2	1995-01-01	\N	f		t
1715	Haron Charles	haroncharles@hotmail.com	Haron Charles	@haroncharles	http://www.euamopagodao.com	24525c8b97334786d6e8dd76e34f7702	f	\N	2011-11-23 03:44:00.002141	1	2011-01-01	\N	f	haroncharles@hotmail.com	t
1620	Francisca Naiane Ferreira Honorato	nanne2010@gmail.com	naiane	@		07cf97bce08d7dbdab72d01ce6f30989	t	2011-11-22 20:34:04.871107	2011-11-22 20:20:34.613311	2	1992-01-01	\N	f		t
2519	Marcos Martins Pineo	marcospineo@gmail.com	Markos Bubu	@marcos_bubu		f14d9d2c4f6c6c33d50346cf2c9d91d4	f	\N	2011-11-24 20:54:23.849037	1	1989-01-01	\N	f	markosbubu@gmail.com	t
1723	paulo christopher	cristianocc.cppdd@yahoo.com.br	paulinho	@		efe84f0e4f959a387d90667b2cb6275e	f	\N	2011-11-23 08:57:30.571854	1	1995-01-01	\N	f		t
1422	Ana kimberly Marçal de Sousa	kimberlly_dazgtinhas@hotmail.com	 kimberlly	@		ca0a357dbd4edcf987c70dd170e20336	f	\N	2011-11-22 16:42:30.232136	2	1995-01-01	\N	f		t
1501	Rhaiane e Silva Vieira	rhaianevieira@gmail.com	Rhaiane	@		fc763dfb1ed7884499095606526b6c75	t	2011-11-22 17:25:27.494833	2011-11-22 17:06:45.112434	2	1994-01-01	\N	f	rhaiane94@hotmail.com	t
1654	THIAGO HENRIQUE SILVA DE OLIVEIRA	thiagoseliga@gmail.com	thiagohenrique	@thiagoseliga		b145ec5d4cac0f01ccec5035c857fee9	f	\N	2011-11-22 21:21:09.968279	1	1991-01-01	\N	f	thiagoseliga@gmail.com	t
1553	Anderson  Bruno	legalmenteb.boy@hotmail.com	Japa Hip Hop	@		ca589dd8212f3d0ae09402d03719af60	f	\N	2011-11-22 17:28:48.800143	1	1993-01-01	\N	f		t
1661	Maryana Almeida	maryanaalmeida42@gmail.com	Maryana'	@		0eb9f9c85cad63adacb35d2f12dc96ec	f	\N	2011-11-22 21:34:51.969928	2	1998-01-01	\N	f		t
1737	Nailton José de Sousa Carneiro	nailtoninfo@yahoo.com	Tayler	@		f179f6df01297061ac34645ea10b8401	f	\N	2011-11-23 09:27:24.850392	1	1995-01-01	\N	f		t
2122	juan matheus da silva duarte	juans.kennedy@hotmail.com	juansk	@		a6249e698af9b9eaa50c8696f757b7c7	f	\N	2011-11-23 18:00:03.083013	1	1996-01-01	\N	f		t
1681	Vitor Kern	vitorkern@hotmail.com	DarthVK	@AloneKern		6babd505e81cd96e8214d08773c0dca1	f	\N	2011-11-22 21:58:02.734183	1	1994-01-01	\N	f	vitorkern@hotmail.com	t
1686	Fabrício Rodrigues	dariusrodrigues@hotmail.com	splatt	@fabriciocecs		f6d53aab5ed32c30f17f3c67fa3e408c	f	\N	2011-11-22 22:06:14.99749	1	1993-01-01	\N	f	dariusrodrigues@hotmail.com	t
2548	Maynara Ávila Rodrigues	mayh.avila.screamo@bol.com.br	Maynara	@		5f0e9056e03417a21e9f1853e77beebb	f	\N	2011-11-25 09:36:49.122454	2	1996-01-01	\N	f		t
1690	vinicius cabral oliveira	asturcabral@hotmail.com	Cabal Alien	@		183e8f921c79238346da08535cd24c5a	f	\N	2011-11-22 22:35:48.004992	1	1995-01-01	\N	f		t
1774	paulo chrystopher da silva sousa	paulochrystopher@hotmail.com	paulinho	@		69bd32939100a78b400aa35841b288bd	f	\N	2011-11-23 09:49:44.267557	1	1996-01-01	\N	f		t
1940	Davi Felipe Soares	davifelipe1996@hotmail.com	davidy	@		b719b089579e194dc3ca3dba2087d78b	f	\N	2011-11-23 14:50:23.937024	1	1996-01-01	\N	f		t
2254	Francisco Wallyson Ferreira Gomes	wallyson2007@hotmail.com	pipoca	@		efeb864d0a684786199fde04472dc288	f	\N	2011-11-24 09:24:25.636383	1	2011-01-01	\N	f	wallyson2007@hotmail.com	t
1795	Victor Lucas Amora Barreto	victor_lukaslol@hotmail.com	Victor Lucas	@		d0993cf6de29d619d07bce1863caf9e7	f	\N	2011-11-23 10:24:31.22203	1	1995-01-01	\N	f		t
2153	Lyndainês Araújo dos Santos	lyndainesaraujo@gmail.com	Lyndainês	@		7a260cf391343c3b53e365539e405591	f	\N	2011-11-23 18:37:18.744443	2	2009-01-01	\N	f		t
2269	Rodrigo Câmara Guimarães	rodrigo.camara23@gmail.com	Rodrigues	@		df47a8ca5f96e3d5d591c0a9331a3e3b	f	\N	2011-11-24 10:08:42.336673	1	1994-01-01	\N	f		t
1424	Monique dos Santos Girão	moniqueegirao@gmail.com	Monique	@		121e194fdb4955c2ee393af445030565	f	\N	2011-11-22 16:42:59.232646	2	1993-01-01	\N	f		t
1152	ALDISIO GONÇALVES MEDEIROS	aldisiog@gmail.com	AldisioGM	@		9c5bdf28414277ce933e86edb1c5c33d	t	2012-01-16 13:46:35.856775	2011-11-21 17:45:37.098164	1	1992-01-01	\N	f		t
1601	Feleciano	frandiascosmetico@hotmail.com	Samurai b-boy	@		0b08eb548c012c7a1693537bb9a9bb7b	f	\N	2011-11-22 19:09:18.13288	1	1997-01-01	\N	f		t
817	AMANDA AZEVEDO DE CASTRO FROTA ARAGAO	amandazevedo_@hotmail.com	amanda	@amandazvd		c3b4bef3f323af9c4d8d23d0d78e73b4	t	2012-01-10 18:25:43.440049	2011-11-14 22:05:00.779498	2	1994-01-01	\N	f	amanda.azevedo3@facebook.com	t
1636	guilherme da silva braga	heavyguill@gmail.com	espectro	@		6bc8d3d21811203d8c80c682d5a53a1c	t	2011-11-22 21:17:33.452829	2011-11-22 20:48:08.815847	1	1991-01-01	\N	f		t
1421	Helen Raquel Frota Pessoa	helenraquel.info@gmail.com	Helen Raquel	@helenraquel		c9145fc1bbff065ac8acdd3f86709ed1	t	2011-11-22 16:43:12.589748	2011-11-22 16:42:27.159962	2	1983-01-01	\N	f	helen.raquel@hotmail.com	t
1426	João Victor Evangelista da Silva	jvictor.info@gmail.com	João Victor	@		2344edf44aac5bd68db726fb05f3de25	f	\N	2011-11-22 16:43:30.795043	1	1995-01-01	\N	f	jvtoc@hotmail.com	t
1021	ANA BEATRIZ FREITAS LEITE	aninha_beatriz_109@hotmail.com	Biazinha	@BiazinhaFreitas		a44ed7e1a5a51b5eae1e125f3cf4268e	f	\N	2011-11-18 19:16:39.788809	2	1992-01-01	\N	f	aninha_beatriz_109@hotmail.com	t
677	ANDRE TEIXEIRA DE QUEIROZ	andre.teixera@hotmail.com	não tenho	@		f25e78d13acac3555a0a37e5e9b1499e	t	2012-01-15 18:10:35.096743	2011-11-10 02:32:33.614841	1	1993-01-01	\N	f	andre.teixera@hotmail.com	t
1419	Luciana Caetano Severo	luci_caet@hotmail.com	Luciana	@		139c5cba43da60e6410f0920ee592b69	t	2011-11-22 16:43:51.15395	2011-11-22 16:42:15.670318	2	1995-01-01	\N	f	luci_caet@hotmail.com	t
1427	Emanuel Santos Sousa	emanuelss25@hotmail.com	Emanuel	@		ede464b41ba6a247514720912f60cdae	t	2011-11-22 16:57:14.762702	2011-11-22 16:44:13.445563	1	1995-01-01	\N	f	emanuelss25@hotmail.com	t
1648	RENATO LIMA BRAUNA	renato.ifce@gmail.com	Renato	@		e3fc22bd7a6daa2d16f586c6d8780667	t	2012-01-10 18:26:28.103813	2011-11-22 21:06:45.109576	1	1983-01-01	\N	f	renato.ifce@gmail.com	t
1471	Rayane Damasceno de Araújo	rayanedamasceno@bol.com.br	rayane	@		320c8ec58e95f21bb51cdfe113c4ea69	t	2011-11-22 17:05:49.033754	2011-11-22 17:01:47.883611	2	1995-01-01	\N	f		t
1429	Marcos Anastacio de Oliveira	markinhoe30@gmail.com	Markinho	@		e40f9b89cb916ee5c8f2e6d67d9e5e2a	f	\N	2011-11-22 16:44:41.096805	1	1995-01-01	\N	f		t
1612	Vladimir Viana De Sousa	vvvladimir169@gmail.com	Vladimir	@		5a4e94870243adde97acafeb95dbb313	t	2011-11-22 20:19:52.687219	2011-11-22 20:10:07.790631	1	1991-01-01	\N	f		t
1430	Paula Rithiele Ferreira Rodriguês	rithielle13@hotmail.com	Rithielle	@rithielle13		4b8d6a54e7b502cfee93e684c54fdb22	t	2011-11-22 16:53:54.233262	2011-11-22 16:44:46.784216	2	1996-01-01	\N	f	rithielle13@hotmail.com	t
1919	Davi Távora	davi_tuf16@hotmail.com	Davi16	@		2990781cf7db5fa64adb583c28bde5b1	f	\N	2011-11-23 14:38:21.592297	1	1996-01-01	\N	f		t
2520	ILANE KARISE BARBOSA CUNHA	ilane_karise@yahoo.com.br	KARISE	@Ilarise		df5fde5cf81ad84916b22dbde1319285	f	\N	2011-11-24 21:00:35.556881	2	1987-01-01	\N	f	ilane_karise@yahoo.com.br	t
1485	João Victor Evangelista da Silva	jitss@live.com	João Victor	@		4befa0b24839d16b3a38a386de5719ce	t	2011-11-22 17:08:30.968181	2011-11-22 17:04:38.28314	1	1995-01-01	\N	f	jvtoc@hotmail.com	t
1432	João Victor Evangelista da Silva	jvtoc@hotmail.com	João Victor	@		3a0816a8fb8b1361372121246a414a88	f	\N	2011-11-22 16:45:07.594132	1	1995-01-01	\N	f	jvtoc@hotmail.com	t
1621	roberto	robertobmw.v8@gmail.com	cocomom	@v8roberto		e333b736eb6ab5982cef81c6a88e385e	f	\N	2011-11-22 20:21:03.675198	1	1994-01-01	\N	f	robertod2.2000@hotmail.com	t
1433	Fernando Martins Da Silva Filho	nandincachoeira1@hotmail.com	Nandin	@		4445ff5c9d4668677595a1436b6c0d69	t	2011-11-22 17:10:58.949632	2011-11-22 16:45:18.362992	1	1995-01-01	\N	f	nandincachoeira1@hotmail.com	t
1498	Mairton Gomes Andrade	mairton_andrade@hotmail.com	macacheira	@		e21c7d5448a54f2369d258bd5e24da35	t	2011-11-22 17:21:01.769759	2011-11-22 17:06:18.602813	1	1996-01-01	\N	f	mairton_andrade@hotmail.com	t
1435	Letícia Costa Lima	leticia_fdm@hotmail.com	leticia	@		b420baeefded2547808fbbf7638a75bc	t	2011-11-22 19:10:49.305669	2011-11-22 16:45:46.51676	2	1995-01-01	\N	f	leticia_fdm@hotmail.com	t
1436	Francysregys Rodrigues de Lima	regyslima07@gmail.com	Regys Lima	@Regysyagami		543045798970e434f0a00e677e0cf378	f	\N	2011-11-22 16:45:51.721962	1	1993-01-01	\N	f	regysyagami@gmail.com	t
1764	francisco Robson Aires Inácio	gts_hx@hotmail.com	RoBiiN	@RoBiiM_		5cb9ac4b4eb2c3bfe2bf658fe4558ce9	f	\N	2011-11-23 09:34:37.629603	1	1994-01-01	\N	f	gts_hx@hotmail.com	t
2123	mario cesar florencio da costa	cesarmario1993@gmail.com	marios	@		2fa86d33bda7cf50445ef294751e4f8e	f	\N	2011-11-23 18:00:32.598692	1	1993-01-01	\N	f		t
1508	Geane Oliveira de Alcântara	geane-oliveira20@hotmail.com	Geane Fofa	@		4ac2d45e671b4fb61c01712f8da5884d	f	\N	2011-11-22 17:08:53.321825	2	1996-01-01	\N	f		t
1518	Felipe Caetano Vieira	lipe_sid@hotmail.com	Felipe	@		d9fbd7d3ec0796f0e82fccc5d2ec661a	f	\N	2011-11-22 17:13:16.880326	1	1994-01-01	\N	f		t
2549	Francisco José Martins Machado Freitas	fj_filho@hotmail.com	Franzé	@		2480c9d71c996c7e03a92219ceddc3e3	f	\N	2011-11-25 09:37:46.75897	1	1994-01-01	\N	f		t
1655	Weuller dos Santos Leite	weuller-sl@hotmail.com	HeadBone	@		a8c5b259eb961a99c46de0018b776ba6	f	\N	2011-11-22 21:26:55.128372	1	1994-01-01	\N	f		t
1662	Germana Cassia Mateus Cunha	gemanacassia@hotmail.com	germana	@		0cdb1f8816da4eb018bf094813044fad	f	\N	2011-11-22 21:35:18.600527	2	1993-01-01	\N	f	gemanacassia@hotmail.com	t
2255	FRANCISCO ROBERTO MOTA SILVA	robertocarlos3ggg@hotmail.com	plzulu	@		26733ed7835f52093e51e61d95e5e86d	f	\N	2011-11-24 09:29:28.411384	1	1985-01-01	\N	f	robertocarlos3ggg@hotmail.com	t
2154	Maria Tailane de Sousa Araújo	laninha-cat100@hotmail.com	Tailane	@		e41a67c5d6ce2449d72f1cf4b4191a7c	f	\N	2011-11-23 18:38:19.33714	2	2009-01-01	\N	f		t
1682	Maryana Almeida 	maryana.anayram@gmail.com	Maryana	@		22516414aa46c9d2bac2db27e153e157	f	\N	2011-11-22 21:58:45.648612	2	1998-01-01	\N	f		t
1977	Bruna Maria Nunes Ferreira	bruna_nunes18@hotmail.com.br	Bruna Nunes	@		1490cd11012e736cb64b83a7d23865cf	f	\N	2011-11-23 15:03:15.439665	2	2011-01-01	\N	f		t
1687	Kaila Carvalho Laurentino	wilianapaiva@yahoo.com	Kaila Carvalho	@		9ebd1450ae53acdac2d7e954dfe16fd2	f	\N	2011-11-22 22:17:25.936975	2	2001-01-01	\N	f		t
2270	Beatriz Oliveira da Silva	beatrizoliveira952010@hotmail.com	Beatriz	@		ede209fbf3e531ccbe6e21873c5b8de7	f	\N	2011-11-24 10:09:38.198587	2	2011-01-01	\N	f		t
1689	Janderson Morais da Silva	djjanderson2010@hotmail.com	Dj Janderson	@		e20bf9d48d07d9e3675eb2a1ce24919b	t	2011-11-22 22:34:19.471715	2011-11-22 22:29:29.274145	1	1993-01-01	\N	f	djjanderson@live.com	t
1985	Francisca Tissiana Sousa Alves	tissi.ana@hotmail.com	Tissiana Alves	@		c7805caebe91f9394bfe907f47a30956	f	\N	2011-11-23 15:07:15.905394	2	2011-01-01	\N	f		t
2166	Felipe Ferreira Paixão	felipeferreirainformatica1@gmail.com	Paixão	@		7d1b824572795f8db6ca90de32e7af13	f	\N	2011-11-23 19:08:37.730454	1	1994-01-01	\N	f	felipe-p63@hotmail.com	t
2283	Lucas Soares Vasconcelos	flalucasfla2@hotmail.com	Soares	@		96f52de56a962a5d85f8b5029c89034a	f	\N	2011-11-24 10:13:53.082276	1	2011-01-01	\N	f		t
2295	maria celestina monteiro de lima	mariacelestinamo@gmail.com	celestina	@		eed336f8a5af7f79f167415002d6eead	f	\N	2011-11-24 10:21:54.592849	2	1973-01-01	\N	f		t
2575	renata priscyla conceicao costa	renatapriscyla@gmail.com	Priscyla	@		b0afdb5559534a563678e645f185bc60	f	\N	2011-11-25 13:57:02.099514	2	1984-01-01	\N	f		t
1439	Amanda Mayara	amanda0gm@hotmail.com	Amanda	@amandamayaraf		29e2f5e7cf3d75245096288d40d866c3	f	\N	2011-11-22 16:46:23.405087	2	1993-01-01	\N	f	amanda0gm@hotmail.com	t
449	ITALO DE QUEIROZ MOURA	italo_de_queiroz@hotmail.com	Italo Queiroz	@italoqueiroz		196e8bd76ebbcf7ee256b2ca5566d65e	t	2012-01-16 01:14:17.082926	2011-10-31 15:22:11.662222	1	2011-01-01	\N	f		t
1440	Ana Clara Silva Viana	anaclara.ti@hotmail.com	Clarinha	@		1e2c51d52d140fb12243e55e7aba3ab1	f	\N	2011-11-22 16:47:10.46632	2	1995-01-01	\N	f	anynhaclara_11@hotmail.com	t
1602	VALRENICE NASCIMENTO DA COSTA	valrenice@yahoo.com.br	Maria Costa	@		5c899478d72f6aecbe352f9b2bebf8e6	f	\N	2011-11-22 19:09:45.980141	2	2011-01-01	\N	f		t
3590	SAMUEL BRUNO HONORATO DA SILVA	ifce.maraca25@ifce.edu.br	SAMUEL BRU	\N	\N	d554f7bb7be44a7267068a7df88ddd20	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
1441	Gabriel	gabrielcamara10@hotmail.com	Gabriel Eufrásio	@		f3dec6ae9710ffb8f14256332fd99db7	t	2011-11-22 16:48:12.67338	2011-11-22 16:47:22.516556	1	1995-01-01	\N	f	gabrielcamara10@hotmail.com	t
1622	Francisco Rafael Pontes Teixeira	rafawlpjunior@gmail.com	RPONTES	@		cdf8c162c0dbe0d4ba74a8f97ae4bbc7	f	\N	2011-11-22 20:27:06.66102	1	1986-01-01	\N	f		t
1423	Gleison anderson	garotoanjo2011@hotmail.com	invasor	@		dfc4d87e901ed4ccd7a3b40e1fe8a180	t	2011-11-22 16:47:50.73028	2011-11-22 16:42:45.067614	1	1994-01-01	\N	f	garotoanjo2011@hotmail.com	t
1442	Anderson Menezes Duarte	andersonmenezesamd@hotmail.com	Dr. bill	@		f4ff1efbf4c88f80bf465a36e230c348	f	\N	2011-11-22 16:47:54.482938	1	1995-01-01	\N	f		t
2521	FRANCISCO RENATO LESSA DE OLIVEIRA	ruth.tuf579@hotmail.com	RENATINHO	@		3a222b5fd437a9a3e8b951a58d0a1765	f	\N	2011-11-24 21:07:31.330922	1	1997-01-01	\N	f		t
1420	Rafael Rodrigo Carvalho de Lima	rodrigolima.2b@hotmail.com	Rafa Lima	@		0e60a8dd650c00ed855dca609444bcf2	t	2011-11-22 16:49:16.358364	2011-11-22 16:42:22.853826	1	1995-01-01	\N	f	rafael-limaplay@hotmail.com	t
1437	davles	davles.sena@hotmail.com	davlessena	@davlessenna		250f48e5dc2d1cd003e2b2739a4f5748	t	2011-11-22 16:48:06.956384	2011-11-22 16:45:54.547931	1	1996-01-01	\N	f	davles.sena@hotmail.com	t
1443	Yago Barbosa Teixeira	yagoteixeira16@hotmail.com	Yago Barbosa	@		22a4687d95e174be2bdae643d688a4ad	f	\N	2011-11-22 16:48:17.368787	1	1995-01-01	\N	f		t
1509	Ayrton Alexsander Monteiro da Silva	monteiro_ayrton01@hotmail.com	Ayrton	@		94feefaf7b140be8da66ac169bc005dc	t	2011-11-22 17:14:45.715879	2011-11-22 17:09:02.779865	1	1996-01-01	\N	f		t
1613	eudes filho	eudesavatar@hotmail.com	eudesfilho	@eudes_filho		71fd2dbb4029d9d978af352e56dffad7	f	\N	2011-11-22 20:10:59.33615	1	1995-01-01	\N	f		t
1920	Italo Aderson Ferreira Rabelo	italo_p.emanueleicaro@hotmail.com	Itinho	@		1f83ee03bdc7b57f64adc7a751dd0b32	f	\N	2011-11-23 14:38:45.876927	1	1996-01-01	\N	f	italo_p.emanueleicaro@hotmail.com	t
1519	Aloísio Silva de Sousa	aloisiocom@gmail.com	Aloisio Sousa	@aloisiosousa		bbb911708c380adc763eaff7f0e5464d	f	\N	2011-11-22 17:13:48.652043	1	1980-01-01	\N	f	aloisiocom@gmail.com	t
1528	Nazareno Cavalcante  de Souza	nazareno_corinthiano@hotmail.com	nazareno	@		bd984eeeaeb66ba48c467cfff2d3548c	t	2011-11-22 17:28:50.588748	2011-11-22 17:16:10.760245	1	2011-01-01	\N	f		t
1449	Stefanie Helena Paula de Moura	stefanie_helena@hotmail.com	 Helena	@stefanie__helena		c59b5a79f170d847a69640700dce75d4	t	2011-11-22 17:02:15.954741	2011-11-22 16:50:35.948912	2	1994-01-01	\N	f	stefanie__helena@hotmail.com	t
1765	Maiara Cindy Rodrigues Pontes Lima	maiara_cindy@hotmail.com	Ciindy	@		49a4b9cd0b263ec861871fb39d89170f	f	\N	2011-11-23 09:35:06.838527	2	1995-01-01	\N	f	maiara_cindy@hotmail.com	t
1450	daiana gomes maia	dada_jc14@hotmail.com	daiana	@		4c1dc85693ac521dd1864af819c74f12	f	\N	2011-11-22 16:50:41.174321	2	1992-01-01	\N	f	dada_jc14@hotmail.com	t
1932	Daniel Firmiano da Silva	daniel_japa15@hotmail.com	daniel japa	@		a3567b3ecf71c452dcddd2cabd95df9d	f	\N	2011-11-23 14:47:20.262131	1	1996-01-01	\N	f		t
1451	Emanuel Lucas	emanuelfurtado_aranha@hotmail.com	Luckazin	@		9d04c667548ed57583f8e00c6ad78398	f	\N	2011-11-22 16:51:08.16919	1	2011-01-01	\N	f	luckazin2011@hotmail.com	t
1656	caiodi	caiomalino@hotmail.com	u4kcay	@		6ff9825adc63652ba7b3ef89e8240440	f	\N	2011-11-22 21:28:27.071165	1	1994-01-01	\N	f		t
1493	Vanessa da Costa Guimarães	vanessaguimaraes_@hotmail.com	Vanessa Guimarães	@vguimaraaes		298794d3c21c8bb5d1ac1d08b07887d9	t	2011-11-22 17:22:04.621092	2011-11-22 17:05:25.045386	2	1995-01-01	\N	f	vanloveikaro@hotmail.com	t
1544	natália fernandes carvalho	natalia151928@hotmail.com	natalia	@		a2cb4087684f1fe12d11ae10fa74482a	f	\N	2011-11-22 17:23:49.976003	2	1993-01-01	\N	f	natalia151928@hotmail.com	t
1453	Aline Maria Mendes André	lilikka_15@hotmail.com	Aline Maria	@_AlineMaria		8e5055de24d23d1770ccb4d88e2e2d68	f	\N	2011-11-22 16:51:52.240786	2	1993-01-01	\N	f	lilikka_15@hotmail.com	t
1425	Flávio de Oliveira Chagas	flaviooliveira.ohs@gmail.com	Flávio	@		1fe69e6661f829f522f3340f4c98c84c	t	2011-11-22 17:26:18.387814	2011-11-22 16:43:02.837947	1	2011-01-01	\N	f	flaviotuf90@hotmail.com	t
1551	Aretha Vieira Magalhães	douglasjva@hotmail.com	Aretha Magalhães	@		230c021492c367f56fb521e3a7e1b443	t	2011-11-22 17:31:18.558458	2011-11-22 17:27:57.39527	2	1994-01-01	\N	f		t
1641	jonas da silva barroso	barroso.jonasdasilva@gmail.com	idiota	@		d239cab2600bfb14ce185707e44b8e79	t	2011-11-22 21:36:14.329678	2011-11-22 20:53:36.907151	1	1995-01-01	\N	f	barroso.jonasdasilva@gmail.com	t
1252	Antonio Anderson Vieira	andersonadler@hotmail.com	Andim 	@		54ac714b4aae4c09bf53fba4f1c556e3	t	2011-11-22 17:28:49.370087	2011-11-22 09:41:08.059629	1	1994-01-01	\N	f	andersonadler@hotmail.com	t
1775	Jansen Nogueira Constantino de Souza	jansen_student@hotmail.com	Jansen	@		d1c00dbfb9a0eb2d5b169bdd14dadc0c	f	\N	2011-11-23 09:56:57.51842	1	1993-01-01	\N	f	jansen_student@hotmail.com	t
1674	Francisco Anderson Silvino Mendes	andersonsilvino@hotmail.com	Montanhão	@		73fb2ab8875eeff51369a98fc7f30e1b	f	\N	2011-11-22 21:42:03.511139	1	1993-01-01	\N	f	andersonsilvino2@hotmail.com	t
1476	Anderson Moisés Gomes Ferreira	moises-gaara@hotmail.com	uzumaki	@		dc9249a9541a1466b3d77e20cb482b00	t	2011-11-22 17:32:23.406078	2011-11-22 17:03:29.386084	1	1996-01-01	\N	f	moises-gaara@hotmail.com	t
2124	JOSUE DA SILVA ALVES	josuealves16@hotmail.com	JOSUE ALVES	@		d9426429ea0655ee69ee720f03b60e66	f	\N	2011-11-23 18:01:12.615189	1	1995-01-01	\N	f		t
1188	Karoline Alcântara Trajano	karoline.200930@hotmail.com	karolzinha	@		6053def04a2487ae9d30ee8d7b3e29bb	t	2011-11-22 21:51:25.064866	2011-11-21 22:52:39.723865	2	1995-01-01	\N	f	karoline.200930@hotmail.com	t
1683	Jose Adonias Pessoa	adonias_bc@hotmail.com	Adonias	@		db762ce45b3cc05ab5fbe1a62c04ab4e	f	\N	2011-11-22 21:59:16.071762	1	1991-01-01	\N	f	adonias_bc@hotmail.com	t
1789	Lyza Guynever Modesto Nogueira	lyzaguynever@hotmail.com	Lyza Guynever	@LGuynever		1dc89da82c2ce2fdc9d435c031297d9f	f	\N	2011-11-23 10:21:48.230991	2	1995-01-01	\N	f	lyza.guynever@gmail.com	t
1942	Pedro Henrique Freitas do Nascimento	pedro-tj2011@hotmail.com	pedroph	@		e8fafce85b7eb600d51a64f5a782efd3	f	\N	2011-11-23 14:51:02.233675	1	1995-01-01	\N	f	pedrohenrique95@hotmail.com	t
2220	Maria Elissandra Cosme da Silva	elissandraoc@gmail.com	Elissandra	@		92bc5f33b8f42923068d1c55592a8b7a	f	\N	2011-11-23 22:25:54.787909	2	1993-01-01	\N	f	elissandra_sss@hotmail.com	t
2155	Ian do Carmo Marques	ian.icm.gato.gaiato@gmail.com	Marck's	@		8bcd1f3ae90bb4a27b0ad2eb3619fd9e	f	\N	2011-11-23 18:39:36.595274	1	2009-01-01	\N	f		t
2550	lucas filho	lucascoe@gmail.com	licas..	@		0823c651f543efee873c7ca4bd3c3106	f	\N	2011-11-25 09:41:52.98039	1	1975-01-01	\N	f		t
2576	Giovana Rodrigues de Castro	gilcastro09@gmail.com	giovana	@		d50b961ac445b59feb146f63629b47d8	f	\N	2011-11-25 14:16:01.231377	2	2002-01-01	\N	f		t
1454	Felipe da Silva Vitaliano	felipevitaliano@gmail.com	Felipe	@		0084333ecca3222afd04a621aa0a5b86	f	\N	2011-11-22 16:51:56.119008	1	1993-01-01	\N	f		t
689	ADONIAS CAETANO DE OLIVEIRA	adoniascaetano@gmail.com	Adonias	@		2aaf68ba90f209eba80cd25662bb7e29	t	2012-01-14 19:29:06.225327	2011-11-10 16:06:03.543246	1	1989-01-01	\N	f	adoniascaetano@gmail.com	t
1455	Ernane	ernanespedalada@gmail.com	Pedalada	@		886eb8f05275bf3dec29230fb6af8e4f	f	\N	2011-11-22 16:52:19.814519	1	1992-01-01	\N	f	ernanespedalada@gmail.com	t
3591	VIVIANE DA COSTA PEREIRA	ifce.maraca26@ifce.edu.br	VIVIANE DA	\N	\N	5e9f92a01c986bafcabbafd145520b13	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
1446	JOELSON FREITAS DE OLIVEIRA	JHOELSONMD@HOTMAIL.COM	JOELSON	@		e33a5420bbd7000c93bcdd216ddef06c	t	2011-11-22 16:53:41.769875	2011-11-22 16:49:03.140358	1	1992-01-01	\N	f		t
1456	Rômulo Nobre	romulo.nobre@hotmail.com	Rômulo	@		c8e1d17f96a0a147885b1338b8d19b35	f	\N	2011-11-22 16:52:36.368072	1	1995-01-01	\N	f	romulo.nobre@hotmail.com	t
2100	Kátia Cristina de Roberto Mendonça	katytarobert@hotmail.com	Kátia	@		028c7a197264d97ce2d4e99b67b9c641	f	\N	2011-11-23 17:39:39.735949	2	1973-01-01	\N	f	katytarobert@hotmail.com	t
1457	Joseph Júnior	joyrolin@hotmail.com	joseph	@		8eab093811eca3126473468421a565db	t	2011-11-22 16:58:29.38933	2011-11-22 16:52:38.677793	1	1995-01-01	\N	f	joyrolin@hotmail.com	t
1603	Wildenberg	artanilse-pinheiro@bol.com.br	B-boy feiy	@		15e8097d1b37feead1ac11140e50d5d4	f	\N	2011-11-22 19:10:30.644302	1	1997-01-01	\N	f		t
1623	Bruno Costa	br15x@hotmail.com	Brunão	@		be85a2805e0cfa8a8cef184c08a4fe6b	t	2011-11-22 20:32:21.064837	2011-11-22 20:30:17.449312	1	1995-01-01	\N	f	br15x@hotmail.com	t
1438	WELLINGTON DOS SANTOS CUNHA	wellingtondos_santoscunha@hotmail.com	lantejoula	@		239ee1a34a49c97d9b1aee5f66175521	t	2012-01-10 18:26:31.247663	2011-11-22 16:46:22.066317	1	1986-01-01	\N	f	baalzebub_chan@hotmail.com	t
1452	kécio Jonas da Silva Queiroz	kecioqueiroz12@gmail.com	kécio	@		9be6ba8fe513983c6e77eb47feb7e75a	t	2011-11-22 16:53:12.177955	2011-11-22 16:51:10.491316	1	1994-01-01	\N	f	kecioqueiroz12@gmail.com	t
1473	Gleydson Ferreira Coelho	gleydsonferreira_tecno@hotmail.com	Geeh'Ferreira !	@gleydsonfc	http://rock-greatesthits@blogspot.com	ab19bdece33d63fb747c4b64835f2675	t	2011-11-22 17:18:15.017137	2011-11-22 17:02:48.101627	1	1996-01-01	\N	f	gleydissinho.tuf@hotmail.com	t
1614	MARIANA DA SILVA NOGUEIRA	MARIANASOMBRA.SILVA72@GMAIL.COM	MARIANA	@		a20e270df937b7b2c532cb820d57399a	f	\N	2011-11-22 20:11:20.870165	2	1995-01-01	\N	f		t
1638	Jucimar de Souza Lima Junior	jucimarlimajunior@gmail.com	Jucimar Lima Junior	@		d22a20b9a1f1293c470fa33301df1498	t	2011-11-22 21:14:35.841032	2011-11-22 20:49:59.820409	1	1982-01-01	\N	f		t
1482	José Nogueira Barbosa Neto	netodatuf_nogueira@hotmail.com	Neto Williams	@Netowilliams	http://neto-williams.blogspot.com	4c11d097aac1f0a4d1912ed49b530787	t	2011-11-22 17:19:10.710077	2011-11-22 17:04:19.000485	2	2011-01-01	\N	f	netodatuf_nogueira@hotmail.com	t
1921	Davi Távora	romulonobre@ymail.com	Davi16	@		39858bd15d89e77133ae1a302655156f	f	\N	2011-11-23 14:39:54.669907	1	1996-01-01	\N	f		t
1740	Mateus Cunha Freire	mateeus__mateeus@hotmail.com	Cunhão	@		d96368c60e9e21be2298bed9d0e770ba	f	\N	2011-11-23 09:29:29.243586	1	1994-01-01	\N	f	mateeus__mateeus@hotmail.com	t
1548	Cleiciana de Sousa Santos	cleicianadesousa@gmail.com	princesa	@		8c38cae33f0053692e40766fa85b7643	f	\N	2011-11-22 17:26:24.694169	2	1994-01-01	\N	f	cleicidesousa@hotmail.com	t
2221	José Elder Cosme da Silva	eldercosme@gmail.com	Welder	@		d63d3da5bbf52113366a254b6d7adaab	f	\N	2011-11-23 22:28:39.459564	1	1992-01-01	\N	f		t
1504	Gina Morais de Menezes	moraisginamenezes@gmail.com	gininha	@		25f9e794323b453885f5181f1b624d0b	t	2011-11-22 17:33:49.761248	2011-11-22 17:07:19.072248	2	1995-01-01	\N	f		t
1547	MARIA IRISMAR NASCIMENTO DE QUEIROZ	irisdequeiroz@hotmail.com	IRIS de queiroz	@		e63cc5fa9e7da391465744694bbc9b28	t	2011-11-22 17:29:17.70358	2011-11-22 17:26:13.147725	2	1973-01-01	\N	f		t
1657	renata ferro	arenatalua@hotmail.com	Renata	@		c485d8a78ee147f40fa7ea8185eb632e	f	\N	2011-11-22 21:29:42.428306	2	1988-01-01	\N	f		t
1565	Aurineide Calixto	elassaodes@hotmail.com	Aurinnha	@		0a866d552de84562f2d6e2b490cd7791	f	\N	2011-11-22 17:34:32.610534	2	1977-01-01	\N	f		t
1566	Pedro Igor	pedroigor91@gmail.com	pedroigor91	@pedroigor91		1d857ddacb50033e64f32c614e123e64	t	2011-11-22 17:35:46.900512	2011-11-22 17:34:48.308814	1	1991-01-01	\N	f	pedroigor91@gmail.com	t
1663	Maryana Almeida	maryana.almeida42@gmail.com	Maryana'	@		1d105ebe980916147303ce643fec2042	f	\N	2011-11-22 21:38:46.256348	2	1998-01-01	\N	f		t
1568	Eudásio Alves	bancopaju@hotmail.com	Eudasio	@		c5141f9b53bde66fd317df2e67d57a08	f	\N	2011-11-22 17:35:38.426116	1	1977-01-01	\N	f		t
1933	adaiane de morais ferreira	adaianefeliz@hotmail.com	daiiia	@		1eac3c951bbed143a035a563c014e25f	f	\N	2011-11-23 14:47:49.453196	2	1995-01-01	\N	f	adaianefeliz@hotmail.com	t
2551	Iara Torres	iara.torres.castro@gmail.com	Iara Torres	@		85a906093149026dce357cab38b8980a	f	\N	2011-11-25 09:44:46.972735	2	1993-01-01	\N	f		t
1684	Carlos Eduardo Sousa Silveira	carlos.eduardo.ss@live.com	Eduardo	@		7f714b8bc052a6324f26608999b59c41	t	2011-11-22 22:04:48.24088	2011-11-22 22:03:22.356131	1	1992-01-01	\N	f	c.eduardo_linkinpark@hotmail.com	t
1733	Victor Hugo Soares da Silva	victor.hugo.infor@gmail.com	Victor	@		cc790dcb802630b141cf6f7d0f0c44a6	f	\N	2011-11-23 09:26:44.348426	1	1994-01-01	\N	f	victor.hugo.infor@gmail.com	t
1688	gutemberg magalhães souza	gmsflp10@hotmail.com	gutinho	@		5cc30a1ffb30b925beae93225e3c8348	f	\N	2011-11-22 22:20:13.567352	1	1982-01-01	\N	f	gmsflp10@hotmail.com	t
1691	Elexandre	elexandre_d2@hotmail.com	Noob Saibot	@		f2e9b77e29a9a14e691a5b0db0c0e545	t	2011-11-22 22:37:10.871279	2011-11-22 22:35:49.969523	1	1994-01-01	\N	f		t
1943	carlos eduardo de sousa lopes	muiknonopo@hotmail.com	kaduuuu	@		fe986da3080dcec5876b453d45ededcb	f	\N	2011-11-23 14:51:14.917711	1	1994-01-01	\N	f		t
2256	Herson Borges Araújo	hersonaraujo@gmal.com	Herson	@		07270482c9a71f5730090f32f7b45de4	f	\N	2011-11-24 09:31:56.894934	1	1994-01-01	\N	f		t
1796	Thalisson	daniel.ciges@gmail.com	Thalisson	@		b6bfb5cfc606eadf20e0b78a2d7a0b17	f	\N	2011-11-23 10:26:27.983766	1	1994-01-01	\N	f	daniel.siges@gmail.com	t
1801	Francisco Eudes de Sousa Júnior	juniorsousa_343@hotmail.com	juniin	@Jr_sousa95		efd2552b38bdbd11e95d3982442fc289	f	\N	2011-11-23 10:29:09.66168	1	1995-01-01	\N	f	juniorsousa_343@hotmail.com	t
1810	Lucas Holanda Feitosa	luks206@gmail.com	Lucas Holanda	@		8e70900e3ee240d666ec16e2f800e5ba	f	\N	2011-11-23 10:31:15.427392	1	1996-01-01	\N	f		t
2577	Wesley rodrigues de castro	wesley.castrowesley@gmail.com	wesley	@		bb655d17a914bf4b13634ce48a324887	f	\N	2011-11-25 14:16:28.422785	1	1999-01-01	\N	f		t
1953	Davi Távora Herculino	brenobarroso12@gmail.com	Davi .I.	@		71a4e8af83e63be46df7f855d9861358	f	\N	2011-11-23 14:54:39.779299	1	1996-01-01	\N	f		t
2156	Fabiana Sousa do Nascimento	fabianapink2010@hotmail.com	Fabý Garraway	@		c166eda9a827dc7ddaf29f68b76c2f54	f	\N	2011-11-23 18:40:54.815059	2	2009-01-01	\N	f		t
2239	Kerliane Cavalcante Pereira	kerlianecavalcante15@hotmail.com	Kerliane	@Kerliane		919f15acdb924f0a2ea1347d699b7600	f	\N	2011-11-24 01:00:33.942468	2	1991-01-01	\N	f	kerlianecavalcante15@hotmail.com	t
2284	Anderson Gomes Andrade	andersongomes660@hotmail.com	Anderson	@		474330852154523cb8c7238ada16eba4	f	\N	2011-11-24 10:13:55.42899	1	1994-01-01	\N	f		t
2598	Felipe da Silva Nascimento	bboylipe04@gmail.com	felipe	@		59aa0ee14c848363d960e5d81b4fdf34	f	\N	2011-11-25 16:39:27.831036	1	1992-01-01	\N	f		t
1571	karolaine matos de moraes	x.k.r.karol@email.com	karolzinha	@		00bbf9f6b61c01da0088e46dff7443ed	f	\N	2011-11-22 17:37:31.140852	2	1994-01-01	\N	f	x.k.r.karol@email.com	t
3592	WILKIA MAYARA DA SILVA NEVES	ifce.maraca27@ifce.edu.br	WILKIA MAY	\N	\N	ef4e3b775c934dada217712d76f3d51f	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
631	ADRYSSON DE LIMA GARÇA	adrysson_rrr@hotmail.com	Adrysson	@adrysson_a7x		d0b2ceedce43aa9118d75c3dd486bb26	t	2012-01-12 08:44:42.742274	2011-11-08 18:53:20.945709	1	1992-01-01	\N	f	adrysson_rrr@hotmail.com	t
1573	Deda Cestas	rafajanulima@hotmail.com	Cestass	@		a34ca6afa73f4fa7330b1e8d4d698809	f	\N	2011-11-22 17:38:56.991634	2	1975-01-01	\N	f		t
1604	Flaviano	eunice78@gmail.com	B-boy  Pócho	@		c29f099c44ff20e000f155998463be17	f	\N	2011-11-22 19:11:59.245504	1	1989-01-01	\N	f		t
1574	Ivoneide Albuquerque	neidebonequeira@hotmail.com	Boneca	@		b44cb4e88768172389f1889217e2eaff	f	\N	2011-11-22 17:40:17.83114	2	1970-01-01	\N	f		t
1624	eliana alves costa	eliana_alves95@hotmail.com	taja preta	@eliana23alves		00681e229f96d7daa01ca81411155537	t	2011-11-22 21:26:16.011474	2011-11-22 20:31:04.201392	2	1995-01-01	\N	f	eliana_alves95@hotmai.com	t
1050	francisco andre de sousa gois	andresousalee@gmail.com	sousax3	@		5b715cedd4f5353e0c4d753607ef6731	t	2011-11-22 20:12:22.62112	2011-11-19 12:42:51.581745	1	1989-01-01	\N	f	andresousalee@gmail.com	t
1578	Luiz Rafael	Fael.bboy2@hotmail.com	Fael b boy	@		ee85710743169a902666ce9d8e8b9003	f	\N	2011-11-22 17:50:29.349685	1	1992-01-01	\N	f		t
1579	Jardel Rodrigues	jardel.ifce@gmail.com	Jardel	@		1141d097fce490af9bf7fb58c7b7f16c	t	2011-11-22 18:16:18.374105	2011-11-22 17:51:24.213959	1	2011-01-01	\N	f		t
1727	sabrina de souza nascimento	binna_bc@hotmail.com	sabrina souza	@		141b02804cc6cc43e3ee1e4ad36e6e3b	f	\N	2011-11-23 09:11:16.455158	2	1992-01-01	\N	f	binna_bc@hotmail.com	t
1639	Márcio Davi Dutra	marciodavi2009@gmail.com	Márcio	@marcio_davii		18cac6526befe0d81abc1a6a7a2d4906	f	\N	2011-11-22 20:50:09.835564	1	1993-01-01	\N	f	marciodavi2009@gmail.com	t
1582	Liluo 	bboyzero9@gmail.com	B-BOY GUINHO	@		f455abe7a4889adbd528116df6f03b09	f	\N	2011-11-22 17:53:31.232559	1	1993-01-01	\N	f		t
1651	Francisco Marciano Rufino	francisko.mr.rfn@gmail.com	Marciano	@		5407b6d7e27091d92555f60bff8ce289	t	2011-11-22 21:15:11.456331	2011-11-22 21:13:30.004656	1	1991-01-01	\N	f	francisko.mr.rfn@gmail.com	t
1583	Maria Rafaela Pereira Januario	rafajanulima@gmail.com	Rafinha	@		2bebc68e425776cc1c681aef04c50885	f	\N	2011-11-22 17:54:15.492578	2	1982-01-01	\N	f		t
1584	FRANCISCA NADJA CAMPOS DE MELO	dinha_nady@hotmail.com	Nadja Melo	@nadjacampos		e04504d2cd002933edee1070f8bcbdf6	f	\N	2011-11-22 17:59:14.363162	2	1989-01-01	\N	f	dinha_nady@hotmail.com	t
1585	francisco daniel bezerra de carvalho	brodcearmusic2@gmail.com	niel da brenda	@		f76d6e2c786fe80cbf0f872b59a0e732	t	2012-01-15 20:33:55.001701	2011-11-22 18:00:39.400064	1	1989-01-01	\N	f		t
1658	Francisco leandro bezerra leite	leandro_cp16@hotmail.com	bolinha	@		98ba5150709f5d78212cd07d234cfb98	t	2011-11-22 21:38:56.654584	2011-11-22 21:30:59.509909	1	1995-01-01	\N	f	leandro_c16@hotmail.com	t
1586	Claudenir Mano	manopiloto@hotail.com	Mano Piloto	@		d18e69c986e49558d306de1e48cbd2b5	f	\N	2011-11-22 18:05:06.311601	1	1994-01-01	\N	f		t
1944	Bárbara Oliveira Medeiro	barbara_agat@hotmail.com	Bárbara	@		ab0b834a35e6c350a0d28ba19e88a66d	f	\N	2011-11-23 14:52:01.472276	2	1996-01-01	\N	f	barbara_agat@hotmail.com	t
1587	FELIPE	irisdequeiroz@gmail.com	B-BOY LIPE	@		4b90b8843217d84dfa1d029b1d134566	f	\N	2011-11-22 18:08:32.517528	1	1992-01-01	\N	f		t
2257	Willys Nakamura	willysteatro@gmail.com	Nakamura	@willysteatro		a61321e62cc62c45b3a4d49f228e84ce	f	\N	2011-11-24 09:33:01.659179	1	2011-01-01	\N	f		t
1588	Endel b boy	iriseducadora@hotmail.com	skiloo	@		161259a1661147fb60216cfd71b03705	f	\N	2011-11-22 18:15:50.876849	1	1998-01-01	\N	f		t
1776	Júlio Cézar Barros Maciel	julio-rx8@hotmail.com	Júlio	@		6e48cc4e3f9f95566b1bc4ee61aeaf97	f	\N	2011-11-23 10:09:13.729131	1	1996-01-01	\N	f		t
1664	Germana Cassia Mateus Cunha	germanacassia@hotmail.com	germana	@		dc75faa80dd55063fa2c90461efa8f2c	t	2011-11-22 21:45:08.573192	2011-11-22 21:40:15.782497	2	1993-01-01	\N	f	germanacassia@hotmail.com	t
1954	Fernanda da Silva Barbosa	nanda_2010_15@hotmail.com	Fernanda	@		800c77bd55f90b51e688b7dbf832d282	f	\N	2011-11-23 14:55:28.737253	2	1996-01-01	\N	f	nanda_2010_15@hotmail.com	t
1644	carlos magno vieira de sousa	carlosmagno60@hotmail.com	romario	@		2f3c3ca333e8382571133c461f7f46d3	t	2011-11-22 21:44:26.317802	2011-11-22 20:58:24.292633	1	1994-01-01	\N	f	carlosmagno60@hotmail.com	t
2157	Francisca Geissiane da Silva Barbosa	geiseflaatemorrer@hotmail.com	Geisse	@		412a37a54235e67c67339b18aa7b06ca	f	\N	2011-11-23 18:42:58.5048	2	2009-01-01	\N	f		t
1685	maryana almeida	atimafernades59@yahoo.com	maryana	@		25efb554f9b4ef9eb24426f9448d5f9b	f	\N	2011-11-22 22:04:50.909608	2	1998-01-01	\N	f		t
1791	Nailton José	nailton@yahoo.com	pé de pano	@		b3a2386bb2462df94e9c7b517e25fe7e	f	\N	2011-11-23 10:22:32.924858	1	1995-01-01	\N	f		t
1962	Raimundo	ariberto_filho@hotmail.com	Ariberto	@		d958044b263527335a2382ed1774faba	f	\N	2011-11-23 14:56:52.53551	1	1995-01-01	\N	f	ariberto_filho@hotmail.com	t
2552	Francisca Edilma Monteiro Pinto	edilma_monteiro@yahoo.com	Edilma	@		fa61b825cfc14e136e8c1d421b299f0a	f	\N	2011-11-25 09:45:27.283623	2	1976-01-01	\N	f		t
1802	Jose Werbeny Lucio Da Silva	werbenylucio@yahoo.com.br	lucioc	@		570ee6e886486b40d67b6051b78fb214	f	\N	2011-11-23 10:29:39.325361	1	1973-01-01	\N	f		t
1978	Francisco Tiago Sousa Alves	tiago_alves3@hotmail.com	Tiago Alves	@		ac0964a34fe693a73bc32bb877f437cb	f	\N	2011-11-23 15:04:09.3549	1	2011-01-01	\N	f		t
1781	Hailton Harriman da Silva	hailtonpaulista@gmail.com	paulista	@		2a4295f5c9fc1d675ba1d865acceea02	f	\N	2011-11-23 10:14:15.48932	1	1980-01-01	\N	f		t
1811	Samuel Azevedo de Abreu	samuelabreu1@hotmail.com	Samuel	@		97afa6c1cc95b330e0b823b39432c369	f	\N	2011-11-23 10:33:17.721327	1	1996-01-01	\N	f		t
1821	Fernando Lopes	fernandolopes78@hotmail.com	Fernando	@		67c2e51eb131382ac403ff676a5a2fe5	f	\N	2011-11-23 10:37:11.03588	1	1994-01-01	\N	f		t
2578	alberto vidal rocha	ppopmaster@gmail.com	alberto	@		a38e4f649fa90f36b6002085f963daf7	f	\N	2011-11-25 14:18:57.072426	1	1988-01-01	\N	f		t
1986	antonia cleitiane holanda pinheiro	cleitypinheiro_yonderfulgire@hotmail.com	cleite	@		610e01c738f01fa17da8a6aca70df6ed	f	\N	2011-11-23 15:07:18.357356	1	1994-01-01	\N	f		t
2167	JOAO BATISTA DE MARIA	joaobejovem@gmail.com	JOAOB1992	@		82969739aa8e8175c4783d22a1dacbc6	f	\N	2011-11-23 19:11:26.347895	1	1992-01-01	\N	f		t
1992	Carlos Eduardo Sousa Lopes	cadu1235@hotmail.com	carlos	@		8f623e1353de4082e8927daeb0f9dd23	f	\N	2011-11-23 15:10:05.474259	1	2011-01-01	\N	f		t
2177	Sergio Murilo Costa Ribeiro	sergio_murilocr@hotmail.com	Murilo	@		7bb2697f47e8872e8dbe1bf8a71a028d	f	\N	2011-11-23 19:38:58.680715	1	1992-01-01	\N	f	darkpasionplay@hotmail.com	t
1754	Jeferson felicio	jeferson.touru@hotmail.com	jefimwona	@		409ee12c30655aac08fae61e760fa039	f	\N	2011-11-23 09:31:27.453259	1	1994-01-01	\N	f	jeferson.touru@hotmail.com	t
2188	Antonio Wesley Araujo dos Santos	antonio.wesley85@hotmail.com	Werling	@		04d3672031f79e8ae8117b8d26b9e853	f	\N	2011-11-23 20:06:38.389152	1	1996-01-01	\N	f	antonio.wesleey85@hotmail.com	t
2240	Erika silva moreira	erika.silvamoreira6@gmail.com	erikinha	@		bd0a2133aa64ee3032e50d2923fbb36b	f	\N	2011-11-24 01:15:47.679886	2	1991-01-01	\N	f	akirafenix38@hotmail.com	t
2646	Roberto Vitor Maia Alencar	roberto_vitor.maia@hotmail.com	roberto	@		5e9e641eed025c1e9a7b214be841e860	f	\N	2011-11-26 12:42:37.073924	1	1993-01-01	\N	f		t
1692	Felipe Gonçalves De Oliveira 	felipe_lipe118@live.com	Felipe	@		a96b55b2c992234da95b706f911c2882	t	2011-11-22 22:44:49.54953	2011-11-22 22:43:19.968256	1	1993-01-01	\N	f	felipe_lipe118@live.com	t
1705	Joelma Roque 	jeicydeusfiel2010@hotmail.com	Joelma	@		ee1cb72f6ad6fbf438bcde3745aa91e8	f	\N	2011-11-22 23:54:30.044585	2	1987-01-01	\N	f	joelmasantiago20@hotmail.com	t
1086	ALCILIANO DA SILVA LIMA	alci987@hotmail.com	Alci Silva	@alci987		fc673b8de91f7b132b3574429e8415c8	t	2012-01-10 18:25:42.408704	2011-11-20 18:52:20.716429	1	1984-01-01	\N	f	alci987@hotmail.com	t
1693	cicera maria diamante martins	cicera_diamante@hotmail.com	pequena	@		8058f9a631fc8a993850639b9e053692	t	2011-11-22 23:12:02.842854	2011-11-22 22:59:54.292844	2	1995-01-01	\N	f		t
1923	Pedro Isidio Menezes da Fonseca	pedroisidio1@hotmail.com	pedroisidio51	@51pedroisidio		75c08173c377cac3dad0ef2777039b6c	f	\N	2011-11-23 14:40:10.504681	1	1994-01-01	\N	f	pedroisidio1@hotmail.com	t
3566	ADNISE NATALIA MOURA DOS REIS	ifce.maraca1@ifce.edu.br	ADNISE NAT	\N	\N	598b3e71ec378bd83e0a727608b5db01	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
1694	Felipe Gerson Araújo	felipegerson-bc@hotmail.com	Felipe	@		d71ce2c2c77fb701b57c51a52335c830	t	2011-11-22 23:11:05.513266	2011-11-22 23:01:09.594887	1	1993-01-01	\N	f	f_gerson_a@hotmail.com	t
1728	Jefferson do Nascimento de Andrade	jefferson_info@yahoo.com.br	Jefferson Andrade	@		c7f96afaa6a1d7ef016f75690d5ebe0c	f	\N	2011-11-23 09:21:58.354479	1	1995-01-01	\N	f		t
1861	André Luiz dos Santos Dutra	andre_teat@hotmail.com	Andre2	@		3c27fa1727fb7368b18a517432fbdc57	f	\N	2011-11-23 11:23:54.852561	1	1991-01-01	\N	f	andre_teat@hotmail.com	t
1448	Anderson Menezes Duarte	andersonmenezes@hotmail.com.br	Anderson	@		23a31aee3b193b715250ce0701b4baed	t	2011-11-22 23:09:48.590865	2011-11-22 16:49:37.081128	1	1995-01-01	\N	f		t
3567	ANA KATARINA TOMAZ HACHEM	ifce.maraca2@ifce.edu.br	ANA KATARI	\N	\N	ca75910166da03ff9d4655a0338e6b09	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
3568	ANTONIO JULIAM DA SILVA	ifce.maraca3@ifce.edu.br	ANTONIO JU	\N	\N	3c59dc048e8850243be8079a5c74d079	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
2463	keyla de souza costa	keyla.seliga@gmail.com	keyla.	@		2a0026ac68e4c9a8723b8f2444ce65c1	f	\N	2011-11-24 16:49:25.337102	2	1992-01-01	\N	f		t
1742	ADRIANA MARA DE ALMEIDA DE SOUZA	adrianayhrar@gmail.com	adriana	@		0defbc285776190c18d8a9ef72810b8b	f	\N	2011-11-23 09:29:39.375324	2	1991-01-01	\N	f	adrianayhrar@hotmail.com	t
1756	LAKILSON BARROSO E SILVA 	lakilson@yahoo.com.br	LAKILSON	@		daf70b6cd326251503a73f3a639580e4	f	\N	2011-11-23 09:31:59.405008	1	1981-01-01	\N	f	lakilson@yahoo.com.br	t
1777	Aliane Nascimento	nascimento.aliane@gmail.com	Lianaa	@		9fd2bc7e94767531f0200aeee408cac8	f	\N	2011-11-23 10:13:14.546483	2	2011-01-01	\N	f	nascimento.aliane@gmail.com	t
2127	vitor mateus felix ribeiro	vitoor.mateus@hotmail.com	mateusinho	@		b812ba1dad5722f03980ad845a746f82	f	\N	2011-11-23 18:02:10.024237	1	1996-01-01	\N	f		t
2223	Eliézio Paula 	Eliezio.Paula@gmail.com	Eliezio	@		e86c71b96578351c59679cb7dc8db2d7	f	\N	2011-11-23 22:47:42.199216	1	1989-01-01	\N	f		t
1792	JULIA SILVA DOS SANTOS	juliasilva_morena@hotmail.com	julinha	@		c9ecc4f6cc3cbca65dd4bf577e5c938f	f	\N	2011-11-23 10:22:42.943524	2	1994-01-01	\N	f	juliasilva_morena@hotmail.com	t
1963	Daniel vasconcelos	danieldasilva_2008@hotmail.com	Dielzinho	@		62b8288c2867583bbbfc172290439710	f	\N	2011-11-23 14:57:01.444649	1	1993-01-01	\N	f		t
2304	Alexandre Nogueira da Silva Júnior	axle-the-shadow@hotmail.com	Alexandre Nogueira	@		fc804c86be264e91a4f6e3ffaae31bdd	f	\N	2011-11-24 10:38:05.647881	1	2011-01-01	\N	f		t
1803	Ana Ellen do Nascimento Santos	anaellen13@yahoo.com.br	Ana Ellen	@		65c919a8ce53b448a32311ad9301d65f	f	\N	2011-11-23 10:29:42.154135	2	1996-01-01	\N	f		t
2158	Francisco Jorge Costa Alcântara	jorgecamaline@gmail.com	Jorgito	@		5f5f63b73c01f9de45e2c80351947834	f	\N	2011-11-23 18:44:20.983556	1	2009-01-01	\N	f		t
1812	lessandra fernandes	lessandrafe@hotmail.com	lessandra	@		2f0954a3787f6d2347fd7d9e0e9da83f	f	\N	2011-11-23 10:33:47.572727	2	1993-01-01	\N	f	lessandra_cearamor@hotmai.com	t
1817	lessandra fernandes	lessandrafe@gmail.com	lessandra	@		ea6147db4d693a147981565da7fc05cc	f	\N	2011-11-23 10:36:31.280091	2	1993-01-01	\N	f	lessandra_cearamor@hotmai.com	t
1979	lucas deyvidson irene costa	lucas.deyvid@hotmail.com	lucas deyvid	@		ed9945ec81543404af635b50668e9d82	f	\N	2011-11-23 15:04:58.366449	1	1996-01-01	\N	f		t
2168	Carlos Eduardo de Sousa Lopes	cadu_gmc@hotmail.com	Eduardo	@		81bd7b7b6a29fe0745732ab8d3b37b7a	f	\N	2011-11-23 19:12:51.194762	1	1994-01-01	\N	f		t
1993	Jhon Maycon Silva Previtera	jhon.previtera@gmail.com	Jhon Maycon	@		beab34e50308d649b1216c61c37577bf	f	\N	2011-11-23 15:11:28.628109	1	1992-01-01	\N	f		t
2241	Danrley Moura	danrluca@hotmail.com	Danwwwww	@		42c89a479369cd413cb3da8484768ae2	f	\N	2011-11-24 01:52:14.450929	1	2011-01-01	\N	f		t
1845	Alexsandro Kauê Carvalho Galdino	carvalho.3331@gmail.com	akcg20	@		39102b12cc439b87f18923a466994206	f	\N	2011-11-23 10:56:02.803452	1	1991-01-01	\N	f		t
2189	Verner Ivo	verner_tuf@hotmail.com	Cachinhos	@		5dab75e454c1b40fd798dea57bba6082	f	\N	2011-11-23 20:08:31.333864	1	1998-01-01	\N	f		t
2313	Jeniffer Lima	jenniferinf1@hotmail.com	Jeniffer	@		fc28b47808d0626726f9552851c89d3b	f	\N	2011-11-24 10:43:12.329037	2	1997-01-01	\N	f		t
2006	Ermivan Mendes Moura	ermivan.mendes@hotmail.com	Ermivan	@ermivan_mendes	http://ermivanmendes.blogspot.com/	85a337b7f38926529f7ee095f4d889c2	f	\N	2011-11-23 15:19:21.041368	1	1991-01-01	\N	f	ermivan.mendes@hotmail.com	t
1860	José Francisco Gomes Costa	josecosta95@hotmail.com	Zechico	@josecosta95		cd83dc6997346b5c9f44266757fae7ab	f	\N	2011-11-23 11:09:25.424972	1	1995-01-01	\N	f	josecosta95@hotmail.com	t
2010	Jean Carlos Monteiro Guimarães	jeanjcmg@gmail.com	Jean Carlos	@		bb1e3fad5a413bdece3aadcb42d56a17	f	\N	2011-11-23 15:23:57.577371	1	2011-01-01	\N	f		t
2198	Betiane Azevedo	babetianeazevedo63@gmail.com	Babetiane	@		9a52907ca93f613676e02c3f2c4f701b	f	\N	2011-11-23 20:30:07.973514	2	1995-01-01	\N	f		t
2258	Wellington Gomes Freitas	wellfreitas2001@yahoo.com.br	Wellington	@		db3ac876943d93b9bd9196f1e64ff8cf	f	\N	2011-11-24 09:55:00.899576	1	2011-01-01	\N	f		t
2321	Miguel Ferreira Lima Filho	miguel.ferreira32@gmail.com	Miguel	@		b6d2a4976bca8ea6c271d30d81301e53	f	\N	2011-11-24 10:46:21.68807	1	1995-01-01	\N	f		t
2553	Terezinha de Sousa Costa	tz.sousa@yahoo.com	Terezinha	@		971a8327075fd684ebc0125aabe87df9	f	\N	2011-11-25 09:46:43.509648	2	1966-01-01	\N	f		t
2296	liane coe	lianecartaxo@gmail.com	lianecoe	@		e3fff32611d8dd7e7942aafaa90c9efc	f	\N	2011-11-24 10:22:54.487449	2	1982-01-01	\N	f		t
2328	fabiano wesley da silva marcos	fabiano.wesley65@hotmail.com	fabiano	@		e314fbe0b1a7803378de28bc9d247697	f	\N	2011-11-24 10:50:00.078696	1	1996-01-01	\N	f		t
2334	Daniel Felipe Nogueira Menezes	daniel.fel@hotmail.com	Daniel	@		948ac36fd3909a9d51d7553157e0c70c	f	\N	2011-11-24 11:05:26.566133	1	2011-01-01	\N	f		t
2579	Ezequiel Gomes Correia	ezequiel-chemistry@hotmail.com	Ezequiel	@		2bc972e94f70be11e53c8eb474c43703	f	\N	2011-11-25 14:21:41.494836	1	1990-01-01	\N	f		t
2647	Samael Lucas de Sousa Mendes	samaellucas@hotmail.com	Samael	@		9c7f640c816e3a71898f2f62f770a936	f	\N	2011-11-26 13:26:33.889628	1	1997-01-01	\N	f		t
2599	francisco wendel soarez da silva	ntememail@hotmail.com	esquilo	@		fbbd49ffb09678787ad71dad456b6dfe	f	\N	2011-11-25 16:41:54.702271	1	1999-01-01	\N	f		t
2666	Vladislave de Almeida Pereira	vladexalmeida@yahoo.com.br	vladslave	@		b115c403f11df7ae6e6562f8d2a98b68	f	\N	2011-11-26 15:08:21.689815	1	1974-01-01	\N	f		t
1695	Ana Jessica Pinto Vasconcelos	jessica_v.bc@hotmail.com	Jessica	@		bae60636b276c28b3ff12925521aaf51	t	2011-11-22 23:38:20.265035	2011-11-22 23:13:53.075953	2	1992-01-01	\N	f		t
1706	Rafael Alexandrino Araujo de Lima	alexandrino628@hotmail.com	Rafael_Alex	@		cfcbedefbdc146e07c235b206bb28698	f	\N	2011-11-23 00:00:58.649783	1	1992-01-01	\N	f		t
1696	Hericson Régis	hericsonregis@hotmail.com	Hattie	@SonyRegis		0e835cd02ec835b49b881e7e70801d03	f	\N	2011-11-22 23:14:31.440356	1	1994-01-01	\N	f	hericsonregis@hotmail.com	t
1843	Diego Siqueira Magalhães	diego.siqueira1994@hotmail.com	dieguinho	@		1216b93468f2e6c0f750ce5ff05ff453	f	\N	2011-11-23 10:54:08.992643	1	1994-01-01	\N	f		t
3569	ANTONIO MARCIO RIBEIRO DA SILVA	ifce.maraca4@ifce.edu.br	ANTONIO MA	\N	\N	eb163727917cbba1eea208541a643e74	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
1697	Jessica Loyola	jeh_loy@hotmail.com	jehloy	@jeh_loyola		c18a83b96eec557664421f5eac73d454	t	2011-11-22 23:19:36.486651	2011-11-22 23:15:55.587523	2	2011-01-01	\N	f	jeh_loy@hotmail.com	t
3570	ARILSON MENDONÇA DO NASCIMENTO	ifce.maraca5@ifce.edu.br	ARILSON ME	\N	\N	7fe1f8abaad094e0b5cb1b01d712f708	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
1729	Lucas Alves Angelo	lukecoldy@hotmail.com	Luke Coldy	@lukecoldy		94033c512177eaa42a839edf6d0be203	f	\N	2011-11-23 09:22:11.221716	1	1996-01-01	\N	f	lukecoldy@hotmail.com	t
3571	CATARINA GOMES DA SILVA	ifce.maraca6@ifce.edu.br	CATARINA G	\N	\N	c3992e9a68c5ae12bd18488bc579b30d	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
1698	antonio jeferson pereira barreto	jefersonpbarreto@yahoo.com.br	Russo 	@		dfc221ce38ef7bb40e6bcfd9678330b3	t	2011-11-22 23:39:19.872543	2011-11-22 23:28:11.921403	1	1990-01-01	\N	f	russo.xxx@hotmail.com	t
1924	Charles Luis Castro	charles_139@hotmail.com	charles timão	@		a6012c5034cd7a69026723fcee84d3e4	f	\N	2011-11-23 14:40:13.987459	1	1994-01-01	\N	f	charles_139@hotmail.com	t
2199	winston bruno	winstonbruno@gmail.com	winston bruno	@		1862990a5aaab5bf6f50f9f85205e534	f	\N	2011-11-23 20:35:18.034381	1	2011-01-01	\N	f		t
3572	DIEGO SOARES DA SILVA	ifce.maraca7@ifce.edu.br	DIEGO SOAR	\N	\N	202cb962ac59075b964b07152d234b70	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
1757	pedro henrique de macedo sobrinho	ph-pedro-henri@hotmail.com	pedrinho	@phenrique_21		8ca6a4065fc22b582a89fe1db58e9777	f	\N	2011-11-23 09:33:01.454877	1	1994-01-01	\N	f		t
1769	João Paulo Barbosa Amorim Leitão	jpjoaopaulo1995@hotmail.com	João Paulo	@JP_JoaoPaulo_JP		175865a38a0f269cfa6fcf1691e37c79	f	\N	2011-11-23 09:37:19.84899	1	1995-01-01	\N	f	jpjoaopaulo1995@hotmail.com	t
2145	Giovanna Félix Sousa Silva	giovanna-lovy@hotmail.com	Giovanna	@		0f0404484164a61295665aa96280d5d4	f	\N	2011-11-23 18:27:36.946319	2	2009-01-01	\N	f		t
1786	Iara Costa Machado	sjesusemeuguia@hotmail.com	Iarinha	@		5102e07a5401636a3cf6f0629b78227d	f	\N	2011-11-23 10:17:51.971651	2	1995-01-01	\N	f		t
1964	Luziana Pereira Rodrigues	luziananix@hotmail.com	Luziana	@		a7166a966fde76763e7dae3f2243ef3b	f	\N	2011-11-23 15:00:41.335294	2	2011-01-01	\N	f		t
1799	Alex Bruno Torres Martins	krshinigami@gmail.com	Alex Bruno	@		feb0858759893a260e3f8b391232cd35	f	\N	2011-11-23 10:27:37.329682	1	1996-01-01	\N	f		t
1804	Alexandre Cavalcante de Almeida	alecavalcantealmeida08091984@gmail.com	alexandre	@		c76da4b30f97d24ae2c968a6457b1eae	f	\N	2011-11-23 10:29:46.077273	1	1984-01-01	\N	f		t
2159	Gabriel de Lima Oliveira	gabrielcamocim512@hotmail.com	Garra 05	@		e63105956f6253736875a119deea2389	f	\N	2011-11-23 18:46:41.951934	1	2009-01-01	\N	f		t
1808	maria vania	vaniape1979@gmail.com	vania m	@		300893c1b6d3dad7953c33b2c7ec9591	f	\N	2011-11-23 10:30:48.985032	2	1979-01-01	\N	f		t
2224	Orlando Cláudio Anchieta de Queiroz	orlandoanchieta@hotmail.com	Orlando	@		d007f48ca31ee95d3a4b65ec2538e356	f	\N	2011-11-23 23:06:10.794029	1	1992-01-01	\N	f	orlandoanchieta@hotmail.com	t
1813	Taylan Vieira da Silva	taylan11t@hotmail.com	Taylan	@		f126df50cf70bbe9d33de5b498310ac8	f	\N	2011-11-23 10:35:13.257286	1	1996-01-01	\N	f		t
2169	jose lucas lima fernandes	k-leu_joselucas@hotmail.com	joselucas	@IVPCjoselucas		18fd2a53d69f7e5368a5e6bfd7097c58	f	\N	2011-11-23 19:14:33.987533	1	1996-01-01	\N	f		t
2003	tiago alexandre francisco de queiroz	tiago.queiroz_2009@hotmail.com	tiago.	@		6284eee8e015918bfd6cffcc8cd4fbf4	f	\N	2011-11-23 15:17:14.476652	1	1995-01-01	\N	f		t
1831	Edilson Marques Teixeira	edilson3004@hotmail.com	Edilson	@		766d55ef5c1ad27fca2853a8697d3475	f	\N	2011-11-23 10:40:44.296536	1	1982-01-01	\N	f		t
2287	washinton moraes felix	wml_roque@hotmail.com	washington	@		9f56dceff4c044a3276f9195476773c5	f	\N	2011-11-24 10:14:28.88783	1	1995-01-01	\N	f		t
1735	Rosiane Roque da Silva	rosianeinfo@yahoo.com.br	Rosiane	@		fecca3ab602a5568eaa51b76feab3163	f	\N	2011-11-23 09:26:47.715488	2	1995-01-01	\N	f	rosianeroque@live.com	t
2179	ROSIANE FERREIRA FREITAS	rosianefreitas@ymail.com	mariliamoraes	@		4d89e3454c26fc2c7ceadbe754ca40ad	f	\N	2011-11-23 19:41:30.506366	2	1985-01-01	\N	f		t
2016	Simone Oliveira	simoma2011@hotmail.com	Simone	@		810c30fe48d67783db8eaab7d0711e38	f	\N	2011-11-23 15:28:34.433332	2	1995-01-01	\N	f		t
2023	Antonia Morgana Medeiros Mesquita	morganamedeiros100@gmail.com	morgas	@		85939e59fb576eb75c6d058f7cf13481	f	\N	2011-11-23 15:31:08.620039	2	1995-01-01	\N	f	morgana.medeiros3@facebook.com	t
1736	Elisângela do Nascimento Xavier da Silva	eli_zan95@hotmail.com	ELI_ZAN	@elisngela31		e28e9b2242e579f40bc78d08628c7297	f	\N	2011-11-23 09:27:04.735763	2	1995-01-01	\N	f	eli_zan95@hotmail.com	t
1842	Diego Siqueira Magalhaes	diego_sq94@hotmail.com	dieguinho	@		528b45ccf7ecb114482f87d820c601cd	f	\N	2011-11-23 10:53:27.734751	1	1994-01-01	\N	f		t
2028	Antonio Leonardo Freitas dos santos 	leo2011nardo@gmail.com	leonardo	@		12bf017c5b293422e6c90685ec9a0f9b	f	\N	2011-11-23 15:39:48.26179	1	1993-01-01	\N	f	leo2011nardo@gmail.com	t
2190	Francisco Renato Lessa de Oliveira	renato.lessa31@gmail.com	Renatinho	@		89e6d728f4afb9ef0c03ee97db4caebf	f	\N	2011-11-23 20:11:40.260658	1	2011-01-01	\N	f		t
2242	André Teixeira De Queiroz	andre.teixera@gmail.com	ñ tenho	@		50bb616d6c69ef116ac7484596215413	f	\N	2011-11-24 02:52:02.706473	1	1993-01-01	\N	f	andre.teixera@hotmail.com	t
2554	João Yago 	yago.alves.moura@hotmail.com	Yago Alves Moura	@		1dee3d16b521d9432a446aaa033eaa5c	f	\N	2011-11-25 09:49:54.882562	1	1992-01-01	\N	f		t
2259	Glenilce Maria de Sousa Forte	glenilce@yahoo.com.br	Glenilce	@		b593b2d92106a737ece1cc8afbc6ec86	f	\N	2011-11-24 09:58:43.965425	2	2011-01-01	\N	f		t
2305	ana ingrid dantas	anaingriddantas@hotmail.com	ingrid	@		3b365c48bac535ad133c39a72e56b2ec	f	\N	2011-11-24 10:40:04.107634	2	1995-01-01	\N	f		t
2297	Iury Mesquita Sousa	iury_kinsser_1973@hotmail.com	Iury Mesquita	@		ba37c003781eebb19ac12dafcdd33adc	f	\N	2011-11-24 10:23:00.240559	1	1995-01-01	\N	f		t
2648	André dos Santos Abreu	abreubarreira@gmail.com	andreb	@		77a1830f18b5b5b54fd9900f0bb92a70	f	\N	2011-11-26 14:05:10.362348	1	1986-01-01	\N	f		t
2314	Rafael Angelo ferreira Santiago	angelosantiago@gmail.com	Angelo	@		379116ba2a14e5adba2cd6f67c4e07a9	f	\N	2011-11-24 10:44:05.454035	1	2011-01-01	\N	f		t
2580	Jefferson Silva Almeida	jefferson.seliga@gmail.com	Jefferson Silva	@jeffersonseliga		d83ef206c7b25939ab9e3fb16b566262	f	\N	2011-11-25 14:25:18.636994	1	1992-01-01	\N	f	jefferson.seliga@gmail.com	t
2600	Severiano de Sousa Oliveira	severianosousa2011@hotmail.com	severiano	@		ac1106a7fb8e29c7714df739c77974f1	f	\N	2011-11-25 16:42:13.921273	1	1997-01-01	\N	f		t
1699	Ticiano Godim Alencar	ticianogodim@gmail.com	Ticiano	@		52aa72297bd46b562214492b18da3631	f	\N	2011-11-22 23:36:44.123218	1	1991-01-01	\N	f		t
3573	FELIPE DANIEL DE SOUSA BARBOSA	ifce.maraca8@ifce.edu.br	FELIPE DAN	\N	\N	0a113ef6b61820daa5611c870ed8d5ee	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
1700	Robson Moreira da Silva	rms-ciclop21@hotmail.com	robinho	@		f4e56c18a077a163eaa7f69907ece162	t	2011-11-22 23:42:59.501127	2011-11-22 23:37:14.574402	1	1990-01-01	\N	f	rms-ciclop@hotmail.com	t
1707	MADSON HENRIQUE DO NASCIMENTO RODRIGUES	madson38@hotmail.com	Tio Bob	@		80893dc277540ec034d4ecb3bd93928a	f	\N	2011-11-23 00:04:46.496182	1	1987-01-01	\N	f	madson38@hotmail.com	t
3574	FRANCISCO CLEDSON ARAÚJO OLIVEIRA	ifce.maraca9@ifce.edu.br	FRANCISCO 	\N	\N	37a749d808e46495a8da1e5352d03cae	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
1701	JOSE HERMESON MAIA MACIEL	j.hermeson_16@hotmail.com	HERMESON	@		e7b7c8baec38960d7d59cbebb40ef94f	t	2011-11-22 23:45:53.146051	2011-11-22 23:41:06.912874	1	1991-01-01	\N	f	j.hermeson_16@hotmail.com	t
3575	FRANCISCO DAVID ALVES DOS SANTOS	ifce.maraca10@ifce.edu.br	FRANCISCO 	\N	\N	2a084e55c87b1ebcdaad1f62fdbbac8e	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
1730	Ingrid Yohana Monteiro da Silva	yohanamonteiro@hotmail.com	Yohana	@		ace5afc4cdd43f917ce5b2e2c535a03f	f	\N	2011-11-23 09:23:02.010134	2	1995-01-01	\N	f		t
2200	Betiane Azevedo	baetianeazevedo63@gmail.com	Babetiane	@		43c75a6cee974a1358baf11325c7c4e2	f	\N	2011-11-23 20:42:00.057386	2	1995-01-01	\N	f		t
1702	Ticiano Gondim Alencar	ticianogondim@gmail.com	Ticiano	@		40b1a3c27b969550afea546fe1611ef4	f	\N	2011-11-22 23:42:10.892386	1	1991-01-01	\N	f		t
3576	FRANCISCO JOAB MAGALHÃES ROCHA	ifce.maraca11@ifce.edu.br	FRANCISCO 	\N	\N	58a2fc6ed39fd083f55d4182bf88826d	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
3577	FRANCISCO VENÍCIUS DA SILVA SANTOS	ifce.maraca12@ifce.edu.br	FRANCISCO 	\N	\N	26337353b7962f533d78c762373b3318	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
1703	Maria Jeiciara	jeiciaraamojesus@hotmail.com	Jeicinha	@		313c154831731b7acf3a019c1eabf6a4	t	2011-11-22 23:46:13.599455	2011-11-22 23:43:33.538857	2	1991-01-01	\N	f	jeicybadgirll@hotmail.com	t
1758	Herison Simplicio dos Santos Soares	herisonsimplicio2010@hotmail.com	Herison	@Hs_santos17		4ab313bcd5d39f33f3a57cc884592ac0	f	\N	2011-11-23 09:33:11.421326	1	1995-01-01	\N	f	herisonsimplicio2010@hotmail.com	t
1616	GABRIELA DA SILVA COSTA	gabrielasilvaadf@gmail.com	gabyzimnha	@		bf5a276e92e82337d6e871c41dd155fb	t	2011-11-25 21:32:18.626367	2011-11-22 20:14:50.756539	2	1995-01-01	\N	f		t
2146	Antonio Dyeuson Souza de Araújo	antoniodyeuson@hotmail.com	Dyeuson	@		d37400754bd9e7d489e603afaca15798	f	\N	2011-11-23 18:29:21.667175	1	2009-01-01	\N	f		t
1704	Bruna Evellyn lima alves	bruna_legal_@hotmail.com	Brunaevellyn	@		720972b13495fd1de1b375a750369827	f	\N	2011-11-22 23:49:12.591819	2	1994-01-01	\N	f		t
1108	rafaela de sousa liberato	rafaela.liberato@hotmail.com	Rafaela	@		85d0c36957025fe087462e899773470b	t	2011-11-22 23:52:40.304961	2011-11-21 10:40:35.991377	2	1990-01-01	\N	f		t
1770	Abel Aguiar	abel_servodeDeus@hotmail.com	bebelda12	@		8abd7eda5a194c55ab6304e740a105eb	f	\N	2011-11-23 09:37:23.718352	1	1994-01-01	\N	f		t
1779	FRANCISCO HERBERTH RODRIGUES LIMA	HERBERTHCYBER@GMAIL.COM	HERBERTH	@		ceaa2cf7388517e4040c3cccd780d39f	f	\N	2011-11-23 10:13:40.840448	1	2011-01-01	\N	f		t
1794	eduardo coutinho dos santos 	educoutinho77@hotmail.com	coutinho	@		4d7b2292876ace7385294306035d0363	f	\N	2011-11-23 10:22:57.421227	1	1977-01-01	\N	f	educoutinho77@hotmail.com	t
2160	Henrique Emiliano Eduardo da Cruz Silva	pavelnedved26@gmail.com	Nedved	@		965da829a2e49db77384b8db054c36b5	f	\N	2011-11-23 18:47:56.62625	1	2009-01-01	\N	f		t
1981	Maria Mônica Freitas Braga	monicabraga11@hotmail.com	Mônica Braga	@		4914f75185591ce7e70a6ac2261e573e	f	\N	2011-11-23 15:06:00.956072	2	2011-01-01	\N	f		t
1805	Antonio Carlos	mamonas_ssss@hotmail.com	Tripa Seca	@		82074cc83e003b025fd72d1326ad88b3	f	\N	2011-11-23 10:29:56.44051	1	1991-01-01	\N	f	mamonas_ssss@hotmail.com	t
2225	DIEGO RAFAL SERAFIM JORGE	diegorafaelsj@gmail.com	rafael	@		93f0cd03e05659ba8ed3fdcbce010447	f	\N	2011-11-23 23:09:27.473952	1	1988-01-01	\N	f		t
1814	Antonio Jorge Nobre Da Silva	jorgenobre.silva@gmail.com	Jorge Nobre	@		4d8fc0860d5c7915161b7d194a3a320f	f	\N	2011-11-23 10:36:12.088789	1	1982-01-01	\N	f		t
2170	Johnatan Bernardo Pereira	johnatanpereira123@yahoo.com.br	Bernardo	@		64ae7eb73e3a8029ada3e11733a3522f	f	\N	2011-11-23 19:30:03.903928	1	1995-01-01	\N	f		t
2288	Larissa Almeida Freitas	Laaryssa13@hotmail.com	Larissa	@		40fb2d60df8bad7d1c6e1c6ab1fe6c4e	f	\N	2011-11-24 10:15:14.975371	2	2011-01-01	\N	f		t
1828	Maria Aparecida	aparecidaferreira639@gmail.com	Cidinha	@		bfc7b468d12ec463f63d2fda11b44dbd	f	\N	2011-11-23 10:39:39.331447	2	1986-01-01	\N	f	aparecidasouzafds@yahoo.com.br	t
2243	Álvaro	alvarorcoelho@hotmail.com	Álvaro	@alvarocoelho		3015ca4f270b6938b27c95863174a8db	f	\N	2011-11-24 03:06:04.656888	1	1984-01-01	\N	f		t
2191	weslley Rodrigues Morais	weslleymorais@live.com	weslley RM	@wesley_rm		fe9298e3376b8ea7bd52e59439ef0926	f	\N	2011-11-23 20:13:19.147505	1	2011-01-01	\N	f	wesleyhapy@hotmail.com	t
1844	Diego Siqueira Magalhaes	diegosiqueiramagalhaes@hotmail.com	dieguinho	@		d970974ffd64098bc7a223716d50b3c6	f	\N	2011-11-23 10:55:33.713762	1	1994-01-01	\N	f	Diego.siqueira1994@hotmail.com	t
2021	manoel lopes da silva júnior	manoel_lopes@ymail.com	manoel	@		d3d330f5ce1d9dbaf223499b040dfb66	f	\N	2011-11-23 15:30:55.076787	1	1990-01-01	\N	f	mlljunior@hotmail.com	t
2581	GEISEL FERNANDES DO NASCIMENTO	gfernandes.fernandes22@gmail.com	Geisel	@geiselplaye		6ecf43b621e5888818a3f54a77886fb3	f	\N	2011-11-25 14:39:41.616363	1	1991-01-01	\N	f	geiselmoral@hotmail.com	t
1784	Erivania de Oliveira Maseno	erivaniamaseno@hotmail.com	maizena	@		2df1786fb1eed37a61263523f7050368	f	\N	2011-11-23 10:16:24.79091	2	1994-01-01	\N	f	erivaniamaseno@hotmail.com	t
2024	vanessa evelyn lima da silva	vanessinhaevelyn@hotmail.com	vanessinha	@		d7798723eab9c4c22b6131aae91c4931	f	\N	2011-11-23 15:32:07.508849	2	1996-01-01	\N	f		t
2260	Maria José Porto de Alencar	masealencar@yahoo.com.br	Maria José	@		dedb9764914648a160c6a3af9744f1a1	f	\N	2011-11-24 09:58:46.99463	2	1957-01-01	\N	f		t
2222	Mário Carneiro Rocha	mariorocha2009@hotmail.com	Mário	@mario_stone		bb86d47a9f361cac4a1eabfc9f973cd1	f	\N	2011-11-23 22:40:10.268597	1	1994-01-01	\N	f	mariorocha2009@hotmail.com	t
2275	Marcos Vinícius Albuquerque da Costa	vinicius-ac@live.com	Vinícius	@		2106a907a4de1dc38f3735248b430e67	f	\N	2011-11-24 10:11:15.492344	1	1995-01-01	\N	f		t
2649	Francisco Osvaldo Batista de Sousa	osvaldosousa@hotmail.com.br	osvaldo	@		59098dd16f9387deabeca4ea7baca306	f	\N	2011-11-26 14:08:40.614507	1	1986-01-01	\N	f		t
2306	Eduardo Távora Carneiro	duds.tavora@hotmail.com	Eduardo	@		9b7ed761c669684cab80c6921af7e1b0	f	\N	2011-11-24 10:40:41.037535	1	1996-01-01	\N	f		t
2315	Matheus Cardozo Carvalho	matheus-cardozo@hotmail.com	Matheus	@		25d1e36478a7bcb611e984f41eaaa017	f	\N	2011-11-24 10:44:46.029203	1	1994-01-01	\N	f		t
2601	Antonio Dennes Paulo de Moraes	dennespaulo15@gmail.com	Dennes Paulo	@		9c81ba1d3451a0b0a65e2480dd6e2d79	f	\N	2011-11-25 16:45:18.492958	1	1990-01-01	\N	f		t
2667	Lucas Neves Lima	lucasneves94@hotmail.com.br	Lucas Neves	@		affa962c5b9b4f6179a7e198a6b3c4d4	f	\N	2011-11-26 15:10:41.108117	1	1994-01-01	\N	f		t
2683	Manoel Alan Pereira da Silva	alan18222@hotmail.com	alan18222	@		fc3b3214a8bd575d59afc8d5894003cf	f	\N	2011-11-26 16:35:31.79591	1	1993-01-01	\N	f		t
1872	talisson chaves de araujo	talisson_invejado@hotmail.com	talisson	@		a7f9160baa38772636c9c79c1c66f68d	f	\N	2011-11-23 11:50:53.491654	1	2011-01-01	\N	f		t
3578	FRANCISCO WANDERSON VIEIRA FERREIRA	ifce.maraca13@ifce.edu.br	FRANCISCO 	\N	\N	b9228e0962a78b84f3d5d92f4faa000b	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
1871	Aparecida	aparecidasouzafds@yahoo.com.br	Aparecida	@		cc431b49d844f18cae31bb09731e2352	f	\N	2011-11-23 11:29:29.966021	2	1986-01-01	\N	f		t
1873	FRANCISCO JOSÉ MARTINS MACHADO FILHO	fjosefilho@hotmail.com	FRANZÉ	@fj_filho		d7438719b2a2d5cecd08375859ab0701	f	\N	2011-11-23 11:54:06.798942	1	1993-01-01	\N	f		t
1910	Priscila Nunes  de Sousa	pris_cila280@hotmail.com	pandora	@		7eadd0d7f0ad015a05733948e730cc25	f	\N	2011-11-23 14:04:59.099455	2	1991-01-01	\N	f	pris_cila130@hotmail.com	t
3579	GÉFRIS DE LIMA PEREIRA	ifce.maraca14@ifce.edu.br	GÉFRIS DE	\N	\N	f90f2aca5c640289d0a29417bcb63a37	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
1874	Wesley Henrique Santos da Silva	tec.wesleyhenrique@hotmail.com	Wesley	@		e184646d78137b956d08847e34bbbc8b	f	\N	2011-11-23 11:54:51.066702	1	1986-01-01	\N	f		t
2201	kevin Batista 	kevinho1717@hotmail.com	pintão.pp	@		97b1ed2f1da57ee30d0861ddaef240a0	f	\N	2011-11-23 20:43:33.639225	1	1996-01-01	\N	f	charllygabriel99@hotmail.com	t
3580	JOÃO FELIPE SAMPAIO XAVIER DA SILVA	ifce.maraca15@ifce.edu.br	JOÃO FELI	\N	\N	d96409bf894217686ba124d7356686c9	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
1875	JOSE ANDERSON FERREIRA MARQUES	js_andersonn@yahoo.com.br	Anderson Marques	@js_anderson10		aea67406eb68045e1434c81ad4b2fa33	f	\N	2011-11-23 11:55:12.284905	1	1989-01-01	\N	f		t
3581	JOÃO RAPHAEL SILVA FARIAS	ifce.maraca16@ifce.edu.br	JOÃO RAPH	\N	\N	819f46e52c25763a55cc642422644317	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
1926	nayana	nanay1947@hotmail.com	luka/nana	@		5d4aa4ebb077a8dd9b015c66d4398184	f	\N	2011-11-23 14:40:19.927737	2	1996-01-01	\N	f		t
1877	Antonia Merelania Silva Pereira	merynha_sp@hotmail.com	Merynha	@		43dc41476484bcecda699cdd3ea9a47e	f	\N	2011-11-23 11:59:30.892871	2	1992-01-01	\N	f	merynha_sp@hotmail.com	t
2130	Eliando Pereira Silva	nanndin@yahoo.com.br	Nanndin	@		6de4d141a7273565f41ece711bb51e44	f	\N	2011-11-23 18:02:40.458196	1	1986-01-01	\N	f	nanndin@yahoo.com.br	t
1938	Thiago Alves de Sousa	thiago.alves83@yahoo.com.br	FideKenga	@		8b1377d7dada5c0f32afab0bfeb9edb6	f	\N	2011-11-23 14:49:13.933116	1	2011-01-01	\N	f		t
2307	geisiane tavares gomes	geisitavares@gmail.com	geise.	@		c679ca74a4c7017745da6292ff6f7da4	f	\N	2011-11-24 10:42:22.278186	2	1997-01-01	\N	f		t
1883	Weslley Nojosa Costa	weslley_nojosa@hotmail.com	Weslley	@Weslley_NCosta		90c2871e9998e4331807dfdca0105a31	f	\N	2011-11-23 12:04:31.964557	1	2011-01-01	\N	f	weslley.nojosa@facebook.com	t
1958	Thiago Alves de Sousa	baldecaneco@yahoo.com.br	Trozol	@		898c0e24abb21ff4afedc6c904f9c760	f	\N	2011-11-23 14:56:09.3649	1	1995-01-01	\N	f		t
2147	Andrino Sousa de Carvalho	andrino_sousa@hotmail.com	Cozinheiro	@		c30f3c2fcbf3d4963d8d398a47ddb351	f	\N	2011-11-23 18:30:21.321803	1	2009-01-01	\N	f		t
2226	valbelene perreira araujo	isaadorabarbosa@hotmail.com	belene	@		2d358a8b55c0b49badd526bf7932191b	f	\N	2011-11-23 23:10:39.042929	2	1990-01-01	\N	f		t
2629	Diakys Julio Laurindo da Silva	diakys.julio@hotmail.com	Diakys	@		af2860cbee69fc4500bfb6e194d37291	f	\N	2011-11-26 09:51:48.507746	1	1993-01-01	\N	f		t
1890	Samanda Arimatéa de Sá	samandasa@hotmail.com	samanda	@		069d359ae1a97ead01f032d262df9387	f	\N	2011-11-23 12:08:24.460406	2	1993-01-01	\N	f		t
1891	Thiago Lima Lopes	thilopes.lima@gmail.com	Thiago	@thi_llopes		77bef6e0f4eb1d42eb5e56464eab2ae9	f	\N	2011-11-23 12:08:35.232151	1	1989-01-01	\N	f	thylyma_lopes@hotmail.com	t
1892	Evander Cardozo da silva 	felipe_feliz2009@hotmail.com	felipe	@felipebolcom		0ffeeae9d4e78d893af74f0a23a19bbb	f	\N	2011-11-23 12:33:28.990526	1	1997-01-01	\N	f	felipe_feliz2009@hotmail.com	t
1893	Cleilson de Sousa Santos	cleilson_link@hotmail.com	cleilson	@		2f848c6398cc9ff9a93486c9fc6080d4	f	\N	2011-11-23 12:35:09.792802	1	1994-01-01	\N	f	cleilson_link@hotmail.com	t
1894	ANTONIO FÁBIO SAMPAIO	natgrey@hotmail.com	phoenix	@		7beeb183761c5e07f8c3e67893da598f	f	\N	2011-11-23 12:43:10.136503	1	1982-01-01	\N	f	natgrey@hotmail.com	t
2181	Francisco Renato Lessa de Oliveira	duzzplaysinhos@gmail.com	Renatinho	@		8d7e08cf76e7708f3525902935facad5	f	\N	2011-11-23 19:44:15.28425	1	1997-01-01	\N	f		t
2244	Antonio Stenio de Lima Lopes	stenio_lima07@hotmail.com	Stenio	@		3ec91ce257b68fc13d31456f7442ebee	f	\N	2011-11-24 08:29:11.210352	1	1994-01-01	\N	f	stenio_lima07@hotmail.com	t
2022	Guilherme Vieira Medeiros	guilhermy.vm@gmail.com	Guilherme Vieira	@		3de8f96b0928b2dd99f99b355bb579cc	f	\N	2011-11-23 15:30:55.096976	1	2011-01-01	\N	f		t
2027	Marcos Alves	logo_marcos@yahoo.com.br	Marquinhos	@		f2af4436f6ae6b3bf786938f83011e25	f	\N	2011-11-23 15:36:01.035767	1	1989-01-01	\N	f		t
3388	DAVIANNE COELHO VALENTIM	daviannevalentim@oi.com.br	DAVIANNE C	\N	\N	7038200126740b1a65308c371966e2d4	f	\N	2012-01-10 18:25:57.996689	0	1980-01-01	\N	f	\N	f
2029	mateus nascimento	mateusblack14@hotmail.com	black ops	@		0cf454fff0412e9fd098652fa95323fb	f	\N	2011-11-23 15:40:28.751105	1	1994-01-01	\N	f		t
2030	Jonas Diego Rodrigues Martins	jonasdiegorodriguesmartins@yahoo.com.br	Jonas.Martins	@JD_Oficial		2ffb71013a8c61036753cbadff8caefb	f	\N	2011-11-23 15:41:23.783819	1	1990-01-01	\N	f	jonasdiegorodriguesmartins@yahoo.com.br	t
2261	Liduina Vidal	lidvidal@yahoo.com.br	Liduina	@		61145ab047775769a7d4adb1a945a6da	f	\N	2011-11-24 09:58:54.752653	2	1962-01-01	\N	f		t
2582	FRANCI WAGNER VIEIRA	francyw@gmail.com	Franci	@		04f53551a0f1d0fa6786e2c4739f4a73	f	\N	2011-11-25 15:06:28.349098	2	1970-01-01	\N	f		t
2298	reginaldo morel freitas	regi_morel@hotmail.com	reginaldo	@		fffbb8ccf15a59b3a87d2da333e01dd9	f	\N	2011-11-24 10:26:00.362068	1	1968-01-01	\N	f		t
2602	Antônio Marcos Carneiro Correia	marcoscorreia27_@hotmail.com	marcos	@		7beafa544e6192fadad943fb9768acd2	f	\N	2011-11-25 17:53:33.36009	1	1985-01-01	\N	f		t
2323	Thays Lima Vieira	thayslv@hotmail.com	thayslv	@		4fce0687724626cc6405f653516cfad2	f	\N	2011-11-24 10:46:54.531379	2	1995-01-01	\N	f		t
2329	Fernando Rodrigues	profernandorodrigues@gmail.com	profnando	@prof_fernad0		004d2a047da0bd99ca74d6420d0c6235	f	\N	2011-11-24 10:51:56.598602	1	1991-01-01	\N	f		t
2650	Leila Danielly Dias Pinheiro	gleyson-leilinha@hotmail.com	LeilaD	@		3bc63bc60a6334f8aedba7bd91e4d2e3	f	\N	2011-11-26 14:12:47.092198	2	1994-01-01	\N	f		t
2335	Eudiene Feitoza da Silva Rolim	eudienerolim@gmail.com	eudiene	@		b0ce166be81084931c4ffddff8308bc0	f	\N	2011-11-24 11:08:14.406249	2	1985-01-01	\N	f	eudiene_feitosa@hotmail.com	t
2338	Alexandre Pereira Batista da Silva	alex-pro1000@hotmail.com	Alexandre	@		ced782636c6bd33daac6508271c15515	f	\N	2011-11-24 11:18:24.850687	1	1991-01-01	\N	f	alex-pro1000@hotmail.com	t
2668	José Wellington de Olivindo	wtec.informacao@gmail.com.br	Tomzim	@		06e6d374db61e61f05584ebef7761d70	f	\N	2011-11-26 15:14:26.295856	1	1979-01-01	\N	f		t
3389	DAVID NASCIMENTO DE ARAUJO	daviddna2007@gmail.com	DAVID NASC	\N	\N	4875cc327093b1e99e34fd7db4b9538c	f	\N	2012-01-10 18:25:58.107027	0	1980-01-01	\N	f	\N	f
3390	DENISE VITORIANO SILVA	denisevitoriano@gmail.com	DENISE VIT	\N	\N	13f320e7b5ead1024ac95c3b208610db	f	\N	2012-01-10 18:25:58.230505	0	1980-01-01	\N	f	\N	f
3354	AMAURI AIRES BIZERRA FILHO	liger_i@hotmail.com	AMAURI AIR	\N	\N	77bdc95368f11ec1c9d88e099ecbad00	f	\N	2012-01-10 18:25:43.727839	0	1980-01-01	\N	f	\N	f
1911	José Arnaldo Souza do Nascimento	arnaldoqxda@gmail.com	jhosepy	@arnald_jhosepy		c3a6fd9e291290f01c116db5c7ab131e	f	\N	2011-11-23 14:22:02.849997	1	1986-01-01	\N	f	arnaldoqxda@gmail.com	t
3582	JONAS FEITOSA CAVALCANTE	ifce.maraca17@ifce.edu.br	JONAS FEIT	\N	\N	28267ab848bcf807b2ed53c3a8f8fc8a	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
2202	joyce wendy	joyce_wendy@hotmail.com	joyce wendy	@		ce23ce574dad627a529ba55bd76b042d	f	\N	2011-11-23 20:47:46.364772	2	1996-01-01	\N	f	joyce_wendy@hotmail.com	t
2131	Sabrina Nogueira da Rocha	sabrina-darocha@hotmail.com	Sabrininha	@		9d463db11dd9ece2e35b5a90e82b6e46	f	\N	2011-11-23 18:03:34.607902	2	1993-01-01	\N	f	sabrina-darocha@hotmail.com	t
3583	JOSÉ TUNAY ARAÚJO	ifce.maraca18@ifce.edu.br	JOSÉ TUNA	\N	\N	45c48cce2e2d7fbdea1afc51c7c6ad26	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
1898	ALEXSANDRO KAUÊ CARVALHO GALDINO	carvalho_3331@hotmail.com	akcg20	@		a6be88d7bf4394c93ff84b52c2dcc794	f	\N	2011-11-23 12:56:58.103421	1	2011-01-01	\N	f		t
1927	Daniel vasconcelos da silva 	danielsolteirao2010@hotmail.com	Dielzinho	@		d1622c8533183a1b597a59c4476685d0	f	\N	2011-11-23 14:43:23.239681	1	1993-01-01	\N	f		t
3391	DENYS ABNER SANTOS BEZERRA	denys_abner@hotmail.com	DENYS ABNE	\N	\N	3ef815416f775098fe977004015c6193	f	\N	2012-01-10 18:25:58.344458	0	1980-01-01	\N	f	\N	f
3584	JULIANA BARROS DA SILVA	ifce.maraca19@ifce.edu.br	JULIANA BA	\N	\N	605ff764c617d3cd28dbbdd72be8f9a2	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
3585	MICHELE XAVIER DA SILVA	ifce.maraca20@ifce.edu.br	MICHELE XA	\N	\N	577ef1154f3240ad5b9b413aa7346a1e	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
3392	DIEGO ALMEIDA CARNEIRO	diegoo_ac@hotmail.com	DIEGO ALME	\N	\N	1ffb8a29dc0f1f707387ca849c26c15b	f	\N	2012-01-10 18:25:58.622743	0	1980-01-01	\N	f	\N	f
3586	PATRICIA PAULA FEITOSA COSTA	ifce.maraca21@ifce.edu.br	PATRICIA P	\N	\N	02e74f10e0327ad868d138f2b4fdd6f0	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
1902	lorena cardoso viana	louren4.c4rdoso@gmail.com	lorena	@		12aaa7df9db139085018afab9baa27c6	f	\N	2011-11-23 13:02:39.070312	2	1995-01-01	\N	f		t
1939	Marlon Clíngio Almeida Coutinho	marlon_ce12@hotmail.com	maninho	@		9c1ff3d6acc3eff0d663fcea4116e8e4	f	\N	2011-11-23 14:50:06.0537	1	1995-01-01	\N	f		t
1903	suzana de sousa gomes	suzan4.gomes@gmail.com	suzana	@		84dc41ed4770bba4784d1f87447d5e04	f	\N	2011-11-23 13:03:47.079535	2	1990-01-01	\N	f	suzana_querida@yahoo.com.br	t
1904	Mirian carlos da costa	miriancc.carlos@gmail.com	Mirian	@		b1c97837675e8532ff3cbe358d526538	f	\N	2011-11-23 13:04:24.246099	2	1982-01-01	\N	f	miriancarlos83@yahoo.com.br	t
1905	kelly santos de sousa 	sousakelly25@gmail.com	kelly25	@		67effe5686e0043eba009618d13e99f6	f	\N	2011-11-23 13:04:29.077247	2	1994-01-01	\N	f		t
2148	Caio Anderson Sabino Lourenço	caioandersonsabino@hotmail.com	Chriss	@		c5758ee238c197f509ecda52122a1fd1	f	\N	2011-11-23 18:31:50.804443	1	2009-01-01	\N	f		t
1906	joel rodrigues chaves	joel.cheves17@gmail.com	joel joka	@		0386a94bb665f42a6577c0ad5b3bb037	f	\N	2011-11-23 13:04:51.778657	1	1994-01-01	\N	f	jorel-leoj@hotmail.com	t
2290	Flávio Irivan Alves	flavioirivan@hotmail.com	kdynho	@		81ecd39be8739df94ca4cedeaae5984d	f	\N	2011-11-24 10:16:00.395797	1	1980-01-01	\N	f		t
1907	Glenilson	glenilson_libra@hotmail.com	Chess UD	@GlenilsonChess	http://www.orkut.com.br/Main#Profile?uid=3660861319709749580	daabc91f2324525bdee89a1d42e5eacb	f	\N	2011-11-23 13:06:24.561291	1	2011-01-01	\N	f	glenilson_libra@hotmail.com	t
1908	Francisco Edileno Matos	edilenomatos@yahoo.com.br	Edileno	@edilenomatos		9662681fdd2de5029bc83a5d330ac053	f	\N	2011-11-23 13:14:24.353174	1	1961-01-01	\N	f	edilenomatos@yahoo.com.br	t
2121	BRUNO BARROSO RODRIGUES	bruno_62110@hotmail.com	Bruninho	@brunobinfo		0052d8c0c355e308217df6a98235a187	f	\N	2011-11-23 17:59:41.249198	1	1993-01-01	\N	f	bruno_62110@hotmail.com	t
1909	José Paulo Rodrigues Moraes	jose_paulo182@yahoo.com.br	J. Paulo	@		9363ac717fb24759bdd33a3833a93941	f	\N	2011-11-23 13:31:52.656916	1	1989-01-01	\N	f	jose_paulo182@yahoo.com.br	t
985	Paula Pinto de Assis	paulinhafekete@hotmail.com	Paulinha	@		302e3105d546f62bc170cff4498166eb	t	2011-11-23 13:44:01.997426	2011-11-17 22:05:02.359279	2	1993-01-01	\N	f	paulinhafekete@hotmail.com	t
2182	Leonardo Souza Melo Falcão	leonardo.smfalcao@gmail.com	Zerofalk	@leowmf	http://zerof4lk.deviantart.com	718184f0ab05341632776a8b128ae36e	f	\N	2011-11-23 19:44:38.531285	1	1996-01-01	\N	f		t
1996	Maria Joana Roseira Paulino	joanamary1972@hotmail.com	Joana Roseira	@		4e3ea496d3273a6f79242913d031deeb	f	\N	2011-11-23 15:15:12.236187	2	2011-01-01	\N	f		t
2227	Beatriz Braga da Silva	bia050@hotmail.com	Bia Braga	@		a658defc58655c1080272aab341b35f5	f	\N	2011-11-23 23:16:30.821263	2	1994-01-01	\N	f	bia050@hotmail.com	t
2001	Maria Joana Roseira Paulino	joanamary1972@hotmail.com.br	Joana Roseira	@		b55359e736a3c08a6eb1ba8011383378	f	\N	2011-11-23 15:16:57.752137	2	2011-01-01	\N	f		t
2005	Dhiego Alves Oliveira	dhiegoalves@oi.com.br	Dhiego	@		6ae5f39e7905aa3afe129636ba64b0db	f	\N	2011-11-23 15:19:01.256098	1	1987-01-01	\N	f	zecapoeiraz@hotmail.com	t
2193	Matheus Gadelha Marques	matheus_rockr@hotmail.com	Gadelha	@gadelhalavigne		ed8e4bc8e3492159950e46bb12aa56bf	f	\N	2011-11-23 20:13:47.940877	1	1996-01-01	\N	f	matheus_rockr@hotmail.com	t
2009	manoel lopes da silva junior	mlljunior@hotmail.com	manoel	@		b868266753902825ba2745ff365efe42	f	\N	2011-11-23 15:23:38.236701	1	2011-01-01	\N	f		t
2528	Davi Felipe Soares	davifelipe316@gmail.com	davidy	@		f0642c39cc3b4b1cd6b0c874dc6acd81	f	\N	2011-11-24 21:48:54.68301	1	1996-01-01	\N	f		t
2014	Ismael Martins Macedo	ismaell.mm@gmail.com	Ismael Martins	@		d58666e1c4892c50ca7b3aeabc7a0bc0	f	\N	2011-11-23 15:27:06.822192	1	2011-01-01	\N	f		t
3393	DIEGO DO NASCIMENTO BRITO	diiego.britto@gmail.com	DIEGO DO N	\N	\N	71c332f3926619ee3dc7f05758295c49	f	\N	2012-01-10 18:25:58.793125	0	1980-01-01	\N	f	\N	f
2299	CARLOS AUGUSTO VIEIRA ALMEIDA JUNIOR	carloskazu@gmail.com	Carlos_Kazu	@Carlos_Kazu06		968acc7c49a4a3a54f14f2deb57c3806	f	\N	2011-11-24 10:26:42.312126	1	1991-01-01	\N	f	car_stagesk8@hotmail.com	t
2262	luciana xavier de campos	lu_campos2000@yahoo.com.br	luciana	@		a1fd535cbdd11c70d1d8027db45eeb2a	f	\N	2011-11-24 10:00:04.213864	2	1967-01-01	\N	f		t
2277	leticia gadelha mendes	leticiagm@live.com	leticia	@		1246f2faa91de876a812432e610c3422	f	\N	2011-11-24 10:11:57.978345	2	1995-01-01	\N	f		t
2557	Francisco Anderson Silvino Mendes	franciscoandersons@hotmail.com	Anderson	@		9809e8d9ac1b7e71ba651c4240019de8	f	\N	2011-11-25 09:54:12.815178	1	1993-01-01	\N	f		t
2308	Fábio Erick	fabioerick95@gmail.com	Fabio Erick	@		5a505536ad04b5393ebfa63b0d3cb051	f	\N	2011-11-24 10:42:27.216595	1	2011-01-01	\N	f		t
3394	DIEGO GUILHERME DE SOUZA MORAES	dieguin_alvinegro@hotmail.com	DIEGO GUIL	\N	\N	50f88458a650c7fe71f4fe05777aa89e	f	\N	2012-01-10 18:25:59.060022	0	1980-01-01	\N	f	\N	f
2583	raquel vieira	raquelvieirass@hotmail.com	raquel	@irineiaraquel		37dfa8a12d6c4c59e0513c61f2605ec0	f	\N	2011-11-25 15:08:07.406706	2	1986-01-01	\N	f		t
2651	Francisco das Chagas Alves de Oliveira	franciscoa.oliveira@yahoo.com	oliveira	@		d38d96d4df4a5d914e05cc54b950e5bc	f	\N	2011-11-26 14:19:08.090884	1	1960-01-01	\N	f		t
3395	DIÊGO LIMA CARVALHO GONÇALVES	zyhazz@msn.com	DIÊGO LIM	\N	\N	2291d2ec3b3048d1a6f86c2c4591b7e0	f	\N	2012-01-10 18:25:59.401986	0	1980-01-01	\N	f	\N	f
3352	ALISSON SAMPAIO DE CARVALHO ALENCAR	alisson_1945@yahoo.com.br	ALISSON SA	\N	\N	8e607725d222db0f7a2dfabead333f95	f	\N	2012-01-10 18:25:43.32245	0	1980-01-01	\N	f	\N	f
2031	Francisco Regis Justa Santos	regis_justa@yahoo.com.br	Regis Justa	@		55dda8f8ad9e06700e57c784d442aa9e	f	\N	2011-11-23 15:48:32.686378	1	1985-01-01	\N	f		t
2203	Marciana Duarte Freire	marcinhaduarte.duarte@gmail.com	marciana.freire	@		843b580ba4d571c84bffec81e58e8fe9	f	\N	2011-11-23 20:51:11.239595	2	1988-01-01	\N	f		t
3587	REGINALDO FREITAS SANTOS FILHO	ifce.maraca22@ifce.edu.br	REGINALDO 	\N	\N	cb70ab375662576bd1ac5aaf16b3fca4	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
2032	João Batista Costa Moreno	jbatista100cori@hotmail.com	João Batista	@		41853cd3a9894737c052e88ef145ac0f	f	\N	2011-11-23 15:51:43.137916	1	1990-01-01	\N	f		t
2132	Vitória Régia Viana Magalhães	vitoria.regia_viana@hotmail.com	vitoria	@		94f0209e010de415ec443bd510cc56c4	f	\N	2011-11-23 18:03:47.868903	2	1992-01-01	\N	f	vitoria.regia_viana@hotmail.com	t
3588	ROBERTA DE SOUZA LIMA	ifce.maraca23@ifce.edu.br	ROBERTA DE	\N	\N	142949df56ea8ae0be8b5306971900a4	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
2033	Wilson Júnior	wilsonjuniorterceiro2011@hotmail.com	wilsonjunior	@		4deed26b284af2936ffca2b83052ce71	f	\N	2011-11-23 15:58:34.226154	1	1995-01-01	\N	f		t
3589	RÔMULO SAMINÊZ DO AMARAL	ifce.maraca24@ifce.edu.br	RÔMULO SA	\N	\N	44c4c17332cace2124a1a836d9fc4b6f	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
1090	Francisco Amsterdan Duarte da Silva	amster_duarte@hotmail.com	Amsterdan	@		e58fcb9f6358c50bba01b762dd324ca2	t	2012-01-19 21:10:46.89831	2011-11-20 21:12:16.04893	1	1995-01-01	\N	f	amster_duarte@hotmail.com	t
2034	ALEFE FEIJAO UCHOA DOS SANTOS	alefefeijao@hotmail.com	ALEFE DOS SANTOS	@		5a64340cd0d9e3e979eba59a5580322f	f	\N	2011-11-23 16:03:12.651504	1	1994-01-01	\N	f		t
3565	VIVIANE FERREIRA ALMEIDA	viviane.fe.almeida@gmail.com	VIVIANE FE	\N	\N	10b3742990747e371721ed390dfc31c1	f	\N	2012-01-19 15:55:08.314743	0	1980-01-01	\N	f	\N	f
399	Luana Gomes de Andrade	j.kluana@gmail.com	Luanynha	@boneklulu		6f95b503ca830587dc87a915bb6f66e5	t	2012-01-16 16:01:55.786352	2011-10-20 18:18:36.750374	2	2011-01-01	\N	f	j.kluana@gmail.com	t
2529	Fabíola da Silva Costa	fabiolasilvainformatica@gmail.com	Babiizinha	@		e75e1101901053b1040b2f7309214904	f	\N	2011-11-24 21:59:26.180618	2	1994-01-01	\N	f	fabiola_festa15@hotmail.com	t
2489	Jeanne Darc de Oliveira Passos	passosjeanne@yahoo.com.br	Jeanne	@		b48d71b76aaa91e7445bb6b7f273b6a4	f	\N	2011-11-24 18:56:58.354307	2	1979-01-01	\N	f	jeanne_passos@hotmail.com	t
2631	Sara Wandy Virginio Rodrigues	sarawandy_10@hotmail.com	sara wandy	@		793729eff410397a1a4cc42b0b66aa72	f	\N	2011-11-26 10:12:06.717735	2	1991-01-01	\N	f		t
2228	Erislaine do Nascimento Alves	eris-alves@hotmail.com	Erislaine	@eriiiss		bac33bc725edf6cfa45c426326ea3a85	f	\N	2011-11-23 23:35:01.483787	2	1992-01-01	\N	f	eris-alves@hotmail.com	t
2037	MARIA SULAMITA DOS SANTOS SALES	sulamitasantos_sales@hotmail.com	SULAMITA	@		d7aaf186b7f6f6064b0628d24722e1e0	f	\N	2011-11-23 16:10:54.552586	2	1995-01-01	\N	f		t
2162	DJALMA DE SÁ RORIZ FILHO	djalmaroriz@yahoo.com.br	Djalma Roriz	@		a09f91f8be77e65b371a64bf1d8305c9	f	\N	2011-11-23 18:57:56.767793	1	1978-01-01	\N	f		t
2490	Kevin Batista	delanosantos14@gmail.com	Kevinho	@		c2a5eee067a4ff22184bff932a139f7e	f	\N	2011-11-24 19:07:50.661887	1	1996-01-01	\N	f		t
2038	Carlos linhares	linhares56@yahoo.com	Carlos	@		4a60bee89e12f0b84d9d30f7e6df77fb	f	\N	2011-11-23 16:12:27.058326	1	1956-01-01	\N	f		t
2330	helton derbe silva almeida	helton_almeida@yahoo.com.br	helton	@		6b035a1aaf763b5b2f174962998d1260	f	\N	2011-11-24 10:52:43.033884	1	1991-01-01	\N	f		t
2039	anakessia gomes da silva	anakesiaejovem@gmail.com	neguinha	@		a29260e6f8074eb73549284ad6bdd886	f	\N	2011-11-23 16:14:10.077301	2	1994-01-01	\N	f		t
2040	MARIA AMANDA LIMA DE SOUSA	amandynha_nega@hotmail.com	AMANDA	@		5c8f7a21626d0b69b29229eb86f7cca3	f	\N	2011-11-23 16:17:20.968055	2	1994-01-01	\N	f		t
2246	LUCAS WEIBY SOUZA DE LIMA	lwsl13662@gmail.com	lucas.	@		d829122ba54c2d0fb69bd4d0aae4cd53	f	\N	2011-11-24 08:48:15.791297	1	1998-01-01	\N	f		t
2183	Rafael Arcanjo de Freitas	rafinha.magnani@hotmail.com	Rafael	@	http://www.facebook.com/profile.php?id=100003077019597	df18126c0acda57772c20ac666540d33	f	\N	2011-11-23 19:46:49.885258	1	1996-01-01	\N	f		t
1918	BREHMER PEREIRA MENDES	BREHMERMENDES@GMAIL.COM	UCHIHA	@		429e760b13701d19773a172beb27c84b	f	\N	2011-11-23 14:37:36.131171	1	1994-01-01	\N	f		t
2045	Anne Katiũscia Costa Couto	annekatiuscia@gmail.com	Katiuscia	@		f6bba0febda4d6efb3c003dc8fa9bf95	f	\N	2011-11-23 16:26:38.120309	2	1988-01-01	\N	f		t
2263	Zaíra Maria de Araújo Siqueira	zaira.proinfo@gmail.com	Zaíra Maria	@		00d25a70cc92b9c2c2e155c0a6b28460	f	\N	2011-11-24 10:00:28.881966	2	1950-01-01	\N	f		t
2048	MARIA RENATA ARRUDA COELHO	renatas2@hotmail.com	RENATA	@		c5cc8669beb6659b82a608583264137f	f	\N	2011-11-23 16:28:49.676231	2	1995-01-01	\N	f		t
2278	Bianca Rodrigues de Almeida	biancarodriguesdealmeida@hotmail.com	Bianca	@		7939b847ab37bbcab335c7535135e57e	f	\N	2011-11-24 10:12:07.860431	2	2011-01-01	\N	f		t
2558	mateus cabral de sousa	mateuscabraldesousa@gmail.com	Mateus cabral	@		3cede20e19ab86d82c9088b8adf7a488	f	\N	2011-11-25 10:00:03.831101	1	1994-01-01	\N	f		t
2291	Paulo Gabriel Pinheiro Vieira	paulolinbiel@hotmail.com	Gabriel	@		7af1c239cfadbb19b450e8924221af57	f	\N	2011-11-24 10:16:12.901318	1	2011-01-01	\N	f		t
3396	EDSON ALVES MELO	edsonbs8@hotmail.com	EDSON ALVE	\N	\N	89fcd07f20b6785b92134bd6c1d0fa42	f	\N	2012-01-10 18:26:00.149215	0	1980-01-01	\N	f	\N	f
2300	solange marinho vercosa 	solange1308_@gmail.com	solange	@		4374f1b7e281c288847a965d6512eb19	f	\N	2011-11-24 10:29:05.615537	2	1961-01-01	\N	f		t
2309	Janderson Rodrigues dos Santos	janderson-_-11@hotmail.com	Adriel	@		e0ad77825fb6fd2cbd34cdf3606e2b9f	f	\N	2011-11-24 10:42:30.766699	1	1994-01-01	\N	f		t
2584	FRANCISCA MARTA VIEIRA DE CASTRO	martavieira1@hotmail.com	Marta Vieira	@		2dd433ea9637f93e8778820fb6c7112a	f	\N	2011-11-25 15:10:12.519297	2	1960-01-01	\N	f		t
2317	Sarah Juliane da Silva 	sarahjulianedasilva@hotmail.com	juliane	@		697492c087d96cf053f9ab144d29bbe3	f	\N	2011-11-24 10:45:12.590114	2	1995-01-01	\N	f		t
2324	Pedro Paulo Moreira Mintoso	ppmintoso10@hotmail.com	Pedro Paulo	@		d737e981c6f00c356c544234bff894ca	f	\N	2011-11-24 10:47:21.880319	1	2011-01-01	\N	f		t
2652	Cindia Carliane Valendino de Oliveira	Kaila-Carvalho@hotmail.com	Carliana	@		726eb0dd4ee68ef523e89077fb2d1c52	f	\N	2011-11-26 14:21:28.801303	2	1999-01-01	\N	f		t
2669	Vanessa Ketlyn Sousa Rodrigues	vanessaketlyn@hotmail.com	Vanessa	@		c0fe4fbddb3724f5a930d601bbb80f67	f	\N	2011-11-26 15:18:27.307159	2	1998-01-01	\N	f		t
2684	Kelvyo Adison Batista da Silva	kelvyodark@hotmail.com	bobmarley	@		49c0cab3ef4cd146451dd72bac4d1029	f	\N	2011-11-26 17:38:43.938499	1	1995-01-01	\N	f		t
3397	EDVANDRO VIEIRA DE ALBUQUERQUE	edvandrovieira@hotmail.com	EDVANDRO V	\N	\N	5c0c0da3e2f999099db5841bc37cc744	f	\N	2012-01-10 18:26:00.263828	0	1980-01-01	\N	f	\N	f
3398	ELIADE MOREIRA DA SILVA	eliadebol@gmail.com	ELIADE MOR	\N	\N	bdb08663ec0d0b0f1a9fced4c3452b6e	f	\N	2012-01-10 18:26:00.391721	0	1980-01-01	\N	f	\N	f
3399	ELINE LIMA DE FREITAS	eline.lim@hotmail.com	ELINE LIMA	\N	\N	c6572b2c1d2a712b50c24707bffdae26	f	\N	2012-01-10 18:26:00.525449	0	1980-01-01	\N	f	\N	f
3400	ELIZABETH DA PAZ SANTOS	ame.uchiha@gamil.com	ELIZABETH 	\N	\N	0266e33d3f546cb5436a10798e657d97	f	\N	2012-01-10 18:26:00.625845	0	1980-01-01	\N	f	\N	f
3401	ELTON NOBRE MORAIS	elton.nobre@live.com	ELTON NOBR	\N	\N	0a0cdc29c48fb5746c5fcac5d50f02f7	f	\N	2012-01-10 18:26:00.705069	0	1980-01-01	\N	f	\N	f
2055	kelliany bento façanha rodrigues	kellianybento@gmail.com	kelliany	@		d9acfab5227519059e9c27becbad3906	f	\N	2011-11-23 16:35:49.39486	2	1994-01-01	\N	f		t
2204	Francisco Jonas Ferreira	jonasferreirabc@gmail.com	jonasfer	@		77ec6f68c7da85da4f14d83b61bf6faf	f	\N	2011-11-23 20:56:43.598563	1	2011-01-01	\N	f		t
2542	luis magno diogo batista	magnomondriantecnologia@mondrian.com.br	luis...	@		a278b910a4d5fa017048a367ec586ab2	f	\N	2011-11-25 09:01:56.736486	1	1981-01-01	\N	f		t
2056	PEDRO RODRIGUES DOS SANTOS NETO	pedroneto_santos@hotmail.com	PEDRO NETO	@		53e00a3094285147de7774fa66992aa5	f	\N	2011-11-23 16:36:05.403238	1	1995-01-01	\N	f		t
2530	Ingrid Nascimento dos Santos	ingridnascimentoinf@gmail.com	Ingrid	@		7b84f1644573e8821ead87138d751642	f	\N	2011-11-24 22:02:13.412184	2	1995-01-01	\N	f		t
2491	Williane Carvalho de Vasconcelos	williane-lindinha@hotmail.com	aninha	@		8503624b874dd9ee218d44a412a7945c	f	\N	2011-11-24 19:12:38.623518	2	1994-01-01	\N	f		t
1532	yuri felipe da silva	y.felipe.silva@gmail.com	felipe	@		d96fa43e2ff9570f96c8e99abc588831	f	\N	2011-11-22 17:16:37.901257	1	2011-01-01	\N	f		t
2632	Jose Edilano Felix Araujo	edilanofelix99@hotmail.com	edilano	@		ac7d277c9592686a03afd64f75d235f0	f	\N	2011-11-26 10:51:40.796319	1	1985-01-01	\N	f		t
2150	Francisco Danilo Sousa Braga Filho	danilo-sbf@hotmail.com	Danillo	@		a3f0a85a9669ae9e40fc3602abbb7978	f	\N	2011-11-23 18:33:52.363358	1	2009-01-01	\N	f		t
2617	Francisco Ulisse Lima Junior	ulissejr@hotmail.com	Ulisse	@		7f8e7bdb076016e83c6ad955521f7a3d	f	\N	2011-11-25 23:21:25.383628	1	1987-01-01	\N	f		t
2492	Simeane da Silva	Simeane@yahoo.com.br	Simeane	@		9cacd302df965404375a14c151839f7f	f	\N	2011-11-24 19:17:15.0595	2	1991-01-01	\N	f	Simeane@yahoo.com.br	t
2571	Helano Albuquerque	m0rtadelLa@hotmail.com	Mortadela	@m0rtadelLaRJ	http://helanoalbuquerque.blogspot.com	f66c5121397be67fdf57a6ac8bdf0872	f	\N	2011-11-25 12:08:10.320071	1	1991-01-01	\N	f	a.h.helano@hotmail.com	t
2163	Felipe Ferreira Paixão	felipe-p63@hotmail.com	Paixão	@		d0bbd41d0ff2d697f2754b8cd1d8255e	f	\N	2011-11-23 19:06:56.462908	1	2011-01-01	\N	f	felipe-p63@hotmail.com	t
2061	Francisco Mailton Silva	maiton_hand@hotmail.com	mailton	@		9e12a7d0991728a314a1e0fcdd5b34f9	f	\N	2011-11-23 16:52:41.370242	1	1992-01-01	\N	f		t
2229	maysa ramos 	maysaramos95@hotmail.com	maysa 	@maaysaramos		9acbd7936202d24bb696744a84ea47df	f	\N	2011-11-23 23:35:59.366595	2	1995-01-01	\N	f		t
2493	Vitória Sousa Rodriguês Nogueira	vitoriaagata79@hotmail.com	Vick01	@		0748a9b6034dc218c6fcee0efdadc592	f	\N	2011-11-24 19:22:42.626496	2	1996-01-01	\N	f		t
2062	Carlos linhares	linhares560@yahoo.com.br	Carlos	@		81a76ff44609363b11d19989cb636d85	f	\N	2011-11-23 16:55:38.190952	1	1956-01-01	\N	f		t
1091	Carlos Adailton Rodrigues	adtn7000@gmail.com	Adailton	@		f27bbe5d534b14e3a171d2aaeda438c3	f	\N	2011-11-20 22:51:14.067744	1	1985-01-01	\N	f		t
2063	JOSE EDILAN PONCIANO COSTA	edilanponciano@hotmail.com	JOSE EDILAN	@		b7ff36c2f92ccbaeb3055106a4c9fe15	f	\N	2011-11-23 16:57:12.815359	1	1994-01-01	\N	f		t
2064	nathália rafaella viana branco	nathy.raffa@hotmail.com	NATTY.	@		825cc759d94a61b1e4c0a81103a413c4	f	\N	2011-11-23 16:59:41.784191	2	1996-01-01	\N	f		t
2065	Rayane Reichert Saraiva	rayanes2forever@hotmail.com	Reichert	@		834dd4b1ac20d0276b405e87218408ce	f	\N	2011-11-23 16:59:42.946549	2	2011-01-01	\N	f		t
2195	MARIA IZABELA NOGUEIRA SALES	isza-nogueiira@hotmail.com	iIZABELA	@		279616d39fc781695f0833b4195ea495	f	\N	2011-11-23 20:15:59.159143	2	1992-01-01	\N	f		t
2066	CARLOS ALBERTO CARNEIRO MOTA	carloscmota@gmail.com	carlosmota	@carloscmota		d1db05f01a6bdadd52254bbcfc42b7a2	f	\N	2011-11-23 16:59:55.339651	1	1984-01-01	\N	f	carloscmota@gmail.com	t
2336	Carla Ruama Matos Francelino	carla.ruama@hotmail.com	Carlinha	@		920076015b3209570a392bbdd8b9fc75	f	\N	2011-11-24 11:12:48.514826	2	1996-01-01	\N	f		t
2067	Renan da Silva Vieira	renanvieira01@hotmail.com	Renanzinho	@		72b20836b73443adcc6165dfba13f4d4	f	\N	2011-11-23 17:03:58.529414	1	1994-01-01	\N	f	renanvieira01@hotmail.com	t
2247	Narcísio Xavier de Freitas Júnior	narcisio.junior@hotmail.com	Juninho	@		3e7e75492f83eaf6aa93d1d42aaded2b	f	\N	2011-11-24 08:53:08.218302	1	1994-01-01	\N	f		t
2559	antônio jonas alves cabral	jonasgatoblz@yahoo.com	Jonass	@		abe962e81cbfe8229965770ca7542142	f	\N	2011-11-25 10:01:47.22613	1	1994-01-01	\N	f		t
2069	Fernando Bruno Pacheco Lima	brunopacheco@quantaignorancia.com	Bruninho	@	http://www.quantaignorancia.com/	a2cb5d2ebfea69fe825039a6fa029194	f	\N	2011-11-23 17:04:42.861479	1	1987-01-01	\N	f	brunopacheco@facebook.com	t
2264	Patrícia Fernandes Costa Martins	patriciafcm@yahoo.com.br	patricia	@		d409ff03d77bdf0bb5c21cc402e9d928	f	\N	2011-11-24 10:01:13.445199	2	2011-01-01	\N	f		t
2070	ERIVANIA RODRIGUES DOS SANTOS	erivania-viana@hotmail.com	ERIVÂNIA	@		7ba73f6f412649ca8ec3757e11d6e415	f	\N	2011-11-23 17:08:37.123439	2	1988-01-01	\N	f		t
2685	jose rafael vieira de morais	kiel_mr@hotmail.com	rafael	@		47d5fd14e6499192d7713ebbca995d1a	f	\N	2011-11-30 01:17:45.621344	1	1994-01-01	\N	f		t
2301	Vinícius Amado Sampaio	vinisci@gmail.com	Thevinisci	@		25b6c1d0bdadabf759439c804174a039	f	\N	2011-11-24 10:29:39.567905	1	1994-01-01	\N	f		t
3402	EMANUEL AGUIAR FREITAS	emanuel_aguiar_f@yahoo.com.br	EMANUEL AG	\N	\N	30bb3825e8f631cc6075c0f87bb4978c	f	\N	2012-01-10 18:26:00.826537	0	1980-01-01	\N	f	\N	f
2310	Levir Melo Ferreira	levimelo16@hotmail.com	levi2011	@		2a63b8f49fdbbdadc792b16e0ea849eb	f	\N	2011-11-24 10:43:06.203352	1	1996-01-01	\N	f		t
2670	Maria Miriene Barbosa Lopes	miriene97@gmail.com	Miriene	@		fee8da8ea19aa2b890cfa3541cf0d527	f	\N	2011-11-26 15:20:13.328349	2	1995-01-01	\N	f		t
2318	sollemberg goncalves rocha	sollemberg@gmail.com	sollemberg	@		297fb06f66b283cbade904ac0463b4d1	f	\N	2011-11-24 10:45:16.042824	1	1996-01-01	\N	f		t
2331	nandiara araujo santana	nandiara.santana@hotmail.com	nandiara	@		079c6ec4b646424459424cba74569afb	f	\N	2011-11-24 10:54:23.906875	2	1990-01-01	\N	f		t
2343	wilsom terceiro de morais junior	wilsonjuniorterceiro@hotmail.com	wilson	@		06a832e6bafe38442a98c9ef15758671	f	\N	2011-11-24 11:21:04.67781	1	1995-01-01	\N	f		t
535	Natália OLiveira	oliveirafigueredo1993@gmail.com	Naathy	@		905a41e4e9d0746080965fb2b0244d3c	t	2011-11-24 11:31:21.239119	2011-11-04 09:00:10.119176	2	1993-01-01	\N	f	natalia_oliveira_13@hotmail.com	t
1277	jarysson	jarysson_damasceno@hotmail.com	jarysson	@		9068bf984808652c137ce4c290d52090	f	\N	2011-11-22 09:53:57.750462	1	1994-01-01	\N	f	jarysson_damasceno@hotmail.com	t
3403	EMANUELLA GOMES RIBEIRO	emma.taylor.49@gmail.com	EMANUELLA 	\N	\N	6395bb6b609c504ae20017aaf4e4b2ff	f	\N	2012-01-10 18:26:01.114221	0	1980-01-01	\N	f	\N	f
2349	ANDERSSON SILVA DE ALMEIDA	anderssoneducador@yahoo.com.br	ANDERSSON	@		f335f3ea149ef203a22d96c10f38a5df	f	\N	2011-11-24 11:35:55.661635	1	1978-01-01	\N	f	ANDERSSON.EDUCADOR@HOTMAIL.COM	t
3404	ÉRICA MARIA GUEDES RODRIGUES	erica_dekynha@yahoo.com.br	ÉRICA MAR	\N	\N	a684eceee76fc522773286a895bc8436	f	\N	2012-01-10 18:26:01.237525	0	1980-01-01	\N	f	\N	f
3405	EUDIJUNO SCARCELA DUARTE	charlie_doson@hotmail.com	EUDIJUNO S	\N	\N	3dd48ab31d016ffcbf3314df2b3cb9ce	f	\N	2012-01-10 18:26:01.381446	0	1980-01-01	\N	f	\N	f
3406	FABIANA DE ALBUQUERQUE SIQUEIRA	biazinha_siqueira@hotmail.com	FABIANA DE	\N	\N	3b810d1d14b6a944d733b20c064d7f86	f	\N	2012-01-10 18:26:01.690952	0	1980-01-01	\N	f	\N	f
3407	FABIO SOUZA SANTOS	fabio1993souza@yahoo.com.br	FABIO SOUZ	\N	\N	5c04925674920eb58467fb52ce4ef728	f	\N	2012-01-10 18:26:01.861289	0	1980-01-01	\N	f	\N	f
2071	Marcos Antonio de Sousa Lima	masl37@hotmail.com	Marquinhos	@		5fb281d6dabc724d52359c697686ddee	f	\N	2011-11-23 17:09:23.431271	1	1986-01-01	\N	f	masl37@hotmail.com	t
2068	levi santos	levivieira10@yahoo.com.br	levi santos	@		92fedaafbad642258e3e43b7870d20f5	f	\N	2011-11-23 17:04:26.416085	1	1992-01-01	\N	f		t
2205	Maria Luiza	malu.mvasconcelos@gmail.com	Malllu	@		ccc20bb05f1cca1ca5e64242fd95b1b7	f	\N	2011-11-23 21:01:12.39574	2	1993-01-01	\N	f		t
2531	Jéssica da Silva Costa	jessica_festa15@hotmail.com	Ingrid	@		063c239a70ae1284658ce991bed97e15	f	\N	2011-11-24 22:05:35.63892	2	1993-01-01	\N	f	jessica_festa15@hotmail.com	t
2151	Francisco Wesley Costa Delmiro	wesleyfla10@live.com	Resley	@		0293f0f6f2a4b396c299ee8468d684a0	f	\N	2011-11-23 18:34:56.945043	1	2009-01-01	\N	f		t
2494	Marlyson Clíngio Almeida Coutinho	marlysonclingio@hotmail.com	Maninho	@		eed344100105d60695468855cb0f60cb	f	\N	2011-11-24 19:26:24.074697	1	1995-01-01	\N	f		t
2597	Lukas camps	lukas.camps@gmail.com	luukamps	@Luukamps		0abd33e27b07c8f4047781e17ac90a08	f	\N	2011-11-25 16:10:07.394206	1	1996-01-01	\N	f	Lukas.camps@gmail.com	t
2230	Natanaelly Oliveira Almeida	natanaelly.oliveira@gmail.com	natanaelly	@		402ad690bbb3f24125cf2fe19a9ee056	f	\N	2011-11-23 23:39:20.255497	2	1992-01-01	\N	f		t
2495	Priscila Duarte	priflorzinha15@hotmail.com	Priscila	@		444e44b34f66e0bf7bcbd7cffd1c43e0	f	\N	2011-11-24 19:27:58.751093	2	1993-01-01	\N	f		t
2633	Francisco Lucilanio da Silva 	lucilanioevangelista@gmail.com	lucilanio	@		7f0d7de578e341c72284977cf6995ad0	f	\N	2011-11-26 10:53:19.538091	2	1986-01-01	\N	f		t
2196	Antonia Claudileide Lima da Silva	klaudileydejc@gmail.com	Dileide	@		bb898c2501d580721e271916e0de059e	f	\N	2011-11-23 20:16:24.82429	2	1992-01-01	\N	f	claudileidejc@yahoo.com.bt	t
2248	Sergimar Kennedy de Paiva Pinheiro	sergimarkennedy@hotmail.com	Kennedy	@		5005551a12249c777728edd800b45380	f	\N	2011-11-24 08:56:44.681937	1	1983-01-01	\N	f		t
3408	FABRICIO BARROSO DE SOUSA	fabriciopote@hotmail.com	FABRICIO B	\N	\N	4e0928de075538c593fbdabb0c5ef2c3	f	\N	2012-01-10 18:26:02.13803	0	1980-01-01	\N	f	\N	f
2496	Karolina Gomes	karolinagomes09@hotmail.com	-Kika-	@karolinagomes09		db39b658f28060bb368a22f73cc56f05	f	\N	2011-11-24 19:30:26.269541	2	1996-01-01	\N	f	karolinagomes09@hotmail.com	t
2643	Francisco Edson Martins Costa	martins_edson@yahoo.com.br	martins	@		f0881d743ce155fe9b1fcceca36a0b41	f	\N	2011-11-26 12:28:26.225026	1	1989-01-01	\N	f		t
2265	ITALO DE OLIVEIRA SANTOS	ITALO_07_@HOTMAIL.COM	ITALO DE OLIVEIRA	@ITALO_07		4d63d025e7bffa05bb9ab46f6f939870	f	\N	2011-11-24 10:02:05.423593	1	1992-01-01	\N	f	ITALO_07_@HOTMAIL.COM	t
2497	davi felipe soares	davidy_1996@hotmail.com	davidy	@		3e974d4af492913dfb0c186b6d2762bc	f	\N	2011-11-24 19:35:54.633128	1	1996-01-01	\N	f		t
3548	TIAGO LINO VASCONCELOS	tlino10@bol.com.br	TIAGO LINO	\N	\N	be3159ad04564bfb90db9e32851ebf9c	f	\N	2012-01-10 18:26:30.00432	0	1980-01-01	\N	f	\N	f
2280	Otávio Dantas Nascimento	odnascimento@hotmail.com	Otávio	@		92bc990a75bb2ce64d3614232c276c8e	f	\N	2011-11-24 10:12:29.266255	1	1995-01-01	\N	f		t
2498	jorge augusto	jorge_augusto1996@hotmail.com	jorgeaugusto	@		3cf424b562c400a59b4f9d2e518aaa92	f	\N	2011-11-24 19:42:31.903512	1	1997-01-01	\N	f		t
2665	Reginaldo dos Santos Melo	peristilo2008@hotmail.com	Reginaldo	@		82daa61b212da0c56243c7fe65a4c23c	f	\N	2011-11-26 15:06:10.934519	0	1972-01-01	\N	f		t
2293	antonio ricardo augusto silva	ric.augusto.sk8@hotmail.com	ricardo	@		70eb7d314d38ff988a6d90205612a4b4	f	\N	2011-11-24 10:16:26.904827	1	1994-01-01	\N	f		t
3549	TIAGO NASCIMENTO SILVA	tiago.crv@hotmail.com	TIAGO NASC	\N	\N	8f85517967795eeef66c225f7883bdcb	f	\N	2012-01-10 18:26:30.063247	0	1980-01-01	\N	f	\N	f
2302	EDSON ROBERVAL SERAFIM DE FREITAS	edson_de_freitas@yahoo.com.br	Roberval	@		1b53827c2371a61b1ce5b9b2268614c9	f	\N	2011-11-24 10:32:47.916927	1	1981-01-01	\N	f		t
2560	maria nathalia de andrade pessoa	nathalia-andrade20@hotmail.com	Nathy stronda	@strondanaty		1a59e5e32e09a57d22324cf83672fadd	f	\N	2011-11-25 10:02:02.695396	2	1995-01-01	\N	f	nathalia-andrade20@hotmail.com	t
2311	Andréia Cavalcante Rodrigues	andreiacavalcante@ifce.edu.br	dedeia	@		e52532431921f15ca72a753fc0347d69	f	\N	2011-11-24 10:43:06.973981	2	1980-01-01	\N	f		t
3409	FABRICIO DE FREITAS ALVES	alvesmf2@hotmail.com	FABRICIO D	\N	\N	fc8001f834f6a5f0561080d134d53d29	f	\N	2012-01-10 18:26:02.2762	0	1980-01-01	\N	f	\N	f
2319	José Igor de Brito Barros	joseigor27@hotmail.com	José Igor	@		3b3ac78869f6cc63ccc9f76666eba8b7	f	\N	2011-11-24 10:45:36.661601	1	1995-01-01	\N	f		t
2326	Marcelo Rodrigues de Sousa	marcellotea@hotmail.com	Marcelo	@		4e1f4a747f11e1b15fcc60b8fc3a6120	f	\N	2011-11-24 10:48:10.640599	1	1995-01-01	\N	f		t
2586	Raquel dos Santos 	raquelpotter1999@gmail.com	Raquelsantos	@		b979c6b5d50206f18a9161bc096f9939	f	\N	2011-11-25 15:12:10.482251	2	1999-01-01	\N	f		t
2671	Jacinta Maria Silva Rodrigues	jacsrodrigues@hotmail.com	Jacinta	@		31b4907324ebe73d2fb2532b6af71407	f	\N	2011-11-26 15:21:31.414388	2	1974-01-01	\N	f		t
2606	THIAGO BRUNO DE SOUSA BARBOSA	felipe-p62@hotmail.com	BRUNINHO	@		8aa36dc6e80f9b147bf3c16a48504b55	f	\N	2011-11-25 18:13:05.48639	1	2011-01-01	\N	f		t
2344	Jheymison de Lima Silva	jheyjhey20@hotmail.com	jheyjhey	@		60dd9bf0b16834a4426ea1ab10bf8cfa	f	\N	2011-11-24 11:21:51.316874	1	2011-01-01	\N	f		t
2346	Jefferson Luis Alves	gt_jefferson@hotmail.com	Jefferson	@		5dd8b2f88d2cba8b27f9f3a4a98899e8	f	\N	2011-11-24 11:23:10.003884	1	1995-01-01	\N	f		t
2348	paulo victor dos santos bezerra	paulobezerra31@gmail.com	baliado	@		d9ee971f4834cb5e04c2e6204e6bcd0b	f	\N	2011-11-24 11:25:27.474553	1	1994-01-01	\N	f	paulobezerra31@gmail.com	t
2351	Francisco Diego Lima Freitas	diego.freitas92@gmail.com	Freitasdl	@Freitasdl		050a7f7ec50f91b7864f861c5ef09e93	f	\N	2011-11-24 11:45:13.923953	1	1992-01-01	\N	f	diego.freitas92@gmail.com	t
2352	HHyeda Maria Cavalcante de Albuquerque	hyedaalbuquerque@yahoo.com	Hyeda Maria	@		c30c8653a3dc63a6aeda87d37bd2e9f4	f	\N	2011-11-24 11:45:58.946625	2	1967-01-01	\N	f		t
3410	FELIPE ALEXSANDER RODRIGUES CHAVES	felipe.alexsander@hotmail.com	FELIPE ALE	\N	\N	e0c641195b27425bb056ac56f8953d24	f	\N	2012-01-10 18:26:02.559435	0	1980-01-01	\N	f	\N	f
2353	Fátima Santana Oliveira	amitafebv@yahoo.com.br	Fátima	@		1d19893983cd791673b30b2ec1f4ccf2	f	\N	2011-11-24 11:48:16.883689	2	1953-01-01	\N	f		t
3411	FERNANDO DENES LUZ COSTA	deneslcosta@hotmail.com	FERNANDO D	\N	\N	28267ab848bcf807b2ed53c3a8f8fc8a	f	\N	2012-01-10 18:26:03.458449	0	1980-01-01	\N	f	\N	f
3412	FLAVIO CESA PEREIRA DA SILVA	t@t	FLAVIO CES	\N	\N	16c222aa19898e5058938167c8ab6c57	f	\N	2012-01-10 18:26:04.040897	0	1980-01-01	\N	f	\N	f
3413	FRANCISCO AMSTERDAN DUARTE DA SILVA	amster1305@hotmail.com	FRANCISCO 	\N	\N	f0adc8838f4bdedde4ec2cfad0515589	f	\N	2012-01-10 18:26:04.332531	0	1980-01-01	\N	f	\N	f
3414	FRANCISCO ARI CÂNDIDO DE OLIVEIRA FILHO	ariexpert@hotmail.com	FRANCISCO 	\N	\N	bd4c9ab730f5513206b999ec0d90d1fb	f	\N	2012-01-10 18:26:04.646172	0	1980-01-01	\N	f	\N	f
3415	FRANCISCO DANIEL BEZERRA DE CARVALHO	vanessacordeiro@oi.com.br	FRANCISCO 	\N	\N	7e7757b1e12abcb736ab9a754ffb617a	f	\N	2012-01-10 18:26:04.877339	0	1980-01-01	\N	f	\N	f
3416	FRANCISCO FERNANDES DA COSTA NETO	nennencfj@hotmail.com	FRANCISCO 	\N	\N	d0102317a9ea161bb4071ff33cf52072	f	\N	2012-01-10 18:26:05.109154	0	1980-01-01	\N	f	\N	f
3417	FRANCISCO GUSTAVO CAVALCANTE BELO	gustavobelo123@gmail.com	FRANCISCO 	\N	\N	497ab2ccd65eae7409c46f622c0226b9	f	\N	2012-01-10 18:26:05.251972	0	1980-01-01	\N	f	\N	f
3418	FRANCISCO LEANDRO HENRIQUE MOREIRA	flhm.le@oi.com.br	FRANCISCO 	\N	\N	de9fc06533492083919cfd7d8d9aec89	f	\N	2012-01-10 18:26:05.479511	0	1980-01-01	\N	f	\N	f
2532	Emanuele	emanuele_suelyn@hotmail.com	Emanuele	@		753a006171fd9847c29a7fa634c35059	f	\N	2011-11-24 22:07:22.91746	2	2011-01-01	\N	f	emanuele_suelyn@hotmail.com	t
2682	Murilo Andrade do Nascimento	murilo.otaku@hotmail.com	Mumumu	@		8d43d1d401d475c04c8e43a359cc998a	f	\N	2011-11-26 16:33:08.617909	1	1994-01-01	\N	f		t
2206	Paulo Delano	delanosantos14@hotmail.com	Delano	@delansant		8eb8bfa91e27ebf40ca7f0d24cda876a	f	\N	2011-11-23 21:08:52.412476	1	1997-01-01	\N	f	delanosantos14@hotmail.com	t
2135	Ítalo de Sousa Oliveira	italodsousa@gmail.com	italodsousa	@		e6e1fda7bc2a2590d7cb8140cfe32ba0	f	\N	2011-11-23 18:06:35.472896	1	1990-01-01	\N	f	italodsousa@gmail.com	t
2075	DIAKYS JULIO LAURINDO DA SILVA	diakysjulio@hotmail.com	"não te importa"	@diakysjulio		e8e8d59869f4ee3f001816d50c9bf26e	f	\N	2011-11-23 17:16:19.364445	1	1993-01-01	\N	f		t
1726	Cinthya Maia Alves	cinthyakiss@hotmail.com	ciicyhw	@		33a17896eee2844968fba82ce816db35	f	\N	2011-11-23 09:06:12.911991	2	1995-01-01	\N	f	cinthyahw@gmail.com	t
2501	Marcelo Furtado	sk.mabuia@hotmail.com	marcelo	@		302672ec16b05bb650fbdf8446d017c8	f	\N	2011-11-24 19:44:04.730083	1	1984-01-01	\N	f		t
2502	Eudázio Sampaio	eudaziosampaio50@hotmail.com	Eudázio Sampaio	@eudazio1		df7447af3d83b9fa88cfaee618d9cdd8	f	\N	2011-11-24 19:46:24.359714	1	1996-01-01	\N	f		t
2077	Vitória Deyse da Rocha Martins	vitoriadeyse@hotmail.com	Vitória	@		f8394243a807c7ba92ec06ba05e411ac	f	\N	2011-11-23 17:16:53.786814	2	1995-01-01	\N	f	vitoriadeyse@hotmail.com	t
2152	Hagyllys Themoskenko de Oliveira Sales Bernardino	ragyllys_osb@hotmail.com	Numero 07	@		52f648f531a163ea817da8b5cd0eca75	f	\N	2011-11-23 18:36:13.175472	1	2009-01-01	\N	f		t
3550	VALRENICE NASCIMENTO DA COSTA	valrenice@gmail.com	VALRENICE 	\N	\N	cfa0860e83a4c3a763a7e62d825349f7	f	\N	2012-01-10 18:26:30.231629	0	1980-01-01	\N	f	\N	f
2078	Edislande de Oliveira Matias	edislandeoliveira@hotmail.com	tetézinho	@h		22f1d9447b609e6036b3b98807a16378	f	\N	2011-11-23 17:17:37.549051	1	1992-01-01	\N	f	tetezinho.mathias@facebook.com	t
3551	VICTOR ALISSON MANGUEIRA CORREIA	kurosakivictor@hotmail.com	VICTOR ALI	\N	\N	182be0c5cdcd5072bb1864cdee4d3d6e	f	\N	2012-01-10 18:26:30.285826	0	1980-01-01	\N	f	\N	f
3552	VICTOR DE OLIVEIRA MATOS	victormanch@hotmail.com	VICTOR DE 	\N	\N	d5cfead94f5350c12c322b5b664544c1	f	\N	2012-01-10 18:26:30.337686	0	1980-01-01	\N	f	\N	f
2079	Sayonara Rodrigues de Paulo	sayonarasnoopy@hotmail.com	Sayonara	@		890bf400bac6a162e410a6070804b838	f	\N	2011-11-23 17:18:43.801284	2	1994-01-01	\N	f	sayonararodriguess@hotmail.com	t
3553	VICTOR LUIS VASCONCELOS DA SILVA	vitorluis@hotmail.com	VICTOR LUI	\N	\N	94c7bb58efc3b337800875b5d382a072	f	\N	2012-01-10 18:26:30.416435	0	1980-01-01	\N	f	\N	f
3554	VLAUDSON DA CRUZ RAMALHO	crvladson@gmail.com	VLAUDSON D	\N	\N	efe937780e95574250dabe07151bdc23	f	\N	2012-01-10 18:26:30.572653	0	1980-01-01	\N	f	\N	f
2080	clenio	clenio.0122@gmail.com	clenio	@		03b531ae8c0864275207dd4cf612f94b	f	\N	2011-11-23 17:23:15.550717	1	1992-01-01	\N	f		t
2231	Paulo Mateus	mateus.moura@hotmail.com	Paulo Mateus	@SrMouraSilva		b2b110af26da7e6073e2eff55dccc29c	f	\N	2011-11-23 23:43:51.638096	1	1994-01-01	\N	f	mateus.moura@hotmail.com	t
3555	WASHINGTON LUIZ DE OLIVEIRA	wasluizoliveira@bol.com.br	WASHINGTON	\N	\N	0d3180d672e08b4c5312dcdafdf6ef36	f	\N	2012-01-10 18:26:31.195324	0	1980-01-01	\N	f	\N	f
2081	Anderson Sousa Rodrigues	andersonsousa.asr@gmail.com	coxinha	@		3ad08244e815b50d2b3fdb91639ea60c	f	\N	2011-11-23 17:23:15.974606	1	1995-01-01	\N	f		t
2342	Maria Édna Lesca de Araújo	edna_gata.2010@hotmail.com	Maria Édna	@		25d4bf55e9d3dfc6078fb9ef172c6e49	f	\N	2011-11-24 11:20:57.828577	2	1997-01-01	\N	f		t
2186	Mayara Jessica Cavalcante Freitas	mayarajessica20@gmail.com	Mayrinha	@		2f95b0dc041a1baa902b35d05c95855e	f	\N	2011-11-23 19:56:36.599989	2	1994-01-01	\N	f		t
2084	Sayonara Rodrigues de Paulo	sayonara_snoopy@hotmail.com	Sayonara	@		9d925919e7d8c01cb9ed453d2d1e42ff	f	\N	2011-11-23 17:27:37.584888	2	1994-01-01	\N	f	sayonararodriguess@hotmail.com	t
2197	Francisco Adriano Xavier Rocha	adrianorochainfor@hotmial.com	adriano	@		4b9f15179ecd66dfe05ce9f0b54ca641	f	\N	2011-11-23 20:24:33.055474	1	1984-01-01	\N	f	adrianorochainfor@hotmail.com	t
2249	Amauri Aires Bizerra Filho	amauriairesfilho@gmail.com	Amauri	@		7f8bcc0a768ebb1130249c06ed2cf0d1	f	\N	2011-11-24 08:57:35.81158	1	1993-01-01	\N	f	liger_i@hotmail.com	t
2266	Silvana Holanda Da Silva	silvana_holanda@yahoo.com.br	Silvana	@		d38b2c4ac539b5c2b8bee92bf30d88b2	f	\N	2011-11-24 10:04:25.09848	2	2011-01-01	\N	f		t
2561	Belchior Torres do Nascimento	belchior.ar@gmail.com	Belchior	@belchior_br		50dd20d0c94eda4cce84d3fab38f2b42	f	\N	2011-11-25 10:03:30.937518	1	1985-01-01	\N	f	belchior.ar@gmail.com	t
2281	Flaviane Passos Nascimento	flavianepassos@hotmail.com	Flaviane	@		c7856f38583f45afa50416854cf14a2e	f	\N	2011-11-24 10:12:56.647524	2	2011-01-01	\N	f		t
2634	Francisco Rene da Silva Santana	germano_nuneslp@hotmail.com	Francisco	@		991646e4325262d9654f8d50f709dddb	f	\N	2011-11-26 10:53:28.687961	1	1991-01-01	\N	f		t
2294	joana dark de souza	souzajoana25@gmail.com	joana.	@		6ce5ffdf890abecd6cdb9879f6170e87	f	\N	2011-11-24 10:19:34.675777	2	1986-01-01	\N	f		t
2303	Jose Hugo Aguiar Sousa	josehugo18@hotmail.com	Hugoaguiar	@		cd7909d4ba511cfc6396bb47baae90d0	f	\N	2011-11-24 10:34:14.417824	1	1988-01-01	\N	f		t
3419	GEORGE GLAIRTON GOMES TIMBÓ	gaga1492@yahoo.com.br	GEORGE GLA	\N	\N	6ea9ab1baa0efb9e19094440c317e21b	f	\N	2012-01-10 18:26:06.448303	0	1980-01-01	\N	f	\N	f
2320	Giovanna Alves rodrigues	giovaninha.ar@gmail.com	Giovana	@		17fb95a7ff5ee37a19f340ab61838c7d	f	\N	2011-11-24 10:45:55.802256	2	2011-01-01	\N	f		t
2327	Willielda Oliveira	willielda_o_@hotmail.com	willielda	@		75a6250f29d6b43b15349aea4bb0cddb	f	\N	2011-11-24 10:49:09.742261	2	1996-01-01	\N	f		t
2672	Tiago Duarte Rodrigues Ferreira	haven_brujah@hotmail.com	Mei Pão	@		f569b11138d103a1c528ab3d773a163d	f	\N	2011-11-26 15:27:05.971944	1	1987-01-01	\N	f		t
2333	jeffson oliveira de sena barbosa	jeffsonsurf@hotmail.com	jeffson	@		b44ec514128681189c359e2f4d714962	f	\N	2011-11-24 11:04:40.726251	1	1992-01-01	\N	f		t
3420	GILDEILSON DOS SANTOS MENDONÇA	gildeilsonmendonca@hotmail.com	GILDEILSON	\N	\N	a666587afda6e89aec274a3657558a27	f	\N	2012-01-10 18:26:06.833208	0	1980-01-01	\N	f	\N	f
2347	Antonio Victor Medeiros da Silva	victor_gaiatinhon@hotmail.com	Victor	@		4a1505e0744b2849f216a6ae5d7bd94b	f	\N	2011-11-24 11:24:01.62268	1	2011-01-01	\N	f		t
3421	GLAILSON MONTEIRO LEANDRO	kailson_@hotmail.com	GLAILSON M	\N	\N	62f0202c4fb99f23d0e4583ef192755d	f	\N	2012-01-10 18:26:07.645553	0	1980-01-01	\N	f	\N	f
3422	GUILHERME DA SILVA BRAGA	heavy_guill@hotmail.com	GUILHERME 	\N	\N	8c416bc362d5966e00e3ba78ddd4c57d	f	\N	2012-01-10 18:26:08.323972	0	1980-01-01	\N	f	\N	f
3423	GUTEMBERG MAGALHAES SOUZA	gmsflp10@hotmail.com.br	GUTEMBERG 	\N	\N	860320be12a1c050cd7731794e231bd3	f	\N	2012-01-10 18:26:08.527206	0	1980-01-01	\N	f	\N	f
3424	HALECKSON HENRICK CONSTANTINO CUNHA	henrick_cc@hotmail.com	HALECKSON 	\N	\N	cdce9293eb8b003cb4b089d0420c2c76	f	\N	2012-01-10 18:26:08.69608	0	1980-01-01	\N	f	\N	f
3425	HANNAH PRESTAH LEAL RABELO	hannahrabelobol.com.br	HANNAH PRE	\N	\N	94c7bb58efc3b337800875b5d382a072	f	\N	2012-01-10 18:26:08.899644	0	1980-01-01	\N	f	\N	f
3426	HELIONEIDA MARIA VIANA	helioneida-viana@hotmail.com	HELIONEIDA	\N	\N	fcc1293c14bcad6f7f6cf6d11a4df64d	f	\N	2012-01-10 18:26:09.237073	0	1980-01-01	\N	f	\N	f
3427	HELTON ATILAS ALVES DA SILVA	helton.atilas@hotmail.com	HELTON ATI	\N	\N	afd4836712c5e77550897e25711e1d96	f	\N	2012-01-10 18:26:09.444197	0	1980-01-01	\N	f	\N	f
3556	WEMILY BARROS NASCIMENTO	wbn.power@hotmail.com	WEMILY BAR	\N	\N	109a0ca3bc27f3e96597370d5c8cf03d	f	\N	2012-01-10 18:26:31.300623	0	1980-01-01	\N	f	\N	f
3557	WILLIAM CLINTON FREIRE SILVA	willianclinton@hotmail.com	WILLIAM CL	\N	\N	68264bdb65b97eeae6788aa3348e553c	f	\N	2012-01-10 18:26:31.452751	0	1980-01-01	\N	f	\N	f
3428	HERBET SILVA CUNHA	herbetsc@hotmail.com	HERBET SIL	\N	\N	fccb3cdc9acc14a6e70a12f74560c026	f	\N	2012-01-10 18:26:09.619607	0	1980-01-01	\N	f	\N	f
576	Ana Samara Soares Pontes	anasamarasp@hotmail.com	Ana Samara	@ana_samara18		514eea530891d207e8c5ea37140e3217	t	2012-07-16 12:16:03.567775	2011-11-04 09:21:12.215145	2	1993-01-01	\N	f	anasamarasp@hotmail.com	t
2213	Diego Guilherme de Souza Moraes	digui.info@gmail.com	Diego Guilherme	@		c44f8c9c9c9f57b1dcf9438305efde77	f	\N	2011-11-23 21:41:26.452277	1	2011-01-01	\N	f	digui.info@gmail.com	t
2161	JAQUELINE DE AQUINO SILVA	jackmorhan@gmail.com	JAQUELINE	@		b1829ff0107437055c2b03d71aa1a0e0	f	\N	2011-11-23 18:49:07.695111	2	1982-01-01	\N	f		t
2072	Santiago	aquinorei@hotmail.com	santos	@		7c69c45afa66b99434fdc34a597a2ef0	f	\N	2011-11-23 17:13:12.546398	1	2011-01-01	\N	f		t
2057	AMANDA MENDONCA MENEZES	amandastylerebol@hotmail.com	AMANDA	@		23effeffaac9caba12c06f42eb50b50b	f	\N	2011-11-23 16:42:23.970947	2	1995-01-01	\N	f		t
2035	JOAO FONSECA PINTO NETO	mrtoshil@hotmail.com	JOAO NETO	@		9c9608c33cf3d47fbd1eb3f0b616cda2	f	\N	2011-11-23 16:08:42.466654	1	1995-01-01	\N	f		t
1965	Bruna Maria Nunes Ferreira	bruna_nunes18@hotmail.com	Bruna Nunes	@		1445e3b3174bc6cf9c2881a56710cc62	f	\N	2011-11-23 15:02:19.047264	2	2011-01-01	\N	f		t
1629	cícera maria diamante martins	ciceradiamante@gmail.com	consciência	@		d2ec3bf6f936ab1514aa80ad33af448c	f	\N	2011-11-22 20:38:42.459702	2	1995-01-01	\N	f		t
3558	WILLIAM PEREIRA LIMA	williamifce@gmail.com	WILLIAM PE	\N	\N	f7b7f0d97ccd4537a8a3cde5df36672c	f	\N	2012-01-10 18:26:31.506699	0	1980-01-01	\N	f	\N	f
1515	Flavio de Oliveira Chagas	flaviotuf90@hotmail.com	Flávio	@		706bc8a4ad5c0948b0bf69875f101172	t	2011-11-24 11:53:15.668793	2011-11-22 17:11:34.327594	1	1994-01-01	\N	f	flaviotuf90@hotmail.com	t
1418	Francisco Eudasio Alves da Silva	eudasioamav@hotmail.com	Eudasio	@		a54875585cb11046ba8420f6db3c8bdf	t	2011-11-24 11:53:18.968348	2011-11-22 16:41:54.051903	1	1975-01-01	\N	f		t
1340	Alan Ferreira Silva Lima	alanferrer19@hotmail.com	Alan Ferrer	@		9180beaa3ce5c981f0979c1736e0ded1	f	\N	2011-11-22 11:15:25.351523	1	1989-01-01	\N	f	alanferrer19@hotmail.com	t
1259	Jéssica	dhet_devilducks@hotmail.com	jeca aquino	@jessyaquino		272891a2fe0082d17c47cd0a948cc1ef	t	2011-11-24 11:53:24.340383	2011-11-22 09:44:17.298903	1	1993-01-01	\N	f	dhet_devilducks@hotmail.com	t
1225	Mikaely Severino Pessoa	mikaelly95@live.com	mikaely	@		2796e477b011b575ac5c5dafaf434d8b	t	2011-11-24 11:53:40.140953	2011-11-22 09:33:41.125306	2	1995-01-01	\N	f		t
2355	César Henrique Pedro de Sousa	aracoiaba22@pob.com.br	César Henrique	@		561aa199072e5ac4ab251fb932272a8e	f	\N	2011-11-24 11:53:40.589327	1	1987-01-01	\N	f		t
2588	nauriello almeida de andrade	nauand@gmail.com	nauriello	@naurielloandrad		55339922b43c310248a1821034150c25	f	\N	2011-11-25 15:21:47.63331	1	1968-01-01	\N	f		t
3559	WILQUEMBERTO NUNES PINTO	wilquem_np@hotmail.com	WILQUEMBER	\N	\N	b6d3de368dbcddd61ca4c434b314ff7e	f	\N	2012-01-10 18:26:31.713212	0	1980-01-01	\N	f	\N	f
1139	Iago Maciel Mendes	num.yagomaciel@gmail.com	Iago M	@Iago_Maciel	http://www.tumblr.com/blog/iagomaciel	ed612fce7042a25ef1764a2ae4405384	f	\N	2011-11-21 15:56:53.544641	1	1993-01-01	\N	f	num_yagomaciel@hotmail.com	t
1107	SIlmara Evaristo	evaristosilmara@gmail.com	Silmara Evaristo	@		74df1e80e58448bdc2e3e69f4338e1d0	t	2011-11-24 11:53:43.529856	2011-11-21 10:32:39.865693	2	2011-01-01	\N	f	silmaraevaristo@hotmail.com	t
983	francisco cledson araujo oliveira	cledson.f@hotmail.com	cl3dson	@		353239aaabd37f90dd34ff3329dfb33e	f	\N	2011-11-17 20:40:50.743125	1	1992-01-01	\N	f		t
943	ANDREIA LOPES DO MONTE	andreialopez50@gmail.com	Andreia	@lopez_andreia		19ea53638a503bc28a41472a75a0afed	t	2011-11-24 11:53:50.422767	2011-11-17 03:00:49.438004	2	1988-01-01	\N	f	andreialopez50@gmail.com	t
587	Christyan Anderson Candido Brilhante	christyananderson@hotmail.com	ANDERSON BRILHANTE	@		81f52bd0628956cf7c98999c2636f144	t	2011-11-24 11:53:55.681822	2011-11-07 12:02:32.091297	1	2011-01-01	\N	f	CHRISTYANANDERSON@HOTMAIL.COM	t
544	Shayllingne de Oliveira Ferreira 	ShayllingneOliveiraaa@Gmail.com.br	Liguelig	@		6643c0f568976d5f842d9cc87db087c4	f	\N	2011-11-04 09:01:53.521862	2	2011-01-01	\N	f		t
476	flaviane	flavyiemillinha@gmail.com	flavia	@		f6a98dce5bd7a06e33b0ad4d635437fe	f	\N	2011-11-03 09:23:48.608751	2	1996-01-01	\N	f		t
464	Iane Roberta	robeertiinhah@hotmail.com	robertýnhah	@		eceb30ff44c01e2f4939c75106df8e77	t	2011-11-24 11:54:03.888953	2011-11-02 12:29:39.177724	2	1994-01-01	\N	f	robeertiinhah@hotmail.com	t
339	RAIZA ARAÚJO DE SOUSA	raizadesousa@hotmail.com	raizha	@		131d9083ed74ba09d80d80ab178b8239	f	\N	2011-10-17 12:32:38.050206	2	2011-01-01	\N	f		t
324	george de sousa ferreira	georgeferreira6@gmail.com	irmazinho	@		d6ca2a91dbbb2a0265fd55c6ca150013	f	\N	2011-10-15 01:19:32.362143	1	1984-01-01	\N	f	georgeferreira6@gmail.com	t
3560	YCARO BRENNO CAVALCANTE RAMALHO	ycarob.cavalcante@hotmail.com	YCARO BREN	\N	\N	ee6a6dc5fd9550ab48d6735c1eaa976a	f	\N	2012-01-10 18:26:31.841672	0	1980-01-01	\N	f	\N	f
2468	Cirley Barbosa	barbosacirley@yahoo.com.br	Cirley	@		ecffc6030cafdfa777665fbb51121c0f	f	\N	2011-11-24 17:07:16.559766	2	1993-01-01	\N	f		t
2358	Diego da Paz Medeiros	didimedeiros244@gmail.com	Diego Medeiros	@		01fb1198e1eccb826b562224d2acb31b	f	\N	2011-11-24 11:57:41.167836	1	1992-01-01	\N	f		t
2608	Francisco Leonardo dos Santos Lima	dmenor.leo@gmail.com	dmenor	@		50b67664cd5697dc216681c1195f9c09	f	\N	2011-11-25 18:13:29.200841	1	1995-01-01	\N	f	dmenor.leo@gmail.com	t
2541	Alisson Mota Pereira	allisonpereiramota@hotmail.com	Alisson	@		9d5a81b66eb1c4b4779aaec1e85077ec	f	\N	2011-11-25 08:59:54.941289	1	1993-01-01	\N	f		t
2469	Josué david vale de aquino 	david.aquino02@hotmail.com	Josué aquino 	@		42162124726552379c05ce51906057e9	f	\N	2011-11-24 17:07:35.363024	1	1995-01-01	\N	f	davi_batima@hotmail.com	t
2470	FRANCISCO ADAIAS GOMES DA SILVA	adaiasgomes314@gmail.com	adaias	@adaiasgomes		8c11caa0386e580549b18c3c0dbbd408	f	\N	2011-11-24 17:15:41.043393	1	1992-01-01	\N	f	adaiasgomes@hotmail.com	t
2673	Teocélio Monteiro Guimarães	federalsys@hotmail.com	federal	@		18ea9820bbda2d9e5758966cf6c92af7	f	\N	2011-11-26 15:46:17.391827	1	1970-01-01	\N	f		t
2471	alexandro silva do nascimento	tecnic.alexsilva@gmail.com	alexandro	@		dc02be5cd6c185130132e7f618d7fd9d	f	\N	2011-11-24 17:56:52.34653	1	1984-01-01	\N	f		t
3429	IAGO BARBOSA DE CARVALHO LINS	rhcpiagoiron@hotmail.com	IAGO BARBO	\N	\N	a4a042cf4fd6bfb47701cbc8a1653ada	f	\N	2012-01-10 18:26:09.860443	0	1980-01-01	\N	f	\N	f
2054	ILANNA EMANUELLE MUNIZ SILVA	ilanna.emanuelle@hotmail.com	Ilanna	@		1fb4eb6f68e3e53db25fc043732c40c2	f	\N	2011-11-23 16:34:54.770303	2	1994-01-01	\N	f		t
3430	ISAAC THIAGO OLIVEIRA CAVALCANTE	isaaccavalcante@ymail.com	ISAAC THIA	\N	\N	86ebb61cbb35df79d2227147269fb7e9	f	\N	2012-01-10 18:26:10.538973	0	1980-01-01	\N	f	\N	f
3431	ISRAEL SOARES DE OLIVEIRA	genina102010@hotmail.com	ISRAEL SOA	\N	\N	7fa732b517cbed14a48843d74526c11a	f	\N	2012-01-10 18:26:10.867507	0	1980-01-01	\N	f	\N	f
3432	ITALO MESQUITA VIEIRA	italo_mbs@hotmail.com	ITALO MESQ	\N	\N	6602294be910b1e3c4571bd98c4d5484	f	\N	2012-01-10 18:26:11.373675	0	1980-01-01	\N	f	\N	f
3433	IVNA SILVESTRE MONTEFUSCO	ivna.silvestre@hotmail.com	IVNA SILVE	\N	\N	38b3eff8baf56627478ec76a704e9b52	f	\N	2012-01-10 18:26:11.648033	0	1980-01-01	\N	f	\N	f
3434	JAMILLE DE AQUINO ARAÚJO NASCIMENTO	jamilles2@hotmail.com	JAMILLE DE	\N	\N	1068c6e4c8051cfd4e9ea8072e3189e2	f	\N	2012-01-10 18:26:11.887457	0	1980-01-01	\N	f	\N	f
2360	José Maria da Paz	josemaria.paz@gmail.com	José Maria	@		1bbf870ef1500fd949c430ce04952abb	f	\N	2011-11-24 11:59:38.376154	1	1989-01-01	\N	f		t
2570	FRANCISCO ROGER GARCIA DE ALMEIDA	frogergarci@gmail.com	Lodger	@		22e5b41cc90b74a2dcfa87b3b131374e	f	\N	2011-11-25 11:42:53.374068	1	2011-01-01	\N	f	rogergarci@live.com	t
2361	manuel agapito de sousa	manuel.agapito@yahoo.com.br	coleguinha	@		f8fb74e410c54cad5fb45e7034fc9cf0	f	\N	2011-11-24 11:59:41.128543	1	1991-01-01	\N	f		t
2534	Ingrid Nascimento dos Santos	fabiola_festa15@hotmail.com	Ingrid	@		db762d52589fcaab99d04868adad9d92	f	\N	2011-11-24 22:24:39.223223	2	1995-01-01	\N	f		t
2636	Germano Nunes	g3rm4n0lp@gmail.com	germano	@		25801c524f239f887da93818307e686a	f	\N	2011-11-26 10:55:57.389957	1	1991-01-01	\N	f		t
2362	Darlhy Alcântara de Sousa	dhy100@hotmail.com	Volverine	@		9b3fad1b19de417233c8cb9688cf9869	f	\N	2011-11-24 12:00:16.905629	1	1994-01-01	\N	f		t
3536	ROMULO DA SILVA GOMES	romulo.ifet@gmail.com	ROMULO DA 	\N	\N	18d8042386b79e2c279fd162df0205c8	f	\N	2012-01-10 18:26:28.618827	0	1980-01-01	\N	f	\N	f
2472	Jjuliana Fernandes Mendonça	juliana.fernadesjr@hotmail.com	juuh'fernandes	@		9d98ce6d1ec5f731d2d1b18bdc0a01df	f	\N	2011-11-24 18:15:52.139762	2	1996-01-01	\N	f		t
2642	José Daniel da Silva Carvalho	danielcarvalhotj@hotmail.com	Imperador	@		d2b30bdf2b0e7e3cd8cd983b6198f59e	f	\N	2011-11-26 12:21:23.178398	1	1988-01-01	\N	f		t
2364	Sabrina dos Santos oliveira	sabrina-sant@hotmail.com	Sabrina	@		32e848cd76891dc0b5edb36817a7d3b6	f	\N	2011-11-24 12:01:55.350473	2	1992-01-01	\N	f		t
2563	Maria Vanúzia Ferreira da Silva	vanuziasdasilva@hotmail.com	Vanúsia	@		48a2faaa1d6961baeac0de1ce26d4764	f	\N	2011-11-25 10:32:37.857582	0	1989-01-01	\N	f		t
2473	Ana Hingrid Andrade do Nascimento	hingridh_tadatuf@hotmail.com	anna'hingriid	@		9a71191976886fd9509f6eed91494e56	f	\N	2011-11-24 18:26:59.059348	2	1996-01-01	\N	f		t
2365	elane souza soares	elane-soares@hotmail.com	elane.	@		e934aa872c7204a172c26b15ecf7b9da	f	\N	2011-11-24 12:01:57.799455	2	1992-01-01	\N	f		t
3537	ROMULO LOPES FRUTUOSO	romulo519@hotmail.com	ROMULO LOP	\N	\N	322105f221a7c3adf19e096196318625	f	\N	2012-01-10 18:26:28.670012	0	1980-01-01	\N	f	\N	f
2474	Pedro lucas bezerra porto	peter_potter@hotmail.com	peelungaa	@		08e7c3789b697931299eb7a5b2998063	f	\N	2011-11-24 18:30:13.201661	2	1996-01-01	\N	f		t
2366	Maria Gardênia Souda dos Santos	gardeniace88@hotmail.com	Gardênia	@		a8bdbf2f54fd0cab4a7582d95d8d1177	f	\N	2011-11-24 12:02:18.461873	2	1991-01-01	\N	f		t
2596	Paulo  Alexandre Costa Siqueira 	alexcosta446@gmail.com	alexcosta	@		ab1fcbe8adfeff036d742aaf7772fd87	f	\N	2011-11-25 15:54:51.447021	1	1977-01-01	\N	f		t
2664	BRUNO DEYSON BRAGA COSTA	nAOTEMEMAIL@GMAIL.COM	BRUNO DEYSON	@		7191eaeea16aa9ad268f823d4a003e29	f	\N	2011-11-26 14:49:02.050652	1	1993-01-01	\N	f		t
2479	brena araujo de mesquita	brenahtasapeka@hotmail.com	brennynha	@		113a6c5a81d30b85a8297e444ce92a01	f	\N	2011-11-24 18:35:06.454401	2	1996-01-01	\N	f		t
2657	Romário Santos de Abreu	romario.santos12@yahoo.com	romario	@		16fea7104bc868bc9acd678ddc1b00cd	f	\N	2011-11-26 14:22:43.263653	1	1990-01-01	\N	f		t
3435	JARDEL DAS CHAGAS RODRIGUES	jardel_19@hotmail.com	JARDEL DAS	\N	\N	1ff1de774005f8da13f42943881c655f	f	\N	2012-01-10 18:26:11.987972	0	1980-01-01	\N	f	\N	f
2368	Andrey Araujo Vera Cruz	andreyveracruz@hotmail.com	Andrey	@		a646dea12c22d82e35d24e584b57553b	f	\N	2011-11-24 12:02:58.752654	1	1992-01-01	\N	f		t
2616	nario rafael claudino dos santos	nario_faizu@yahoo.com.br	nario.	@		e3efaaefb263de67ce1049536df005bb	f	\N	2011-11-25 19:54:14.444827	1	1992-01-01	\N	f		t
2481	Karem Campos	karen-gata-9@live.com	Kaah Camp's	@		cd40fc148cfb36a1179d0ba6dcd6f0bb	f	\N	2011-11-24 18:40:26.633471	2	1997-01-01	\N	f		t
2369	Francisca Soraia Martins do Nascimento	soraya17.martins@gmail.com	Soraya	@		d49c568fb794f65ba71dc2ee83c07723	f	\N	2011-11-24 12:03:29.821884	2	1992-01-01	\N	f		t
2674	Francisco Charlisson	chacha_ogatinha@hotmail.com	Chacha	@		12a17b541da116ed91a05fcf2ea3be7b	f	\N	2011-11-26 15:46:45.341772	0	1996-01-01	\N	f		t
2681	Fernando da Silva Lima	nando-nandonando@live.com	Fernando	@		845199ac64e71926607138102ae870ec	f	\N	2011-11-26 16:12:12.443703	1	1993-01-01	\N	f		t
3436	JARDEL MAX SILVEIRA PINTO	jardel_max@hotmail.com	JARDEL MAX	\N	\N	c203d8a151612acf12457e4d67635a95	f	\N	2012-01-10 18:26:12.106381	0	1980-01-01	\N	f	\N	f
3538	ROSEANNE PAIVA DA SILVA	roseannepaiva@gmail.com	ROSEANNE P	\N	\N	9f396fe44e7c05c16873b05ec425cbad	f	\N	2012-01-10 18:26:28.823241	0	1980-01-01	\N	f	\N	f
2372	micael marcos carvalho de souza	micael--marcos@hotmail.com	micael	@		3aedfa40c54adf134acaf9dfea192cf2	f	\N	2011-11-24 12:03:52.650563	1	1994-01-01	\N	f		t
2487	Eli Samuel silva almeida	samuelocara2009@hotmail.com	samuin	@		de00a1d690b0cb2746d56cf4ab0c0e0b	f	\N	2011-11-24 18:50:08.24816	1	1996-01-01	\N	f		t
3539	SAMARA SOARES DE LIMA	samara_aunika@hotmail.com	SAMARA SOA	\N	\N	f234f727bf9a63751828c0b65552bb43	f	\N	2012-01-10 18:26:28.975369	0	1980-01-01	\N	f	\N	f
3533	ROBSON SILVA PORTELA	robgolrsp@hotmail.com	ROBSON SIL	\N	\N	82489c9737cc245530c7a6ebef3753ec	f	\N	2012-01-10 18:26:28.462347	0	1980-01-01	\N	f	\N	f
3437	JÉSSICA GOMES PEREIRA	jessk.gms@gmail.com	JÉSSICA G	\N	\N	6d27f6c8ce59e37118e1a539e04c05f2	f	\N	2012-01-10 18:26:13.462068	0	1980-01-01	\N	f	\N	f
2375	Nailton de Oliveira Alves	pittyalves@hotmail.com	Pitty Alves	@		5d98d3ba00f7b9a6747e18cdc61e2dbe	f	\N	2011-11-24 12:04:21.673306	1	1991-01-01	\N	f		t
2376	katryna santos da silva	katryna-ss1@live.com	katryna	@		a246159c7e26fbc942129337f7e3b7b3	f	\N	2011-11-24 12:04:37.917846	2	1992-01-01	\N	f		t
3438	JESSIMARA DE SENA ANDRADE	jessimara@oi.com.br	JESSIMARA 	\N	\N	53e3a7161e428b65688f14b84d61c610	f	\N	2012-01-10 18:26:13.693546	0	1980-01-01	\N	f	\N	f
3439	JHON MAYCON SILVA PREVITERA	j_may_con@hotmail.com	JHON MAYCO	\N	\N	45fbc6d3e05ebd93369ce542e8f2322d	f	\N	2012-01-10 18:26:13.917418	0	1980-01-01	\N	f	\N	f
3440	JOÃO GOMES DA SILVA NETO	joao.gsneto@gmail.com	JOÃO GOME	\N	\N	bf9e9339255666283a63d773685e6d79	f	\N	2012-01-10 18:26:14.239518	0	1980-01-01	\N	f	\N	f
3441	JOÃO GUILHERME COLOMBINI SILVA	joao.guil.xd@gmail.com	JOÃO GUIL	\N	\N	b06d54c275ab7c807e86ad01cb519cbd	f	\N	2012-01-10 18:26:14.443498	0	1980-01-01	\N	f	\N	f
3442	JOÃO HENRIQUE RODRIGUES DOS SANTOS	henriquecqsantos99@hotmail.com	JOÃO HENR	\N	\N	9bf31c7ff062936a96d3c8bd1f8f2ff3	f	\N	2012-01-10 18:26:14.584009	0	1980-01-01	\N	f	\N	f
3443	JOÃO LUCAS DE FREITAS MATOS	lucas.freitas.matos@hotmail.com	JOÃO LUCA	\N	\N	e744f91c29ec99f0e662c9177946c627	f	\N	2012-01-10 18:26:14.763961	0	1980-01-01	\N	f	\N	f
3444	JOAO OLEGARIO PINHEIRO NETO	olegarioifce@hotmail.com	JOAO OLEGA	\N	\N	d2ed45a52bc0edfa11c2064e9edee8bf	f	\N	2012-01-10 18:26:14.879015	0	1980-01-01	\N	f	\N	f
3445	JOELSON FERREIRA DA SILVA	joellson_j@yahoo.com.br	JOELSON FE	\N	\N	38af86134b65d0f10fe33d30dd76442e	f	\N	2012-01-10 18:26:15.333047	0	1980-01-01	\N	f	\N	f
3446	JOELSON FREITAS DE OLIVEIRA	jhoelsonmd@hotmail.com	JOELSON FR	\N	\N	94a3abe2f525a4d7126df846a6973f9b	f	\N	2012-01-10 18:26:15.487591	0	1980-01-01	\N	f	\N	f
3447	JOHN DHOUGLAS LIRA FREITAS	johndhouglas@gmail.com	JOHN DHOUG	\N	\N	4ffce04d92a4d6cb21c1494cdfcd6dc1	f	\N	2012-01-10 18:26:15.581671	0	1980-01-01	\N	f	\N	f
3448	JONAS RODRIGUES VIEIRA DOS SANTOS	jonascomputacao@gmail.com	JONAS RODR	\N	\N	c997a606483dd82bdeb8263bc6480f01	f	\N	2012-01-10 18:26:15.885755	0	1980-01-01	\N	f	\N	f
3449	JORGE FERNANDO RAMOS BEZERRA	marvinjfpg@hotmail.com	JORGE FERN	\N	\N	35ab010c0c90bc06fc34af8d858afe9d	f	\N	2012-01-10 18:26:16.476763	0	1980-01-01	\N	f	\N	f
3450	JOSE BARROSO AGUIAR NETO	jotabe1990@hotmail.com	JOSE BARRO	\N	\N	17c276c8e723eb46aef576537e9d56d0	f	\N	2012-01-10 18:26:16.735409	0	1980-01-01	\N	f	\N	f
2381	antonio sampaio de souza junior	juniorsampaio14@hotmail.com	junior	@		c760d1ab8b7869cba0737ba672f92029	f	\N	2011-11-24 12:05:51.554737	1	1992-01-01	\N	f		t
2535	FRANCISCO ERLANIO GOMES SANTOS	erlaniofegs@hotmail.com	FEGS007	@		03148cb6c0666ce793e7b13052a9bd76	f	\N	2011-11-24 23:15:26.08664	1	1990-01-01	\N	f		t
2488	jaqueline duarte	jack_brankinha2010@hotmail.com	jaqueline	@jaqueduarte3		f2a565b45168d7d4d8a9e9596e093004	f	\N	2011-11-24 18:52:13.63457	2	1995-01-01	\N	f	jack_brankinha2010@hotmail.com	t
2384	Maria Rafaela Matos Bezerra	mrafaellamt@hotmail.com	Rafaela	@		4944049d7c42daf3bc4287d0f41777c8	f	\N	2011-11-24 12:08:17.953977	2	1994-01-01	\N	f		t
852	Alanc Sousa Saraiva	alancsaraiva@live.com	alaanc	@alancsaraiva		292631618cc419b157f657be962b0c46	t	2011-11-26 11:16:24.707625	2011-11-16 10:24:08.863948	1	1994-01-01	\N	f		t
307	SAMIR COUTINHO COSTA	samirfor@gmail.com	samirfor	@samirfor	http://www.samirfor.com	70df54803bfee1bb7634478758d3c9ac	t	2012-01-10 18:26:29.027674	2011-10-14 14:43:03.756161	1	1988-01-01	\N	t	samirfor	t
3540	SAMUEL KARLMARTINS PINHEIRO MAGALHAES	samukapinheiro_surf@hotmail.com	SAMUEL KAR	\N	\N	7ef605fc8dba5425d6965fbd4c8fbe1f	f	\N	2012-01-10 18:26:29.129193	0	1980-01-01	\N	f	\N	f
2380	WESLEY OLIVEIRA SILVA	wesleysilva@live.com	Wesley Roots	@wesleyroots		e10adc3949ba59abbe56e057f20f883e	f	\N	2011-11-24 12:05:33.518111	1	1989-01-01	\N	f		t
2386	Natasha Lopes	natashalopesgomes@hotmail.com	natasha	@		82d67eac4ce7b2953503ddeb539d38d3	f	\N	2011-11-24 12:15:06.412772	2	1992-01-01	\N	f		t
2564	Ricardo Araújo Maciel	ricardoejovem@gmail.com	Ricardo	@		3237f3ac7892fd4485aee3ed320e1431	f	\N	2011-11-25 10:49:44.516971	1	1973-01-01	\N	f		t
758	SARA PINHEIRO ZACARIAS	sara.crazytj@hotmail.com	Sara Pinheiro	@sarah_axl182		6104df369888589d6dbea304b59a32d4	t	2012-01-10 18:26:29.230716	2011-11-11 19:02:21.616989	2	1991-01-01	\N	f	sara.crazytj@hotmail.com	t
2387	luana lemos amaral	luanalemos118@gmail.com	luana1	@		d42fc5cca30605a47f51755d91587d4d	f	\N	2011-11-24 12:17:18.497124	2	1991-01-01	\N	f		t
304	ROBSON DA SILVA SIQUEIRA	siqueira.robson.dasilva@gmail.com	Prof. Siqueira	@ProfSiqueira	http://www.comsolid.org	1bc493e2ed2d5ff496b0489de0e1a16f	t	2012-01-17 16:34:11.784925	2011-10-14 13:28:50.541718	1	1975-01-01	\N	t	siqueira.robson.dasilva@gmail.com	t
3541	SAULO ANDERSON FREITAS DE OLIVEIRA	saulo.ifet@gmail.com	SAULO ANDE	\N	\N	97e8527feaf77a97fc38f34216141515	f	\N	2012-01-10 18:26:29.284024	0	1980-01-01	\N	f	\N	f
2388	Fernando Henrique Costa	fernandocosta.ifce@gmail.com	Fernando 	@		82dc7421d293dd251418cc939ca59f43	f	\N	2011-11-24 12:17:48.215411	2	1988-01-01	\N	f		t
299	SHARA SHAMI ARAÚJO ALVES	shara.alves@gmail.com	ervilha	@ervilha		101e9ac182895985e4c8a0a52a90813b	f	\N	2011-10-13 19:14:47.697442	2	1990-01-01	\N	f	shara.alves@gmail.com	t
3542	SIMEANE DA SILVA MONTEIRO	simeane@yahoo.com.br	SIMEANE DA	\N	\N	2f55707d4193dc27118a0f19a1985716	f	\N	2012-01-10 18:26:29.390041	0	1980-01-01	\N	f	\N	f
2367	Ana Zelia Morais	ana.zelia27@hotmail.com	anazelia	@		8add6e966311c1fa2dde2c7ea9e514be	f	\N	2011-11-24 12:02:24.213976	2	1982-01-01	\N	f		t
2389	Marcos Ambrósio do Santos	marcos.ambrosio@hotmail.com	Marcos	@		ab6ee421e6cc20073243e1c119d5e4dd	f	\N	2011-11-24 12:20:00.324739	1	1983-01-01	\N	f		t
2590	Daniel Vasconcelos Uchoa	danieluchoa1@gmail.com	DANIEL	@		80272d7168f333ff4be8131d544c5b58	f	\N	2011-11-25 15:33:40.329374	1	1982-01-01	\N	f		t
3543	STÉFERSON SOUZA DE OLIVEIRA	stefersonsouza@hotmail.com	STÉFERSON	\N	\N	8eefcfdf5990e441f0fb6f3fad709e21	f	\N	2012-01-10 18:26:29.443767	0	1980-01-01	\N	f	\N	f
2675	Lilian Rodrigues	lilianrock1@hotmail.com	Lilian	@		2525d7b75aa05fbed52c0bced9f3eb4f	f	\N	2011-11-26 15:48:05.634553	2	1997-01-01	\N	f		t
3544	SUSANA MARA CATUNDA SOARES	susana.mara17@hotmail.com	SUSANA MAR	\N	\N	860320be12a1c050cd7731794e231bd3	f	\N	2012-01-10 18:26:29.495294	0	1980-01-01	\N	f	\N	f
2392	antonio iriẽ dias pereira 	naotememail@hotmail.com	antonio	@		8238ed8af610616cd80f87defce860c0	f	\N	2011-11-24 12:23:21.167121	1	1968-01-01	\N	f		t
2610	jociara	joise_love@hotmail.com	joisse	@		3ccac184dac77b6096c7524c2f291658	f	\N	2011-11-25 18:17:27.222616	2	1995-01-01	\N	f	joise.castro@facebook.com	t
3545	SYNARA DE FÁTIMA BEZERRA DE LIMA	syfafa@hotmail.com	SYNARA DE 	\N	\N	53c3bce66e43be4f209556518c2fcb54	f	\N	2012-01-10 18:26:29.548742	0	1980-01-01	\N	f	\N	f
2393	Lindenberg Jackson Sousa de Castro	lindenbergsousac@gmail.com	Lindenberg	@		b0f7be3bc070f5b130a8690a6d93f2a1	f	\N	2011-11-24 12:24:16.901083	1	1983-01-01	\N	f		t
3451	JOSE IVANILDO FIRMINO ALVES	ivanalvesnet@yahoo.com.br	JOSE IVANI	\N	\N	b337e84de8752b27eda3a12363109e80	f	\N	2012-01-10 18:26:17.737751	0	1980-01-01	\N	f	\N	f
1063	TATIANE SOUZA DA SILVA	tat_do@hotmail.com	Tatiane	@		b936936f4cb4a3853abca6296783e997	t	2012-01-16 17:11:42.069569	2011-11-19 19:13:45.190375	2	1993-01-01	\N	f	tat_do@hotmail.com	t
2394	Ellen Cristina P Nascimento	ecrisbn@gmail.com	Ellen Cris	@		449e055c46cff4d73fb392e87fb5a32e	f	\N	2011-11-24 12:25:21.246606	2	1979-01-01	\N	f		t
2395	francisco anderson de sousa oliveira	andersomsousa1406@gmail.com	anderson	@		5ab44c616ddb7ec0734e46087416ad7b	f	\N	2011-11-24 12:30:22.193125	1	1991-01-01	\N	f		t
3452	JOSÉ MACEDO DE ARAÚJO FILHO	corujaraylander@hotmail.com	JOSÉ MACE	\N	\N	e4da3b7fbbce2345d7772b0674a318d5	f	\N	2012-01-10 18:26:17.816026	0	1980-01-01	\N	f	\N	f
2397	Wellignton Carvalho Silva 	macstell@gmail.com	Wellington	@		fb9296ffa1ed8bd877c26ec8aadab58d	f	\N	2011-11-24 13:08:49.228511	1	1985-01-01	\N	f	macstell@gmail.com	t
2398	Alisson da Silva	aliseverino@gmail.com	Severino	@		7ee69b837fe27ccfac3b9522d623ad85	f	\N	2011-11-24 14:16:11.218669	1	1991-01-01	\N	f	aliseverino@gmail.com	t
2399	Ana Kessia Gomes da Silva	anakessiaejovem@gmail.com	Kessia	@		d650ffd2fe97de74fe4cd5390d5e5b5f	f	\N	2011-11-24 14:24:00.095431	2	1994-01-01	\N	f		t
3453	JOSÉ NATANAEL DE SOUSA	sergiotome28@yahoo.com	JOSÉ NATA	\N	\N	fc8001f834f6a5f0561080d134d53d29	f	\N	2012-01-10 18:26:17.869106	0	1980-01-01	\N	f	\N	f
3454	JOSÉ PAULINO DE SOUSA NETTO	paulino_netto27@hotmail.com	JOSÉ PAUL	\N	\N	ae9d762a40e77d724c97e0dc91bb565a	f	\N	2012-01-10 18:26:17.921119	0	1980-01-01	\N	f	\N	f
3455	JOSÉ WEVERTON RIBEIRO MONTEIRO	j.weverton@hotmail.com	JOSÉ WEVE	\N	\N	d3bb0faa849903ce4895e41274139f7b	f	\N	2012-01-10 18:26:18.031042	0	1980-01-01	\N	f	\N	f
3456	JOSERLEY PAULO TEOFILO DA COSTA	yosef.j@hotmail.com	JOSERLEY P	\N	\N	f3d02cf53e1c72cc4327b5960c23ac49	f	\N	2012-01-10 18:26:18.141629	0	1980-01-01	\N	f	\N	f
3457	JOVANE AMARO PIRES	jovanepires@ymail.com	JOVANE AMA	\N	\N	f828f786ad16d29ca1d52187e32585b8	f	\N	2012-01-10 18:26:18.208622	0	1980-01-01	\N	f	\N	f
3458	JOYCE SARAIVA LIMA	jojosl@hotmail.com	JOYCE SARA	\N	\N	4550523903d6f22806e6222ba46a436b	f	\N	2012-01-10 18:26:18.2695	0	1980-01-01	\N	f	\N	f
3459	JULIO CESAR OTAZO NUNES	juliocesar_otazo@hotmail.com	JULIO CESA	\N	\N	c74d97b01eae257e44aa9d5bade97baf	f	\N	2012-01-10 18:26:19.035087	0	1980-01-01	\N	f	\N	f
3460	KILDARY JUCÁ CAJAZEIRAS	kildarydoido@yahoo.com.br	KILDARY JU	\N	\N	5737c6ec2e0716f3d8a7a5c4e0de0d9a	f	\N	2012-01-10 18:26:21.227179	0	1980-01-01	\N	f	\N	f
3461	KILVIA RIBEIRO MORAIS	kikig4_192@hotmail.com	KILVIA RIB	\N	\N	823f5535c45ed0b5b25ba2c1e853cee2	f	\N	2012-01-10 18:26:21.277533	0	1980-01-01	\N	f	\N	f
3462	KLEBER DE MELO MESQUITA	kleber.kmm@hotmail.com	KLEBER DE 	\N	\N	90957dc82c2856cf0bfd283d99bd3ddd	f	\N	2012-01-10 18:26:21.327605	0	1980-01-01	\N	f	\N	f
3463	KLEVERLAND SOUSA FORMIGA	kleverland@yahoo.com.br	KLEVERLAND	\N	\N	200e26be323cb5c4dd91a7f87c840e9e	f	\N	2012-01-10 18:26:21.890511	0	1980-01-01	\N	f	\N	f
3464	LAIS EVELYN BERNARDINO ALVES	lais-evelyn@hotmail.com	LAIS EVELY	\N	\N	d9d4f495e875a2e075a1a4a6e1b9770f	f	\N	2012-01-10 18:26:22.107064	0	1980-01-01	\N	f	\N	f
2401	Marisa Clementino Cruz	marisa_crazy@hotmail.com	Mari Crazy	@		73bc4b5cdb243f06cd5885b0b907eb97	f	\N	2011-11-24 14:30:29.305074	2	1997-01-01	\N	f		t
3546	THAÍS BARROS SOUSA	thaizinhabarros@hotmail.com	THAÍS BAR	\N	\N	76dc611d6ebaafc66cc0879c71b5db5c	f	\N	2012-01-10 18:26:29.66758	0	1980-01-01	\N	f	\N	f
2536	pedro victor gomes de souza	pedrovictor22@hotmail.com	pedrinho	@pedro_victinho		93b7e499154266936523a516dbba0938	f	\N	2011-11-24 23:24:58.909095	1	1997-01-01	\N	f	pedrovictor22@hotmail.com	t
2637	Pdero Anderson Pires Humberto da Rocha	pedropires5@hotmail.com	Anderson	@		acb6d7d1805d2b2a7e76dd0b8c66844e	f	\N	2011-11-26 12:03:38.084794	1	1998-01-01	\N	f		t
3547	TIAGO ALEXANDRE FRANCISCO DE QUEIROZ	lucianaqueiroz2007@yahoo.com.br	TIAGO ALEX	\N	\N	3dc4876f3f08201c7c76cb71fa1da439	f	\N	2012-01-10 18:26:29.840674	0	1980-01-01	\N	f	\N	f
2565	Camila Escudeiro Oliveira Pinheiro	camila.escudeiro@seduc.ce.gov.br	Camila	@		6327bb0d760ac85969dcf74103be55d8	f	\N	2011-11-25 10:50:16.657833	2	1983-01-01	\N	f		t
3465	LEANDRO MENEZES DE SOUSA	leomesou@yahoo.com.br	LEANDRO ME	\N	\N	3d6d8b2e50af88368fd3df1cb6a9cab1	f	\N	2012-01-10 18:26:22.670868	0	1980-01-01	\N	f	\N	f
2635	TIAGO CORDEIRO ARAGÃO	tiago.ifet@gmail.com	Cordeiro	@		73858ba9eadee4ccbfb8835cb1acdbc9	f	\N	2011-11-26 10:53:31.77019	1	1991-01-01	\N	f		t
2591	paulo henrique mendonça de araujo	henriquepaulovictor@yahoo.com	paulo aqw	@		6fddf87e973c1c96ca43851c0264ff55	f	\N	2011-11-25 15:35:50.740007	1	1996-01-01	\N	f		t
2453	gabriel linhares de souza	linhares.biel@gmail.com	biel...	@		f82367d96015b7e86460de7326df7e08	f	\N	2011-11-24 15:55:45.454539	1	1998-01-01	\N	f		t
2420	Leandro da Silva Braga	leandro.braga_200@hotmail.com	Leandro	@		eea5026bd57307c454d094c7228f67a1	f	\N	2011-11-24 15:37:41.317391	1	1992-01-01	\N	f		t
2611	Ana Mara de Sousa Pereira	ana.mara709@gmail.com	Ana Mara	@		d3a001bf93a1f36d5037df8cf44c75b2	f	\N	2011-11-25 18:28:31.094339	2	1995-01-01	\N	f		t
2659	Deyvison Vagna Alves Candido	Dayvisonvaga23@gmail.com	Deyvison	@		a21aa91c73d3c3b51fafb4837f6356ed	f	\N	2011-11-26 14:24:30.229604	1	1991-01-01	\N	f		t
2454	Pedro Alberto Morais pessoa	pedroalbertomorais@hotmail.com	alberto	@		0691b49ec0e1beadb022c79e72461c0c	f	\N	2011-11-24 16:01:20.223761	1	1990-01-01	\N	f		t
2540	Jose Stenio dos Santos	josestenio@gmail.com	stenio	@stenior		21e95db190fa927249e417804f4ad756	f	\N	2011-11-25 07:35:06.220039	1	1983-01-01	\N	f	josestenio@gmail.com	t
2423	Francisco Rafael da silva	rafaeldarenata@gmail.com	Rafael silva	@		4b4e04e862421818157ab6d7dcb87af0	f	\N	2011-11-24 15:39:30.480352	1	1984-01-01	\N	f	rafalouco100@hotmail.com	t
2676	maria hortencia costa de souza	mhortencia.2011@gmail.com	hortencia	@		25722e2a24a4fde4904a7c5ff34bfc33	f	\N	2011-11-26 15:49:39.777545	2	1969-01-01	\N	f		t
2455	Larisse da Silva Moreira	larissedasilvamoreira@gmail.com	Larisse Johns	@		7e65423b69c3baf6b583efcb8e6f70e7	f	\N	2011-11-24 16:04:00.981613	2	1992-01-01	\N	f		t
2641	Douglas Camurça Lima	acumulador@hotmail.com	douglas	@		cb2340d91848ff64b5d1aea0c11cd8ea	f	\N	2011-11-26 12:20:29.563441	1	1981-01-01	\N	f		t
3466	LEEWAN ALVES DE MENESES	leewanalves@hotmail.com	LEEWAN ALV	\N	\N	3c7777f766a2a054dfb9cca55f2713ca	f	\N	2012-01-10 18:26:22.95213	0	1980-01-01	\N	f	\N	f
2569	LEONILDO FERREIRA DE ABREU	leonildoabreu@yahoo.com.br	Leonildo	@		e7edcf2d0238488690d1f646e7cb7014	f	\N	2011-11-25 11:32:12.265401	1	1986-01-01	\N	f	leonildoabreu@yahoo.com.br	t
3467	LEONARDO BARBOSA DE SOUZA	yvensleo@hotmail.com	LEONARDO B	\N	\N	c3c59e5f8b3e9753913f4d435b53c308	f	\N	2012-01-10 18:26:23.011694	0	1980-01-01	\N	f	\N	f
2456	José Siloé Sousa Moreira	josesiloe13@gmail.com	Siloé	@		666651c01830d470730c360649a1366e	f	\N	2011-11-24 16:10:04.836942	1	1964-01-01	\N	f		t
3468	LEVI VIANA DE ANDRADE	levi_viana_@hotmail.com	LEVI VIANA	\N	\N	2bcab9d935d219641434683dd9d18a03	f	\N	2012-01-10 18:26:23.116253	0	1980-01-01	\N	f	\N	f
2457	rodrigo araujo alves	naruto@karater.com	rodrigo	@		d551b8174647ec472edb8e39b8436066	f	\N	2011-11-24 16:10:33.291892	1	1996-01-01	\N	f		t
3469	LILIAN JACAÚNA LOPES	lilian.jacauna.lopes@hotmail.com	LILIAN JAC	\N	\N	72f2b423c8ccd1cdaa65bf453baaba90	f	\N	2012-01-10 18:26:23.167222	0	1980-01-01	\N	f	\N	f
2458	gilberto luis morais pessoa	gilberto@luis.com	gilberto	@		d427089167982504a0665cf4b625860f	f	\N	2011-11-24 16:12:31.131378	1	1994-01-01	\N	f		t
3470	LIVIA FIGUEIREDO SOARES	halinefigueiredo@hotmail.com	LIVIA FIGU	\N	\N	f64eac11f2cd8f0efa196f8ad173178e	f	\N	2012-01-10 18:26:23.219346	0	1980-01-01	\N	f	\N	f
2459	Pedro Ian Tavares Costa	yan.design@hotmail.com	pedro ian	@		5d48e72ba2fd392e6862be47fbfa6f98	f	\N	2011-11-24 16:15:20.621644	1	1986-01-01	\N	f		t
3471	LÍVIO SIQUEIRA LIMA	lslprogramador@gmail.com	LÍVIO SIQ	\N	\N	f73278bd85a966e65ee6935740490c20	f	\N	2012-01-10 18:26:23.273218	0	1980-01-01	\N	f	\N	f
2663	Jose Wanderley Maciel Silveira	maciel-silveira@bol.com.br	Wanderley	@		dec274360822dc546addba0a1c1cc57e	f	\N	2011-11-26 14:46:09.730907	1	1989-01-01	\N	f		t
3472	LUAN SIDNEY NASCIMENTO DOS SANTOS	luansidneyseliga@gmail.com	LUAN SIDNE	\N	\N	01c77487b58afff6a5c0baaed961bb2e	f	\N	2012-01-10 18:26:23.323248	0	1980-01-01	\N	f	\N	f
2460	Jairo da Silva Freitas	jairomg_@hotmail.com	jairomg	@		6ee73616b0351edd8b49108abbf00a57	f	\N	2011-11-24 16:17:47.598282	1	1993-01-01	\N	f		t
3473	LUANA DE OLIVEIRA CORREIA	luana.oc@hotmail.com	LUANA DE O	\N	\N	2afe4567e1bf64d32a5527244d104cea	f	\N	2012-01-10 18:26:23.374354	0	1980-01-01	\N	f	\N	f
2615	Edson Dutra	edson123dutra@hotmail.com	gordim	@		6d446eb9a4a51f615bbf2084ff5b7435	f	\N	2011-11-25 19:08:45.004337	1	1995-01-01	\N	f		t
3474	LUANA GOMES DE ANDRADE	j.kluana@hotmail.com	LUANA GOME	\N	\N	d2ba5e72126c50c7682fcd40f43ae144	f	\N	2012-01-10 18:26:23.424312	0	1980-01-01	\N	f	\N	f
2461	Ricardo Martins	rickmaro@hotmail.com	Ricardo	@		39e9228b280afae31cc875b97fd8b4db	f	\N	2011-11-24 16:19:11.597158	1	1987-01-01	\N	f		t
2462	Maria Patrícia Moraes Leal	mpateleal@yahoo.com.br	Patricia	@		e2f44e74d0f8b6e3097d4ab6e09ed521	f	\N	2011-11-24 16:19:22.928844	2	1963-01-01	\N	f		t
3475	LUCAS ÁBNER LIMA REBOUÇAS	revpecas@uol.com.br	LUCAS ÁBN	\N	\N	72b32a1f754ba1c09b3695e0cb6cde7f	f	\N	2012-01-10 18:26:23.523715	0	1980-01-01	\N	f	\N	f
2680	Milena Gois da Silva	milena15303@hotmail.com	Aninha	@		01fba6efbd2d68309a8851218a26ec50	f	\N	2011-11-26 16:05:41.8609	2	1996-01-01	\N	f		t
3476	LUCAS FIGUEIREDO SOARES	lucasfigueiredo@hotmail.fr	LUCAS FIGU	\N	\N	20aee3a5f4643755a79ee5f6a73050ac	f	\N	2012-01-10 18:26:23.575657	0	1980-01-01	\N	f	\N	f
3532	ROBSON MACIEL DE ANDRADE	robson5647@hotmail.com	ROBSON MAC	\N	\N	ca75910166da03ff9d4655a0338e6b09	f	\N	2012-01-10 18:26:28.409762	0	1980-01-01	\N	f	\N	f
3477	LUCIANA SA DE CARVALHO	lucianasa.jc@gmail.com	LUCIANA SA	\N	\N	85422afb467e9456013a2a51d4dff702	f	\N	2012-01-10 18:26:23.725354	0	1980-01-01	\N	f	\N	f
3478	LUIS CLAUDIO COSTA CAETANO	lcccaetano@yahoo.com.br	LUIS CLAUD	\N	\N	8a0e1141fd37fa5b98d5bb769ba1a7cc	f	\N	2012-01-10 18:26:23.876143	0	1980-01-01	\N	f	\N	f
3479	LUIS RAFAEL SOUSA FERNANDES	l.rafilx@globomail.com	LUIS RAFAE	\N	\N	d2ddea18f00665ce8623e36bd4e3c7c5	f	\N	2012-01-10 18:26:23.927607	0	1980-01-01	\N	f	\N	f
3480	MAIARA MARIA PEREIRA BASTOS SOUSA	maiampb@yahoo.com.br	MAIARA MAR	\N	\N	7250eb93b3c18cc9daa29cf58af7a004	f	\N	2012-01-10 18:26:24.238913	0	1980-01-01	\N	f	\N	f
3481	MANOEL NAZARENO E SILVA	nazarenosp@gmail.com	MANOEL NAZ	\N	\N	05049e90fa4f5039a8cadc6acbb4b2cc	f	\N	2012-01-10 18:26:24.392338	0	1980-01-01	\N	f	\N	f
3482	MARA JÉSSYCA LIMA BARBOSA	marajessyca@hotmail.com	MARA JÉSS	\N	\N	85034e9501f93af7a0d3bfcd376fe76c	f	\N	2012-01-10 18:26:24.443904	0	1980-01-01	\N	f	\N	f
3483	MARCOS DA SILVA JUSTINO	marcos.ce8@gmail.com	MARCOS DA 	\N	\N	b0b183c207f46f0cca7dc63b2604f5cc	f	\N	2012-01-10 18:26:24.497117	0	1980-01-01	\N	f	\N	f
2400	isake barbosa de castro	pbro_pk@hotmail.com	isake.	@		0df7bd0c55bc6cdd2c4fe7703df37761	f	\N	2011-11-24 14:30:19.519398	1	1996-01-01	\N	f		t
2402	Douglas Marques	dpmcb@hotmail.com	Douglas	@douglasmarques		1423a3a5785e7242cc100fc7d5fc62d3	f	\N	2011-11-24 14:35:54.247503	1	1987-01-01	\N	f	dpmcb@hotmail.com	t
2537	matheus davi queiroz nunes	dragon.six@hotmail.com	leitoso	@		f2b249ab129a503075bc837eeef42f2c	f	\N	2011-11-24 23:38:52.756272	1	2011-01-01	\N	f		t
2464	GLAYDSON RAFAEL MACEDO	glaydsonmacedo@yahoo.com	Glaydson	@glaydsonmacedo		4ddffbe54bf1a1eda00f348c57337e2d	f	\N	2011-11-24 16:50:00.134301	1	1977-01-01	\N	f	glaydsonmacedo@yahoo.com	t
2403	Grace Kelly Oliveira de Sousa	kellyoliveira48@gmail.com	Kelly Oliveira	@		7e603c95a6a0ac400d3fcf3ced678345	f	\N	2011-11-24 14:49:08.197444	2	1993-01-01	\N	f		t
2638	Luiz Henrique de Araujo Pires	luizpires1010@yahoo.com.br	henrique	@		97ec159498e9f06139eb29998c109fbc	f	\N	2011-11-26 12:05:26.791006	1	1999-01-01	\N	f		t
3524	REBECA HANNA SANTOS DA SILVA	rebecahannaduarte@hotmail.com	REBECA HAN	\N	\N	0b8aff0438617c055eb55f0ba5d226fa	f	\N	2012-01-10 18:26:27.78893	0	1980-01-01	\N	f	\N	f
2404	Glauciane Silva de Sousa	glauciasilva_mel@hotmail.com	Glaucia	@		619ed8d983c45e99592baf20dd4e9cdf	f	\N	2011-11-24 14:49:27.573867	2	1996-01-01	\N	f		t
2465	Juliana Fernandes Mendonça	juliana.fernandesjr@hotmail.com	julianafernandes	@		1a4526cd1d607ef0f2c909087d97267d	f	\N	2011-11-24 16:50:57.063525	2	1996-01-01	\N	f		t
3525	REGINALDO MOTA DE SOUSA	sousa.rmt@gmail.com	REGINALDO 	\N	\N	599cca3b69f381a629e95b2710ba55ac	f	\N	2012-01-10 18:26:27.89358	0	1980-01-01	\N	f	\N	f
2405	Francisco James de Abreu 	jamesabreu16@gmail.com	jamesabreu	@		4eb822c28eae559c75a97f7b48e6642f	f	\N	2011-11-24 14:50:13.961695	1	1989-01-01	\N	f		t
3484	MARIA ANGELINA FERREIRA PONTES	alngel1994@bol.com.br	MARIA ANGE	\N	\N	a8f15eda80c50adb0e71943adc8015cf	f	\N	2012-01-10 18:26:24.598594	0	1980-01-01	\N	f	\N	f
2466	Antonia Glaucivania pereira Luz	glaucia.208@hotmail.com	Glaucivania	@		ebb0d3a3c4e375adf8ecb076fcac4f15	f	\N	2011-11-24 17:03:04.291475	2	1989-01-01	\N	f	glaucia.208@hotmail.com	t
2406	francisco carlos araujo de mesquita	fcarlosaraujo_85@hotmail.com	carlos	@		c985324a60f60b31b05f8d1ed86a4722	f	\N	2011-11-24 14:50:30.381636	1	1991-01-01	\N	f		t
2592	josienio alves	josienio007@yahoo.com	josiene	@		6515441ece6f5579f63181be32ff6b90	f	\N	2011-11-25 15:41:49.567665	1	1997-01-01	\N	f		t
2467	Tamyres Cavalcante Marques	tamyres_limao@hotmail.com	  myres	@		32159a59481b539d704a97429a811707	f	\N	2011-11-24 17:06:31.524969	2	1994-01-01	\N	f	tamyres_limao@hotmail.com	t
2407	Hiago Henrique Ferreira dos Anjos	hiago.henriquer.f@gmail.com	Ogaihh	@		8ffb324e58ef34176e798fbff76e16b2	f	\N	2011-11-24 14:52:35.714392	1	1993-01-01	\N	f		t
3526	REGINALDO PATRÍCIO DE SOUZA LIMA	moral.reginaldo@hotmail.com	REGINALDO 	\N	\N	06eb61b839a0cefee4967c67ccb099dc	f	\N	2012-01-10 18:26:27.944315	0	1980-01-01	\N	f	\N	f
3527	REGIO FLAVIO DO SANTOS SILVA FILHO	negflafil@hotmail.com	REGIO FLAV	\N	\N	df7f28ac89ca37bf1abd2f6c184fe1cf	f	\N	2012-01-10 18:26:27.996465	0	1980-01-01	\N	f	\N	f
2408	domingos savio de mesquita nascimento	domingos.savio07@gmail.com	domingos	@		784832328962eff3ceb963f3f82254c2	f	\N	2011-11-24 14:54:08.880975	1	1993-01-01	\N	f		t
3528	RENAN ALMEIDA DA SILVA	renanteclado@yahoo.com.br	RENAN ALME	\N	\N	9c838d2e45b2ad1094d42f4ef36764f6	f	\N	2012-01-10 18:26:28.048745	0	1980-01-01	\N	f	\N	f
3529	RICARDO VALENTIM DE LIMA	ricardol@chesf.gov.br	RICARDO VA	\N	\N	2dace78f80bc92e6d7493423d729448e	f	\N	2012-01-10 18:26:28.154491	0	1980-01-01	\N	f	\N	f
2409	Maria Keliane Alves Rocha	kelianerocha27@hotmail.com	Keliane	@		f43800f3c6d8a262020e117722058bbf	f	\N	2011-11-24 14:54:44.850346	2	1990-01-01	\N	f		t
2612	THIAGO BRUNO DE SOUSA BARBOSA	thiagob66@gmail.com	BRUNINHO	@		c76537959434da86c41151701c4c668a	f	\N	2011-11-25 18:31:43.270647	1	2011-01-01	\N	f		t
3530	RICARLOS PEREIRA DE MELO	ricarlosmelo@gmail.com	RICARLOS P	\N	\N	c6e19e830859f2cb9f7c8f8cacb8d2a6	f	\N	2012-01-10 18:26:28.207604	0	1980-01-01	\N	f	\N	f
2410	oscarina viana lima	oscarinavianalima@gmail.com	oscarina	@		6a8c7f685eea654a8a5f8eef50b0375e	f	\N	2011-11-24 14:55:27.081229	2	1991-01-01	\N	f		t
2660	Agamenon Silva Alves	agamenon.exercito33@hotmail.com	agamenon	@		0a37d3a10d2bc01aecdd21ec7b3b693e	f	\N	2011-11-26 14:24:31.455739	1	1987-01-01	\N	f		t
3531	ROBSON DOUGLAS BARBOZA GONÇALVES	robsondouglasrd@yahoo.com.br	ROBSON DOU	\N	\N	ce801c9e0a7c3758ab1f52028c07e94c	f	\N	2012-01-10 18:26:28.360293	0	1980-01-01	\N	f	\N	f
2411	suelio de pinho sobral de sousa	suelio09@yahoo.com	suelio	@		e4845ac98f96ebf48551a8268ff8d6a1	f	\N	2011-11-24 14:57:11.078101	1	1992-01-01	\N	f		t
3485	MARIA ELANIA VIEIRA ASEVEDO	elania_vieira@hotmail.com	MARIA ELAN	\N	\N	09c072ff90ef0332174a709595702122	f	\N	2012-01-10 18:26:24.701565	0	1980-01-01	\N	f	\N	f
2413	Francisco Gleison Rodrigues Soares	xgleisonx@gmail.com	Gleison	@		b24799ff4840d4da7250836f363e3599	f	\N	2011-11-24 15:00:09.781507	1	1987-01-01	\N	f		t
2414	Thamara Edna Barbosa da Silva	tanzinhatuf@hotmail.com	Tanzinha	@		ca1438ddd001980740638cbd07afa123	f	\N	2011-11-24 15:01:58.472776	2	1996-01-01	\N	f		t
2677	Lívia Rodrigues da Silva	rodrigues_liviaskp@hotmail.com	Livinha	@		aaa610f36e5890df57858f5901cb00a9	f	\N	2011-11-26 15:49:51.576636	2	1998-01-01	\N	f		t
2415	Sara da Silva Paulo	saradasilva.seliga@gmail.com	Sara da Silva	@		254f81a02a761e0f1811dce2300643a8	f	\N	2011-11-24 15:20:55.840111	2	1992-01-01	\N	f		t
2416	Luana da Silva Paulo	luanaml09@gmail.com	Luana da Silva	@		b5ea1335b8f8f730b6f9afbaf98ec15d	f	\N	2011-11-24 15:22:48.696411	2	1997-01-01	\N	f		t
2417	Rafaela Alves de Lima	rafaela.infor@gmail.com	Rafaela	@		b83e4c0760bb7d5f459e5e14fa857c34	f	\N	2011-11-24 15:34:22.401125	2	1993-01-01	\N	f		t
3486	MARIA JULIANE DA SILVA CHAGAS	julianychagas@gmail.com	MARIA JULI	\N	\N	87c17be19f945b7ad44e98bceb792057	f	\N	2012-01-10 18:26:24.809579	0	1980-01-01	\N	f	\N	f
3487	MARIA VALDENE PEREIRA DE SOUZA	valdenyagarotinha@hotmail.com	MARIA VALD	\N	\N	7d04bbbe5494ae9d2f5a76aa1c00fa2f	f	\N	2012-01-10 18:26:24.922855	0	1980-01-01	\N	f	\N	f
3488	MATEUS PEREIRA DE SOUSA	infomateus@hotmail.com	MATEUS PER	\N	\N	d1c38a09acc34845c6be3a127a5aacaf	f	\N	2012-01-10 18:26:24.973624	0	1980-01-01	\N	f	\N	f
3489	MATHEUS ARLESON SALES XAVIER	iceman_nfsu@hotmail.com	MATHEUS AR	\N	\N	c81e728d9d4c2f636f067f89cc14862c	f	\N	2012-01-10 18:26:25.023252	0	1980-01-01	\N	f	\N	f
3490	MATHEUS CARVALHO DE FREITAS	matheuscarvalhodf@ymail.com	MATHEUS CA	\N	\N	f842ba079c54f383974e02e3b5e35ca2	f	\N	2012-01-10 18:26:25.072939	0	1980-01-01	\N	f	\N	f
3491	MATHEUS TAVEIRA SOARES	mmetheus@hotmail.com	MATHEUS TA	\N	\N	ca63d2b01c6b58d90f551f14c26ee7cb	f	\N	2012-01-10 18:26:25.124757	0	1980-01-01	\N	f	\N	f
3492	MAURO SERGIO PEREIRA	maurosergio@live.com	MAURO SERG	\N	\N	c8c41c4a18675a74e01c8a20e8a0f662	f	\N	2012-01-10 18:26:25.176503	0	1980-01-01	\N	f	\N	f
3493	MAYARA JESSICA CAVALCANTE FREITAS	mayarajessica20@hotmail.com	MAYARA JES	\N	\N	13f3cf8c531952d72e5847c4183e6910	f	\N	2012-01-10 18:26:25.328979	0	1980-01-01	\N	f	\N	f
3494	MAYARA NOGUEIRA BEZERRA	mayara_nb@hotmail.com	MAYARA NOG	\N	\N	94a37d0075cbdddae3489552038e190e	f	\N	2012-01-10 18:26:25.464503	0	1980-01-01	\N	f	\N	f
3495	MAYARA SUÉLLY HONORATO DA SILVA	mayarasilvah@yahoo.com.br	MAYARA SU�	\N	\N	860320be12a1c050cd7731794e231bd3	f	\N	2012-01-10 18:26:25.515469	0	1980-01-01	\N	f	\N	f
3496	MERCIA OLIVEIRA DE SOUSA	mercia_butterfly@hotmail.com	MERCIA OLI	\N	\N	6067303a8950a26f0873802c50c65a68	f	\N	2012-01-10 18:26:25.565756	0	1980-01-01	\N	f	\N	f
3497	MOISÉS LOURENÇO BANDEIRA	moresain@hotmail.com	MOISÉS LO	\N	\N	06409663226af2f3114485aa4e0a23b4	f	\N	2012-01-10 18:26:25.668226	0	1980-01-01	\N	f	\N	f
2418	patricia vasconcelos de sousa	patriciavasconcelosdesousa@hotmail.com	patricia	@		95cb80b27f04fe966286c835f66e1c3b	f	\N	2011-11-24 15:34:53.480097	2	1994-01-01	\N	f		t
3534	RODRIGO MUNIZ DA SILVA	rrodrigo.mmuniz@gmail.com	RODRIGO MU	\N	\N	6f2268bd1d3d3ebaabb04d6b5d099425	f	\N	2012-01-10 18:26:28.512576	0	1980-01-01	\N	f	\N	f
2419	Jaqueline Teixiera	jaquelinecearamor@gmail.com	jaqueline	@		5a78b1e4feb9e647b64932598bcd0325	f	\N	2011-11-24 15:36:01.684447	2	1988-01-01	\N	f	jaquelinecearamor@gmail.com	t
2538	Jose aurisnando marques 	aurisnado@hotmail.com	nandomarques	@		0dd4701083a31109364ebaee35ba67a8	f	\N	2011-11-25 00:48:28.652322	1	1995-01-01	\N	f	aurisnado@hotmail.com	t
3535	ROGÉRIO QUEIROZ LIMA	rogerio-_2010@hotmail.com	ROGÉRIO Q	\N	\N	67d16d00201083a2b118dd5128dd6f59	f	\N	2012-01-10 18:26:28.566746	0	1980-01-01	\N	f	\N	f
2639	Francisco Vanderson da Silva Santos	vandersonbob@hotmail.com	Vanderson	@		2a6c965b94f8f1c3faaae672197894c7	f	\N	2011-11-26 12:08:34.983296	1	1990-01-01	\N	f		t
2434	andré silva monteiro 	amdreanimem@gmail.com	andré.	@		ed05bfd20586abaeb05dc60634824026	f	\N	2011-11-24 15:47:57.356103	1	1997-01-01	\N	f		t
2567	Antonia Mikelle Egidio de Paulo	mikelleflayther@gmail.com	Mikelle	@		ce5c9352311846a335706a6cd3fb1fc7	f	\N	2011-11-25 11:14:13.765168	2	1993-01-01	\N	f		t
2421	marcilio oliveira nascimento	marcilio.nascimento.93@gmail.com	marcilio	@		a2bdeba810c1b734bc5ac9c614c38925	f	\N	2011-11-24 15:38:08.780133	1	1993-01-01	\N	f		t
3498	MÔNICA GUIMARÃES RIBEIRO	monikrg@hotmail.com	MÔNICA GU	\N	\N	6ea2ef7311b482724a9b7b0bc0dd85c6	f	\N	2012-01-10 18:26:25.718948	0	1980-01-01	\N	f	\N	f
2539	Daniel Neves Bezerra Lima	danielnbl@gmail.com	Daniel	@danielneves	http://danielneves.com	47e5286857ceac27791a3fa0b4cc4ccc	f	\N	2011-11-25 03:34:52.092891	1	1990-01-01	\N	f	danielnbl@gmail.com	t
2422	Dhaeyvison Evangelista da Silva	dhaeyvison.infor@gmail.com	Dhaeyvison 	@		1bec2d64b389c491870a2405e7498754	f	\N	2011-11-24 15:38:17.870478	1	1995-01-01	\N	f		t
2435	Francisco de Assis Andrade	francisco.nacimento2011@hotmail.com	franciscoassis	@		23753adaf411adc02418574f8bb8b0da	f	\N	2011-11-24 15:48:05.46812	1	1989-01-01	\N	f		t
2640	Mariana Geronimo da Costa	mariana_jdcosta@hotmail.com	mariana	@		4f189c635af8b9ce32e6e65a66950b07	f	\N	2011-11-26 12:19:11.328773	2	1988-01-01	\N	f		t
2593	Vicente de Paula Blum 	vicenteblum@gmail.com	vicente	@		6c077b3980681e594079217cee87e96b	f	\N	2011-11-25 15:50:13.284752	1	1962-01-01	\N	f		t
2436	Larissa Pena Amancio	larissabellahg.n@gmail.com	larissa	@		2e3e67cf081d126f6a95ae603472755d	f	\N	2011-11-24 15:48:51.265108	2	1994-01-01	\N	f		t
2437	Francisca Joice Lopes Ferreira	lopesferreirajoice@gmail.com	Joice Lopes	@		66b7e07fa1db532ff27d1f3430199238	f	\N	2011-11-24 15:48:59.530682	2	1995-01-01	\N	f		t
2424	Lucas Nascimento Leitão	lucasnascimentoleito518@gmail.com	Rukasu-daijo	@bbLucascom		038c74e4f1d5f81ab2141f64cd576b45	f	\N	2011-11-24 15:41:50.07457	1	1994-01-01	\N	f	lucasgatosemdona@hotmail.com	t
2661	Rafael Sousa de Oliveira	Rafaelsolsa2011@yahoo.com	Rafael	@		71922e4f63a8ed5e4c46f9a4efd49097	f	\N	2011-11-26 14:26:59.148756	1	1990-01-01	\N	f	Rafael_cinza@hotmail.com	t
2568	Samuel Bruno Honorado da Silva	brunohonorados@gmail.com	Honorado	@		b5bd10602b49b22e03c07225b704b4a6	f	\N	2011-11-25 11:14:14.155638	1	1993-01-01	\N	f		t
2425	Ana Carolina Trajano Silva	anaacarolinats@gmail.com	Ana Carol	@		18b8c438c35e3d8227c6a0c100b49e1b	f	\N	2011-11-24 15:42:47.764932	2	1993-01-01	\N	f		t
2438	Lilian Camurça Coelho	lilian0011@hotmail.com	lilian	@		5470dd33a2a3d38a35a5799a7d48b736	f	\N	2011-11-24 15:49:07.0374	2	1995-01-01	\N	f		t
3511	PÉRICLES HENRIQUE GOMES DE OLIVEIRA	pericles_henrique@yahoo.com.br	PÉRICLES 	\N	\N	1ce927f875864094e3906a4a0b5ece68	f	\N	2012-01-10 18:26:26.796797	0	1980-01-01	\N	f	\N	f
2426	Maria Mirna do Nascimento	mirnasousa46@gmail.com	mariamirna	@		38e7f594fd9db32fc4cc493c232d04a0	f	\N	2011-11-24 15:44:00.2747	2	1996-01-01	\N	f		t
2439	franciane silva albuquerque	francianesilvaalbuquerque@gmail.com	franciane	@		7c67be923cd9f2cff3929a6bca588d5e	f	\N	2011-11-24 15:50:00.589834	2	1995-01-01	\N	f		t
2440	Paulo Ricardo Ribeiro Rodrigues	paullo.riccardo@hotmail.com	riccardo	@		23937ab7e9563f903b8c040de4521230	f	\N	2011-11-24 15:50:00.948817	2	1989-01-01	\N	f		t
2427	Kawanny Paiva	kawannypaiva@hotmail.com	Kakau Iane	@		cb4203783ebba72744c96497805f7cb3	f	\N	2011-11-24 15:45:16.14438	2	1994-01-01	\N	f		t
2678	Geovane Vasconcelos	geovane_leokyo@hotmail.com	Geovane	@		c95d6d016999f494d9d062dd76db851e	f	\N	2011-11-26 15:51:59.068874	1	1995-01-01	\N	f		t
2441	Karyne dieckman Bernardo da Silva	KaryneDieckman@hotmail.com	Karyne	@		7d7e6326cd071750e0217e772c9f2e6f	f	\N	2011-11-24 15:50:21.855054	2	1994-01-01	\N	f		t
2428	Jaine Passos Ramos	jaine.pimentinha@hotmail.com	Jaine Jackson	@		1ddc9c792758a2bda13689f492e45cbf	f	\N	2011-11-24 15:45:29.62865	2	1994-01-01	\N	f		t
3499	NANAXARA DE OLIVEIRA FERRER	nanaxara_oliv@hotmail.com	NANAXARA D	\N	\N	2dace78f80bc92e6d7493423d729448e	f	\N	2012-01-10 18:26:25.872565	0	1980-01-01	\N	f	\N	f
2429	jéssica siqueira 	jessycasiqueira201@gmail.com	jéssica	@		8f6e9953ebca5fbef76f0a25d7ee4436	f	\N	2011-11-24 15:45:37.465656	2	1990-01-01	\N	f		t
2430	Tainara Dominique Sousa Maciel	nara@bf.hotmail.com	Tainara	@		1fd1c090d6ea5b4fe0cd07f5502a1353	f	\N	2011-11-24 15:45:39.482437	2	1996-01-01	\N	f		t
2431	Ana Kecia Nascimento	kecia.fernandes03@gmail.com	anakecia	@		d09ea75c220b27e40187fa532fbbb0e3	f	\N	2011-11-24 15:45:53.588077	2	1996-01-01	\N	f		t
3500	NEYLLANY ANDRADE FERNANDES	neyllany@hotmail.com	NEYLLANY A	\N	\N	006f52e9102a8d3be2fe5614f42ba989	f	\N	2012-01-10 18:26:25.973641	0	1980-01-01	\N	f	\N	f
2432	Adriana Rodrigues de Menezes	adrai9ana@gmail.com	Drica Rodrigues	@		102cfa4ff686f3428cfa9a15a230bebe	f	\N	2011-11-24 15:47:17.286196	2	1995-01-01	\N	f		t
2433	Benjamin Kaleu	benjamin_skateboy@yahoo.com.br	Benjamin	@		5cd8dcad01eacbb65a3b917b5f860198	f	\N	2011-11-24 15:47:27.456128	1	1995-01-01	\N	f		t
3501	NINFA IARA SABINO ROCHA DA SILVA	ninfaiar@hotmail.com	NINFA IARA	\N	\N	6cdd60ea0045eb7a6ec44c54d29ed402	f	\N	2012-01-10 18:26:26.125237	0	1980-01-01	\N	f	\N	f
3502	NYKOLAS MAYKO MAIA BARBOSA	nykolasmayko2@globo.com	NYKOLAS MA	\N	\N	1740e8023c61af7c127f92a806afe5c3	f	\N	2012-01-10 18:26:26.177214	0	1980-01-01	\N	f	\N	f
3503	PAULO ANDERSON FERREIRA NOBRE	paulo_anderson14@hotmail.com	PAULO ANDE	\N	\N	53c3bce66e43be4f209556518c2fcb54	f	\N	2012-01-10 18:26:26.326175	0	1980-01-01	\N	f	\N	f
3504	PAULO PEREIRA GUALTER	paulogualter@ig.com.br	PAULO PERE	\N	\N	aa169b49b583a2b5af89203c2b78c67c	f	\N	2012-01-10 18:26:26.434203	0	1980-01-01	\N	f	\N	f
3505	PAULO ROBSON SANTOS DA COSTA	prscsantos@gmail.com	PAULO ROBS	\N	\N	c361bc7b2c033a83d663b8d9fb4be56e	f	\N	2012-01-10 18:26:26.484786	0	1980-01-01	\N	f	\N	f
3506	PEDRO DA SILVA NETO	pedrosneto@hotmail.com.br	PEDRO DA S	\N	\N	9de6d14fff9806d4bcd1ef555be766cd	f	\N	2012-01-10 18:26:26.53821	0	1980-01-01	\N	f	\N	f
3507	PEDRO HENRIQUE GOMES DE OLIVEIRA	henriqueoliveira.r9@hotmail.com	PEDRO HENR	\N	\N	beb22fb694d513edcf5533cf006dfeae	f	\N	2012-01-10 18:26:26.58827	0	1980-01-01	\N	f	\N	f
3508	PEDRO ITALO BONFIM LACERDA	pedro.3v@hotmail.com	PEDRO ITAL	\N	\N	1afa34a7f984eeabdbb0a7d494132ee5	f	\N	2012-01-10 18:26:26.638685	0	1980-01-01	\N	f	\N	f
3509	PEDRO VINNICIUS VIEIRA ALVES CABRAL	pedro1_3@yahoo.com.br	PEDRO VINN	\N	\N	f96c09ef093c6f412d6b361660e01817	f	\N	2012-01-10 18:26:26.692317	0	1980-01-01	\N	f	\N	f
3510	PEDRO VITOR DE SOUSA GUIMARÃES	pedrovitor1@bol.com.br	PEDRO VITO	\N	\N	9fb7ded1b2947449047d91c7eeca78f9	f	\N	2012-01-10 18:26:26.744226	0	1980-01-01	\N	f	\N	f
3593	Luan Pedroza Lima	luan_tdb5@hotmail.com	luanpl92	@luanpl92		f433ffd96c9552a409c86b0d6b90f1da	f	\N	2012-04-29 12:26:27.961808	1	1992-01-01	\N	f	luan_tdb5@hotmail.com	t
3594	Eliascorinthias	eliascorinthias99@hotmail.com	souza100	@		5ba6648d15409364369ae1dc88645dfa	f	\N	2012-06-06 21:18:28.990123	1	1998-01-01	\N	f	eliascorinthias99@hotmail.com	t
3596	Luana Furtunato de Freitas	luh-castanhos@hotmail.com	luanafurtunato	@		6b44d527862197a15101dabb8d4e4843	f	\N	2012-07-09 21:43:58.048471	2	1991-01-01	\N	f	luh-castanhos@hotmail.com	t
3598	Michael Lourenço Bezerra	connectionreverse@gmail.com	Skywalker	@		369e17d76369a1648159e3556d8f8a74	f	\N	2012-07-12 23:38:56.871887	1	1992-01-01	\N	f	connectionreverse@gmail.com	t
3601	Francisco Junior	juniornro11@hotmail.com	junior	@		ad6be9eda436605af89f22832ecc720d	f	\N	2012-10-10 15:31:14.16264	2	1994-01-01	\N	f	juniornro11@hotmail.com	t
3599	Michel Pereira Machado	michelpm2@gmail.com	michelpm2	@		a09e89e29336502e745470a3b102921a	f	\N	2012-09-28 11:37:12.948995	1	2011-01-01	\N	f		t
3600	Emerson Guimarães de Araújo	emersonguimaraes77@yahoo.com	Emerson	@EmersonGuim		7c5a57c11c6a70f1285311f46d789c22	f	\N	2012-10-01 08:39:09.176452	1	1995-01-01	\N	f		t
3602	MAGNA DE OLIVEIRA BRANDAO	magna.negreiros@hotmail.com	magnanegreiros	@magnanegreiros		ec9c482f4e39d26030407e7d62174cc2	f	\N	2012-10-13 19:06:00.924361	2	1988-01-01	\N	f	magna.negreiros@hotmail.com	t
2594	manuel muniz neto 	manuelmunizbneto@hotmail.com	neto...	@		ebb7673be9455ef94f283efd088954ca	f	\N	2011-11-25 15:50:59.862215	1	1987-01-01	\N	f		t
1806	Natália Pereira Da Silva Nobre	nataliapereira.nobre@gmail.com	Talhinha	@		0a85f6fcb0b9e9af5ffa5f939bedbf45	f	\N	2011-11-23 10:30:03.259018	2	1987-01-01	\N	f	nataliaejorge1@hotmail.com	t
2442	reginaldo Ribeiro da Silva	reginaldo.silva069@gmail.com	Reginaldo	@		aa03a765db38845967370fb222cd42be	f	\N	2011-11-24 15:50:34.721298	1	1994-01-01	\N	f		t
2443	Sabrina Ferreira da Silva	sabrina.john@gmail.com	Sabrina	@		a5a74bcf1993dabc48a44168bc11d6b7	f	\N	2011-11-24 15:50:35.445612	2	1995-01-01	\N	f		t
3603	Emanuel Leal Marques	ultramanel@msn.com	DogSpirit	@		e4f6c4e6b24a637392eafc75fe669bf0	f	\N	2012-10-29 23:15:56.972907	1	1986-01-01	\N	f		t
333	CARLOS THAYNAN LIMA DE ANDRADE	thaynan.seliga@gmail.com	Thaynan Lima	@thaynanlima_16	http://www.ministerioyeshua.com.br	a049ae94a68314be93a5938d2a570946	t	2012-10-30 00:23:01.325743	2011-10-16 13:35:21.700643	1	1993-01-01	\N	f	thaynanamojesus@hotmail.com	t
2444	Sabrina Silva	sabrina-fec@hotmail.com	sabrina	@		8c278462dc2f486dd9697edc17eff391	f	\N	2011-11-24 15:51:27.071305	2	1994-01-01	\N	f		t
2614	Nicolas Alessandros Oliveira Menezes	nickplay96@hotmail.com	Nicolas	@		6cb651015a84a980ac1c4e75956d40f7	f	\N	2011-11-25 18:35:05.207123	1	1995-01-01	\N	f		t
2662	PATRICK DE OLIVEIRA	patrick.oliveira09@gmail.com	PATRICK	@		dfbe448b0e4bab4c81001ceefdeff61f	f	\N	2011-11-26 14:45:22.66037	1	1996-01-01	\N	f		t
2445	Carlos Thiago de Andrade Feitosa	thiago-vab@hotmail.com	thiago	@		b89726847ecd67440ee54be8de3b67ce	f	\N	2011-11-24 15:51:36.299846	1	2011-01-01	\N	f		t
3512	PHYLLIPE DO CARMO FELIX	phyllipe_do_carmo@hotmail.com	PHYLLIPE D	\N	\N	66808e327dc79d135ba18e051673d906	f	\N	2012-01-10 18:26:26.846931	0	1980-01-01	\N	f	\N	f
297	CAMILA LINHARES	linhares.mila@gmail.com	Camila	@linharesmila	http://comsolid.org	da132774aa7e0d355360e5ccc87ae411	t	2012-11-19 12:24:44.264108	2011-10-13 16:54:56.049301	2	1989-01-01	\N	t	linhares.mila@gmail.com	t
2446	gilliard de souza maciel	gilliardgdx@gmail.com	gilliard	@		8aa9ac8292be4289ef9ec167f72cda45	f	\N	2011-11-24 15:51:49.253282	1	1994-01-01	\N	f		t
3604	João Pedro Martins Sales	joaopedroms.ifce@gmail.com	João Pedro	@		01ecd4b522c02adf9ee7ea8dd86559a1	f	\N	2012-11-02 10:13:05.530846	1	1989-01-01	\N	f		t
296	Joséé Albertobarros do nascimento	jalbertogod@gmail.com	Bbbbbbbb	@		e3d61d0f1a40f43986b5431ced03e36c	t	2012-11-06 09:02:11.999035	2011-10-12 23:49:00.468359	1	1996-01-01	\N	t		t
2447	Ítalo de Oliveira da Silva Farias	ioliveirafarias@gmail.com	Ítalo	@		7b6adfb91f2441bf425685c6c0100c6c	f	\N	2011-11-24 15:52:18.577109	1	1996-01-01	\N	f		t
2679	Leandro Rodrigues da Silva	leandro_cearamor67@hotmail.com	Leandro	@		7887980fa5afe1d3b72863d46eb015f3	f	\N	2011-11-26 16:03:51.659153	1	1995-01-01	\N	f		t
3513	PRISCILA CARDOSO DO NASCIMENTO	prisna.cardoso@hotmail.com	PRISCILA C	\N	\N	88219212c52f303152f0417b59ebb638	f	\N	2012-01-10 18:26:26.900302	0	1980-01-01	\N	f	\N	f
3514	PRISCILA FEITOSA DE FRANÇA	priscilapff@gmail.com	PRISCILA F	\N	\N	28267ab848bcf807b2ed53c3a8f8fc8a	f	\N	2012-01-10 18:26:26.950809	0	1980-01-01	\N	f	\N	f
3515	RAFAEL ARAGAO OLIVEIRA	raphaeltecnico.fiacao@gmail.com	RAFAEL ARA	\N	\N	1728efbda81692282ba642aafd57be3a	f	\N	2012-01-10 18:26:27.001982	0	1980-01-01	\N	f	\N	f
328	KLEBER DE MELO MESQUITA	kleber099@gmail.com	kleber	@		9144f9c1bcfaecf5841bb17d67a13cb9	t	2012-11-19 15:10:54.14031	2011-10-15 10:10:09.949636	1	1986-01-01	\N	t	kleber099@gmail.com	t
3516	RAFAEL BEZERRA DE OLIVEIRA	rafaelbezerra195@gmail.com.br	RAFAEL BEZ	\N	\N	971e6b87788ada8e69ca7281ff4bc2a3	f	\N	2012-01-10 18:26:27.053711	0	1980-01-01	\N	f	\N	f
3517	RAFAEL SILVA DOMINGOS	rafaelsdomingos@gmail.com	RAFAEL SIL	\N	\N	0c74b7f78409a4022a2c4c5a5ca3ee19	f	\N	2012-01-10 18:26:27.204541	0	1980-01-01	\N	f	\N	f
3518	RAFAEL SOARES RODRIGUES	rafael88.soares@hotmail.com	RAFAEL SOA	\N	\N	c0c7c76d30bd3dcaefc96f40275bdc0a	f	\N	2012-01-10 18:26:27.326224	0	1980-01-01	\N	f	\N	f
3519	RAFAEL VIEIRA MOURA	rafael-.-vieira@hotmail.com	RAFAEL VIE	\N	\N	4fe748fbadcd8ba14fb8ea4472f3f4ad	f	\N	2012-01-10 18:26:27.381386	0	1980-01-01	\N	f	\N	f
3520	RAFAELA DE LIMA SILVA	rafaella02@yahoo.com.br	RAFAELA DE	\N	\N	41f1f19176d383480afa65d325c06ed0	f	\N	2012-01-10 18:26:27.432442	0	1980-01-01	\N	f	\N	f
3521	RAIMUNDO PEREIRA CAVALCANTE NETO	pcnetur27@hotmail.com	RAIMUNDO P	\N	\N	94c7bb58efc3b337800875b5d382a072	f	\N	2012-01-10 18:26:27.484976	0	1980-01-01	\N	f	\N	f
3522	RALPH LEAL HECK	imagomundi@hotmail.com	RALPH LEAL	\N	\N	53c3bce66e43be4f209556518c2fcb54	f	\N	2012-01-10 18:26:27.535581	0	1980-01-01	\N	f	\N	f
3523	RAPHAEL ARAÚJO VASCONCELOS	rapha_araujo_vasconcelos@hotmail.com	RAPHAEL AR	\N	\N	5b8add2a5d98b1a652ea7fd72d942dac	f	\N	2012-01-10 18:26:27.585921	0	1980-01-01	\N	f	\N	f
\.


--
-- TOC entry 2062 (class 0 OID 23525717)
-- Dependencies: 157
-- Data for Name: pessoa_arquivo; Type: TABLE DATA; Schema: public; Owner: comsolid
--

COPY pessoa_arquivo (id_pessoa, foto) FROM stdin;
\.


--
-- TOC entry 2063 (class 0 OID 23525722)
-- Dependencies: 159
-- Data for Name: sala; Type: TABLE DATA; Schema: public; Owner: comsolid
--

COPY sala (id_sala, nome_sala) FROM stdin;
1	RUBY
2	PYTHON
3	JAVA
4	PHP
5	LUA
6	PERL
7	COFFEESCRIPT
8	HASKELL
9	GAMBAS
10	JAVASCRIPT
\.


--
-- TOC entry 2064 (class 0 OID 23525727)
-- Dependencies: 161
-- Data for Name: sexo; Type: TABLE DATA; Schema: public; Owner: comsolid
--

COPY sexo (id_sexo, descricao_sexo, codigo_sexo) FROM stdin;
0	Não Informado	N
1	Masculino	M
2	Feminino	F
\.


--
-- TOC entry 2065 (class 0 OID 23525730)
-- Dependencies: 162
-- Data for Name: tipo_evento; Type: TABLE DATA; Schema: public; Owner: comsolid
--

COPY tipo_evento (id_tipo_evento, nome_tipo_evento) FROM stdin;
1	Palestra
2	Minicurso
3	Oficina
\.


--
-- TOC entry 2066 (class 0 OID 23525735)
-- Dependencies: 164
-- Data for Name: tipo_mensagem_email; Type: TABLE DATA; Schema: public; Owner: comsolid
--

COPY tipo_mensagem_email (id_tipo_mensagem_email, descricao_tipo_mensagem_email) FROM stdin;
1	Confirma��o de cadastro
2	Recuperar senha
3	Recuparar senha telematica
\.


--
-- TOC entry 2067 (class 0 OID 23525738)
-- Dependencies: 165
-- Data for Name: tipo_usuario; Type: TABLE DATA; Schema: public; Owner: comsolid
--

COPY tipo_usuario (id_tipo_usuario, descricao_tipo_usuario) FROM stdin;
1	Coordena��o
2	Organiza��o
3	Participante
\.


SET search_path = armario, pg_catalog;

--
-- TOC entry 2001 (class 2606 OID 33214036)
-- Dependencies: 173 173
-- Name: administrador_pk; Type: CONSTRAINT; Schema: armario; Owner: comsolid; Tablespace: 
--

ALTER TABLE ONLY administrador
    ADD CONSTRAINT administrador_pk PRIMARY KEY (pessoa);


--
-- TOC entry 1999 (class 2606 OID 32817091)
-- Dependencies: 172 172
-- Name: aluno_pk; Type: CONSTRAINT; Schema: armario; Owner: comsolid; Tablespace: 
--

ALTER TABLE ONLY aluno
    ADD CONSTRAINT aluno_pk PRIMARY KEY (matricula);


--
-- TOC entry 1991 (class 2606 OID 32817071)
-- Dependencies: 168 168 168
-- Name: aluno_preferencia_pk; Type: CONSTRAINT; Schema: armario; Owner: comsolid; Tablespace: 
--

ALTER TABLE ONLY aluno_preferencia
    ADD CONSTRAINT aluno_preferencia_pk PRIMARY KEY (id_posicao_armario, id_pessoa);


--
-- TOC entry 1997 (class 2606 OID 32817085)
-- Dependencies: 171 171 171
-- Name: armario_individual_pk; Type: CONSTRAINT; Schema: armario; Owner: comsolid; Tablespace: 
--

ALTER TABLE ONLY armario_individual
    ADD CONSTRAINT armario_individual_pk PRIMARY KEY (id_armario, id_posicao_armario);


--
-- TOC entry 1993 (class 2606 OID 32817080)
-- Dependencies: 170 170
-- Name: armario_pk; Type: CONSTRAINT; Schema: armario; Owner: comsolid; Tablespace: 
--

ALTER TABLE ONLY armario
    ADD CONSTRAINT armario_pk PRIMARY KEY (id_armario);


--
-- TOC entry 1989 (class 2606 OID 32817065)
-- Dependencies: 167 167
-- Name: posicao_armario_pk; Type: CONSTRAINT; Schema: armario; Owner: comsolid; Tablespace: 
--

ALTER TABLE ONLY posicao_armario
    ADD CONSTRAINT posicao_armario_pk PRIMARY KEY (id_posicao_armario);


SET search_path = bv, pg_catalog;

--
-- TOC entry 2003 (class 2606 OID 34527819)
-- Dependencies: 174 174
-- Name: bv_pearson_pk; Type: CONSTRAINT; Schema: bv; Owner: comsolid; Tablespace: 
--

ALTER TABLE ONLY bv_pearson
    ADD CONSTRAINT bv_pearson_pk PRIMARY KEY (login);


SET search_path = public, pg_catalog;

--
-- TOC entry 1937 (class 2606 OID 23525754)
-- Dependencies: 130 130 130
-- Name: caravana_encontro_pk; Type: CONSTRAINT; Schema: public; Owner: comsolid; Tablespace: 
--

ALTER TABLE ONLY caravana_encontro
    ADD CONSTRAINT caravana_encontro_pk PRIMARY KEY (id_caravana, id_encontro);


--
-- TOC entry 1935 (class 2606 OID 23525756)
-- Dependencies: 129 129
-- Name: caravana_pk; Type: CONSTRAINT; Schema: public; Owner: comsolid; Tablespace: 
--

ALTER TABLE ONLY caravana
    ADD CONSTRAINT caravana_pk PRIMARY KEY (id_caravana);


--
-- TOC entry 1940 (class 2606 OID 23525758)
-- Dependencies: 132 132
-- Name: dificuldade_evento_pk; Type: CONSTRAINT; Schema: public; Owner: comsolid; Tablespace: 
--

ALTER TABLE ONLY dificuldade_evento
    ADD CONSTRAINT dificuldade_evento_pk PRIMARY KEY (id_dificuldade_evento);


--
-- TOC entry 1944 (class 2606 OID 23525760)
-- Dependencies: 134 134
-- Name: encontro_horario_pkey; Type: CONSTRAINT; Schema: public; Owner: comsolid; Tablespace: 
--

ALTER TABLE ONLY encontro_horario
    ADD CONSTRAINT encontro_horario_pkey PRIMARY KEY (id_encontro_horario);


--
-- TOC entry 1946 (class 2606 OID 23525762)
-- Dependencies: 137 137 137
-- Name: encontro_participante_pk; Type: CONSTRAINT; Schema: public; Owner: comsolid; Tablespace: 
--

ALTER TABLE ONLY encontro_participante
    ADD CONSTRAINT encontro_participante_pk PRIMARY KEY (id_encontro, id_pessoa);


--
-- TOC entry 1942 (class 2606 OID 23525764)
-- Dependencies: 133 133
-- Name: encontro_pk; Type: CONSTRAINT; Schema: public; Owner: comsolid; Tablespace: 
--

ALTER TABLE ONLY encontro
    ADD CONSTRAINT encontro_pk PRIMARY KEY (id_encontro);


--
-- TOC entry 1948 (class 2606 OID 23525766)
-- Dependencies: 138 138
-- Name: estado_pk; Type: CONSTRAINT; Schema: public; Owner: comsolid; Tablespace: 
--

ALTER TABLE ONLY estado
    ADD CONSTRAINT estado_pk PRIMARY KEY (id_estado);


--
-- TOC entry 1952 (class 2606 OID 23525768)
-- Dependencies: 142 142
-- Name: evento_arquivo_pk; Type: CONSTRAINT; Schema: public; Owner: comsolid; Tablespace: 
--

ALTER TABLE ONLY evento_arquivo
    ADD CONSTRAINT evento_arquivo_pk PRIMARY KEY (id_evento_arquivo);


--
-- TOC entry 1955 (class 2606 OID 23525770)
-- Dependencies: 143 143 143
-- Name: evento_demanda_pk; Type: CONSTRAINT; Schema: public; Owner: comsolid; Tablespace: 
--

ALTER TABLE ONLY evento_demanda
    ADD CONSTRAINT evento_demanda_pk PRIMARY KEY (evento, id_pessoa);


--
-- TOC entry 1957 (class 2606 OID 23525772)
-- Dependencies: 145 145 145
-- Name: evento_palestrante_pk; Type: CONSTRAINT; Schema: public; Owner: comsolid; Tablespace: 
--

ALTER TABLE ONLY evento_palestrante
    ADD CONSTRAINT evento_palestrante_pk PRIMARY KEY (id_evento, id_pessoa);


--
-- TOC entry 1959 (class 2606 OID 23525774)
-- Dependencies: 146 146 146
-- Name: evento_participacao_pk; Type: CONSTRAINT; Schema: public; Owner: comsolid; Tablespace: 
--

ALTER TABLE ONLY evento_participacao
    ADD CONSTRAINT evento_participacao_pk PRIMARY KEY (evento, id_pessoa);


--
-- TOC entry 1950 (class 2606 OID 23525776)
-- Dependencies: 140 140
-- Name: evento_pk; Type: CONSTRAINT; Schema: public; Owner: comsolid; Tablespace: 
--

ALTER TABLE ONLY evento
    ADD CONSTRAINT evento_pk PRIMARY KEY (id_evento);


--
-- TOC entry 1963 (class 2606 OID 23525778)
-- Dependencies: 149 149
-- Name: evento_realizacao_multipla_pkey; Type: CONSTRAINT; Schema: public; Owner: comsolid; Tablespace: 
--

ALTER TABLE ONLY evento_realizacao_multipla
    ADD CONSTRAINT evento_realizacao_multipla_pkey PRIMARY KEY (evento_realizacao_multipla);


--
-- TOC entry 1961 (class 2606 OID 23525780)
-- Dependencies: 147 147
-- Name: evento_realizacao_pk; Type: CONSTRAINT; Schema: public; Owner: comsolid; Tablespace: 
--

ALTER TABLE ONLY evento_realizacao
    ADD CONSTRAINT evento_realizacao_pk PRIMARY KEY (evento);


--
-- TOC entry 1967 (class 2606 OID 23525782)
-- Dependencies: 151 151
-- Name: instituicao_pk; Type: CONSTRAINT; Schema: public; Owner: comsolid; Tablespace: 
--

ALTER TABLE ONLY instituicao
    ADD CONSTRAINT instituicao_pk PRIMARY KEY (id_instituicao);


--
-- TOC entry 1969 (class 2606 OID 23525784)
-- Dependencies: 153 153 153
-- Name: mensagem_email_pk; Type: CONSTRAINT; Schema: public; Owner: comsolid; Tablespace: 
--

ALTER TABLE ONLY mensagem_email
    ADD CONSTRAINT mensagem_email_pk PRIMARY KEY (id_encontro, id_tipo_mensagem_email);


--
-- TOC entry 1971 (class 2606 OID 23525786)
-- Dependencies: 154 154
-- Name: municipio_pk; Type: CONSTRAINT; Schema: public; Owner: comsolid; Tablespace: 
--

ALTER TABLE ONLY municipio
    ADD CONSTRAINT municipio_pk PRIMARY KEY (id_municipio);


--
-- TOC entry 1976 (class 2606 OID 23525788)
-- Dependencies: 157 157
-- Name: pessoa_arquivo_pk; Type: CONSTRAINT; Schema: public; Owner: comsolid; Tablespace: 
--

ALTER TABLE ONLY pessoa_arquivo
    ADD CONSTRAINT pessoa_arquivo_pk PRIMARY KEY (id_pessoa);


--
-- TOC entry 1974 (class 2606 OID 23525790)
-- Dependencies: 156 156
-- Name: pessoa_pk; Type: CONSTRAINT; Schema: public; Owner: comsolid; Tablespace: 
--

ALTER TABLE ONLY pessoa
    ADD CONSTRAINT pessoa_pk PRIMARY KEY (id_pessoa);


--
-- TOC entry 1978 (class 2606 OID 23525792)
-- Dependencies: 159 159
-- Name: sala_pk; Type: CONSTRAINT; Schema: public; Owner: comsolid; Tablespace: 
--

ALTER TABLE ONLY sala
    ADD CONSTRAINT sala_pk PRIMARY KEY (id_sala);


--
-- TOC entry 1980 (class 2606 OID 23525794)
-- Dependencies: 161 161
-- Name: sexo_pk; Type: CONSTRAINT; Schema: public; Owner: comsolid; Tablespace: 
--

ALTER TABLE ONLY sexo
    ADD CONSTRAINT sexo_pk PRIMARY KEY (id_sexo);


--
-- TOC entry 1982 (class 2606 OID 23525796)
-- Dependencies: 162 162
-- Name: tipo_evento_pk; Type: CONSTRAINT; Schema: public; Owner: comsolid; Tablespace: 
--

ALTER TABLE ONLY tipo_evento
    ADD CONSTRAINT tipo_evento_pk PRIMARY KEY (id_tipo_evento);


--
-- TOC entry 1984 (class 2606 OID 23525798)
-- Dependencies: 164 164
-- Name: tipo_mensagem_email_pk; Type: CONSTRAINT; Schema: public; Owner: comsolid; Tablespace: 
--

ALTER TABLE ONLY tipo_mensagem_email
    ADD CONSTRAINT tipo_mensagem_email_pk PRIMARY KEY (id_tipo_mensagem_email);


--
-- TOC entry 1986 (class 2606 OID 23525800)
-- Dependencies: 165 165
-- Name: tipo_usuario_pk; Type: CONSTRAINT; Schema: public; Owner: comsolid; Tablespace: 
--

ALTER TABLE ONLY tipo_usuario
    ADD CONSTRAINT tipo_usuario_pk PRIMARY KEY (id_tipo_usuario);


SET search_path = armario, pg_catalog;

--
-- TOC entry 1994 (class 1259 OID 32817086)
-- Dependencies: 171
-- Name: armario_individual_idx; Type: INDEX; Schema: armario; Owner: comsolid; Tablespace: 
--

CREATE UNIQUE INDEX armario_individual_idx ON armario_individual USING btree (id_pessoa);


--
-- TOC entry 1995 (class 1259 OID 34529136)
-- Dependencies: 171
-- Name: armario_individual_idx1; Type: INDEX; Schema: armario; Owner: comsolid; Tablespace: 
--

CREATE UNIQUE INDEX armario_individual_idx1 ON armario_individual USING btree (codigo_chave);


--
-- TOC entry 1987 (class 1259 OID 32817066)
-- Dependencies: 167
-- Name: posicao_armario_idx; Type: INDEX; Schema: armario; Owner: comsolid; Tablespace: 
--

CREATE UNIQUE INDEX posicao_armario_idx ON posicao_armario USING btree (apelido);


SET search_path = public, pg_catalog;

--
-- TOC entry 1938 (class 1259 OID 23525801)
-- Dependencies: 130 130
-- Name: caravana_encontro_responsavel_idx; Type: INDEX; Schema: public; Owner: comsolid; Tablespace: 
--

CREATE UNIQUE INDEX caravana_encontro_responsavel_idx ON caravana_encontro USING btree (id_encontro, responsavel);


--
-- TOC entry 1972 (class 1259 OID 23525802)
-- Dependencies: 156
-- Name: email_uidx; Type: INDEX; Schema: public; Owner: comsolid; Tablespace: 
--

CREATE UNIQUE INDEX email_uidx ON pessoa USING btree (email);


--
-- TOC entry 1953 (class 1259 OID 23525803)
-- Dependencies: 142
-- Name: evento_arquivomd5_uidx; Type: INDEX; Schema: public; Owner: comsolid; Tablespace: 
--

CREATE UNIQUE INDEX evento_arquivomd5_uidx ON evento_arquivo USING btree (nome_arquivo_md5);


--
-- TOC entry 1964 (class 1259 OID 23525804)
-- Dependencies: 149 149 149 149
-- Name: evento_realizacaomultipla_uidx; Type: INDEX; Schema: public; Owner: comsolid; Tablespace: 
--

CREATE UNIQUE INDEX evento_realizacaomultipla_uidx ON evento_realizacao_multipla USING btree (evento, data, hora_inicio, hora_fim);


--
-- TOC entry 1965 (class 1259 OID 27587796)
-- Dependencies: 151
-- Name: instituicao_indx_unq; Type: INDEX; Schema: public; Owner: comsolid; Tablespace: 
--

CREATE UNIQUE INDEX instituicao_indx_unq ON instituicao USING btree (apelido_instituicao);


SET search_path = armario, pg_catalog;

--
-- TOC entry 2042 (class 2620 OID 32948393)
-- Dependencies: 191 172
-- Name: trgrgeraralunopreferencia; Type: TRIGGER; Schema: armario; Owner: comsolid
--

CREATE TRIGGER trgrgeraralunopreferencia
    AFTER INSERT ON aluno
    FOR EACH ROW
    EXECUTE PROCEDURE public.funcgeraralunopreferencia();


--
-- TOC entry 2043 (class 2620 OID 34549501)
-- Dependencies: 191 172
-- Name: trgrgeraralunopreferencia2; Type: TRIGGER; Schema: armario; Owner: comsolid
--

CREATE TRIGGER trgrgeraralunopreferencia2
    AFTER UPDATE ON aluno
    FOR EACH ROW
    EXECUTE PROCEDURE public.funcgeraralunopreferencia();


--
-- TOC entry 2041 (class 2620 OID 32817394)
-- Dependencies: 189 170
-- Name: trgrgerararmarios; Type: TRIGGER; Schema: armario; Owner: comsolid
--

CREATE TRIGGER trgrgerararmarios
    AFTER INSERT ON armario
    FOR EACH ROW
    EXECUTE PROCEDURE public.funcgerararmarios();


SET search_path = public, pg_catalog;

--
-- TOC entry 2039 (class 2620 OID 23525805)
-- Dependencies: 193 140
-- Name: trgrvalidaevento; Type: TRIGGER; Schema: public; Owner: comsolid
--

CREATE TRIGGER trgrvalidaevento
    BEFORE UPDATE ON evento
    FOR EACH ROW
    EXECUTE PROCEDURE funcvalidaevento();


--
-- TOC entry 2040 (class 2620 OID 23525806)
-- Dependencies: 156 194
-- Name: trgrvalidausuario; Type: TRIGGER; Schema: public; Owner: comsolid
--

CREATE TRIGGER trgrvalidausuario
    BEFORE UPDATE ON pessoa
    FOR EACH ROW
    EXECUTE PROCEDURE funcvalidausuario();


SET search_path = armario, pg_catalog;

--
-- TOC entry 2036 (class 2606 OID 32817118)
-- Dependencies: 171 170 1992
-- Name: armario_armario_individual_fk; Type: FK CONSTRAINT; Schema: armario; Owner: comsolid
--

ALTER TABLE ONLY armario_individual
    ADD CONSTRAINT armario_armario_individual_fk FOREIGN KEY (id_armario) REFERENCES armario(id_armario);


--
-- TOC entry 2038 (class 2606 OID 33214029)
-- Dependencies: 173 156 1973
-- Name: pessoa_administrador_fk; Type: FK CONSTRAINT; Schema: armario; Owner: comsolid
--

ALTER TABLE ONLY administrador
    ADD CONSTRAINT pessoa_administrador_fk FOREIGN KEY (pessoa) REFERENCES public.pessoa(id_pessoa);


--
-- TOC entry 2037 (class 2606 OID 32817093)
-- Dependencies: 156 172 1973
-- Name: pessoa_aluno_fk; Type: FK CONSTRAINT; Schema: armario; Owner: comsolid
--

ALTER TABLE ONLY aluno
    ADD CONSTRAINT pessoa_aluno_fk FOREIGN KEY (id_pessoa) REFERENCES public.pessoa(id_pessoa);


--
-- TOC entry 2032 (class 2606 OID 32817098)
-- Dependencies: 1973 156 168
-- Name: pessoa_aluno_preferencia_fk; Type: FK CONSTRAINT; Schema: armario; Owner: comsolid
--

ALTER TABLE ONLY aluno_preferencia
    ADD CONSTRAINT pessoa_aluno_preferencia_fk FOREIGN KEY (id_pessoa) REFERENCES public.pessoa(id_pessoa);


--
-- TOC entry 2034 (class 2606 OID 32817103)
-- Dependencies: 156 171 1973
-- Name: pessoa_armario_individual_fk; Type: FK CONSTRAINT; Schema: armario; Owner: comsolid
--

ALTER TABLE ONLY armario_individual
    ADD CONSTRAINT pessoa_armario_individual_fk FOREIGN KEY (id_pessoa) REFERENCES public.pessoa(id_pessoa);


--
-- TOC entry 2033 (class 2606 OID 32817113)
-- Dependencies: 167 1988 168
-- Name: posicao_armario_aluno_preferencia_fk; Type: FK CONSTRAINT; Schema: armario; Owner: comsolid
--

ALTER TABLE ONLY aluno_preferencia
    ADD CONSTRAINT posicao_armario_aluno_preferencia_fk FOREIGN KEY (id_posicao_armario) REFERENCES posicao_armario(id_posicao_armario);


--
-- TOC entry 2035 (class 2606 OID 32817108)
-- Dependencies: 1988 171 167
-- Name: posicao_armario_armario_individual_fk; Type: FK CONSTRAINT; Schema: armario; Owner: comsolid
--

ALTER TABLE ONLY armario_individual
    ADD CONSTRAINT posicao_armario_armario_individual_fk FOREIGN KEY (id_posicao_armario) REFERENCES posicao_armario(id_posicao_armario);


SET search_path = public, pg_catalog;

--
-- TOC entry 2008 (class 2606 OID 23525807)
-- Dependencies: 130 1934 129
-- Name: caravana_caravana_encontro_fk; Type: FK CONSTRAINT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY caravana_encontro
    ADD CONSTRAINT caravana_caravana_encontro_fk FOREIGN KEY (id_caravana) REFERENCES caravana(id_caravana);


--
-- TOC entry 2006 (class 2606 OID 23525812)
-- Dependencies: 156 1973 129
-- Name: caravana_criador_fkey; Type: FK CONSTRAINT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY caravana
    ADD CONSTRAINT caravana_criador_fkey FOREIGN KEY (criador) REFERENCES pessoa(id_pessoa);


--
-- TOC entry 2014 (class 2606 OID 23525817)
-- Dependencies: 130 130 137 137 1936
-- Name: caravana_encontro_encontro_participante_fk; Type: FK CONSTRAINT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY encontro_participante
    ADD CONSTRAINT caravana_encontro_encontro_participante_fk FOREIGN KEY (id_caravana, id_encontro) REFERENCES caravana_encontro(id_caravana, id_encontro);


--
-- TOC entry 2018 (class 2606 OID 23525822)
-- Dependencies: 1939 132 140
-- Name: dificuldade_evento_evento_fk; Type: FK CONSTRAINT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY evento
    ADD CONSTRAINT dificuldade_evento_evento_fk FOREIGN KEY (id_dificuldade_evento) REFERENCES dificuldade_evento(id_dificuldade_evento);


--
-- TOC entry 2009 (class 2606 OID 23525827)
-- Dependencies: 130 133 1941
-- Name: encontro_caravana_encontro_fk; Type: FK CONSTRAINT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY caravana_encontro
    ADD CONSTRAINT encontro_caravana_encontro_fk FOREIGN KEY (id_encontro) REFERENCES encontro(id_encontro);


--
-- TOC entry 2015 (class 2606 OID 23525832)
-- Dependencies: 137 133 1941
-- Name: encontro_encontro_participante_fk; Type: FK CONSTRAINT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY encontro_participante
    ADD CONSTRAINT encontro_encontro_participante_fk FOREIGN KEY (id_encontro) REFERENCES encontro(id_encontro);


--
-- TOC entry 2019 (class 2606 OID 23525837)
-- Dependencies: 1941 140 133
-- Name: encontro_evento_fk; Type: FK CONSTRAINT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY evento
    ADD CONSTRAINT encontro_evento_fk FOREIGN KEY (id_encontro) REFERENCES encontro(id_encontro);


--
-- TOC entry 2030 (class 2606 OID 23525842)
-- Dependencies: 1947 138 154
-- Name: estado_municipio_fk; Type: FK CONSTRAINT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY municipio
    ADD CONSTRAINT estado_municipio_fk FOREIGN KEY (id_estado) REFERENCES estado(id_estado);


--
-- TOC entry 2023 (class 2606 OID 23525847)
-- Dependencies: 1949 145 140
-- Name: evento_evento_palestrante_fk; Type: FK CONSTRAINT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY evento_palestrante
    ADD CONSTRAINT evento_evento_palestrante_fk FOREIGN KEY (id_evento) REFERENCES evento(id_evento);


--
-- TOC entry 2027 (class 2606 OID 23525852)
-- Dependencies: 147 140 1949
-- Name: evento_evento_realizacao_fk; Type: FK CONSTRAINT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY evento_realizacao
    ADD CONSTRAINT evento_evento_realizacao_fk FOREIGN KEY (id_evento) REFERENCES evento(id_evento);


--
-- TOC entry 2021 (class 2606 OID 23525857)
-- Dependencies: 143 147 1960
-- Name: evento_realizacao_evento_demanda_fk; Type: FK CONSTRAINT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY evento_demanda
    ADD CONSTRAINT evento_realizacao_evento_demanda_fk FOREIGN KEY (evento) REFERENCES evento_realizacao(evento);


--
-- TOC entry 2024 (class 2606 OID 23525862)
-- Dependencies: 1960 146 147
-- Name: evento_realizacao_evento_participacao_fk; Type: FK CONSTRAINT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY evento_participacao
    ADD CONSTRAINT evento_realizacao_evento_participacao_fk FOREIGN KEY (evento) REFERENCES evento_realizacao(evento);


--
-- TOC entry 2028 (class 2606 OID 23525867)
-- Dependencies: 147 1960 149
-- Name: evento_realizacao_multipla_evento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY evento_realizacao_multipla
    ADD CONSTRAINT evento_realizacao_multipla_evento_fkey FOREIGN KEY (evento) REFERENCES evento_realizacao(evento);


--
-- TOC entry 2016 (class 2606 OID 23525872)
-- Dependencies: 156 140 1973
-- Name: evento_responsavel_fkey; Type: FK CONSTRAINT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY evento
    ADD CONSTRAINT evento_responsavel_fkey FOREIGN KEY (responsavel) REFERENCES pessoa(id_pessoa);


--
-- TOC entry 2004 (class 2606 OID 23525877)
-- Dependencies: 1966 151 129
-- Name: instituicao_caravana_fk; Type: FK CONSTRAINT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY caravana
    ADD CONSTRAINT instituicao_caravana_fk FOREIGN KEY (id_instituicao) REFERENCES instituicao(id_instituicao);


--
-- TOC entry 2010 (class 2606 OID 23525882)
-- Dependencies: 1966 137 151
-- Name: instituicao_encontro_participante_fk; Type: FK CONSTRAINT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY encontro_participante
    ADD CONSTRAINT instituicao_encontro_participante_fk FOREIGN KEY (id_instituicao) REFERENCES instituicao(id_instituicao);


--
-- TOC entry 2005 (class 2606 OID 23525887)
-- Dependencies: 129 1970 154
-- Name: municipio_caravana_fk; Type: FK CONSTRAINT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY caravana
    ADD CONSTRAINT municipio_caravana_fk FOREIGN KEY (id_municipio) REFERENCES municipio(id_municipio);


--
-- TOC entry 2011 (class 2606 OID 23525892)
-- Dependencies: 137 154 1970
-- Name: municipio_encontro_participante_fk; Type: FK CONSTRAINT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY encontro_participante
    ADD CONSTRAINT municipio_encontro_participante_fk FOREIGN KEY (id_municipio) REFERENCES municipio(id_municipio);


--
-- TOC entry 2007 (class 2606 OID 23525897)
-- Dependencies: 130 1973 156
-- Name: pessoa_caravana_encontro_fk; Type: FK CONSTRAINT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY caravana_encontro
    ADD CONSTRAINT pessoa_caravana_encontro_fk FOREIGN KEY (responsavel) REFERENCES pessoa(id_pessoa);


--
-- TOC entry 2012 (class 2606 OID 23525902)
-- Dependencies: 1973 137 156
-- Name: pessoa_encontro_participante_fk; Type: FK CONSTRAINT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY encontro_participante
    ADD CONSTRAINT pessoa_encontro_participante_fk FOREIGN KEY (id_pessoa) REFERENCES pessoa(id_pessoa);


--
-- TOC entry 2020 (class 2606 OID 23525907)
-- Dependencies: 143 156 1973
-- Name: pessoa_evento_demanda_fk; Type: FK CONSTRAINT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY evento_demanda
    ADD CONSTRAINT pessoa_evento_demanda_fk FOREIGN KEY (id_pessoa) REFERENCES pessoa(id_pessoa);


--
-- TOC entry 2022 (class 2606 OID 23525912)
-- Dependencies: 156 1973 145
-- Name: pessoa_evento_palestrante_fk; Type: FK CONSTRAINT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY evento_palestrante
    ADD CONSTRAINT pessoa_evento_palestrante_fk FOREIGN KEY (id_pessoa) REFERENCES pessoa(id_pessoa);


--
-- TOC entry 2025 (class 2606 OID 23525917)
-- Dependencies: 1973 156 146
-- Name: pessoa_evento_participacao_fk; Type: FK CONSTRAINT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY evento_participacao
    ADD CONSTRAINT pessoa_evento_participacao_fk FOREIGN KEY (id_pessoa) REFERENCES pessoa(id_pessoa);


--
-- TOC entry 2026 (class 2606 OID 23525922)
-- Dependencies: 147 1977 159
-- Name: sala_evento_realizacao_fk; Type: FK CONSTRAINT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY evento_realizacao
    ADD CONSTRAINT sala_evento_realizacao_fk FOREIGN KEY (id_sala) REFERENCES sala(id_sala);


--
-- TOC entry 2031 (class 2606 OID 23525927)
-- Dependencies: 1979 161 156
-- Name: sexo_pessoa_fk; Type: FK CONSTRAINT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY pessoa
    ADD CONSTRAINT sexo_pessoa_fk FOREIGN KEY (id_sexo) REFERENCES sexo(id_sexo);


--
-- TOC entry 2017 (class 2606 OID 23525932)
-- Dependencies: 1981 162 140
-- Name: tipo_evento_evento_fk; Type: FK CONSTRAINT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY evento
    ADD CONSTRAINT tipo_evento_evento_fk FOREIGN KEY (id_tipo_evento) REFERENCES tipo_evento(id_tipo_evento);


--
-- TOC entry 2029 (class 2606 OID 23525937)
-- Dependencies: 164 1983 153
-- Name: tipo_mensagem_email_mensagem_email_fk; Type: FK CONSTRAINT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY mensagem_email
    ADD CONSTRAINT tipo_mensagem_email_mensagem_email_fk FOREIGN KEY (id_tipo_mensagem_email) REFERENCES tipo_mensagem_email(id_tipo_mensagem_email);


--
-- TOC entry 2013 (class 2606 OID 23525942)
-- Dependencies: 1985 165 137
-- Name: tipo_usuario_encontro_participante_fk; Type: FK CONSTRAINT; Schema: public; Owner: comsolid
--

ALTER TABLE ONLY encontro_participante
    ADD CONSTRAINT tipo_usuario_encontro_participante_fk FOREIGN KEY (id_tipo_usuario) REFERENCES tipo_usuario(id_tipo_usuario);


--
-- TOC entry 2079 (class 0 OID 0)
-- Dependencies: 3
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2012-11-20 11:48:13 BRT

--
-- PostgreSQL database dump complete
--

