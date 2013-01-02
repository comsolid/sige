--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'LATIN1';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

--
-- Name: funcgeraralunopreferencia(); Type: FUNCTION; Schema: public; Owner: -
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


--
-- Name: funcgerararmarios(); Type: FUNCTION; Schema: public; Owner: -
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


--
-- Name: funcgerarsenha(character varying); Type: FUNCTION; Schema: public; Owner: -
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


--
-- Name: funcinseriraluno(bigint, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
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


--
-- Name: funcselecionararmario(integer); Type: FUNCTION; Schema: public; Owner: -
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


--
-- Name: funcsorteararmario(); Type: FUNCTION; Schema: public; Owner: -
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


--
-- Name: funcsorteararmarios(); Type: FUNCTION; Schema: public; Owner: -
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


--
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


SET default_tablespace = '';

SET default_with_oids = false;

--
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
-- Name: caravana_encontro; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE caravana_encontro (
    id_caravana integer NOT NULL,
    id_encontro integer NOT NULL,
    responsavel integer NOT NULL,
    validada boolean DEFAULT false NOT NULL
);


--
-- Name: COLUMN caravana_encontro.responsavel; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN caravana_encontro.responsavel IS 'Respons�vel pela caravana.
Seu cadastro deve estar realizado previamente.';


--
-- Name: caravana_id_caravana_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE caravana_id_caravana_seq
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: caravana_id_caravana_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE caravana_id_caravana_seq OWNED BY caravana.id_caravana;


--
-- Name: dificuldade_evento; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE dificuldade_evento (
    id_dificuldade_evento integer NOT NULL,
    descricao_dificuldade_evento character varying(15) NOT NULL
);


--
-- Name: TABLE dificuldade_evento; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE dificuldade_evento IS 'Mostra o n�vel de dificuldade do Evento.
B�sico
Intermedi�rio
Avan�ado';


--
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
-- Name: encontro_horario_id_encontro_horario_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE encontro_horario_id_encontro_horario_seq
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: encontro_horario_id_encontro_horario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE encontro_horario_id_encontro_horario_seq OWNED BY encontro_horario.id_encontro_horario;


--
-- Name: encontro_id_encontro_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE encontro_id_encontro_seq
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: encontro_id_encontro_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE encontro_id_encontro_seq OWNED BY encontro.id_encontro;


--
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
-- Name: estado; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE estado (
    id_estado integer NOT NULL,
    nome_estado character varying(30) NOT NULL,
    codigo_estado character(2) NOT NULL
);


--
-- Name: estado_id_estado_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE estado_id_estado_seq
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: estado_id_estado_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE estado_id_estado_seq OWNED BY estado.id_estado;


--
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
    curriculum text DEFAULT 'Curriculum B�sico'::text NOT NULL,
    id_dificuldade_evento integer DEFAULT 1 NOT NULL,
    perfil_minimo text DEFAULT 'Perfil M�nimo do Participante'::text NOT NULL,
    preferencia_horario text
);


--
-- Name: TABLE evento; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE evento IS 'Evento � qualquer tipo de atividade no Encontro: Palestra, Minicurso, Oficina.';


--
-- Name: COLUMN evento.validada; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN evento.validada IS 'O administrador deve indicar qual o evento aprovado.';


--
-- Name: evento_arquivo_id_evento_arquivo_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE evento_arquivo_id_evento_arquivo_seq
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
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
-- Name: evento_demanda; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE evento_demanda (
    evento integer NOT NULL,
    id_pessoa integer NOT NULL,
    data_solicitacao date DEFAULT now() NOT NULL
);


--
-- Name: evento_id_evento_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE evento_id_evento_seq
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: evento_id_evento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE evento_id_evento_seq OWNED BY evento.id_evento;


--
-- Name: evento_palestrante; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE evento_palestrante (
    id_evento integer NOT NULL,
    id_pessoa integer NOT NULL
);


--
-- Name: evento_participacao; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE evento_participacao (
    evento integer NOT NULL,
    id_pessoa integer NOT NULL
);


--
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
-- Name: evento_realizacao_evento_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE evento_realizacao_evento_seq
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: evento_realizacao_evento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE evento_realizacao_evento_seq OWNED BY evento_realizacao.evento;


--
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
-- Name: evento_realizacao_multipla_evento_realizacao_multipla_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE evento_realizacao_multipla_evento_realizacao_multipla_seq
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: evento_realizacao_multipla_evento_realizacao_multipla_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE evento_realizacao_multipla_evento_realizacao_multipla_seq OWNED BY evento_realizacao_multipla.evento_realizacao_multipla;


--
-- Name: instituicao; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE instituicao (
    id_instituicao integer NOT NULL,
    nome_instituicao character varying(100) NOT NULL,
    apelido_instituicao character varying(50) NOT NULL
);


--
-- Name: TABLE instituicao; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE instituicao IS 'Institui��o de origem da pessoa. Escola, Comunidade.';


--
-- Name: COLUMN instituicao.apelido_instituicao; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN instituicao.apelido_instituicao IS 'EEMF Adauto Bezerra.
Essa informa��o pode estar no CRACH�.';


--
-- Name: instituicao_id_instituicao_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE instituicao_id_instituicao_seq
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: instituicao_id_instituicao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE instituicao_id_instituicao_seq OWNED BY instituicao.id_instituicao;


--
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
-- Name: municipio; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE municipio (
    id_municipio integer NOT NULL,
    nome_municipio character varying(40) NOT NULL,
    id_estado integer NOT NULL
);


--
-- Name: municipio_id_municipio_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE municipio_id_municipio_seq
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: municipio_id_municipio_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE municipio_id_municipio_seq OWNED BY municipio.id_municipio;


--
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
    email_enviado boolean DEFAULT false NOT NULL
);


--
-- Name: COLUMN pessoa.nome; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN pessoa.nome IS 'Nome completo e em letra Mai�scula';


--
-- Name: COLUMN pessoa.email; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN pessoa.email IS 'email em letra min�scula';


--
-- Name: COLUMN pessoa.twitter; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN pessoa.twitter IS 'Iniciando com @';


--
-- Name: COLUMN pessoa.endereco_internet; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN pessoa.endereco_internet IS 'Um endere�o come�ando com http:// indicando onde est�o as informa��es da pessoa.
Pode ser um blog, p�gina do facebook, site...';


--
-- Name: COLUMN pessoa.senha; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN pessoa.senha IS 'Senha do usu�rio usando criptografia md5 do comsolid.
Valor padr�o vai ser o pr�prio nome do usu�rio.';


--
-- Name: COLUMN pessoa.email_enviado; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN pessoa.email_enviado IS 'Indica se o sistema conseguiu conectar a um servidor de email e validar o email.';


--
-- Name: pessoa_arquivo; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE pessoa_arquivo (
    id_pessoa integer NOT NULL,
    foto oid NOT NULL
);


--
-- Name: pessoa_id_pessoa_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE pessoa_id_pessoa_seq
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pessoa_id_pessoa_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE pessoa_id_pessoa_seq OWNED BY pessoa.id_pessoa;


--
-- Name: sala; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sala (
    id_sala integer NOT NULL,
    nome_sala character varying(20) NOT NULL
);


--
-- Name: sala_id_sala_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sala_id_sala_seq
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sala_id_sala_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sala_id_sala_seq OWNED BY sala.id_sala;


--
-- Name: sexo; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sexo (
    id_sexo integer NOT NULL,
    descricao_sexo character varying(15) NOT NULL,
    codigo_sexo character(1) NOT NULL
);


--
-- Name: tipo_evento; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tipo_evento (
    id_tipo_evento integer NOT NULL,
    nome_tipo_evento character varying(20) NOT NULL
);


--
-- Name: TABLE tipo_evento; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE tipo_evento IS 'Tipos de Eventos: Palestra, Minicurso, Oficina.';


--
-- Name: tipo_evento_id_tipo_evento_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tipo_evento_id_tipo_evento_seq
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tipo_evento_id_tipo_evento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tipo_evento_id_tipo_evento_seq OWNED BY tipo_evento.id_tipo_evento;


--
-- Name: tipo_mensagem_email; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tipo_mensagem_email (
    id_tipo_mensagem_email integer NOT NULL,
    descricao_tipo_mensagem_email character varying(30) NOT NULL
);


--
-- Name: tipo_usuario; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tipo_usuario (
    id_tipo_usuario integer NOT NULL,
    descricao_tipo_usuario character varying(15) NOT NULL
);


--
-- Name: id_caravana; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY caravana ALTER COLUMN id_caravana SET DEFAULT nextval('caravana_id_caravana_seq'::regclass);


--
-- Name: id_encontro; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY encontro ALTER COLUMN id_encontro SET DEFAULT nextval('encontro_id_encontro_seq'::regclass);


--
-- Name: id_encontro_horario; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY encontro_horario ALTER COLUMN id_encontro_horario SET DEFAULT nextval('encontro_horario_id_encontro_horario_seq'::regclass);


--
-- Name: id_estado; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY estado ALTER COLUMN id_estado SET DEFAULT nextval('estado_id_estado_seq'::regclass);


--
-- Name: id_evento; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento ALTER COLUMN id_evento SET DEFAULT nextval('evento_id_evento_seq'::regclass);


--
-- Name: evento; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_realizacao ALTER COLUMN evento SET DEFAULT nextval('evento_realizacao_evento_seq'::regclass);


--
-- Name: evento_realizacao_multipla; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_realizacao_multipla ALTER COLUMN evento_realizacao_multipla SET DEFAULT nextval('evento_realizacao_multipla_evento_realizacao_multipla_seq'::regclass);


--
-- Name: id_instituicao; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY instituicao ALTER COLUMN id_instituicao SET DEFAULT nextval('instituicao_id_instituicao_seq'::regclass);


--
-- Name: id_municipio; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY municipio ALTER COLUMN id_municipio SET DEFAULT nextval('municipio_id_municipio_seq'::regclass);


--
-- Name: id_pessoa; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY pessoa ALTER COLUMN id_pessoa SET DEFAULT nextval('pessoa_id_pessoa_seq'::regclass);


--
-- Name: id_sala; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sala ALTER COLUMN id_sala SET DEFAULT nextval('sala_id_sala_seq'::regclass);


--
-- Name: id_tipo_evento; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tipo_evento ALTER COLUMN id_tipo_evento SET DEFAULT nextval('tipo_evento_id_tipo_evento_seq'::regclass);


--
-- Data for Name: caravana; Type: TABLE DATA; Schema: public; Owner: -
--

COPY caravana (id_caravana, nome_caravana, apelido_caravana, id_municipio, id_instituicao, criador) FROM stdin;
50	AS Malucas do novo	new maluc	1	2	328
51	IFCE COMSOLiD	IFSolid	101	3	304
53	Técnico em Informática ETM	Tec ETM	101	61	297
54	Parque Jeruzalém	Jeruzalém	182	1	819
\.


--
-- Data for Name: caravana_encontro; Type: TABLE DATA; Schema: public; Owner: -
--

COPY caravana_encontro (id_caravana, id_encontro, responsavel, validada) FROM stdin;
50	1	328	f
51	1	304	f
53	1	297	f
54	1	819	f
\.


--
-- Name: caravana_id_caravana_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('caravana_id_caravana_seq', 54, true);


--
-- Data for Name: dificuldade_evento; Type: TABLE DATA; Schema: public; Owner: -
--

COPY dificuldade_evento (id_dificuldade_evento, descricao_dificuldade_evento) FROM stdin;
1	Básico
2	Intermediário
3	Avançado
\.


--
-- Data for Name: encontro; Type: TABLE DATA; Schema: public; Owner: -
--

COPY encontro (id_encontro, nome_encontro, apelido_encontro, data_inicio, data_fim, ativo) FROM stdin;
1	4o. Encontro da COMSOLiD	COMSOLiD^4	2011-11-09	2011-11-12	f
2	5� Encontro da COMSOLID	COMSOLiD+5	2012-12-06	2012-12-08	t
\.


--
-- Data for Name: encontro_horario; Type: TABLE DATA; Schema: public; Owner: -
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
-- Name: encontro_horario_id_encontro_horario_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('encontro_horario_id_encontro_horario_seq', 1, false);


--
-- Name: encontro_id_encontro_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('encontro_id_encontro_seq', 3, true);


--
-- Data for Name: encontro_participante; Type: TABLE DATA; Schema: public; Owner: -
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
2	5450	205	101	\N	3	f	\N	2012-12-08 23:37:47.631989	f	\N
2	3653	3	101	\N	3	f	\N	2012-11-23 23:31:34.1705	t	2012-12-06 09:33:42.090293
2	433	3	101	\N	3	f	\N	2012-11-22 13:25:16.517253	f	\N
2	5348	41	182	\N	3	f	\N	2012-12-07 22:02:32.430003	f	\N
2	1831	82	102	\N	3	f	\N	2012-11-21 13:49:03.809323	f	\N
2	5178	205	84	\N	3	f	\N	2012-12-07 09:34:59.059281	t	2012-12-07 09:35:33.819193
2	978	3	182	\N	3	f	\N	2012-11-21 17:35:18.75934	f	\N
2	3618	3	182	\N	3	f	\N	2012-11-22 18:15:03.276931	f	\N
2	3629	3	101	\N	3	f	\N	2012-11-22 19:45:27.795589	t	2012-12-07 09:45:31.514877
2	3622	205	182	\N	3	f	\N	2012-11-22 18:28:42.427059	f	\N
2	3625	1	182	\N	3	f	\N	2012-11-22 18:54:42.606928	f	\N
2	5365	98	64	\N	3	f	\N	2012-12-08 09:46:49.972425	t	2012-12-08 09:47:49.782494
2	444	3	101	\N	3	f	\N	2012-11-22 18:31:15.34471	t	2012-12-07 09:53:50.246311
2	3627	41	182	\N	3	f	\N	2012-11-22 19:35:01.564545	f	\N
2	3628	41	182	\N	3	f	\N	2012-11-22 19:44:31.710004	f	\N
2	596	3	101	\N	3	f	\N	2012-11-22 20:30:02.033053	f	\N
2	3630	194	182	\N	3	f	\N	2012-11-22 22:16:23.918872	f	\N
2	3631	194	182	\N	3	f	\N	2012-11-22 22:31:45.829437	f	\N
2	3634	1	182	\N	3	f	\N	2012-11-22 22:38:57.26307	f	\N
2	3636	3	182	\N	3	f	\N	2012-11-22 23:04:59.338898	f	\N
2	3637	1	101	\N	3	f	\N	2012-11-22 23:10:13.218365	f	\N
2	3638	41	182	\N	3	f	\N	2012-11-23 00:09:54.978753	f	\N
2	3878	41	182	\N	3	f	\N	2012-11-28 22:59:48.905405	t	2012-12-07 09:55:48.986278
2	3640	41	182	\N	3	f	\N	2012-11-23 07:56:06.894991	f	\N
2	5204	205	122	\N	3	f	\N	2012-12-07 10:40:29.139013	f	\N
2	3641	205	42	\N	3	f	\N	2012-11-23 10:20:07.9861	f	\N
2	3642	205	182	\N	3	f	\N	2012-11-23 17:51:25.44881	f	\N
2	399	3	101	\N	3	f	\N	2012-11-23 19:06:05.029931	f	\N
1	1438	3	125	\N	3	f	\N	2011-11-22 16:46:22.066317	t	2011-11-25 10:34:10.964287
1	550	3	182	\N	3	f	\N	2011-11-04 09:04:28.48115	t	2011-11-25 10:34:22.280408
1	336	1	182	\N	3	f	\N	2011-10-17 12:21:34.8845	t	2011-11-25 10:42:40.77858
1	1052	3	101	\N	3	f	\N	2011-11-19 14:00:38.838496	t	2011-11-25 10:49:28.491028
1	2564	1	182	\N	3	f	\N	2011-11-25 10:49:44.516971	t	2011-11-25 10:50:00.287652
2	1310	1	182	\N	3	f	\N	2012-11-23 18:28:36.554323	t	2012-12-07 10:47:01.445025
1	2565	1	182	\N	3	f	\N	2011-11-25 10:50:16.657833	t	2011-11-25 10:50:58.948736
2	3646	3	101	\N	3	f	\N	2012-11-23 20:03:22.284436	f	\N
1	1638	41	182	\N	3	f	\N	2011-11-22 20:49:59.820409	t	2011-11-25 10:52:11.840181
2	3647	3	182	\N	3	f	\N	2012-11-23 20:10:03.941428	f	\N
1	2567	1	146	\N	3	f	\N	2011-11-25 11:14:13.765168	t	2011-11-25 11:15:09.540368
1	2568	1	101	\N	3	f	\N	2011-11-25 11:14:14.155638	f	\N
2	3648	185	182	\N	3	f	\N	2012-11-23 20:28:35.409969	f	\N
1	299	1	101	53	3	f	\N	2011-10-13 19:14:47.697442	t	2011-11-25 11:20:04.058759
1	2569	3	101	\N	3	f	\N	2011-11-25 11:32:12.265401	f	\N
1	2570	1	1	\N	3	f	\N	2011-11-25 11:42:53.374068	f	\N
1	2572	1	101	\N	3	f	\N	2011-11-25 13:08:09.872374	t	2011-11-25 14:16:58.621135
1	2573	204	32	\N	3	f	\N	2011-11-25 13:35:57.174926	f	\N
1	2574	3	101	\N	3	f	\N	2011-11-25 13:55:39.849006	t	2011-11-25 13:55:58.448832
2	5215	1	182	\N	3	f	\N	2012-12-07 10:46:51.982183	t	2012-12-07 10:47:03.274481
1	2575	1	182	\N	3	f	\N	2011-11-25 13:57:02.099514	f	\N
1	2576	1	101	\N	3	f	\N	2011-11-25 14:16:01.231377	t	2011-11-25 14:16:30.311228
1	2577	80	101	\N	3	f	\N	2011-11-25 14:16:28.422785	t	2011-11-25 14:16:39.352415
2	1883	1	182	\N	3	f	\N	2012-11-23 23:11:51.693737	f	\N
1	2578	1	101	\N	3	f	\N	2011-11-25 14:18:57.072426	t	2011-11-25 14:19:13.921414
2	3652	205	182	\N	3	f	\N	2012-11-23 22:25:52.608977	t	2012-12-08 09:50:50.282417
1	2579	3	101	\N	3	f	\N	2011-11-25 14:21:41.494836	t	2011-11-25 14:22:22.500799
2	3655	3	182	\N	3	f	\N	2012-11-23 23:37:38.680833	f	\N
1	2580	3	101	\N	3	f	\N	2011-11-25 14:25:18.636994	t	2011-11-25 14:25:44.659996
2	1021	3	101	\N	3	f	\N	2012-11-24 00:17:45.70535	f	\N
1	2581	1	42	\N	3	f	\N	2011-11-25 14:39:41.616363	t	2011-11-25 14:41:17.324347
2	3656	205	101	\N	3	f	\N	2012-11-24 00:21:49.326284	f	\N
1	302	3	101	\N	3	f	\N	2011-10-13 20:43:29.01891	t	2011-11-25 14:44:31.912283
1	2582	1	125	\N	3	f	\N	2011-11-25 15:06:28.349098	t	2011-11-25 15:06:43.31426
2	3657	41	101	\N	3	f	\N	2012-11-24 01:28:55.59212	f	\N
1	2583	1	101	\N	3	f	\N	2011-11-25 15:08:07.406706	t	2011-11-25 15:09:20.865492
2	5194	205	122	\N	3	f	\N	2012-12-07 10:31:00.682387	t	2012-12-08 10:05:34.300269
1	2584	1	125	\N	3	f	\N	2011-11-25 15:10:12.519297	t	2011-11-25 15:10:22.022946
2	3659	205	182	\N	3	f	\N	2012-11-24 02:12:56.378274	f	\N
1	2586	1	101	\N	3	f	\N	2011-11-25 15:12:10.482251	t	2011-11-25 15:13:54.613218
1	2588	1	101	\N	3	f	\N	2011-11-25 15:21:47.63331	t	2011-11-25 15:23:05.465366
2	5241	205	122	\N	3	f	\N	2012-12-07 11:05:38.631481	t	2012-12-08 10:05:42.811723
2	1083	1	101	\N	3	f	\N	2012-11-24 02:14:24.34304	f	\N
1	323	3	101	\N	3	f	\N	2011-10-15 00:01:28.109928	t	2011-11-25 15:27:09.839256
2	3660	61	101	\N	3	f	\N	2012-11-24 09:00:49.634612	f	\N
2	3623	1	182	\N	3	f	\N	2012-11-22 18:35:36.837247	t	2012-12-08 10:08:32.435788
2	3662	205	101	\N	3	f	\N	2012-11-24 17:04:49.57593	f	\N
2	5387	191	182	\N	3	f	\N	2012-12-08 10:21:37.668281	t	2012-12-08 10:22:03.601559
2	3665	200	182	\N	3	f	\N	2012-11-24 22:48:41.655392	f	\N
2	3677	205	75	\N	3	f	\N	2012-11-26 10:03:08.037503	f	\N
2	5397	191	182	\N	3	f	\N	2012-12-08 10:27:54.778194	t	2012-12-08 10:28:05.730377
2	3666	203	101	\N	3	f	\N	2012-11-25 00:55:23.168124	f	\N
2	5451	205	182	\N	3	f	\N	2012-12-11 09:23:01.740986	f	\N
2	3668	205	146	\N	3	f	\N	2012-11-25 01:49:22.935987	f	\N
2	3669	1	84	\N	3	f	\N	2012-11-25 11:05:56.259248	f	\N
2	3671	205	101	\N	3	f	\N	2012-11-25 13:01:19.612429	f	\N
2	3672	205	182	\N	3	f	\N	2012-11-25 13:23:38.475365	f	\N
2	3673	205	182	\N	3	f	\N	2012-11-25 14:37:52.159478	f	\N
2	3674	205	182	\N	3	f	\N	2012-11-25 16:28:13.673858	f	\N
2	3603	1	182	\N	3	f	\N	2012-11-25 20:37:52.686095	f	\N
2	3678	1	1	\N	3	f	\N	2012-11-26 10:35:49.282493	f	\N
2	3682	204	32	\N	3	f	\N	2012-11-26 10:46:51.593964	f	\N
2	5349	41	182	\N	3	f	\N	2012-12-07 22:04:10.394686	f	\N
2	3684	205	182	\N	3	f	\N	2012-11-26 13:35:25.567424	f	\N
2	3685	1	125	\N	3	f	\N	2012-11-26 15:06:35.465637	f	\N
2	3687	205	182	\N	3	f	\N	2012-11-26 17:36:13.325713	f	\N
2	3753	205	182	\N	3	f	\N	2012-11-27 16:42:16.641508	t	2012-12-07 09:19:34.908017
2	3771	205	182	\N	3	f	\N	2012-11-27 19:25:09.643537	t	2012-12-07 09:22:25.998981
2	3690	21	101	\N	3	f	\N	2012-11-26 19:55:12.652984	f	\N
2	3691	3	182	\N	3	f	\N	2012-11-26 20:12:57.345565	f	\N
2	3692	1	42	\N	3	f	\N	2012-11-26 21:37:27.0803	f	\N
2	3693	205	182	\N	3	f	\N	2012-11-26 21:42:58.63044	f	\N
2	4263	67	101	\N	3	f	\N	2012-12-03 12:06:29.742006	t	2012-12-07 09:35:36.00223
2	3696	71	101	\N	3	f	\N	2012-11-26 22:54:14.231247	f	\N
2	3697	191	182	\N	3	f	\N	2012-11-26 23:04:47.87596	f	\N
2	3698	1	125	\N	3	f	\N	2012-11-26 23:06:12.509336	f	\N
2	5205	134	150	\N	3	f	\N	2012-12-07 10:40:31.649296	t	2012-12-08 09:28:47.016087
2	3707	41	101	\N	3	f	\N	2012-11-26 23:23:01.629701	f	\N
2	3802	1	101	\N	3	f	\N	2012-11-27 22:40:09.20284	t	2012-12-08 09:32:56.617679
2	2636	1	64	\N	3	f	\N	2012-11-27 16:35:45.117938	t	2012-12-07 09:42:51.693217
2	3710	205	182	\N	3	f	\N	2012-11-26 23:30:31.223658	f	\N
2	316	1	182	\N	3	f	\N	2012-11-26 23:31:59.596589	f	\N
2	3712	1	101	\N	3	f	\N	2012-11-26 23:54:09.941437	f	\N
2	3714	205	182	\N	3	f	\N	2012-11-26 23:59:26.084117	f	\N
2	3717	204	32	\N	3	f	\N	2012-11-27 00:05:24.0527	f	\N
2	3718	48	49	\N	3	f	\N	2012-11-27 00:05:45.524789	f	\N
2	3722	50	1	\N	3	f	\N	2012-11-27 00:22:02.460563	f	\N
2	5160	194	182	\N	3	f	\N	2012-12-07 01:01:00.223298	t	2012-12-07 09:57:48.887927
2	3725	1	182	\N	3	f	\N	2012-11-27 00:31:06.77291	f	\N
2	3726	41	182	\N	3	f	\N	2012-11-27 00:35:59.960825	f	\N
2	5195	134	150	\N	3	f	\N	2012-12-07 10:32:04.183841	f	\N
2	3728	41	182	\N	3	f	\N	2012-11-27 00:49:17.480508	f	\N
2	3734	3	182	\N	3	f	\N	2012-11-27 08:25:33.591217	f	\N
2	631	3	101	\N	3	f	\N	2012-11-27 09:30:27.001822	f	\N
2	3735	205	182	\N	3	f	\N	2012-11-27 10:15:41.526425	f	\N
2	3738	205	182	\N	3	f	\N	2012-11-27 10:33:21.881842	f	\N
2	2121	101	101	\N	3	f	\N	2012-11-27 11:04:25.424464	f	\N
2	3739	205	182	\N	3	f	\N	2012-11-27 11:12:21.617778	f	\N
2	3740	205	182	\N	3	f	\N	2012-11-27 11:26:56.310227	f	\N
2	3741	205	122	\N	3	f	\N	2012-11-27 11:42:00.831948	f	\N
2	3744	50	91	\N	3	f	\N	2012-11-27 12:17:45.187333	f	\N
2	3746	205	182	\N	3	f	\N	2012-11-27 14:51:09.821886	f	\N
2	3747	205	182	\N	3	f	\N	2012-11-27 15:30:50.511521	f	\N
2	5216	134	150	\N	3	f	\N	2012-12-07 10:47:01.196053	f	\N
2	3751	205	39	\N	3	f	\N	2012-11-27 16:15:26.890762	f	\N
2	3749	1	101	\N	3	f	\N	2012-11-27 16:01:19.620264	f	\N
2	3754	41	182	\N	3	f	\N	2012-11-27 17:03:20.479634	f	\N
2	3755	3	101	\N	3	f	\N	2012-11-27 17:08:14.859633	f	\N
2	3756	205	146	\N	3	f	\N	2012-11-27 17:46:53.99819	f	\N
2	5366	1	1	\N	3	f	\N	2012-12-08 09:48:52.346543	t	2012-12-08 09:50:03.148738
2	3760	72	101	\N	3	f	\N	2012-11-27 18:31:15.147347	f	\N
2	3761	201	182	\N	3	f	\N	2012-11-27 18:39:16.526158	f	\N
2	3711	205	122	\N	3	f	\N	2012-11-26 23:36:06.00348	t	2012-12-08 09:57:15.031933
2	3767	201	182	\N	3	f	\N	2012-11-27 19:03:02.373626	f	\N
2	3769	201	182	\N	3	f	\N	2012-11-27 19:11:25.613001	f	\N
2	3770	201	182	\N	3	f	\N	2012-11-27 19:17:56.709777	f	\N
2	3772	205	182	\N	3	f	\N	2012-11-27 19:44:19.065941	f	\N
2	3773	201	182	\N	3	f	\N	2012-11-27 19:59:34.44485	f	\N
2	3774	185	182	\N	3	f	\N	2012-11-27 19:59:52.542224	f	\N
2	3775	185	182	\N	3	f	\N	2012-11-27 20:01:39.851396	f	\N
2	3777	205	25	\N	3	f	\N	2012-11-27 20:02:51.273915	f	\N
2	3778	1	25	\N	3	f	\N	2012-11-27 20:05:01.674242	f	\N
2	3779	185	182	\N	3	f	\N	2012-11-27 20:10:19.692581	f	\N
2	3780	1	25	\N	3	f	\N	2012-11-27 20:13:39.035571	f	\N
2	3781	205	25	\N	3	f	\N	2012-11-27 20:21:11.35139	f	\N
2	3784	205	182	\N	3	f	\N	2012-11-27 20:25:12.359513	f	\N
2	3786	1	25	\N	3	f	\N	2012-11-27 20:25:46.106777	f	\N
2	3787	205	25	\N	3	f	\N	2012-11-27 20:32:31.493824	f	\N
2	4155	111	159	\N	3	f	\N	2012-11-30 23:16:53.09392	t	2012-12-07 10:59:09.262786
2	462	3	101	\N	3	f	\N	2012-11-27 20:40:41.502045	f	\N
2	3791	205	25	\N	3	f	\N	2012-11-27 21:01:59.749775	f	\N
2	3792	205	25	\N	3	f	\N	2012-11-27 21:05:13.285838	f	\N
2	3965	111	159	\N	3	f	\N	2012-11-29 18:50:24.432888	t	2012-12-07 11:00:57.960675
2	3795	205	25	\N	3	f	\N	2012-11-27 21:18:19.179998	f	\N
2	3796	205	25	\N	3	f	\N	2012-11-27 21:19:08.610979	f	\N
2	3797	205	25	\N	3	f	\N	2012-11-27 21:47:43.061487	f	\N
2	3798	201	182	\N	3	f	\N	2012-11-27 22:30:14.310224	f	\N
2	3742	205	122	\N	3	f	\N	2012-11-27 11:45:02.405767	t	2012-12-08 09:59:00.09862
2	3803	1	42	\N	3	f	\N	2012-11-27 22:43:03.834987	f	\N
2	3804	205	101	\N	3	f	\N	2012-11-27 23:49:51.302467	f	\N
2	3805	185	182	\N	3	f	\N	2012-11-28 00:01:40.052582	f	\N
2	3743	205	122	\N	3	f	\N	2012-11-27 11:47:50.470719	t	2012-12-08 09:59:28.228912
2	3807	22	101	\N	3	f	\N	2012-11-28 08:48:37.0668	f	\N
2	5226	205	122	\N	3	f	\N	2012-12-07 10:52:33.681118	t	2012-12-08 10:03:07.69905
2	5232	205	122	\N	3	f	\N	2012-12-07 10:58:39.745689	t	2012-12-08 10:06:46.395207
2	3808	22	101	\N	3	f	\N	2012-11-28 08:51:13.943569	f	\N
2	3809	1	101	\N	3	f	\N	2012-11-28 08:53:07.975526	f	\N
2	3810	22	101	\N	3	f	\N	2012-11-28 08:53:41.325039	f	\N
2	3811	22	101	\N	3	f	\N	2012-11-28 08:54:51.150513	f	\N
2	3812	22	101	\N	3	f	\N	2012-11-28 08:55:09.217302	f	\N
2	3813	1	182	\N	3	f	\N	2012-11-28 08:58:13.109084	f	\N
2	3814	22	101	\N	3	f	\N	2012-11-28 08:58:14.268047	f	\N
2	3599	98	64	\N	3	f	\N	2012-12-23 11:19:17.127122	f	\N
2	3816	1	101	\N	3	f	\N	2012-11-28 09:37:04.372958	f	\N
2	3818	205	182	\N	3	f	\N	2012-11-28 11:06:35.159188	f	\N
2	3819	205	182	\N	3	f	\N	2012-11-28 11:33:14.945634	f	\N
2	1698	61	101	\N	3	f	\N	2012-11-28 12:13:23.641078	f	\N
2	3951	1	125	\N	3	f	\N	2012-11-29 16:31:06.42888	t	2012-12-08 09:22:10.326821
2	3827	205	182	\N	3	f	\N	2012-11-28 13:02:44.782236	f	\N
2	3829	205	182	\N	3	f	\N	2012-11-28 15:11:05.181404	f	\N
2	3830	136	182	\N	3	f	\N	2012-11-28 15:24:43.905057	f	\N
2	3835	185	182	\N	3	f	\N	2012-11-28 15:27:00.664324	f	\N
2	3836	185	182	\N	3	f	\N	2012-11-28 15:28:12.167827	f	\N
2	3840	205	182	\N	3	f	\N	2012-11-28 17:56:03.524532	f	\N
2	696	3	102	\N	3	f	\N	2012-11-28 18:01:25.32606	f	\N
2	2054	3	182	\N	3	f	\N	2012-11-28 18:03:52.24842	f	\N
2	3841	111	159	\N	3	f	\N	2012-11-28 18:16:58.752576	f	\N
2	1167	3	182	\N	3	f	\N	2012-11-28 18:57:16.212729	f	\N
2	3842	111	159	\N	3	f	\N	2012-11-28 19:04:36.478773	f	\N
2	3848	22	101	\N	3	f	\N	2012-11-28 19:25:42.988441	f	\N
2	5367	98	64	\N	3	f	\N	2012-12-08 09:49:18.962442	t	2012-12-08 09:49:28.358806
2	3850	185	182	\N	3	f	\N	2012-11-28 20:18:11.896543	f	\N
2	3851	205	182	\N	3	f	\N	2012-11-28 20:28:55.859452	f	\N
2	3817	205	122	\N	3	f	\N	2012-11-28 10:12:23.772422	t	2012-12-08 10:00:36.116206
2	3853	111	159	\N	3	f	\N	2012-11-28 21:13:47.926001	f	\N
2	3856	91	101	\N	3	f	\N	2012-11-28 21:32:55.85318	f	\N
2	3857	111	159	\N	3	f	\N	2012-11-28 21:40:51.033241	f	\N
2	3858	111	159	\N	3	f	\N	2012-11-28 21:47:25.080314	f	\N
2	1084	1	182	\N	3	f	\N	2012-11-28 21:58:05.205485	f	\N
2	3867	111	159	\N	3	f	\N	2012-11-28 22:28:24.582774	f	\N
2	3871	3	182	\N	3	f	\N	2012-11-28 22:36:15.193133	f	\N
2	3872	111	159	\N	3	f	\N	2012-11-28 22:40:32.419311	f	\N
2	3873	111	159	\N	3	f	\N	2012-11-28 22:50:01.375913	f	\N
2	5112	205	122	\N	3	f	\N	2012-12-06 20:16:34.523859	t	2012-12-08 10:01:34.128526
2	3875	185	182	\N	3	f	\N	2012-11-28 22:58:01.19753	f	\N
2	3876	185	182	\N	3	f	\N	2012-11-28 22:59:23.998258	f	\N
2	3877	41	182	\N	3	f	\N	2012-11-28 22:59:31.015331	f	\N
2	3950	205	122	\N	3	f	\N	2012-11-29 15:39:38.114147	t	2012-12-08 10:02:40.737482
2	3879	1	182	\N	3	f	\N	2012-11-28 23:01:17.090193	f	\N
2	3880	111	159	\N	3	f	\N	2012-11-28 23:13:55.268516	f	\N
2	3881	205	182	\N	3	f	\N	2012-11-28 23:31:30.811619	f	\N
2	3882	205	25	\N	3	f	\N	2012-11-28 23:41:01.853366	f	\N
2	3884	3	182	\N	3	f	\N	2012-11-29 00:12:13.613706	f	\N
2	3886	185	182	\N	3	f	\N	2012-11-29 00:50:23.607876	f	\N
2	615	3	101	\N	3	f	\N	2012-11-29 00:50:44.337561	f	\N
2	3887	205	12	\N	3	f	\N	2012-11-29 08:53:12.888552	f	\N
2	3888	205	160	\N	3	f	\N	2012-11-29 09:28:42.541911	f	\N
2	4247	67	101	\N	3	f	\N	2012-12-03 11:44:54.87745	t	2012-12-07 09:36:19.318254
2	632	3	101	\N	3	f	\N	2012-11-28 16:59:04.624976	t	2012-12-07 09:43:25.74221
2	3895	1	182	\N	3	f	\N	2012-11-29 09:54:22.811504	f	\N
2	3896	205	182	\N	3	f	\N	2012-11-29 09:54:37.93756	f	\N
2	3897	205	182	\N	3	f	\N	2012-11-29 09:55:53.793341	f	\N
2	3898	111	159	\N	3	f	\N	2012-11-29 09:56:58.302159	f	\N
2	3899	205	182	\N	3	f	\N	2012-11-29 09:59:00.338688	f	\N
2	3900	205	182	\N	3	f	\N	2012-11-29 09:59:21.578031	f	\N
2	3901	111	159	\N	3	f	\N	2012-11-29 10:01:00.094631	f	\N
2	3902	205	42	\N	3	f	\N	2012-11-29 10:01:12.764272	f	\N
2	3903	205	182	\N	3	f	\N	2012-11-29 10:01:22.534691	f	\N
2	3904	205	42	\N	3	f	\N	2012-11-29 10:03:29.190533	f	\N
2	3905	205	182	\N	3	f	\N	2012-11-29 10:04:12.586277	f	\N
2	3906	185	182	\N	3	f	\N	2012-11-29 12:14:04.498537	f	\N
2	3911	205	1	\N	3	f	\N	2012-11-29 12:20:53.662764	f	\N
2	3912	185	182	\N	3	f	\N	2012-11-29 12:21:34.007389	f	\N
2	3913	185	182	\N	3	f	\N	2012-11-29 12:33:16.193388	f	\N
2	3914	111	159	\N	3	f	\N	2012-11-29 13:03:41.731431	f	\N
2	3915	111	159	\N	3	f	\N	2012-11-29 13:05:34.611593	f	\N
2	3916	111	159	\N	3	f	\N	2012-11-29 13:05:39.447276	f	\N
2	3918	111	159	\N	3	f	\N	2012-11-29 13:07:12.548339	f	\N
2	3919	111	159	\N	3	f	\N	2012-11-29 13:09:27.828991	f	\N
2	3920	111	159	\N	3	f	\N	2012-11-29 13:10:50.988846	f	\N
2	3921	111	159	\N	3	f	\N	2012-11-29 13:13:30.6168	f	\N
2	3922	111	159	\N	3	f	\N	2012-11-29 13:21:01.657227	f	\N
2	3924	111	159	\N	3	f	\N	2012-11-29 13:26:02.350022	f	\N
2	3925	111	159	\N	3	f	\N	2012-11-29 13:34:42.186775	f	\N
2	4129	111	159	\N	3	f	\N	2012-11-30 21:24:39.185033	f	\N
2	3927	1	159	\N	3	f	\N	2012-11-29 13:40:49.07062	f	\N
2	3932	185	182	\N	3	f	\N	2012-11-29 13:52:55.637593	f	\N
2	3933	111	159	\N	3	f	\N	2012-11-29 13:53:51.6305	f	\N
2	4319	205	150	\N	3	f	\N	2012-12-03 21:40:24.32698	f	\N
2	3940	201	182	\N	3	f	\N	2012-11-29 14:39:57.618391	f	\N
2	3941	22	101	\N	3	f	\N	2012-11-29 15:09:24.699911	f	\N
2	3942	22	101	\N	3	f	\N	2012-11-29 15:11:11.062543	f	\N
2	3943	22	101	\N	3	f	\N	2012-11-29 15:13:37.059613	f	\N
2	3944	22	125	\N	3	f	\N	2012-11-29 15:14:53.051919	f	\N
2	3945	1	101	\N	3	f	\N	2012-11-29 15:16:07.772644	f	\N
2	3946	22	101	\N	3	f	\N	2012-11-29 15:19:17.857096	f	\N
2	3947	22	101	\N	3	f	\N	2012-11-29 15:21:29.998647	f	\N
2	3948	22	101	\N	3	f	\N	2012-11-29 15:22:42.534371	f	\N
2	3949	22	101	\N	3	f	\N	2012-11-29 15:25:33.899658	f	\N
2	3957	205	182	\N	3	f	\N	2012-11-29 18:07:56.702662	f	\N
2	4000	205	25	\N	3	f	\N	2012-11-29 20:45:45.822584	f	\N
2	5353	41	182	\N	3	f	\N	2012-12-07 22:32:30.648509	f	\N
2	3959	111	182	\N	3	f	\N	2012-11-29 18:36:09.130623	f	\N
2	3960	185	182	\N	3	f	\N	2012-11-29 18:40:59.770205	f	\N
2	4073	58	171	\N	3	f	\N	2012-11-30 12:54:19.342873	t	2012-12-06 09:40:32.338738
2	3962	111	159	\N	3	f	\N	2012-11-29 18:48:51.175292	f	\N
2	4198	21	101	\N	3	f	\N	2012-12-01 22:02:16.414284	f	\N
2	4200	3	101	\N	3	f	\N	2012-12-01 23:20:08.950358	f	\N
2	5113	205	84	\N	3	f	\N	2012-12-06 20:20:09.55861	f	\N
2	323	3	101	\N	3	f	\N	2012-12-02 01:29:31.553197	f	\N
2	4031	98	125	\N	3	f	\N	2012-11-29 22:17:21.461023	t	2012-12-08 09:42:51.479355
2	4210	52	99	\N	3	f	\N	2012-12-02 11:02:43.237329	f	\N
2	4216	3	101	\N	3	f	\N	2012-12-02 12:30:07.452417	f	\N
2	5368	98	64	\N	3	f	\N	2012-12-08 09:49:21.247655	t	2012-12-08 09:49:30.209552
2	4218	45	42	\N	3	f	\N	2012-12-02 14:09:23.639616	f	\N
2	4220	185	182	\N	3	f	\N	2012-12-02 16:06:25.128891	f	\N
2	3977	185	182	\N	3	f	\N	2012-11-29 19:00:44.801061	f	\N
2	3978	111	159	\N	3	f	\N	2012-11-29 19:10:02.38016	f	\N
2	3979	111	159	\N	3	f	\N	2012-11-29 19:17:15.477632	f	\N
2	3983	111	159	\N	3	f	\N	2012-11-29 19:23:43.979355	f	\N
2	5159	74	101	\N	3	f	\N	2012-12-07 00:47:54.894468	f	\N
2	4058	3	182	\N	3	f	\N	2012-11-30 10:19:50.286062	t	2012-12-08 10:07:00.151027
2	3992	111	159	\N	3	f	\N	2012-11-29 19:59:39.810693	f	\N
2	3993	111	159	\N	3	f	\N	2012-11-29 19:59:55.720169	f	\N
2	3998	111	159	\N	3	f	\N	2012-11-29 20:15:30.227205	f	\N
2	3999	111	182	\N	3	f	\N	2012-11-29 20:19:53.677913	f	\N
2	4002	205	25	\N	3	f	\N	2012-11-29 21:31:01.252257	f	\N
2	4003	205	113	\N	3	f	\N	2012-11-29 21:31:37.146338	f	\N
2	4004	1	1	\N	3	f	\N	2012-11-29 21:33:13.445154	f	\N
2	4005	205	25	\N	3	f	\N	2012-11-29 21:33:21.752818	f	\N
2	4009	205	25	\N	3	f	\N	2012-11-29 21:34:50.46463	f	\N
2	3649	3	182	\N	3	f	\N	2012-11-23 20:31:38.197121	t	2012-12-08 10:08:20.014796
2	4019	205	25	\N	3	f	\N	2012-11-29 21:40:43.686082	f	\N
2	4021	205	25	\N	3	f	\N	2012-11-29 21:43:21.619455	f	\N
2	4022	111	159	\N	3	f	\N	2012-11-29 21:43:51.869835	f	\N
2	4024	111	159	\N	3	f	\N	2012-11-29 21:51:55.742716	f	\N
2	4025	205	25	\N	3	f	\N	2012-11-29 21:52:10.509949	f	\N
2	4026	205	25	\N	3	f	\N	2012-11-29 21:54:23.520663	f	\N
2	4131	1	101	\N	3	f	\N	2012-11-30 21:46:38.2785	f	\N
2	4029	205	101	\N	3	f	\N	2012-11-29 22:01:01.792876	f	\N
2	4027	205	101	\N	3	f	\N	2012-11-29 21:56:55.421643	t	2012-12-07 08:54:22.406429
2	5388	1	1	\N	3	f	\N	2012-12-08 10:23:20.358795	t	2012-12-08 10:23:31.803873
2	4041	205	101	\N	3	f	\N	2012-11-30 08:47:21.913658	f	\N
2	4044	205	146	\N	3	f	\N	2012-11-30 08:58:35.421617	f	\N
2	4046	41	182	\N	3	f	\N	2012-11-30 09:05:53.192959	f	\N
2	4049	41	182	\N	3	f	\N	2012-11-30 09:32:08.443314	f	\N
2	4045	41	182	\N	3	f	\N	2012-11-30 09:05:01.817407	t	2012-12-07 09:18:50.852419
2	4051	58	171	\N	3	f	\N	2012-11-30 09:45:31.865101	f	\N
2	4047	41	182	\N	3	f	\N	2012-11-30 09:07:22.319618	t	2012-12-07 09:24:07.383581
2	4053	3	182	\N	3	f	\N	2012-11-30 10:08:49.379217	f	\N
2	4048	205	182	\N	3	f	\N	2012-11-30 09:14:58.090011	t	2012-12-07 09:25:38.271153
2	4060	205	25	\N	3	f	\N	2012-11-30 11:30:27.477835	f	\N
2	4061	205	25	\N	3	f	\N	2012-11-30 11:30:34.221478	f	\N
2	4062	205	25	\N	3	f	\N	2012-11-30 11:30:47.670204	f	\N
2	4063	205	25	\N	3	f	\N	2012-11-30 11:31:13.43284	f	\N
2	4064	205	25	\N	3	f	\N	2012-11-30 11:31:18.886619	f	\N
2	4065	205	25	\N	3	f	\N	2012-11-30 11:31:47.167096	f	\N
2	4066	1	25	\N	3	f	\N	2012-11-30 11:32:57.706265	f	\N
2	4067	205	25	\N	3	f	\N	2012-11-30 11:35:38.0831	f	\N
2	4068	205	182	\N	3	f	\N	2012-11-30 11:38:34.894559	f	\N
2	4042	41	182	\N	3	f	\N	2012-11-30 08:53:23.724719	t	2012-12-07 09:26:17.616801
2	4076	111	159	\N	3	f	\N	2012-11-30 13:15:40.730766	f	\N
2	4077	111	159	\N	3	f	\N	2012-11-30 13:16:24.24086	f	\N
2	3926	111	159	\N	3	f	\N	2012-11-29 13:34:43.544623	f	\N
2	4078	111	159	\N	3	f	\N	2012-11-30 13:21:08.69095	f	\N
2	4079	111	159	\N	3	f	\N	2012-11-30 13:25:15.479867	f	\N
2	4080	111	159	\N	3	f	\N	2012-11-30 13:25:18.946791	f	\N
2	4087	111	159	\N	3	f	\N	2012-11-30 13:37:31.689802	f	\N
2	5398	191	182	\N	3	f	\N	2012-12-08 10:28:23.139626	t	2012-12-08 10:28:33.424874
2	4096	205	25	\N	3	f	\N	2012-11-30 13:50:23.530577	f	\N
2	4097	111	159	\N	3	f	\N	2012-11-30 13:50:41.74606	f	\N
2	4098	205	25	\N	3	f	\N	2012-11-30 13:51:24.837079	f	\N
2	4100	205	25	\N	3	f	\N	2012-11-30 14:30:52.932558	f	\N
2	4101	205	25	\N	3	f	\N	2012-11-30 14:32:03.139847	f	\N
2	4102	205	25	\N	3	f	\N	2012-11-30 14:32:55.249714	f	\N
2	4104	142	152	\N	3	f	\N	2012-11-30 14:57:57.242638	f	\N
2	4043	205	182	\N	3	f	\N	2012-11-30 08:58:01.084684	t	2012-12-07 09:28:14.843522
2	4109	142	152	\N	3	f	\N	2012-11-30 15:26:42.107876	f	\N
2	4081	67	101	\N	3	f	\N	2012-11-30 13:25:56.644747	t	2012-12-07 09:30:49.38053
2	5180	1	84	\N	3	f	\N	2012-12-07 09:36:58.988272	f	\N
2	4072	45	42	\N	3	f	\N	2012-11-30 12:01:40.539857	t	2012-12-07 09:39:50.356848
2	1953	101	101	\N	3	f	\N	2012-12-07 09:58:18.760565	f	\N
2	4116	185	182	\N	3	f	\N	2012-11-30 16:48:20.450609	f	\N
2	4117	58	171	\N	3	f	\N	2012-11-30 16:58:24.13417	f	\N
2	5407	1	1	\N	3	f	\N	2012-12-08 10:32:57.352025	t	2012-12-08 10:33:14.97931
2	4136	111	159	\N	3	f	\N	2012-11-30 22:27:47.976455	f	\N
2	4149	111	159	\N	3	f	\N	2012-11-30 22:49:44.546895	f	\N
2	4099	142	152	\N	3	f	\N	2012-11-30 14:25:15.754432	t	2012-12-08 10:36:13.05765
2	4110	142	152	\N	3	f	\N	2012-11-30 15:34:12.378891	t	2012-12-08 10:36:42.057277
2	4108	142	152	\N	3	f	\N	2012-11-30 15:18:30.948673	t	2012-12-08 10:37:53.47509
2	4107	142	152	\N	3	f	\N	2012-11-30 15:15:45.554216	t	2012-12-08 10:38:48.794024
2	4119	205	25	\N	3	f	\N	2012-11-30 17:19:22.038902	f	\N
2	392	3	124	\N	3	f	\N	2012-12-06 20:30:50.214764	f	\N
2	4121	205	146	\N	3	f	\N	2012-11-30 18:03:32.657487	f	\N
2	4028	111	159	\N	3	f	\N	2012-11-29 21:58:19.825507	f	\N
2	1736	95	42	\N	3	f	\N	2012-11-30 18:17:05.535212	f	\N
2	5140	3	101	\N	3	f	\N	2012-12-06 22:23:40.9417	f	\N
2	466	68	101	\N	3	f	\N	2012-11-30 19:10:04.179614	f	\N
2	4126	111	159	\N	3	f	\N	2012-11-30 19:32:22.044442	f	\N
2	4127	75	101	\N	3	f	\N	2012-11-30 20:06:34.237816	f	\N
2	4128	205	182	\N	3	f	\N	2012-11-30 20:43:40.640195	f	\N
2	627	3	150	\N	3	f	\N	2012-12-07 23:12:54.950667	f	\N
2	4197	1	182	\N	3	f	\N	2012-12-01 21:52:46.570912	f	\N
2	4135	1	101	\N	3	f	\N	2012-11-30 22:14:51.863238	f	\N
2	4123	3	182	\N	3	f	\N	2012-11-30 19:21:45.035442	t	2012-12-08 09:42:54.815789
2	4152	111	159	\N	3	f	\N	2012-11-30 22:54:19.964468	f	\N
2	3961	111	159	\N	3	f	\N	2012-11-29 18:46:53.484434	f	\N
2	1037	3	101	\N	3	f	\N	2012-11-30 22:57:07.700509	f	\N
2	4153	111	159	\N	3	f	\N	2012-11-30 22:59:45.873658	f	\N
2	4312	98	64	\N	3	f	\N	2012-12-03 20:33:06.806739	t	2012-12-08 09:44:16.064179
2	4140	205	101	\N	3	f	\N	2012-11-30 22:43:06.777881	t	2012-12-08 09:49:05.807535
2	4154	45	42	\N	3	f	\N	2012-11-30 23:10:35.059869	f	\N
2	5369	98	64	\N	3	f	\N	2012-12-08 09:51:13.076435	t	2012-12-08 09:51:22.507526
2	3971	111	159	\N	3	f	\N	2012-11-29 18:55:48.904647	f	\N
2	4178	1	122	\N	3	f	\N	2012-12-01 15:31:01.27165	t	2012-12-08 09:59:17.754868
2	4203	205	122	\N	3	f	\N	2012-12-02 00:44:52.962429	t	2012-12-08 09:59:59.841301
2	4156	111	159	\N	3	f	\N	2012-11-30 23:19:49.10905	f	\N
2	3974	111	159	\N	3	f	\N	2012-11-29 18:56:32.124504	f	\N
2	4158	205	101	\N	3	f	\N	2012-12-01 00:04:20.439545	f	\N
2	4159	3	101	\N	3	f	\N	2012-12-01 00:04:29.820053	f	\N
2	4160	78	101	\N	3	f	\N	2012-12-01 00:15:16.418464	f	\N
2	4161	41	182	\N	3	f	\N	2012-12-01 00:27:54.434694	f	\N
2	4162	111	159	\N	3	f	\N	2012-12-01 00:31:07.164508	f	\N
2	1200	3	101	\N	3	f	\N	2012-12-01 01:07:17.704841	f	\N
2	4171	3	101	\N	3	f	\N	2012-12-01 11:38:52.794862	f	\N
2	4244	67	101	\N	3	f	\N	2012-12-03 11:42:50.077884	t	2012-12-07 09:27:20.592433
2	4173	111	159	\N	3	f	\N	2012-12-01 13:09:26.262685	f	\N
2	1519	104	125	\N	3	f	\N	2012-12-01 13:28:49.507353	f	\N
2	4232	67	101	\N	3	f	\N	2012-12-03 11:40:04.573127	t	2012-12-07 09:27:44.696774
2	4234	67	101	\N	3	f	\N	2012-12-03 11:40:18.961725	t	2012-12-07 09:28:15.172288
2	697	3	182	\N	3	f	\N	2012-12-01 15:23:29.528086	f	\N
2	5381	1	1	\N	3	f	\N	2012-12-08 10:10:18.575436	t	2012-12-08 10:10:30.658015
2	4180	205	101	\N	3	f	\N	2012-12-01 15:45:45.739508	f	\N
2	4181	205	101	\N	3	f	\N	2012-12-01 15:47:07.596352	f	\N
2	4189	205	101	\N	3	f	\N	2012-12-01 19:37:08.957219	f	\N
2	4194	111	159	\N	3	f	\N	2012-12-01 19:45:30.06103	f	\N
2	4195	111	159	\N	3	f	\N	2012-12-01 19:58:30.219703	f	\N
2	4201	1	101	\N	3	f	\N	2012-12-01 23:24:18.6742	f	\N
2	4209	205	101	\N	3	f	\N	2012-12-02 02:44:09.456539	f	\N
2	4251	67	101	\N	3	f	\N	2012-12-03 11:46:38.000925	t	2012-12-07 09:31:59.821905
2	4217	3	182	\N	3	f	\N	2012-12-02 13:22:25.985582	f	\N
2	4245	67	101	\N	3	f	\N	2012-12-03 11:43:14.520461	t	2012-12-07 09:33:18.348059
2	4237	67	101	\N	3	f	\N	2012-12-03 11:40:40.44645	t	2012-12-07 09:34:43.986125
2	5389	191	182	\N	3	f	\N	2012-12-08 10:23:33.129014	t	2012-12-08 10:23:42.847857
2	4225	65	101	\N	3	f	\N	2012-12-03 09:53:22.412741	f	\N
2	4229	3	101	\N	3	f	\N	2012-12-03 11:02:28.72942	f	\N
2	5399	191	182	\N	3	f	\N	2012-12-08 10:28:33.429015	t	2012-12-08 10:28:46.384129
2	4235	67	101	\N	3	f	\N	2012-12-03 11:40:20.961387	f	\N
2	4236	67	101	\N	3	f	\N	2012-12-03 11:40:33.529513	f	\N
2	4238	67	101	\N	3	f	\N	2012-12-03 11:40:45.212496	f	\N
2	4239	67	1	\N	3	f	\N	2012-12-03 11:40:51.365251	f	\N
2	4240	205	25	\N	3	f	\N	2012-12-03 11:41:03.261739	f	\N
2	4241	67	101	\N	3	f	\N	2012-12-03 11:41:37.927334	f	\N
2	4242	67	101	\N	3	f	\N	2012-12-03 11:41:39.178598	f	\N
2	4243	67	101	\N	3	f	\N	2012-12-03 11:42:49.857819	f	\N
2	4246	205	25	\N	3	f	\N	2012-12-03 11:44:16.120017	f	\N
2	5144	101	1	\N	3	f	\N	2012-12-06 23:20:35.47291	t	2012-12-08 10:33:19.079383
2	4293	142	152	\N	3	f	\N	2012-12-03 16:12:43.849534	t	2012-12-08 10:37:09.26075
2	4124	142	152	\N	3	f	\N	2012-11-30 19:23:46.019366	t	2012-12-08 10:37:58.488019
2	4250	205	25	\N	3	f	\N	2012-12-03 11:46:08.131118	f	\N
2	4252	67	101	\N	3	f	\N	2012-12-03 11:46:49.470663	f	\N
2	4254	205	25	\N	3	f	\N	2012-12-03 11:49:18.390169	f	\N
2	4255	67	101	\N	3	f	\N	2012-12-03 11:50:35.906233	f	\N
2	3939	142	152	\N	3	f	\N	2012-11-29 13:57:09.193861	t	2012-12-08 10:38:09.249638
2	4103	142	152	\N	3	f	\N	2012-11-30 14:46:47.890812	t	2012-12-08 10:39:46.74833
2	4373	142	152	\N	3	f	\N	2012-12-04 12:20:33.882743	t	2012-12-08 10:42:37.902461
2	4265	67	101	\N	3	f	\N	2012-12-03 12:08:24.759372	f	\N
2	4267	41	182	\N	3	f	\N	2012-12-03 13:22:22.274768	f	\N
2	4268	142	152	\N	3	f	\N	2012-12-03 13:41:14.209777	f	\N
2	4274	3	101	\N	3	f	\N	2012-12-03 14:38:30.768126	f	\N
2	4275	3	182	\N	3	f	\N	2012-12-03 14:52:21.756828	f	\N
2	4276	1	1	\N	3	f	\N	2012-12-03 14:54:28.492803	f	\N
2	4277	3	102	\N	3	f	\N	2012-12-03 15:00:55.390775	f	\N
2	4278	205	146	\N	3	f	\N	2012-12-03 15:02:28.478286	f	\N
2	4280	3	101	\N	3	f	\N	2012-12-03 15:51:49.429624	f	\N
2	4281	3	101	\N	3	f	\N	2012-12-03 16:06:58.897606	f	\N
2	4282	185	182	\N	3	f	\N	2012-12-03 16:07:08.452611	f	\N
2	4294	3	101	\N	3	f	\N	2012-12-03 16:14:57.339283	f	\N
2	4320	205	150	\N	3	f	\N	2012-12-03 21:54:03.558554	f	\N
2	5411	205	101	\N	3	f	\N	2012-12-08 10:47:20.919642	t	2012-12-08 10:47:35.62174
2	4302	205	182	\N	3	f	\N	2012-12-03 17:24:34.651677	f	\N
2	4303	61	102	\N	3	f	\N	2012-12-03 18:00:56.989472	f	\N
2	4305	1	101	\N	3	f	\N	2012-12-03 18:33:40.678228	f	\N
2	4306	111	159	\N	3	f	\N	2012-12-03 18:36:38.638265	f	\N
2	4307	205	182	\N	3	f	\N	2012-12-03 18:45:09.006527	f	\N
2	4308	142	152	\N	3	f	\N	2012-12-03 18:58:35.083557	f	\N
2	4311	41	182	\N	3	f	\N	2012-12-03 19:49:15.176348	f	\N
2	2186	3	101	\N	3	f	\N	2012-12-03 20:02:48.735157	f	\N
2	4318	142	152	\N	3	f	\N	2012-12-03 21:17:58.188907	f	\N
2	4322	205	150	\N	3	f	\N	2012-12-03 21:56:41.675722	f	\N
2	4323	205	150	\N	3	f	\N	2012-12-03 22:03:53.909982	f	\N
2	4324	205	150	\N	3	f	\N	2012-12-03 22:06:24.903662	f	\N
2	4325	205	150	\N	3	f	\N	2012-12-03 22:10:10.694162	f	\N
2	4326	205	150	\N	3	f	\N	2012-12-03 22:12:32.977937	f	\N
2	5356	1	101	\N	3	f	\N	2012-12-08 00:14:22.327338	f	\N
2	4328	1	182	\N	3	f	\N	2012-12-03 22:25:15.77559	f	\N
2	2162	3	101	\N	3	f	\N	2012-12-04 09:26:01.4468	t	2012-12-08 09:47:03.815785
2	792	3	101	\N	3	f	\N	2012-12-06 22:28:35.582426	f	\N
2	525	2	182	\N	3	f	\N	2012-12-04 01:52:40.209582	f	\N
2	4390	21	101	\N	3	f	\N	2012-12-04 14:09:08.079339	t	2012-12-08 09:47:43.1957
2	4333	67	101	\N	3	f	\N	2012-12-04 07:36:24.579836	f	\N
2	4334	67	101	\N	3	f	\N	2012-12-04 07:40:19.49327	f	\N
2	4340	205	25	\N	3	f	\N	2012-12-04 08:40:08.164881	f	\N
2	4341	194	182	\N	3	f	\N	2012-12-04 08:46:14.757255	f	\N
2	5119	41	182	\N	3	f	\N	2012-12-06 20:43:22.264716	t	2012-12-07 09:22:49.780974
2	4347	67	101	\N	3	f	\N	2012-12-04 11:07:40.130861	t	2012-12-07 09:32:39.060183
2	4349	67	101	\N	3	f	\N	2012-12-04 11:08:08.987863	t	2012-12-07 09:33:55.611803
2	4346	205	182	\N	3	f	\N	2012-12-04 10:43:21.251592	f	\N
2	4350	67	101	\N	3	f	\N	2012-12-04 11:10:55.639445	f	\N
2	4351	67	101	\N	3	f	\N	2012-12-04 11:12:19.651326	f	\N
2	4352	205	182	\N	3	f	\N	2012-12-04 11:13:12.191257	f	\N
2	4363	111	159	\N	3	f	\N	2012-12-04 11:25:58.121046	f	\N
2	5370	98	64	\N	3	f	\N	2012-12-08 09:51:17.819714	t	2012-12-08 09:51:36.611185
2	4364	111	159	\N	3	f	\N	2012-12-04 11:33:35.015875	f	\N
2	4372	41	182	\N	3	f	\N	2012-12-04 12:19:39.045129	f	\N
2	4374	205	49	\N	3	f	\N	2012-12-04 12:28:01.897312	f	\N
2	4199	205	122	\N	3	f	\N	2012-12-01 22:39:45.378028	t	2012-12-08 10:01:47.816088
2	4382	205	101	\N	3	f	\N	2012-12-04 13:05:54.750447	f	\N
2	4388	1	182	\N	3	f	\N	2012-12-04 13:41:22.416455	f	\N
2	4389	3	101	\N	3	f	\N	2012-12-04 13:43:51.90417	f	\N
2	4394	1	182	\N	3	f	\N	2012-12-04 14:24:26.692421	f	\N
2	4395	1	182	\N	3	f	\N	2012-12-04 14:41:28.120055	f	\N
2	4396	1	182	\N	3	f	\N	2012-12-04 14:44:50.546839	f	\N
2	4400	3	182	\N	3	f	\N	2012-12-04 14:55:30.975679	f	\N
2	4401	21	101	\N	3	f	\N	2012-12-04 15:27:29.387425	f	\N
2	5182	45	42	\N	3	f	\N	2012-12-07 09:38:56.07188	t	2012-12-07 09:39:15.950446
2	4402	205	182	\N	3	f	\N	2012-12-04 16:07:24.636488	t	2012-12-07 09:42:33.874371
2	4353	1	122	\N	3	f	\N	2012-12-04 11:19:26.58211	t	2012-12-08 10:02:30.954381
2	4405	205	182	\N	3	f	\N	2012-12-04 17:13:31.656349	f	\N
2	4406	205	182	\N	3	f	\N	2012-12-04 17:19:13.079495	f	\N
2	4407	205	182	\N	3	f	\N	2012-12-04 17:19:22.386689	f	\N
2	4413	205	182	\N	3	f	\N	2012-12-04 17:20:33.144859	f	\N
2	4414	205	182	\N	3	f	\N	2012-12-04 17:21:32.466022	f	\N
2	4416	205	182	\N	3	f	\N	2012-12-04 17:21:59.911272	f	\N
2	4417	205	182	\N	3	f	\N	2012-12-04 17:23:04.838988	f	\N
2	4418	205	182	\N	3	f	\N	2012-12-04 17:23:43.856099	f	\N
2	4419	205	182	\N	3	f	\N	2012-12-04 17:24:18.226876	f	\N
2	4420	205	182	\N	3	f	\N	2012-12-04 17:24:48.607	f	\N
2	4421	205	182	\N	3	f	\N	2012-12-04 17:24:56.497627	f	\N
2	4422	205	182	\N	3	f	\N	2012-12-04 17:25:14.498725	f	\N
2	4423	205	182	\N	3	f	\N	2012-12-04 17:25:18.136572	f	\N
2	4393	185	182	\N	3	f	\N	2012-12-04 14:21:42.435802	t	2012-12-07 09:54:38.577362
2	4425	1	1	\N	3	f	\N	2012-12-04 17:32:33.356399	f	\N
2	4426	205	182	\N	3	f	\N	2012-12-04 17:34:48.348355	f	\N
2	4427	205	182	\N	3	f	\N	2012-12-04 18:30:22.818956	f	\N
2	4428	1	182	\N	3	f	\N	2012-12-04 18:47:54.85822	f	\N
2	2127	101	101	\N	3	f	\N	2012-12-04 19:29:16.256175	f	\N
2	5187	1	182	\N	3	f	\N	2012-12-07 10:14:26.597133	t	2012-12-07 10:14:42.910369
2	4433	3	101	\N	3	f	\N	2012-12-04 20:18:52.940932	f	\N
2	4434	74	101	\N	3	f	\N	2012-12-04 20:27:30.049368	f	\N
2	4435	74	101	\N	3	f	\N	2012-12-04 20:31:58.808636	f	\N
2	1196	3	101	\N	3	f	\N	2012-12-04 21:43:34.450458	t	2012-12-07 10:29:19.704572
2	4437	205	101	\N	3	f	\N	2012-12-04 20:55:54.617964	f	\N
2	5196	205	182	\N	3	f	\N	2012-12-07 10:33:53.535278	t	2012-12-07 10:34:23.723489
2	4441	142	152	\N	3	f	\N	2012-12-04 21:41:58.978459	f	\N
2	4442	3	1	\N	3	f	\N	2012-12-04 21:56:20.768671	f	\N
2	5206	3	101	\N	3	f	\N	2012-12-07 10:40:35.337824	f	\N
2	380	1	182	\N	3	f	\N	2012-11-27 16:27:39.172618	t	2012-12-08 10:10:50.043164
2	5391	191	182	\N	3	f	\N	2012-12-08 10:24:11.499999	t	2012-12-08 10:26:40.636537
2	4447	205	182	\N	3	f	\N	2012-12-04 22:13:53.841875	f	\N
2	4448	205	182	\N	3	f	\N	2012-12-04 22:14:17.813176	f	\N
2	5400	191	182	\N	3	f	\N	2012-12-08 10:29:25.56233	t	2012-12-08 10:29:34.712493
2	5408	1	1	\N	3	f	\N	2012-12-08 10:34:10.396435	t	2012-12-08 10:34:25.323117
2	4449	205	182	\N	3	f	\N	2012-12-04 22:17:56.269968	f	\N
2	5120	3	101	\N	3	f	\N	2012-12-06 20:47:53.694276	f	\N
2	677	3	101	\N	3	f	\N	2012-12-05 00:29:31.375486	f	\N
2	636	3	182	\N	3	f	\N	2012-12-05 00:42:19.94689	f	\N
2	4459	205	182	\N	3	f	\N	2012-12-05 00:50:17.837186	f	\N
2	4460	205	182	\N	3	f	\N	2012-12-05 01:03:11.929104	f	\N
2	4461	191	182	\N	3	f	\N	2012-12-05 08:36:48.885599	f	\N
2	4463	104	125	\N	3	f	\N	2012-12-05 09:27:52.606326	f	\N
2	5164	205	84	\N	3	f	\N	2012-12-07 05:12:20.472151	t	2012-12-07 09:09:23.96359
2	5183	67	101	\N	3	f	\N	2012-12-07 09:39:57.642876	f	\N
2	3874	205	182	\N	3	f	\N	2012-11-28 22:56:35.037164	t	2012-12-07 10:16:25.603369
2	4468	104	125	\N	3	f	\N	2012-12-05 09:34:01.361186	f	\N
2	4469	104	125	\N	3	f	\N	2012-12-05 09:34:40.078923	f	\N
2	4715	194	182	\N	3	f	\N	2012-12-05 20:31:08.378601	t	2012-12-07 10:47:46.036153
2	1023	3	182	\N	3	f	\N	2012-11-24 18:06:36.264385	t	2012-12-07 10:47:48.862267
2	478	1	182	\N	3	f	\N	2012-12-07 10:52:59.669908	t	2012-12-07 10:54:42.790449
2	4476	205	32	\N	3	f	\N	2012-12-05 10:05:01.704154	f	\N
2	3958	111	159	\N	3	f	\N	2012-11-29 18:26:00.963448	t	2012-12-07 10:59:24.516817
2	4453	111	159	\N	3	f	\N	2012-12-05 00:06:24.29346	t	2012-12-07 11:00:49.448136
2	3967	111	159	\N	3	f	\N	2012-11-29 18:52:54.316994	t	2012-12-07 11:01:11.177928
2	4484	104	125	\N	3	f	\N	2012-12-05 10:21:43.269116	f	\N
2	5240	111	159	\N	3	f	\N	2012-12-07 11:03:26.349495	t	2012-12-07 11:03:36.474442
2	4454	111	159	\N	3	f	\N	2012-12-05 00:08:39.47982	t	2012-12-07 11:04:14.852389
2	4455	111	159	\N	3	f	\N	2012-12-05 00:10:30.259182	t	2012-12-07 11:04:38.925525
2	3815	3	101	\N	3	f	\N	2012-11-28 09:15:57.730668	t	2012-12-07 11:07:52.912948
2	4480	205	182	\N	3	f	\N	2012-12-05 10:18:13.512038	f	\N
2	539	3	182	\N	3	f	\N	2012-12-07 12:05:30.632129	t	2012-12-07 12:05:49.848341
2	4492	104	125	\N	3	f	\N	2012-12-05 10:26:40.543482	f	\N
2	383	1	101	\N	3	f	\N	2012-12-07 12:51:06.484493	f	\N
2	5270	205	182	\N	3	f	\N	2012-12-07 14:02:29.357222	t	2012-12-07 14:04:08.843631
2	5274	205	182	\N	3	f	\N	2012-12-07 14:05:15.24939	t	2012-12-07 14:05:49.725409
2	4498	104	125	\N	3	f	\N	2012-12-05 10:31:20.318771	f	\N
2	5278	205	182	\N	3	f	\N	2012-12-07 14:06:59.166352	t	2012-12-07 14:07:30.465992
2	5282	1	182	\N	3	f	\N	2012-12-07 14:09:11.093113	t	2012-12-07 14:09:22.780302
2	4504	205	86	\N	3	f	\N	2012-12-05 10:35:33.18423	f	\N
2	5285	205	182	\N	3	f	\N	2012-12-07 14:10:52.188803	t	2012-12-07 14:11:22.618968
2	5288	205	182	\N	3	f	\N	2012-12-07 14:11:44.721442	t	2012-12-07 14:11:53.2174
2	5289	61	101	\N	3	f	\N	2012-12-07 14:13:19.346435	f	\N
2	4509	3	42	\N	3	f	\N	2012-12-05 10:46:15.42346	f	\N
2	4649	1	101	\N	3	f	\N	2012-12-05 17:13:46.333863	t	2012-12-07 14:14:34.948541
2	5293	3	101	\N	3	f	\N	2012-12-07 14:29:31.994663	t	2012-12-07 14:29:58.324622
2	5295	3	101	\N	3	f	\N	2012-12-07 14:31:26.46891	t	2012-12-07 14:31:35.645444
2	5001	67	101	\N	3	f	\N	2012-12-06 16:14:01.411087	t	2012-12-07 14:35:36.676042
2	5002	67	101	\N	3	f	\N	2012-12-06 16:14:22.240569	t	2012-12-07 14:36:43.309198
2	5158	86	102	\N	3	f	\N	2012-12-07 00:43:11.812975	t	2012-12-07 14:38:18.610179
2	4521	130	32	\N	3	f	\N	2012-12-05 11:05:07.18942	f	\N
2	4738	1	101	\N	3	f	\N	2012-12-05 21:44:17.006132	t	2012-12-07 14:50:32.442842
2	4527	130	32	\N	3	f	\N	2012-12-05 11:47:17.800377	f	\N
2	4528	130	32	\N	3	f	\N	2012-12-05 11:47:54.906008	f	\N
2	3713	205	182	\N	3	f	\N	2012-11-26 23:54:30.269981	t	2012-12-07 14:54:46.859216
2	4531	130	32	\N	3	f	\N	2012-12-05 11:54:04.002354	f	\N
2	4532	130	32	\N	3	f	\N	2012-12-05 11:54:15.734792	f	\N
2	5298	1	182	\N	3	f	\N	2012-12-07 14:54:48.385239	t	2012-12-07 14:54:57.95175
2	4535	130	32	\N	3	f	\N	2012-12-05 11:57:43.219534	f	\N
2	4647	76	101	\N	3	f	\N	2012-12-05 17:13:05.127026	t	2012-12-07 14:55:21.542745
2	4537	130	32	\N	3	f	\N	2012-12-05 12:00:38.080987	f	\N
2	5299	22	101	\N	3	f	\N	2012-12-07 14:56:26.36948	f	\N
2	5000	67	101	\N	3	f	\N	2012-12-06 16:13:17.02317	t	2012-12-07 14:56:48.273325
2	4540	130	32	\N	3	f	\N	2012-12-05 12:12:33.421412	f	\N
2	5302	111	101	\N	3	f	\N	2012-12-07 15:05:50.214357	f	\N
2	4541	130	32	\N	3	f	\N	2012-12-05 12:18:23.45254	f	\N
2	4542	130	32	\N	3	f	\N	2012-12-05 12:27:17.200889	f	\N
2	4543	1	101	\N	3	f	\N	2012-12-05 12:28:12.140946	f	\N
2	4544	130	32	\N	3	f	\N	2012-12-05 12:28:33.220211	f	\N
2	4545	130	32	\N	3	f	\N	2012-12-05 12:35:04.655802	f	\N
2	4547	134	150	\N	3	f	\N	2012-12-05 12:36:55.683593	f	\N
2	4550	130	32	\N	3	f	\N	2012-12-05 12:38:18.010392	f	\N
2	4552	78	182	\N	3	f	\N	2012-12-05 12:42:22.710988	f	\N
2	4555	134	150	\N	3	f	\N	2012-12-05 12:48:47.057359	f	\N
2	4556	134	150	\N	3	f	\N	2012-12-05 12:51:04.552119	f	\N
2	4558	3	125	\N	3	f	\N	2012-12-05 13:13:29.2664	f	\N
2	4559	130	32	\N	3	f	\N	2012-12-05 13:16:56.393105	f	\N
2	734	3	101	\N	3	f	\N	2012-12-05 13:18:09.618824	f	\N
2	5197	134	150	\N	3	f	\N	2012-12-07 10:34:17.579363	t	2012-12-08 09:29:05.802594
2	4563	1	182	\N	3	f	\N	2012-12-05 13:24:15.228561	f	\N
2	4564	1	182	\N	3	f	\N	2012-12-05 13:35:10.876103	f	\N
2	4554	134	150	\N	3	f	\N	2012-12-05 12:47:01.917774	t	2012-12-08 09:36:59.418837
2	4566	3	101	\N	3	f	\N	2012-12-05 13:53:03.053576	f	\N
2	4567	102	102	\N	3	f	\N	2012-12-05 13:54:31.178687	f	\N
2	4568	205	86	\N	3	f	\N	2012-12-05 13:55:41.17806	f	\N
2	4553	134	150	\N	3	f	\N	2012-12-05 12:44:34.314935	t	2012-12-08 09:39:18.111129
2	5357	205	182	\N	3	f	\N	2012-12-08 02:19:14.356831	t	2012-12-08 09:42:36.66004
2	5371	1	1	\N	3	f	\N	2012-12-08 09:51:51.169643	t	2012-12-08 09:53:49.970439
2	5248	205	122	\N	3	f	\N	2012-12-07 11:30:52.610476	t	2012-12-08 09:59:54.366173
2	5207	1	122	\N	3	f	\N	2012-12-07 10:40:47.611034	t	2012-12-08 10:05:20.159003
2	5380	1	101	\N	3	f	\N	2012-12-08 10:07:24.407307	t	2012-12-08 10:11:19.043088
2	5392	191	182	\N	3	f	\N	2012-12-08 10:24:59.968566	t	2012-12-08 10:25:09.138912
2	5401	205	182	\N	3	f	\N	2012-12-08 10:29:29.334486	t	2012-12-08 10:30:33.142068
2	4367	142	152	\N	3	f	\N	2012-12-04 11:58:12.839404	t	2012-12-08 10:35:16.090963
2	5121	205	122	\N	3	f	\N	2012-12-06 20:55:07.994456	f	\N
2	5165	205	182	\N	3	f	\N	2012-12-07 07:17:35.094721	f	\N
2	5184	1	42	\N	3	f	\N	2012-12-07 09:40:26.060538	f	\N
2	4696	74	101	\N	3	f	\N	2012-12-05 19:56:41.755933	t	2012-12-07 09:56:23.341757
2	4697	74	101	\N	3	f	\N	2012-12-05 19:57:47.213798	t	2012-12-07 09:57:24.281213
2	4602	205	101	\N	3	f	\N	2012-12-05 14:55:06.102835	t	2012-12-07 09:58:34.701191
2	4613	205	101	\N	3	f	\N	2012-12-05 15:25:38.209531	t	2012-12-07 09:59:06.554465
2	4605	205	101	\N	3	f	\N	2012-12-05 14:55:49.288226	t	2012-12-07 09:59:45.42335
2	4593	104	125	\N	3	f	\N	2012-12-05 14:17:59.74856	f	\N
2	4612	205	101	\N	3	f	\N	2012-12-05 15:23:46.827251	t	2012-12-07 10:00:12.187449
2	4595	104	125	\N	3	f	\N	2012-12-05 14:20:38.634258	f	\N
2	4618	205	101	\N	3	f	\N	2012-12-05 15:48:55.833435	t	2012-12-07 10:15:44.560814
2	4012	205	25	\N	3	f	\N	2012-11-29 21:36:16.032458	t	2012-12-07 10:17:40.052237
2	374	205	182	\N	3	f	\N	2012-12-05 19:35:09.769043	t	2012-12-07 10:25:34.847705
2	4685	205	182	\N	3	f	\N	2012-12-05 19:31:00.02603	t	2012-12-07 10:27:19.011154
2	5208	134	150	\N	3	f	\N	2012-12-07 10:42:02.986003	f	\N
2	4694	194	182	\N	3	f	\N	2012-12-05 19:52:14.567218	t	2012-12-07 10:44:42.649437
2	1351	3	182	\N	3	f	\N	2012-12-05 14:56:50.312542	f	\N
2	4607	104	125	\N	3	f	\N	2012-12-05 14:58:43.308122	f	\N
2	4690	194	182	\N	3	f	\N	2012-12-05 19:37:57.298074	t	2012-12-07 10:46:10.170648
2	1001	3	182	\N	3	f	\N	2012-12-05 15:29:30.60112	f	\N
2	4376	205	182	\N	3	f	\N	2012-12-04 12:56:01.480088	t	2012-12-07 10:49:10.74565
2	5228	205	122	\N	3	f	\N	2012-12-07 10:54:58.951268	f	\N
2	4616	3	101	\N	3	f	\N	2012-12-05 15:38:54.393413	f	\N
2	4617	205	101	\N	3	f	\N	2012-12-05 15:41:17.638229	f	\N
2	5337	205	122	\N	3	f	\N	2012-12-07 21:24:53.656161	f	\N
2	4621	191	182	\N	3	f	\N	2012-12-05 15:56:48.66026	f	\N
2	5358	1	182	\N	3	f	\N	2012-12-08 09:26:54.845086	t	2012-12-08 09:27:11.63679
2	4622	191	182	\N	3	f	\N	2012-12-05 15:58:16.69517	f	\N
2	472	3	182	\N	3	f	\N	2012-12-06 22:35:41.298268	t	2012-12-08 09:36:28.09099
2	4624	191	182	\N	3	f	\N	2012-12-05 16:01:20.295264	f	\N
2	4630	205	182	\N	3	f	\N	2012-12-05 16:19:24.064404	f	\N
2	1756	61	150	\N	3	f	\N	2012-12-05 16:42:03.344535	f	\N
2	4640	191	182	\N	3	f	\N	2012-12-05 16:56:49.518345	f	\N
2	4641	191	182	\N	3	f	\N	2012-12-05 16:57:21.81665	f	\N
2	5372	98	64	\N	3	f	\N	2012-12-08 09:52:09.889399	t	2012-12-08 09:52:44.931062
2	4643	1	1	\N	3	f	\N	2012-12-05 17:02:05.04716	f	\N
2	4644	1	101	\N	3	f	\N	2012-12-05 17:08:08.439063	f	\N
2	4645	1	101	\N	3	f	\N	2012-12-05 17:09:18.043636	f	\N
2	4639	205	122	\N	3	f	\N	2012-12-05 16:23:17.89938	t	2012-12-08 10:00:26.627677
2	5237	205	122	\N	3	f	\N	2012-12-07 11:01:44.635158	t	2012-12-08 10:03:59.214281
2	5198	205	122	\N	3	f	\N	2012-12-07 10:35:28.441684	t	2012-12-08 10:04:12.152545
2	4657	3	101	\N	3	f	\N	2012-12-05 17:33:15.506332	f	\N
2	753	101	125	\N	3	f	\N	2012-12-05 17:45:59.906255	f	\N
2	5382	191	182	\N	3	f	\N	2012-12-08 10:16:20.32426	t	2012-12-08 10:17:50.645121
2	4714	111	159	\N	3	f	\N	2012-12-05 20:22:28.561973	t	2012-12-07 10:58:30.088521
2	4030	111	159	\N	3	f	\N	2012-11-29 22:14:08.093609	t	2012-12-07 10:59:42.517154
2	4660	205	182	\N	3	f	\N	2012-12-05 18:38:04.370304	f	\N
2	4672	82	102	\N	3	f	\N	2012-12-05 18:45:37.489844	f	\N
2	4679	3	101	\N	3	f	\N	2012-12-05 19:04:28.38177	f	\N
2	4674	54	101	\N	3	f	\N	2012-12-05 18:48:05.955019	f	\N
2	4179	111	159	\N	3	f	\N	2012-12-01 15:40:55.719719	t	2012-12-07 11:03:52.085861
2	5243	205	122	\N	3	f	\N	2012-12-07 11:11:17.010485	f	\N
2	4684	1	101	\N	3	f	\N	2012-12-05 19:30:10.594762	f	\N
2	4686	82	102	\N	3	f	\N	2012-12-05 19:31:22.577185	f	\N
2	4688	201	182	\N	3	f	\N	2012-12-05 19:34:37.02297	f	\N
2	5250	61	182	\N	3	f	\N	2012-12-07 11:47:16.763551	t	2012-12-07 11:47:25.918535
2	5393	1	1	\N	3	f	\N	2012-12-08 10:25:46.683765	t	2012-12-08 10:26:08.708276
2	4691	194	182	\N	3	f	\N	2012-12-05 19:45:53.31985	f	\N
2	4692	3	101	\N	3	f	\N	2012-12-05 19:47:54.919129	f	\N
2	5256	205	122	\N	3	f	\N	2012-12-07 12:21:14.88696	f	\N
2	4698	74	101	\N	3	f	\N	2012-12-05 19:59:30.090868	f	\N
2	4700	96	125	\N	3	f	\N	2012-12-05 20:00:47.655088	f	\N
2	5402	1	1	\N	3	f	\N	2012-12-08 10:29:44.000008	t	2012-12-08 10:30:07.386611
2	4366	142	152	\N	3	f	\N	2012-12-04 11:54:36.284156	t	2012-12-08 10:37:02.026061
2	4703	205	101	\N	3	f	\N	2012-12-05 20:04:56.859196	f	\N
2	4704	74	101	\N	3	f	\N	2012-12-05 20:05:50.660126	f	\N
2	4705	74	101	\N	3	f	\N	2012-12-05 20:07:08.410039	f	\N
2	4706	90	125	\N	3	f	\N	2012-12-05 20:08:26.571491	f	\N
2	1186	104	125	\N	3	f	\N	2012-12-07 13:22:05.954316	f	\N
2	4708	74	101	\N	3	f	\N	2012-12-05 20:10:20.322715	f	\N
2	5271	205	182	\N	3	f	\N	2012-12-07 14:02:40.498676	t	2012-12-07 14:03:01.625436
2	4310	142	152	\N	3	f	\N	2012-12-03 19:36:55.27515	t	2012-12-08 10:40:19.580299
2	4716	1	182	\N	3	f	\N	2012-12-05 20:34:42.502788	f	\N
2	5275	205	182	\N	3	f	\N	2012-12-07 14:05:41.26235	t	2012-12-07 14:06:30.611228
2	5279	205	182	\N	3	f	\N	2012-12-07 14:08:04.678142	t	2012-12-07 14:08:12.497574
2	4721	3	182	\N	3	f	\N	2012-12-05 21:13:48.809529	f	\N
2	4440	205	101	\N	3	f	\N	2012-12-04 21:37:20.939059	t	2012-12-08 10:43:59.238118
2	4725	67	101	\N	3	f	\N	2012-12-05 21:35:16.773518	f	\N
2	4726	67	101	\N	3	f	\N	2012-12-05 21:35:42.006509	f	\N
2	4727	67	101	\N	3	f	\N	2012-12-05 21:35:47.166191	f	\N
2	4309	1	101	\N	3	f	\N	2012-12-03 19:03:09.009929	t	2012-12-08 10:47:52.217461
2	5346	205	182	\N	3	f	\N	2012-12-07 21:49:01.345995	t	2012-12-08 10:50:16.313373
2	5338	205	182	\N	3	f	\N	2012-12-07 21:40:08.839199	t	2012-12-08 10:51:16.348526
2	5133	205	182	\N	3	f	\N	2012-12-06 21:37:29.893524	t	2012-12-08 10:51:44.702898
2	5292	1	182	\N	3	f	\N	2012-12-07 14:28:44.988392	t	2012-12-08 10:52:07.389545
2	5132	205	182	\N	3	f	\N	2012-12-06 21:34:43.835898	t	2012-12-08 10:52:40.417217
2	5139	3	182	\N	3	f	\N	2012-12-06 21:56:58.298571	t	2012-12-08 10:59:12.693585
2	5378	1	182	\N	3	f	\N	2012-12-08 10:01:31.464935	t	2012-12-08 10:59:51.524064
2	5414	1	1	\N	3	f	\N	2012-12-08 11:01:50.489133	t	2012-12-08 11:02:05.976606
2	5416	1	1	\N	3	f	\N	2012-12-08 11:05:11.086934	t	2012-12-08 11:05:35.786828
2	5127	194	182	\N	3	f	\N	2012-12-06 21:13:07.828052	f	\N
2	4735	77	101	\N	3	f	\N	2012-12-05 21:38:17.418005	f	\N
2	4736	102	102	\N	3	f	\N	2012-12-05 21:39:31.641904	f	\N
2	3748	3	101	\N	3	f	\N	2012-11-27 15:49:20.149071	f	\N
2	5142	80	182	\N	3	f	\N	2012-12-06 22:50:12.278172	f	\N
2	5209	134	150	\N	3	f	\N	2012-12-07 10:43:19.396911	t	2012-12-08 09:28:29.601367
2	1191	3	182	\N	3	f	\N	2012-12-05 22:00:26.836022	f	\N
2	4742	205	124	\N	3	f	\N	2012-12-05 22:09:54.937981	f	\N
2	5171	205	101	\N	3	f	\N	2012-12-07 08:58:29.658891	f	\N
2	4805	67	101	\N	3	f	\N	2012-12-06 08:47:15.410485	t	2012-12-07 09:30:45.145527
2	2580	3	101	\N	3	f	\N	2012-12-07 09:40:59.514664	t	2012-12-07 09:52:15.239509
2	4784	205	101	\N	3	f	\N	2012-12-06 08:27:17.994003	t	2012-12-07 10:00:51.446684
2	1090	3	101	\N	3	f	\N	2012-12-05 22:40:30.979066	f	\N
2	2453	1	101	\N	3	f	\N	2012-12-05 22:42:17.603523	t	2012-12-07 10:02:17.270596
2	4424	1	182	\N	3	f	\N	2012-12-04 17:27:27.020444	f	\N
2	5188	1	182	\N	3	f	\N	2012-12-07 10:19:30.670792	f	\N
2	4761	3	101	\N	3	f	\N	2012-12-05 23:13:16.705844	f	\N
2	4762	205	182	\N	3	f	\N	2012-12-05 23:14:13.422174	f	\N
2	3956	1	182	\N	3	f	\N	2012-11-29 17:36:19.577171	t	2012-12-07 10:35:55.632586
2	4767	203	125	\N	3	f	\N	2012-12-06 00:21:30.748501	f	\N
2	4765	194	182	\N	3	f	\N	2012-12-05 23:46:32.031771	t	2012-12-07 10:43:17.497266
2	4777	1	182	\N	3	f	\N	2012-12-06 01:39:43.616054	f	\N
2	4751	194	182	\N	3	f	\N	2012-12-05 22:39:46.963943	t	2012-12-07 10:46:52.029664
2	4768	194	182	\N	3	f	\N	2012-12-06 00:23:59.965512	t	2012-12-07 10:48:25.98536
2	5220	1	122	\N	3	f	\N	2012-12-07 10:49:19.721289	f	\N
2	3964	111	159	\N	3	f	\N	2012-11-29 18:49:31.928587	t	2012-12-07 10:59:45.774666
2	3969	111	159	\N	3	f	\N	2012-11-29 18:53:42.040051	t	2012-12-07 11:01:54.978504
2	4196	111	159	\N	3	f	\N	2012-12-01 20:11:12.984962	t	2012-12-07 11:03:56.939
2	4783	67	101	\N	3	f	\N	2012-12-06 08:00:53.301263	t	2012-12-07 11:08:26.18762
2	4404	3	182	\N	3	f	\N	2012-12-04 17:07:54.562617	t	2012-12-07 11:14:38.402195
2	1000	1	182	\N	3	f	\N	2012-12-07 11:54:58.519688	f	\N
2	5257	186	182	\N	3	f	\N	2012-12-07 12:28:52.108266	f	\N
2	5272	21	101	\N	3	f	\N	2012-12-07 14:02:53.470833	f	\N
2	5276	205	182	\N	3	f	\N	2012-12-07 14:05:57.521699	t	2012-12-07 14:06:26.128821
2	5280	205	182	\N	3	f	\N	2012-12-07 14:08:08.041619	t	2012-12-07 14:08:22.045177
2	4798	102	102	\N	3	f	\N	2012-12-06 08:38:41.802218	f	\N
2	5283	1	182	\N	3	f	\N	2012-12-07 14:09:43.362598	t	2012-12-07 14:09:55.499942
2	4732	67	101	\N	3	f	\N	2012-12-05 21:37:02.371829	t	2012-12-07 14:10:42.734653
2	5286	205	182	\N	3	f	\N	2012-12-07 14:11:19.621288	f	\N
2	4806	82	101	\N	3	f	\N	2012-12-06 08:48:44.986324	f	\N
2	4731	67	101	\N	3	f	\N	2012-12-05 21:35:53.062588	t	2012-12-07 14:11:35.23617
2	3953	22	101	\N	3	f	\N	2012-11-29 16:57:52.877745	t	2012-12-07 14:12:21.28666
2	4740	1	101	\N	3	f	\N	2012-12-05 21:57:55.095411	t	2012-12-07 14:12:26.228486
2	4804	62	101	\N	3	f	\N	2012-12-06 08:44:58.246698	t	2012-12-07 14:12:49.70003
2	4648	1	101	\N	3	f	\N	2012-12-05 17:13:36.339001	t	2012-12-07 14:13:48.056837
2	4821	205	86	\N	3	f	\N	2012-12-06 09:23:14.786724	f	\N
2	4822	3	182	\N	3	f	\N	2012-12-06 09:26:25.751676	f	\N
2	4431	3	182	\N	3	f	\N	2012-12-04 19:36:51.95851	t	2012-12-06 09:30:12.66474
2	4517	1	101	\N	3	f	\N	2012-12-05 10:58:18.48307	t	2012-12-06 09:30:56.115767
2	3686	3	101	\N	3	f	\N	2012-11-26 15:35:40.217722	t	2012-12-06 09:31:34.177024
2	3688	3	182	\N	3	f	\N	2012-11-26 17:51:25.58444	t	2012-12-06 09:32:14.316625
2	4824	104	125	\N	3	f	\N	2012-12-06 09:32:53.178387	t	2012-12-06 09:33:13.89331
2	3619	58	171	\N	3	f	\N	2012-11-22 18:15:22.289823	t	2012-12-06 09:34:52.345001
2	4825	104	125	\N	3	f	\N	2012-12-06 09:36:19.502421	t	2012-12-06 09:36:27.127071
2	4502	104	125	\N	3	f	\N	2012-12-05 10:34:01.360957	t	2012-12-06 09:37:39.744923
2	4507	104	125	\N	3	f	\N	2012-12-05 10:39:22.045347	t	2012-12-06 09:37:59.578885
2	4329	1	101	\N	3	f	\N	2012-12-03 22:58:46.695268	t	2012-12-06 09:38:10.291602
2	4712	104	125	\N	3	f	\N	2012-12-05 20:19:48.120063	t	2012-12-06 09:38:26.390698
2	4826	104	125	\N	3	f	\N	2012-12-06 09:38:16.451985	t	2012-12-06 09:38:30.091185
2	4832	104	101	\N	3	f	\N	2012-12-06 09:41:08.152837	t	2012-12-06 09:41:21.711271
2	4215	58	171	\N	3	f	\N	2012-12-02 11:51:57.801278	t	2012-12-06 09:41:22.463814
2	4508	104	125	\N	3	f	\N	2012-12-05 10:43:35.804069	t	2012-12-06 09:41:45.811266
2	4505	104	125	\N	3	f	\N	2012-12-05 10:37:31.562141	t	2012-12-06 09:42:01.887357
2	4485	104	125	\N	3	f	\N	2012-12-05 10:21:44.999353	t	2012-12-06 09:42:19.841717
2	4489	104	125	\N	3	f	\N	2012-12-05 10:24:32.293569	t	2012-12-06 09:42:33.723165
2	4495	104	125	\N	3	f	\N	2012-12-05 10:29:59.342523	t	2012-12-06 09:42:44.989416
2	4501	104	125	\N	3	f	\N	2012-12-05 10:33:32.044215	t	2012-12-06 09:42:56.887883
2	4514	90	125	\N	3	f	\N	2012-12-05 10:53:08.366759	t	2012-12-06 09:43:09.473931
2	4450	58	171	\N	3	f	\N	2012-12-04 22:19:28.123709	t	2012-12-06 09:45:18.336012
2	4496	104	125	\N	3	f	\N	2012-12-05 10:30:32.961413	t	2012-12-06 09:45:52.54126
2	4511	90	125	\N	3	f	\N	2012-12-05 10:48:09.926262	t	2012-12-06 09:46:44.863102
2	4487	104	101	\N	3	f	\N	2012-12-05 10:23:12.847099	t	2012-12-06 09:47:13.797146
2	4481	104	125	\N	3	f	\N	2012-12-05 10:18:23.71334	t	2012-12-06 09:47:26.261436
2	4506	104	125	\N	3	f	\N	2012-12-05 10:38:23.894019	t	2012-12-06 09:47:39.133146
2	5291	3	101	\N	3	f	\N	2012-12-07 14:23:44.153101	t	2012-12-07 14:24:05.142448
2	4764	3	101	\N	3	f	\N	2012-12-05 23:23:22.465794	t	2012-12-07 14:27:09.454373
2	5359	134	150	\N	3	f	\N	2012-12-08 09:34:56.077904	t	2012-12-08 09:35:22.487688
2	4827	98	64	\N	3	f	\N	2012-12-06 09:40:19.812179	t	2012-12-08 09:38:19.384694
2	5373	98	64	\N	3	f	\N	2012-12-08 09:52:54.975068	t	2012-12-08 09:53:04.17362
2	5231	1	122	\N	3	f	\N	2012-12-07 10:57:02.724293	t	2012-12-08 10:01:28.799542
2	5383	191	42	\N	3	f	\N	2012-12-08 10:16:54.176848	t	2012-12-08 10:17:08.557307
2	1595	191	42	\N	3	f	\N	2012-12-08 10:26:08.652115	t	2012-12-08 10:26:47.672296
2	5403	205	182	\N	3	f	\N	2012-12-08 10:30:46.529664	t	2012-12-08 10:31:01.39147
2	4375	142	152	\N	3	f	\N	2012-12-04 12:39:51.054764	t	2012-12-08 10:37:34.446485
2	4134	1	101	\N	3	f	\N	2012-11-30 22:05:13.327474	t	2012-12-08 10:40:42.483327
2	4368	142	152	\N	3	f	\N	2012-12-04 12:16:22.618351	t	2012-12-08 10:44:53.895199
2	4304	1	101	\N	3	f	\N	2012-12-03 18:23:24.174803	t	2012-12-08 10:49:15.352895
2	5344	1	182	\N	3	f	\N	2012-12-07 21:44:27.214723	t	2012-12-08 10:50:23.603448
2	4491	104	125	\N	3	f	\N	2012-12-05 10:25:43.821558	t	2012-12-06 09:47:51.974206
2	4493	104	125	\N	3	f	\N	2012-12-05 10:27:44.778152	t	2012-12-06 09:48:07.743006
2	4219	58	171	\N	3	f	\N	2012-12-02 15:33:28.042175	t	2012-12-06 09:48:20.962573
2	4050	205	22	\N	3	f	\N	2012-11-30 09:43:55.951209	t	2012-12-06 09:48:37.582986
2	4833	104	125	\N	3	f	\N	2012-12-06 09:48:27.942609	t	2012-12-06 09:48:37.655961
2	4510	90	125	\N	3	f	\N	2012-12-05 10:47:46.427267	t	2012-12-06 09:48:57.134304
2	4513	90	125	\N	3	f	\N	2012-12-05 10:49:37.17952	t	2012-12-06 09:49:16.048895
2	4483	104	125	\N	3	f	\N	2012-12-05 10:19:53.541165	t	2012-12-06 09:49:34.626444
2	4497	104	125	\N	3	f	\N	2012-12-05 10:31:13.981687	t	2012-12-06 09:49:52.962306
2	4778	104	125	\N	3	f	\N	2012-12-06 07:09:39.465342	t	2012-12-06 09:49:58.665322
2	4753	104	125	\N	3	f	\N	2012-12-05 22:45:20.283672	t	2012-12-06 09:50:21.990685
2	4224	58	171	\N	3	f	\N	2012-12-02 22:55:41.587603	t	2012-12-06 09:50:27.788234
2	4834	104	125	\N	3	f	\N	2012-12-06 09:50:55.377743	t	2012-12-06 09:51:05.838808
2	4520	104	125	\N	3	f	\N	2012-12-05 11:04:29.124936	t	2012-12-06 09:51:21.533751
2	4059	58	171	\N	3	f	\N	2012-11-30 10:49:55.169843	t	2012-12-06 09:51:47.096714
2	4494	90	125	\N	3	f	\N	2012-12-05 10:29:38.231081	t	2012-12-06 09:51:49.822186
2	4490	104	125	\N	3	f	\N	2012-12-05 10:25:34.213447	t	2012-12-06 09:52:09.737639
2	3611	58	171	\N	3	f	\N	2012-11-22 15:26:53.622371	t	2012-12-06 09:52:48.072543
2	4838	104	125	\N	3	f	\N	2012-12-06 09:52:32.034024	t	2012-12-06 09:53:03.06096
2	4474	104	125	\N	3	f	\N	2012-12-05 09:39:11.957027	t	2012-12-06 09:53:07.943939
2	4470	104	125	\N	3	f	\N	2012-12-05 09:35:15.355387	t	2012-12-06 09:53:35.727995
2	4841	104	125	\N	3	f	\N	2012-12-06 09:53:31.128957	t	2012-12-06 09:53:41.847807
2	4475	104	125	\N	3	f	\N	2012-12-05 09:40:44.972809	t	2012-12-06 09:53:43.008921
2	4512	90	125	\N	3	f	\N	2012-12-05 10:48:45.820102	t	2012-12-06 09:53:55.261888
2	4711	104	125	\N	3	f	\N	2012-12-05 20:19:19.688	t	2012-12-06 09:54:03.758656
2	4488	90	125	\N	3	f	\N	2012-12-05 10:23:39.021055	t	2012-12-06 09:54:07.182352
2	4843	90	125	\N	3	f	\N	2012-12-06 09:53:52.405389	t	2012-12-06 09:54:12.697626
2	4592	104	125	\N	3	f	\N	2012-12-05 14:16:58.444056	t	2012-12-06 09:54:24.73658
2	4699	104	125	\N	3	f	\N	2012-12-05 19:59:53.301253	t	2012-12-06 09:54:40.773821
2	4562	104	101	\N	3	f	\N	2012-12-05 13:20:07.646274	t	2012-12-06 09:54:42.679063
2	5128	3	101	\N	3	f	\N	2012-12-06 21:15:35.542615	f	\N
2	4466	104	125	\N	3	f	\N	2012-12-05 09:30:08.776858	t	2012-12-06 09:55:01.592883
2	4499	90	125	\N	3	f	\N	2012-12-05 10:32:05.069653	t	2012-12-06 09:55:02.32767
2	4769	130	32	\N	3	f	\N	2012-12-06 00:30:30.729275	t	2012-12-06 09:55:15.385683
2	4844	104	125	\N	3	f	\N	2012-12-06 09:54:49.038253	f	\N
2	4589	104	125	\N	3	f	\N	2012-12-05 14:02:00.00669	t	2012-12-06 09:55:26.598944
2	4486	104	125	\N	3	f	\N	2012-12-05 10:22:22.746066	t	2012-12-06 09:55:28.736903
2	4500	90	125	\N	3	f	\N	2012-12-05 10:32:08.342061	t	2012-12-06 09:55:36.176181
2	4471	104	125	\N	3	f	\N	2012-12-05 09:37:01.248771	t	2012-12-06 09:55:54.224414
2	4534	101	101	\N	3	f	\N	2012-12-05 11:57:22.279732	t	2012-12-06 09:56:12.872879
2	4467	104	125	\N	3	f	\N	2012-12-05 09:32:45.037237	t	2012-12-06 09:56:13.318961
2	4120	58	171	\N	3	f	\N	2012-11-30 17:51:22.984289	t	2012-12-06 09:56:20.184235
2	4846	104	125	\N	3	f	\N	2012-12-06 09:56:14.795778	t	2012-12-06 09:56:24.362339
2	4465	104	125	\N	3	f	\N	2012-12-05 09:29:36.289594	t	2012-12-06 09:56:34.229466
2	4689	103	125	\N	3	f	\N	2012-12-05 19:35:34.181519	t	2012-12-06 09:56:35.840383
2	4591	104	125	\N	3	f	\N	2012-12-05 14:15:54.775675	t	2012-12-06 09:56:50.031308
2	4795	102	102	\N	3	f	\N	2012-12-06 08:35:55.755926	t	2012-12-06 09:56:53.630123
2	4717	104	101	\N	3	f	\N	2012-12-05 20:41:06.638918	t	2012-12-06 09:57:05.571084
2	4848	90	101	\N	3	f	\N	2012-12-06 09:57:00.06644	t	2012-12-06 09:57:08.013763
2	4472	104	125	\N	3	f	\N	2012-12-05 09:38:10.598018	t	2012-12-06 09:57:17.849768
2	4835	104	125	\N	3	f	\N	2012-12-06 09:51:18.748698	t	2012-12-06 09:57:35.27204
2	4462	103	125	\N	3	f	\N	2012-12-05 09:23:50.453938	t	2012-12-06 09:57:36.880057
2	4675	104	125	\N	3	f	\N	2012-12-05 18:52:23.109624	t	2012-12-06 09:57:44.505021
2	4598	104	125	\N	3	f	\N	2012-12-05 14:22:13.451062	t	2012-12-06 09:58:02.660764
2	4600	90	125	\N	3	f	\N	2012-12-05 14:50:41.038118	t	2012-12-06 09:58:05.524242
2	4473	104	125	\N	3	f	\N	2012-12-05 09:38:46.782986	t	2012-12-06 09:58:05.524254
2	3683	3	64	\N	3	f	\N	2012-11-26 11:31:53.18478	t	2012-12-06 09:58:11.279399
2	4601	104	125	\N	3	f	\N	2012-12-05 14:54:13.737876	t	2012-12-06 09:58:13.89068
2	4608	104	125	\N	3	f	\N	2012-12-05 14:59:52.612006	t	2012-12-06 09:58:39.316095
2	4782	3	101	\N	3	f	\N	2012-12-06 07:55:01.064073	t	2012-12-06 09:59:07.237248
2	4594	104	125	\N	3	f	\N	2012-12-05 14:18:56.778171	t	2012-12-06 09:59:15.130358
2	4446	130	32	\N	3	f	\N	2012-12-04 22:12:49.588226	t	2012-12-06 09:59:15.701906
2	4779	3	1	\N	3	f	\N	2012-12-06 07:44:36.16798	t	2012-12-06 09:59:23.49262
2	3639	205	101	\N	3	f	\N	2012-11-23 00:19:46.022053	t	2012-12-06 09:59:39.449567
2	4850	104	125	\N	3	f	\N	2012-12-06 09:59:33.518875	t	2012-12-06 09:59:40.220497
2	4464	104	125	\N	3	f	\N	2012-12-05 09:27:54.269118	t	2012-12-06 09:59:57.920771
2	4718	205	182	\N	3	f	\N	2012-12-05 20:58:02.477134	t	2012-12-06 10:00:22.716851
2	4052	58	171	\N	3	f	\N	2012-11-30 09:57:43.655287	t	2012-12-06 10:00:46.356045
2	4750	1	182	\N	3	f	\N	2012-12-05 22:34:28.253318	t	2012-12-06 10:01:17.413804
2	4436	74	101	\N	3	f	\N	2012-12-04 20:32:23.625778	t	2012-12-06 10:01:38.736633
2	4557	74	101	\N	3	f	\N	2012-12-05 12:59:05.652876	t	2012-12-06 10:02:21.706255
2	4851	102	102	\N	3	f	\N	2012-12-06 10:02:30.651407	f	\N
2	4432	1	182	\N	3	f	\N	2012-12-04 20:10:35.608125	t	2012-12-06 10:02:46.527365
2	4439	205	32	\N	3	f	\N	2012-12-04 21:28:54.052751	t	2012-12-06 10:03:07.834348
2	4438	1	1	\N	3	f	\N	2012-12-04 21:24:31.622269	t	2012-12-06 10:03:33.70464
2	4590	58	181	\N	3	f	\N	2012-12-05 14:07:19.145525	t	2012-12-06 10:03:36.029616
2	4614	58	171	\N	3	f	\N	2012-12-05 15:34:16.505044	t	2012-12-06 10:04:01.08597
2	4854	58	171	\N	3	f	\N	2012-12-06 10:03:50.185558	t	2012-12-06 10:04:04.338998
2	4477	205	32	\N	3	f	\N	2012-12-05 10:08:36.386689	t	2012-12-06 10:04:05.815642
2	4482	205	32	\N	3	f	\N	2012-12-05 10:18:24.530427	t	2012-12-06 10:04:21.037883
2	4536	130	32	\N	3	f	\N	2012-12-05 12:00:23.144196	t	2012-12-06 10:04:25.629449
2	4719	205	32	\N	3	f	\N	2012-12-05 21:06:32.838149	t	2012-12-06 10:04:35.446633
2	4538	130	32	\N	3	f	\N	2012-12-05 12:06:53.315994	t	2012-12-06 10:04:38.709203
2	5173	1	84	\N	3	f	\N	2012-12-07 09:15:43.03929	t	2012-12-07 09:16:18.493594
2	4233	67	101	\N	3	f	\N	2012-12-03 11:40:16.305127	t	2012-12-07 09:41:08.916143
2	5189	191	182	\N	3	f	\N	2012-12-07 10:20:26.884289	f	\N
2	5200	134	150	\N	3	f	\N	2012-12-07 10:36:08.8015	f	\N
2	5221	1	182	\N	3	f	\N	2012-12-07 10:49:19.864831	t	2012-12-07 10:49:26.663926
2	3828	205	182	\N	3	f	\N	2012-11-28 15:10:24.476756	t	2012-12-07 10:58:22.434574
2	4150	111	159	\N	3	f	\N	2012-11-30 22:52:27.311945	t	2012-12-07 10:59:50.507915
2	4330	111	159	\N	3	f	\N	2012-12-04 00:05:27.548715	t	2012-12-07 11:02:30.689359
2	5149	1	182	\N	3	f	\N	2012-12-07 00:22:59.434948	t	2012-12-07 11:05:09.437007
2	3654	3	182	\N	3	f	\N	2012-11-23 23:35:09.773202	t	2012-12-07 11:16:41.298114
2	4526	130	32	\N	3	f	\N	2012-12-05 11:35:40.648421	t	2012-12-06 10:04:47.360043
2	4599	205	32	\N	3	f	\N	2012-12-05 14:23:08.245506	t	2012-12-06 10:04:48.026821
2	4533	130	32	\N	3	f	\N	2012-12-05 11:55:53.843731	t	2012-12-06 10:04:53.194757
2	4122	3	182	\N	3	f	\N	2012-11-30 18:42:31.262145	t	2012-12-06 10:05:32.907656
2	4445	130	32	\N	3	f	\N	2012-12-04 22:12:23.014397	t	2012-12-06 10:05:40.260535
2	2014	130	32	\N	3	f	\N	2012-12-05 11:53:41.55562	t	2012-12-06 10:05:52.781461
2	3788	1	182	\N	3	f	\N	2012-11-27 20:33:21.087719	t	2012-12-06 10:06:01.878666
2	4443	130	32	\N	3	f	\N	2012-12-04 21:59:47.093327	t	2012-12-06 10:06:14.33317
2	4597	130	32	\N	3	f	\N	2012-12-05 14:21:14.774609	t	2012-12-06 10:06:24.373689
2	4856	205	182	\N	3	f	\N	2012-12-06 10:06:40.936287	f	\N
2	4444	130	32	\N	3	f	\N	2012-12-04 22:03:40.87498	t	2012-12-06 10:06:41.551824
2	4539	130	32	\N	3	f	\N	2012-12-05 12:11:56.549693	t	2012-12-06 10:06:47.855012
2	4596	130	32	\N	3	f	\N	2012-12-05 14:21:00.328477	t	2012-12-06 10:07:07.419391
2	4855	58	171	\N	3	f	\N	2012-12-06 10:05:41.620275	t	2012-12-06 10:07:30.982867
2	4569	130	32	\N	3	f	\N	2012-12-05 13:55:46.718098	t	2012-12-06 10:07:34.813149
2	4658	130	32	\N	3	f	\N	2012-12-05 18:01:27.598638	t	2012-12-06 10:07:35.685937
2	4118	58	171	\N	3	f	\N	2012-11-30 16:59:20.24629	t	2012-12-06 10:08:25.24402
2	4857	205	182	\N	3	f	\N	2012-12-06 10:08:19.198417	t	2012-12-06 10:08:36.774809
2	4365	58	171	\N	3	f	\N	2012-12-04 11:45:41.895687	t	2012-12-06 10:09:20.218632
2	4298	58	171	\N	3	f	\N	2012-12-03 16:39:07.27992	t	2012-12-06 10:09:46.21043
2	1026	3	182	\N	3	f	\N	2012-12-04 16:35:03.476857	t	2012-12-06 10:09:54.312967
2	4503	204	32	\N	3	f	\N	2012-12-05 10:34:12.37876	t	2012-12-06 10:10:59.621218
2	4112	58	171	\N	3	f	\N	2012-11-30 16:31:00.684499	t	2012-12-06 10:11:55.850676
2	1416	3	182	\N	3	f	\N	2012-11-30 01:23:11.934109	t	2012-12-06 10:12:57.104847
2	4518	58	171	\N	3	f	\N	2012-12-05 11:00:35.067347	t	2012-12-06 10:13:33.702262
2	4861	102	102	\N	3	f	\N	2012-12-06 10:14:23.243836	f	\N
2	4862	3	182	\N	3	f	\N	2012-12-06 10:15:55.903983	t	2012-12-06 10:16:09.241983
2	4863	3	182	\N	3	f	\N	2012-12-06 10:16:57.878821	t	2012-12-06 10:17:10.083425
2	3890	81	102	\N	3	f	\N	2012-11-29 09:38:27.425509	t	2012-12-06 10:17:49.252222
2	3889	81	102	\N	3	f	\N	2012-11-29 09:37:48.875027	t	2012-12-06 10:18:03.587295
2	4525	205	182	\N	3	f	\N	2012-12-05 11:33:26.777413	t	2012-12-06 10:21:06.599743
2	3849	1	182	\N	3	f	\N	2012-11-28 19:59:42.223607	t	2012-12-06 10:21:31.935082
2	4866	1	1	\N	3	f	\N	2012-12-06 10:34:23.333003	f	\N
2	4865	3	101	\N	3	f	\N	2012-12-06 10:34:09.047264	t	2012-12-06 10:35:10.435386
2	4707	194	182	\N	3	f	\N	2012-12-05 20:08:32.550062	t	2012-12-06 10:35:43.66952
2	3806	3	182	\N	3	f	\N	2012-11-28 00:03:22.423651	t	2012-12-06 10:43:23.382729
2	4867	67	101	\N	3	f	\N	2012-12-06 10:45:06.863949	f	\N
2	4174	1	182	\N	3	f	\N	2012-12-01 13:36:53.625314	t	2012-12-06 10:46:00.152401
2	4175	1	182	\N	3	f	\N	2012-12-01 13:44:34.254649	t	2012-12-06 10:46:16.984688
2	4868	205	84	\N	3	f	\N	2012-12-06 10:56:16.292302	f	\N
2	4869	3	101	\N	3	f	\N	2012-12-06 10:57:57.961781	f	\N
2	4873	205	84	\N	3	f	\N	2012-12-06 11:02:44.502203	f	\N
2	4874	1	182	\N	3	f	\N	2012-12-06 11:03:27.588327	t	2012-12-06 11:03:39.502738
2	4875	205	84	\N	3	f	\N	2012-12-06 11:04:24.43691	f	\N
2	4877	72	101	\N	3	f	\N	2012-12-06 11:09:09.881432	t	2012-12-06 11:09:22.941192
2	1053	205	101	\N	3	f	\N	2012-11-30 16:13:13.653	t	2012-12-06 11:11:12.71696
2	4878	1	101	\N	3	f	\N	2012-12-06 11:10:07.883794	t	2012-12-06 11:11:21.362355
2	1081	3	101	\N	3	f	\N	2012-11-28 17:55:01.59796	t	2012-12-06 11:13:38.816574
2	4880	80	101	\N	3	f	\N	2012-12-06 11:14:34.919597	t	2012-12-06 11:15:17.726881
2	4881	41	182	\N	3	f	\N	2012-12-06 11:18:29.884276	t	2012-12-06 11:18:38.336555
2	937	3	182	\N	3	f	\N	2012-12-06 11:20:29.34384	t	2012-12-06 11:39:12.62471
2	4882	1	182	\N	3	f	\N	2012-12-06 11:39:26.45442	f	\N
2	4886	205	84	\N	3	f	\N	2012-12-06 11:41:23.649211	f	\N
2	4888	1	182	\N	3	f	\N	2012-12-06 11:41:46.669158	t	2012-12-06 11:42:01.612852
2	4887	203	182	\N	3	f	\N	2012-12-06 11:41:31.362778	t	2012-12-06 11:42:23.909479
2	816	3	182	\N	3	f	\N	2012-12-06 11:42:50.451586	f	\N
2	3794	1	182	\N	3	f	\N	2012-11-27 21:18:13.670489	t	2012-12-06 11:45:01.633972
2	4710	3	182	\N	3	f	\N	2012-12-05 20:17:19.713631	t	2012-12-06 11:45:15.59657
2	4896	111	159	\N	3	f	\N	2012-12-06 11:50:30.044532	f	\N
2	5129	205	182	\N	3	f	\N	2012-12-06 21:27:43.590191	f	\N
2	333	3	101	\N	3	f	\N	2012-11-24 18:57:36.217376	t	2012-12-06 11:53:13.784949
2	307	3	182	\N	3	f	\N	2012-11-19 11:04:46.671259	t	2012-12-06 11:53:20.866138
2	328	3	101	\N	3	f	\N	2012-11-17 17:43:09.011009	t	2012-12-06 11:53:32.492676
2	4897	3	182	\N	3	f	\N	2012-12-06 11:53:32.662003	t	2012-12-06 11:53:43.278101
2	4898	1	159	\N	3	f	\N	2012-12-06 11:55:58.215852	f	\N
2	4900	3	101	\N	3	f	\N	2012-12-06 11:58:09.305411	t	2012-12-06 11:58:18.382233
2	4899	88	101	\N	3	f	\N	2012-12-06 11:58:00.308259	t	2012-12-06 11:58:49.053305
2	749	1	101	\N	3	f	\N	2012-11-21 12:35:36.798367	t	2012-12-06 11:58:49.946645
2	4901	90	101	\N	3	f	\N	2012-12-06 12:00:33.606545	t	2012-12-06 12:00:43.285304
2	4902	86	101	\N	3	f	\N	2012-12-06 12:00:42.691949	t	2012-12-06 12:00:52.706605
2	4903	104	125	\N	3	f	\N	2012-12-06 12:01:38.147452	t	2012-12-06 12:01:46.318705
2	4905	205	125	\N	3	f	\N	2012-12-06 12:01:56.626275	t	2012-12-06 12:02:13.538644
2	4907	104	101	\N	3	f	\N	2012-12-06 12:02:12.760756	t	2012-12-06 12:02:26.826145
2	4912	21	101	\N	3	f	\N	2012-12-06 12:02:52.426259	f	\N
2	4893	205	84	\N	3	f	\N	2012-12-06 11:42:52.226087	t	2012-12-07 09:15:45.682088
2	4864	205	182	\N	3	f	\N	2012-12-06 10:25:14.782304	t	2012-12-07 09:21:05.988501
2	5174	1	182	\N	3	f	\N	2012-12-07 09:22:02.596594	t	2012-12-07 09:22:11.82919
2	4256	67	101	\N	3	f	\N	2012-12-03 11:51:39.808896	t	2012-12-07 09:43:38.867377
2	5190	1	125	\N	3	f	\N	2012-12-07 10:21:24.863174	t	2012-12-07 10:21:42.882208
2	3826	205	101	\N	3	f	\N	2012-11-28 12:56:58.071098	t	2012-12-07 10:37:10.487891
2	4917	194	1	\N	3	f	\N	2012-12-06 12:05:21.571324	t	2012-12-07 10:44:07.206719
2	5222	205	122	\N	3	f	\N	2012-12-07 10:49:52.548829	f	\N
2	4226	111	159	\N	3	f	\N	2012-12-03 09:57:29.592719	t	2012-12-07 11:00:04.922072
2	3970	111	159	\N	3	f	\N	2012-11-29 18:54:53.203526	t	2012-12-07 11:02:33.976328
2	5244	1	122	\N	3	f	\N	2012-12-07 11:18:50.816722	f	\N
2	5252	205	182	\N	3	f	\N	2012-12-07 11:56:49.043543	t	2012-12-07 11:56:58.702467
2	5340	72	125	\N	3	f	\N	2012-12-07 21:43:47.358375	f	\N
2	5268	111	101	\N	3	f	\N	2012-12-07 13:58:38.390421	t	2012-12-07 13:58:48.779755
2	803	1	182	\N	3	f	\N	2012-12-06 11:56:35.154037	t	2012-12-08 09:27:59.114617
2	5361	1	101	\N	3	f	\N	2012-12-08 09:39:19.64845	t	2012-12-08 09:39:54.611787
2	5374	98	64	\N	3	f	\N	2012-12-08 09:53:04.743192	t	2012-12-08 09:53:14.524758
2	4914	105	125	\N	3	f	\N	2012-12-06 12:03:58.454176	t	2012-12-06 12:04:12.457549
2	4904	103	125	\N	3	f	\N	2012-12-06 12:01:44.789645	t	2012-12-06 12:04:41.506328
2	4921	103	182	\N	3	f	\N	2012-12-06 12:06:08.350241	f	\N
2	4923	104	125	\N	3	f	\N	2012-12-06 12:08:32.689505	t	2012-12-06 12:08:47.270721
2	4929	205	84	\N	3	f	\N	2012-12-06 12:19:36.871599	f	\N
2	4930	205	84	\N	3	f	\N	2012-12-06 12:19:45.454059	f	\N
2	934	3	42	\N	3	f	\N	2012-12-06 12:23:38.527025	t	2012-12-06 12:25:46.611756
2	5360	134	150	\N	3	f	\N	2012-12-08 09:39:04.825936	t	2012-12-08 09:39:19.690877
2	3645	205	182	\N	3	f	\N	2012-11-23 19:38:28.550805	t	2012-12-06 13:03:32.692031
2	4935	1	182	\N	3	f	\N	2012-12-06 13:03:45.518383	f	\N
2	5130	205	182	\N	3	f	\N	2012-12-06 21:30:58.305587	f	\N
2	4937	1	101	\N	3	f	\N	2012-12-06 13:21:26.364884	f	\N
2	4940	1	101	\N	3	f	\N	2012-12-06 13:23:21.829054	f	\N
2	3981	42	182	\N	3	f	\N	2012-11-29 19:23:20.149921	t	2012-12-06 13:50:47.176144
2	973	3	101	\N	3	f	\N	2012-11-30 15:54:36.409778	t	2012-12-06 13:51:45.545423
2	4942	1	101	\N	3	f	\N	2012-12-06 13:55:32.557519	t	2012-12-06 13:55:39.493725
2	3750	3	125	\N	3	f	\N	2012-11-27 16:11:24.269369	t	2012-12-06 14:00:06.918747
2	4944	205	101	\N	3	f	\N	2012-12-06 14:02:47.3398	f	\N
2	4946	3	125	\N	3	f	\N	2012-12-06 14:05:31.838672	t	2012-12-06 14:08:11.608885
2	4945	3	101	\N	3	f	\N	2012-12-06 14:02:57.932037	t	2012-12-06 14:08:20.829985
2	4949	65	101	\N	3	f	\N	2012-12-06 14:12:53.575504	f	\N
2	4659	102	102	\N	3	f	\N	2012-12-05 18:30:40.219304	t	2012-12-06 14:14:16.897467
2	1810	82	102	\N	3	f	\N	2012-12-05 22:58:39.263834	t	2012-12-06 14:14:33.188014
2	4794	102	102	\N	3	f	\N	2012-12-06 08:35:38.133553	t	2012-12-06 14:15:37.601523
2	2344	1	182	\N	3	f	\N	2012-12-06 08:35:18.967574	t	2012-12-06 14:16:32.604025
2	1795	82	102	\N	3	f	\N	2012-12-06 08:57:25.957001	t	2012-12-06 14:17:15.721222
2	4792	102	102	\N	3	f	\N	2012-12-06 08:33:42.563501	t	2012-12-06 14:17:31.348572
2	4951	102	101	\N	3	f	\N	2012-12-06 14:18:17.548662	t	2012-12-06 14:19:21.140236
2	4575	82	102	\N	3	f	\N	2012-12-05 13:58:27.916612	t	2012-12-06 14:19:23.498295
2	4744	102	102	\N	3	f	\N	2012-12-05 22:22:08.132689	t	2012-12-06 14:19:55.950441
2	4754	102	102	\N	3	f	\N	2012-12-05 22:47:25.674003	t	2012-12-06 14:20:31.995035
2	4953	102	102	\N	3	f	\N	2012-12-06 14:22:04.78097	t	2012-12-06 14:22:42.223862
2	4687	102	102	\N	3	f	\N	2012-12-05 19:34:00.591491	t	2012-12-06 14:23:10.631264
2	4790	102	102	\N	3	f	\N	2012-12-06 08:32:05.924981	t	2012-12-06 14:23:39.83318
2	4820	102	102	\N	3	f	\N	2012-12-06 09:14:46.045875	t	2012-12-06 14:23:53.696216
2	1789	102	102	\N	3	f	\N	2012-12-01 20:57:04.874987	t	2012-12-06 14:24:15.02982
2	4802	102	102	\N	3	f	\N	2012-12-06 08:44:06.370953	t	2012-12-06 14:24:33.702125
2	4817	102	102	\N	3	f	\N	2012-12-06 09:05:28.902457	t	2012-12-06 14:24:42.760848
2	4793	82	102	\N	3	f	\N	2012-12-06 08:34:29.119806	t	2012-12-06 14:25:01.727045
2	4803	82	102	\N	3	f	\N	2012-12-06 08:44:17.107026	t	2012-12-06 14:25:34.51483
2	4774	3	101	\N	3	f	\N	2012-12-06 01:23:49.32603	t	2012-12-06 14:25:37.748233
2	4796	82	102	\N	3	f	\N	2012-12-06 08:37:12.279608	t	2012-12-06 14:25:39.012743
2	4818	102	102	\N	3	f	\N	2012-12-06 09:08:58.57021	t	2012-12-06 14:26:21.271307
2	4570	102	102	\N	3	f	\N	2012-12-05 13:56:01.34444	t	2012-12-06 14:26:56.84776
2	4800	82	102	\N	3	f	\N	2012-12-06 08:41:13.435699	t	2012-12-06 14:27:13.120917
2	4785	102	102	\N	3	f	\N	2012-12-06 08:30:07.437181	t	2012-12-06 14:27:24.056263
2	4823	102	102	\N	3	f	\N	2012-12-06 09:31:28.150226	t	2012-12-06 14:27:42.572473
2	4933	102	102	\N	3	f	\N	2012-12-06 12:48:22.99465	t	2012-12-06 14:27:52.901251
2	4952	62	101	\N	3	f	\N	2012-12-06 14:20:57.834429	t	2012-12-06 14:28:22.949794
2	4786	102	102	\N	3	f	\N	2012-12-06 08:31:01.28756	t	2012-12-06 14:28:33.138885
2	4799	102	102	\N	3	f	\N	2012-12-06 08:40:17.41072	t	2012-12-06 14:29:09.469217
2	4583	102	102	\N	3	f	\N	2012-12-05 13:59:14.85187	t	2012-12-06 14:29:42.592655
2	4565	102	102	\N	3	f	\N	2012-12-05 13:52:35.714285	t	2012-12-06 14:29:46.957557
2	4578	82	102	\N	3	f	\N	2012-12-05 13:58:50.298559	t	2012-12-06 14:30:26.874202
2	4734	67	101	\N	3	f	\N	2012-12-05 21:38:00.268812	t	2012-12-06 14:30:46.40714
2	4752	102	102	\N	3	f	\N	2012-12-05 22:39:48.561247	t	2012-12-06 14:31:05.697889
2	4728	67	101	\N	3	f	\N	2012-12-05 21:35:47.866177	t	2012-12-06 14:31:15.028409
2	4971	205	84	\N	3	f	\N	2012-12-06 14:43:53.974793	t	2012-12-07 09:01:04.809015
2	4950	3	101	\N	3	f	\N	2012-12-06 14:16:06.273791	t	2012-12-06 14:31:45.99402
2	4729	67	101	\N	3	f	\N	2012-12-05 21:35:48.95954	t	2012-12-06 14:31:54.461947
2	4737	67	101	\N	3	f	\N	2012-12-05 21:39:37.598821	t	2012-12-06 14:32:15.081789
2	4960	205	124	\N	3	f	\N	2012-12-06 14:32:27.380506	f	\N
2	1007	21	101	\N	3	f	\N	2012-12-08 09:58:41.512242	t	2012-12-08 09:59:23.840448
2	4961	1	101	\N	3	f	\N	2012-12-06 14:33:51.025755	t	2012-12-06 14:33:58.452375
2	646	3	101	\N	3	f	\N	2012-11-23 09:06:49.626278	t	2012-12-06 14:34:31.533573
2	4962	205	84	\N	3	f	\N	2012-12-06 14:34:33.706272	f	\N
2	3689	3	182	\N	3	f	\N	2012-11-26 18:34:14.217252	t	2012-12-06 14:34:55.033838
2	1133	3	125	\N	3	f	\N	2012-12-04 09:30:40.649831	t	2012-12-06 14:36:09.222187
2	4964	142	152	\N	3	f	\N	2012-12-06 14:36:15.150645	f	\N
2	4967	205	84	\N	3	f	\N	2012-12-06 14:39:30.446619	f	\N
2	4965	205	84	\N	3	f	\N	2012-12-06 14:37:14.321271	t	2012-12-07 09:06:35.913694
2	5146	205	84	\N	3	f	\N	2012-12-06 23:55:55.656476	t	2012-12-07 09:07:13.473677
2	4069	41	182	\N	3	f	\N	2012-11-30 11:54:08.359474	t	2012-12-06 14:42:34.206067
2	4970	205	84	\N	3	f	\N	2012-12-06 14:43:34.160242	f	\N
2	4973	205	125	\N	3	f	\N	2012-12-06 14:44:37.619926	t	2012-12-06 14:44:54.429433
2	4963	205	84	\N	3	f	\N	2012-12-06 14:34:52.394901	t	2012-12-07 09:09:10.635271
2	4972	205	84	\N	3	f	\N	2012-12-06 14:44:21.556996	t	2012-12-07 09:13:32.733232
2	4932	205	84	\N	3	f	\N	2012-12-06 12:40:16.758328	t	2012-12-07 09:13:54.101113
2	4968	205	84	\N	3	f	\N	2012-12-06 14:39:42.532187	t	2012-12-07 09:17:43.939503
2	5175	1	182	\N	3	f	\N	2012-12-07 09:24:02.582838	f	\N
2	4969	205	84	\N	3	f	\N	2012-12-06 14:43:05.974886	t	2012-12-07 09:32:02.247886
2	5185	1	84	\N	3	f	\N	2012-12-07 09:47:39.02395	f	\N
2	4797	102	102	\N	3	f	\N	2012-12-06 08:38:31.677336	f	\N
2	3670	1	84	\N	3	f	\N	2012-11-25 11:51:01.898842	t	2012-12-07 09:58:49.225597
2	4966	205	84	\N	3	f	\N	2012-12-06 14:38:31.55339	t	2012-12-07 10:01:19.455591
2	352	2	182	\N	3	f	\N	2012-12-07 10:27:18.299625	t	2012-12-07 10:28:18.55357
2	4248	67	101	\N	3	f	\N	2012-12-03 11:45:42.70349	t	2012-12-07 10:37:22.328046
2	5384	191	182	\N	3	f	\N	2012-12-08 10:17:27.196467	t	2012-12-08 10:19:56.921683
2	5394	191	182	\N	3	f	\N	2012-12-08 10:26:30.813054	t	2012-12-08 10:26:38.637508
2	5404	1	1	\N	3	f	\N	2012-12-08 10:31:27.354466	t	2012-12-08 10:31:39.65494
2	4384	142	152	\N	3	f	\N	2012-12-04 13:15:11.053222	t	2012-12-08 10:38:33.154184
2	4321	142	152	\N	3	f	\N	2012-12-03 21:55:25.923258	t	2012-12-08 10:40:55.145914
2	4974	205	84	\N	3	f	\N	2012-12-06 14:45:20.83545	f	\N
2	4975	205	84	\N	3	f	\N	2012-12-06 14:45:24.194335	f	\N
2	4977	1	84	\N	3	f	\N	2012-12-06 14:45:51.62157	f	\N
2	313	3	101	\N	3	f	\N	2012-11-25 17:32:04.339479	t	2012-12-06 14:45:59.95868
2	4978	205	182	\N	3	f	\N	2012-12-06 14:48:07.611633	t	2012-12-06 14:48:18.420733
2	4979	205	182	\N	3	f	\N	2012-12-06 14:49:11.289058	t	2012-12-06 14:49:21.182024
2	4980	104	125	\N	3	f	\N	2012-12-06 14:49:19.322298	t	2012-12-06 14:49:37.62608
2	4982	205	182	\N	3	f	\N	2012-12-06 14:52:58.580819	f	\N
2	4985	104	101	\N	3	f	\N	2012-12-06 14:55:55.946715	t	2012-12-06 14:56:08.805525
2	4986	1	84	\N	3	f	\N	2012-12-06 14:58:03.971343	f	\N
2	4987	205	84	\N	3	f	\N	2012-12-06 14:58:49.3966	f	\N
2	415	1	101	\N	3	f	\N	2012-12-06 14:57:30.732044	t	2012-12-06 15:00:54.776052
2	4988	205	84	\N	3	f	\N	2012-12-06 15:01:05.045885	f	\N
2	4202	3	182	\N	3	f	\N	2012-12-01 23:57:16.386208	t	2012-12-06 15:01:56.640807
2	5211	134	150	\N	3	f	\N	2012-12-07 10:45:07.201961	t	2012-12-08 09:29:33.443779
2	4983	3	101	\N	3	f	\N	2012-12-06 14:53:01.634951	t	2012-12-06 15:06:40.004141
2	3651	3	102	\N	3	f	\N	2012-11-23 22:00:06.762111	t	2012-12-06 15:07:39.774965
2	4989	1	84	\N	3	f	\N	2012-12-06 15:08:02.687303	f	\N
2	1134	3	101	\N	3	f	\N	2012-12-06 15:11:14.536343	t	2012-12-06 15:15:37.473811
2	1381	3	101	\N	3	f	\N	2012-11-28 09:12:06.691374	t	2012-12-06 15:15:46.624171
2	3727	3	101	\N	3	f	\N	2012-11-27 00:47:32.51417	t	2012-12-06 15:16:27.938069
2	4990	1	101	\N	3	f	\N	2012-12-06 15:16:32.095424	f	\N
2	3694	3	101	\N	3	f	\N	2012-11-26 22:52:45.168683	t	2012-12-06 15:17:11.148753
2	4741	3	101	\N	3	f	\N	2012-12-05 21:59:45.030317	t	2012-12-06 15:17:39.534993
2	1010	3	101	\N	3	f	\N	2012-12-06 02:25:31.322466	t	2012-12-06 15:18:17.684955
2	1002	3	125	\N	3	f	\N	2012-11-26 23:25:48.990988	t	2012-12-06 15:19:03.916447
2	4992	1	101	\N	3	f	\N	2012-12-06 15:19:27.900853	f	\N
2	4991	3	182	\N	3	f	\N	2012-12-06 15:17:45.580703	t	2012-12-06 15:20:49.084786
2	4993	22	101	\N	3	f	\N	2012-12-06 15:29:36.702627	t	2012-12-06 15:29:48.000374
2	4709	74	101	\N	3	f	\N	2012-12-05 20:14:27.727557	t	2012-12-06 15:32:23.829012
2	4713	74	101	\N	3	f	\N	2012-12-05 20:21:52.917851	t	2012-12-06 15:33:22.02435
2	1009	3	101	\N	3	f	\N	2012-12-06 15:31:52.489876	t	2012-12-06 15:34:52.557271
2	4995	3	101	\N	3	f	\N	2012-12-06 15:48:43.281234	f	\N
2	5012	134	150	\N	3	f	\N	2012-12-06 16:27:30.035365	t	2012-12-08 09:29:56.538207
2	4331	205	125	\N	3	f	\N	2012-12-04 01:14:08.58196	t	2012-12-06 15:50:34.029779
2	4342	3	182	\N	3	f	\N	2012-12-04 09:19:08.662986	t	2012-12-06 15:53:24.978802
2	585	3	101	\N	3	f	\N	2012-12-02 17:18:11.875372	t	2012-12-06 15:57:21.242404
2	4996	3	101	\N	3	f	\N	2012-12-06 15:59:39.873093	f	\N
2	4998	21	101	\N	3	f	\N	2012-12-06 16:09:28.983483	t	2012-12-06 16:09:44.668796
2	4999	1	101	\N	3	f	\N	2012-12-06 16:11:12.181346	f	\N
2	5362	134	150	\N	3	f	\N	2012-12-08 09:41:43.120365	t	2012-12-08 09:41:57.413861
2	5192	1	122	\N	3	f	\N	2012-12-07 10:27:57.826552	t	2012-12-08 10:00:36.328509
2	5258	1	122	\N	3	f	\N	2012-12-07 12:40:23.036092	t	2012-12-08 10:02:21.977161
2	5242	1	122	\N	3	f	\N	2012-12-07 11:05:46.366946	t	2012-12-08 10:05:07.002257
2	4345	205	182	\N	3	f	\N	2012-12-04 10:36:26.978657	t	2012-12-06 16:22:32.102739
2	5385	191	182	\N	3	f	\N	2012-12-08 10:19:18.523301	t	2012-12-08 10:19:40.16073
2	5006	205	182	\N	3	f	\N	2012-12-06 16:23:47.567553	t	2012-12-06 16:23:58.174758
2	5008	205	101	\N	3	f	\N	2012-12-06 16:24:08.754704	f	\N
2	5009	205	182	\N	3	f	\N	2012-12-06 16:25:38.358958	t	2012-12-06 16:25:52.008677
2	5010	71	182	\N	3	f	\N	2012-12-06 16:26:32.121612	t	2012-12-06 16:26:45.340542
2	5013	205	182	\N	3	f	\N	2012-12-06 16:27:34.820881	t	2012-12-06 16:27:45.227822
2	5017	205	182	\N	3	f	\N	2012-12-06 16:29:07.130578	t	2012-12-06 16:29:17.52399
2	5018	205	182	\N	3	f	\N	2012-12-06 16:29:19.166433	t	2012-12-06 16:29:32.268986
2	5395	1	1	\N	3	f	\N	2012-12-08 10:27:33.230576	t	2012-12-08 10:27:56.714926
2	5020	205	182	\N	3	f	\N	2012-12-06 16:30:54.650502	t	2012-12-06 16:31:04.091766
2	5021	205	182	\N	3	f	\N	2012-12-06 16:36:43.975799	t	2012-12-06 16:36:59.303639
2	5022	205	101	\N	3	f	\N	2012-12-06 16:43:37.847221	t	2012-12-06 16:43:48.830953
2	5023	1	101	\N	3	f	\N	2012-12-06 16:45:57.726415	t	2012-12-06 16:46:08.835723
2	5024	205	84	\N	3	f	\N	2012-12-06 16:49:42.271828	f	\N
2	5025	205	84	\N	3	f	\N	2012-12-06 16:51:21.985715	f	\N
2	4780	62	101	\N	3	f	\N	2012-12-06 07:53:06.367018	t	2012-12-06 16:51:47.241081
2	5026	1	101	\N	3	f	\N	2012-12-06 16:52:06.549351	f	\N
2	4766	72	101	\N	3	f	\N	2012-12-06 00:09:10.5271	t	2012-12-06 16:52:20.092518
2	5028	1	101	\N	3	f	\N	2012-12-06 16:54:57.398274	f	\N
2	5029	21	101	\N	3	f	\N	2012-12-06 16:56:55.707512	t	2012-12-06 16:57:10.391036
2	5031	22	101	\N	3	f	\N	2012-12-06 17:00:53.390687	t	2012-12-06 17:01:07.605483
2	5147	1	102	\N	3	f	\N	2012-12-07 00:00:38.343874	f	\N
2	4984	205	84	\N	3	f	\N	2012-12-06 14:54:46.22449	t	2012-12-07 09:03:10.768669
2	4976	1	84	\N	3	f	\N	2012-12-06 14:45:33.212868	t	2012-12-07 09:08:33.690679
2	5176	1	182	\N	3	f	\N	2012-12-07 09:25:52.620734	f	\N
2	5405	191	182	\N	3	f	\N	2012-12-08 10:31:29.408793	t	2012-12-08 10:31:55.436823
2	5186	205	101	\N	3	f	\N	2012-12-07 09:53:10.006558	t	2012-12-07 09:53:31.582665
2	5202	134	150	\N	3	f	\N	2012-12-07 10:37:25.059535	f	\N
2	5224	3	182	\N	3	f	\N	2012-12-07 10:50:36.929869	t	2012-12-07 10:50:45.960446
2	3989	111	159	\N	3	f	\N	2012-11-29 19:50:51.132856	t	2012-12-07 10:58:40.772444
2	3976	111	159	\N	3	f	\N	2012-11-29 18:57:18.924105	t	2012-12-07 11:00:18.965961
2	3966	111	159	\N	3	f	\N	2012-11-29 18:51:42.6916	t	2012-12-07 11:02:53.800417
2	5131	205	101	\N	3	f	\N	2012-12-06 21:33:58.676721	t	2012-12-07 11:17:25.509827
2	5245	1	125	\N	3	f	\N	2012-12-07 11:19:30.435236	t	2012-12-07 11:19:39.397409
2	5254	205	182	\N	3	f	\N	2012-12-07 11:58:20.748427	t	2012-12-07 11:58:33.048863
2	5011	142	152	\N	3	f	\N	2012-12-06 16:27:07.977676	t	2012-12-08 10:35:18.365236
2	4403	142	152	\N	3	f	\N	2012-12-04 16:14:32.467246	t	2012-12-08 10:39:06.842828
2	4106	142	152	\N	3	f	\N	2012-11-30 15:12:00.948697	t	2012-12-08 10:41:40.465384
2	5410	22	101	\N	3	f	\N	2012-12-08 10:45:27.709583	t	2012-12-08 10:45:40.95952
2	5135	205	182	\N	3	f	\N	2012-12-06 21:41:05.803994	t	2012-12-08 10:49:47.685813
2	940	62	101	\N	3	f	\N	2012-11-22 19:29:43.042743	t	2012-12-06 17:02:50.873764
2	5032	22	101	\N	3	f	\N	2012-12-06 17:02:49.510838	t	2012-12-06 17:03:01.158962
2	5034	1	101	\N	3	f	\N	2012-12-06 17:05:44.422428	t	2012-12-06 17:06:02.481524
2	5043	134	150	\N	3	f	\N	2012-12-06 17:31:17.49497	t	2012-12-08 09:30:55.444075
2	5037	194	182	\N	3	f	\N	2012-12-06 17:13:12.871515	f	\N
2	5038	1	182	\N	3	f	\N	2012-12-06 17:24:41.346178	f	\N
2	5039	1	182	\N	3	f	\N	2012-12-06 17:26:12.214706	f	\N
2	5040	134	150	\N	3	f	\N	2012-12-06 17:27:02.512504	f	\N
2	5041	134	150	\N	3	f	\N	2012-12-06 17:28:39.456109	f	\N
2	5042	134	150	\N	3	f	\N	2012-12-06 17:29:53.422815	f	\N
2	5044	134	150	\N	3	f	\N	2012-12-06 17:33:59.547256	f	\N
2	5046	3	101	\N	3	f	\N	2012-12-06 17:39:35.027082	f	\N
2	5048	205	101	\N	3	f	\N	2012-12-06 17:44:54.460923	f	\N
2	5049	3	182	\N	3	f	\N	2012-12-06 18:04:03.624368	f	\N
2	671	3	101	\N	3	f	\N	2012-11-23 18:12:32.271254	t	2012-12-06 18:05:28.195755
2	3612	58	174	\N	3	f	\N	2012-11-22 17:51:18.060527	t	2012-12-06 18:20:45.695928
2	4693	3	101	\N	3	f	\N	2012-12-05 19:51:37.896795	t	2012-12-06 18:29:31.482532
2	3724	3	101	\N	3	f	\N	2012-11-27 00:27:18.840159	t	2012-12-06 18:29:53.003562
2	4847	205	182	\N	3	f	\N	2012-12-06 09:56:58.400937	t	2012-12-06 18:55:18.333737
2	4724	62	101	\N	3	f	\N	2012-12-05 21:19:33.870198	t	2012-12-06 18:56:04.738488
2	5051	1	101	\N	3	f	\N	2012-12-06 18:56:34.391484	t	2012-12-06 18:57:33.576609
2	4615	205	101	\N	3	f	\N	2012-12-05 15:37:54.388574	t	2012-12-06 18:57:56.545603
2	5052	3	101	\N	3	f	\N	2012-12-06 19:10:24.109163	f	\N
2	3988	134	101	\N	3	f	\N	2012-11-29 19:49:28.159699	t	2012-12-06 19:14:20.327665
2	5054	205	101	\N	3	f	\N	2012-12-06 19:15:56.179856	f	\N
2	5055	205	101	\N	3	f	\N	2012-12-06 19:17:36.048506	f	\N
2	5056	1	125	\N	3	f	\N	2012-12-06 19:21:08.056025	f	\N
2	5057	1	125	\N	3	f	\N	2012-12-06 19:22:13.924507	f	\N
2	5058	1	101	\N	3	f	\N	2012-12-06 19:24:51.787331	t	2012-12-06 19:26:27.329807
2	5059	1	101	\N	3	f	\N	2012-12-06 19:32:20.71124	t	2012-12-06 19:32:29.630829
2	5062	205	122	\N	3	f	\N	2012-12-06 19:38:33.432136	f	\N
2	5064	41	182	\N	3	f	\N	2012-12-06 19:39:40.426168	f	\N
2	5065	205	122	\N	3	f	\N	2012-12-06 19:43:50.534135	f	\N
2	5067	205	122	\N	3	f	\N	2012-12-06 19:45:28.19774	f	\N
2	5070	3	182	\N	3	f	\N	2012-12-06 19:49:44.868482	f	\N
2	4739	1	182	\N	3	f	\N	2012-12-05 21:47:16.688847	t	2012-12-06 19:50:03.451809
2	5071	111	159	\N	3	f	\N	2012-12-06 19:50:16.503266	f	\N
2	5073	205	182	\N	3	f	\N	2012-12-06 19:53:12.895976	f	\N
2	4941	3	101	\N	3	f	\N	2012-12-06 13:32:01.42736	t	2012-12-06 19:53:19.027408
2	4936	75	101	\N	3	f	\N	2012-12-06 13:14:27.412106	t	2012-12-06 19:53:29.860885
2	4994	62	101	\N	3	f	\N	2012-12-06 15:41:16.32439	t	2012-12-06 19:54:35.949154
2	5079	1	101	\N	3	f	\N	2012-12-06 19:56:09.488742	t	2012-12-06 19:56:27.736589
2	5081	205	122	\N	3	f	\N	2012-12-06 20:01:20.70224	f	\N
2	5082	205	84	\N	3	f	\N	2012-12-06 20:05:46.118668	f	\N
2	5084	1	182	\N	3	f	\N	2012-12-06 20:05:57.195459	f	\N
2	5105	67	101	\N	3	f	\N	2012-12-06 20:11:27.985909	f	\N
2	5106	205	182	\N	3	f	\N	2012-12-06 20:11:31.511228	f	\N
2	5107	1	182	\N	3	f	\N	2012-12-06 20:11:35.040965	f	\N
2	5110	1	182	\N	3	f	\N	2012-12-06 20:12:38.67032	f	\N
2	5045	134	150	\N	3	f	\N	2012-12-06 17:35:01.91042	t	2012-12-08 09:42:15.006797
2	5177	1	101	\N	3	f	\N	2012-12-07 09:29:56.620022	f	\N
2	5069	205	122	\N	3	f	\N	2012-12-06 19:49:21.840799	t	2012-12-07 09:30:23.591871
2	4249	67	101	\N	3	f	\N	2012-12-03 11:46:04.125094	t	2012-12-07 09:55:01.534087
2	3891	81	102	\N	3	f	\N	2012-11-29 09:39:59.680392	t	2012-12-07 10:30:20.388514
2	5203	134	150	\N	3	f	\N	2012-12-07 10:39:14.070159	f	\N
2	5214	1	122	\N	3	f	\N	2012-12-07 10:46:44.044229	f	\N
2	5225	205	122	\N	3	f	\N	2012-12-07 10:51:32.071235	f	\N
2	3968	111	159	\N	3	f	\N	2012-11-29 18:53:23.299634	t	2012-12-07 10:58:47.68472
2	3972	111	159	\N	3	f	\N	2012-11-29 18:55:56.90714	t	2012-12-07 11:00:47.262538
2	4039	111	159	\N	3	f	\N	2012-11-30 02:08:39.523742	t	2012-12-07 11:03:13.497025
2	4095	111	159	\N	3	f	\N	2012-11-30 13:49:41.654164	t	2012-12-07 11:05:49.738028
2	5246	104	125	\N	3	f	\N	2012-12-07 11:21:29.575386	t	2012-12-07 11:21:44.697583
2	564	3	182	\N	3	f	\N	2012-12-07 11:59:57.535026	f	\N
2	5269	104	101	\N	3	f	\N	2012-12-07 14:00:40.973472	f	\N
2	5273	205	182	\N	3	f	\N	2012-12-07 14:04:59.201539	t	2012-12-07 14:05:11.579642
2	5277	205	182	\N	3	f	\N	2012-12-07 14:06:35.671914	t	2012-12-07 14:06:42.208618
2	5281	205	182	\N	3	f	\N	2012-12-07 14:08:49.466455	t	2012-12-07 14:09:18.758416
2	5284	205	182	\N	3	f	\N	2012-12-07 14:09:46.396426	t	2012-12-07 14:09:58.408488
2	5287	205	182	\N	3	f	\N	2012-12-07 14:11:38.797889	t	2012-12-07 14:12:03.23725
2	4730	67	101	\N	3	f	\N	2012-12-05 21:35:52.428615	t	2012-12-07 14:12:24.004968
2	3610	3	101	\N	3	f	\N	2012-11-21 17:57:50.364267	t	2012-12-07 14:14:09.417332
2	5294	3	101	\N	3	f	\N	2012-12-07 14:29:35.610985	t	2012-12-07 14:30:10.863601
2	4733	67	101	\N	3	f	\N	2012-12-05 21:37:52.835892	t	2012-12-07 14:35:01.450456
2	5019	67	101	\N	3	f	\N	2012-12-06 16:29:41.787394	t	2012-12-07 14:36:09.738855
2	5148	1	102	\N	3	f	\N	2012-12-07 00:08:27.16657	t	2012-12-07 14:37:12.258153
2	4934	61	102	\N	3	f	\N	2012-12-06 13:01:04.80467	t	2012-12-07 14:37:39.317657
2	5016	205	101	\N	3	f	\N	2012-12-06 16:28:47.812328	t	2012-12-07 14:42:44.012907
2	2189	1	101	\N	3	f	\N	2012-12-07 12:34:25.281269	t	2012-12-07 14:51:26.160787
2	3801	3	182	\N	3	f	\N	2012-11-27 22:37:15.886823	t	2012-12-07 14:54:45.194233
2	5363	1	1	\N	3	f	\N	2012-12-08 09:45:30.396489	t	2012-12-08 09:49:38.769483
2	5063	205	122	\N	3	f	\N	2012-12-06 19:39:21.742525	t	2012-12-08 09:57:05.485054
2	5060	205	122	\N	3	f	\N	2012-12-06 19:37:01.75313	t	2012-12-08 09:58:22.11403
2	5072	205	122	\N	3	f	\N	2012-12-06 19:51:52.015093	t	2012-12-08 09:58:40.10926
2	5066	205	122	\N	3	f	\N	2012-12-06 19:44:40.97517	t	2012-12-08 09:58:52.497648
2	5074	205	122	\N	3	f	\N	2012-12-06 19:53:50.280422	t	2012-12-08 09:59:56.045153
2	5075	205	122	\N	3	f	\N	2012-12-06 19:54:01.005336	t	2012-12-08 10:03:40.679315
2	4646	76	101	\N	3	f	\N	2012-12-05 17:12:38.131481	t	2012-12-07 14:57:41.018317
2	5004	205	101	\N	3	f	\N	2012-12-06 16:17:23.172434	t	2012-12-07 14:58:30.211085
2	5003	205	101	\N	3	f	\N	2012-12-06 16:17:16.667281	t	2012-12-07 14:58:36.891208
2	5005	67	101	\N	3	f	\N	2012-12-06 16:20:40.513981	t	2012-12-07 14:59:13.872823
2	5007	1	101	\N	3	f	\N	2012-12-06 16:23:55.376102	t	2012-12-07 14:59:14.303705
2	5027	67	101	\N	3	f	\N	2012-12-06 16:54:39.118809	t	2012-12-07 14:59:54.927278
2	3699	21	101	\N	3	f	\N	2012-11-26 23:07:17.064765	t	2012-12-07 15:00:18.149968
2	4755	67	101	\N	3	f	\N	2012-12-05 22:50:58.565055	t	2012-12-07 15:02:14.024055
2	4327	3	101	\N	3	f	\N	2012-12-03 22:20:30.95625	t	2012-12-07 15:05:18.69352
2	3759	75	101	\N	3	f	\N	2012-11-27 18:27:16.248805	t	2012-12-07 15:05:51.735589
2	5035	205	101	\N	3	f	\N	2012-12-06 17:06:25.523239	t	2012-12-07 15:12:33.374727
2	1910	1	101	\N	3	f	\N	2012-12-07 15:28:00.786574	t	2012-12-07 15:29:15.884783
2	4623	191	182	\N	3	f	\N	2012-12-05 15:58:22.121581	t	2012-12-07 15:29:34.233774
2	5111	191	182	\N	3	f	\N	2012-12-06 20:14:49.220038	t	2012-12-07 15:29:44.93046
2	4619	191	182	\N	3	f	\N	2012-12-05 15:56:31.368576	t	2012-12-07 15:30:06.964856
2	5305	1	125	\N	3	f	\N	2012-12-07 15:30:35.391621	f	\N
2	4997	1	182	\N	3	f	\N	2012-12-06 16:08:43.669586	t	2012-12-07 15:30:43.650638
2	4642	191	182	\N	3	f	\N	2012-12-05 17:00:25.418434	t	2012-12-07 15:31:20.535487
2	4620	191	182	\N	3	f	\N	2012-12-05 15:56:35.772542	t	2012-12-07 15:31:22.278277
2	3709	201	182	\N	3	f	\N	2012-11-26 23:24:48.443422	t	2012-12-07 15:31:32.538213
2	4626	191	1	\N	3	f	\N	2012-12-05 16:10:40.365083	t	2012-12-07 15:31:44.69043
2	3852	201	182	\N	3	f	\N	2012-11-28 20:58:04.012	t	2012-12-07 15:32:10.018663
2	3658	201	182	\N	3	f	\N	2012-11-24 01:48:15.732215	t	2012-12-07 15:32:12.420719
2	5036	191	182	\N	3	f	\N	2012-12-06 17:07:03.156907	t	2012-12-07 15:32:16.481078
2	2351	1	84	\N	3	f	\N	2012-12-05 15:56:52.056596	t	2012-12-07 15:32:44.330891
2	902	1	182	\N	3	f	\N	2012-12-04 11:01:02.358881	t	2012-12-07 15:32:46.469273
2	3661	201	182	\N	3	f	\N	2012-11-24 11:05:38.529003	t	2012-12-07 15:32:48.616347
2	2596	1	101	\N	3	f	\N	2012-12-04 11:28:10.011843	t	2012-12-07 15:34:07.997162
2	5306	48	182	\N	3	f	\N	2012-12-07 15:34:47.40244	t	2012-12-07 15:34:58.338638
2	3626	22	101	\N	3	f	\N	2012-11-22 19:20:21.588308	t	2012-12-07 15:49:57.658824
2	5307	1	101	\N	3	f	\N	2012-12-07 15:54:44.658689	t	2012-12-07 15:54:57.131996
2	5308	1	101	\N	3	f	\N	2012-12-07 15:56:59.725144	t	2012-12-07 15:57:11.97124
2	4702	74	101	\N	3	f	\N	2012-12-05 20:04:53.370498	t	2012-12-07 16:02:45.876182
2	341	3	182	\N	3	f	\N	2012-11-24 20:40:19.286485	t	2012-12-07 16:03:39.502243
2	5314	134	150	\N	3	f	\N	2012-12-07 16:45:36.508866	f	\N
2	5161	186	182	\N	3	f	\N	2012-12-07 01:28:01.65093	t	2012-12-07 16:45:48.042039
2	5315	1	182	\N	3	f	\N	2012-12-07 16:46:00.188466	t	2012-12-07 16:46:12.091167
2	5318	1	182	\N	3	f	\N	2012-12-07 16:47:39.15856	f	\N
2	5316	205	182	\N	3	f	\N	2012-12-07 16:47:04.290929	t	2012-12-07 16:48:12.745567
2	4673	1	182	\N	3	f	\N	2012-12-05 18:45:47.435504	t	2012-12-07 16:49:11.60869
2	4701	74	101	\N	3	f	\N	2012-12-05 20:03:36.455094	t	2012-12-07 17:04:54.215691
2	2647	1	101	\N	3	f	\N	2012-12-07 17:11:02.65676	t	2012-12-07 17:11:49.050066
2	304	3	101	\N	3	f	\N	2012-12-05 14:32:01.607868	f	\N
2	5320	136	101	\N	3	f	\N	2012-12-07 17:13:05.980739	f	\N
2	3733	41	182	\N	3	f	\N	2012-11-27 08:06:06.875672	t	2012-12-07 17:13:59.195549
2	5311	205	125	\N	3	f	\N	2012-12-07 16:13:44.526068	t	2012-12-07 16:14:01.893921
2	5324	205	182	\N	3	f	\N	2012-12-07 17:30:27.212431	t	2012-12-07 17:30:43.282801
2	5325	205	182	\N	3	f	\N	2012-12-07 17:33:12.034311	t	2012-12-07 17:33:24.418024
2	5326	205	182	\N	3	f	\N	2012-12-07 17:34:22.184633	f	\N
2	5327	205	101	\N	3	f	\N	2012-12-07 17:37:11.351863	f	\N
2	3763	1	101	\N	3	f	\N	2012-11-27 18:40:08.80488	t	2012-12-07 17:37:48.567605
2	5328	1	101	\N	3	f	\N	2012-12-07 17:47:22.516349	t	2012-12-07 17:49:16.436533
2	5334	104	101	\N	3	f	\N	2012-12-07 19:04:13.592071	f	\N
2	5335	21	101	\N	3	f	\N	2012-12-07 19:36:03.779381	f	\N
2	5336	3	101	\N	3	f	\N	2012-12-07 19:45:31.702345	f	\N
2	5347	1	182	\N	3	f	\N	2012-12-07 21:49:09.273727	f	\N
2	5313	134	150	\N	3	f	\N	2012-12-07 16:44:07.248975	t	2012-12-08 09:39:50.179977
2	5364	1	64	\N	3	f	\N	2012-12-08 09:46:08.715435	t	2012-12-08 09:46:18.893504
2	5309	21	101	\N	3	f	\N	2012-12-07 16:03:17.257195	t	2012-12-08 09:53:37.245315
2	5210	205	122	\N	3	f	\N	2012-12-07 10:43:29.553641	t	2012-12-08 10:04:22.957729
2	5304	205	122	\N	3	f	\N	2012-12-07 15:17:29.841184	t	2012-12-08 10:04:54.69442
2	5310	21	101	\N	3	f	\N	2012-12-07 16:06:40.91718	t	2012-12-08 10:17:57.238127
2	5386	191	182	\N	3	f	\N	2012-12-08 10:21:00.666805	t	2012-12-08 10:21:10.484291
2	5396	205	182	\N	3	f	\N	2012-12-08 10:27:50.369648	t	2012-12-08 10:30:04.393327
2	5406	205	182	\N	3	f	\N	2012-12-08 10:31:50.363735	t	2012-12-08 10:32:35.249657
2	5329	142	152	\N	3	f	\N	2012-12-07 18:17:14.38304	t	2012-12-08 10:36:22.854385
2	4111	142	152	\N	3	f	\N	2012-11-30 15:36:06.361216	t	2012-12-08 10:39:14.715478
2	4105	142	152	\N	3	f	\N	2012-11-30 15:05:40.923603	t	2012-12-08 10:42:03.651398
2	5409	1	101	\N	3	f	\N	2012-12-08 10:45:18.761614	t	2012-12-08 10:45:29.531226
2	4478	205	182	\N	3	f	\N	2012-12-05 10:13:21.866553	t	2012-12-08 10:49:48.147138
2	5141	205	182	\N	3	f	\N	2012-12-06 22:33:21.210747	t	2012-12-08 10:50:42.869261
2	5345	205	182	\N	3	f	\N	2012-12-07 21:45:20.233937	t	2012-12-08 10:51:18.569868
2	5134	205	182	\N	3	f	\N	2012-12-06 21:37:38.481262	t	2012-12-08 10:52:02.212985
2	5339	1	182	\N	3	f	\N	2012-12-07 21:42:37.515725	t	2012-12-08 10:52:14.02092
2	614	3	101	\N	3	f	\N	2012-12-05 11:15:26.5787	t	2012-12-08 10:55:12.5125
2	5412	1	1	\N	3	f	\N	2012-12-08 10:59:23.084907	t	2012-12-08 10:59:36.244803
2	5413	205	182	\N	3	f	\N	2012-12-08 11:01:18.738205	t	2012-12-08 11:01:42.501239
2	5415	205	182	\N	3	f	\N	2012-12-08 11:03:17.923537	t	2012-12-08 11:03:30.629924
2	1828	1	182	\N	3	f	\N	2012-12-06 15:31:29.328664	t	2012-12-08 11:09:08.183178
2	1152	3	101	\N	3	f	\N	2012-11-22 18:43:52.641991	t	2012-12-08 11:10:54.239875
2	5417	1	182	\N	3	f	\N	2012-12-08 11:11:34.165471	t	2012-12-08 11:11:47.538722
2	3667	1	182	\N	3	f	\N	2012-11-25 01:34:24.405392	t	2012-12-08 11:19:54.23703
2	5418	3	101	\N	3	f	\N	2012-12-08 11:39:08.979132	t	2012-12-08 11:39:19.667714
2	5419	3	101	\N	3	f	\N	2012-12-08 11:46:32.678398	t	2012-12-08 11:47:14.514163
2	5421	3	182	\N	3	f	\N	2012-12-08 11:48:58.432687	f	\N
2	5422	3	101	\N	3	f	\N	2012-12-08 11:49:22.530597	t	2012-12-08 11:49:41.477303
2	5423	3	101	\N	3	f	\N	2012-12-08 11:50:39.521349	t	2012-12-08 11:51:09.949421
2	5424	3	101	\N	3	f	\N	2012-12-08 12:06:33.138725	t	2012-12-08 12:06:46.720495
2	5425	1	101	\N	3	f	\N	2012-12-08 12:31:59.219241	t	2012-12-08 12:32:22.519905
2	3885	3	101	\N	3	f	\N	2012-11-29 00:24:15.555335	t	2012-12-08 12:56:21.461521
2	5263	77	101	\N	3	f	\N	2012-12-07 13:24:16.809923	t	2012-12-08 13:43:02.596922
2	3650	201	182	\N	3	f	\N	2012-11-23 21:56:21.294254	t	2012-12-08 13:55:12.554533
2	5432	205	101	\N	3	f	\N	2012-12-08 14:03:17.986662	t	2012-12-08 14:03:28.300587
2	5433	3	101	\N	3	f	\N	2012-12-08 14:03:50.439546	f	\N
2	4348	205	182	\N	3	f	\N	2012-12-04 11:07:54.933519	t	2012-12-08 14:06:07.173083
2	3752	205	182	\N	3	f	\N	2012-11-27 16:40:44.088638	t	2012-12-08 14:11:22.137236
2	5434	1	101	\N	3	f	\N	2012-12-08 14:13:38.015935	t	2012-12-08 14:13:49.213128
2	5435	3	101	\N	3	f	\N	2012-12-08 14:14:23.166432	t	2012-12-08 14:14:56.784728
2	5436	1	101	\N	3	f	\N	2012-12-08 14:29:01.516063	t	2012-12-08 14:29:34.753567
2	5437	1	182	\N	3	f	\N	2012-12-08 14:34:17.234515	t	2012-12-08 14:34:49.804972
2	5438	1	64	\N	3	f	\N	2012-12-08 14:36:28.062255	t	2012-12-08 14:36:40.459403
2	425	3	101	\N	3	f	\N	2012-11-22 18:47:31.828777	t	2012-12-08 14:51:59.580083
2	5439	1	101	\N	3	f	\N	2012-12-08 14:53:50.559639	t	2012-12-08 14:54:00.947201
2	4193	21	101	\N	3	f	\N	2012-12-01 19:40:54.479795	t	2012-12-08 14:55:09.623629
2	5323	205	182	\N	3	f	\N	2012-12-07 17:24:52.628188	t	2012-12-08 14:58:03.993027
2	2616	1	101	\N	3	f	\N	2012-12-07 00:36:21.068861	t	2012-12-08 15:02:20.267199
2	5441	205	101	\N	3	f	\N	2012-12-08 15:04:50.443072	t	2012-12-08 15:04:58.119714
2	5440	72	101	\N	3	f	\N	2012-12-08 15:03:12.968508	t	2012-12-08 15:05:43.368509
2	5259	205	101	\N	3	f	\N	2012-12-07 12:40:41.592811	t	2012-12-08 15:09:00.407517
2	5431	101	125	\N	3	f	\N	2012-12-08 13:47:23.80616	t	2012-12-08 15:09:34.433513
2	1089	1	101	\N	3	f	\N	2012-12-08 13:50:14.951782	t	2012-12-08 15:10:49.455276
2	5143	3	101	\N	3	f	\N	2012-12-06 22:54:24.421692	t	2012-12-08 15:14:59.60317
2	5426	3	101	\N	3	f	\N	2012-12-08 12:54:26.614683	t	2012-12-08 15:24:43.775415
2	5350	3	101	\N	3	f	\N	2012-12-07 22:18:50.808596	t	2012-12-08 15:26:21.20748
2	5427	3	101	\N	3	f	\N	2012-12-08 13:02:13.212853	t	2012-12-08 15:27:35.984444
2	5442	1	125	\N	3	f	\N	2012-12-08 15:31:48.577406	t	2012-12-08 15:31:58.750873
2	5050	72	125	\N	3	f	\N	2012-12-06 18:38:15.899249	t	2012-12-08 15:32:35.767559
2	5443	1	182	\N	3	f	\N	2012-12-08 15:49:57.230227	t	2012-12-08 15:50:07.402462
2	5444	1	182	\N	3	f	\N	2012-12-08 15:51:37.143535	t	2012-12-08 15:51:48.37796
2	5445	1	101	\N	3	f	\N	2012-12-08 16:09:00.562696	t	2012-12-08 16:09:11.7965
2	5446	1	101	\N	3	f	\N	2012-12-08 16:13:48.811709	t	2012-12-08 16:13:58.84523
2	4266	1	101	\N	3	f	\N	2012-12-03 12:57:22.596614	t	2012-12-08 16:15:02.027306
2	5447	1	101	\N	3	f	\N	2012-12-08 16:17:07.330082	t	2012-12-08 16:17:14.865581
2	298	1	182	\N	3	f	\N	2012-12-07 14:54:08.976039	t	2012-12-08 17:17:54.480126
2	672	3	101	\N	3	f	\N	2012-11-17 18:15:57.49961	t	2012-12-08 17:18:28.018329
2	5449	21	101	\N	3	f	\N	2012-12-08 21:25:54.211191	f	\N
\.


--
-- Data for Name: estado; Type: TABLE DATA; Schema: public; Owner: -
--

COPY estado (id_estado, nome_estado, codigo_estado) FROM stdin;
1	Cear�	CE
\.


--
-- Name: estado_id_estado_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('estado_id_estado_seq', 1, false);


--
-- Data for Name: evento; Type: TABLE DATA; Schema: public; Owner: -
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
78	Jogos 2D 2 3D usando Java	2	2	f	 Enterder o sistema básico de criação e funcionamento de jogos 2D.\r\nCriar um jogo simples 2D em Java utilizando notepad.\r\nConehecer IDE’s para desenvolvimento de jogos 2D em Java.\r\nDesenvolver um jogo 2D em Java utilizando uma IDE.\r\nApresentar o mercado de jogos 2D e 3D, em desktop, online e na web, ferramentas mais utilizadas, cursos, livros etc.	3651	\N	2012-11-26 21:04:18.105251	 Enterder o sistema básico de criação e funcionamento de jogos 2D.\r\nCriar um jogo simples 2D em Java utilizando notepad.\r\nConehecer IDE’s para desenvolvimento de jogos 2D em Java.\r\nDesenvolver um jogo 2D em Java utilizando uma IDE.\r\nApresentar o mercado de jogos 2D e 3D, em desktop, online e na web, ferramentas mais utilizadas, cursos, livros etc.	1	 Enterder o sistema básico de criação e funcionamento de jogos 2D.\r\nCriar um jogo simples 2D em Java utilizando notepad.\r\nConehecer IDE’s para desenvolvimento de jogos 2D em Java.\r\nDesenvolver um jogo 2D em Java utilizando uma IDE.\r\nApresentar o mercado de jogos 2D e 3D, em desktop, online e na web, ferramentas mais utilizadas, cursos, livros etc.	\N
79	O que a Bíblia fala sobre a informática	1	2	f	O que a Bíblia fala sobre a informática? Usando novos conceitos para ensinar	3651	\N	2012-11-26 21:08:45.477832	O que a Bíblia fala sobre a informática? Usando novos conceitos para ensinar	1	O que a Bíblia fala sobre a informática? Usando novos conceitos para ensinar	\N
80	Introdução básica ao desenvolvimento de aplicações para Android	2	2	f	Introdução básica ao desenvolvimento de aplicações para Android	3651	\N	2012-11-26 21:10:43.797556	Introdução básica ao desenvolvimento de aplicações para Android	1	Introdução básica ao desenvolvimento de aplicações para Android	\N
82	minicurso	2	2	f	tecnica logica de progamaçao	4195	\N	2012-01-12 00:00:00	tecnica em informatica	1	parda, cabelo claros,	\N
83	Introdução básica ao desenvolvimento de aplicações para Android	2	2	f	Nível básico com interesse em entender essa área e cursando E-Jovem Modulo II	4461	\N	2012-12-05 09:38:46.016392	Curso E-Jovem Modulo II	1	Nível básico com interesse em entender essa área	\N
81	COMSOLiD 5	2	2	f	Em busca de aprendizado.	5361	\N	2012-01-12 00:00:00	Curso de programação em CNC;\r\nCurso em eletrônica analogica básica;\r\nCurso Circuits and Electronics - 6.002x MITx;\r\nCurso CS101 pelo Coursera;	2	Estudante de Engenharia Mecatrônica pelo IFCE - campus Fortaleza.	\N
84	Hackerativismo  tecnologia para um mundo mais justo  Sala Lua	1	2	f	00000000000000	4794	\N	2012-06-12 00:00:00	00000000000000	1	000000000000000	\N
85	Introdução básica ao desenvolvimento de aplicações para Android Oficina  Laboratório PHP	1	2	f	000000000000000000000000000	4794	\N	2012-12-06 08:49:10.330823	00000000000000000000000000000	1	000000000000000000000000000	\N
86	Android  Vamos nessa  Sala Java	1	2	f	000000000000000000000000000000	4794	\N	2012-12-06 08:50:58.927033	00000000000000000000000000000000	1	00000000000000000000000000	\N
87	Hackerativismo	1	2	f	gfjhdfiohsdgoisdhgsiorghsdioghasdgiodh	1795	\N	2012-12-06 08:59:12.967812	uiçguiçgniadfhadfh	1	gffjgyudjasghjkçdfasuigfsuigfas	\N
88	comsolid	2	2	f	area da informatica é bem ampla e nesse evento tenho oportunidade de conhecer algumas area desse ramo.	4306	\N	2012-12-06 00:00:00	aluna da eeep adelino cunha alcantara.	1	participar para adquirir novos conhecimentos no ramo de informatica.	\N
\.


--
-- Data for Name: evento_arquivo; Type: TABLE DATA; Schema: public; Owner: -
--

COPY evento_arquivo (id_evento_arquivo, id_evento, nome_arquivo, arquivo, nome_arquivo_md5) FROM stdin;
\.


--
-- Name: evento_arquivo_id_evento_arquivo_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('evento_arquivo_id_evento_arquivo_seq', 1, false);


--
-- Data for Name: evento_demanda; Type: TABLE DATA; Schema: public; Owner: -
--

COPY evento_demanda (evento, id_pessoa, data_solicitacao) FROM stdin;
\.


--
-- Name: evento_id_evento_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('evento_id_evento_seq', 88, true);


--
-- Data for Name: evento_palestrante; Type: TABLE DATA; Schema: public; Owner: -
--

COPY evento_palestrante (id_evento, id_pessoa) FROM stdin;
\.


--
-- Data for Name: evento_participacao; Type: TABLE DATA; Schema: public; Owner: -
--

COPY evento_participacao (evento, id_pessoa) FROM stdin;
\.


--
-- Data for Name: evento_realizacao; Type: TABLE DATA; Schema: public; Owner: -
--

COPY evento_realizacao (evento, id_evento, id_sala, data, hora_inicio, hora_fim, descricao) FROM stdin;
\.


--
-- Name: evento_realizacao_evento_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('evento_realizacao_evento_seq', 13, true);


--
-- Data for Name: evento_realizacao_multipla; Type: TABLE DATA; Schema: public; Owner: -
--

COPY evento_realizacao_multipla (evento_realizacao_multipla, evento, data, hora_inicio, hora_fim) FROM stdin;
\.


--
-- Name: evento_realizacao_multipla_evento_realizacao_multipla_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('evento_realizacao_multipla_evento_realizacao_multipla_seq', 9, true);


--
-- Data for Name: instituicao; Type: TABLE DATA; Schema: public; Owner: -
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
-- Name: instituicao_id_instituicao_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('instituicao_id_instituicao_seq', 205, true);


--
-- Data for Name: mensagem_email; Type: TABLE DATA; Schema: public; Owner: -
--

COPY mensagem_email (id_encontro, id_tipo_mensagem_email, mensagem, assunto, link) FROM stdin;
3	2	<table width="597px" style="font-family: Arial, Helvetica, sans-serif; font-size: 13px; color: #555555; margin: 0;">\n<tr><td><img src="http://comsolid.org/armario/public/imagens/banner_telematica.jpg" /></td></tr>\n<tr><td><img src="http://comsolid.org/images/bg_corpo_sige.png" /></td></tr>\n<tr background="#" width="597px" border="2">\n<td style="float:left;padding-left:20px; width:545px; margin-top: -230px;">                     \n\tOl� <b><nome><b><br><br>\n\tSua nova senha foi gerada com sucesso!<br><br>\n\tSeu login �: <b><email></b><br><br>\n\tSua senha padr�o �: <b><senha></b><br><br>\n\tAtenciosamente,<br><br>\n\tCoordena��o da Telem�tica.<br>\n\tsite:<a href="http://comsolid.org/armario/public/login/login" target="_blank">Clique aqui</a><br>\n\tProf. Robson da Silva Siqueira.<br>\n</td>\n</tr>\n<tr><td><img src="http://comsolid.org/images/rodape-email.jpg" /></td></tr>\n</table>	TELEM�TICA: Recupera��o	http://comsolid.org/armario/public/login/login
1	1	<table width="597px" style="font-family: Arial, Helvetica, sans-serif; font-size: 13px; color: #555555; margin: 0;">\n<tr><td><img src="http://comsolid.org/images/topo-email.jpg" /></td></tr>\n<tr><td><img src="http://comsolid.org/images/bg_corpo_sige.png" /></td></tr>\n<tr background="#" width="597px" border="2">\n<td style="float:left;padding-left:20px; width:545px; margin-top: -230px;">                     \n\tOl� <b><nome><b><br><br>\n\tSeu cadastro foi efetuado com sucesso!<br><br>\n\tSeu login �: <b><email></b><br><br>\n\tSua senha padr�o �: <b><senha></b><br><br>\n\t<a href="<href_link>" target="_blank"><b>Clique aqui</b></a> para ativar seu cadastro.<br><br>\n\tUse seu login e a senha acima.<br><br>\n\tAproveite para atualizar seus dados, verificar a programa��o e indicar os eventos nos quais vai participar.<br><br>\n\tVenha fazer parte desta TRANSFORMA��O.<br><br>\n\tAtenciosamente,<br><br>\n\tCoordena��o da COMSOLiD - Comunidade Maracanauense de Software Livre e Inclus�o Digital<br>\n\tsite:<a href="http://comsolid.org" target="_blank">www.comsolid.org</a><br>\n\temail: comsolid@comsolid.org / ifce.comsolid@gmail.com<br>\n\ttwitter: <a href="http://twitter.com/comsolid/" target="_blank">twitter.com/comsolid/</a><br>\n\tfacebook: <a href="http://www.facebook.com/comsolid/" target="_blank">facebook.com/comsolid/</a><br><br>\n</td>\n</tr>\n<tr><td><img src="http://comsolid.org/images/rodape-email.jpg" /></td></tr>\n</table>	COMSOLiD^4: Cadastro no Evento	http://sige.comsolid.org/login/login
1	2	<table width="597px" style="font-family: Arial, Helvetica, sans-serif; font-size: 13px; color: #555555; margin: 0;">\n<tr><td><img src="http://comsolid.org/images/topo-email.jpg" /></td></tr>\n<tr><td><img src="http://comsolid.org/images/bg_corpo_sige.png" /></td></tr>\n<tr background="#" width="597px" border="2">\n<td style="float:left;padding-left:20px; width:545px; margin-top: -230px;">                     \n\tOl� <b><nome><b><br><br>\n\tSua nova senha foi gerada com sucesso!<br><br>\n\tSeu login �: <b><email></b><br><br>\n\tSua senha padr�o �: <b><senha></b><br><br>\n\tAproveite para atualizar seus dados, verificar a programa��o e indicar os eventos nos quais vai participar.<br><br>\n\tVenha fazer parte desta TRANSFORMA��O.<br><br>\n\tAtenciosamente,<br><br>\n\tCoordena��o da COMSOLiD - Comunidade Maracanauense de Software Livre e Inclus�o Digital<br>\n\tsite:<a href="http://comsolid.org" target="_blank">www.comsolid.org</a><br>\n\temail: comsolid@comsolid.org / ifce.comsolid@gmail.com<br>\n\ttwitter: <a href="http://twitter.com/comsolid/" target="_blank">twitter.com/comsolid/</a><br>\n\tfacebook: <a href="http://www.facebook.com/comsolid/" target="_blank">facebook.com/comsolid/</a><br><br>\n</td>\n</tr>\n<tr><td><img src="http://comsolid.org/images/rodape-email.jpg" /></td></tr>\n</table>	COMSOLiD^4: Recupera��o de Senha	http://sige.comsolid.org/login/login
2	1	<table width="597px" style="font-family: Arial, Helvetica, sans-serif; font-size: 13px; color: #555555; margin: 0;">\n<tr><td><img src="http://comsolid.org/images/topo-email.jpg" /></td></tr>\n<tr><td><img src="http://comsolid.org/images/bg_corpo_sige.png" /></td></tr>\n<tr background="#" width="597px" border="2">\n<td style="float:left;padding-left:20px; width:545px; margin-top: -230px;">                     \n\tOl� <b><nome><b><br><br>\n\tSeu cadastro foi efetuado com sucesso!<br><br>\n\tSeu login �: <b><email></b><br><br>\n\tSua senha padr�o �: <b><senha></b><br><br>\n\t<a href="<href_link>" target="_blank"><b>Clique aqui</b></a> para ativar seu cadastro.<br><br>\n\tUse seu login e a senha acima.<br><br>\n\tAproveite para atualizar seus dados, verificar a programa��o e indicar os eventos nos quais vai participar.<br><br>\n\tVenha fazer parte desta TRANSFORMA��O.<br><br>\n\tAtenciosamente,<br><br>\n\tCoordena��o da COMSOLiD - Comunidade Maracanauense de Software Livre e Inclus�o Digital<br>\n\tsite:<a href="http://comsolid.org" target="_blank">www.comsolid.org</a><br>\n\temail: comsolid@comsolid.org / ifce.comsolid@gmail.com<br>\n\ttwitter: <a href="http://twitter.com/comsolid/" target="_blank">twitter.com/comsolid/</a><br>\n\tfacebook: <a href="http://www.facebook.com/comsolid/" target="_blank">facebook.com/comsolid/</a><br><br>\n</td>\n</tr>\n<tr><td><img src="http://comsolid.org/images/rodape-email.jpg" /></td></tr>\n</table>	COMSOLiD+5: Cadastro no Evento	http://sige.comsolid.org/login/login
2	2	<table width="597px" style="font-family: Arial, Helvetica, sans-serif; font-size: 13px; color: #555555; margin: 0;">\n<tr><td><img src="http://comsolid.org/images/topo-email.jpg" /></td></tr>\n<tr><td><img src="http://comsolid.org/images/bg_corpo_sige.png" /></td></tr>\n<tr background="#" width="597px" border="2">\n<td style="float:left;padding-left:20px; width:545px; margin-top: -230px;">                     \n\tOl� <b><nome><b><br><br>\n\tSua nova senha foi gerada com sucesso!<br><br>\n\tSeu login �: <b><email></b><br><br>\n\tSua senha padr�o �: <b><senha></b><br><br>\n\tAproveite para atualizar seus dados, verificar a programa��o e indicar os eventos nos quais vai participar.<br><br>\n\tVenha fazer parte desta TRANSFORMA��O.<br><br>\n\tAtenciosamente,<br><br>\n\tCoordena��o da COMSOLiD - Comunidade Maracanauense de Software Livre e Inclus�o Digital<br>\n\tsite:<a href="http://comsolid.org" target="_blank">www.comsolid.org</a><br>\n\temail: comsolid@comsolid.org / ifce.comsolid@gmail.com<br>\n\ttwitter: <a href="http://twitter.com/comsolid/" target="_blank">twitter.com/comsolid/</a><br>\n\tfacebook: <a href="http://www.facebook.com/comsolid/" target="_blank">facebook.com/comsolid/</a><br><br>\n</td>\n</tr>\n<tr><td><img src="http://comsolid.org/images/rodape-email.jpg" /></td></tr>\n</table>	COMSOLiD+5: Recupera��o de Senha	http://sige.comsolid.org/login/login
\.


--
-- Data for Name: municipio; Type: TABLE DATA; Schema: public; Owner: -
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
-- Name: municipio_id_municipio_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('municipio_id_municipio_seq', 182, true);


--
-- Data for Name: pessoa; Type: TABLE DATA; Schema: public; Owner: -
--

COPY pessoa (id_pessoa, nome, email, apelido, twitter, endereco_internet, senha, cadastro_validado, data_validacao_cadastro, data_cadastro, id_sexo, nascimento, telefone, administrador, facebook, email_enviado) FROM stdin;
586	Beatriz Machado	bia_princess2106@hotmail.com	Biazinha	@		47840c2db8903f4f14224a5ce4e01e62	t	2011-11-07 09:43:27.0466	2011-11-07 09:29:27.354015	2	1994-01-01	\N	f	bia_princess2106@hotmail.com	t
301	Reyson Barros do Nascimento	reyson_barros@hotmail.com	Reyson	@Reyson1991		85787a7434fad944a39f0b2d72d9f5e3	t	2011-10-13 20:43:24.530758	2011-10-13 20:39:26.992664	1	1991-01-01	\N	f	reyson_barros@hotmail.com	t
635	Alessandra	barbielp@hotmail.com	Alessandra	@lessandra3		f2f786dee2773ba268fa679a371f8619	f	\N	2011-11-08 20:40:15.422504	2	1994-01-01	\N	f	barbielp@hotmail.com	t
356	Renan Brito Almeida	renan_brito_almeida@hotmail.com	RenanTi	@		c60392813f696638c23e456b4dfa0454	f	\N	2011-10-17 17:08:18.159799	1	1991-01-01	\N	f	renan_brito_almeida@hotmail.com	t
816	Thays dos Santos Sales	santosthays1@gmail.com	thaysxiinha	@		c8f3ae235fd8bf96a4d4ee93d82305aa	t	2011-11-16 21:53:28.605411	2011-11-14 20:53:51.719247	2	1993-01-01	\N	f	thaysxiinha@gmail.com	t
598	francisco edson da silva alves	edsonfakewarnnig@gmail.com	edsonzim	@		fac7492b390f3652d3d248cd089cb64a	f	\N	2011-11-07 21:42:55.271328	1	1992-01-01	\N	f		t
1132	WIHARLEY FEITOSA NASCIMENTO	wiharleynascimento@hotmail.com	wiharley	@		051e36c2d5338d6c1d30de9ed1b3c479	t	2012-01-18 15:23:50.143061	2011-11-21 15:04:35.236333	1	1995-01-01	\N	f	wiharleynascimento@hotmail.com	t
782	WILLIANY GOMES NOBRE	williany_gomes@yahoo.com	willyzinha	@		30e2ba164df6abf155378e7edac2bad4	f	\N	2011-11-12 19:34:48.167155	2	1994-01-01	\N	f	williany_gomes@yahoo.com	t
640	YARA BERNARDO CABRAL	yara-bernardo@hotmail.com	Yara C.	@diariofrenetica	http://diariodeumafrenetica.blogspot.com/	b7365147eb467266128babba3773b5fa	t	2012-01-17 11:47:51.881439	2011-11-08 23:09:43.816554	2	1989-01-01	\N	f	yara-bernardo@hotmail.com	t
298	CINCINATO FURTADO	cincinatofurtado@gmail.com	Cincinato	@		be49628d8cb92b2e79ab9e342b28cc50	f	\N	2011-10-13 18:24:41.773394	1	1987-01-01	\N	f		t
1255	Pedro Erico Pinheiro	erico.pep@hotmail.com	Pedro Erico	@		955b2714f15028d0d965030e806c9bea	t	2011-11-22 09:44:07.498156	2011-11-22 09:42:19.989996	1	1993-01-01	\N	f		t
322	Luiz Herik Ferreira Da Silva	herik_flu@hotmail.com	pó de arroz	@		7da81500dd5849abf5e8cdf59185ae45	t	2011-10-14 23:55:41.06192	2011-10-14 23:52:14.496813	1	1992-01-01	\N	f		t
331	Francisco Alessandro Feitoza da Silva	alessandro.feitoza.silva@gmail.com	Alessandro	@		ade6c3af910b888d4975d51cf4f3fc0d	t	2012-11-29 10:59:56.692527	2011-10-15 17:38:27.701254	1	1995-01-01	\N	f	Alessandro.eu@hotmail.com	t
4128	Anna Ketleyn Colares Santos	ketcolares@gmail.com	Ketleyn	@		bd07d1e505a4077e8f8bd0d10869cc7d	f	\N	2012-11-30 20:43:40.640195	2	1996-01-01	\N	f		t
365	Antonia Merelania Silva Pereira	merelaniapereira@gmail.com	Merynha	@		1f91f6be34c21d2afee0d61164d847b8	t	2011-10-17 20:26:24.500958	2011-10-17 20:19:02.350302	2	1992-01-01	\N	f	merynha_sp@hotmail.com	t
4197	Hemerson	hemersonc07@gmail.com	nãotenho	@		047593db20542717823321cb640e2b1d	f	\N	2012-12-01 21:52:46.570912	1	1995-01-01	\N	f	hemersonc07@gmail.com	t
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
343	THIAGO VERAS DE ALMEIDA	thgveras@gmail.com	TVERAS	@thiagoverass		18fc0acdbcd3fb4ef0d4723cf872c744	t	2011-10-17 13:23:57.571238	2011-10-17 13:17:31.701165	1	1990-01-01	\N	f	thgveras@gmail.com	t
362	Enilton Angelim	enilton.angelim@gmail.com	Enilton	@	http://technolivre.blogspot.com/	6c44d9791d5bf6fae60fb54d97df48a0	t	2011-10-17 20:33:10.699166	2011-10-17 20:06:44.659635	1	1989-01-01	\N	f		t
368	francisco janailson ferreira gomes	janailsonferreira@yahoo.com.br	nailson	@		3470e06fb765e9b91a1159904752dba5	t	2011-10-17 20:39:54.140215	2011-10-17 20:21:12.449866	1	1992-01-01	\N	f	janailsonferreira@yahoo.com.br	t
1257	isaias de lima sousa	isaiasdelima1@gmail.com	MegaThrasher	@		b312503b2202e1ad3cc2dba66a3065d9	t	2011-11-22 09:48:36.855544	2011-11-22 09:43:52.91034	1	1993-01-01	\N	f	isaias_Drummer@hotmail.com	t
849	Hitalo Sousa	pivete20112011@hotmail.com	Hitalo pivete	@		c3e43433abe43ac97a3b0f08c0ce1fa7	f	\N	2011-11-15 23:33:27.4418	1	2011-01-01	\N	f	pivete20112011@hotmail.com	t
390	Robson Santiago	robim85@gmail.com	robson	@RobsonSanti		8b015a32ed520400242bac51e9efc22f	t	2011-10-19 15:39:30.838845	2011-10-19 15:34:11.420454	1	2011-01-01	\N	f	robim_85@hotmail.com	t
2618	Roberto Sousa da Silva Junior	betinhox3@hotmail.com	Bigaoo	@		5eeb1a80afe7f4dd882cc0b1cbf8156a	f	\N	2011-11-26 01:54:07.579739	1	1993-01-01	\N	f	bigaoo@hotmail.com	t
371	Matheus Arleson	matheusarleson@gmail.com	Matheus	@		2fdb00bc8031ec909469135ddf7ca412	t	2011-10-17 22:14:06.877917	2011-10-17 22:12:46.746807	1	1991-01-01	\N	f	matheusarleson@gmail.com	t
416	Luciana Gomes de Andrade	luciana.bonek.gomesdeandrade@gmail.com	Luluzinha	@		feb7e34146d4382590e3d07d5eb21877	t	2011-11-11 16:11:37.425146	2011-10-23 19:24:04.158308	2	1994-01-01	\N	f	luciana.bonek.gomesdeandrade@gmail.com	t
420	FRANCISCO ALEXANDRE PEREIRA DE SOUSA	franciscoalexandre92@gmail.com	ALEXANDRE	@		4f7f448ac12af4db01a1cb4f98fe9c31	t	2011-10-23 23:26:52.913765	2011-10-23 23:17:53.521513	1	1992-01-01	\N	f		t
448	JUNIOR MENDES	franciscomendes@bol.com.br	JUNIOR MENDES	@		b0299b6f0d85da51b3169dfbb05b6551	f	\N	2011-10-31 15:21:39.859831	1	1993-01-01	\N	f		t
614	Rimária de Oliveira Castelo Branco	rimaria_100@hotmail.com	Rimária	@		f70ebdec2f8738b1a91d15c50043eb7a	t	2011-11-16 23:52:42.99146	2011-11-07 23:02:49.829515	2	1991-01-01	\N	f	rimaria_100@hotmail.com	t
2619	chagas carvalho teixeira de oliveira junior	junior.ce@live.com	junior	@		97724e4b64b43fac28b7ee1bdb977aee	f	\N	2011-11-26 01:55:41.930267	1	2011-01-01	\N	f	junior.ce@live.com	t
674	YOHANA MARIA SILVA DE ALMEIDA	ravena_xispe@hotmail.com	Ravena	@		30a94be9920bac763d60a4b54ab7b8c6	t	2012-01-10 18:26:31.892498	2011-11-09 21:22:27.145494	2	1995-01-01	\N	f	ravena_xispe@hotmail.com	t
308	Jose Cleudes da Silva	jcleudess@gmail.com	Cleudes	@		e3d3a7ac295b60a71a9044eda4a48e09	t	2011-10-14 15:07:25.16484	2011-10-14 14:55:23.206773	1	1988-01-01	\N	f	cleudes_maximo@hotmail.com	t
314	PEDRO HENRIQUE FEITOZA DA SILVA	FEITOZA.PEDRO@GMAIL.COM	PEDROH	@pedrofeitoza_	https://www.facebook.com/#!/profile.php?id=100002141256624	b49433d7c4ec05e0dfc79bd8bc802909	t	2011-10-14 18:03:23.575703	2011-10-14 17:55:22.630283	1	1988-01-01	\N	f	ph_tuf@hotmail.com	t
320	Anderson dos Santos	anderson.dsf@hotmail.com	Anderson dsf	@	http://www.andersondsf.xpg.com.br	e19d5cd5af0378da05f63f891c7467af	t	2011-10-14 20:59:57.08353	2011-10-14 20:54:37.333334	1	1993-01-01	\N	f	anderson.dsf@hotmail.com	t
332	Rafael Bezerra	rafaelbezerra195@gmail.com	Rafael	@bezerra_rafael		aad7b10f15a8896e4904280d4b8c7d8e	t	2012-01-18 19:33:55.160331	2011-10-16 12:06:59.272359	1	1992-01-01	\N	f		t
309	Marcos Paulo Roque Pio	marcospauloroquepio@gmail.com	Rkpio13	@		fee18b146ed91b416737c2800d334ca3	t	2011-10-14 15:20:13.969642	2011-10-14 15:07:06.470144	1	1982-01-01	\N	f	marcosproquepio@hotmail.com	t
4325	Rafaela da Silva Pereria	rafinhaflor10@hotmail.com	rafinha	@		cd34c96eb120abd1dbe365eee80c3094	f	\N	2012-12-03 22:10:10.694162	2	1994-01-01	\N	f	rafinhaflor10@hotmail.com	t
317	Ana Gabrielly Lustosa	gabylustosa@hotmail.com	Gaby Lustosa	@		4c1f4acf526a745f91658687d9d3ea2f	f	\N	2011-10-14 19:09:37.71781	2	1994-01-01	\N	f	gabylustosa@hotmail.com	t
1100	ROSINEIDE SILVA DE ARAUJO	rosineide.s.araujo@gmail.com	Rosineide	@		89a785212b29a2c7d675b4c7bd34c6d9	f	\N	2011-11-21 10:14:38.370951	2	1989-01-01	\N	f	rosineide.s.araujo@gmail.com	t
338	Junior Lopes	junior777_lopes@hotmail.com	Junior Lopes	@junior777_lopes		e495932e673d22725e7e8170db819d3b	t	2011-10-17 12:31:18.466043	2011-10-17 12:30:44.838198	1	1993-01-01	\N	f		t
1096	SAMUHEL MARQUES REIS	samuhel.e.reis@hotmail.com	Samuhel	@		db8a169949322f1449b974898119a17b	t	2012-01-10 18:26:29.18168	2011-11-21 09:12:04.544026	1	1988-01-01	\N	f	samuhel.e.reis@hotmail.com	t
3603	Emanuel Leal Marques	ultramanel@msn.com	DogSpirit	@		727f11d1a023ecb58d1c78f4974e48bc	f	\N	2012-10-29 23:15:56.972907	1	1986-01-01	\N	f		t
357	gustavo santos	gustavosantosk1@gmail.com	gustavo	@		26d343adf899b5472c474fff659e347d	t	2011-10-17 17:32:23.971414	2011-10-17 17:28:30.448817	1	2011-01-01	\N	f	gusta.moreno@hotmail.com	t
4238	Adriano de oliveira pereira	adrianorra@hotmail.com	adriano	@		f495d86b047c10c399ce2fd039c8beed	f	\N	2012-12-03 11:40:45.212496	1	1995-01-01	\N	f	adrianorra@hotmail.com	t
5358	Taís Silva Alves	alvestais10@gmail.com	taissilva	@		2d269fde6b0a6e611222d373d5814a00	f	\N	2012-12-08 09:26:54.845086	0	1993-01-01	\N	f	alvestais10@gmail.com	t
363	Antonia Adriana Sousa Maciel	adrianasousa1990@gmail.com	Adriana	@		a0fc74a9bdfa1d784e303068200311d8	t	2011-10-17 20:23:51.383657	2011-10-17 20:16:39.732074	2	1990-01-01	\N	f		t
2689	Helder Sampaio de Magalhaes	heldersm5@hotmail.com	heldersm	@heldersm		dc1ff982eacba2919594d51181642a03	f	\N	2011-12-29 12:08:14.56036	1	1976-01-01	\N	f	heldersm5@hotmail.com	t
526	reenan	stuart-tuf@hotmail.com	infowayw	@		4358a67f0af2964b6e442a7a52e185ca	t	2011-11-03 16:27:17.676675	2011-11-03 16:21:47.737727	1	1994-01-01	\N	f	renanroocha@hotmail.com	t
2207	Maria Carlene dos Santos	loraleny@hotmail.com	carlene	@		eee4c21c773a203d8120a041ad40550e	f	\N	2011-11-23 21:11:04.555238	2	1991-01-01	\N	f		t
360	Lucilio	luciliogomes_100@hotmail.com	Lucilio Gomes	@		c7df7cd16fb853734d85c78bc9074c76	t	2011-10-17 19:29:19.083955	2011-10-17 19:27:38.5761	1	1986-01-01	\N	f	luciliogomes_100@hotmail.com	t
344	Joelia de Souza Rodrigues	joelia.srodrigues@gmail.com	Joelia	@		2a18daf7b2043a69c3fe6e179066bca2	t	2011-10-17 13:21:28.106001	2011-10-17 13:20:03.481579	2	1993-01-01	\N	f	jojo_joelia@hotmail.com	t
387	Estevão	estevaovs@gmail.com	Olyver Vongola	@Estevao_vs		68e54efd311e8817d826b9858a833b9d	t	2011-10-19 10:02:03.768485	2011-10-19 10:00:09.439739	1	1994-01-01	\N	f	estevaovs@vs.com.br	t
366	João Paulo Costa Moreno	j.paulo_cor@yahoo.com.br	________	@		90acf54b52e74cc7979ef566005d8b26	t	2011-10-17 20:25:15.075949	2011-10-17 20:20:30.400212	1	1991-01-01	\N	f		t
347	Charlenny Freitas	mylcha@hotmail.com	Charlenny	@mylcha		770851948539d76a3597f3320544f879	f	\N	2011-10-17 14:14:27.814937	2	1976-01-01	\N	f	mylcha@hotmail.com	t
395	alan barros	alanbmx_01@hotmail.com	alanbarros	@		a1e677bf265d76b9113aa178febe447c	t	2011-10-20 09:23:29.321265	2011-10-20 09:22:26.934898	1	1990-01-01	\N	f	alanbmx_01@hotmail.com	t
350	Antonio José Castelo da Silva	antoniojosecdd@gmail.com	Antonio José	@antonioqx	http://www.wlmaster.com	4abd5a8a639656ba8855ea57f7a4d87e	f	\N	2011-10-17 15:04:31.632401	1	1985-01-01	\N	f	antoniojosecdd@gmail.com	t
409	João Victor Ribeiro Galvino	joaovictor777@yahoo.com.br	João Victor	@		740b9c2a17774293a1e97dc27e7f4aec	t	2011-10-20 21:03:09.812971	2011-10-20 21:02:03.415854	1	1991-01-01	\N	f		t
369	Keliane Rocha	kelianerocha27@gmail.com	Keliane Rocha	@		b877cc368d3bd8e49a7760920a09fb1d	t	2011-10-17 20:29:02.460711	2011-10-17 20:22:36.939862	2	1990-01-01	\N	f		t
354	Jedson	jedsonguedes@yahoo.com.br	JedsonGuedes	@jedsonguedes	http://jedsonguedes.wordpress.com	bde25ab206c6fc4ed6011613ff3ff0e9	t	2011-10-17 16:51:23.897544	2011-10-17 16:50:03.431749	1	1992-01-01	\N	f	jedsonguedes@yahoo.com.br	t
413	Marcelo Sá	marcelo.filefox@hotmail.com	Marcelo	@		4667ee68cfb44492694b03dffb4b28e2	f	\N	2011-10-22 12:46:08.163751	1	1986-01-01	\N	f	marcelo.filefox@hotmail.com	t
372	Barboza	cleidiane.maria@gmail.com	Barboza	@		3f9c5c7b0aa9362f095d34432dbb2a8d	t	2011-10-17 23:03:40.83919	2011-10-17 22:51:20.30048	2	1990-01-01	\N	f		t
391	Adairton Freire	adairton_freire@yahoo.com.br	Adairton	@adairton		2aac68fd8537db1894e1d78ac891dbcc	f	\N	2011-10-19 17:58:33.566354	1	1978-01-01	\N	f	adairton_freire@yahoo.com.br	t
421	Harissonn Ferreira Holanda	harissonferreiraholanda@gmail.com	Harisson	@harissonholanda	http://www.harissonholanda.blogspot.com	2f5de6fe853b14c371789488e8f217c6	t	2011-10-23 23:23:31.680253	2011-10-23 23:18:45.104515	1	1993-01-01	\N	f	harissonferreiraholanda@gmail.com	t
430	flanduyar	flanduyar@gmail.com	download	@		1abc9cba0113b3042a18850be94204d1	f	\N	2011-10-24 23:13:16.087866	1	1986-01-01	\N	f	flanduyar@gmail.com	t
434	Allef Bruno	bnrunotk_gb@hotmail.com	Allef Br	@		3f3279d43c2329c3749fbd3aa014ea18	f	\N	2011-10-25 23:52:54.598675	1	1993-01-01	\N	f	brunotk_gb@hotmail.com	t
440	Patricia Pierre Barbosa	patriciapierre00@gmail.com	Pierre	@		66f09e2e115a54b481fadcf5b31916bb	t	2011-10-27 13:51:39.745865	2011-10-27 13:50:01.418599	2	1993-01-01	\N	f	patriciapierre00@gmail.com	t
437	Wesley Coelho Silva	coelho.w@alu.ufc.br	Coelho	@		76a6744cfc6f228e94c539f0a1452ccf	t	2011-10-26 17:39:29.146059	2011-10-26 17:37:30.231462	2	1992-01-01	\N	f		t
442	jorge fernando	jorgefernandorb@hotmail.com	jorge fernando	@jorgefernandu		245a63382e68333dab137dd019c449a3	t	2011-10-28 22:58:02.651705	2011-10-28 22:54:32.001839	1	1988-01-01	\N	f	marvinjfpg@hotmail.com	t
445	 Ana Camila	kakazinhamix@hotmail.com	Camila	@		6a67e071db5a47888d6b58abe69c0cc5	t	2011-10-29 22:33:18.268991	2011-10-29 22:26:27.208853	2	1988-01-01	\N	f		t
531	francisco jailson alves felix	fjalvesfelix@gmail.com	Jailson	@		1ce63cb603aa5b1c92d47e465624f7e2	f	\N	2011-11-03 21:01:07.532749	1	1993-01-01	\N	f	jailson_kbca@hotmail.com	t
310	Camila	milamlima@gmail.com	Camila	@		bc7e2f23169a62706a1b4268ef597147	t	2011-10-14 15:19:06.617174	2011-10-14 15:18:07.70981	2	1987-01-01	\N	f		t
929	THEOFILO DE SOUSA SILVEIRA	theofilo.silveira@gmail.com	Theófilo	@theo_silveira		0a85ccb247d1c641f7c2572d4c8e08e8	f	\N	2011-11-16 15:15:51.504715	1	1985-01-01	\N	f		t
321	Emanuel Pereira de Souza	manix1992ago@gmail.com	Emanuel	@		9da9dd9f2a0df61f924372a829f058a6	t	2011-10-14 21:01:16.988615	2011-10-14 20:55:19.24889	1	1992-01-01	\N	f	manix1992ago@gmail.com	t
311	josé macedo de araujo	rocklee.jiraia@gmail.com	strategia	@		25c9bf68343db897bbd8afce9754ef3c	t	2011-10-14 16:59:17.890375	2011-10-14 16:03:17.96049	1	2011-01-01	\N	f	rocklee.jiraia@gmail.com	t
752	Eugênio Barreto	eugeniobarreto@gmail.com	Eugênio	@		5a1fef13f0a4e6fccd155e8b729b4870	t	2011-11-24 11:53:52.379528	2011-11-11 17:05:15.407481	1	1975-01-01	\N	f		t
318	Ana Gabrielly Lustosa	fofa-gaby@hotmail.com	Gaby Lustosa	@		0cb5bd5c29c3779de866a3b1f70614c6	t	2011-10-14 19:16:34.571626	2011-10-14 19:12:50.609865	2	1994-01-01	\N	f	gabylustosa@hotmail.com	t
336	Geovanio Carlos Bezerra Rodrigues	geovanioufc@gmail.com	Geovanio	@geovanioc		f2be7097da09f3b4dbdf648179b17d25	f	\N	2011-10-17 12:21:34.8845	1	1987-01-01	\N	f	geovanioufc@gmail.com	t
2630	VALDECI ALMEIDA FILHO	valdecifilho94@yahoo.com	Alexandre	@		513fa7fe78d6dada8eb6e431dd24521c	f	\N	2011-11-26 10:08:39.849125	1	1980-01-01	\N	f		t
364	MARIA NILBA DOS SANTOS PAIVA	mnilbapaiva2@gmail.com	nilbapaiva	@		5ca6a76fb54657f19768b03ed316f363	t	2011-10-17 21:11:26.819061	2011-10-17 20:17:54.631479	2	1958-01-01	\N	f	mnilbapaiva2@gmail.com	t
1109	WAGNER ALCIDES FERNANDES CHAVES	waguimch@yahoo.com.br	wagner	@Wagnercomedy		9d2e07412994a909d06fc5b18ef0e069	t	2012-01-10 18:26:30.990073	2011-11-21 10:43:03.394794	1	1988-01-01	\N	f	waguimch@hotmail.com	t
934	WAGNER DOUGLAS DO NASCIMENTO E SILVA	wagner.doug@hotmail.com	Thantoo	@		53f43d5ae2d950bc8d60328eb409eda6	t	2012-01-10 18:26:31.043852	2011-11-16 18:12:22.936075	1	1990-01-01	\N	f		t
3788	José Erick Viana de Oliveira	erickyviana@gmail.com	dricky	@		4787f28295a99a1053ace3a588f0b0fd	f	\N	2012-11-27 20:33:21.087719	1	1995-01-01	\N	f	erickygato@hotmail.com	t
1200	TIAGO DE MATOS LIMA	tiago_m_lima@hotmail.com	TiagoMattos	@		91dbcb360227593ed2846f79ed4031d7	t	2012-12-01 01:06:28.368559	2011-11-22 01:30:27.716866	1	1986-01-01	\N	f	tiago_m_lima@hotmail.com	t
4434	Michael Sullivan	michaelbrother@hotmail.com	micsull08	@micsull08		dde926308425eac159a7d74997a180fc	f	\N	2012-12-04 20:27:30.049368	1	1989-01-01	\N	f	michaelbrother@hotmail.com	t
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
4012	joana darc serafim de souza	joanadarc993@gmail.com	joana darc	@		2ac6ef5b465570d735185e3e689f45c8	f	\N	2012-11-29 21:36:16.032458	2	1993-01-01	\N	f		t
380	Mark Alleson Silva Lima	markalleson@gmail.com	Mark Alleson	@markalleson		d42adbd3c0b23933b9aa8468a5a242fa	t	2011-10-18 13:39:14.656071	2011-10-18 13:37:03.567588	1	1983-01-01	\N	f	markalleson@gmail.com	t
397	Denylson Santos de Oliveira	densdeoliveira@hotmail.com	denys86	@		8e5ba776ad43c72f2a284a884c9a1557	t	2011-10-20 11:54:04.851143	2011-10-20 11:08:34.528286	1	1986-01-01	\N	f	densdeoliveira@hotmail.com	t
411	George Santos	georgesantos169@gmail.com	George	@georgesanto		c7af520291d0ad0e083f43b8da6ae610	t	2011-10-21 21:08:06.771013	2011-10-21 21:02:34.130201	1	1988-01-01	\N	f	judogeorge@hotmail.com	t
3344	ADILIO MOURA COSTA	adilio_costa27@yahoo.com.br	ADILIO MOU	\N	\N	e7d908ec300d16b1fe39c2d765109eec	f	\N	2012-01-10 18:25:40.966063	0	1980-01-01	\N	f	\N	f
419	david Der	d.avid.h@hotmail.com	David_Der	@		6b3214b6418eb40ab4d70487c8633216	t	2011-10-23 21:52:23.679007	2011-10-23 21:51:06.143256	1	1994-01-01	\N	f	d.avid.h@hotmail.com	t
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
4326	Sara Maria da Silva	saramarrentynha@gmail.com	marrenta	@		688e7ffa5cbbd9c8a0cff79a280b58e4	f	\N	2012-12-03 22:12:32.977937	2	1996-01-01	\N	f	saramarrentynha@gmail.com	t
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
487	rafaela torres moraes	rafaela.torres.moraes@gmail.com	rafaelinha	@		a0456f963adab644714d2b8770896f61	f	\N	2011-11-03 09:29:35.340325	2	1995-01-01	\N	f		t
762	OLGA SILVA CASTRO	olga_kastro@hotmail.com	OLGA CASTRO	@olgascastro		f1ce484fd645f6fb196b7b8954c556b2	t	2012-01-10 18:26:26.228833	2011-11-11 21:19:28.154973	2	2011-01-01	\N	f	olga_kastro@hotmail.com	t
1196	LUCIANO JOSÉ DE ARAÚJO	luciano_geo2007@yahoo.com.br	Luciano	@		561f9fbd1b07b3310bdbaa86b7d82995	t	2012-01-16 11:20:58.103582	2011-11-21 23:33:01.856965	1	1988-01-01	\N	f	luciano_geo2007@yahoo.com.br	t
4704	Juliene Albino França	juliene.albino@gmail.com	Enne'zinha	@		cdc9783d45e2ba25d5b656bb282b822e	f	\N	2012-12-05 20:05:50.660126	2	1992-01-01	\N	f	enne_vip@hotmail.com	t
784	Francisco Rafael Alves de Oliveira	thinodomas@hotmail.com	Rafa22	@drafael18	http://vampirerafa18.blogspot.com/	b03d5bc273bd671cea6b09d7780b55dd	t	2011-11-12 21:02:03.762902	2011-11-12 21:01:14.899389	1	1992-01-01	\N	f	thinodomas@hotmail.com	t
536	CAMILA DA COSTA	camilasousa172011@hotmail.com	camila	@		8effa82b05f5509e9f780e7ce7640094	t	2011-11-04 09:12:23.35954	2011-11-04 09:00:13.883409	2	1994-01-01	\N	f	camilasousa172011@hotmail.com	t
579	GEORGE GLAIRTON GOMES TIMBÓ	g3timbo@gmail.com	George	@		c6f94723f580ee11753560db05062266	t	2012-01-13 21:15:32.679804	2011-11-04 13:35:52.706198	1	1992-01-01	\N	f	g3timbo@gmail.com	t
582	Alexandre	alexandrekenpachimaster@gmail.com	Alexandre kenpachi 	@		984ac10ccb4ab9aa92a6929f3cc5ad1f	t	2011-11-04 22:05:52.042425	2011-11-04 21:49:16.158345	1	1992-01-01	\N	f	alexandrekenpachimaster@gmail.com	t
478	alex da silva gonçalves	alex.d4.silva@gmail.com	alexdasilva	@		8cbc5579d9cf20c0c0162153c23644ac	t	2012-12-07 10:51:08.862243	2011-11-03 09:25:36.091016	1	1995-01-01	\N	f		t
482	elisebety de sena lima	elisabetysena95@gmail.com	betinha	@		434b4fcb7d01109c7e73dd6154d567de	t	2011-11-03 09:35:30.878474	2011-11-03 09:28:10.331618	2	1995-01-01	\N	f		t
542	robson	robson.gospel@hotmail.com	robson	@		6a4d6a69ee8c47b2b7a2b1b46205ee20	f	\N	2011-11-04 09:00:46.916292	1	1992-01-01	\N	f	robson.gospel@hotmail.com	t
545	Daniele Souza de Araújo	danielesouzadearaujo@gmail.com	Daniele	@		e9de2f52bed2b78d46c9bf1e127dd897	t	2011-11-04 11:13:18.361311	2011-11-04 09:02:29.647025	2	1982-01-01	\N	f		t
589	Wendel Barros Vieira	wendel_bar@hotmail.com	Wendel	@		19879ef859ba3cee5907da2afb018aed	t	2011-11-07 15:24:19.992042	2011-11-07 15:21:30.734132	1	1983-01-01	\N	f		t
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
803	Francisco Thiago de Sousa Crispim	thiagoejovem@gmail.com	Thiago	@		7ab94d0e5423a1f0c39800dd2c32f1ea	t	2012-12-06 11:45:33.065415	2011-11-14 12:53:20.053551	1	1990-01-01	\N	f	thiagoscrispim@gmail.com	t
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
819	Alan Moreira Teixeira	alan_mt95@hotmail.com	Alan''  =D	@		51e2353677ec247d12ac65608eb73f20	t	2011-11-19 20:33:57.942658	2011-11-14 22:15:09.927311	1	1995-01-01	\N	f		t
1098	Carlos Kervin	kervin_goo@hotmail.com	Kervin	@KervinVI		a781d4c6fc432955bc2ec9db8f02d642	t	2011-11-21 09:30:02.209504	2011-11-21 09:21:49.882447	1	1995-01-01	\N	f	kervin_goo@hotmail.com	t
549	Jéssica	r_bd_j@hotmail.com	'jessy'	@JssicaB		741fedb304688937b77c0feba0f6d327	t	2011-11-04 09:12:53.808165	2011-11-04 09:04:23.60953	2	1994-01-01	\N	f	r_bdj@hotmail.com	t
557	Thalis Jordy Gonçalves Braz	tj-braz@hotmail.com	TeeJay	@thalisjordy		d126207eadec477bd9f4d1460dd270c1	t	2011-11-04 09:13:31.510294	2011-11-04 09:06:59.439062	1	1994-01-01	\N	f	tj-braz@hotmail.com	t
577	Antonio Ailton Gomes da Silva	aagomes63@gmail.com	Ailton	@	http://ticnewszumbi.blogspot.com/	e769bdd3ddb981270f87545c38ee149f	t	2011-11-04 11:35:01.498039	2011-11-04 11:18:10.696052	1	1963-01-01	\N	f	aagomes63@gmail.com	t
5359	Mary ângela sales do nascimento	anginha_sales@hotmail.com	anginha	@		987afd71702a1e675e23c2f15e420b15	f	\N	2012-12-08 09:34:56.077904	2	1995-01-01	\N	f	anginha_sales@hotmail.com	t
550	junior	diisalesjunior@gmail.com	yudiii	@		92837e9e5a53dc97ee4d079d0e26b98f	t	2011-11-04 09:15:04.939884	2011-11-04 09:04:28.48115	1	1993-01-01	\N	f		t
425	MANOEL ALEKSANDRE FILHO	aleksandref@gmail.com	Lex Aleksandre	@aleksandre	http://debianmaniaco.blogspot.com	4e90d6fe6bca1758146a378f7b79223a	t	2012-01-10 18:26:24.340552	2011-10-24 14:57:56.38271	1	1974-01-01	\N	f	aleksandref@gmail.com	t
398	MARCOS PAULO LIMA ALMEIDA	marck_migo@hotmail.com	M.Paulo	@		4556c0f57577b07acabb177725d9b909	t	2012-01-16 17:34:49.106925	2011-10-20 18:18:22.577374	1	1991-01-01	\N	f	marck_migo@hotmail.com	t
563	José Raimundo de Araújo Neto	neto0147@hotmail.com	neto0147	@		afe43989b8bb2b1b51acf5d61c387320	t	2011-11-24 11:21:44.68811	2011-11-04 09:10:44.806262	1	1992-01-01	\N	f	neto0147@gmail.com	t
824	MARIA CAMILA ALCANTARA DA SILVA	camila.ca27@gmail.com	CAMILA ALCANTARA	@		bae18e916bdd91af9f6df7b65c68f870	t	2012-01-17 09:29:38.646835	2011-11-15 09:57:48.587851	2	1992-01-01	\N	f	camila.ca27@gmail.com	t
1079	MARIA IZABELA NOGUEIRA SALES	iza-nogueiira@hotmail.com	Izabela	@iza_alone		b49dcddff16509fc5ca1520c569ab60a	t	2012-01-15 23:05:58.858861	2011-11-20 14:36:14.809742	2	1992-01-01	\N	f	iza-nogueiira@hotmail.com	t
4705	MONALISA EVANGELISTA BARROSO 	mona.barroso23@gmail.com	Monnah	@		422431e965fd873dbdc2404af37f7cb8	f	\N	2012-12-05 20:07:08.410039	2	1993-01-01	\N	f		t
5397	SARA GUIMARAES DA COSTA	saraguimares56@gmail.com	SARA COSTA	@		bb31beaa2ee053ba478dca0b9eae8c68	f	\N	2012-12-08 10:27:54.778194	2	1995-01-01	\N	f		t
591	Edson Gustavo de Freitas Queiroz	gustavotecno1@hotmail.com	Crash@	@		259179fddc7a425b06e6e99d4c860c58	t	2011-11-07 16:43:57.204917	2011-11-07 16:41:34.203561	1	1990-01-01	\N	f	ed-queiroz@hotmail.com	t
612	edson da silva	gallgml@hotmail.com	edsongall	@		11f9ae1dd040f1b37718234d28f03f34	t	2011-11-07 21:53:28.84569	2011-11-07 21:50:44.369926	1	1992-01-01	\N	f	gallgml@hotmail.com	t
679	Flávio Dias	flaviodiasd@gmail.com	Flávio Dias	@phlaviodiasd		38484a971e96ba7065661c2f5912e8e7	t	2011-11-10 09:47:53.005936	2011-11-10 09:40:47.235808	1	1990-01-01	\N	f	flaviodiasd@gmail.com	t
596	João Raphael Silva Farias	metal.raphael@gmail.com	Raphael Farias	@	http://www.youtube.com/user/metalraphael	da6401d315eb7fc696180b9b679d3668	t	2011-11-07 18:42:34.115569	2011-11-07 18:36:49.532318	1	1987-01-01	\N	f	metal.raphael@gmail.com	t
756	adeline louise	adeline.12@hotmail.com	deline	@		461e872ac53573f6040494bb84c71d3a	f	\N	2011-11-11 18:46:39.437575	2	1995-01-01	\N	f	adeline.12@hotmail.com	t
617	Ingrid Ruana Lobo E Silva	ingrid.ruanna@gmail.com	Flávia	@		53f54c2789ec0799a31b66541d31ed34	t	2011-11-08 08:13:48.081422	2011-11-08 08:07:30.989561	2	1993-01-01	\N	f	ingrid-poderosa@hotmail.com	t
645	Herculano Filho	herculanogfilho@yahoo.com.br	Laninho	@herculanogfilho		9b0529a36ec6f3e3badc52095a7620de	f	\N	2011-11-09 09:30:30.28339	1	1989-01-01	\N	f	laninho_boyy@yahoo.com.br	t
621	Eduardo Costa Rafael	edudunove@hotmail.com	edudunove	@		d76af5c647077d3f8593b7163294f64b	f	\N	2011-11-08 11:56:06.009774	1	1982-01-01	\N	f		t
786	Thayanne de Sousa Ribeiro	taya_sousa@hotmail.com	ThaTah	@ThaTah_XD		9ca32378bfc3576855e81773d07bc9ce	t	2011-11-12 23:10:38.881953	2011-11-12 23:09:16.904175	2	1993-01-01	\N	f	taya_sousa@hotmail.com	t
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
424	MAXSUELL LOPES DE SOUSA BESSA	iniciusx@gmail.com	Inicius	@		79b82cb2386c8bcffdb5290154ccab73	f	\N	2011-10-24 13:11:46.091424	1	2011-01-01	\N	f	iniciusx@gmail.com	t
597	Emanuely Jennyfer	emanuelyjennyfer@gmail.com	emadinny	@		1e855d841574ae2cc4cda5400c1b4675	t	2011-11-13 18:24:19.571087	2011-11-07 21:41:59.636901	2	2011-01-01	\N	f	emanuelyjennyfer@gmail.com	t
467	MAYARA FREITAS SOUSA	mayara_rebeldemia12@hotmail.com	MAYARA	@		8c45740cf4da30af77169bf8c09d6f56	t	2012-01-10 18:26:25.27822	2011-11-02 17:34:21.592705	2	1994-01-01	\N	f	mayara_rebeldemia12@hotmail.com	t
578	Núcleo de Tecnologia Educacional de Maracanaú	ntmmaracanau@gmail.com	NUTEM Maracanaú	@	http://ntmmaracanau.blogspot.com/	d0c14d7666601f351d5d113814615b19	t	2011-11-04 11:33:30.918787	2011-11-04 11:21:55.7866	1	2008-01-01	\N	f	ntmmaracanau@gmail.com	t
4240	Antônio Italo Pereira da Silva	Antonyitallo90@hotmail.com	Itallo	@italloprncepi		c9c20265d2acc002d052ff55148829fd	f	\N	2012-12-03 11:41:03.261739	1	1993-01-01	\N	f		t
3353	AMANDA DIOGENES LUCAS	manda_zita@hotmail.com	AMANDA DIO	\N	\N	ede7e2b6d13a41ddf9f4bdef84fdc737	f	\N	2012-01-10 18:25:43.586899	0	1980-01-01	\N	f	\N	f
325	JULIANA PEIXOTO SILVA	juliana.compifce@gmail.com	Juliana	@		0cd399de1e1e05b97a836a1fb83f79ba	t	2012-01-16 21:36:23.451752	2011-10-15 09:43:24.296862	2	1986-01-01	\N	f	juliana_1945@hotmail.com	t
627	JONAS OTHON PINHEIRO	othon.jp@gmail.com	OTHON00	@othon_jp		6f6e5e4112ad9fb2d86b981462b3cbee	t	2012-12-07 23:13:17.192052	2011-11-08 15:50:37.98393	1	1993-01-01	\N	f	othon.jp@gmail.com	t
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
4731	Amanda Ingrid Silveira Alves	amandasilveira.25837@hotmail.com	Amanda Silveira	@		9a9e47a3642a06d59eec614208a89475	f	\N	2012-12-05 21:35:53.062588	2	1993-01-01	\N	f	amanda_bebe10@hotmail.com	t
669	Felipe dos Santos Alves	felipe_santos_9@live.com	Felipe	@FelipeSantos		9e3c47f4c278670c023c9abb09e4daae	f	\N	2011-11-09 14:42:19.997088	1	1995-01-01	\N	f	felipe_santos_9@live.com	t
3357	ANA FLÁVIA CASTRO ALVES	ilifinivai@gmail.com	ANA FLÁVI	\N	\N	cdb902eab5c00651ede9072ae2f1c26d	f	\N	2012-01-10 18:25:44.730579	0	1980-01-01	\N	f	\N	f
670	Carlos Henrique Silva Sales	chss.ce@gmail.com	Henrique	@henriquepardal		d2ce5c875e55ffaf46b45b463615498b	t	2011-11-09 19:40:38.80518	2011-11-09 18:55:07.846336	1	1981-01-01	\N	f	chss.ce@facebook.com	t
1365	HIANDRA RAMOS PEREIRA	hiandra_ramos@hotmail.com	HIANDRA	@		3f1aabc3dbb3276eb67118e90d873ec9	f	\N	2011-11-22 12:08:33.91252	2	1995-01-01	\N	f		t
3856	Cleidiane Rodrigues	cleidiane.r@hotmail.com	Cleidiane	@		688d759412331bc514e6b867a39220cd	f	\N	2012-11-28 21:32:55.85318	2	1994-01-01	\N	f		t
671	Jean Gleison Andrade do Nascimento	jandradenascimento@gmail.com	jnascimento	@		ad682987640b7300eac0ef577a55f248	t	2011-11-09 19:13:40.788869	2011-11-09 19:10:19.824234	1	1986-01-01	\N	f	jandradenascimento@gmail.com	t
1626	Rúben Alves	rubenlobao@gmail.com	Lobão	@		13782ca2d6d36f66c5c9bf683e00c82f	f	\N	2011-11-22 20:32:23.271203	1	1995-01-01	\N	f		t
687	Thiago Lucas de Souza Pinheiro	thiagopanic@hotmail.com	T.Lucaas	@		a808c9d90b95231922ec5112ba0cea24	f	\N	2011-11-10 14:11:35.459129	1	1994-01-01	\N	f		t
4327	Viviane Costa	vivicosttaa@yahoo.com.br	Vivi Costa	@vivicostta		0c071f26e0c9c3efc8833dd6abbef82a	f	\N	2012-12-03 22:20:30.95625	2	1989-01-01	\N	f		t
5026	Deusdedit Meneses	dentin.lokos@gmail.com	Detin Menezes	@		c387f828388ed073d3e4ddd3a81affcd	f	\N	2012-12-06 16:52:06.549351	1	1995-01-01	\N	f	detinho125@hotmail.com	t
788	Daniel Ferreira de França	daniel.fer1992@hotmail.com	.Bilu.	@		d7c624cabe7fa6e9613968f043cde57b	f	\N	2011-11-13 04:16:35.003953	2	2011-01-01	\N	f		t
986	Keliane da Silva Santos	Kellyane-pink@hotmail.com	Kellynha	@		f3674879f5e18c7989e02235da302cc9	t	2011-11-17 22:20:20.679821	2011-11-17 22:10:41.974482	2	1997-01-01	\N	f		t
695	tayná rayssa lima araujo	tayna15love@hotmail.com	Rayssa	@		0544a0ce3ea0becff9d4c018900ddf1c	t	2011-11-17 09:21:45.629369	2011-11-10 20:06:06.59623	2	1996-01-01	\N	f	tayna15love@hotmail.com	t
713	Maurilio Bandeira	maurilio.naruto057@gmail.com	Maurilio	@		baf25364f35b97b7324dac48ee1cb2ef	t	2011-11-10 22:21:59.9087	2011-11-10 22:11:44.610832	1	1993-01-01	\N	f		t
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
433	Francisco David	david.xbox01@gmail.com	F David	@		86f114a653abb0d6e5e3db972b9f4455	t	2012-11-26 21:52:33.052281	2011-10-25 22:05:21.489388	1	1986-01-01	\N	f	fd_xbox@hotmail.com	t
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
1074	Thiago André Cardoso Silva	thiagoandrecadoso@gmail.com	ThiagoQI	@qignorancia	http://www.quantaignorancia.com/	41d2cfab1eef3096964a74f84577b2b8	f	\N	2011-11-20 09:08:16.025271	1	1987-01-01	\N	f	aerosmith-so@hotmail.com	t
1459	Marcos Teixeira Marques Filho	marquinhos_14cearamor@hotmail.com	Marcos	@		e2e64a0f4ddbedadca84102499e4c90f	f	\N	2011-11-22 16:54:33.860885	1	1995-01-01	\N	f	marquinhos_14cearamor@hotmail.com	t
843	Stefhanie Gama	stefhanie.gama@hotmail.com	Thefyy	@stefhaniieg		494609f80f5a615aeebaa4cd9bf47c80	t	2011-11-17 14:43:29.336451	2011-11-15 19:21:10.407503	2	1994-01-01	\N	f	stefhanie.gama@hotmail.com	t
846	Aluisio Rodrigues	aluisio0919@hotmail.com	Aluisio	@		8fb5c330af19b0f8af387f651704e626	t	2011-11-15 19:40:54.689747	2011-11-15 19:39:45.889856	1	1994-01-01	\N	f	aluisio0919@hotmail.com	t
947	Rafael Freitas Rodrigues Viana	rafaelviana70@yahoo.com.br	Viiana '-'	@		e3da615b6ddceedca071673916a96d97	t	2011-11-17 09:10:08.796101	2011-11-17 09:05:21.433986	1	1994-01-01	\N	f	rafaelnaparada@hotmail.com	t
854	Bruna Caroline Xavier Gomes 	brunagomes365@hotmail.com	bruna gomes	@		48010a8994cc781dec74efba9be4f3ef	t	2011-11-16 10:57:42.096117	2011-11-16 10:30:41.344781	2	1995-01-01	\N	f	brunagomes365@hotmail.com	t
1041	anna paula	anna_pauliinha@hotmail.com	paulinha	@		039347a98500499a83a6d1a6fc2eaf7a	f	\N	2011-11-19 00:43:42.305405	2	1993-01-01	\N	f	anna_pauliinha@hotmail.com	t
1589	Junior Vasconcelos	cardozoqueiroz@hotmail.com	b-boy Bob	@		be571c6636f20722ef59acefa44e6462	f	\N	2011-11-22 18:17:22.787866	1	1995-01-01	\N	f		t
859	walter barbosa	wthummel@hotmail.com	Binladen	@		61669c4f41c341cb917a2571a6a52670	t	2011-11-16 11:01:59.412482	2011-11-16 10:43:33.903967	1	1995-01-01	\N	f	wthummel@hotmail.com	t
1261	Alysson Martins	alyssonmartins13_@hotmail.com	Vaskin	@vaskin_pxpxcx		6f99bca242e384a49c197051e53ec591	f	\N	2011-11-22 09:45:06.341304	1	1991-01-01	\N	f	alyssonmartins13_@hotmail.com	t
1044	JEAN LUCK CARDOSO DA SILVEIRA	janusrock@hotmail.com	euthanatos	@		f8abdee5310b6e44369d0948877d9ad5	t	2012-01-10 18:26:12.947566	2011-11-19 11:09:36.694851	1	1992-01-01	\N	f	janusrock@hotmail.com	t
972	halesson	halessonmenezes0@hotmail.com	massive	@		9fb10d125a03d2b9d7780cbe87accb9e	t	2011-11-17 11:51:31.468893	2011-11-17 11:47:59.994481	1	1995-01-01	\N	f	halessonmenezes0@gmail.com	t
326	AlysonMello	Alyson27@gmail.com	Triplomaster	@Alyson_Mello		8ae8483a4f4ddb0d4451d3f801229c53	t	2011-11-17 14:58:21.147421	2011-10-15 09:54:25.937655	1	2011-01-01	\N	f	Alysonmello_2011@hotmail.com	t
863	Bruno Celiio	brunoceliio@hotmail.com	BrunoCeliio#	@		be7b053ca729a45fe38cef462b78fd5a	t	2011-11-16 11:34:28.897137	2011-11-16 10:50:00.561277	1	1995-01-01	\N	f	brunoceliio@hotmail.com	t
901	Carlos Matheus Chaves de Gois	carlos_matheush01@yahoo.com.br	skid RM	@		b41dba9db2e4f11abf3a7eaa0941fc71	t	2011-11-16 11:44:54.382958	2011-11-16 11:37:47.267099	1	1995-01-01	\N	f	matheus_gdx@hotmail.com	t
979	Levi Pires de Gois	levipiresgois@hotmail.com	katekyu	@		ef1bc753815beb298ef12b5f3e226504	f	\N	2011-11-17 15:21:25.350163	1	1995-01-01	\N	f		t
1012	Leticia fernandes	lehfernandes@hotmail.com	leeeeh	@		809edf53fabb12d2014876bbcedce2a0	f	\N	2011-11-18 17:08:46.574817	2	1996-01-01	\N	f		t
1120	Paulo Rafael da Silva Cavalcante	rafaeljigsaw_@hotmail.com	rafael sinx	@		1f2aef49bf21f02a37aba50bde45a43d	f	\N	2011-11-21 12:02:15.09179	1	1994-01-01	\N	f		t
2211	Francisco Jonas Ferreira	jonnascr7@LIVE.COM	jonasferr	@		95183eccbc41d7beccf46c272ea948ca	f	\N	2011-11-23 21:18:59.832639	1	1990-01-01	\N	f		t
748	isaac bruno	isaac.bruno@hotmail.com	bruno10	@		c6fcc0dedd4250a3ef8c5cc5fdc09503	t	2011-11-11 15:56:58.303016	2011-11-11 15:50:15.865561	1	1994-01-01	\N	f		t
408	JOÃO VICTOR RIBEIRO GALVINO	joaov777@gmail.com	João Victor	@		3284dbb877a0a0d129bbba353687cc3b	t	2012-01-10 18:26:15.233517	2011-10-20 21:00:50.225138	1	1991-01-01	\N	f		t
4706	nando mota	nando.famv@hotmail.com	speckops	@		e663a9a0c5a82282ca2b87d2a12bebfe	f	\N	2012-12-05 20:08:26.571491	1	1996-01-01	\N	f	nando.famv@hotmail.com	t
1414	JONATA ALVES DE MATOS	jonataamatos@hotmail.com	jonata	@jonata08matos		1d04054ec1abb85e0421a6e6f2cac538	t	2012-01-16 11:28:21.970509	2011-11-22 16:32:35.909901	1	1986-01-01	\N	f	jonataamatos@hotmail.com	t
751	Leandro Silva de Sousa	tricolor.leandro@gmail.com	Leandro	@leossousa	http://sistemaozileo.blogspot.com	ed2f0d39f4964bc294d5ffa9e50f427d	t	2011-11-11 16:45:12.07433	2011-11-11 16:40:37.270709	1	1974-01-01	\N	f	tricolor.leandro@gmail.com	t
791	Mônica	monica.b.l@hotmail.com	Mônica	@monica_angel		51044394289de849bf0a2cb1ddc654b7	t	2011-11-13 10:11:46.317703	2011-11-13 09:44:37.837919	2	1988-01-01	\N	f	monica.bandeira.lourenco@gmail.com	t
776	Carlos Eduardo de Oliveira	kaduoliveira13@hotmail.com	Kaduzinho	@		c1c892138543dee118a5a43cd65c7be0	f	\N	2011-11-12 15:02:03.736978	1	1994-01-01	\N	f	kaduoliveira13@hotmail.com	t
3364	ANTONIA MARIANA OLIVEIRA LIMA	mariana.lima91@hotmail.com	ANTONIA MA	\N	\N	9ab0d88431732957a618d4a469a0d4c3	f	\N	2012-01-10 18:25:48.115129	0	1980-01-01	\N	f	\N	f
1151	JOSÉ XAVIER DE LIMA JÚNIOR	xavierxion@hotmail.com	Zyegfreed	@		908ec83844397d4df4f605743a3f7184	t	2012-01-10 18:26:18.092088	2011-11-21 17:42:01.123853	1	1988-01-01	\N	f	xavierxion@hotmail.com	t
3365	ANTONIA NEY DA SILVA PEREIRA	bibleney@gmail.com	ANTONIA NE	\N	\N	644593a6096a12d57271d31515d06bbf	f	\N	2012-01-10 18:25:48.319241	0	1980-01-01	\N	f	\N	f
815	ana claudia	ana.cnarujo@hotmail.com	aninha	@		18862362c266237811f11624db053c06	f	\N	2011-11-14 20:46:20.237031	2	1994-01-01	\N	f	ana.cnaraujo@hotmail.com	t
993	GABRIEL BEZERRA SANTOS	bezerragb@hotmail.com	Gabriel	@Erupoldaner		d8059c5dfe4bbc60f0d0f6bd69b8accb	t	2012-01-16 12:48:56.649725	2011-11-18 09:18:26.10386	1	1991-01-01	\N	f	bezerragb@hotmail.com	t
1075	Marcos Gabriel Santos Freitas	gb_tinho@hotmail.com	VesgoMaker	@Gabriel_Screamo	http://envenenado.tumblr.com/	277dbf3be51fc5b3b18860b0f1014fa2	t	2011-11-24 11:53:45.397738	2011-11-20 10:30:24.758507	1	1993-01-01	\N	f	gb_tinho@hotmail.com	t
3665	Sanção Selestino Loiola	sansaoselestino@gmail.com	morpheu	@sansao_starnews		7685a635653560e90f4278c1ccf4c67c	f	\N	2012-11-24 22:48:41.655392	1	1984-01-01	\N	f		t
798	Marcos Calixto Duarte	mcalixtod@bol.com.br	Calixto	@		796278a4e151e7e05049c425030c0e13	t	2011-11-22 22:43:33.049886	2011-11-13 19:40:15.107385	1	1996-01-01	\N	f		t
3366	ANTONIA SIDIANE DE SOUSA GONDIM	sidiane_cindy@hotmail.com	ANTONIA SI	\N	\N	e555ebe0ce426f7f9b2bef0706315e0c	f	\N	2012-01-10 18:25:48.618342	0	1980-01-01	\N	f	\N	f
4198	Edney Almeida	edney49@hotmail.com	Edy almeida	@edy_rocky		69de40d7464b7151923ee912262a6371	f	\N	2012-12-01 22:02:16.414284	1	1984-01-01	\N	f	edney49@hotmail.com	t
329	Carlos Henrique 	carlos-tuf@hotmail.com	carlinhos	@		29c0140c11ef9f7abbbf81c7f237879a	t	2011-11-15 01:38:34.48918	2011-10-15 12:08:25.218063	1	1993-01-01	\N	f	carlos-tuf@hotmail.com	t
3694	Nauhan dos Santos Dias	nauhandsdias@hotmail.com	Nauhan	@		b64a2e10c02d210c0877697d4e9c5655	f	\N	2012-11-26 22:52:45.168683	2	1994-01-01	\N	f		t
4241	alana lima	aless.allana@gmail.com	allana	@		49cb36d62bb7bedab51203ff0e83109c	f	\N	2012-12-03 11:41:37.927334	2	1996-01-01	\N	f	alanamaluca@hotmail.com	t
835	Márcia Caroline Germano Pereira	marcia___caroline@hotmail.com	Carolzinha	@marcia_caroline		e56ee9b8b30e6ad9e50a155b3e4e871a	t	2011-11-15 16:35:33.836129	2011-11-15 16:29:48.981154	2	1994-01-01	\N	f	marcia___caroline@hotmail.com	t
989	Aline Isabelle	alineisabelle@bol.com.br	Aline Isabelle	@alineisabelle		e3c68baa8a32fd328864588eb99c85ae	f	\N	2011-11-17 23:26:46.084834	2	1995-01-01	\N	f	alineisabelle@bol.com.br	t
1174	Darlildo Lima	darlildo17@hotmail.com	Darlildo	@darlildo	http://darlildo.wordpress.com/	e6072eb614506728167864e5cfdbf168	f	\N	2011-11-21 20:45:45.886739	1	1989-01-01	\N	f	darlildo.cefetce@gmail.com	t
5360	Alexandre pereira aquino	alexpaquino@gmail.com	alexaquino	@	http://www.originaldesigner.com.br	b2ad0eeddb2ad41090146f77cb175b1f	f	\N	2012-12-08 09:39:04.825936	1	1979-01-01	\N	f	aquinoalexp@hotmail.com	t
838	Fabiana Larissa Barbosa da Silva	flarissasilva@hotmail.com	fabiana	@		c0aedde73e52a867ea2e432052dfc3e4	f	\N	2011-11-15 17:58:46.998596	2	1993-01-01	\N	f	flarissasilva@hotmail.com	t
857	Karine Vieira Queiroz	karine_fofaa@hotmail.com	Kazinha	@		f8def8dbeffe7de925d3efbc5a10174b	t	2011-11-16 10:43:11.202093	2011-11-16 10:33:03.24012	2	1994-01-01	\N	f	karine_foffa@hotmail.com	t
841	João Ferreira	joaogato07@hotmail.com	joaoferreiratorres	@DepositoJacome		908c9b1fe76d776304eb59dc02cd534f	f	\N	2011-11-15 19:06:25.311182	1	1997-01-01	\N	f	joaogato07@hotmail.com	t
1035	Antonio Herlanio Pinheiro Lacerda	herlanio_lacerda@hotmail.com	herlanio	@Fercodine		2946ac642dc502bc700556fc98cfde69	t	2011-11-18 21:35:08.595635	2011-11-18 21:31:51.541993	1	1996-01-01	\N	f	herlanio_17x@hotmail.com	t
844	Bensonhedges de Sousa Gama	benson_black_star@hotmail.com	Benzoo	@		dc5842cf06261ea146ddf341a2573317	f	\N	2011-11-15 19:22:16.796786	1	1996-01-01	\N	f		t
948	Raul de Souza Ferreira	hw_raul95@yahoo.com.br	>pipoca<	@		f2baddc6b3305042b40a6479f225639e	t	2011-11-17 09:19:01.829256	2011-11-17 09:06:48.982852	1	1995-01-01	\N	f		t
3367	ANTONIO DE LIMA FERREIRA	johnnyrude@hotmail.com	ANTONIO DE	\N	\N	22ac3c5a5bf0b520d281c122d1490650	f	\N	2012-01-10 18:25:48.801679	0	1980-01-01	\N	f	\N	f
969	Monique Farias Abreu	monique_salvatore16@hotmail.com	perfeiktinha	@		0fcd0734cde1d0e51ea4c433dfec7d5a	f	\N	2011-11-17 09:44:39.674402	2	1995-01-01	\N	f		t
691	adrielly gomes oliveira	adriellydrika2009@hotmail.com	lily gomes	@adrielygomez		6caebb8d29bd69a9a694b1dabfdc005d	t	2011-11-23 11:00:28.750002	2011-11-10 17:19:43.734321	2	1996-01-01	\N	f	adriellydrika2009@hotmail.com	t
3368	ANTONIO ELSON SANTANA DA COSTA	elsonsan@yahoo.com.br	ANTONIO EL	\N	\N	277261b31167f604df82fd5926297e9a	f	\N	2012-01-10 18:25:48.943544	0	1980-01-01	\N	f	\N	f
845	samuel jodson nunes ponte	samukacearamor@hotmail.com	samuca	@		c1acdd3b0d152c94eac96ed49834049d	t	2011-11-19 00:58:19.647037	2011-11-15 19:22:57.120401	1	1994-01-01	\N	f		t
821	Daniel Abner Sousa dos Santos	abnersousa2009@hotmail.com	daniel	@		c670bbbd9eebc9f48756c6668fd59091	t	2011-11-16 11:23:23.654417	2011-11-14 22:25:36.802964	1	1995-01-01	\N	f	abnersousa2009@hotmail.com	t
858	jhonathan davi alves da silva	jhon-davi@hotmail.com	jhon-jhon	@		08d927976fc9fdd1888d08d29bc408c3	t	2011-11-16 11:30:43.256012	2011-11-16 10:42:23.848331	1	1995-01-01	\N	f	jhon-davi@hotmail.com	t
1368	WILKER BEZERRA LUCIO	wilker100wbl@hotmail.com	WILKER	@		3e9c9d97bd066d5c86a54533c47c3df3	t	2011-11-22 21:46:32.937454	2011-11-22 12:14:43.213561	1	1995-01-01	\N	f		t
938	Mikaelly Ribeiro da Silva	Mikaelly.r.s@gmail.com	Mikaelly	@		4af4e24481f01b54c7d219994b698c87	t	2011-11-17 15:40:26.049044	2011-11-16 21:03:55.249724	2	1992-01-01	\N	f	Mikaelly.r.s@gmail.com	t
1048	Deise Dayane	deisinha_tuf@hotmail.com	Deisinha	@		17232c911601f062447a9d94d99f0344	t	2011-11-19 12:38:46.391978	2011-11-19 12:30:45.47491	2	1993-01-01	\N	f	deisinha_tuf@hotmail.com	t
1274	Alexandro Santos de Oliveira	alexandroliveira2009@hotmail.com	alex Lón	@		4aec9e75419f74553cc14f2a3f2fd08e	f	\N	2011-11-22 09:50:22.250403	1	1989-01-01	\N	f		t
1590	Cesinha	vania.rosivania@gmail.com	Cesiha	@		589d8e28f7443c2584d26309d1a35043	f	\N	2011-11-22 18:20:13.327172	1	1993-01-01	\N	f		t
941	maria samia andrade oliveira	saklb@hotmail.com	samia19	@		a22c2723d47d3e0b6792bf5c2cdf4eb3	t	2011-11-18 23:02:27.145239	2011-11-16 21:56:55.020327	2	1992-01-01	\N	f	samia.andrade.oliveira@gmail.com	t
4436	Michael Sullivan	michaelsullivan.micsull@gmail.com	micsull08	@micsull08		120e710b2cdd8776f49b8768ca4f2ce6	f	\N	2012-12-04 20:32:23.625778	1	2011-01-01	\N	f	michaelbrother@hotmail.com	t
990	jonathan santos	jonatha_igor@hotmail.com	kanda yuu	@jonahigor		ad4b5edbe64deabf32b653dfb809e852	t	2011-11-17 23:46:48.732943	2011-11-17 23:41:43.75936	1	1993-01-01	\N	f	jonatha_igor@hotmail.com	t
1076	João Guilherme Colombini Silva	Joao.Guil.xD@gmail.com	Guilherme	@		bd635174e4d3e05ad7a0d53d9204254e	t	2011-11-20 11:09:13.315219	2011-11-20 11:04:09.718925	1	1993-01-01	\N	f	Joao.Guil.xD@hotmail.com	t
3369	ANTONIO EVERTON RODRIGUES TORRES	evertonrodrigues3@hotmail.com	ANTONIO EV	\N	\N	a90c78175e9684f6865c849fc2b69757	f	\N	2012-01-10 18:25:49.071834	0	1980-01-01	\N	f	\N	f
906	Samuel Jerônimo Dantas	samueljeronimo27@gmail.com	Samuel	@samjeronimo		daacbf40ffd7e39e50aa96b32fa53cde	f	\N	2011-11-16 12:27:22.333283	1	1991-01-01	\N	f	samueljeronimo@hotmail.com	t
957	RAIMUNDO IGOR SILVA BRAGA	hunknow1337@gmail.com	Hunknow	@		e31c6bf63ba8a5afb6291153cdddfcb2	t	2011-11-17 09:25:26.428057	2011-11-17 09:17:33.923175	1	1995-01-01	\N	f		t
809	GIDEÃO SANTANA DE FRANÇA	gideaosf@gmail.com	Gideao	@		57d956497db6a547cb8ed3d1e840dd58	t	2012-01-16 17:15:32.185926	2011-11-14 16:30:35.477413	1	1993-01-01	\N	f	gideaosf@gmail.com	t
3370	ANTONIO JEFERSON PEREIRA BARRETO	russo.xxx@hotmail.com	ANTONIO JE	\N	\N	7af684c7e0b74b6d88743b06fc2ae108	f	\N	2012-01-10 18:25:49.20635	0	1980-01-01	\N	f	\N	f
2245	GILLIARD FERREIRA DA SILVA	gil.palmeiras@hotmail.com	Giliard	@		b7a8528753296124667d74d5d0a8b7b4	f	\N	2011-11-24 08:47:07.217937	1	1990-01-01	\N	f		t
907	Fernanda 	fernandaos12@gmail.com	nandaoliveira	@nandaoliveira7		5b83d8137f56d2382a770b8d2e6dffee	t	2011-11-16 12:42:50.275899	2011-11-16 12:33:34.445784	2	1983-01-01	\N	f	fernandaos12@gmail.com	t
3878	Thaís Marinho	thasmarinho@gmail.com	YunnaRulkes	@		c2b29f6f828f7f2b5d21b266037ce3e5	f	\N	2012-11-28 22:59:48.905405	2	1995-01-01	\N	f		t
1186	David Weslley Costa de Oliveira	david.weslley8@gmail.com	DeeH'Oliveira	@		701def4009bbb8b7e7ed805d310f9531	t	2012-12-07 13:28:22.249309	2011-11-21 22:43:46.856017	1	1995-01-01	\N	f	davidd_BMB@hotmail.com	t
908	EDSON RODRIGUES DE ARAUJO	edhunter_edson@hotmail.com	edhunter	@		8fdf4376c11d7fd189b92a4952be7a39	t	2011-11-22 18:20:26.676519	2011-11-16 13:36:33.509093	1	1989-01-01	\N	f	edhunter_edson@hotmail.com	t
5361	Mayke Souza	maykeboter@hotmail.com	Mayke S	@		9a8113af5edb1004651ab8d84220f14f	f	\N	2012-12-08 09:39:19.64845	0	2011-01-01	\N	f		t
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
2622	Maria Darlice Souza Lima	mac.strategia@hotmail.com	Darlice	@		ffeaa43be260b6beab731e5a4db384d4	f	\N	2011-11-26 09:10:05.808955	2	2002-01-01	\N	f		t
958	Clodoaldo Lopes Albuquerque	clodoaldo.lopes.10@hotmail.com	cloo'h	@		60bd8155c4108f08be3e6b777eaf8e5a	t	2011-11-17 09:24:37.440867	2011-11-17 09:18:13.277631	1	1995-01-01	\N	f		t
991	wilker costa da silva	wilkerlancelot@hotmail.com	lancelot	@		8fa79caaff3ebddf2f2c73ef6b34b6ec	t	2011-11-17 23:51:55.496217	2011-11-17 23:45:34.284496	1	1990-01-01	\N	f	wilkerlancelot@hotmail.com	t
1627	Adriana Maria Silva Costa	drizinha_santinha@hotmail.com	drizinha	@		32928b22f2e114ec3bd80c420d52872c	f	\N	2011-11-22 20:36:51.489825	2	1977-01-01	\N	f	drizinha_santinha@hotmail.com	t
417	IENDE REBECA CARVALHO DA SILVA	bekinha-carvalho@hotmail.com	Bekinha	@		b3e877ec7e411a70afb727db8b280c2a	t	2012-01-16 08:41:21.18171	2011-10-23 19:32:57.944197	2	1991-01-01	\N	f	bekinha-carvalho@hotmail.com	t
1883	Weslley Nojosa Costa	weslley_nojosa@hotmail.com	Weslley	@Weslley_NCosta		37d3a8e03ab5889ecaf207a8e5f02b60	f	\N	2011-11-23 12:04:31.964557	1	2011-01-01	\N	f	weslley.nojosa@facebook.com	t
1085	WALTER JHAMESON XAVIER PEREIRA	walterjhamesoon@gmail.com	walterjxp	@walterjhameson		1637b1ec40f59a00324cc634b3e890ff	t	2011-11-20 18:36:12.260926	2011-11-20 18:35:20.304783	1	2011-01-01	\N	f	walterjhamesoon@gmail.com	t
5027	Emilene Santos	emyllenesantos@gmail.com	Emilene Santos	@		25056ab15d2ad976a87a1e5c6a9e1d6e	f	\N	2012-12-06 16:54:39.118809	2	1996-01-01	\N	f	emilene_geovana_--!@hotmail.com	t
971	Halley da silva pinto	keydash_1@hotmail.com	Keydash	@		07a1097effdf7a6298a6aae5f507f5ab	f	\N	2011-11-17 10:35:18.796416	1	1985-01-01	\N	f	keydash_1@hotmail.com	t
1007	Ana Erika Rodrigues Torres	ana_erika12@hotmail.com	aninha	@anaerikaoficial		ebf09e00cc1ce2319756da7b6691ac8d	t	2012-12-25 14:06:19.741162	2011-11-18 15:42:10.729297	2	1996-01-01	\N	f		t
975	Lucas Castro de Aquino	lucacastro22@hotmail.com	Lucas Dx	@		55e9fb759e308d9ee58e28decb5ba1b8	t	2011-11-17 14:08:27.437068	2011-11-17 14:07:08.15467	1	1996-01-01	\N	f	lucacastro22@hotmail.com	t
997	Tiago Bezerra	tiago.tt@hotmail.com	sinnes7k^	@MALDITOHANTARO		13dbe1c0b967db9e33257bfd8db88fd8	t	2011-11-18 12:01:26.368528	2011-11-18 11:58:34.416165	1	1994-01-01	\N	f	tiago.tt@hotmail.com	t
1912	Paulo Sérgio	paulo.15@hotmail.com	Paulo Sérgio	@		67c00bc147d9905833e8518e199e5bb1	f	\N	2011-11-23 14:26:43.076686	1	1994-01-01	\N	f		t
981	tanila	tanila_martins6@hotmail.com	tanizinha	@tanilasilva		900bf37798631c3bb7303b3541660a45	t	2011-11-17 17:12:38.391394	2011-11-17 17:07:47.790345	2	1992-01-01	\N	f	tanila_martins6@hotmail.com	t
1708	joao vitor sena de souza	osjonathas@yahoo.com.br	joao vitor	@		14b12c553017496e28e589139ca56016	f	\N	2011-11-23 00:06:49.765183	1	2000-01-01	\N	f		t
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
1020	Gilfran Ribeiro	contato@gilfran.net	Gilfran	@Gilfran	http://blog.gilfran.net	e41e9876e54581a02d46990accf98e7c	t	2011-11-18 19:13:06.446053	2011-11-18 19:12:30.86776	1	2011-01-01	\N	f	eu@gilfran.net	t
521	JACKSON DENIS RODRIGUES DA COSTA	jacksondenisrodrigues@gmail.com	jdkitom	@		9c646f146e16ee2c5d87011e27d09125	t	2012-01-16 21:21:27.454469	2011-11-03 11:41:55.197748	1	1990-01-01	\N	f		t
1093	Deyvison Ximenes Nobre	deyvison.ximenes@hotmail.com	Ximenes	@		77c9192ac008dc696c5c2ade8aaf3b3e	f	\N	2011-11-21 00:16:13.037042	1	1996-01-01	\N	f		t
3677	Glaucivan Pereira	glaucivanp2@gmail.com	Glaucivan	@GlaucivanP		11e11f9e5036f7369395f66238eec0f4	f	\N	2012-11-26 10:03:08.037503	1	1992-01-01	\N	f		t
4435	Micael Moura	micael92mc@gmail.com	micael	@		15b3964e5716cb78014f3592e20a669b	f	\N	2012-12-04 20:31:58.808636	1	1992-01-01	\N	f	micael-mc@hotmail.com	t
996	EMMILY ALVES DE ALMEIDA	emmly_23@hotmail.com	Emmily	@		7ba100171ea3d50620063b041dd31ea5	t	2012-01-18 13:32:31.639104	2011-11-18 11:52:18.044453	2	1994-01-01	\N	f	emmly_23@hotmail.com	t
588	ERYKA FREIRES DA SILVA	eryka.setec@gmail.com	Eryka Freires	@		b8a720f7e05d9df63606d81d5004a393	t	2012-01-15 21:06:59.663283	2011-11-07 14:51:05.549578	2	1990-01-01	\N	f		t
3375	CARLOS ADAILTON RODRIGUES	adtn700@yahoo.com.br	CARLOS ADA	\N	\N	e49b8b4053df9505e1f48c3a701c0682	f	\N	2012-01-10 18:25:52.341918	0	1980-01-01	\N	f	\N	f
980	EUGENIO REGIS PINHEIRO DANTAS	regis_dant@hotmail.com	regisdantas	@		77744b4b713115f77d4aa39ae385eabb	t	2012-01-19 16:22:02.058001	2011-11-17 16:05:51.390327	1	1984-01-01	\N	f		t
3376	CARLOS YURI DE AQUINO FAÇANHA	c_yuri13@hotmail.com	CARLOS YUR	\N	\N	40805b9b0fb1ae92ff692eebef39f9c5	f	\N	2012-01-10 18:25:54.482031	0	1980-01-01	\N	f	\N	f
1176	José Smith Batista dos Santos	josesmithbatistadossantos@gmail.com	sumisu	@sumisu_sama		d66b468c43e7f616ae277bbf2bfb2d91	t	2011-11-21 21:02:14.979246	2011-11-21 20:57:53.617105	1	1992-01-01	\N	f	josesmithbatistadossantos@gmail.com	t
1053	Elizabeth da Paz Santos	ame.uchiha@gmail.com	Beth Santos	@BethUchiha		b4c61caaf5c055e1cda928a6f72b2400	t	2012-11-30 16:22:41.02089	2011-11-19 14:38:02.751172	2	1992-01-01	\N	f	ame.uchiha@gmail.com	t
533	Hannah Leal Rabelo	hannah.rabelo@gmail.com	hannah	@hannahrabelo		ab2e739265bcfc7abf996c0fb0569e66	t	2012-01-19 20:46:02.699387	2011-11-03 23:32:22.421281	2	1990-01-01	\N	f	hannah.rabelo@gmail.com	t
4200	Eudijuno Scarcela Duarte	eudijuno@hotmail.com	eudijuno	@		0d8ca6218c721cb50456a04962c42223	f	\N	2012-12-01 23:20:08.950358	1	2011-01-01	\N	f	eudijuno@hotmail.com	t
4242	Rayane	rayane_be@hotmail.com	Kelvelle	@		74a12e97cc9e725f15afc4dba877d74c	f	\N	2012-12-03 11:41:39.178598	2	1993-01-01	\N	f	rayane_be@hotmail.com	t
1003	Andre Luiz G de Araujo	andinformatica@yahoo.com.br	AndreLuiz	@		32f00e32f91c784f2cb7e474d15ee943	t	2011-11-19 08:58:48.880323	2011-11-18 15:00:32.561228	1	1975-01-01	\N	f		t
4328	Cleuson Bergson Ferreira Da Silva	bergsonsilva_contato@hotmail.com	Bergson Silva	@		06b985a40949f24def9e9a5f00f5d282	f	\N	2012-12-03 22:25:15.77559	1	1992-01-01	\N	f		t
1047	Raíssa Aragão Araújo	rhay.araujoo@hotmail.com	pequena	@littlerhaay		9691237d3c9f75dc731365f5b36aa2c7	t	2011-11-19 11:58:25.370188	2011-11-19 11:55:23.250087	2	1994-01-01	\N	f	rhay.araujoo@hotmail.com	t
1371	Rafael Oliveira	rafael@originaldesigner.com.br	Grande Rafa	@portaloriginal	http://www.originaldesigner.com.br	c9ef12a98b0f57e1e8da9ade8508884e	f	\N	2011-11-22 12:25:26.179948	1	1986-01-01	\N	f		t
1463	Breno Barroso Rodrigues	breno_barroso12@hotmail.com	brenin	@breno_barroso		f48a113d40974b677454331d52185a02	t	2011-11-22 16:56:34.37981	2011-11-22 16:55:34.66119	1	1995-01-01	\N	f		t
3378	CLAYTON BEZERRA PRIMO	claytonbp@oi.com.br	CLAYTON BE	\N	\N	4a6f57c68f8280a164ea0b2782e82a8f	f	\N	2012-01-10 18:25:55.85234	0	1980-01-01	\N	f	\N	f
1051	Franklin Gonçalves Rodrigues	franklin201121@hotmail.com	frankl	@		6fef42b707ee98f3e32b283a12db402a	t	2011-11-19 12:48:28.42001	2011-11-19 12:43:38.354197	1	1991-01-01	\N	f	franklin201121@hotmail.com	t
1123	Tiago Bezerra Sales de Almeida	tiagosales9@gmail.com	Tiaguito	@LeTiaguito		1bc427198b055c38357079e27206b2f4	t	2011-11-21 12:44:00.678931	2011-11-21 12:40:11.500147	1	1988-01-01	\N	f	tiagosales9@gmail.com	t
346	wesley jorge gomes de souza	millenium_guitar@hotmail.com	wesley loureiro	@		b5ee046698134ded6c1f923048345d48	t	2011-11-19 14:17:13.155471	2011-10-17 14:12:02.954796	1	1988-01-01	\N	f		t
1184	André Victor de Souza Siqueira	elyson_011@hotmail.com	André	@		b8f8bee7c9e40eb003b1b101bdb4a3c6	t	2011-11-21 22:47:29.746188	2011-11-21 22:43:14.572852	1	2011-01-01	\N	f		t
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
590	FRANCISCO ANDERSON FARIAS MACIEL	andersonfariasm@gmail.com	Anderson	@		05810f068168bc1d19180fb8cd04025e	t	2012-01-14 22:46:02.764721	2011-11-07 16:39:33.317404	1	1991-01-01	\N	f	andersonfariasm@gmail.com	t
848	sarah batista	sarahcharmyebarros@hotmail.com	sarah batista	@sarahbcosta		2e2d3638154696e88cf1d5720ffccf08	t	2011-11-19 18:18:36.189696	2011-11-15 23:27:46.407396	2	2011-01-01	\N	f	sarahcharmyebarros@hotmail.com	t
1373	Julian	julianleno@gmail.com	Julian Leno	@JulianLeno	http://www.dizaew.com.br	d5c149cfc0c886c62cc6c25f9c90fd00	t	2011-11-22 12:50:13.136692	2011-11-22 12:44:47.553269	1	1991-01-01	\N	f	julianleno@gmail.com	t
1080	mayara mesquita santiago	mazinha29_@hotmail.com	mazinha	@		09694b0ca4dd9da622b224e2d597ee32	f	\N	2011-11-20 15:00:00.885451	2	1992-01-01	\N	f	mazinha29_@hotmail.com	t
3384	DANIEL JEAN RODRIGUES VASCONCELOS	cefet_daniel@yahoo.com.br	DANIEL JEA	\N	\N	71442b689327b3d764432f32b4d4accd	f	\N	2012-01-10 18:25:56.724311	0	1980-01-01	\N	f	\N	f
4732	Lucas reinaldo cavalcante	lucasreinaldocavalcante@gmail.com	Reinaldo	@		2c5eaf6c7062bca4cfbd2c7a02d93ef1	f	\N	2012-12-05 21:37:02.371829	1	1994-01-01	\N	f		t
1595	Isabela Amnoá Medeiros Sampaio	isabelamnoa.tech@live.com	Bella, Bel	@IsabelaAmnoa		d9f455da70a52573114fec6306b6dc36	t	2012-12-08 10:24:16.237137	2011-11-22 18:43:42.246824	2	1995-01-01	\N	f	isabelamnoa.tech@live.com	t
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
1140	ANTONIA CLEITIANE HOLANDA PINHEIRO	cleitypinheiro_wonderfulgirl@hotmail.com	cleity	@		4e0cd06b506c380409411a6cc2dd0145	f	\N	2011-11-21 16:08:04.823754	2	1994-01-01	\N	f	cleitypinheiro_wonderfulgirl@hotmail.com	t
1161	Ingrid de Oliveira Magalhães	gridkat@msn.com	Gridzinha	@		a8eec21667e33fcc23697c1611e04603	t	2011-11-21 19:04:24.781869	2011-11-21 18:59:58.132323	2	1994-01-01	\N	f	gridkat@msn.com	t
1018	ANTONIO RENAN ROGERIO PAZ	antoniorenan@pmenos.com.br	ANTONIO RENAN	@		4f33d3d9334bd11f40b9ed5319ba2f96	t	2012-01-15 18:15:28.639824	2011-11-18 18:53:50.91309	1	1985-01-01	\N	f	ananerrp@hotmail.com	t
5398	Cosme Henrique Silva	cosme_203@hotmail.com	cosmehenrique	@		f8110fdf00d8bde3164941902386c409	f	\N	2012-12-08 10:28:23.139626	1	1995-01-01	\N	f		t
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
749	Darlilson Lima	darlildo.cefetce@gmail.com	Darlilson	@		22090a4fb9d65a6cedf855c949b8d405	t	2012-11-21 12:34:31.479081	2011-11-11 15:51:56.612032	1	2000-01-01	\N	f		t
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
3634	Mateus da Silva Páscoa	pascoamateus12@gmail.com	Páscoa	@		4004dfcf735cf0260464a19eac763954	f	\N	2012-11-22 22:38:57.26307	1	1996-01-01	\N	f	mateus.pascoa@hotmail.com	t
998	CÍCERO JOSÉ SOUSA DA SILVA	c1c3ru@hotmail.com	cicero	@		e14005106bd0e03ea0056e5e38d8a220	t	2012-01-10 18:25:55.619703	2011-11-18 12:08:46.954662	1	1984-01-01	\N	f		t
1599	Jéssica Samanta Silva Santos	samantinha.santos@yahoo.com.br	samantinha	@		ba48a6103fe019c08b4f862ee9c3eb78	t	2011-11-22 19:11:30.772032	2011-11-22 18:57:14.420231	2	1995-01-01	\N	f		t
3666	Rui Carlos Santos	ruicarlos3g.rc@gmail.com	Carlos	@		d369e5300b72db59dcc6e27834c393c9	f	\N	2012-11-25 00:55:23.168124	1	1990-01-01	\N	f		t
5362	Rafael nunes de castro	rafael_ncastro@yahoo.com.br	rafael	@		ea1f84fca6b6380dd3cb59d9049cf334	f	\N	2012-12-08 09:41:43.120365	1	1987-01-01	\N	f	rafael_ncastro@yahoo.com.br	t
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
1671	Gisele Silveira Lima	giselesilveira_bc@hotmail.com	gisele	@gigisilveira8		bcea9fc633c7f7f38797e1e6ba46c09b	t	2011-11-22 21:44:38.783359	2011-11-22 21:41:18.298224	2	1992-01-01	\N	f	giselesilveira_bc@hotmail.com	t
2574	Wendel Sousa Terceiro	wtesousatrcenro@yahoo.com.br	Wendel	@		dce94b693322e6bebaebd55b9237232b	f	\N	2011-11-25 13:55:39.849006	1	1952-01-01	\N	f		t
1762	Davi Alves Leitao	davi_alle@hotmail.com	leitao	@		ac0f56fed9921e64d84d8f1057e8fdba	f	\N	2011-11-23 09:34:28.063544	1	1994-01-01	\N	f	davialle@hotmail.com	t
1929	charl gabriel tavares rodrigues 	charllygabriel99@hotmail.com	charlly	@		31d09e544e8900f5b974fa592fb8e0c4	f	\N	2011-11-23 14:44:04.486097	1	2011-01-01	\N	f		t
2253	Valdeci Almeida Filho	valdecifilho21@gmail.com	valdeci	@		63301a337e4dcc67264397ce00e4748e	f	\N	2011-11-24 09:21:15.181852	1	2011-01-01	\N	f		t
2268	Ana Kelly Rodrigues Miranda	anakelly.rodrigues08@gmail.com	Kellynha	@		4c84a20d9123c23433256197ad299e11	f	\N	2011-11-24 10:07:25.992875	2	1996-01-01	\N	f	anakelly.rodrigues08@gmail.com	t
1350	Leonardo Sousa 	marcelaborges2000@hotmail.com	Leonardo	@		2947c2b9b06ca45f9a02733464944481	f	\N	2011-11-22 11:30:00.556066	1	1997-01-01	\N	f		t
315	CARLOS ANDERSON FERREIRA SALES	saycor_13_gpb@hotmail.com	Desordem	@AndersonNimb		06e23bf3b9a133d5459c1da743989aa7	t	2012-01-10 18:25:53.657326	2011-10-14 18:00:57.379024	1	2011-01-01	\N	f	saycor_13_gpb@hotmail.com	t
1795	Victor Lucas Amora Barreto	victor_lukaslol@hotmail.com	Victor Lucas	@		afc7bdbc54b83c03beaeec880103194e	f	\N	2011-11-23 10:24:31.22203	1	1995-01-01	\N	f		t
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
2153	Lyndainês Araújo dos Santos	lyndainesaraujo@gmail.com	Lyndainês	@		7a260cf391343c3b53e365539e405591	f	\N	2011-11-23 18:37:18.744443	2	2009-01-01	\N	f		t
2269	Rodrigo Câmara Guimarães	rodrigo.camara23@gmail.com	Rodrigues	@		df47a8ca5f96e3d5d591c0a9331a3e3b	f	\N	2011-11-24 10:08:42.336673	1	1994-01-01	\N	f		t
1424	Monique dos Santos Girão	moniqueegirao@gmail.com	Monique	@		121e194fdb4955c2ee393af445030565	f	\N	2011-11-22 16:42:59.232646	2	1993-01-01	\N	f		t
1601	Feleciano	frandiascosmetico@hotmail.com	Samurai b-boy	@		0b08eb548c012c7a1693537bb9a9bb7b	f	\N	2011-11-22 19:09:18.13288	1	1997-01-01	\N	f		t
817	AMANDA AZEVEDO DE CASTRO FROTA ARAGAO	amandazevedo_@hotmail.com	amanda	@amandazvd		c3b4bef3f323af9c4d8d23d0d78e73b4	t	2012-01-10 18:25:43.440049	2011-11-14 22:05:00.779498	2	1994-01-01	\N	f	amanda.azevedo3@facebook.com	t
1636	guilherme da silva braga	heavyguill@gmail.com	espectro	@		6bc8d3d21811203d8c80c682d5a53a1c	t	2011-11-22 21:17:33.452829	2011-11-22 20:48:08.815847	1	1991-01-01	\N	f		t
1421	Helen Raquel Frota Pessoa	helenraquel.info@gmail.com	Helen Raquel	@helenraquel		c9145fc1bbff065ac8acdd3f86709ed1	t	2011-11-22 16:43:12.589748	2011-11-22 16:42:27.159962	2	1983-01-01	\N	f	helen.raquel@hotmail.com	t
1426	João Victor Evangelista da Silva	jvictor.info@gmail.com	João Victor	@		2344edf44aac5bd68db726fb05f3de25	f	\N	2011-11-22 16:43:30.795043	1	1995-01-01	\N	f	jvtoc@hotmail.com	t
4019	Isabele Cristina Silva Vicente	isabelecristinasv@gmail.com	Bellynha	@		c8c5877ac347f6cf1024d4becaff2c74	f	\N	2012-11-29 21:40:43.686082	2	1993-01-01	\N	f	isabelecristinasv@gmail.com	t
3653	Raissa Leandro de Sousa	raissasousa1994@hotmail.com	Raissa	@Raiissa21		c2eac4e9a62017852bfed306d3692e01	f	\N	2012-11-23 23:31:34.1705	2	1994-01-01	\N	f	raissa.sousa.14@facebook.com	t
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
5028	gecian moreira	gecianmoreira@gmail.com	gecian	@		b154e6beca55df8dd1a3d2ca56e30461	f	\N	2012-12-06 16:54:57.398274	1	1996-01-01	\N	f	gecian@hotmail.com	t
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
1942	Pedro Henrique Freitas do Nascimento	pedro-tj2011@hotmail.com	pedroph	@		e8fafce85b7eb600d51a64f5a782efd3	f	\N	2011-11-23 14:51:02.233675	1	1995-01-01	\N	f	pedrohenrique95@hotmail.com	t
2220	Maria Elissandra Cosme da Silva	elissandraoc@gmail.com	Elissandra	@		92bc5f33b8f42923068d1c55592a8b7a	f	\N	2011-11-23 22:25:54.787909	2	1993-01-01	\N	f	elissandra_sss@hotmail.com	t
2155	Ian do Carmo Marques	ian.icm.gato.gaiato@gmail.com	Marck's	@		8bcd1f3ae90bb4a27b0ad2eb3619fd9e	f	\N	2011-11-23 18:39:36.595274	1	2009-01-01	\N	f		t
2550	lucas filho	lucascoe@gmail.com	licas..	@		0823c651f543efee873c7ca4bd3c3106	f	\N	2011-11-25 09:41:52.98039	1	1975-01-01	\N	f		t
2576	Giovana Rodrigues de Castro	gilcastro09@gmail.com	giovana	@		d50b961ac445b59feb146f63629b47d8	f	\N	2011-11-25 14:16:01.231377	2	2002-01-01	\N	f		t
1454	Felipe da Silva Vitaliano	felipevitaliano@gmail.com	Felipe	@		0084333ecca3222afd04a621aa0a5b86	f	\N	2011-11-22 16:51:56.119008	1	1993-01-01	\N	f		t
689	ADONIAS CAETANO DE OLIVEIRA	adoniascaetano@gmail.com	Adonias	@		2aaf68ba90f209eba80cd25662bb7e29	t	2012-01-14 19:29:06.225327	2011-11-10 16:06:03.543246	1	1989-01-01	\N	f	adoniascaetano@gmail.com	t
1455	Ernane	ernanespedalada@gmail.com	Pedalada	@		886eb8f05275bf3dec29230fb6af8e4f	f	\N	2011-11-22 16:52:19.814519	1	1992-01-01	\N	f	ernanespedalada@gmail.com	t
3591	VIVIANE DA COSTA PEREIRA	ifce.maraca26@ifce.edu.br	VIVIANE DA	\N	\N	5e9f92a01c986bafcabbafd145520b13	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
4329	Ronaldo Brito Sombra	ronaldolindo26@hotmail.com	Naldinho	@		4aba1dc0741a37439fb82f0320d6a2e8	f	\N	2012-12-03 22:58:46.695268	1	1997-01-01	\N	f	ronaldodebritto@hotmail.com	t
1446	JOELSON FREITAS DE OLIVEIRA	JHOELSONMD@HOTMAIL.COM	JOELSON	@		e33a5420bbd7000c93bcdd216ddef06c	t	2011-11-22 16:53:41.769875	2011-11-22 16:49:03.140358	1	1992-01-01	\N	f		t
1456	Rômulo Nobre	romulo.nobre@hotmail.com	Rômulo	@		c8e1d17f96a0a147885b1338b8d19b35	f	\N	2011-11-22 16:52:36.368072	1	1995-01-01	\N	f	romulo.nobre@hotmail.com	t
1953	Davi Távora Herculino	brenobarroso12@gmail.com	Davi .I.	@		391361a7a4f2b07b9c2719a710297955	f	\N	2011-11-23 14:54:39.779299	1	1996-01-01	\N	f		t
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
2577	Wesley rodrigues de castro	wesley.castrowesley@gmail.com	wesley	@		bb655d17a914bf4b13634ce48a324887	f	\N	2011-11-25 14:16:28.422785	1	1999-01-01	\N	f		t
2156	Fabiana Sousa do Nascimento	fabianapink2010@hotmail.com	Fabý Garraway	@		c166eda9a827dc7ddaf29f68b76c2f54	f	\N	2011-11-23 18:40:54.815059	2	2009-01-01	\N	f		t
2239	Kerliane Cavalcante Pereira	kerlianecavalcante15@hotmail.com	Kerliane	@Kerliane		919f15acdb924f0a2ea1347d699b7600	f	\N	2011-11-24 01:00:33.942468	2	1991-01-01	\N	f	kerlianecavalcante15@hotmail.com	t
2284	Anderson Gomes Andrade	andersongomes660@hotmail.com	Anderson	@		474330852154523cb8c7238ada16eba4	f	\N	2011-11-24 10:13:55.42899	1	1994-01-01	\N	f		t
2598	Felipe da Silva Nascimento	bboylipe04@gmail.com	felipe	@		59aa0ee14c848363d960e5d81b4fdf34	f	\N	2011-11-25 16:39:27.831036	1	1992-01-01	\N	f		t
1571	karolaine matos de moraes	x.k.r.karol@email.com	karolzinha	@		00bbf9f6b61c01da0088e46dff7443ed	f	\N	2011-11-22 17:37:31.140852	2	1994-01-01	\N	f	x.k.r.karol@email.com	t
3592	WILKIA MAYARA DA SILVA NEVES	ifce.maraca27@ifce.edu.br	WILKIA MAY	\N	\N	ef4e3b775c934dada217712d76f3d51f	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
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
2647	Samael Lucas de Sousa Mendes	samaellucas@hotmail.com	Samael	@		8bc55ea6f516956ca22662b9551ab972	f	\N	2011-11-26 13:26:33.889628	1	1997-01-01	\N	f		t
1742	ADRIANA MARA DE ALMEIDA DE SOUZA	adrianayhrar@gmail.com	adriana	@		0defbc285776190c18d8a9ef72810b8b	f	\N	2011-11-23 09:29:39.375324	2	1991-01-01	\N	f	adrianayhrar@hotmail.com	t
1777	Aliane Nascimento	nascimento.aliane@gmail.com	Lianaa	@		9fd2bc7e94767531f0200aeee408cac8	f	\N	2011-11-23 10:13:14.546483	2	2011-01-01	\N	f	nascimento.aliane@gmail.com	t
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
3857	José 	jose.victor.sa.santos@gmail.com	Victor	@		4fb1ca94f04408669256de4a1512d9b0	f	\N	2012-11-28 21:40:51.033241	1	1997-01-01	\N	f	jose.victor21@hotmail.com	t
1924	Charles Luis Castro	charles_139@hotmail.com	charles timão	@		a6012c5034cd7a69026723fcee84d3e4	f	\N	2011-11-23 14:40:13.987459	1	1994-01-01	\N	f	charles_139@hotmail.com	t
2199	winston bruno	winstonbruno@gmail.com	winston bruno	@		1862990a5aaab5bf6f50f9f85205e534	f	\N	2011-11-23 20:35:18.034381	1	2011-01-01	\N	f		t
3572	DIEGO SOARES DA SILVA	ifce.maraca7@ifce.edu.br	DIEGO SOAR	\N	\N	202cb962ac59075b964b07152d234b70	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
3693	Margleyck Rabelo	margleyck@hotmail.com	Margleyck	@		538fb2a14bef4a2bb72c6ec5f2be85db	f	\N	2012-11-26 21:42:58.63044	1	1992-01-01	\N	f	margleyck@hotmail.com	t
1757	pedro henrique de macedo sobrinho	ph-pedro-henri@hotmail.com	pedrinho	@phenrique_21		8ca6a4065fc22b582a89fe1db58e9777	f	\N	2011-11-23 09:33:01.454877	1	1994-01-01	\N	f		t
4021	franciberg ferreira de lima	warlockgood@gmail.com	frcberglima 	@		6ae2e4eb7f71b65973fb0e0ec309ab3a	f	\N	2012-11-29 21:43:21.619455	1	1993-01-01	\N	f		t
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
3696	Thaynan dos Santos Dias	nauhandias@hotmail.com	Thaynan	@		185b0cc4cb2497bcdbc52ff624a1c238	f	\N	2012-11-26 22:54:14.231247	2	1996-01-01	\N	f		t
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
3579	GÉFRIS DE LIMA PEREIRA	ifce.maraca14@ifce.edu.br	GÉFRIS DE	\N	\N	f90f2aca5c640289d0a29417bcb63a37	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
1874	Wesley Henrique Santos da Silva	tec.wesleyhenrique@hotmail.com	Wesley	@		e184646d78137b956d08847e34bbbc8b	f	\N	2011-11-23 11:54:51.066702	1	1986-01-01	\N	f		t
2201	kevin Batista 	kevinho1717@hotmail.com	pintão.pp	@		97b1ed2f1da57ee30d0861ddaef240a0	f	\N	2011-11-23 20:43:33.639225	1	1996-01-01	\N	f	charllygabriel99@hotmail.com	t
3580	JOÃO FELIPE SAMPAIO XAVIER DA SILVA	ifce.maraca15@ifce.edu.br	JOÃO FELI	\N	\N	d96409bf894217686ba124d7356686c9	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
1875	JOSE ANDERSON FERREIRA MARQUES	js_andersonn@yahoo.com.br	Anderson Marques	@js_anderson10		aea67406eb68045e1434c81ad4b2fa33	f	\N	2011-11-23 11:55:12.284905	1	1989-01-01	\N	f		t
3581	JOÃO RAPHAEL SILVA FARIAS	ifce.maraca16@ifce.edu.br	JOÃO RAPH	\N	\N	819f46e52c25763a55cc642422644317	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
3667	Douglas Silva	douglas.silva30@ymail.com	dougts	@dougts	http://dougts.blogspot.com/	8a082021ecd4db48d7926eab02a7e301	f	\N	2012-11-25 01:34:24.405392	1	1993-01-01	\N	f	douglas.silva30@ymail.com	t
1910	Priscila Nunes  de Sousa	pris_cila280@hotmail.com	pandora	@		30fcd575ec6a2544694b9da5d695e849	f	\N	2011-11-23 14:04:59.099455	2	1991-01-01	\N	f	pris_cila130@hotmail.com	t
1877	Antonia Merelania Silva Pereira	merynha_sp@hotmail.com	Merynha	@		43dc41476484bcecda699cdd3ea9a47e	f	\N	2011-11-23 11:59:30.892871	2	1992-01-01	\N	f	merynha_sp@hotmail.com	t
2130	Eliando Pereira Silva	nanndin@yahoo.com.br	Nanndin	@		6de4d141a7273565f41ece711bb51e44	f	\N	2011-11-23 18:02:40.458196	1	1986-01-01	\N	f	nanndin@yahoo.com.br	t
1938	Thiago Alves de Sousa	thiago.alves83@yahoo.com.br	FideKenga	@		8b1377d7dada5c0f32afab0bfeb9edb6	f	\N	2011-11-23 14:49:13.933116	1	2011-01-01	\N	f		t
2307	geisiane tavares gomes	geisitavares@gmail.com	geise.	@		c679ca74a4c7017745da6292ff6f7da4	f	\N	2011-11-24 10:42:22.278186	2	1997-01-01	\N	f		t
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
5363	Andresa Sousa Santos 	dresa_4ever@hotmail.com	Dresa4ever	@		abacb7985f836f1f8a8a138c7c0ed11b	f	\N	2012-12-08 09:45:30.396489	2	2011-01-01	\N	f		t
3583	JOSÉ TUNAY ARAÚJO	ifce.maraca18@ifce.edu.br	JOSÉ TUNA	\N	\N	45c48cce2e2d7fbdea1afc51c7c6ad26	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
1898	ALEXSANDRO KAUÊ CARVALHO GALDINO	carvalho_3331@hotmail.com	akcg20	@		a6be88d7bf4394c93ff84b52c2dcc794	f	\N	2011-11-23 12:56:58.103421	1	2011-01-01	\N	f		t
1927	Daniel vasconcelos da silva 	danielsolteirao2010@hotmail.com	Dielzinho	@		d1622c8533183a1b597a59c4476685d0	f	\N	2011-11-23 14:43:23.239681	1	1993-01-01	\N	f		t
3391	DENYS ABNER SANTOS BEZERRA	denys_abner@hotmail.com	DENYS ABNE	\N	\N	3ef815416f775098fe977004015c6193	f	\N	2012-01-10 18:25:58.344458	0	1980-01-01	\N	f	\N	f
3584	JULIANA BARROS DA SILVA	ifce.maraca19@ifce.edu.br	JULIANA BA	\N	\N	605ff764c617d3cd28dbbdd72be8f9a2	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
3585	MICHELE XAVIER DA SILVA	ifce.maraca20@ifce.edu.br	MICHELE XA	\N	\N	577ef1154f3240ad5b9b413aa7346a1e	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
3392	DIEGO ALMEIDA CARNEIRO	diegoo_ac@hotmail.com	DIEGO ALME	\N	\N	1ffb8a29dc0f1f707387ca849c26c15b	f	\N	2012-01-10 18:25:58.622743	0	1980-01-01	\N	f	\N	f
3586	PATRICIA PAULA FEITOSA COSTA	ifce.maraca21@ifce.edu.br	PATRICIA P	\N	\N	02e74f10e0327ad868d138f2b4fdd6f0	f	\N	2012-01-20 12:31:22.739814	0	1980-01-01	\N	f	\N	f
4437	Felipe dos Santos Souza	twitterfelipe@gmail.com	Fezito	@fezithu		1e646bc2e3f9a3e734e35609fe389e5c	f	\N	2012-12-04 20:55:54.617964	1	1991-01-01	\N	f	yuyupapara@gmail.com	t
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
2034	ALEFE FEIJAO UCHOA DOS SANTOS	alefefeijao@hotmail.com	ALEFE DOS SANTOS	@		5a64340cd0d9e3e979eba59a5580322f	f	\N	2011-11-23 16:03:12.651504	1	1994-01-01	\N	f		t
3565	VIVIANE FERREIRA ALMEIDA	viviane.fe.almeida@gmail.com	VIVIANE FE	\N	\N	10b3742990747e371721ed390dfc31c1	f	\N	2012-01-19 15:55:08.314743	0	1980-01-01	\N	f	\N	f
4225	Cristiane Morais	cristianemorais.1992@hotmail.com	cristiane	@		e300171d6cdfefd1d69b2df33698e6b3	f	\N	2012-12-03 09:53:22.412741	2	1992-01-01	\N	f		t
2529	Fabíola da Silva Costa	fabiolasilvainformatica@gmail.com	Babiizinha	@		e75e1101901053b1040b2f7309214904	f	\N	2011-11-24 21:59:26.180618	2	1994-01-01	\N	f	fabiola_festa15@hotmail.com	t
2489	Jeanne Darc de Oliveira Passos	passosjeanne@yahoo.com.br	Jeanne	@		b48d71b76aaa91e7445bb6b7f273b6a4	f	\N	2011-11-24 18:56:58.354307	2	1979-01-01	\N	f	jeanne_passos@hotmail.com	t
2631	Sara Wandy Virginio Rodrigues	sarawandy_10@hotmail.com	sara wandy	@		793729eff410397a1a4cc42b0b66aa72	f	\N	2011-11-26 10:12:06.717735	2	1991-01-01	\N	f		t
2228	Erislaine do Nascimento Alves	eris-alves@hotmail.com	Erislaine	@eriiiss		bac33bc725edf6cfa45c426326ea3a85	f	\N	2011-11-23 23:35:01.483787	2	1992-01-01	\N	f	eris-alves@hotmail.com	t
2037	MARIA SULAMITA DOS SANTOS SALES	sulamitasantos_sales@hotmail.com	SULAMITA	@		d7aaf186b7f6f6064b0628d24722e1e0	f	\N	2011-11-23 16:10:54.552586	2	1995-01-01	\N	f		t
3885	Uranistude	uranistude@gmail.com	Uranistude	@		80acad9e7cc7247ea304b4ad3902ecf3	f	\N	2012-11-29 00:24:15.555335	1	1970-01-01	\N	f		t
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
4330	matheus vitor	matheusviitor@hotmail.com	matheus	@		dd104bcf285382a27fa4bfd4324dc9c3	f	\N	2012-12-04 00:05:27.548715	1	1996-01-01	\N	f	matheusviitor@hotmail.com	t
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
2346	Jefferson Luis Alves	gt_jefferson@hotmail.com	Jefferson	@		5dd8b2f88d2cba8b27f9f3a4a98899e8	f	\N	2011-11-24 11:23:10.003884	1	1995-01-01	\N	f		t
2348	paulo victor dos santos bezerra	paulobezerra31@gmail.com	baliado	@		d9ee971f4834cb5e04c2e6204e6bcd0b	f	\N	2011-11-24 11:25:27.474553	1	1994-01-01	\N	f	paulobezerra31@gmail.com	t
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
5029	Rodrigo araújo Barros	rodrigoaraujokarate@hotmail.com	Rodrigo	@		1f8de8b10c2880ad3220cffe34e368ba	f	\N	2012-12-06 16:56:55.707512	1	1996-01-01	\N	f		t
5065	Antonio Flavio da Silva Oliveira	afsoliveira2013@gmail.com	Flavio	@		e7fec23b96cae9fe3c9eb988d36f46f1	f	\N	2012-12-06 19:43:50.534135	1	1994-01-01	\N	f	flaviotimao@hotmail.com.br	t
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
3430	ISAAC THIAGO OLIVEIRA CAVALCANTE	isaaccavalcante@ymail.com	ISAAC THIA	\N	\N	86ebb61cbb35df79d2227147269fb7e9	f	\N	2012-01-10 18:26:10.538973	0	1980-01-01	\N	f	\N	f
3431	ISRAEL SOARES DE OLIVEIRA	genina102010@hotmail.com	ISRAEL SOA	\N	\N	7fa732b517cbed14a48843d74526c11a	f	\N	2012-01-10 18:26:10.867507	0	1980-01-01	\N	f	\N	f
3432	ITALO MESQUITA VIEIRA	italo_mbs@hotmail.com	ITALO MESQ	\N	\N	6602294be910b1e3c4571bd98c4d5484	f	\N	2012-01-10 18:26:11.373675	0	1980-01-01	\N	f	\N	f
3433	IVNA SILVESTRE MONTEFUSCO	ivna.silvestre@hotmail.com	IVNA SILVE	\N	\N	38b3eff8baf56627478ec76a704e9b52	f	\N	2012-01-10 18:26:11.648033	0	1980-01-01	\N	f	\N	f
3434	JAMILLE DE AQUINO ARAÚJO NASCIMENTO	jamilles2@hotmail.com	JAMILLE DE	\N	\N	1068c6e4c8051cfd4e9ea8072e3189e2	f	\N	2012-01-10 18:26:11.887457	0	1980-01-01	\N	f	\N	f
2360	José Maria da Paz	josemaria.paz@gmail.com	José Maria	@		1bbf870ef1500fd949c430ce04952abb	f	\N	2011-11-24 11:59:38.376154	1	1989-01-01	\N	f		t
2570	FRANCISCO ROGER GARCIA DE ALMEIDA	frogergarci@gmail.com	Lodger	@		22e5b41cc90b74a2dcfa87b3b131374e	f	\N	2011-11-25 11:42:53.374068	1	2011-01-01	\N	f	rogergarci@live.com	t
5364	José Aldair Paulino do Nascimento	paulinoaldair@gmail.com	aldairp	@		b6737bb6f1dbd53de58286acb24c3e7f	f	\N	2012-12-08 09:46:08.715435	1	1995-01-01	\N	f	aldair_2014love@hotmail.com	t
2534	Ingrid Nascimento dos Santos	fabiola_festa15@hotmail.com	Ingrid	@		db762d52589fcaab99d04868adad9d92	f	\N	2011-11-24 22:24:39.223223	2	1995-01-01	\N	f		t
3791	Francisco Elvis dos Santos Pereira	elvisdossantoss@gmail.com	Elvis dos Santos	@		2a220718b2d03be1f9313f681b57e038	f	\N	2012-11-27 21:01:59.749775	1	1990-01-01	\N	f	elvisdossantoss@gmail.com	t
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
4733	Raynara Macklly Arruda dos Santos	raynaramacklly@gmail.com	raynara	@		7f21ebefd40c7c905ff790771b2b6f75	f	\N	2012-12-05 21:37:52.835892	2	1994-01-01	\N	f		t
2664	BRUNO DEYSON BRAGA COSTA	nAOTEMEMAIL@GMAIL.COM	BRUNO DEYSON	@		7191eaeea16aa9ad268f823d4a003e29	f	\N	2011-11-26 14:49:02.050652	1	1993-01-01	\N	f		t
2479	brena araujo de mesquita	brenahtasapeka@hotmail.com	brennynha	@		113a6c5a81d30b85a8297e444ce92a01	f	\N	2011-11-24 18:35:06.454401	2	1996-01-01	\N	f		t
2657	Romário Santos de Abreu	romario.santos12@yahoo.com	romario	@		16fea7104bc868bc9acd678ddc1b00cd	f	\N	2011-11-26 14:22:43.263653	1	1990-01-01	\N	f		t
3435	JARDEL DAS CHAGAS RODRIGUES	jardel_19@hotmail.com	JARDEL DAS	\N	\N	1ff1de774005f8da13f42943881c655f	f	\N	2012-01-10 18:26:11.987972	0	1980-01-01	\N	f	\N	f
2368	Andrey Araujo Vera Cruz	andreyveracruz@hotmail.com	Andrey	@		a646dea12c22d82e35d24e584b57553b	f	\N	2011-11-24 12:02:58.752654	1	1992-01-01	\N	f		t
5399	Ana Alice Ximenes Mota	analice1995@gmail.com	Ana Alice	@		5e1809c69e546497737801427501101c	f	\N	2012-12-08 10:28:33.429015	2	1995-01-01	\N	f		t
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
3441	JOÃO GUILHERME COLOMBINI SILVA	joao.guil.xd@gmail.com	JOÃO GUIL	\N	\N	57dcf983365b98c0fb798ab8dbf79b7a	f	\N	2012-01-10 18:26:14.443498	0	1980-01-01	\N	f	\N	f
5425	Ana Kecia Silva Melo	keciacind@hotmail.com	Ana Kecia	@		045f378af0ff464472d894eb037b6171	f	\N	2012-12-08 12:31:59.219241	2	1996-01-01	\N	f		t
2376	katryna santos da silva	katryna-ss1@live.com	katryna	@		a246159c7e26fbc942129337f7e3b7b3	f	\N	2011-11-24 12:04:37.917846	2	1992-01-01	\N	f		t
3438	JESSIMARA DE SENA ANDRADE	jessimara@oi.com.br	JESSIMARA 	\N	\N	53e3a7161e428b65688f14b84d61c610	f	\N	2012-01-10 18:26:13.693546	0	1980-01-01	\N	f	\N	f
3439	JHON MAYCON SILVA PREVITERA	j_may_con@hotmail.com	JHON MAYCO	\N	\N	45fbc6d3e05ebd93369ce542e8f2322d	f	\N	2012-01-10 18:26:13.917418	0	1980-01-01	\N	f	\N	f
3440	JOÃO GOMES DA SILVA NETO	joao.gsneto@gmail.com	JOÃO GOME	\N	\N	bf9e9339255666283a63d773685e6d79	f	\N	2012-01-10 18:26:14.239518	0	1980-01-01	\N	f	\N	f
3442	JOÃO HENRIQUE RODRIGUES DOS SANTOS	henriquecqsantos99@hotmail.com	JOÃO HENR	\N	\N	9bf31c7ff062936a96d3c8bd1f8f2ff3	f	\N	2012-01-10 18:26:14.584009	0	1980-01-01	\N	f	\N	f
3443	JOÃO LUCAS DE FREITAS MATOS	lucas.freitas.matos@hotmail.com	JOÃO LUCA	\N	\N	e744f91c29ec99f0e662c9177946c627	f	\N	2012-01-10 18:26:14.763961	0	1980-01-01	\N	f	\N	f
3444	JOAO OLEGARIO PINHEIRO NETO	olegarioifce@hotmail.com	JOAO OLEGA	\N	\N	d2ed45a52bc0edfa11c2064e9edee8bf	f	\N	2012-01-10 18:26:14.879015	0	1980-01-01	\N	f	\N	f
3445	JOELSON FERREIRA DA SILVA	joellson_j@yahoo.com.br	JOELSON FE	\N	\N	38af86134b65d0f10fe33d30dd76442e	f	\N	2012-01-10 18:26:15.333047	0	1980-01-01	\N	f	\N	f
3447	JOHN DHOUGLAS LIRA FREITAS	johndhouglas@gmail.com	JOHN DHOUG	\N	\N	4ffce04d92a4d6cb21c1494cdfcd6dc1	f	\N	2012-01-10 18:26:15.581671	0	1980-01-01	\N	f	\N	f
3448	JONAS RODRIGUES VIEIRA DOS SANTOS	jonascomputacao@gmail.com	JONAS RODR	\N	\N	c997a606483dd82bdeb8263bc6480f01	f	\N	2012-01-10 18:26:15.885755	0	1980-01-01	\N	f	\N	f
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
3541	SAULO ANDERSON FREITAS DE OLIVEIRA	saulo.ifet@gmail.com	SAULO ANDE	\N	\N	97e8527feaf77a97fc38f34216141515	f	\N	2012-01-10 18:26:29.284024	0	1980-01-01	\N	f	\N	f
2388	Fernando Henrique Costa	fernandocosta.ifce@gmail.com	Fernando 	@		82dc7421d293dd251418cc939ca59f43	f	\N	2011-11-24 12:17:48.215411	2	1988-01-01	\N	f		t
3999	klysman	klysmanpecem@gmail.com	Klysman	@	http://sige.comsolid.org/participante/add	850a9bfcdb4bef2e926d91e5d188c91a	f	\N	2012-11-29 20:19:53.677913	1	1997-01-01	\N	f	klysmanpessoa@hotmail.com	t
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
2635	TIAGO CORDEIRO ARAGÃO	tiago.ifet@gmail.com	Cordeiro	@		73858ba9eadee4ccbfb8835cb1acdbc9	f	\N	2011-11-26 10:53:31.77019	1	1991-01-01	\N	f		t
2591	paulo henrique mendonça de araujo	henriquepaulovictor@yahoo.com	paulo aqw	@		6fddf87e973c1c96ca43851c0264ff55	f	\N	2011-11-25 15:35:50.740007	1	1996-01-01	\N	f		t
3465	LEANDRO MENEZES DE SOUSA	leomesou@yahoo.com.br	LEANDRO ME	\N	\N	0015c620f7173841d848c70dc929f601	f	\N	2012-01-10 18:26:22.670868	0	1980-01-01	\N	f	\N	f
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
299	SHARA SHAMI ARAÚJO ALVES	shara.alves@gmail.com	ervilha	@ervilha		c4f92959551b70e7d3b5f5a570234aad	f	\N	2011-10-13 19:14:47.697442	2	1990-01-01	\N	f	shara.alves@gmail.com	t
3593	Luan Pedroza Lima	luan_tdb5@hotmail.com	luanpl92	@luanpl92		f433ffd96c9552a409c86b0d6b90f1da	f	\N	2012-04-29 12:26:27.961808	1	1992-01-01	\N	f	luan_tdb5@hotmail.com	t
3594	Eliascorinthias	eliascorinthias99@hotmail.com	souza100	@		5ba6648d15409364369ae1dc88645dfa	f	\N	2012-06-06 21:18:28.990123	1	1998-01-01	\N	f	eliascorinthias99@hotmail.com	t
3600	Emerson Guimarães de Araújo	emersonguimaraes77@yahoo.com	Emerson	@EmersonGuim		bc5aa1b1ac25eb0bf556f5e949584184	f	\N	2012-10-01 08:39:09.176452	1	1995-01-01	\N	f		t
3596	Luana Furtunato de Freitas	luh-castanhos@hotmail.com	luanafurtunato	@		6b44d527862197a15101dabb8d4e4843	f	\N	2012-07-09 21:43:58.048471	2	1991-01-01	\N	f	luh-castanhos@hotmail.com	t
3598	Michael Lourenço Bezerra	connectionreverse@gmail.com	Skywalker	@		369e17d76369a1648159e3556d8f8a74	f	\N	2012-07-12 23:38:56.871887	1	1992-01-01	\N	f	connectionreverse@gmail.com	t
3601	Francisco Junior	juniornro11@hotmail.com	junior	@		ad6be9eda436605af89f22832ecc720d	f	\N	2012-10-10 15:31:14.16264	2	1994-01-01	\N	f	juniornro11@hotmail.com	t
3648	José Rafael da Silva Matias	jose.rafael.2k10@gmail.com	José Rafael	@		a8c9d5df8c881acf7be439171cc431e7	f	\N	2012-11-23 20:28:35.409969	1	1995-01-01	\N	f		t
3602	MAGNA DE OLIVEIRA BRANDAO	magna.negreiros@hotmail.com	magnanegreiros	@magnanegreiros		ec9c482f4e39d26030407e7d62174cc2	f	\N	2012-10-13 19:06:00.924361	2	1988-01-01	\N	f	magna.negreiros@hotmail.com	t
2594	manuel muniz neto 	manuelmunizbneto@hotmail.com	neto...	@		ebb7673be9455ef94f283efd088954ca	f	\N	2011-11-25 15:50:59.862215	1	1987-01-01	\N	f		t
1806	Natália Pereira Da Silva Nobre	nataliapereira.nobre@gmail.com	Talhinha	@		0a85f6fcb0b9e9af5ffa5f939bedbf45	f	\N	2011-11-23 10:30:03.259018	2	1987-01-01	\N	f	nataliaejorge1@hotmail.com	t
2442	reginaldo Ribeiro da Silva	reginaldo.silva069@gmail.com	Reginaldo	@		aa03a765db38845967370fb222cd42be	f	\N	2011-11-24 15:50:34.721298	1	1994-01-01	\N	f		t
3697	Luan Pedroza Lima	luanpl92@hotmail.com	luanpl92	@luanpl92		f433ffd96c9552a409c86b0d6b90f1da	f	\N	2012-11-26 23:04:47.87596	1	1992-01-01	\N	f	luanpl92@hotmail.com	t
2443	Sabrina Ferreira da Silva	sabrina.john@gmail.com	Sabrina	@		a5a74bcf1993dabc48a44168bc11d6b7	f	\N	2011-11-24 15:50:35.445612	2	1995-01-01	\N	f		t
3636	Pedro Italo Bonfim Lacerda	pedroibl@hotmail.com	zezito	@		ba9b1e7918339bcfdcca192a61a2fe02	f	\N	2012-11-22 23:04:59.338898	1	1990-01-01	\N	f		t
333	CARLOS THAYNAN LIMA DE ANDRADE	thaynan.seliga@gmail.com	Thaynan Lima	@thaynanlima_16	http://www.ministerioyeshua.com.br	a049ae94a68314be93a5938d2a570946	t	2012-10-30 00:23:01.325743	2011-10-16 13:35:21.700643	1	1993-01-01	\N	f	thaynanamojesus@hotmail.com	t
2444	Sabrina Silva	sabrina-fec@hotmail.com	sabrina	@		8c278462dc2f486dd9697edc17eff391	f	\N	2011-11-24 15:51:27.071305	2	1994-01-01	\N	f		t
2614	Nicolas Alessandros Oliveira Menezes	nickplay96@hotmail.com	Nicolas	@		6cb651015a84a980ac1c4e75956d40f7	f	\N	2011-11-25 18:35:05.207123	1	1995-01-01	\N	f		t
2662	PATRICK DE OLIVEIRA	patrick.oliveira09@gmail.com	PATRICK	@		dfbe448b0e4bab4c81001ceefdeff61f	f	\N	2011-11-26 14:45:22.66037	1	1996-01-01	\N	f		t
2445	Carlos Thiago de Andrade Feitosa	thiago-vab@hotmail.com	thiago	@		b89726847ecd67440ee54be8de3b67ce	f	\N	2011-11-24 15:51:36.299846	1	2011-01-01	\N	f		t
3512	PHYLLIPE DO CARMO FELIX	phyllipe_do_carmo@hotmail.com	PHYLLIPE D	\N	\N	66808e327dc79d135ba18e051673d906	f	\N	2012-01-10 18:26:26.846931	0	1980-01-01	\N	f	\N	f
978	Kleverland Sousa	kleverland@gmail.com	klever	@		20da2e1b6c561555d61901fff9c3f21e	t	2012-11-21 17:29:36.406192	2011-11-17 15:18:32.168227	1	1990-01-01	\N	f		t
2446	gilliard de souza maciel	gilliardgdx@gmail.com	gilliard	@		8aa9ac8292be4289ef9ec167f72cda45	f	\N	2011-11-24 15:51:49.253282	1	1994-01-01	\N	f		t
3604	João Pedro Martins Sales	joaopedroms.ifce@gmail.com	João Pedro	@		01ecd4b522c02adf9ee7ea8dd86559a1	f	\N	2012-11-02 10:13:05.530846	1	1989-01-01	\N	f		t
296	Joséé Albertobarros do nascimento	jalbertogod@gmail.com	Bbbbbbbb	@		e3d61d0f1a40f43986b5431ced03e36c	t	2012-11-06 09:02:11.999035	2011-10-12 23:49:00.468359	1	1996-01-01	\N	t		t
2447	Ítalo de Oliveira da Silva Farias	ioliveirafarias@gmail.com	Ítalo	@		7b6adfb91f2441bf425685c6c0100c6c	f	\N	2011-11-24 15:52:18.577109	1	1996-01-01	\N	f		t
2679	Leandro Rodrigues da Silva	leandro_cearamor67@hotmail.com	Leandro	@		7887980fa5afe1d3b72863d46eb015f3	f	\N	2011-11-26 16:03:51.659153	1	1995-01-01	\N	f		t
3513	PRISCILA CARDOSO DO NASCIMENTO	prisna.cardoso@hotmail.com	PRISCILA C	\N	\N	88219212c52f303152f0417b59ebb638	f	\N	2012-01-10 18:26:26.900302	0	1980-01-01	\N	f	\N	f
1831	Edilson Marques Teixeira	edilson3004@hotmail.com	Edilson	@		318ff89cd187f8211697def566f3c8db	f	\N	2011-11-23 10:40:44.296536	1	1982-01-01	\N	f		t
297	CAMILA LINHARES	linhares.mila@gmail.com.backup	Camila	@linharesmila	http://comsolid.org	e94cda7830c572b1f81bd1abe7299b14	t	2012-11-21 17:43:50.860758	2011-10-13 16:54:56.049301	2	1989-01-01	\N	t	linhares.mila@gmail.com	t
3515	RAFAEL ARAGAO OLIVEIRA	raphaeltecnico.fiacao@gmail.com	RAFAEL ARA	\N	\N	1728efbda81692282ba642aafd57be3a	f	\N	2012-01-10 18:26:27.001982	0	1980-01-01	\N	f	\N	f
3630	Samyha Maria Gomes da Silva	samyha.maria@hotmail.com	Samynha	@		b31b3835f0ddc192f5795afe5f13ac40	f	\N	2012-11-22 22:16:23.918872	2	1996-01-01	\N	f	samynhag@facebook.com	t
3516	RAFAEL BEZERRA DE OLIVEIRA	rafaelbezerra195@gmail.com.br	RAFAEL BEZ	\N	\N	971e6b87788ada8e69ca7281ff4bc2a3	f	\N	2012-01-10 18:26:27.053711	0	1980-01-01	\N	f	\N	f
3611	Luiz Lauro Moura de Jesus	luizlauromoura@gmail.com	Luiz Lauro	@		25f9e794323b453885f5181f1b624d0b	f	\N	2012-11-22 15:26:53.622371	1	1991-01-01	\N	f		t
3818	Jacy taveira	jacy.taveira@gmail.com	JacyTav	@		e970f8e02e796581ad3fd04243adf37a	f	\N	2012-11-28 11:06:35.159188	2	1992-01-01	\N	f		t
3514	PRISCILA FEITOSA DE FRANÇA	priscilapff@gmail.com	PRISCILA F	\N	\N	81a0e1c9876788c45e5af6b5c4e7ebc2	f	\N	2012-01-10 18:26:26.950809	0	1980-01-01	\N	f	\N	f
3518	RAFAEL SOARES RODRIGUES	rafael88.soares@hotmail.com	RAFAEL SOA	\N	\N	c0c7c76d30bd3dcaefc96f40275bdc0a	f	\N	2012-01-10 18:26:27.326224	0	1980-01-01	\N	f	\N	f
3654	Francisca Naiane da Silva Rocha	naianerocha1@gmail.com	Naiane	@nanirocha		c4e3ea61893bb2842acb2959776bc503	f	\N	2012-11-23 23:35:09.773202	2	1988-01-01	\N	f	naiane-nani@hotmail.com	t
3519	RAFAEL VIEIRA MOURA	rafael-.-vieira@hotmail.com	RAFAEL VIE	\N	\N	4fe748fbadcd8ba14fb8ea4472f3f4ad	f	\N	2012-01-10 18:26:27.381386	0	1980-01-01	\N	f	\N	f
3668	Renato William Rodrigues de Souza	renatowilliam21@gmail.com	Arrojado	@		2fc1dc241f5f2ae4f9161cdee9801d88	f	\N	2012-11-25 01:49:22.935987	1	1986-01-01	\N	f	renatodoarrojado@hotmail.com	t
3520	RAFAELA DE LIMA SILVA	rafaella02@yahoo.com.br	RAFAELA DE	\N	\N	41f1f19176d383480afa65d325c06ed0	f	\N	2012-01-10 18:26:27.432442	0	1980-01-01	\N	f	\N	f
3521	RAIMUNDO PEREIRA CAVALCANTE NETO	pcnetur27@hotmail.com	RAIMUNDO P	\N	\N	94c7bb58efc3b337800875b5d382a072	f	\N	2012-01-10 18:26:27.484976	0	1980-01-01	\N	f	\N	f
3522	RALPH LEAL HECK	imagomundi@hotmail.com	RALPH LEAL	\N	\N	53c3bce66e43be4f209556518c2fcb54	f	\N	2012-01-10 18:26:27.535581	0	1980-01-01	\N	f	\N	f
3523	RAPHAEL ARAÚJO VASCONCELOS	rapha_araujo_vasconcelos@hotmail.com	RAPHAEL AR	\N	\N	5b8add2a5d98b1a652ea7fd72d942dac	f	\N	2012-01-10 18:26:27.585921	0	1980-01-01	\N	f	\N	f
3610	camila linhares	linhares.mila@gmail.com	camila	@linharesmila		95bbefbffd57f391f6249c6f35df3f9d	f	\N	2012-11-21 17:57:50.364267	2	1989-01-01	\N	t	linhares.mila@gmail.com	t
3631	Marvlyn da Silva de Paulo 	ma_rv_lyn100leoesdatuf@hotmail.com	Marvlyn	@		8dc4a4e49437397dd90cabe961e7cfb2	f	\N	2012-11-22 22:31:45.829437	1	1995-01-01	\N	f		t
4438	RAIMUNDO ISMAEL 	ismael-raimundo@hotmail.com	maelzão	@		f094e4a59c6a836287db9ccf35d88f40	f	\N	2012-12-04 21:24:31.622269	1	2011-01-01	\N	f	ismael-raimundo@hotmail.com	t
3637	Paulo Rogerio Lameu Fraga	paullolameu@gmail.com	Optimus	@		5ca33d221fd09f16c1ecba9c1aadc3eb	f	\N	2012-11-22 23:10:13.218365	1	1987-01-01	\N	f	paullolameu@gmail.com	t
3619	ANTONIO ARLEY RODRIGUES DA SILVA	arleysb@gmail.com	ARLEY RODRIGUES	@	http://www.arleyrodrigues.com.br	a3a019f7d7ed870aefd145d8c0fabc16	f	\N	2012-11-22 18:15:22.289823	1	1981-01-01	\N	f		t
3669	Raphaelle da Silva Sales	rsales2010@gmail.com	Raphinha	@		66a331a12a579a8acce97a7ee316472f	f	\N	2012-11-25 11:05:56.259248	2	1987-01-01	\N	f		t
3640	Wandemberg Rodrigues Gomes	wandemberg.rodrigues@gmail.com	Wandemberg	@		526eafb45b056bace5c3e45807bc31de	f	\N	2012-11-23 07:56:06.894991	1	1988-01-01	\N	f		t
3792	Pabllo Alexandre Bruno Alves da Silva	pabllo.allexandre@gmail.com	-Piiu-	@		bd97f8cf6bad9e7f412c4a5076a359e0	f	\N	2012-11-27 21:05:13.285838	1	1993-01-01	\N	f	pabllo_0@hotmail.com	t
3612	Maria José Luz de Sousa	marialuz-ubj@hotmail.com	Maria Luz	@		95bae4943a7aad9b863734a737f48877	f	\N	2012-11-22 17:51:18.060527	2	1990-01-01	\N	f	marialuz-ubj@hotmail.com	t
3858	Emanoel Alves	emanoel.alves@rocketmail.com	Emanoel	@		79aaaedb78cf76eba46a7c8dbda84669	f	\N	2012-11-28 21:47:25.080314	1	1997-01-01	\N	f	emanoel.alves@rocketmail.com	t
3655	Francisco Diego Pereira Nobre	diegopnobre@hotmail.com	Diego Nobre	@diegopnobre		10e75f3e8a076541ac3001c0e1c2b5ba	f	\N	2012-11-23 23:37:38.680833	1	1989-01-01	\N	f	diegopnobre@hotmail.com	t
3642	Danuso	danusorocha@gmail.com	Danuso	@		d200f6d62186965ca6476266fcb5cf8b	f	\N	2012-11-23 17:51:25.44881	1	1991-01-01	\N	f		t
3623	Israel Rodrigues Bezerra	raelgames.bezerra@gmail.com	Israel Bezerra	@		ca4c5ab15d5fe13b7a972f62a59bbf35	f	\N	2012-11-22 18:35:36.837247	1	1995-01-01	\N	f	kuro2008@hotmai.com	t
1310	Robson	robsonfail@gmail.com	Das treva	@robinfail		d16f772bdee06cd871dac796ace59630	t	2012-11-23 18:28:55.613023	2011-11-22 10:24:07.072665	1	1995-01-01	\N	f	robinxp_mf_@hotmail.com	t
3625	Franciscoi Diego do Nascimento Menezes	diego.menezes120@gmail.com	diegodolouvor	@		eb9c3fa2cc70a7ba7a970a6cd958d53e	f	\N	2012-11-22 18:54:42.606928	1	1995-01-01	\N	f	diego.menezes120@gmail.com	t
3646	Dauryellen Mendes Lima	daury.mendes@gmail.com	Daury 	@		891dc8e1293b6f489165633a77b56fff	f	\N	2012-11-23 20:03:22.284436	2	1988-01-01	\N	f		t
3626	Aluísio Cavalcante de Queiroz Neto	cavalcante.alusio@gmail.com	Aluísio	@		2a6fca80c7d9b23d9bd5b699ad3bc8c4	f	\N	2012-11-22 19:20:21.588308	1	1988-01-01	\N	f	aluisio.cavalcante.roautec@facebook.com	t
940	Hércules	herculessantana1@hotmail.com	Hércules	@herculessant1		dc3dfdda496005416f8a34434d0ee32b	t	2012-11-22 19:30:52.635761	2011-11-16 21:44:43.224635	1	1997-01-01	\N	f	herculessantana1@hotmail.com	t
1083	Michael Lourenço Bezerra	jesussave.podecrer@hotmail.com	Darth Michael	@		d5a66bdb0d7cc4ca5159d58666242c9e	t	2012-11-24 02:15:32.309912	2011-11-20 18:07:14.696447	1	1992-01-01	\N	f	jesussave.podecrer@hotmail.com	t
3672	Graziela	grazielabarros19@gmail.com	Graziela	@		81f0a813e9223d08fd0e4bd27f1a4f10	f	\N	2012-11-25 13:23:38.475365	2	1992-01-01	\N	f	laedegrazielabarros@hotmail.com	t
3661	Júnior Rodrigues	jrrti@live.com	Júnior Rodrix	@		59e976c1dea2775cf14326639ede9cce	f	\N	2012-11-24 11:05:38.529003	1	1993-01-01	\N	f	jrodrix@live.com	t
313	José Natanael de Sousa	sousanatanael@rocketmail.com	Natanael Sousa	@		adcb8bd8cd071d0952ef95b99e5b77cc	t	2012-11-25 17:32:44.061227	2011-10-14 17:01:53.939236	1	1990-01-01	\N	f	natanlean@hotmail.com	t
3683	WINDSON REGIS TEIXEIRA DA SILVA	windson37@hotmail.com	 φ do vento	@		fbdfb0507c0f55ad92e80d17161b1516	f	\N	2012-11-26 11:31:53.18478	0	1995-01-01	\N	f	windson37@hotmail.com	t
3685	Andre Luiz	andrezaofranklin@gmail.com	Andre luiz	@		e27cc30ebe662399439e968d38d88f03	f	\N	2012-11-26 15:06:35.465637	1	1986-01-01	\N	f		t
3618	Samanda Sa	samandasaquimica@gmail.com	Samanda	@		aa9abc5aece06a96cbc9138e2d2dd18d	f	\N	2012-11-22 18:15:03.276931	2	1993-01-01	\N	f	samandapat@hotmail.com	t
5066	Leiliane Dantas Cosme de Oliveira	leiliane051091@hotmail.com	Leiliane	@		7e3917fa3924951c4dbc1722b74559f1	f	\N	2012-12-06 19:44:40.97517	2	1991-01-01	\N	f	leiliane051091@hotmail.com	t
3698	samira torres	shamiratorres@hotmail.com	Samira	@		cdb59486dc68d61f5660edc4a04402a1	f	\N	2012-11-26 23:06:12.509336	2	1988-01-01	\N	f	shamiratorres@hotmail.com	t
3781	Michael Jordan Lourenço Jacinto 	michaeljodan92@gmail.com	michael	@		25fc80581d22e774333461b660427570	f	\N	2012-11-27 20:21:11.35139	1	1992-01-01	\N	f		t
4000	AFONSO ALVES DE SOUZA FILHO	afonsoalves05@gmail.com	Afonso	@		e2abfabe1256003969da2959f83d5097	f	\N	2012-11-29 20:45:45.822584	1	1991-01-01	\N	f		t
316	Anderson Ávila	andersonmufc@gmail.com	Anderson Ávila	@andersonxavila		b7d279a88bdd5ee9df44aa018e745863	t	2012-11-26 23:23:47.130153	2011-10-14 18:36:49.44144	1	1988-01-01	\N	f	andersonmufc@gmail.com	t
3517	RAFAEL SILVA DOMINGOS	rafaelsdomingos@gmail.com	RAFAEL SIL	\N	\N	553a7e31fa31a40d8ce68810c576ebca	f	\N	2012-01-10 18:26:27.204541	0	1980-01-01	\N	f	\N	f
5365	Ana Kelle da Silva Barroso	annakelleyrock@hotmail.com	Ana Kelle	@		971277a8af16e4ef999537bbda8fd4cb	f	\N	2012-12-08 09:46:49.972425	2	1996-01-01	\N	f		t
3712	Joel Ewerton da Costa Almeida	jooelcosta@gmail.com	Joel Costa	@_joelcosta		70148acb44ec247a72a9500b0aa4ad59	f	\N	2012-11-26 23:54:09.941437	1	1992-01-01	\N	f	jooh__costa@hotmail.com	t
3872	Sarah da Costa Barbosa	sariinha.costa@hotmail.com	Sarinha	@sarahcostab		bde1752add621d42a15b202ab536829e	f	\N	2012-11-28 22:40:32.419311	2	1997-01-01	\N	f	sariinha.costa@hotmail.com	t
3801	Matheus Carvalho	matheuscarvalhodf@gmail.com	Matheus	@m4theusc		18179ef5f66bcd18a9900372510b37a8	f	\N	2012-11-27 22:37:15.886823	1	1995-01-01	\N	f	matheuscarvalhodf@ymail.com	t
4226	João Vitor Coelho Nunes da Mata	jv.mata@hotmail.com	João Vitor Kass	@		227fa126340f93c98b576cfab6f08162	f	\N	2012-12-03 09:57:29.592719	1	1996-01-01	\N	f		t
4048	maria socorro rufino	socorro.resed23@gmail.com	socorro	@		7f9d0d16143ef977efe3c888af3e29d6	f	\N	2012-11-30 09:14:58.090011	2	1978-01-01	\N	f		t
4129	Carolina Silva de Azevedo	carol_azevedo_silva@hotmail.com	Carol Azevedo	@		76463bfd3221a4de30165c9d18ddc54f	f	\N	2012-11-30 21:24:39.185033	2	1996-01-01	\N	f	carol_azevedo_silva@hotmail.com	t
4059	Maxela Martins Pontes	maxelamartins10@gmail.com	Maxela	@		cad65d727912e8e545f4cf4be52980f8	f	\N	2012-11-30 10:49:55.169843	2	1990-01-01	\N	f	maxela_martins@hotmail.com	t
4068	Vânya	vanya.bessa@gmail.com	Vânya	@		5886c82806d2eaada8833378cefa8172	f	\N	2012-11-30 11:38:34.894559	2	1995-01-01	\N	f	vanyabessa@hotmail.com	t
3649	Lucas Mota	sinxeb@hotmail.com	Sinxtm	@		7bc1f680852b43847a8d1e6de69267bf	f	\N	2012-11-23 20:31:38.197121	1	1994-01-01	\N	f	sinxeb@hotmail.com	t
3627	Iuri Vieira Gaier	Iurivieiragaier@hotmail.com	Iurigaier	@	http://www.facebook.com/iuri.gaier	a4f70886891b0ca3c36a4108bb7a2f15	f	\N	2012-11-22 19:35:01.564545	0	1987-01-01	\N	f	Iurivieiragaier@hotmail.com	t
3647	Douglas Ferreira da Silva	douglasejovem@gmail.com	Douglas	@DoougSiilva		a78dd9813aa9cc36292a933673771ea1	f	\N	2012-11-23 20:10:03.941428	1	1996-01-01	\N	f	sexyrcing_vip@hotmil.com	t
3628	iuri vieira gaier	iurivieiragaier@hotmail.com	scourt	@	http://www.facebook.com/iuri.gaier	ed304a5949c5c879b0825bb3565fd54b	f	\N	2012-11-22 19:44:31.710004	1	1987-01-01	\N	f	iuri.gaier@facebook.com	t
3638	John Wilkson Carvalho de Sousa	JOHN_WILKSONCS@YAHOO.COM.BR	John Rolim	@johnrolim		d914f6e01466fe4fbbcc53eb22156293	f	\N	2012-11-23 00:09:54.978753	1	1986-01-01	\N	f		t
4734	WESLEY ANSELMO LIMA	weslley.anselmo.l@gmail.com	Kcafeeé	@		ed47de7392ca09d51d2a53b5cfe1363a	f	\N	2012-12-05 21:38:00.268812	1	1995-01-01	\N	f	wesley_eevee@hotmail.com	t
646	EMANUEL ROSEIRA GUEDES	emanuelrguedes@hotmail.com	Emanuel	@emanuelrguedes		6de98ccf808eea58dad4d9a402cbc73e	t	2012-11-23 09:12:20.487026	2011-11-09 10:27:55.197417	1	1995-01-01	\N	f	emanuelrguedes@hotmail.com	t
3650	Vitória Freitas	vitoria.f.n@hotmail.com	Vitória	@		233d3634f83f762e1de85591d7e4facb	f	\N	2012-11-23 21:56:21.294254	2	1994-01-01	\N	f	vitoria.f.n@hotmail.com	t
399	Luana Gomes de Andrade	j.kluana@gmail.com	Luanynha	@boneklulu		b39197747a604dc4c8d05dd56fc83412	t	2012-11-23 19:06:26.248439	2011-10-20 18:18:36.750374	2	2011-01-01	\N	f	j.kluana@gmail.com	t
1021	ANA BEATRIZ FREITAS LEITE	aninha_beatriz_109@hotmail.com	Biazinha	@BiazinhaFreitas		aef7f7aa807c7fdfc6cb22dc1bd13a61	f	\N	2011-11-18 19:16:39.788809	2	1992-01-01	\N	f	aninha_beatriz_109@hotmail.com	t
3658	caroline praxedes de almeida	krol.p@hotmail.com	carol.p	@		9616e6571517d2771554278ae96c37b0	f	\N	2012-11-24 01:48:15.732215	2	1995-01-01	\N	f	krol.p@hotmail.com	t
3449	JORGE FERNANDO RAMOS BEZERRA	marvinjfpg@hotmail.com	JORGE FERN	\N	\N	47b83302fa24b1276cb0ac321175000a	f	\N	2012-01-10 18:26:16.476763	0	1980-01-01	\N	f	\N	f
3662	Lucas Rebouças Monte	lukastoc82@hotmail.com	lukinha	@		34fadfbd1bbc09359d2ee4d3c478c6be	f	\N	2012-11-24 17:04:49.57593	1	1994-01-01	\N	f	lukastoc82@hotmail.com	t
1023	ISLAS GIRÃO GARCIA	islasg.garcia@gmail.com	Islash	@		e3ddde4c3693e9d076e4431b5b7ae373	t	2012-11-24 18:06:54.051617	2011-11-18 19:26:41.224203	1	1994-01-01	\N	f	islasgarcia@live.com	t
3690	Ivanov de Almeida Moraes	ivanov_almeida@hotmail.com	Ivanov	@		fc7a779ea3b9b4d829674bed41c70b0a	f	\N	2012-11-26 19:55:12.652984	1	1997-01-01	\N	f	ivanov.dealmeida.56@facebook.com	t
3673	José Pereira da Fonseca Filho	j_pereira2@yahoo.com.br	Pereira	@		8ff01141b64f63f34be6778f5a63c8f4	f	\N	2012-11-25 14:37:52.159478	1	1987-01-01	\N	f	j_pereira2@yahoo.com.br	t
3678	Clara Bianca Silva Alves	clarabianca.2011@gmail.com	Bainca	@		a680b348c4720e1ed0517ea34dca6857	f	\N	2012-11-26 10:35:49.282493	0	2011-01-01	\N	f		t
3684	Renato Damasceno de Vasconcelos	renatogalatico@hotmail.com	Galatico	@		fbf3e285ff8097170b0f92f0e4390056	f	\N	2012-11-26 13:35:25.567424	1	1989-01-01	\N	f	renatogalatico@hotmail.com	t
3699	Arthur Mikael	artmik2008@hotmail.com	Art Myk	@artmyks		4e00b525d8f6bc14d449d8e143873aa6	f	\N	2012-11-26 23:07:17.064765	1	1996-01-01	\N	f	artmik2008@hotmail.com	t
3686	Maiara Jéssica Ribeiro Silva	maiarajessicars@gmail.com	Maiara Jéssica	@Maiarajessicars		9a5964f65f74f78292d403a520a0a0fd	f	\N	2012-11-26 15:35:40.217722	2	1995-01-01	\N	f	maiara.jessica.161@facebook.com	t
3688	Antonio Leandro Martins Cândido	leandros999@yahoo.com.br	LeoTeclas	@LeoTeclas_	http://meadiciona.com/LeoTeclas	774135367572e29045e7b037b4511b49	f	\N	2012-11-26 17:51:25.58444	1	1987-01-01	\N	f	leoteclas@facebook.com	t
349	david tomás ferreira da silva	davidtomas.ilustracoes@hotmail.com	davidtomas	@davidtomasilust	http://davidtomasilustracoes.blogspot.com/	1a2b8ab43753bc072ec039ba667c1fa7	f	\N	2011-10-17 15:04:25.316944	1	2011-01-01	\N	f	davidtomas.ilustracoes@hotmail.com	t
3830	Jefferson Costa	jeffersoncostadelima@gmail.com	Jefferson	@		39304e08d60d3ee3281c90422db85ecf	f	\N	2012-11-28 15:24:43.905057	1	1996-01-01	\N	f	jeffersoncosta96@hotmail.com	t
3802	DELVANI SOUSA DOS SANTOS PIRES	delvanisousa@gmail.com	Delvani	@		19032b8f42050e9b34fff439d40fb07f	f	\N	2012-11-27 22:40:09.20284	0	1987-01-01	\N	f		t
3707	Charles Luis Castro	charles.luis.seliga@gmail.com	ChIF12	@		02d94235dd1213e54a2f9619641fcdfa	f	\N	2012-11-26 23:23:01.629701	1	1994-01-01	\N	f	charles_139@hotmail.com	t
3807	Maxkson	maxkson.felipe@hotmail.com	Felipe	@		da508b2cfabecaa0ff044d0e5c580593	f	\N	2012-11-28 08:48:37.0668	1	1997-01-01	\N	f	maxkson.felipe@hotmail.com	t
3709	Kecia Kevia	kecia-bf@hotmail.com	Kecia Kevia	@		730beb195e72a418e031d7777eb4fa92	f	\N	2012-11-26 23:24:48.443422	2	1994-01-01	\N	f	kecia-bf@hotmail.com	t
5031	Thalyta Lima da Silva Rocha	thalyta.lima15@hotmail.com	Thalyta	@		f3d2ef5b918fc2cf343cf17f71557a05	f	\N	2012-12-06 17:00:53.390687	2	1999-01-01	\N	f		t
2580	Jefferson Silva Almeida	jefferson.seliga@gmail.com	Jefferson Silva	@jeffersonseliga		106344127a3012eb32f833e76b9daadd	f	\N	2011-11-25 14:25:18.636994	1	1992-01-01	\N	f	jefferson.seliga@gmail.com	t
3713	Mayane	mayaneecristina_@hotmail.com	mayanee	@		28e357c5f9cdd6832bab4c7e3d0c61f7	f	\N	2012-11-26 23:54:30.269981	2	1994-01-01	\N	f		t
3813	brenos	brenosampaio125@hotmail.com	gatinho do maracanau	@		99a2cef99a5f8273abc80e085c875cd3	f	\N	2012-11-28 08:58:13.109084	1	2000-01-01	\N	f		t
3718	Marcelo Oliveira	marcelo.autin@gmail.com	marceloautin	@		b52f0bdff75abe854cf7aabe93a5c930	f	\N	2012-11-27 00:05:45.524789	1	1991-01-01	\N	f	marceloautin@hotmail.com	t
615	Reginaldo Patrício de Souza Lima	reginaldopslima@gmail.com	Reginaldo	@reginaldopslima		a1e450b6d28d51c5a448321896403ae7	t	2012-11-28 22:09:35.454872	2011-11-07 23:30:57.064224	1	1990-01-01	\N	f	reginaldopslima@gmail.com	t
3819	Iasmin Holanda	iasmin_holanda@hotmail.com	Iasmin	@		1dc28cc69a9275c1617a03049d819f66	f	\N	2012-11-28 11:33:14.945634	2	1992-01-01	\N	f		t
3836	Karla Rebeca Barbosa	karla.rebek@hotmail.com	Rebeca	@		b748f6080565e65accd084b9a3b0f923	f	\N	2012-11-28 15:28:12.167827	2	1996-01-01	\N	f	barbosarebeca@hotmail.com	t
3840	THARLES MICHAEL BATISTA AMARO	tharles.fate.redes@gmail.com	Tharles	@		ca3b52694de016ee0a31cf11870525d8	f	\N	2012-11-28 17:56:03.524532	1	1993-01-01	\N	f	tharlesmichael.contato@yahoo.com.br	t
3873	Letícia Lima e Silva	letycialimasga@hotmail.com	Tícia	@		0e0acb2cd0bdd119986b1aa319c87e67	f	\N	2012-11-28 22:50:01.375913	2	1997-01-01	\N	f	leticiahsga@hotmail.com	t
3879	Anderson 	anderson95gomes@gmail.com	Andinho	@Andinhogomez		ea1eb24de8b67f3f91822d8764475c4e	f	\N	2012-11-28 23:01:17.090193	1	1995-01-01	\N	f	andinhogomez@gmail.com	t
4131	carlos jhonatan	carlosjhonatan2009@hotmail.com	Jhon Jhon	@		3680ea409c4fbd64cdbbad61b66de1c0	f	\N	2012-11-30 21:46:38.2785	1	1998-01-01	\N	f	carlosjhonatan2009@hotmail.com	t
4049	viviane	Viviane.demeneses@gmail.com	viviane	@		0c3bdd714e563d29d97db6d0feab9b91	f	\N	2012-11-30 09:32:08.443314	2	1996-01-01	\N	f		t
4201	Robson Pires	rpiresz@yahoo.com.br	Robinho	@		9ece5adadc185b187fab4c129e026f99	f	\N	2012-12-01 23:24:18.6742	1	1982-01-01	\N	f		t
4312	Raylan Pereira Alves	raylan_nd@hotmail.com	Raylander	@		0c1afedffcb74954cd4689e1a6ccf8b1	f	\N	2012-12-03 20:33:06.806739	1	1997-01-01	\N	f	raylan_nd@hotmail.com	t
3629	REGINALDO MOTA DE SOUSA	reginaldomt.sousa@gmail.com	Reginaldo Mota	@		ae248b27fce89452ea7fdb126653e2ed	f	\N	2012-11-22 19:45:27.795589	1	1986-01-01	\N	f		t
3639	fabio vinicius	fabioviniciusmaia@yahoo.com.br	fabioVinicius	@		938d4eaa05671f970fc56d90ca5674fc	f	\N	2012-11-23 00:19:46.022053	1	1986-01-01	\N	f		t
3651	Francisco Ivanildo da Costa Brito	ivanildo-brito@hotmail.com	Ivanildo	@		70dd4853b02411df80cef2191d37c910	f	\N	2012-11-23 22:00:06.762111	1	1992-01-01	\N	f		t
3641	Rand Brito de Albuquerque	randalbuquerque@gmail.com	Randrand	@		20182070be0cc4568720c97925df8c67	f	\N	2012-11-23 10:20:07.9861	1	1989-01-01	\N	f	randalbuquerque@gmail.com	t
341	André Luis Vieira Lemos	andre.luis.vieira.lemos@gmail.com	andre_eofim	@		200f9cebcd71eb87741e05b8ccf93449	t	2012-11-24 20:42:25.042669	2011-10-17 12:48:21.120346	1	1990-01-01	\N	f	andre_eofim@hotmail.com	t
3645	Diego Oliveira Pereira	diego_shess@hotmail.com	diego.shess	@		2f8a31d0a3d1e511a15329fb6144e3a1	f	\N	2012-11-23 19:38:28.550805	1	1994-01-01	\N	f		t
3659	silvana vitorino	silvanavitorino@gmail.com	anavitorino	@		b56af86c98380212af32cb0092dcb7be	f	\N	2012-11-24 02:12:56.378274	2	1985-01-01	\N	f	silvanavitorino18@hotmail.com	t
3660	washington alves	washington_ad@hotmail.com	HardDance	@		603c86df664862f6daf45c1dd6820020	f	\N	2012-11-24 09:00:49.634612	1	1991-01-01	\N	f	washingtontecnico@hotmail.com	t
3656	Magno Silva Gomes	magnosilva01@yahoo.com.br	Magno Silva	@		455a640c2765988b9158c5e55c064cb1	f	\N	2012-11-24 00:21:49.326284	1	1993-01-01	\N	f	magno_vasco@yahoo.com.br	t
3671	kilder fontinele	kfserv@hotmail.com	kilder	@kilderfontinele		1d024f8e63f0436920a9b5a0094f1ecf	f	\N	2012-11-25 13:01:19.612429	1	1978-01-01	\N	f	kfserv@hotmail.com	t
3682	Rayca Cavalcante	raycasampaio@yahoo.com.br	Rayca Cavalcante	@		cb67b341050a71114817913440277474	f	\N	2012-11-26 10:46:51.593964	2	1992-01-01	\N	f		t
3674	André Jálisson Gonzaga de Sousa	andrejalisson@gmail.com	andrejalisson	@andrejalisson		8b3b4eada1e50e43ed56744f9587eeb8	f	\N	2012-11-25 16:28:13.673858	1	1991-01-01	\N	f	andrejalisson@gmail.com	t
692	lucas Araujo da Silva	lucas._.araujo@hotmail.com	the dark knight	@		a3125854d7f5f6e9f510c7341108a45f	t	2012-11-26 13:47:56.538487	2011-11-10 17:36:38.192231	1	1995-01-01	\N	f	lucas._.araujo@hotmail.com	t
3692	José Marlon Sousa dos Santos	sousa.marlon@ymail.com	Marlon	@		0d4a4835c34645662526ae7cc25fd016	f	\N	2012-11-26 21:37:27.0803	1	1990-01-01	\N	f		t
3687	Marina Marques Coelho	marinac.fotografia@yahoo.com	Marina	@		667a80d95c619fa700932f46c9065ce6	f	\N	2012-11-26 17:36:13.325713	2	2011-01-01	\N	f		t
1084	david tomás	davidtomas.instrutor@gmail.com	davidilustracoes	@davidtomasilust	http://davidtomasilustracoes.blogspot.com/	9375d30cd5ed3519445620593cf32209	f	\N	2011-11-20 18:18:52.453047	1	1987-01-01	\N	f	davidtomas.ilustracoes@hotmail.com	t
3689	Dayane	dayaneandrade7@hotmail.com	Dayane	@		a86222b16f874818ad13eea050b2f233	f	\N	2012-11-26 18:34:14.217252	2	1994-01-01	\N	f		t
3691	Alefi Yago Rodrigues Candido	alefirodrigues@oi.com.br	lionlan	@alefi7x		a02a8f972ec1c3a8a05573771f406a88	f	\N	2012-11-26 20:12:57.345565	1	1994-01-01	\N	f	alefitey@hotmail.com	t
3794	Edson Gomes	edson874@gmail.com	NightCrawler	@edson_vpg		75abbd96fec6f9f42cfa81966814eea7	f	\N	2012-11-27 21:18:13.670489	1	1985-01-01	\N	f		t
5025	Eliezer Coelho Mesquita	eliezercoelho08@gmail.com	ELIEZER	@		6cd5ac496cf9599b2bd9d9bf9dd2edb2	f	\N	2012-12-06 16:51:21.985715	1	1992-01-01	\N	f	eliezercoelho08@gmail.com	t
5113	Antenúsia Alves Ferreira	nusyah123@gmail.com	Nusiaa	@niquinhabraga	http://www.tumblr.com/dashboard	1d5c464c83e5678a42dc3a3acf166d20	f	\N	2012-12-06 20:20:09.55861	2	1998-01-01	\N	f	antenusia_gatinha@hotmail.com	t
3803	Rêmulo Mendes Rocha	remulo8@gmail.com	Kalel8	@		4f0df434b56598aa475dc66242ba5f8e	f	\N	2012-11-27 22:43:03.834987	1	1990-01-01	\N	f	kalelsuper8@hotmail.com	t
3867	Antonio Victor Abreu Martins	antoniovictor585@hotmail.com	victor	@		4a9015124549d480fea908c7c120bdde	f	\N	2012-11-28 22:28:24.582774	1	1997-01-01	\N	f	antoniovictor585@gmail.com	t
3714	Mayane	_mayanee@hotmail.com.br	mayanee	@		82ed6dab85f6e547d512a73f01995fe8	f	\N	2012-11-26 23:59:26.084117	2	1994-01-01	\N	f		t
3808	Lucas André	lucas_cearamor10@hotmail.com	André	@		b30cab3e1cc4a817174e09bf43342a34	f	\N	2012-11-28 08:51:13.943569	1	1998-01-01	\N	f		t
3717	Marcelo Lessa Martins	marcelolessamartins@hotmail.com	Marcelo Lessa	@Marcelo__Lessa		84502fd0d456033623e06609c141650f	f	\N	2012-11-27 00:05:24.0527	1	1994-01-01	\N	f	marcellolessamartins@hotmail.com	t
3814	maicon	maicon_baia@live.com	maicon.silva	@		31a0a36264fa10a5f57253860f52089b	f	\N	2012-11-28 08:58:14.268047	1	1998-01-01	\N	f		t
3722	amanda	aman_din_hanf@hotmail.com	amanda	@		751857a43082d0f7bc818b9d71423df2	f	\N	2012-11-27 00:22:02.460563	2	1991-01-01	\N	f	amandakellynf@hotmail.com	t
3874	Renato Bruno Jansen 	renatobruno26@gmail.com	Pezão	@		4029f1dc1fe42f20b8478c78e6d3e53e	f	\N	2012-11-28 22:56:35.037164	1	1986-01-01	\N	f	renato-ce@hotmail.com	t
4002	Letícia Elísia de Araújo	leticia_elisiaaraujo@hotmail.com	Morgan Le Fay	@		d3cb5e196bd4d030e74df882927111d6	f	\N	2012-11-29 21:31:01.252257	2	1994-01-01	\N	f	leticia_elisiaaraujo@hotmail.com	t
696	Neyllany	neyllany@gmail.com	Neyllany	@Neyllany		878aaeeecd03c898e0c8fc7f826919b2	t	2012-11-28 18:01:54.439425	2011-11-10 20:21:42.393681	2	1991-01-01	\N	f	neyllany@gmail.com	t
3880	valdenice alves dos santos	nyces2s2@hotmail.com	nycenha	@		46fb7ee36b553a641a4c89049281cc51	f	\N	2012-11-28 23:13:55.268516	2	1996-01-01	\N	f	nyces2s2@hotmail.com	t
3849	Thatiana Oliveira	taty.livre@gmail.com	Thatiana	@		200820e3227815ed1756a6b531e7e0d2	f	\N	2012-11-28 19:59:42.223607	2	1991-01-01	\N	f	taty_livre@hotmail.com	t
3886	carlos leonardo lima nascimento	leosinho1995@live.com	leonardo	@		137ef1d7c46f61fa42460d1757240fe2	f	\N	2012-11-29 00:50:23.607876	1	1995-01-01	\N	f	leosinho1995@live.com	t
4050	JOSÉ BERNARDO DE ARAÚJO TORRES	jbbbtorres@hotmail.com	Prof. Bernardo	@		234505e0d96baf755bcc462bb5d993e7	f	\N	2012-11-30 09:43:55.951209	1	1960-01-01	\N	f	jbbbtorres@hotmail.com	t
4060	Francisco André de Lima Barbosa	andresneidjer091@yahoo.com	andrexi	@		96284bda8bff2c2550168df4c1db3d68	f	\N	2012-11-30 11:30:27.477835	1	1993-01-01	\N	f	andresneidjer091@yahoo.com	t
4039	Emanuel Costa Moreira	jobs.ec16@gmail.com	Emanuel 	@		4fb1cf4617ee4dab5f803159d3181274	f	\N	2012-11-30 02:08:39.523742	1	1996-01-01	\N	f	jobs.ec15@gmail.com	t
4439	OTAVIO WESLEY BARBOSA NASCIMENTO	otaviowesley.bnascimento@hotmail.com	WESLEY	@		1548ae0b747db23b7f15c54329fec47d	f	\N	2012-12-04 21:28:54.052751	1	1997-01-01	\N	f	otaviowesley.bnascimento@hotmail.com	t
4069	Fabrício Nunes Tavares	fabriciontavares@hotmail.com	Fntavares	@		c62d7e57805fdcb25162ef1a097ee52e	f	\N	2012-11-30 11:54:08.359474	1	1985-01-01	\N	f	fabricionunes.tavares.7@facebook.com	t
4156	Camila Alves	camilafavority@gmail.com	Camila Alves	@		867e488604f41e219b65a9ea081173c1	f	\N	2012-11-30 23:19:49.10905	2	1995-01-01	\N	f		t
4202	FRANCISCO HENRIQUE XIMENES DA CRUZ	henrique.xc.he@gmail.com	chicooreia	@		9f8d25a3fd275b3158373aa8e75c8549	f	\N	2012-12-01 23:57:16.386208	1	1992-01-01	\N	f	henrique.xc.he@gmail.com	t
4244	leilisan	leilisan.gomes@gmail.com	sanzinha	@		5bfea62ba1b3caaa571d38125dc9b332	f	\N	2012-12-03 11:42:50.077884	2	1991-01-01	\N	f	leilisan.gomes@gmail.com	t
3724	Eryka Freires da Silva	erykafreires@gmail.com	Eryka Freires	@		48ab8700342ebcd1592cb0678a79b1ff	f	\N	2012-11-27 00:27:18.840159	2	1990-01-01	\N	f	eryka.setec@gmail.com	t
3725	Jackson Uchoa Ponte	jackson.uchoa@gmail.com	Jackson	@	http://www.mvline.com.br	361e0cbf92edee01aeb675301b56e6f2	f	\N	2012-11-27 00:31:06.77291	1	1990-01-01	\N	f	jackson.uchoa@facebook.com	t
3726	Eduardo Souza Nunes	magu_sn@hotmail.com	Edu sn	@		9850178b4997ac6f17b382155444516d	f	\N	2012-11-27 00:35:59.960825	1	1994-01-01	\N	f	magu_sn@hotmail.com	t
3784	wandenbergna do carmo soares	wandenbergnacarmo@gmail.com	bergna	@		1ca391a10c153e0c56578392d12fd245	f	\N	2012-11-27 20:25:12.359513	2	1995-01-01	\N	f	bergnaanahi@hotmail.com	t
3795	Wanderson Lyncon	lynconsg@gmail.com	Anjiim	@		28c3d5f6714edc31e65dbe87ebd10b89	f	\N	2012-11-27 21:18:19.179998	1	1993-01-01	\N	f	lynconsg@hotmail.com	t
3809	erick jonas	jonas.rocha12@hotmail.com	e.jonas	@		f922cb2ab947e83b90c061751525005b	f	\N	2012-11-28 08:53:07.975526	1	1999-01-01	\N	f		t
3875	Andréa Geisiane Gomes da Silva	andreageisiane@gmail.com	Geyse/geh	@		af6b2a8158ec54fbdb17770cf9cb526b	f	\N	2012-11-28 22:58:01.19753	2	1995-01-01	\N	f	andreageisyane@hotmail.com	t
3815	Michele Estefany de Sousa Lima	michelle.fane@hotmail.com	Michele	@MichellyFany		7a5e934256324fefd6f40d1457f0632d	f	\N	2012-11-28 09:15:57.730668	2	1994-01-01	\N	f	michelle.fane@hotmail.com	t
3915	Nicolas goes barbosa	nicolas.goes12@hotmail.com	Nicolas	@		380a01516dd16c6e45d8b89203ce463f	f	\N	2012-11-29 13:05:34.611593	1	1997-01-01	\N	f	nicolas.goes12@hotmail.com	t
3826	Davi Gomes	davi.gomes3@gmail.com	Davi Gomes	@DaviGowes		c1df058857313ebebe06a3ebeccb3694	f	\N	2012-11-28 12:56:58.071098	1	1993-01-01	\N	f	davi.gomes3@gmail.com	t
4203	WELLYSON COSME LOURENCO	wellysoncosme@gmail.com	WELLYSON	@wellyson_ceara		4607dae51f3ac65986a5c18469104de8	f	\N	2012-12-02 00:44:52.962429	1	1991-01-01	\N	f	wellysoncosme2@gmail.com	t
2054	ILANNA EMANUELLE MUNIZ SILVA	ilanna.emanuelle@hotmail.com	Ilanna	@		b07ed8eaf1126fed511f490d843c5bfb	f	\N	2011-11-23 16:34:54.770303	2	1994-01-01	\N	f		t
4003	Leandro Araújo	leandro145@hotmail.com	Leandro	@leandro145		2f3e2fc97efebe8c13be8a6ba01481f3	f	\N	2012-11-29 21:31:37.146338	1	1992-01-01	\N	f	leandro145@hotmail.com	t
3850	vitor de lima	vitorlimasss@gmail.com	vitor lima	@		ed1425ca77f636a48cca928496a6a0a9	f	\N	2012-11-28 20:18:11.896543	1	1995-01-01	\N	f	vitorlimasss@hotmail.com	t
3887	Lindomar Lima	limasilva16@gmail.com	Bruno Lima	@		11302b6e83c9c95e30e1e427059ed06d	f	\N	2012-11-29 08:53:12.888552	1	1987-01-01	\N	f	lindomarlima25@hotmail.com	t
3891	Yago Herbeson Costa de Oliveira	yago_483@hotmail.com	ripchip	@yago_483		9740970ecf77af17781b8c6fb543997f	f	\N	2012-11-29 09:39:59.680392	1	1995-01-01	\N	f	yago_483@hotmail.com	t
3919	Marcelo de Sousa Caalcante	mscavalcante@hotmail.com.br	celinho	@		4d19eb233275419826bd68707027a489	f	\N	2012-11-29 13:09:27.828991	1	1998-01-01	\N	f	mscavalcante17@hotmail.com	t
3924	marciano	marciano_marciano2012@hotmail.com	marciano	@		13ff1fa9bec848b785bef0a659b3784b	f	\N	2012-11-29 13:26:02.350022	1	1997-01-01	\N	f	marciano_marciano2012@hotmail.com	t
3903	gleidiane	gleidyannecosta125@gmail.com	gleidy	@gleidyannecosta		b1fb64bc5e515fc5abc92b86d1069798	f	\N	2012-11-29 10:01:22.534691	2	1995-01-01	\N	f	gleidyannecostaa@hotmail.com	t
4077	Felipe Bezerra Cardoso	felipeuzumaqui@gmail.com	felipe	@		3a4f24e138bce5f6e079fe2369307477	f	\N	2012-11-30 13:16:24.24086	1	1997-01-01	\N	f	felipecardoso53@gmail.com	t
3927	Marcelo de Sousa Cavalcante	mscavalcante17@hotmail.com.br	celinho	@		564df791a3c743f25772693d835fe664	f	\N	2012-11-29 13:40:49.07062	1	1998-01-01	\N	f	mscavalcante17@hotmail.com	t
3899	Luiz Henrique Costa da Silva	luizhenriqu6@gmail.com	Henrique	@		16e41b1b178f7edb51ffb44c2c460f67	f	\N	2012-11-29 09:59:00.338688	1	1990-01-01	\N	f		t
3895	douglas	douglas_meu@hotmail.com	douglas	@		3b16dc694c38d04f7d7451cc37d3c654	f	\N	2012-11-29 09:54:22.811504	1	1993-01-01	\N	f	douglas_meu@hotmail.com	t
4025	Danilo Antunes dos Anjos	daniloantunesdosanjos@gmail.com	Danilão	@		dea795b633c03368e48b61f7beaf44e3	f	\N	2012-11-29 21:52:10.509949	1	1991-01-01	\N	f		t
323	KAUÊ FRANCISCO MARCELINO MENEZES	kaue.menezes191@gmail.com	Kauê Menezes	@_kauemenezes		1a42e239c10b58378a4f2852b52ee633	t	2012-12-02 01:24:54.172668	2011-10-15 00:01:28.109928	1	1991-01-01	\N	f	kaue.menezes191@gmail.com	t
3911	FRANCISCO EUDENIO DE SOUSA DA COSTA GOMES	eudenio@hotmail.com	Eudenio	@		c72e0303bd8dafa4edb36f115196d096	f	\N	2012-11-29 12:20:53.662764	1	1987-01-01	\N	f		t
3932	Gregory Nobre	pablogregory3@hotmail.com	Greg lindo	@		d81ae4dedd9d9df6eb1448402cb84cb9	f	\N	2012-11-29 13:52:55.637593	1	1995-01-01	\N	f	pablogregory2@hotmail.com	t
4051	Renata Magalhães Lemos	renata_magalhaes_lemos@hotmail.com	Renatinha	@		93426c96a1a4ea8b2514e2d109510d66	f	\N	2012-11-30 09:45:31.865101	2	1991-01-01	\N	f	renatamagalhaesl@facebook.com	t
4162	Daniele Inácio de Sousa 	danielesousa2012@bol.com.br	Danisousa	@		ff4f60e28bfab5cac1138dec8547bb1b	f	\N	2012-12-01 00:31:07.164508	2	1997-01-01	\N	f		t
585	ITALO DE OLIVEIRA SANTOS	italo_07_@hotmail.com	italo oliveira	@italo_07		4c1d63d8b13f0130c86609aa3f089103	t	2012-12-02 17:18:53.347289	2011-11-06 00:26:33.998035	1	2011-01-01	\N	f	italo_07_@hotmail.com	t
4061	Lucas de Souza Rodrigues	lukas16rodrigues@gmail.com	LucasR.	@		d6d6663d0ff31d2ed94b4c34403004fc	f	\N	2012-11-30 11:30:34.221478	1	1994-01-01	\N	f		t
3933	Jeferson cavalcante de oliveira	cavalcantejefferson7@gmail.com	furtacor	@		9a6bb0322e5488da296b95f6d85117e3	f	\N	2012-11-29 13:53:51.6305	1	1998-01-01	\N	f		t
4243	Adriano Hunik de Sousa	adrianohunik@gmail.com	adriano	@		9de5f18800dd8fc50735646e45d3d86a	f	\N	2012-12-03 11:42:49.857819	1	1996-01-01	\N	f		t
4171	Ícaro Oliveira	oliveiraicaro@hotmail.com	Ícaro	@		f4df4381502bfb76d03ab28f250f0265	f	\N	2012-12-01 11:38:52.794862	0	2011-01-01	\N	f	oliveiraicaro@hotmail.com	t
4251	Raquel	silvaraquel14@gmail.com	Raquelzinha	@		3d838dd4c168c3c377048118dc2b9667	f	\N	2012-12-03 11:46:38.000925	2	1994-01-01	\N	f	hillaryraquel1@hotmail.com	t
697	WILLIAM VIEIRA BASTOS	will.v.b@hotmail.com	Willvb	@willvb		84f3ea20769026be4b6512d3e0399832	t	2012-12-01 15:25:24.823013	2011-11-10 20:28:54.293715	1	1990-01-01	\N	f	will.v.b@hotmail.com	t
4263	Rayane	rayaneejovem@gmail.com	Kelvelle	@		8e7a467212788887694ff63c04a11609	f	\N	2012-12-03 12:06:29.742006	2	1993-01-01	\N	f	rayane_be@hotmail.com	t
4229	Adriano Barros	adriannynho@yahoo.com.br	Adriano	@adriannynho		572ecbc0205a3a4a81fa107c158e4ace	f	\N	2012-12-03 11:02:28.72942	1	1986-01-01	\N	f	adriannynho@yahoo.com.br	t
4440	Elim Jorge da Silva	elim.jorge@gmail.com	elinux	@		c5d259bba7c539ddb0362af0f7a409cd	f	\N	2012-12-04 21:37:20.939059	1	1971-01-01	\N	f	elim.jorge@gmail.com	t
4331	Cynthia Raquel Chagas Martins	cynthia_martins.ti@outlook.com	Cynthiiiiinha	@Cynn_Martins		0421d2f705cef2ec6b5c008e08f269a8	f	\N	2012-12-04 01:14:08.58196	2	1995-01-01	\N	f	cynthia.faceb@live.com	t
4453	lucas araujo	lucasaraujo7005200@hotmail.com	lucas araujo	@		c5210964556764069f0011dea8758018	f	\N	2012-12-05 00:06:24.29346	1	1994-01-01	\N	f	lucasaraujo7005200@hotmail.com	t
5032	Paula Helaine Santos Gomes	helainesilveira2012@hotmail.com	Helaine	@		b23b3daef555b051a64087f653623c31	f	\N	2012-12-06 17:02:49.510838	0	1999-01-01	\N	f		t
3727	Marcos Paulo	mpfortal@hotmail.com	expeliarmus	@		9de0568841520449fb98a3d7b572bfe1	f	\N	2012-11-27 00:47:32.51417	1	1993-01-01	\N	f		t
3657	Marcos Aurelio Araujo Ferreira Junior	aurelio.ferreira.jr@gmail.com	Marcos Junior	@		a348f3d2f7912668a853a020fa7337f2	f	\N	2012-11-24 01:28:55.59212	1	1989-01-01	\N	f	marcosaaf16@hotmail.com	t
3728	Johan Victor	johan88232671@hotmail.com	Johan12	@		5c968448160a1d45fd5905e3468e8080	f	\N	2012-11-27 00:49:17.480508	1	1993-01-01	\N	f	johan88232671@hotmail.com	t
462	Lília Souza	liliasouzas2@gmail.com	LíliaS	@		a51b486c534d1a7d235a0797bcaf937c	t	2012-11-27 20:41:28.058181	2011-11-01 16:50:55.505754	2	1992-01-01	\N	f		t
3796	wesley menezes	wesleymenezes2012@gmail.com	wesley	@		ee9de1bc8a6f35c75e7985f044cdae9f	f	\N	2012-11-27 21:19:08.610979	1	1997-01-01	\N	f	wesleym.stilo@facebook.com	t
3733	Rômulo Silva do Nascimento	roms.silva@gmail.com	Rômulo	@		ae79df3a55f4e42b553cafca5c334c09	f	\N	2012-11-27 08:06:06.875672	1	1993-01-01	\N	f		t
3734	Jorge Fernando Ramos Bezerra	jorgefernandorbezerra@hotmail.com	jorgefernando	@		70ba62502449892beb296fdbc2918e9c	f	\N	2012-11-27 08:25:33.591217	1	1988-01-01	\N	f	marvinjfpg@hotmail.co	t
3804	Geovane Sousa de Oliveira	geovanesousa01@gmail.com	Geovane	@		6ebcdc5b9b672425c8e3bd33574239ea	f	\N	2012-11-27 23:49:51.302467	1	1994-01-01	\N	f	geovanesousa01@live.com	t
631	ADRYSSON DE LIMA GARÇA	adrysson_rrr@hotmail.com	Adrysson	@adrysson_a7x		2af415a2174b122c80e901297f2d114e	t	2012-11-27 09:31:12.922502	2011-11-08 18:53:20.945709	1	1992-01-01	\N	f	adrysson_rrr@hotmail.com	t
3735	francisco airton araujo junior 	airtonjunior_crede17@hotmail.com	juniorce	@		350d38074e0ed5923ac509f33eb23c2c	f	\N	2012-11-27 10:15:41.526425	1	1979-01-01	\N	f	airtonjunior_crede17@hotmail.com	t
3810	josé lucas	lucas_almeida71@hotmail.com	lukinhas	@		c0b20cd9bcc590191918d4bda9a5fae3	f	\N	2012-11-28 08:53:41.325039	1	1999-01-01	\N	f		t
3738	francisco airton araujo junior 	airtonjunior2014@hotmail.com	juniorce2014	@		033b0cd43fdb4e5a086f6346fa256415	f	\N	2012-11-27 10:33:21.881842	1	1979-01-01	\N	f	airtonjunior2014@hotmail.com	t
2121	BRUNO BARROSO RODRIGUES	bruno_62110@hotmail.com	Bruninho	@brunobinfo		7797c87a2d34ea8c4c45b0ee46b43d8e	f	\N	2011-11-23 17:59:41.249198	1	1993-01-01	\N	f	bruno_62110@hotmail.com	t
3622	João Marcelo Cavalcante Oliveira	joaomarcelo.co@hotmail.com	joaomarcelo.co	@		c0923cfc4e142d936ab10efa474dffda	f	\N	2012-11-22 18:28:42.427059	1	1987-01-01	\N	f		t
3739	FRANCISCO ERNANDO DE SOUSA RODRIGUES JUNIOR	ernandorodrigeus.ce@gmail.com	Stallman	@		c16cb5c7558ac09069eced45a094a4cf	f	\N	2012-11-27 11:12:21.617778	1	1989-01-01	\N	f	junior02livr@gmail.com	t
4004	Maria Rosélia Barroso	roselia.barroso@hotmail.com	roselia	@		61da314ff0d1ae73f5e24f9fefd86a5a	f	\N	2012-11-29 21:33:13.445154	0	2011-01-01	\N	f		t
3740	FRANCISCO ERNANDO DE SOUSA RODRIGUES JUNIOR	ernandorodrigues.ce@gmail.com	Stallman	@		c63f6d6cc6a0d45d3441bf1a8e1219d6	f	\N	2012-11-27 11:26:56.310227	1	1989-01-01	\N	f	junior02livr@gmail.com	t
3741	FRANCISCO JOAB MARCOS FERREIRA	joab_@hotmail.com	joabjb	@		2f33ea0f4e2aabd2e833fd4c05a17b60	f	\N	2012-11-27 11:42:00.831948	1	1990-01-01	\N	f		t
3876	Daniele	danielebenigno@gmail.com	Daniele	@		cfcb5c78cf58b695941b796b9c1f6987	f	\N	2012-11-28 22:59:23.998258	2	1995-01-01	\N	f	danielecunhabenigno@hotmail.com	t
3827	erico dias	ericodc@gmail.com	ericodc	@		60cd72318cdce2f6e49bce64452986a8	f	\N	2012-11-28 13:02:44.782236	1	1975-01-01	\N	f		t
3904	antonia anagelica sales oliveira	anagelica.oliveira@gmail.com	anadelica	@		4fcdb6625c83bb47f6758f3f3df6dcfe	f	\N	2012-11-29 10:03:29.190533	2	1995-01-01	\N	f	gata_172012@hotmail.com	t
3882	Jandisley Cardins de Aquino	jandy_cardins@hotmail.com	Jandii	@		45225d78ad1f529655c400364bade77a	f	\N	2012-11-28 23:41:01.853366	1	1993-01-01	\N	f	jandy_cardins@hotmail.com	t
4441	Yanka Araújo Lima	yankadora@hotmail.com	yankinha	@		0377fc777d149e178defdcb03f1bfb7a	f	\N	2012-12-04 21:41:58.978459	2	1996-01-01	\N	f	yankadora@hotmail.com	t
3916	Francisca Mireli Da Silva Alcântara	mirelly_07@hotmail.com	Morena	@		32fb866b3c0927ff3985963c04e6aad3	f	\N	2012-11-29 13:05:39.447276	2	1996-01-01	\N	f	mirelly_07@hotmail.com	t
3888	Edson Freire Caetano	edson-44@hotmail.com	Edinho	@		71f4868817cf5422e2bb77ad99e48a1e	f	\N	2012-11-29 09:28:42.541911	1	1991-01-01	\N	f		t
3851	Rafael Sânzio Francesco de Ribeiro e Silva	rafaelsanziofrancesco@gmail.com	Rafael Sânzio	@		eb77ab4169533a556a3abff6620bcf3a	f	\N	2012-11-28 20:28:55.859452	1	2011-01-01	\N	f	rafaelsanzio2003@yahoo.com.br	t
3896	Rafaelly	rafaelly.barbozaa@gmail.com	Rafaelly	@		a255b0f59052467c71d67a64deadffae	f	\N	2012-11-29 09:54:37.93756	2	1996-01-01	\N	f	rafaelly.barbozaa@gmail.com	t
4052	Weslley Thomaz de Oliveira	weslleythomaz@hotmail.com	Ezinho	@		4aef8e81bfb014a533ae9c4d0695663e	f	\N	2012-11-30 09:57:43.655287	1	1986-01-01	\N	f		t
3900	Thiago	thiago.vieira.1990@gmail.com	Stuart	@		d9e07a377f42b36e214286d77fbe981c	f	\N	2012-11-29 09:59:21.578031	1	1990-01-01	\N	f		t
4026	franciberg ferreira d lima	lfranciberg@gmail.com	fcoberg	@		76d6ec893bdc5d3ebd60a2eb09e9c55d	f	\N	2012-11-29 21:54:23.520663	1	1993-01-01	\N	f		t
3912	crislanne jacinto do nascimento	crislanne.1995@gmail.com	lannynha	@		b8e8c604a0e2f979e8299884bab33ce9	f	\N	2012-11-29 12:21:34.007389	2	1995-01-01	\N	f	crislanne.tuf@hotmail.com	t
3920	Francisca Mireli Da Silva Alcântara	mirelif.m@gmail.com	Morena	@		a454cbe2185f232bab44ad7ea6fe8ed3	f	\N	2012-11-29 13:10:50.988846	2	1996-01-01	\N	f	mirelly_07@hotmail.com	t
4062	Jonielle Gomes de Lima	joniellegomes@gmail.com	JONYGOMES	@		8b62ad7c741d70390f360b7f0add80bb	f	\N	2012-11-30 11:30:47.670204	1	1993-01-01	\N	f		t
3925	Claudemir Oliveira do Nascimento	claudemiroliveira2014@gmail.com	Claudemir	@		5e99b2d29cc808a543d9d5fef86dada1	f	\N	2012-11-29 13:34:42.186775	1	1997-01-01	\N	f	claudemiroliveira2014@gmail.com	t
3742	ADERLANIA HENRIQUE DE OLIVEIRA	aderlaniaadm@gmail.com	aderlania	@		cda59708e288b4f21929964d85c4fff5	f	\N	2012-11-27 11:45:02.405767	2	1990-01-01	\N	f		t
3926	Douglas Mendes Martins	dougmendes91@hotmail.com	Douglas	@		db7ffaa2087165339b1b2b5eb70a219b	f	\N	2012-11-29 13:34:43.544623	1	1996-01-01	\N	f		t
4134	jhonatan dias	carlosjhonatan48@hotmail.com	jon jon	@		ceead61014ef8d7d24de21b3322b2618	f	\N	2012-11-30 22:05:13.327474	1	1998-01-01	\N	f	carlosjhonatan2009@hotmail.com	t
4041	Francisco de Assis F	almeidaxalmeida@gmail.com	almeida	@		ada5c27e1a1d8baa3e0cd308e9c078a0	f	\N	2012-11-30 08:47:21.913658	1	1960-01-01	\N	f		t
4149	Emanuel Sousa	emanuel_sousa-7@hotmail.com	Emanuel Sousa	@		d693e6edbc516ae965139c396fb3b811	f	\N	2012-11-30 22:49:44.546895	1	1996-01-01	\N	f		t
4245	Katia Santos de Sousa	katiiasaantoos@gmail.com	katinha	@		065d0d5bb43ccab9a833a22230317c61	f	\N	2012-12-03 11:43:14.520461	2	1995-01-01	\N	f	katiiasaantoos@gmail.com	t
4341	Kelly Freitas	kellynha_garota@hotmail.com	kellynha	@		0f7c0fa6fb20458afbb249411034a7ba	f	\N	2012-12-04 08:46:14.757255	0	1995-01-01	\N	f	kellynha_garota@hotmail.com	t
4735	LUCAS TEODOZIO SILVA	teoboy_13@hotmail.com	TEODOZIO	@		fa3583140e52b1da968a7c6f40f502c7	f	\N	2012-12-05 21:38:17.418005	1	1995-01-01	\N	f	teoboy_13@hotmail.com	t
3744	wanielli galdino martins	waniellygaldinojbe@hotmail.com	vaninha	@		dd56afee80e6bfa0eba3ebbe32900208	f	\N	2012-11-27 12:17:45.187333	2	1994-01-01	\N	f	wanielly12@hotmail.com	t
3746	Bruno Henrique Graziano Costa	bruno_graziano@hotmail.com	graziano	@		77ab840706b4a89ec6953dbea720c578	f	\N	2012-11-27 14:51:09.821886	0	1986-01-01	\N	f	bruno_graziano@hotmail.com	t
3755	Samuel Bruno	brunohonoratos@gmail.com	Samuel	@		7a4d3f277a80533911bb1ad8732866e2	f	\N	2012-11-27 17:08:14.859633	1	1993-01-01	\N	f	brunohonoratos@gmail.com	t
3747	Francisco Lourisval de Araújo	lourisvaljunior@gmail.com	junior	@		9908e73ac01885279f0882390cbbc325	f	\N	2012-11-27 15:30:50.511521	1	1979-01-01	\N	f		t
3786	Artur Emilio de Queiroz	arturemilio.ae@gmail.com	Emilio	@		c57106f4f6a81ea9133bba02757b1f82	f	\N	2012-11-27 20:25:46.106777	1	1990-01-01	\N	f		t
3756	PRISCILA DE SOUZA ALMEIDA	prihdesa@gmail.com	Priiih	@priihalmeida		44f93e8631985b8768c320cb78937894	f	\N	2012-11-27 17:46:53.99819	2	1990-01-01	\N	f	prihs.almeida@facebook.com	t
4442	Maria Angelina Ferreira Pontes	garota17ce@hotmail.com	angelina	@		9d4d70ac5d2c8a70f227f6239c11de05	f	\N	2012-12-04 21:56:20.768671	2	1994-01-01	\N	f	angel1994@bol.com.br	t
3797	Lidiane Bandeira Ramos	lidiane.bandeira93@gmail.com	Lidiane	@		dbb6cb1754e2f676a31bff1c09d8b048	f	\N	2012-11-27 21:47:43.061487	2	1993-01-01	\N	f		t
3760	Pedro Felipe Ferreira Lima	felipe.lima1996@hotmail.com	Liip3Lim4	@Liip3lim4		d3ce9efea6244baa7bf718f12dd0c331	f	\N	2012-11-27 18:31:15.147347	1	1996-01-01	\N	f	felipe.lima1996@hotmail.com	t
3751	Carlos Daniel de Oliveira Castro	dancasttro@gmail.com	dancasttro	@dancasttro		b1b0f284148a1b36edf95735d0150ad1	f	\N	2012-11-27 16:15:26.890762	1	1981-01-01	\N	f		t
3761	Matheus Loureiro	matheuslou@globo.com	Loureiro	@mloureirao		3def87c5f6c8310b60d7d91a1abd48ae	f	\N	2012-11-27 18:39:16.526158	1	1996-01-01	\N	f	facebook@loureirotec.com	t
3749	Elberson Jeferson dos Santos Barboza	jefincomando@hotmail.com	Jeferson	@		3b45514c6fcde77a1b8b20986fd445db	f	\N	2012-11-27 16:01:19.620264	1	1993-01-01	\N	f	jefincomando@hotmail.com	t
2636	Germano Nunes	g3rm4n0lp@gmail.com	germano	@		f812d52025a75a8046de665023bb1e5d	f	\N	2011-11-26 10:55:57.389957	1	1991-01-01	\N	f		t
3852	Valter Duarte de Lima Júnior	valterduarte507@gmailo.com	Valter	@		fa62e017fc541c379885f0d61c408f6f	f	\N	2012-11-28 20:58:04.012	1	1995-01-01	\N	f	juniorvalter25@hotmail.com	t
3752	Carlos Henrique Freitas dos Santos	carlosce@gmail.com	kaique	@		426254b8746f2473da418a6674e9c11d	f	\N	2012-11-27 16:40:44.088638	1	1984-01-01	\N	f		t
3805	Isadora Kristhny Rocha Sousa Gomes	isadora_2809@hotmail.com	Isadora Kristthny	@		c2584194b6c18df16e4f6d220fc2646e	f	\N	2012-11-28 00:01:40.052582	2	1996-01-01	\N	f	isadora_kris@hotmail.com	t
3753	Felipe da Silva Rodrigues	rodriguesfelipe20@gmail.com	Felipe	@feforodrigues		6bc0005763007489e1edf3f8e15fce16	f	\N	2012-11-27 16:42:16.641508	1	1992-01-01	\N	f	gt_felipe@hotmail.com	t
3811	alan kleber	philphilshow@gmail.com	phil phil show	@		62032588f910cb264f7907222346e817	f	\N	2012-11-28 08:54:51.150513	1	1998-01-01	\N	f	philphilshow@gmail.com	t
3754	Darlan Clarindo de Sousa	dcsdarlan@gmail.com	dcsdarlan	@_dcsdarlan		09966dfa16b1481a124850c2506016b5	f	\N	2012-11-27 17:03:20.479634	1	1987-01-01	\N	f		t
4005	davyla rayane da silva lima	davylalima@gmail.com	davyla	@		7556da2aec2e1984afb50cb4324b2a36	f	\N	2012-11-29 21:33:21.752818	2	1993-01-01	\N	f		t
3816	Ana Leticia Silva de Queiroz	leticiaqueiroz21@gmail.com	leticia	@		bce616253b1a73acc4a92449c0699603	f	\N	2012-11-28 09:37:04.372958	2	1994-01-01	\N	f		t
3759	Ermeson Santhus	ermeson__xd@hotmail.com	__22KU-	@		65ab27f55a1bc62c75c8b0c7aa328f12	f	\N	2012-11-27 18:27:16.248805	1	1992-01-01	\N	f	ermeson__xd@hotmail.com	t
1698	antonio jeferson pereira barreto	jefersonpbarreto@yahoo.com.br	Russo 	@		a93f9f654be3e6ac5b637c09a0238e1f	t	2012-11-28 12:02:50.884317	2011-11-22 23:28:11.921403	1	1990-01-01	\N	f	russo.xxx@hotmail.com	t
3828	Gilson Gondim de Oliveira	gilsongondim@hotmail.com	Gilson Gondim	@gilsongondim		8a17ea2bbdec5703608306b19ce8bfa8	f	\N	2012-11-28 15:10:24.476756	1	1982-01-01	\N	f		t
3877	Bárbara Barros Carlos	www.barbaraa@gmail.com	Babi-Wan	@babi_wan	http://relatoriodasituacao.com.br/relatorio/	e1108218ca1ff868ae71ca697bd386f3	f	\N	2012-11-28 22:59:31.015331	2	1992-01-01	\N	f	babi.wan.kenobi@facebook.com	t
1167	DIEGO FARIAS DE OLIVEIRA	diegofarias06@hotmail.com	Diego Farias	@		b9eec52c683e9c7a42d9c7a01eea88c6	t	2012-11-28 18:57:34.811912	2011-11-21 20:05:35.163636	1	1993-01-01	\N	f	diegofarias06@hotmail.com	t
4053	Alexmar Matos Queiroz	alexmm001@yahoo.com.br	Alexmar	@alexqueiroz		98a8706df9c043aec86678afa8ec0344	f	\N	2012-11-30 10:08:49.379217	1	1995-01-01	\N	f	alexmm001@yahoo.com.br	t
3889	Andreza de Sousa Alves	dengozaam@hotmail.com	Andreza	@		6452acf5248a2fc532d3cb393d7f6f56	f	\N	2012-11-29 09:37:48.875027	2	1994-01-01	\N	f	dengozaam@hotmail.com	t
4027	Lorrana Laurindo dos Santos	lorranalaurindosantos@hotmail.com	Lorrana	@		b20381779d93f78a5bbe230ac3a9e543	f	\N	2012-11-29 21:56:55.421643	2	1998-01-01	\N	f		t
3897	Taiane	taianediasaguiar@gmail.com	tatazinha	@		860b2f1abab22e918104544b4fa5ea8b	f	\N	2012-11-29 09:55:53.793341	2	1987-01-01	\N	f		t
3913	crislanne jacinto do nascimento	lannynha.infor@gmail.com	lannynha	@		c7acf52a44fe080db8b0c8ad846c6052	f	\N	2012-11-29 12:33:16.193388	2	1995-01-01	\N	f	crislanne.tuf@hotmail.com	t
3901	Carlos Augustinho Souza Andrade	carlos_augustinho1@hotmail.com	augustinho	@		cb99674f835cbabc35ce4ad8f9ee3734	f	\N	2012-11-29 10:01:00.094631	1	1996-01-01	\N	f	carlos_augustinho1@hotmail.com	t
3905	gleidiane	gleidyannecosta@hotmail.com	gleidy	@gleidyannecosta		f3e56a34a990115e750561fce6f9eb84	f	\N	2012-11-29 10:04:12.586277	2	1995-01-01	\N	f	gleidyannecostaa@hotmail.com	t
3750	Maria Fabiana	fabiananogueira07@gmail.com	Fabiana	@		cdc37578e1188fe5b65d8d28243353fd	f	\N	2012-11-27 16:11:24.269369	2	1987-01-01	\N	f	fabyan.bongiovi@hotmail.com	t
4063	Edigley Barboza da Silva	edigleybarboza@gmail.com	edigleyedy	@		02e8c9e66fac025805c3a8d7e4015686	f	\N	2012-11-30 11:31:13.43284	1	1993-01-01	\N	f		t
3743	RAIMUNDO PEREIRA DE OLIVEIRA	raimundomca@gmail.com	raimundinho	@		fa6f336fe757e2ce8b0d0683bebeaa4b	f	\N	2012-11-27 11:47:50.470719	1	1986-01-01	\N	f		t
4042	Rachel Patricio da Rocha	rachel.patricio.rocha@gmail.com	Rachel	@		c86dcb0542d16bf963df699c037423d8	f	\N	2012-11-30 08:53:23.724719	0	1997-01-01	\N	f		t
4239	Glaurerison H R da Silva	glaurrerison@gmail.com	glaurrerison	@		0d5ca31712f3097f5e8ba3212880cb75	f	\N	2012-12-03 11:40:51.365251	1	2011-01-01	\N	f		t
4150	Emanuel Sousa	mellg_007@hotmail.com	Emanuel Sousa	@		a0968555e287c70634fb514b12bc2e50	f	\N	2012-11-30 22:52:27.311945	1	1995-01-01	\N	f		t
4072	Sheyla Maria Martins Pontes	sheyla_live@hotmail.com	Sheyla_M	@		ec2adedf267fc55a525f7e48be245ec7	f	\N	2012-11-30 12:01:40.539857	2	1992-01-01	\N	f		t
4708	Francisca Carolina Ribeiro de Oliveira	francisca.carolina@hotmail.com	Carolina	@		8c69669dc35f72eb1478b0e07470c354	f	\N	2012-12-05 20:10:20.322715	2	1992-01-01	\N	f	francisca.carolina@hotmail.com	t
5034	Gilberto Luis Moraes Pessoa	gilberto@luiz.com	Gilberto	@		25adf898ec1e0198e7f26da189b77be4	f	\N	2012-12-06 17:05:44.422428	0	1993-01-01	\N	f		t
5366	Rebeca Mesquita Freitas	rebecat_patty@hotmail.com	Bekinha	@		ba4fa6b1e770965f154769e61b6ef57c	f	\N	2012-12-08 09:48:52.346543	0	2011-01-01	\N	f		t
3763	Breno Lucas Bezerra Cavalcante	Barra-breno@hotmail.com	Brenim	@		ee413d0874a92629cadb32768b36d692	f	\N	2012-11-27 18:40:08.80488	1	1997-01-01	\N	f	Brenocavalcante2@hotmail.com	t
3775	Juliana Felix da Silva	julyanna.felix@hotmail.com	Juliana	@		18cca74f35daf68326da3263ac30fac5	f	\N	2012-11-27 20:01:39.851396	2	1996-01-01	\N	f	julyanna_felix@hotmail.com	t
3767	Matheus coelho de sousa	matheuscoelho.sosua@gmail.com	Coelho	@		19860e322337021d60887b766e111c63	f	\N	2012-11-27 19:03:02.373626	1	1996-01-01	\N	f		t
3787	Wanderson Lyncon	lynconhp@hotmail.com	Lyncon	@		9796a5764c820c1bd94ff9d42a1f69ab	f	\N	2012-11-27 20:32:31.493824	1	1993-01-01	\N	f	lynconsg@hotmail.com	t
3770	Jefte Justino Alencar	jefte.justino@gmail.com	Pikeno	@		569b7df1eb0aaba46e9fa55254a17fc0	f	\N	2012-11-27 19:17:56.709777	1	1996-01-01	\N	f	jefte_pikeno@hotmail.com	t
3771	Priscyliane da silva Melo	priscylianemelo@hotmail.com	priscyliane	@		a54492793bbadf026fd3395a37b24871	f	\N	2012-11-27 19:25:09.643537	2	1995-01-01	\N	f	priscylianemelo@hotmail.com	t
3842	Evaniele dos Santos Andrade	evaniele112@gmail.com	Nyelly	@		a1e301a298a2469f3f24dec52daa05a5	f	\N	2012-11-28 19:04:36.478773	2	1996-01-01	\N	f	evaniele112@gmail.com	t
3772	Paulo Anderson Marinho	pauloandersonufc@hotmail.com	Paulo Anderson	@		905d4d8a4677b565a197e1fe37489ec1	f	\N	2012-11-27 19:44:19.065941	2	1989-01-01	\N	f	pauloandersonufc@hotmail.com	t
3798	Feynman Dias	feynmandn@hotmail.com	Feynman	@		105a0446eb1c7688650227463a028bf4	f	\N	2012-11-27 22:30:14.310224	1	1995-01-01	\N	f	feynmandn@hotmail.com	t
3774	Andressa Cândido da Silva	andressacandiido@gmail.com	Andressa	@		ab5ccf9ed7fecb4da959745bba798e21	f	\N	2012-11-27 19:59:52.542224	2	1996-01-01	\N	f	candido-andressa@hotmail.com	t
3806	wesley silva saraiva	wesley.sr7@outlook.com	wesley	@		17245fc2efc329b713ddfce60994d721	f	\N	2012-11-28 00:03:22.423651	1	1988-01-01	\N	f		t
3777	André Gadelha Rocha 	andre1.2.3@live.com	Gadelha	@		b960602f6f66254a155dd40f2d11cd8d	f	\N	2012-11-27 20:02:51.273915	1	1994-01-01	\N	f	andre1.2.3@live.com	t
3812	Brenner	darleyxp@hotmail.com	nenhun	@		1567cff57baea16cb71ee4ddef788166	f	\N	2012-11-28 08:55:09.217302	0	1999-01-01	\N	f	darleyxp@hotmail.com	t
3778	Francisco Francisnando de Souza Silva	odnansil@hotmail.com	Nando de Souza	@		54ac67d1a74f1f5e960ea6904ed9bebf	f	\N	2012-11-27 20:05:01.674242	1	1987-01-01	\N	f	odnansil@hotmail.com	t
3773	Ingred Gomes Oliveira	ingred.go16@gmail.com	Ingred	@		19cf24d5b024b28d2dd159a472dec1f5	f	\N	2012-11-27 19:59:34.44485	2	1996-01-01	\N	f	ingredaceiak@hotmail.com	t
5367	Nara Livia da Silva Costa	naraemoxinha1@live.com	narinha	@ivia_nara		077292ab8cb4c8febb291cdb0e9c2e27	f	\N	2012-12-08 09:49:18.962442	2	1997-01-01	\N	f	naraemoxinha1@live.com	t
3848	Lucas Weiby Souza de Lima	lucas13662@gmail.com	Luquinhas	@LucasWeibySouza		a741239e06808cf5a2a9e9106aab1f2d	f	\N	2012-11-28 19:25:42.988441	0	1998-01-01	\N	f	lucas.weiby.9@facebook.com	t
4709	Francisco Ednilton Lima Honorato	edniltonn@hotmail.com	ed.lima	@		fffd4b5022a69f4721a570de63befbed	f	\N	2012-12-05 20:14:27.727557	1	1995-01-01	\N	f	edniltonn@hotmail.com	t
3779	Natália Loiola Braga	nathalyabraga1@gmail.com	Natália	@		20ef6484a32a1bb9c8c34d4239b7c852	f	\N	2012-11-27 20:10:19.692581	2	1996-01-01	\N	f	nathalyabraga1@hotmail.com	t
3780	Paulo André da Silva Saraiva	passsl77@hotmail.com	mago paulo	@		f8f46495231f6aac659f3a18d272a8dd	f	\N	2012-11-27 20:13:39.035571	1	1977-01-01	\N	f		t
3898	Marcelo de Sousa Cavalcante	mscavalcante@hotmail.com	marcelo	@		c82cffec2f6ada08577885281d167b66	f	\N	2012-11-29 09:56:58.302159	1	1998-01-01	\N	f	mscavalcante17@hotmail.com	t
3829	Camila Torres	camilatorres.ce@gmail.com	Camila Torres	@Camilatorresmcr		c4c7b01fbd2b9ac3d4cf6f80f31be934	f	\N	2012-11-28 15:11:05.181404	2	1994-01-01	\N	f	camilatorres.1994@gmail.com	t
3835	Brenda da Silva Araujo	brenda_silvaaraujo@hotmail.com	Brenda	@		fc55f34d26cf96b56a4133fdf1a62148	f	\N	2012-11-28 15:27:00.664324	2	1996-01-01	\N	f	brenda_silvaaraujo@hotmail.com	t
1081	Leandro Menezes de Sousa	leomesou@gmail.com	Leandro	@		1e6b4aea63e80502fab0de183112f1cd	t	2012-11-28 17:55:14.753934	2011-11-20 15:39:36.944764	1	1992-01-01	\N	f	leomesou@facebook.com	t
3871	Heyde Adilles Moura Cavalcante	moura.heyde@gmail.com	heydemoura	@heydemoura	http://fissuratech.blogspot.com	f8ad09245e56dd60ffb963badc9ad17c	f	\N	2012-11-28 22:36:15.193133	1	1992-01-01	\N	f		t
3902	Felipe dos Santos Alves	felipe.s.alves95@gmail.com	Felipe	@		c194c9485a5d97131904022de7ac650c	f	\N	2012-11-29 10:01:12.764272	1	1995-01-01	\N	f	felipeknd08@hotmail.com	t
3884	Felinto Jose Mamede Aguiar Filho	fifilho@gmail.com	Aguiar	@		deb7fafc641eb95b28d5ad03ae6ca214	f	\N	2012-11-29 00:12:13.613706	1	1989-01-01	\N	f		t
3914	José Joelton Martins Rocha	josejoelton.1997@gmail.com	Joelton	@		af8250c58998402255a85f9ebc262bbd	f	\N	2012-11-29 13:03:41.731431	1	1997-01-01	\N	f	josejoelton.1997@gmail.com	t
3890	Elaine Helena POntes dos Santos	elainesantos95@hotmail.com	Elaine	@		2682e8883eb9ddf1df3cfc8296940f1d	f	\N	2012-11-29 09:38:27.425509	2	1995-01-01	\N	f	abusadinha58@hotmail.com	t
4215	Francisco Douglas Ferreira da Silva	fdouglasfsilva@hotmail.com	Douglas	@		39a927cd820b19c835c488a7d8c38222	f	\N	2012-12-02 11:51:57.801278	1	1990-01-01	\N	f	fdouglasfsilva@hotmail.com	t
3906	nayara dos santos silva	nayara.dossantos.inf@gmail.com	nayarinha	@		e62cef3d9ad11040e92aabddeb30aa6e	f	\N	2012-11-29 12:14:04.498537	2	1992-01-01	\N	f	nana.sexy15@hotmail.com	t
4028	Maíra Morais de Sousa	mairinha11@hotmail.com	Maira Morais	@		b39c407e35fc2633f6c149a1f9621517	f	\N	2012-11-29 21:58:19.825507	2	1996-01-01	\N	f	mairinha11@hotmail.com	t
4136	larissa keylla dos santos braga	acza_sanora@hotmail.com	princesa	@		1f81e274ff50e3dc5dcfb4ec6c065a48	f	\N	2012-11-30 22:27:47.976455	2	1997-01-01	\N	f	acza_sanora@hotmail.com	t
3918	Daniel Caetano Soares	Dannyel_caetano@hotmail.com	Daniel	@		e40aca3a6bb4e42879ac8bb608c78749	f	\N	2012-11-29 13:07:12.548339	1	1997-01-01	\N	f	Dannyel_caetano@hotmail.com	t
3853	Antonio Victor Abreu Martins	antoniovictor585@gmail.com	cabeça	@		426e8e892b9168a12706b87222cc5b5d	f	\N	2012-11-28 21:13:47.926001	1	1997-01-01	\N	f	antoniovictor585@gmail.com	t
3922	sammyra santos	sammyra_spfc@hotmail.com	myrynha	@		c680d0ec4b0e9aa4a698c83efb824a1e	f	\N	2012-11-29 13:21:01.657227	2	1997-01-01	\N	f	sammyra_spfc@hotmail.com	t
4043	isnadia monteiro lima	iza-azul@hotmail.com	isnadia	@		23ae5226805a520575ab32a8db01b999	f	\N	2012-11-30 08:58:01.084684	2	1986-01-01	\N	f	iza-azul@hotmail.com	t
3965	Bruna Eloise	bru.hinrichs@hotmail.com	Bruna eloise	@		c266d97a9437a80a2e248e53d4771d56	f	\N	2012-11-29 18:50:24.432888	2	1996-01-01	\N	f		t
4232	rubens marques	rubens_aci@hotmail.com	Rubinho	@		7b5e644b2e11b89c25b143f38c00cb42	f	\N	2012-12-03 11:40:04.573127	1	1993-01-01	\N	f	rubens_cobicado@hotmail.com	t
525	Marcello de Souza	marcellodesouza@gmail.com	marcello	@marcellodesouza	http://www.treinolivre.com	3231f88bfcea447317a6a1aa72958e29	f	\N	2011-11-03 13:58:30.15612	1	1972-01-01	\N	f	marcellodesouza@gmail.com	t
4100	Francisca Irislania da Silva Pinheiro	irislania.pinheiro@gmail.com	Irislania	@		e7513c8ca3026a54fbc0dd65a9445dc0	f	\N	2012-11-30 14:30:52.932558	2	1993-01-01	\N	f		t
3940	Myrian Kelly de Oliveira Araújo	ana_emylle@hotmail.com	Myrian Kelly	@		6ad4b57793a3d4731eed4b3c6aabbb63	f	\N	2012-11-29 14:39:57.618391	2	1995-01-01	\N	f	ana_emylle@hotmail.com	t
4029	Amanda Richer Laurindo dos Santos	amandaricher_rebelde@hotmail.com	Amanda	@		e642944e7997b9f1e441849859141a94	f	\N	2012-11-29 22:01:01.792876	2	1996-01-01	\N	f		t
3941	marina jéssica evangelista nunes	marinanunes2011@hotmail.com	marina	@		501a7300020a0559b4027d1cd8df9ac1	f	\N	2012-11-29 15:09:24.699911	2	1999-01-01	\N	f		t
3942	marcele camurça ribeiro	marcelecamurca@hotmail.com	anginha	@		b8699baf891cf0121ff7bca701503c71	f	\N	2012-11-29 15:11:11.062543	2	1998-01-01	\N	f		t
3943	Gabriel Nascimento Camurça	gnascimentocamura@gmail.com	gabrielNC	@		cd8f10cd650c8681d335e7623bb980c3	f	\N	2012-11-29 15:13:37.059613	1	2000-01-01	\N	f		t
3944	Glaudianny da Silva Ferreira	glau_deus@hotmail.com	Dadá06	@		db185c075b212d92cdc8d35bdecfebfe	f	\N	2012-11-29 15:14:53.051919	2	1995-01-01	\N	f		t
3945	ciliano carvalho martins	cilianomartins@hotmail.com	ciliano	@		a2b55ff7ada82101e402d72a88b1c9b2	f	\N	2012-11-29 15:16:07.772644	0	1998-01-01	\N	f		t
3946	benyon carvalho martins	benyonramalho@hotmail.com	ben 10	@		2885068b6dc25fc4031a9aaa1571ec53	f	\N	2012-11-29 15:19:17.857096	0	2000-01-01	\N	f		t
4443	Júlio Serafim Martins	serafimjuliom583@gmail.com	Júlio	@	http://sige.comsolid.org/participante/add	a208c6bf04cbc55ea2d890773f83532f	f	\N	2012-12-04 21:59:47.093327	1	1996-01-01	\N	f	serafimjuliom583@gmail.com	t
3947	ana mayara da silva sousa	mayara_silva_13@hotmail.com	negona	@		a94b19e320c23bf593515d50d746aa92	f	\N	2012-11-29 15:21:29.998647	2	1999-01-01	\N	f		t
4454	emanoel carlos	emanoelcarlos99@hotmail.com	emanoel carlos	@		d539faea1013f31018db2c8ac7ab69f9	f	\N	2012-12-05 00:08:39.47982	1	1995-01-01	\N	f		t
3948	Auana Jennifer Silva Costa	auaninha_10@hotmail.com	aninha	@		5230ae11cd544462d23a507222eeda3d	f	\N	2012-11-29 15:22:42.534371	2	2000-01-01	\N	f		t
3949	Aquila mateus profileo  nunes	mateus-mengo07@hotmail.com	safadão	@		d609e403509dbe219ef35fc4e1ee82a4	f	\N	2012-11-29 15:25:33.899658	1	1997-01-01	\N	f		t
4152	Vladiane Silva	Vladiane01@hotmail.com	Vladiane	@		bfa45f99ff0ade9fc269620fac5bd173	f	\N	2012-11-30 22:54:19.964468	2	1995-01-01	\N	f		t
4073	Eliseudo tomaz de carvalho	olavio_2012@hotmail.com	olavio	@		6fb4aa0a77e7a82827ac407847995b71	f	\N	2012-11-30 12:54:19.342873	1	1993-01-01	\N	f	olavio_2012@hotmail.com	t
4216	karoline brandão dos santos	karoline-brandao@hotmail.com	karoline	@		a2a82c04f0aab2c0e3663b118f7aaa20	f	\N	2012-12-02 12:30:07.452417	2	1993-01-01	\N	f	karoline-brandao@hotmail.com	t
3953	vanessa	vanessa-britos2@hotmail.com	Vanessa	@		1b00afb3ae5017388ef4e87deffd1c5a	f	\N	2012-11-29 16:57:52.877745	2	1998-01-01	\N	f	wanessa_brito@gmail.com	t
4078	Higor Andrade	fhigoras@hotmail.com	Higor A.	@		1864db51fe48d610451c6ba5f7afeb1b	f	\N	2012-11-30 13:21:08.69095	1	1997-01-01	\N	f	higorandrade-28@hotmail.com	t
4318	Maria Vitória Moreira Freitas	vihfreitas123@gmail.com	luucky	@		4df1e57a92b10d6eb7b4d4f1ed1e0f48	f	\N	2012-12-03 21:17:58.188907	2	1996-01-01	\N	f	vihfreitas123@gmail.com	t
4246	Francisco Yago Alves da Silva 	Yago.Alves.9047@facebook.com	yago Alves	@		079f00f512580d7065528ddc5b41fe17	f	\N	2012-12-03 11:44:16.120017	1	1994-01-01	\N	f	Yago.Alves.9047@facebook.com	t
4158	Nathanael Freitas	nathan.apolo@gmail.com	Nathan Freitas	@nathanfz		341eb2171a9059c359a9bf87799c6dc3	f	\N	2012-12-01 00:04:20.439545	1	1992-01-01	\N	f	nael_apolo@hotmail.com	t
4095	Weverton 	fmesquita_weverton09@live.com	Mazembe	@		0007addc39fa23423c1fcbda94fb3554	f	\N	2012-11-30 13:49:41.654164	1	1996-01-01	\N	f	fmesquita-weverton@live.com	t
3951	Emanuel Bruno de Oliveira	emanuel-bruno@hotmail.com	Bruninho	@emannuelbruuno		dd32991d8394dabfb7878260cd20177b	f	\N	2012-11-29 16:31:06.42888	1	1989-01-01	\N	f	emanuel-bruno@hotmail.com	t
4044	diego 	diego.li.car@gmail.com	diego.lc	@		e6d2e8362f35a0a8d86b616dbc50e3d6	f	\N	2012-11-30 08:58:35.421617	1	1991-01-01	\N	f	diegomoleque@hotmail.com	t
4252	vitoria	vitoriamoreiravitoriano@gmail.com	vitora	@		3a5b2ea54094221e5b2615ec7cd09c15	f	\N	2012-12-03 11:46:49.470663	2	1996-01-01	\N	f	vitoria.881@hotmail.com	t
4103	SAMIA CARLA SANTIAGO FONSECA	carlla_ssantyago@hotmail.com	carlinha	@		9e4d977761c15635eb0eaa4eaec4af17	f	\N	2012-11-30 14:46:47.890812	2	1996-01-01	\N	f	carlla_ssantyago@hotmail.com	t
4107	SAMUEL NUNES LIMA 	mu.el@hotmail.com	cocãoo	@		f97c19dbffff2cc94d597222e55c2f57	f	\N	2012-11-30 15:15:45.554216	1	1995-01-01	\N	f	mu.el@hotmail.com	t
4111	PEDRO LAEL BEZERRA TEXEIRA	pedrolael101@hotmail.com	laelll	@		6a4b101c37f0cdda3b1021dcfcbe2be5	f	\N	2012-11-30 15:36:06.361216	1	1997-01-01	\N	f	pedrolael101@hotmail.com	t
4064	José Gilson de Souza Lima	gilsonlima245@gmail.com	gilsonplay	@		e1e3dfbe8403ec247da7d6665cd53527	f	\N	2012-11-30 11:31:18.886619	1	1995-01-01	\N	f		t
4119	Francisco Luciano Lopes da Silva	luciano.lopess07@gmail.com	luciano	@		2fdf08f1d02fb3e19a348700a3739422	f	\N	2012-11-30 17:19:22.038902	1	1990-01-01	\N	f		t
4179	klebson	klebsondealmeida21@gmail.com	klebson	@		cb5d28cfb56d4ae7041c00c611c72db2	f	\N	2012-12-01 15:40:55.719719	1	1996-01-01	\N	f		t
4462	Raílson Alves Felix	raicqc@hotmail.com	Raí            	@		403bc1dfb89c845f60523becec3e6d16	f	\N	2012-12-05 09:23:50.453938	1	1996-01-01	\N	f	raicqc@hotmail.com	t
4233	JONATAN SOARES DA SILVA	jonatan.conectado@gmail.com	JONATAN	@		2d39cf8e7c2a998d49fa079ed6479da3	f	\N	2012-12-03 11:40:16.305127	1	1994-01-01	\N	f	jonatansoares14@hotmail.com	t
4333	Elisabeth	betthmorfi@hotmail.com	Beth Silva	@		97028aaa708659b66e4e6c5eb59997d1	f	\N	2012-12-04 07:36:24.579836	2	1985-01-01	\N	f	betthsangalo@hotmail.com	t
3939	Marcílio José Pontes	marcilio.pontes@hotmail.com	Marcilio	@marciliopontes	http://marciliopontes.blog.com	96ed2c7871a46a70f5e8151a28d4770c	f	\N	2012-11-29 13:57:09.193861	1	1981-01-01	\N	f	marciliopoint@hotmail.com	t
4342	jonata  alves de matos	jonataamatos08@gmail.com	jonata	@jonata08matos		b8fdf4a48d941561577a02de03a8ef2d	f	\N	2012-12-04 09:19:08.662986	1	1986-01-01	\N	f	jonataamatos@hotmail.com	t
4347	Crislane	crislanysoares@gmail.com	nanazinha	@		04e52273da7a81bc16991d6059c5a20a	f	\N	2012-12-04 11:07:40.130861	2	1995-01-01	\N	f	crislanevieira2@gmail.com	t
4471	laiza eduardo dos santos	laizah14pf_@hotmail.com	laizinha	@		99650c4117cd91b0eb6142c0ea9d64dc	f	\N	2012-12-05 09:37:01.248771	2	1995-01-01	\N	f	laizah14pf_@hotmail.com	t
4710	Felipe De Sousa Milhomens	Sousa.felipe06@gmail.com	-Joby-	@		e8c77cc81b649967e85d593a15073cc2	f	\N	2012-12-05 20:17:19.713631	1	1993-01-01	\N	f		t
5368	ERICA CASSIANO DIAS	erica15cassiano@gmail.com	ERICA DIAS	@		95bb87ac661f0ea844ecff2f59920c53	f	\N	2012-12-08 09:49:21.247655	2	1996-01-01	\N	f		t
5036	Marcelo dos Reis Cavalcante	m.reis.cavalcante@bol.com.br	marcelinho	@reiscavalcante		57868761ddc7a39c7dac1aeffcd9b6db	f	\N	2012-12-06 17:07:03.156907	1	1984-01-01	\N	f		t
5400	JAMELLY MARTINS DE FREITAS	jamelly_freitas@hotmail.com	JAMELLY	@		a39b46f0ff0c1dd58417e002887d5289	f	\N	2012-12-08 10:29:25.56233	1	1996-01-01	\N	f		t
4030	Maira Morais de Sousa	mayrasousa15@gmail.com	mairinha	@		e8298d64ce5fc0f2a4dc859fce554483	f	\N	2012-11-29 22:14:08.093609	2	1996-01-01	\N	f	mairinha11@hotmail.com	t
3957	FRANCISCO EDNALDO NASCIMENTO DE SOUSA	jasenildo@gmail.com	ednaldojta	@Naldinhojta		1fd719e13fd96a15c1e6ff6b9dd3be68	f	\N	2012-11-29 18:07:56.702662	1	1992-01-01	\N	f		t
3960	Franscisco Douglas Lima Monteiro	fdouglaslima@gmail.com	Douglas	@		a4fe8265facb6c13dd74f465e3504d88	f	\N	2012-11-29 18:40:59.770205	1	1996-01-01	\N	f	douglaslgm02@hotmail.com	t
4108	YGOR ALCANTARA GONDIM 	kikogondim@hotmail.com	ygorrr	@		c7fdfd66c1fff7ba7126912e6ae9a434	f	\N	2012-11-30 15:18:30.948673	1	1995-01-01	\N	f	kikogondim@hotmail.com	t
4045	ingrid maria ribeiro sousa	ingridmariasousa@gmail.com	ingdizinha	@		3fa1c91450070f2b51015b240a6e9acd	f	\N	2012-11-30 09:05:01.817407	2	1968-01-01	\N	f	ingridmariasousa@yahoo.com.br	t
3958	Fernando Castro	fernandotks1@hotmail.com	Fernando Castro	@		a82bdca8a2defad035ea1e0f01f62ce4	f	\N	2012-11-29 18:26:00.963448	1	1995-01-01	\N	f	fernandotks1@gmail.com	t
4234	Hercilio Felipe Torres Vasconcelos	herciliofelipe@gmail.com	felipe	@		9fe1fb143dc2f7103bb9c95a15835b4f	f	\N	2012-12-03 11:40:18.961725	1	1996-01-01	\N	f	bonecodetrapo.punk@gmail.com	t
4217	Flaviana Castelo	flavicastelocc@gmail.com	flavicastelo	@		d06babf9f78c575e12ed6fc433870caa	f	\N	2012-12-02 13:22:25.985582	2	1990-01-01	\N	f	flavicastelo@facebook.com	t
973	JONATAS HARBAS ALVES NUNES	jonatasnice@yahoo.co.uk	harbas	@		78a6d06bea52dbfba7f03f94282290bc	t	2012-11-30 15:55:06.335325	2011-11-17 12:26:21.367156	1	1993-01-01	\N	f	jonatasnice@yahoo.co.uk	t
4065	Tamires Fontenele Souza	thamyresfontinelle@hotmail.com	 thami'   	@		cea01f849e28dccf635a4e543849b903	f	\N	2012-11-30 11:31:47.167096	2	1993-01-01	\N	f		t
3956	Kelvyn	john-kelvyn@hotmail.com	Cardoso	@		ef445d507f508419a2c7268e46ce62c0	f	\N	2012-11-29 17:36:19.577171	1	1992-01-01	\N	f	john-kelvyn@hotmail.com	t
3962	Katiane dee Mesquita	katianejmesquita2011@hotmail.com	Katiane	@		76749fc9ee3abd1350c322739e2aa6a1	f	\N	2012-11-29 18:48:51.175292	2	1996-01-01	\N	f	katianejmesquita2011@hotmail.com	t
4247	tamires	tamiesmerencio@gmail.com	thammy	@		e19ddbc8b2a13cf84357f4ad62786a2d	f	\N	2012-12-03 11:44:54.87745	2	1995-01-01	\N	f	tamires_tamy_@yahoo.com	t
4079	Marcelo de Sousa Cavalcante	mscavalcante17@hotmail.com	marcelo	@		3798405d81ce73e54acc5faeb301054d	f	\N	2012-11-30 13:25:15.479867	1	1998-01-01	\N	f	mscavalcante17_@hotmail.com	t
4319	Brenda kelly de oliveira ribeiro	brendakoliveira100@hotmail.com	oliveira	@		48cc0f49412dbb9efd529732826d8749	f	\N	2012-12-03 21:40:24.32698	2	1992-01-01	\N	f	brendakoliveira100@hotmail.com	t
4265	tamires	tamiresmerencio@gmail.com	thammy	@		a4eaad0803f98149f12d7c315aea04d0	f	\N	2012-12-03 12:08:24.759372	2	1995-01-01	\N	f	tamires_tamy_@yahoo.com	t
4096	Pedro Henrique Rufino Gadelha	pedro.rufino@gmail.com	cabeção	@		3b63bb7fc7df8f1e5977d7097a502d2a	f	\N	2012-11-30 13:50:23.530577	1	1995-01-01	\N	f	pedrox_0@hotmail.com	t
4334	Elisabeth	elisabethsilvasangalo@gmail.com	Beth Silva	@		cd5b9af56720f2e58b882ffc8a11d4a1	f	\N	2012-12-04 07:40:19.49327	2	1985-01-01	\N	f	betthsangalo@hotmail.com	t
2162	DJALMA DE SÁ RORIZ FILHO	djalmaroriz@yahoo.com.br	Djalma Roriz	@		700476dc6e22aeb4d16c4e778b2831f5	f	\N	2011-11-23 18:57:56.767793	1	1978-01-01	\N	f		t
4099	MARCUS VINICIUS BESERRA ARAUJO	markiin_mv15@hotmail.com	markiin	@		66cbbc6a885904ddc2047c52f145b23b	f	\N	2012-11-30 14:25:15.754432	1	1996-01-01	\N	f	markiin_mv15@hotmail.com	t
4104	PABLO ITALO DA SILVA SOMBRA	pablo_iti14@hotmail.com	pabloo	@		52f26a19b30f0700e82d538c4baa6e3c	f	\N	2012-11-30 14:57:57.242638	1	1996-01-01	\N	f	pablo_iti14@hotmail.com	t
4274	DAYANE BARROSO LUZ	dayaneblack@hotmail.com	lady day	@		4554e29a711656df684c3547f3f2041c	f	\N	2012-12-03 14:38:30.768126	2	1990-01-01	\N	f	dayblack1@hotmail.com.br	t
4116	Vitoria Emilly De Souza Vasconcelos	vitoriavasconcelos16@yahoo.com.br	neguinha	@		c4f35f1fb919f3e16517220bb9f98591	f	\N	2012-11-30 16:48:20.450609	2	1996-01-01	\N	f		t
4120	Pedro Leonardo Fernandes Pereira	leo92fernandes@gmail.com	Pedrinho	@		af965cb97b7b66637949646634555dda	f	\N	2012-11-30 17:51:22.984289	1	1992-01-01	\N	f	leonardo92fernandes@gmail.com	t
4122	Geylson	geylsonmartins@gmail.com	GêGÊ	@		72af002d55efdfe8a0b334bf2b3464bf	f	\N	2012-11-30 18:42:31.262145	1	1994-01-01	\N	f	joao_tuf@hotmail.com	t
3961	Daniele Abreu	vx_dannizinha@hotmail.com	Daniele	@		e013762612b8559c090a50eb635c9034	f	\N	2012-11-29 18:46:53.484434	2	1996-01-01	\N	f	daniabreuxvc@gmail.com	t
4123	Maria Renata da Silva	renatha_ce@hotmail.com	Renata	@		6dc8bb813d4c8b43ddaa870dcb92ce9c	f	\N	2012-11-30 19:21:45.035442	2	1989-01-01	\N	f	RenataSilva12@facebook.com	t
1037	Péricles Henrique Gomes de Oliveira	pericles_h@hotmail.com	Pericles	@pericleshenriq		12aebcea23ac1019b5d07bf929756e40	t	2012-11-30 22:59:08.029739	2011-11-18 22:58:26.906386	1	1990-01-01	\N	f	pericles_h@hotmail.com	t
3964	Isabella Menezes	isabellamenezes08@hotmail.com	Isabella	@		a0247669713b9575776b65f0386da63a	f	\N	2012-11-29 18:49:31.928587	2	1996-01-01	\N	f		t
3966	Nayara Paiva	narapaiva7@gmail.com	Nayara	@		3167b2cd15ce043439f9f4951ac8b65c	f	\N	2012-11-29 18:51:42.6916	2	1996-01-01	\N	f		t
3967	Nayara Florindo	nayaraflorindo@gmail.com	Nayara Florindo	@		59adee253b9a4b2f7b3edb0edf597b33	f	\N	2012-11-29 18:52:54.316994	2	1996-01-01	\N	f		t
3969	Mateus Silva	mateusdasilva82@gmail.com	Mateus silva	@		3aa809c8e4be1f6e002ad0c2256490f9	f	\N	2012-11-29 18:53:42.040051	1	1996-01-01	\N	f		t
5035	Ramon teles	RTramondk@gmail.com	shuradk	@		646f09c0f69a030ee0e4ccfba5191be8	f	\N	2012-12-06 17:06:25.523239	1	1996-01-01	\N	f	caroramontelkes@hotmail.com	t
4348	wellyngton braz	wbb1994@hotmail.com	wellyngtonbb	@wellyngtonbb	https://www.facebook.com/wellyngtonbb.wbb	d8ea0380703c77341ffc473c5d2fcdcd	f	\N	2012-12-04 11:07:54.933519	1	2011-01-01	\N	f	wellyngtonbb@hotmail.com	t
2596	Paulo  Alexandre Costa Siqueira 	alexcosta446@gmail.com	alexcosta	@		78bfc99ea6690b6ac1f7132b8d81ae0d	f	\N	2011-11-25 15:54:51.447021	1	1977-01-01	\N	f		t
4444	Kaio Breno Serafim Mariano	kaio_brenok9@hotmail.com	Kaio Breno	@		e15a7143ab2441e13db8ee52d6441d46	f	\N	2012-12-04 22:03:40.87498	1	1993-01-01	\N	f	kaio_brenok9@hotmail.com	t
4711	victor santos	victor.metal4e@gmail.com	victor	@		d307f50ac5530f9b93dffb2ffff11077	f	\N	2012-12-05 20:19:19.688	1	1996-01-01	\N	f	victor_lordkeior@hotmail.com	t
4455	anderson duarte	anderson.duarte11@gmail.com	anderson duarte 	@		0d9343125526c6bc9876f7a160664e4b	f	\N	2012-12-05 00:10:30.259182	1	1996-01-01	\N	f		t
4737	Douglas Roque dos Santos	dougllasroque@gmail.com	Yuukito Neko	@	http://thelegionofanime.blogspot.com	4bdb3c609cb2c51a229d7e4d72b574a3	f	\N	2012-12-05 21:39:37.598821	1	1995-01-01	\N	f	douglas_vipsantos@hotmail.com	t
5067	Amanda Maria Costa Santos	amcs.amanda@gmail.com	Amanda	@		02b7aca97ba318f0cf7ee7c20fc174f7	f	\N	2012-12-06 19:45:28.19774	2	1992-01-01	\N	f	amcs.amanda@gmail.com	t
4268	Carlos Alexandre de Lima	carlos-ale1986@hotmail.com	Alexandre	@		22762e62fa7f068022d38cda6b7f78b4	f	\N	2012-12-03 13:41:14.209777	1	2011-01-01	\N	f	carlos-ale1986@hotmail.com	t
5369	ANTONIO MAIKON DA SILVA GARCIA	maikon1046@hotmail.com	MAIKON	@		7a007fdf021171ae230d2fb0bf661d5e	f	\N	2012-12-08 09:51:13.076435	1	1997-01-01	\N	f		t
3970	Natalicio Nascimento	mosquitodainformatica@hotmail.com	Natalicio	@		cdbaf916622d476467a56e7d98c8a12d	f	\N	2012-11-29 18:54:53.203526	0	1996-01-01	\N	f		t
4112	Aron Souza Chula	aron.s.c@hotmail.com	jwrrasc	@		c411fe031eb862c8c52164aafce0934c	f	\N	2012-11-30 16:31:00.684499	1	1992-01-01	\N	f		t
3972	Katiane de Jesus Mesquita	katianejmesquita@gmail.com	Katiane	@		f710591d233a2a920921ce5e421f3e7b	f	\N	2012-11-29 18:55:56.90714	2	1996-01-01	\N	f	katianejmesquita@gmail.com	t
4009	franciberg ferreira de lima	lfranciberg@gmaill.com	FcBerg	@ffranciberg		4e48f94006bf0d905207a073ac47eb44	f	\N	2012-11-29 21:34:50.46463	1	1993-01-01	\N	f		t
4209	Felipe Everton	everton.faturamento@hotmail.com	Coelho	@felipebodyboard		fd9b09eea9adb1d43cb8f85c00aff7b0	f	\N	2012-12-02 02:44:09.456539	1	1988-01-01	\N	f		t
3968	Egnaldo Júnior da Silva Gois	egnaldopotter@hotmail.com	Egnaldo Jr.	@		566ec5d76dee9314abbc70b0adac2f11	f	\N	2012-11-29 18:53:23.299634	1	1996-01-01	\N	f	egnaldopotter@hotmail.com	t
4031	Henrique Angelo da Silva Junior	henri.j@hotmail.com	Henrique Junior	@		f399966e7848c8e06488638efc24cdfc	f	\N	2012-11-29 22:17:21.461023	1	1994-01-01	\N	f		t
3977	Karlos Ítalo Pedrosa Bastos	karlosinfbastos@gmail.com	Ferrim	@	http://www.facebook.com/karlositalo.p.bastos	97fffb7efc2912c1db88ff99ec6631d2	f	\N	2012-11-29 19:00:44.801061	1	1996-01-01	\N	f	karlosinfo27@gmail.com	t
3978	Walison Mota	walisonmota01@hotmail.com	Tapuio	@		c4f0a9bf693289d07c45081bcf969951	f	\N	2012-11-29 19:10:02.38016	1	1996-01-01	\N	f		t
4046	Fernanda	nandinhafernanda932@gmail.com	fernandinha	@		9b8bbada2e61e9ce9c2e9b6af7ee05b4	f	\N	2012-11-30 09:05:53.192959	2	1996-01-01	\N	f	nanda-ms2011@hotmail.com	t
3981	Márcio França	marciooliveira48@hotmail.com	França	@		be10789825d51630e560d48152528fba	f	\N	2012-11-29 19:23:20.149921	1	1992-01-01	\N	f	marciooliveira48@hotmail.com	t
4066	Bonk Rogis de Sousa Silva	bonkrogis@gmail.com	cabeça	@		d64a12abc0c90ebe3f9daf14c85afa79	f	\N	2012-11-30 11:32:57.706265	1	1992-01-01	\N	f		t
4235	Elisabeth da silva martins	betthmorfi@gmail.com	betinha	@		734a48c20ba174aff4bf2093e509111a	f	\N	2012-12-03 11:40:20.961387	2	1985-01-01	\N	f	betthsangalo@hotmail.com	t
4153	Wesley	alves.wesleya@gmail.com	wesley	@		8bd22baa830fe9e02243db448555239e	f	\N	2012-11-30 22:59:45.873658	1	1996-01-01	\N	f	alves.wesley@live.com	t
4080	Jeferson Araújo Nascimento	j.efersonaraujo@hotmail.com	Jefinho	@j_efersonaraujo		f32c857eb833cc710cc5a15e21ed20c2	f	\N	2012-11-30 13:25:18.946791	1	1996-01-01	\N	f	j_efersonaraujo@hotmail.com	t
3971	Herverson Sousa	herverson.sousa@gmail.com	Herverson	@		9ed624a5d77e2037d1419c0e39fe83be	f	\N	2012-11-29 18:55:48.904647	1	1996-01-01	\N	f		t
3979	Adriano José	adrianojose81@gmail.com	Adrikk	@		f4ad0b20ae4b076ea98c551513f491e0	f	\N	2012-11-29 19:17:15.477632	1	1997-01-01	\N	f	adrianojose81@gmail.com	t
3983	Carina	carinhynharay@gmail.com	Tanajura	@		2ccbcef9c139cf670d88a089a662bf7e	f	\N	2012-11-29 19:23:43.979355	2	1996-01-01	\N	f	carinhynharay@gmail.com	t
3976	Nadine Calisto	nadinecalisto@gmail.com	Nadine	@		112571116c31def8cdfb1cb92d6e0303	f	\N	2012-11-29 18:57:18.924105	2	1996-01-01	\N	f		t
4097	marcelo	marcelinhodygdin@hotmail.com	um dyg din	@		aad46304545e0f3995230f8f159ed0c4	f	\N	2012-11-30 13:50:41.74606	1	1998-01-01	\N	f		t
3974	Aniele Santos	aniele06@hotmail.com	Aniele	@		2037baa17b528e4f0cc919e557b09f87	f	\N	2012-11-29 18:56:32.124504	2	1996-01-01	\N	f		t
4101	Antonia Izamara Araujo de Paula	antoniaizamaraap@gmail.com	Izamara	@		b46aa85823db2ced204a1aed1b5b5098	f	\N	2012-11-30 14:32:03.139847	2	1991-01-01	\N	f		t
4218	ANDERSON WAGNER ALVES	anderson.wagner13@gmail.com	anderson	@		a29c9d654c6bd3160d9cec989e79ab4b	f	\N	2012-12-02 14:09:23.639616	1	1985-01-01	\N	f		t
4109	CARLOS EMANUEL NASCIMENTO SILVA	emanuel_clarinetista@hotmail.com	nielll	@		a262f6a0bdf0be19dab287820ed16058	f	\N	2012-11-30 15:26:42.107876	1	1995-01-01	\N	f	emanuel_clarinetista@hotmail.com	t
4159	marcos samuel magalhães menezes	marcossamuel15@hotmail.com	samuel	@		1295d62d59654f404bc9a8f8768ef895	f	\N	2012-12-01 00:04:29.820053	1	1993-01-01	\N	f		t
4117	Maria Edinalva de Oliveira Alves	eddynalvamarya@gmail.com	Edinalva	@		17f3894f7ff1859d0bad68642d8c07f5	f	\N	2012-11-30 16:58:24.13417	2	1989-01-01	\N	f		t
4121	Antonio Neuton da Silva Júnior	neutonjrep@gmail.com	Neuton Júnior	@neutonjr	https://plus.google.com/118072690377162713424	9c92c4f3866b9a0329f38f6eb6477cb6	f	\N	2012-11-30 18:03:32.657487	1	1993-01-01	\N	f		t
4320	Janaína Arruda	janaarruda16@hotmail.com	Janaarruda	@		0e66ce77c71c1da0c19b72975e50db0f	f	\N	2012-12-03 21:54:03.558554	2	1995-01-01	\N	f	janaarruda16@hotmail.com	t
4248	levy cavalcante	levycavalcante.ti@gmail.com	lorimm	@		ad9a05484e98e0b5c46f22efba9163a6	f	\N	2012-12-03 11:45:42.70349	1	1995-01-01	\N	f	levy_santista@hotmail.com	t
4173	Marcelo	marcelocavalcante17@yahoo.com	marcelo	@		e7dc840122af983c5964b17096b67adc	f	\N	2012-12-01 13:09:26.262685	1	1995-01-01	\N	f	mscavalcante17_@hotmail.com	t
4445	Antonio Emannuel Martins Silva	emannuelmsilva@gmail.com	Emannuel	@		9e7dadfe2666ab1b1df35b0f05d3849a	f	\N	2012-12-04 22:12:23.014397	1	1993-01-01	\N	f	einstein067@gmail.com	t
4254	Maria Thamirys Lima da Silva	thamirys_17@lima.com.br	thamirys	@		974fa331e9c20494de1548afec065835	f	\N	2012-12-03 11:49:18.390169	2	1995-01-01	\N	f	thamirys_17@lima.com.br	t
5143	Alysson Jones dos Santos Pereira	alysson.jones@hotmail.com	AllyJones	@		e98251ebb98ceff8d19976c48a339374	f	\N	2012-12-06 22:54:24.421692	1	1996-01-01	\N	f	alysson.jones@hotmail.com	t
4180	deogells colares de moura	deogells.colares@gmail.com	deogells	@		252dbbf4bb9970703de977ae1b340f38	f	\N	2012-12-01 15:45:45.739508	1	1987-01-01	\N	f	deogells@facebook.com	t
4712	Matheus da Costa Brandão	matheuscostact@hotmail.com	Matheusinho	@		70091e40c98ea1eeefa94a6e839b4b88	f	\N	2012-12-05 20:19:48.120063	1	1996-01-01	\N	f		t
4349	magna raaele guimarares patricio	magnarafaely@gmail.com	magnarafaele	@		a07f10cf323450b7e79e32a71ac9e6d3	f	\N	2012-12-04 11:08:08.987863	2	1987-01-01	\N	f		t
677	ANDRE TEIXEIRA DE QUEIROZ	andre.teixera@hotmail.com	não tenho	@		1ce655665177fec8eb8361ce492e88d3	t	2012-12-05 00:30:20.241631	2011-11-10 02:32:33.614841	1	1993-01-01	\N	f	andre.teixera@hotmail.com	t
4463	Bruno César	brunocesarperreira@hotmail.com	Bruninho	@		0d61e00a3bca633ed4bda5a1f850b41c	f	\N	2012-12-05 09:27:52.606326	1	1995-01-01	\N	f	brunocesarperreira@hotmail.com	t
5037	Kelly Freitas	kelly.freitas07@hotmail.com	kellynha	@		35dbf19109a8a4701899e73b652d8223	f	\N	2012-12-06 17:13:12.871515	2	1995-01-01	\N	f	kellynha_garota@hotmail.com	t
4738	Marcos	kadu391@gmail.com	Calixto	@calixtodudu	http://camaraonoticia.blogspot.com.br/	5fc93244c7d74fa92e35fa4c74aeb13a	f	\N	2012-12-05 21:44:17.006132	1	1996-01-01	\N	f		t
4755	Lucivan de Castro Barroso	lucivanbarroso@gmail.com	Takeshi	@		a47b1480db458c9ee4229d2f458b9f49	f	\N	2012-12-05 22:50:58.565055	1	1992-01-01	\N	f	lucivan_takeshi_118@hotmail.com	t
5370	Jéssyca Freitas Felix dos Santos	jessicaespanhol@hotmail.com	jessyca	@		6d51dcd463cec358bba3ed00722dd16c	f	\N	2012-12-08 09:51:17.819714	2	1996-01-01	\N	f	jessycafreitaslove@gmail.com	t
3989	Sterffany de Arruda Ribeiro	sterffany1@hotmail.com	Sterffany	@sterffany9		a05b675ae73ec5f755ef0d9cf16904af	f	\N	2012-11-29 19:50:51.132856	2	1995-01-01	\N	f	sterffany1@hotmail.com	t
3988	Mauricio Martins Pereira	taizuksama@live.com	Taizuk Shiro	@TaizukShiro		44ac066fb974bfeb3ef5ef2b829dd9ac	f	\N	2012-11-29 19:49:28.159699	1	1998-01-01	\N	f	taizuksama@live.com	t
3998	vladiane	vladiane01@hotmail.com	vladia	@		b61c162804cf7ab9496ecfadc508c855	f	\N	2012-11-29 20:15:30.227205	2	1995-01-01	\N	f		t
3992	Emanoel Alves Teixeira	emanoel_alves@rocketmail.com	Emanoel	@		eb7877e0b2fb140a508ee346b295a76c	f	\N	2012-11-29 19:59:39.810693	1	1997-01-01	\N	f	emanoel.alves.7758@facebook.com	t
4154	Raimundo Abner Escócio de Souza	abner.escocio@hotmail.com	Abner Escócio	@		8d28460d49cf7e0457b42fa0ffdec54e	f	\N	2012-11-30 23:10:35.059869	1	1994-01-01	\N	f	abner.escocio@facebook.com	t
3993	Francisca Mayara Pereira Moreira	MayaraMoreira1000@gmail.com	Mayara	@		703a94288adda67bdfc992f2bde292ce	f	\N	2012-11-29 19:59:55.720169	2	1997-01-01	\N	f	MayaraMoreira1000@gmail.com	t
4047	Henrique Souza 	henrique123souza123@gmail.com	francisco 	@		b10f14ae2b2dcf6cf9458bc511387148	f	\N	2012-11-30 09:07:22.319618	1	1995-01-01	\N	f	henrycta@hotmail.com	t
4110	NEYSSAN REBECA SANTIAGO DA SILVA	rebeecasantiago@hotmail.com	Rebeca	@		fe927e367a495e6f6d8f970032a9b939	f	\N	2012-11-30 15:34:12.378891	0	1997-01-01	\N	f	rebeecasantiago@hotmail.com	t
4058	Alexmar Matos Queiroz	jose.bzhha@yahoo.com.br	alexmar	@alexqueiroz		d9682dce3a4a8a15e42eae470debd310	f	\N	2012-11-30 10:19:50.286062	1	1995-01-01	\N	f	alexmm001@yahoo.com.br	t
4067	Deborah Sousa Silva	Deborasousa@gmail.com	Debbieh	@		f648dc0627f573ca0d0831f2429312b6	f	\N	2012-11-30 11:35:38.0831	2	1994-01-01	\N	f		t
4076	Matheus Matias	ma0the0us7@hotmail.com	theuss	@		5284af628dcce3f7b988ef0bdbfc3aa5	f	\N	2012-11-30 13:15:40.730766	1	1998-01-01	\N	f	ma0the0us7@hotmail.com	t
4081	Gutto Bevilaqua da Silva Braga	guttobevilaqua@gmail.com	Gutto Bevilaqua	@		3d3c1ee46c756f2fa46e995c0d3aeccb	f	\N	2012-11-30 13:25:56.644747	1	1987-01-01	\N	f		t
4160	Carlos Henrique	carloshenrique9511@gmail.com	Grandão	@		e573ea83d2ac5b869f0926b9cd02a038	f	\N	2012-12-01 00:15:16.418464	1	1992-01-01	\N	f	carlos-henrique9511@hotmail.com	t
4087	MARCELO	mccavalcante17@hotmail.com	marcelinhodyg	@		d25f84a67dd9e01f2579e2b9e7e0a0e6	f	\N	2012-11-30 13:37:31.689802	1	1998-01-01	\N	f		t
4210	Júnio João Martins	martins.junio@hotmail.com	Júnio Martins	@		2cbbcaccbf732348679974d76248bcc7	f	\N	2012-12-02 11:02:43.237329	1	1991-01-01	\N	f	junioamizade@hotmail.com	t
4236	anderson	andersoncrew111@hotmail.com	jay-lion	@		b14d7a8fa3aa7020b1ad009d03c0ff71	f	\N	2012-12-03 11:40:33.529513	1	1996-01-01	\N	f	anderson.look@hotmail.com	t
4098	Pedro Henrique Rufino Gadelha	pedro.rufino02@gmail.com	Pedro.H	@		d598d2ccb690b07784d1be49011d3380	f	\N	2012-11-30 13:51:24.837079	1	1995-01-01	\N	f	pedrox_0@hotmail.com	t
4219	Adriany Alves Silva	adryany_sylva@hotmail.com	Drykaa	@		62468007023ade257fd3c7a2f8cec6c7	f	\N	2012-12-02 15:33:28.042175	2	1988-01-01	\N	f		t
4102	Wanderson Barbosa da Silva	wandersonbaterista2009@hotmail.com	wanderson	@		b9768b896ce369399afe9f52ae214d79	f	\N	2012-11-30 14:32:55.249714	1	1994-01-01	\N	f		t
4174	Gabriela Mota Carapeto	gabrielacarapeto@hotmail.com	gabimotac	@		c31c62b4fac385d9d02a7e12d0c2c9b3	f	\N	2012-12-01 13:36:53.625314	2	1992-01-01	\N	f	gabrielacarapeto@hotmail.com	t
4140	Kerliane Cavalcante Pereira	kerlianec@gmail.com	Kerliane	@kerliane	http://pubtecnologia.wix.com/comunicacao20	92d3f442bb23b8443c0d0eee93985290	f	\N	2012-11-30 22:43:06.777881	2	1991-01-01	\N	f	kerlianecavalcante15@hotmail.com	t
3403	EMANUELLA GOMES RIBEIRO	emma.taylor.49@gmail.com	EMANUELLA 	\N	\N	37d21092fb1eb1a35667e866250f913d	f	\N	2012-01-10 18:26:01.114221	0	1980-01-01	\N	f	\N	f
4118	Francisca Vanda de Sousa Firmo 	vanda.ti@hotmail.com	Vanda Sousa	@		e34f5c1997c08e80ac50ea84479c67b2	f	\N	2012-11-30 16:59:20.24629	2	1987-01-01	\N	f	vanda_ti@hotmail.com	t
1318	GABRIEL DE SOUSA VENÂNCIO	gabriel.saxofone2009@gmail.com	Gabriel Venancio	@gabrielseliga		b872cbdd96ed6fea997f74ca384450c0	t	2012-11-30 18:13:42.313071	2011-11-22 10:59:09.444928	1	1922-01-01	\N	f	gabriel.saxofone2009@gmail.com	t
466	RAPHAEL SANTOS DA SILVA	rsdsfec@yahoo.com.br	SANTOS	@phaels		a70d499673b25d02228d7a283092e441	t	2012-11-30 19:11:43.245788	2011-11-02 13:50:03.991611	1	1986-01-01	\N	f	rsdsfec@yahoo.com.br	t
4124	gerfson	gerfsonlima2011@hotmail.com	cabeção	@		05302275269143b8d9c0bc3b11db38f1	f	\N	2012-11-30 19:23:46.019366	1	1996-01-01	\N	f	gerfsonlima2011@hotmail.com	t
4126	Virlanda Martins	Virlanda.martins@hotmail.com	Landinha	@		47aed986fa4affcd77a74582dd4c1753	f	\N	2012-11-30 19:32:22.044442	2	1997-01-01	\N	f		t
4181	Luiz Fernando Gomes da Silva	luizfernandogsilva@gmail.com	Luiz_Fernando	@Luiz_Fernando_S		338195e32cc7e1d7650a80c5ac3835cd	f	\N	2012-12-01 15:47:07.596352	1	1988-01-01	\N	f	luizfernandogsilva@gmail.com	t
4321	Matheus Almeida Carvalho	mathheus_almeida@hotmail.com	Almeida	@		c72032ef8ff0615f14dc85a641dd87b6	f	\N	2012-12-03 21:55:25.923258	1	1997-01-01	\N	f	mathheus_almeida@hotmail.com	t
3881	germano machado	germanomachado1989@hotmail.com	geholiveira	@		566ca5d3a9b79c8ed11fef4550515593	f	\N	2012-11-28 23:31:30.811619	1	1989-01-01	\N	f		t
4255	alisson romario	alissonromarioaraujoferreira@gmail.com	alisson	@		e74649468d43f90eea351ba0f1c04747	f	\N	2012-12-03 11:50:35.906233	0	1993-01-01	\N	f	alissonromarioaraujoferreira@gmail.com	t
4249	WESLEY MENESES DA SILVA	wesleeym.s@gmail.com	LEOZINHO	@		1084968d180e40654d25683386eb5975	f	\N	2012-12-03 11:46:04.125094	1	1995-01-01	\N	f		t
4446	Francisco Valdemir Alves Barbosa Filho	valdemir2511@gmail.com	Filhor	@		ebc73b3ba486181480e75afd9af65f32	f	\N	2012-12-04 22:12:49.588226	1	1993-01-01	\N	f		t
4266	Laislan Oliveira	laislan.olv@gmail.com	Laislan	@laislanolv	http://www.laislanoliveira.com.br	8501b8ee39de23fd28d43348dfefbdbb	f	\N	2012-12-03 12:57:22.596614	1	1991-01-01	\N	f	laislan.olv@gmail.com	t
5038	Diego Camilo	diegocuruma@myopera.com	diegOCuruma	@		0e65700b5a337f6ed2b6c4b5dd322b68	f	\N	2012-12-06 17:24:41.346178	1	1990-01-01	\N	f		t
4350	douglas morais de freitas	douglasmoraisfreitas@gmail.com	dogunha	@		650e6c3049d22270054f44cf11a94f7e	f	\N	2012-12-04 11:10:55.639445	1	1995-01-01	\N	f		t
4713	rafael oliveira	tateteamoteadoro@gmail.com	leaphar	@		64df41fd717097f5ce394edde71c89bb	f	\N	2012-12-05 20:21:52.917851	1	1995-01-01	\N	f	leapharrafa@gmail.com	t
4464	José Augusto	Augustothedragon@hotmail.com	Augustozão	@		5679b6e7236904058f82861c0ca3634d	f	\N	2012-12-05 09:27:54.269118	1	1996-01-01	\N	f		t
4472	pamela oliveira	pamelas2paloma@gmail.com	pamela	@		97eba361f8a783f7ae57c2d4fa6378b2	f	\N	2012-12-05 09:38:10.598018	2	1996-01-01	\N	f	pamelas2paloma@gmail.com	t
4739	kennedy anderson 	ragnarok__55@hotmail.com	bokinha	@		2c4b22be7c6248756e106a3a2e276d8d	f	\N	2012-12-05 21:47:16.688847	1	1994-01-01	\N	f	ragnarok__55@hotmail.com	t
5142	Leandro	leandro.aso123@gmail.com	leandro	@		db6eb7749242abe54dd9d744bf8cf58a	f	\N	2012-12-06 22:50:12.278172	1	1992-01-01	\N	f	hatakeleandro@hotmail.com	t
4127	Ronnis Pereira	ronnyspseliga@gmail.com	Ronnys	@		a087a33ff9851050f3fa31a157b7d1d2	f	\N	2012-11-30 20:06:34.237816	1	1990-01-01	\N	f	ronnyspseliga@gmail.com	t
4196	Jailson Cruz	fdjailson100@yahoo.com.br	Jhay Shinoda	@		2934c15db7ddc80757434e96fd89402f	f	\N	2012-12-01 20:11:12.984962	1	1996-01-01	\N	f	fdjailson100@yahoo.com.br	t
4155	Simão Pedro	simaopedro95@gmail.com	Simão Pedro	@		28b499112478e0f6da22918bbb1de27d	f	\N	2012-11-30 23:16:53.09392	1	1995-01-01	\N	f		t
4161	Rogers Guedes Feitosa Teixeira	rogerguedes.ft@gmail.com	Rogers	@		d9305c2deeaff81dc25111123327e6d6	f	\N	2012-12-01 00:27:54.434694	1	1990-01-01	\N	f		t
4022	Antonio Victor Abreu Martins	antoniovictor585siupe@gmail.com	antonio victor	@		a61ba6af77f3446319cdac8297bbea83	f	\N	2012-11-29 21:43:51.869835	1	1997-01-01	\N	f	antoniovictor585@gmail.com	t
4237	Nagila	NagiilaSiilvaA@gmail.com	nanázinha	@		b9436685a3dbaf15a1c8e2717ba07d92	f	\N	2012-12-03 11:40:40.44645	2	1995-01-01	\N	f	nagilaSiilva_01@yahoo.com.br	t
4220	Carlos Elmen Andrade	carloselmen@gmail.com	Carlos Elmen	@		b4bdd0b2a38cfc7232799d15d03fbbc1	f	\N	2012-12-02 16:06:25.128891	1	2010-01-01	\N	f		t
4175	Bruno França Lima	brunof_10@hotmail.com	brunof	@		e7dcac8674dd86d962bca112eab25e24	f	\N	2012-12-01 13:44:34.254649	1	1993-01-01	\N	f		t
4250	Ana Letícia Lima dos Santos	analeticiasantos68@gmail.com	leticia	@		5f5a7c1ffa71c43d9e5779697077ccb0	f	\N	2012-12-03 11:46:08.131118	2	1994-01-01	\N	f		t
4447	paulo alberto	pauloalberto555@gmail.com	ulquiorra	@		d46234e0ffafd8d27e8acb646fb10c54	f	\N	2012-12-04 22:13:53.841875	1	1994-01-01	\N	f		t
4189	Jefferson L Gurguri	jeffersongurguri@gmail.com	Jefferson	@		a8995cc8be91858e5bfb974d5d028466	f	\N	2012-12-01 19:37:08.957219	1	1991-01-01	\N	f		t
4256	Wanessa Caitano Freitas	wanessabiar@gmail.com	wanessa	@		745b4f1269c3b2ea7192ff320cb611ad	f	\N	2012-12-03 11:51:39.808896	2	1983-01-01	\N	f		t
3959	larissa keylla dos santos braga	larissaprincess87@hotmail.com	princesa	@		d0012d5d38ebcacafa21578b9edfce7b	f	\N	2012-11-29 18:36:09.130623	2	1997-01-01	\N	f	larissaprincess87@hotmail.com	t
4193	Jonathan Vanderpol	itachidante@gmail.com	-Arkano-	@	https://www.facebook.com/JonhVanderpol	91add68e2f5408a710b67a3e0166adaf	f	\N	2012-12-01 19:40:54.479795	1	1990-01-01	\N	f	JonhVanderpol@facebook.com	t
4322	José Ricardo de Oliveira Alves	alvesricardo274@gmail.com	richard	@		3aebac0738760b80b75708cccc0d2f70	f	\N	2012-12-03 21:56:41.675722	1	1994-01-01	\N	f	alves_rick@elite.com.br	t
4194	keylla larissa braga	lunara_braga@hotmail.com	princesa	@		4a1b1d7f42614785ffa222f3dd30106f	f	\N	2012-12-01 19:45:30.06103	2	1997-01-01	\N	f	larissaprincess87@hotmail.com	t
4195	Keylla   Dos Santos Braga	aczaprinss2010@hotmail.com	princesa	@		4ade0a19846d18a090f43b17cdb07906	f	\N	2012-12-01 19:58:30.219703	2	1997-01-01	\N	f	acza_sanora@hotmail.com	t
4267	JOSE ANDERSON RODRIGUES ALBUQUERQUE	anderson.pindorama@gmail.com	Alokka	@		6045b1829568b401153cb8d1c09cb71c	f	\N	2012-12-03 13:22:22.274768	1	1987-01-01	\N	f		t
1133	FLAVIANA DA SILVA NOGUEIRA LUCAS	flavia.nogueyra@gmail.com	Flavia	@		e1c40f80bca23163442f3731e73d759d	f	\N	2011-11-21 15:13:15.272083	2	1984-01-01	\N	f		t
4999	johny leandro	johnyleandro19@gmail.com	johny leandro	@eskacela		dd7dfaffa6a31a0ee0e3e5c805f6342d	f	\N	2012-12-06 16:11:12.181346	1	1996-01-01	\N	f	johnyleandro1@hotmail.com	t
632	JULIANA LIMA GARÇA	julianagarca@gmail.com	Juh Yuki	@JuhYuki		0521d07701d0dc67c3385d9bcefb3385	t	2012-12-03 14:42:15.687592	2011-11-08 19:33:05.281306	2	1990-01-01	\N	f	juliana_yuki@hotmail.com	t
4275	Joyce Saraiva Lima	joycesaraivalima@gmail.com	Joycee	@		49bfbd24dea8a19670088274ad9ce3c9	f	\N	2012-12-03 14:52:21.756828	2	1989-01-01	\N	f	joyceqmc@yahoo.com.br	t
4714	Marilia Brenda	mariliabrenda22@gmail.com	Marilia	@		1056ec0f48580c74e04678121fb44324	f	\N	2012-12-05 20:22:28.561973	2	1996-01-01	\N	f		t
4276	darliane barroso luz	darlianegata2009@hotmail.com	cortas largas,0	@		c14fd2b5a26a7a5f5b66497ecbc33533	f	\N	2012-12-03 14:54:28.492803	0	2011-01-01	\N	f		t
4277	Renato Moura Paz	renatotimaomoura@hotmail.com	Renato_Paz	@		83cd03908f60e17272aa9d0376515834	f	\N	2012-12-03 15:00:55.390775	1	1994-01-01	\N	f		t
4278	Lorena Maria da Silva	loresi2010@gmail.com	Lorena Maria	@lorenamaria_		9e64641d951ae1624c632621cbaa2655	f	\N	2012-12-03 15:02:28.478286	2	1990-01-01	\N	f	loreninha_25@hotmail.com	t
4351	felicio cavalcante feitosa	feliciospfc@gmail.com	xplode	@		7f5957dcc0dd54df3d2b28740e290604	f	\N	2012-12-04 11:12:19.651326	1	1995-01-01	\N	f	feliciospfc@gmail.com	t
4280	Rafael Silva Domingos	raffael_sd@hotmail.com	Rafael	@		e590854851bc15451c85e8240f6d1ded	f	\N	2012-12-03 15:51:49.429624	1	1985-01-01	\N	f		t
4473	maria thamyrys	thamyrysaaraujo@hotmail.com	thamyrys	@		01b83c83fe820cc1e69a6718fa82f644	f	\N	2012-12-05 09:38:46.782986	2	1996-01-01	\N	f	thamyrysaaraujo@hotmail.com	t
4363	sandeson neves	sandeson.neviz@gmail.com	sandeson	@		67fc2ae9f21d97b2e0e662b54b585f11	f	\N	2012-12-04 11:25:58.121046	1	1997-01-01	\N	f		t
4367	Yara Thaysa da Costa Cunha	yara.thaysa@hotmail.com	Yara T	@		11a72723f9755d6abdeff542590f4983	f	\N	2012-12-04 11:58:12.839404	2	1996-01-01	\N	f	yara.thaysa@hotmail.com	t
4740	LUCAS TEODOZIO SILVA	teodozio556@gmail.com	TEODOZIO	@		d8e34731657f47e36d9944959094e421	f	\N	2012-12-05 21:57:55.095411	1	1995-01-01	\N	f	teodozio556@gmail.com	t
4373	Hiago Batista de Melo	Hiago099@hotmail.com.br	Laranja	@		5281a45d0b0c5c1e924269878655eb0a	f	\N	2012-12-04 12:20:33.882743	1	1995-01-01	\N	f	Hiago099@hotmail.com.br	t
4486	Alynne Ferreira Sousa	alynne-ferreira@hotmail.com	Alynne	@Nynnah7T		f81a27152b9afa46875a7a298d79b37c	f	\N	2012-12-05 10:22:22.746066	2	1997-01-01	\N	f		t
4480	Neryvaldo Souza de  Alicim	neryvaldo.ejv@gmail.com	Nery_ Souza	@nery_alicim		0117b062fbd3f31e305cae1ef00235b7	f	\N	2012-12-05 10:18:13.512038	1	1990-01-01	\N	f	nery.valdo@hotmail.com	t
1810	Lucas Holanda Feitosa	luks206@gmail.com	Lucas Holanda	@		0a5a2fe34f68e8dd4f173689677f1b3b	f	\N	2011-11-23 10:31:15.427392	1	1996-01-01	\N	f		t
5371	Francisco Anderson Gomes da Sliva	AndersonGomesilva@gmail.com	Andinho	@		770ef9c0695771a1f6cb8af44ebc0e3e	f	\N	2012-12-08 09:51:51.169643	0	2011-01-01	\N	f		t
5039	Jonas Sousa	jonascomdominio@gmail.com	JonasSousa	@		6aea12e3ed1b816eb480c4128a4701c7	f	\N	2012-12-06 17:26:12.214706	1	1985-01-01	\N	f		t
4774	Henrick Cunha	henrick_ccunha@hotmail.com	rickconstantino	@		8f236742e7b8b8cfd24210978b1d22b6	f	\N	2012-12-06 01:23:49.32603	1	1993-01-01	\N	f		t
5069	Edilene Ferreira de Sena	edilenesena7@gmail.com	Eudilaine	@		c81b3d71f286916e692c704b71e235d9	f	\N	2012-12-06 19:49:21.840799	2	1996-01-01	\N	f	edilenesena7@gmail.com	t
5144	Jean Felipe Oliveira Sousa	jeanfelipe19962010@hotmail.com	jean felipe	@		25f9e794323b453885f5181f1b624d0b	f	\N	2012-12-06 23:20:35.47291	1	2010-01-01	\N	f	jeanfelipe.o.sousa@facebook.com	t
5401	Marcilio Maciel Gomes	marcilioceara@hotmail.com	Marcilio	@		1e7d1b831a483cdaa28cfc6a53771924	f	\N	2012-12-08 10:29:29.334486	1	1995-01-01	\N	f		t
4282	Francisco Isnair	isnair.infor@gmail.com	Naizinho	@		be1bec1fc389c16047622e5c95bd6a66	f	\N	2012-12-03 16:07:08.452611	1	1996-01-01	\N	f	isnairdaschagas@hotmail.com	t
4135	EDMO JEOVA SILVA DE LIMA	edmojeova@gmail.com	EDMO JEOVA	@edmo_jeova		b5dde6fe53ec410f2da1a92ae46cd955	f	\N	2012-11-30 22:14:51.863238	1	1991-01-01	\N	f	edmojeova@gmail.com	t
4395	Darlinson Alves	darlisonalves@hapvida.com	GansoX	@		93a89c8827d1c3078992e267371a7811	f	\N	2012-12-04 14:41:28.120055	1	2011-01-01	\N	f	Darlison.7@hotmail.com	t
4345	Lucas da Silva Costa	lsilvaacostaa@hotmail.com	lsilvaacostaa	@lsilvaacostaa		74b5e7faed52165342ef5d9fa8be1682	f	\N	2012-12-04 10:36:26.978657	1	1996-01-01	\N	f	lsilvaacostaa@hotmail.com	t
4448	Edivânia	edivaniagarcia9@gmail.com	Estrela	@		438cb6549924e9bb38d120eb092e548d	f	\N	2012-12-04 22:14:17.813176	2	1994-01-01	\N	f	edvannia-garcia@hotmail.com	t
1191	BRUNO BARBOSA AMARAL	bruno_k16@yahoo.com.br	Brunn0	@		9abe58c54ce3bb15dd7bf4c06ec0f5cb	t	2012-12-05 21:59:24.621387	2011-11-21 23:04:28.043243	1	1990-01-01	\N	f		t
4281	Ilannah Taggyn Leal Rabêlo	ilannahrabelo@yahoo.com.br	ilannah	@		354b4ea2a961d1716e3e44a99ad6940c	f	\N	2012-12-03 16:06:58.897606	2	1991-01-01	\N	f	ilannahrabelo@yahoo.com.br	t
4293	Ánderson de Lima Félix	anderson-lf1@hotmail.com	andinho	@		e9f2b9d6f625d576ecb74e286e61116c	f	\N	2012-12-03 16:12:43.849534	1	1996-01-01	\N	f		t
4364	helton	helton-break@hotmail.com	dyon dyon	@		8a13b41555e9365d14b4f83963a01639	f	\N	2012-12-04 11:33:35.015875	1	1997-01-01	\N	f	helton-break@hotmail.com	t
4352	Ivanaldo	jr-xd@hotmail.com	Naldo 	@		ca8bcedfeb69e318aefa019528fe5aab	f	\N	2012-12-04 11:13:12.191257	1	1994-01-01	\N	f	jr-xd@hotmail.com	t
4294	Elionazio Filho	elionazio@gmail.com	elionazio 	@		c42c43f0d98506f955d80e46c3d5c514	f	\N	2012-12-03 16:14:57.339283	1	1989-01-01	\N	f	elionazio@gmail.com	t
3921	Morgana Oliveira Silva	morgana_taiba@hotmail.com	morgana	@		53dee760aafd8d1773c1eafc5997bb7f	f	\N	2012-11-29 13:13:30.6168	2	1997-01-01	\N	f	morgana_taiba@hotmail.com	t
4466	Bruno da Silva Amancio	brunoamancio62@hotmail.com	Amancio	@		3deaa01667c8205f80f6cd5309a8f8ca	f	\N	2012-12-05 09:30:08.776858	1	1995-01-01	\N	f	brunoamancio62@hotmail.com	t
4374	Francisco Neudimar Ferreira Junior	juniis@live.jp	Junior	@juniorsaeki		f9d105a2f56031e711647e4ac0c89487	f	\N	2012-12-04 12:28:01.897312	1	1992-01-01	\N	f	juniis@live.jp	t
4474	Karla Dellany	dhellanynha@hotmail.com	Karla Dellany	@		9d0556ad869c4cea520163d0e23ab869	f	\N	2012-12-05 09:39:11.957027	2	1995-01-01	\N	f	karla_dellany@yahoo.com	t
4741	Francisco Lucas de Sousa	lucas.peopleware@gmail.com	Peopleware	@		58534b40840883ec5c2a9b95cc2e4f79	f	\N	2012-12-05 21:59:45.030317	1	1991-01-01	\N	f	lucas.peopleware@gmail.com	t
4481	Leandro Jackson Pinheiro do Nascimento	leandrojackson_1a@yahoo.com	leandro	@		88448ad0927eb9e7db565f64181ff2b6	f	\N	2012-12-05 10:18:23.71334	1	1996-01-01	\N	f	leandro-resident1@hotmail.com	t
328	KLEBER DE MELO MESQUITA	kleber099@gmail.com	kleber	@		b1542e8fb84304f231314d7a4f40f957	t	2012-12-08 09:21:20.810003	2011-10-15 10:10:09.949636	1	1986-01-01	\N	t	kleber099@gmail.com	t
5000	camila	camila.p.silva118@gmail.com	Camila Silva	@		5b1879762b30dc0b99c3d7b252c137db	f	\N	2012-12-06 16:13:17.02317	2	1995-01-01	\N	f	camila_p_silva@live.com	t
4302	Paulo Sampaio	jhagas@gmail.com	Paulinho	@paulinhomininu		ca7b679360f96b89891fb4338e0c5a51	f	\N	2012-12-03 17:24:34.651677	1	1986-01-01	\N	f	jhagas@gmail.com	t
4199	Antonio Aldo de Sousa Silva	aldosousa600@gmail.com	Aldo Sousa	@		2b89dd307c08bb9a70b26b834879059d	f	\N	2012-12-01 22:39:45.378028	1	1996-01-01	\N	f	aldoeaglered@hotmail.com	t
4487	Alesy Terceiro Feitosa	alesy64@hotmail.com	alesy3	@		5ee6253f0fdcb3871808187a10c66c57	f	\N	2012-12-05 10:23:12.847099	1	1996-01-01	\N	f	alesy64@hotmail.com	t
4390	Gabriela Lourenco	gabywednesday@hotmail.com	gabywednesday	@		92f20dafc5e5ac1c66820903c492cc04	f	\N	2012-12-04 14:09:08.079339	2	1996-01-01	\N	f		t
4401	Hannah Amara Agostinho de Oliveira	nina_amara@hotmail.com	Haninha	@		7041abfb86eea8c54259471c5914f1ef	f	\N	2012-12-04 15:27:29.387425	2	1996-01-01	\N	f		t
3374	BRENDO DE SOUSA ALVES	brendo2008@gmail.com	BRENDO DE 	\N	\N	7bc672801a8a301a19b3a6d70ca7556a	f	\N	2012-01-10 18:25:51.453355	0	1980-01-01	\N	f	\N	f
1026	ROSANABERG PAIXAO DE LIMA	rosanabergpaixao@hotmail.com	Rosana	@		394fe445461e2cfa3ac4892399d987dc	t	2012-12-04 16:37:56.218072	2011-11-18 19:53:42.749773	2	1991-01-01	\N	f	rosanabergpaixao@hotmail.com	t
4492	Erika Carvalho de Sousa	erika1a@yahoo.com	mekita	@erikaGleek		29ec37a3fbb5dd5b0f5d9edcb576d66e	f	\N	2012-12-05 10:26:40.543482	2	1994-01-01	\N	f	mekita24@hotmail.com	t
4404	Priscila Rodrigues da Costa	priscila_rc@live.com	Pryh =)	@		846cbd53779aa3c84b76a33ffdb40c7f	f	\N	2012-12-04 17:07:54.562617	2	1991-01-01	\N	f		t
5119	Marcio	marciogaara@hotmail.com	marcio	@		01f8603ed402cd37540b5b9fd34bbb1a	f	\N	2012-12-06 20:43:22.264716	1	1994-01-01	\N	f	sabaconogaara@hotmail.com	t
4407	Gabriele Vanessa do Vale Silva	gabrielevs1838@yahoo.com.br	Gabriele	@		729a5dd7688d7a1f7f96ad3ee17e059a	f	\N	2012-12-04 17:19:22.386689	2	1993-01-01	\N	f		t
4497	Anderson Lima Menezes	andersonlimajava5@yahoo.com.br	uchiha	@		636ade2349f21289b59cfb96a9fec865	f	\N	2012-12-05 10:31:13.981687	1	1997-01-01	\N	f	sharingananderson_@hotmail.com	t
4413	Millena Ximenes De Lima	millena_gr@hotmail.com	Milleninha	@millena_ximenes		8bb68de2a242fe45497d3725231fdb61	f	\N	2012-12-04 17:20:33.144859	2	1991-01-01	\N	f		t
5040	Mônica Kelly Gonçalves Nascimento	monicakelly@gmail.com	Mônica	@		f99ab3561eeb7e111eee4e6ce115292c	f	\N	2012-12-06 17:27:02.512504	2	1997-01-01	\N	f		t
4790	Edna Araújo	rukia.mow@gmail.com	ApaixonadaPorBleach	@		0acdb7996659e533d286f3a9b4ebc80c	f	\N	2012-12-06 08:32:05.924981	2	1997-01-01	\N	f		t
4806	jerons	jeronschwantz@gmail.com	derin5	@		9a132853f99f94ef957eb6f4014425b4	f	\N	2012-12-06 08:48:44.986324	1	1995-01-01	\N	f	jronschwantz@gmail.com	t
3950	wilter teofilo coelho	wilterk6@hotmail.com	wilter	@		fd26ffa5ca779e89c10bb0f2e9f8e522	f	\N	2012-11-29 15:39:38.114147	1	1994-01-01	\N	f	wilterk6@hotmail.com	t
5171	Francisco de Assis da Silva Júnior	juniorlpct@hotmail.com	Junior Silva	@		e18740b8c4cab5769def4c273884a667	f	\N	2012-12-07 08:58:29.658891	1	1989-01-01	\N	f	juniorlpct@hotmail.com	t
5195	Antonia Joicy de Oliveira Lima	joicylima12@yahoo.com	Joicy Lima	@		132593a398f71ff982ce382e07437ccf	f	\N	2012-12-07 10:32:04.183841	2	1995-01-01	\N	f		t
5372	Maria Luiza Prudêncio da Silva Neto	luiza_gleicir@hotmail.com	Maria Luiza	@		c375ad4e74287c9589272ece247fb41a	f	\N	2012-12-08 09:52:09.889399	2	1996-01-01	\N	f		t
4303	Pedro Feitoza	feitoza.pedro@gmail.com	PedroH	@pedrohfs_	http://informaxter.wordpress.com/	1ce655665177fec8eb8361ce492e88d3	f	\N	2012-12-03 18:00:56.989472	1	1988-01-01	\N	f		t
4304	Kelvia	Hime17@hotmail.com	Ketynha	@mc_ketty		7b727d8b16b1eca3b78148ec7609f495	f	\N	2012-12-03 18:23:24.174803	2	1994-01-01	\N	f	alokadaesttela@hotmail.com	t
4402	Eurico Saraiva	zurasaraiva@yahoo.com.br	Zurico	@		fe392e95d6d34530cc37a9057b4911f8	f	\N	2012-12-04 16:07:24.636488	1	2002-01-01	\N	f	zurasaraiva@yahoo.com.br	t
4323	José Everson Leitão Lima	eversonlima7@gmail.com	everson	@		a1737033e65d58475d1036ceceeec0c0	f	\N	2012-12-03 22:03:53.909982	1	1996-01-01	\N	f	everson_elpirata@hotmail.com	t
4449	wesley	wesley.ceara4@hotmail.com	gigante	@		c998d6e8d6b621cb681ee8f7acfa0944	f	\N	2012-12-04 22:17:56.269968	0	1994-01-01	\N	f	wesley.ceara4@hotmail.com	t
4346	wellyngton braz	wellyngtonbb@hotmail.com	wellyngtonbb	@wellyngtonbb	https://www.facebook.com/wellyngtonbb.wbb	db481c8d23c70d0155c1787ef44e5e05	f	\N	2012-12-04 10:43:21.251592	1	1994-01-01	\N	f	wellyngtonbb@hotmail.com	t
4405	Paulo Ricardo Ribeiro Rodrigues	pauloribeiro1989@gmail.com	Riccardinho	@		d59649ce4b8f797277f39d607bc441b5	f	\N	2012-12-04 17:13:31.656349	1	1989-01-01	\N	f	paullo_slevin@hotmail.com	t
4353	Cleiton Dodó da Silva	cdsaventura@hotmail.com	cleiton aventura	@		d91c79c9e3d732cb550e231c18e02888	f	\N	2012-12-04 11:19:26.58211	1	1983-01-01	\N	f	cdsaventura@hotmail.com	t
4459	Lucas Mapurunga	lucasmapurunga@gmail.com	Mapurunga	@		3bef8d10fca58cb01ecda000a613c406	f	\N	2012-12-05 00:50:17.837186	1	1993-01-01	\N	f		t
4365	Mirlânia Fernandes Costa	mirlanyfc@gmail.com	Mirlânia	@		4685e814c4bc513b292d5325cb5536d3	f	\N	2012-12-04 11:45:41.895687	2	1992-01-01	\N	f		t
4368	Jeová de Lima Rodirgues	jeovadelimar@htomail.com	Geovas	@		989552f139232b31e2be051ce1055d86	f	\N	2012-12-04 12:16:22.618351	1	1994-01-01	\N	f	jeovadelimar@hotmail.com	t
3841	Larissa 	larissa.oli2@hotmail.com	Larinha	@		7515ed92d41676bf9c39505c000bab71	f	\N	2012-11-28 18:16:58.752576	2	1998-01-01	\N	f		t
4375	Maria Silvana Costa Silva	silvanalifelove@hotmail.com	Silvana	@		5f12923228276eec4095d60bdb44de96	f	\N	2012-12-04 12:39:51.054764	2	1995-01-01	\N	f	silvanalifelove@hotmail.com	t
4467	maria claudia	claudia.sayure@hotmail.com	claudia	@		82f6dfcea7157ffc633a6e24a9887bdc	f	\N	2012-12-05 09:32:45.037237	2	1994-01-01	\N	f	claudia.sayure@hotmail.com	t
4382	FLAVIO DIAS	FLAVIODIASD@GMAIL.COM	FLAVIO DIAS D	@		38484a971e96ba7065661c2f5912e8e7	f	\N	2012-12-04 13:05:54.750447	0	1990-01-01	\N	f		t
4715	marvlyn da silva	marvlyndasilva@hotmail.com	marvlyn	@		2bfabdfe3b4167fb85809a356ee14fa4	f	\N	2012-12-05 20:31:08.378601	1	1995-01-01	\N	f	ma_rv_lyn100leoesdatuf@hotmail.com	t
3387	DARIO ABNOR SOARES DOS ANJOS	darioabnor@gmail.com	DARIO ABNO	\N	\N	c118f4e1000e2eae99cfd2c9aaf196fa	f	\N	2012-01-10 18:25:57.435458	0	1980-01-01	\N	f	\N	f
4475	Jenifer Fontinele 	jenifergata1924@hotmail.com	Jenifer Fontinele	@		67b3b360f1f9c850b348a21b6737a6de	f	\N	2012-12-05 09:40:44.972809	2	1997-01-01	\N	f	jeniferfontinele@hotmail.com	t
4393	Julio Cesar	julio.souzam@gmail.com	JulioTk	@juliotk	https://www.facebook.com/DivineShiro	b364bb294cc49bd5596226cf6665a533	f	\N	2012-12-04 14:21:42.435802	1	1997-01-01	\N	f	julio.souzam@gmail.com	t
4482	FRANCISCA GERMANA AQUINO FERREIRA	germanaaquino@ymail.com	GERMANA	@		c6d7f0b24bf99d5d9be592c2423f52bd	f	\N	2012-12-05 10:18:24.530427	2	1997-01-01	\N	f	germanaaquino2011@hotmail.com	t
4396	Darlinson Alves	darlisonalves@hapvida.com.br	GansoX	@		702a5cc82be699ea5413abe470336086	f	\N	2012-12-04 14:44:50.546839	1	2011-01-01	\N	f	Darlison.7@hotmail.com	t
5001	Ana Célia Fernandes Sousa	anacelia.empregoestagio@gmail.com	Teteiaa.Sousaa	@		a77d048d9315d4172e8fdeae2147503a	f	\N	2012-12-06 16:14:01.411087	2	1996-01-01	\N	f	metidah.aninha@gmail.com	t
4488	Isabele Maria Amaral Faustino	isabelly.bebel12@hotmail.com	Bebeli	@		698cdd617dd9f9ea95f9d9df5d8f50a0	f	\N	2012-12-05 10:23:39.021055	2	1997-01-01	\N	f	isabelly.bebel12@hotmail.com	t
4414	José Anderson de Freitas Silva	linuxberoot@gmail.com	Pança	@anfim		a8ad6d1b95d12d8ec43c267be25d3f58	f	\N	2012-12-04 17:21:32.466022	1	1987-01-01	\N	f	jose-anderson1987@hotmail.com	t
4416	Dálete salem oliveira lopes	dalete_01@hotmail.com	Dalete	@		39395c8bdb02b866e69ed9abc47d79bc	f	\N	2012-12-04 17:21:59.911272	2	1994-01-01	\N	f	dalete_01@hotmail.com	t
4493	Antonia Maria	antoniamary123@hotmail.com	Tenho não	@		17345e8264600ed775e2f12c68c36393	f	\N	2012-12-05 10:27:44.778152	2	1996-01-01	\N	f	tonnyamary@hotmail.com	t
4742	Kedna Maria Marques de Oliveira	kedna.marques@gmail.com	kédna	@		af0b92d2f1d2470a576cd084abf33d1f	f	\N	2012-12-05 22:09:54.937981	2	1993-01-01	\N	f	keeh.oliveiiira@gmail.com	t
4498	Luiz Felipe Araújo Vieira	felipearaujovieira@hotmail.com	Felipe	@		4f598e8b2cbb8bcad8e9cfd0deaa8426	f	\N	2012-12-05 10:31:20.318771	1	1997-01-01	\N	f	felipe_luis75@hotmail.com	t
4501	Tatiane Mendes	tatianemendes123@hotmail.com	Tenho não	@		fca7f6bb553bc246dbfcd80b6a54d355	f	\N	2012-12-05 10:33:32.044215	2	1995-01-01	\N	f	tatianemendes123@hotmail.com	t
5041	Sarah Humbert Silva de Sousa	sarah_humbert@hotmail.com	Sarah Humbert	@		98aa3aa377586b1d41185426acb47ea2	f	\N	2012-12-06 17:28:39.456109	2	1997-01-01	\N	f		t
2344	Jheymison de Lima Silva	jheyjhey20@hotmail.com	jheyjhey	@		03367ee62bd800caa6cfc22b6a591b83	f	\N	2011-11-24 11:21:51.316874	1	2011-01-01	\N	f		t
5120	FRANCISCO GERBESSON NOGUEIRA DE LIMA	Gerbesson_Gn@Hotmail.com	GnLima	@		96b096cc21c6880fdc7f9ada323b3a1b	f	\N	2012-12-06 20:47:53.694276	1	1990-01-01	\N	f	Gerbesson_Gn@Hotmail.com	t
4823	Maria Letycia Martins Peixoto	letyciay2@hotmail.com	Letycia	@		24490c449a3a063ce7c8a73f704dc4b6	f	\N	2012-12-06 09:31:28.150226	2	1997-01-01	\N	f		t
5070	Diego Soares	diego8859@hotmail.com	Diego Bob	@		cdbc6981e3a55b44b7348b5a0e682852	f	\N	2012-12-06 19:49:44.868482	1	1988-01-01	\N	f	diego8859@hotmail.com	t
5146	Francisco Filipe Costa Cruz	liphimarka@hotmail.com	Filipe Cruz	@		1d963eea479de90ede6cc10bc8a4d89e	f	\N	2012-12-06 23:55:55.656476	1	1994-01-01	\N	f	liphimarka@hotmail.com	t
5373	MARIA IANCA DA SILVA PAIVA	yanka.hta@hotmail.com	MARIA IANCA	@		9c480f18614dc805f07d78275a25ace3	f	\N	2012-12-08 09:52:54.975068	2	1996-01-01	\N	f		t
5402	José Leandro Silva dos Santos	joseleandrosilvadossantos455@gmail.com	Aio dos Santos	@		ddd77ede867ef41656c7651d4324b7ae	f	\N	2012-12-08 10:29:44.000008	0	2011-01-01	\N	f		t
5196	Gigdal Eder Carneiro Cabral	gigdal@gmail.com	GigdalElder	@		df7b7738e672309127e4fcd9bc1f890f	f	\N	2012-12-07 10:33:53.535278	1	1989-01-01	\N	f		t
5426	Allex Pontes Carneiro	allex.carneiro@hotmail.com	Barbosa	@Xx_Allex_xX		2360908b6108147c416c21ba88779f54	f	\N	2012-12-08 12:54:26.614683	1	1996-01-01	\N	f	allex.carneiro@hotmail.com	t
4305	josafa	josafarock@hotmail.com	josafa	@		33f0bb5b7540f6d70678b26255994c56	f	\N	2012-12-03 18:33:40.678228	1	2011-01-01	\N	f		t
4310	Antônio Mendonça Lima	toin_1996@hotmail.com	Dragonforce	@		a8fe81a4c08503c738bf255b6b08ec3f	f	\N	2012-12-03 19:36:55.27515	1	1996-01-01	\N	f		t
4306	Vitória Cavalcante Braga	vitoriacb000@gmail.com	Vitória	@		0a17c1aecfe7f7ff8843d49474bd062c	f	\N	2012-12-03 18:36:38.638265	2	1997-01-01	\N	f		t
4307	sandy ferreira da costa	sandynhafcosta@hotmail.com	sandynha	@		1ce7bb1ba27f1309129e6eefd2b3c555	f	\N	2012-12-03 18:45:09.006527	2	1990-01-01	\N	f	sandynhafcosta@facebook.com	t
4394	Kaio Cainã Nobre Dos Santos	natsohiboshi@gmail.com	natsohiboshi	@		b6a09ca29e8b7fdaf083d29f419da2ae	f	\N	2012-12-04 14:24:26.692421	1	1998-01-01	\N	f	kaio-kun@hotmail.com	t
4308	Tatiane Aline Oliveira Caminha	tatyanne_allyne@hotmail.com	Tatyane	@		e53c62e514a1c7fd085b92152fd88859	f	\N	2012-12-03 18:58:35.083557	2	1995-01-01	\N	f	tatyanne_allyne@hotmail.com	t
4324	Vanessa Souza Oliveira	wanessa.oliver8@gmail.com	vanessa	@		3e5e4a9e933100c7550c1738e247d1ef	f	\N	2012-12-03 22:06:24.903662	2	1995-01-01	\N	f		t
4309	Brenna	brenna-araujo@live.com	B.Steele	@		42a4e6ca8f3294c8c5d143813e8901d8	f	\N	2012-12-03 19:03:09.009929	2	1993-01-01	\N	f	brenna-araujo@live.com	t
3748	Andrinny Leal Dias	andrinny1995@gmail.com	andrinny	@		ae7de598960bf6ecb56d1de4dff612e9	f	\N	2012-11-27 15:49:20.149071	1	1995-01-01	\N	f	andrinny.dias@gmail.com	t
4311	José Flávio	joseflavio@alu.ufc.br	José Flávio	@		25a278f20f0ae00bda49f85f632e0fb3	f	\N	2012-12-03 19:49:15.176348	1	1993-01-01	\N	f	joseflavio@alu.ufc.br	t
2186	Mayara Jessica Cavalcante Freitas	mayarajessica20@gmail.com	Mayrinha	@		ffb2154d5c5b9aa75468cfc4f7787389	f	\N	2011-11-23 19:56:36.599989	2	1994-01-01	\N	t		t
4340	Deborah Sousa Silva	Deborasousa1001@gmail.com	Deborah	@		1b97a77a09d62b0ce54304020733100c	f	\N	2012-12-04 08:40:08.164881	2	1994-01-01	\N	f		t
902	Samuel Jerônimo Dantas	samueljeronimo@hotmail.com	Samuel	@samjeronimo		a8557714848b2cdcaa119210345cdca2	t	2012-12-04 11:01:38.972724	2011-11-16 12:11:51.531903	1	1991-01-01	\N	f	samueljeronimo@hotmail.com	t
4450	JOSE JOAB FERREIRA DA SILVA	joabf9@gmail.com	JOABSILVA	@		b918a3b441a768720d1c9e7d3c9891fb	f	\N	2012-12-04 22:19:28.123709	1	1988-01-01	\N	f	joabf9@gmail.com	t
4366	Maria Andréia Santiago da Silva	andreiasantym@hotmail.com	Andréia	@		9150b078b31c14944ebe8c46287e5327	f	\N	2012-12-04 11:54:36.284156	2	1997-01-01	\N	f	andreiasantyg@hotmail.com	t
4716	Romero Lopes de Lima	romerosintese@hotmail.com	Romero Lopes	@		51aa403875349c144f74fd1fcce0c786	f	\N	2012-12-05 20:34:42.502788	1	1981-01-01	\N	f		t
4372	Osvaldo Modesto Silva Filho	omsf_itprofessional@gmail.com	Osvaldo Filho	@osvaldofilho	http://osvaldofilho.wordpress.com	27e4ffcfd238525df0f7d4907f6301ab	f	\N	2012-12-04 12:19:39.045129	1	1986-01-01	\N	f	osvaldofilho.redes@gmail.com	t
4460	Alisson Marx	alissonmarx10@gmail.com	Alisson Marx	@		3028aa5a2d148247bedd722782f69b71	f	\N	2012-12-05 01:03:11.929104	1	1995-01-01	\N	f		t
4376	Cicero Henrique	cicerohen@gmail.com	cicerohen	@cicerohenrique		c9308c657d6c4060bea671b59b659664	f	\N	2012-12-04 12:56:01.480088	1	1985-01-01	\N	f	cicerohen@gmail.com	t
4178	MARIA JOSE MENDES DE MORAES	mariamendesd@gmail.com	Maria Moraes	@maryamoraes2		176d1c4f7341af54d9f8f3376bfdab7b	f	\N	2012-12-01 15:31:01.27165	2	1994-01-01	\N	f	maria_todabo@hotmail.com	t
4468	Pedro Henrique de Andrade	pedro_henrique1102@hotmail.com	Henrique	@		7b372f0c0b2babf9407c681778393c37	f	\N	2012-12-05 09:34:01.361186	1	1997-01-01	\N	f	pedro_henrique1102@hotmail.com	t
4384	Arielle Lima Oliveira	ary.elle@hotmail.com	arielle	@		eaaa4c860df80c1bc6079b32abd47c66	f	\N	2012-12-04 13:15:11.053222	0	1995-01-01	\N	f		t
4389	claudio marcos da silva oliveira	phenicksx@gmail.com	claudio	@		9a630d88f01ee531ab95cbe7d15e57b5	f	\N	2012-12-04 13:43:51.90417	1	1983-01-01	\N	f		t
4476	ANTONIO RENATO SANTOS SOUSA	renatosantos478@yahoo.com	RENATO	@		a61194013d9dd3164c9adaa48f828662	f	\N	2012-12-05 10:05:01.704154	1	1997-01-01	\N	f	renatosantoscp@yahoo.com	t
4400	felipe	nyson_pacifico@hotmail.com	felipe	@		a30fd46229d836b867d8952d35d085f5	f	\N	2012-12-04 14:55:30.975679	1	1989-01-01	\N	f	nyson_pacifico@hotmail.com	t
4483	felipe cavalcante dos santos	felipecs75@hotmail.com	felipe	@		9cc18f3f7bf2470fae6a56bd66016013	f	\N	2012-12-05 10:19:53.541165	1	1997-01-01	\N	f	felipecs75@hotmail.com	t
4403	Pablo Italo da silva sombra	pabloiti14@hotmail.com	Pablo Italo	@		a7e499cb5d36cd7e5565b648204118e8	f	\N	2012-12-04 16:14:32.467246	1	1996-01-01	\N	f		t
5002	Alice Fernandes	alicefernandesafs@gmail.com	Alice Fernandes	@		98a996f6205d7dfe1ab68e8fc46795e1	f	\N	2012-12-06 16:14:22.240569	2	1997-01-01	\N	f	alice_129@hotmail.com	t
4777	fenexomega	4everjordone@gmail.com	jordyfg	@		c6098c94070276011b8e5ad6f7688a5d	f	\N	2012-12-06 01:39:43.616054	1	1993-01-01	\N	f		t
5121	Rafaela Mendes da Silva	rafaellalourenco1@hotmail.com	Faelaaa	@		f3487e7b391aff462991415979e70bd4	f	\N	2012-12-06 20:55:07.994456	2	1996-01-01	\N	f		t
4494	José Roberto Castro Souto Júnior	jose_roberto1a@hotmail.com	Robert	@		3945c7690bf99494dde03682cababdcf	f	\N	2012-12-05 10:29:38.231081	1	1997-01-01	\N	f	jose_roberto1a@hotmail.com	t
5042	Vitória Régia Cavalcante da Silva	vitoria_regia12@bol.com.br	Vitória	@		476b5f28090065c34a0062643b21f3fb	f	\N	2012-12-06 17:29:53.422815	2	1997-01-01	\N	f		t
4824	JOSÉ LINDEMBERG VIDAL BARBOSA	lindembergno@hotmail.com	Lindemberg	@		b10c1f4509efb45ce6848b1f64eeddf9	f	\N	2012-12-06 09:32:53.178387	1	1997-01-01	\N	f	lindembergno@hotmail.com	t
4838	Micaelle Rocha de Sousa	micaelle_1a@yahoo.com.br	Micaelle	@		b4a2b97302817ad4c1de5072b64075da	f	\N	2012-12-06 09:52:32.034024	2	1997-01-01	\N	f		t
5071	Klysman	klysmangomes@gmail.com	klysman7	@	http://sige.comsolid.org/participante/add	c92c37d5b5364de335de6cb22051ac0b	f	\N	2012-12-06 19:50:16.503266	1	1997-01-01	\N	f	klysmanpessoa@hotmail.com	t
5449	Matheus de Sousa Lima	matheushxcx@hotmail.com	Ramone	@matheusramone10		207607f03d76da34842429ee20b7dc44	f	\N	2012-12-08 21:25:54.211191	1	1993-01-01	\N	f	matheusramone@facebook.com	t
5147	Breno Macedo Da Silva	ibraimovict@hotmail.com	Slardark	@		83fe291625135b6c824d4f1cb465b1d9	f	\N	2012-12-07 00:00:38.343874	1	1993-01-01	\N	f	Brenno-troll@hotmail.com	t
5374	Francisco Breno Domingos da Silva	brenodomingos@gmail.com	brenodomingos	@		51a81c9ce452180d67f57082ec9cc675	f	\N	2012-12-08 09:53:04.743192	1	1994-01-01	\N	f	brenodomingos@gmail.com	t
5173	Débora Jandira Araujo Lira	deboralyra88@gmail.com	Debora	@		38dc36ed1a2694296767f9979084d5c9	f	\N	2012-12-07 09:15:43.03929	2	1988-01-01	\N	f		t
5403	Milcar da Silva	milcar.deus@gmail.com	milcardeus	@		4f9b09f54bab5f2c8cfc1690c9f376e2	f	\N	2012-12-08 10:30:46.529664	2	1995-01-01	\N	f	milcar.deus@gmail.com	t
4418	kenedy soares da silva	kenedy.soares.silva@gmail.com	kenedy soares	@		093e194736e9302b7da7eb0b713568b3	f	\N	2012-12-04 17:23:43.856099	1	1994-01-01	\N	f	kenedy_soares@hotmail.com	t
4419	Maria ivania de oliveira sales	ivania.oliveira.sales@gmail.com	aninha	@		892c35546ebc751bc7a5270580e04f27	f	\N	2012-12-04 17:24:18.226876	2	1995-01-01	\N	f	ivania.oliveira.sales@hotmail.com	t
4421	Felipe de Castro Lima e Silva	felipe.castro1995@gmail.com	Felipe	@		ee252d2288d91217504712efbfcb269e	f	\N	2012-12-04 17:24:56.497627	1	1995-01-01	\N	f	felipe-castro1995@hotmail.com	t
5003	ílare de Lima	illarelima@gmail.com	Ílare	@		4effcd90787d1da5f712c274c9d1de3e	f	\N	2012-12-06 16:17:16.667281	2	1995-01-01	\N	f	ilaridelimabarbosa@hotmail.com	t
4717	Francisco Bruno dos Santos Bastos	franciscobrunosantosbastos@gmail.com	brunobastos	@		d6050a7b8b33e3563047ca9b48ec253f	f	\N	2012-12-05 20:41:06.638918	1	1996-01-01	\N	f	brunobastos@gmail.com	t
4461	Antonio Fernando de Moura Junior	moura.brasil@live.com	Fernando Moura	@__fernandomoura		413d51c2db0402349ba847158cf6f3dc	f	\N	2012-12-05 08:36:48.885599	1	2011-01-01	\N	f	moura.brasil@live.com	t
4406	carlos weiber do vale silva	carlos.weibersilva@gmail.com	djweiber	@weiber		440c7424d759f451d030027d7e859c51	f	\N	2012-12-04 17:19:13.079495	1	1991-01-01	\N	f	carlos.weibersilva@gmail.com	t
4417	David Costa Soares	david.costa.soares@gmail.com	DavidSr.	@		9bef4eaef5f450f32a6c9d32a9b67fb7	f	\N	2012-12-04 17:23:04.838988	1	1995-01-01	\N	f	david.costa.soares@gmail.com	t
4469	Tayná Martins	taynasousa31@hotmail.com	tatinha	@		01fbd32bd06d6141b50e776a4278ea9e	f	\N	2012-12-05 09:34:40.078923	2	1996-01-01	\N	f		t
4423	Patricia Rodrigues da Silva	pattymolekinha@gmail.com	Patty molekinha	@		5b3daaf30ae7d793ee8e08d6f48a02a4	f	\N	2012-12-04 17:25:18.136572	2	1995-01-01	\N	f	pattymolekinha@gmail.com	t
4420	Jeferson Inacio Macedo	jeferson.inacio.macedo@gmail.com	Jefinho	@		2e74eee42b9578308386119ea54f0afa	f	\N	2012-12-04 17:24:48.607	1	1995-01-01	\N	f	inaciojeferson@hotmail.com	t
4422	Enyo Cavalcante de Souza	enyo_cavalcante@hotmail.com	_enyo_	@		abf2030397e80567331d3f5b029395f9	f	\N	2012-12-04 17:25:14.498725	1	1994-01-01	\N	f	enyo_cavalcante@hotmail.com	t
4425	Francisco Edinilton Cardoso da Silva	edinilton.nolton@gmail.com	Edinilton	@		8a3b689cdba0fef1c479566218fbb89f	f	\N	2012-12-04 17:32:33.356399	1	2011-01-01	\N	f		t
4426	Francisco Edinilton Cardoso da Silva	edinilton.nilton@gmail.com	Edinilton	@		09c867f614667c933a5c3523b4596332	f	\N	2012-12-04 17:34:48.348355	1	1994-01-01	\N	f		t
4427	Ruth de Sousa Moreira	ruths.moreira@hotmail.com	Ruth Moreira	@		0885d6cdca0b34baac77d26f4a2e0e0d	f	\N	2012-12-04 18:30:22.818956	2	1984-01-01	\N	f	ruths.moreira@hotmail.com	t
4477	ANTONIO RENATO SANTOS SOUSA	renatosantos487@yahoo.com	RENATO	@		ed7b0c7b48e5a52a068d987b8f5cdadb	f	\N	2012-12-05 10:08:36.386689	1	1997-01-01	\N	f	renatosantoscp@yahoo.com	t
4428	Jessica Borges Silva	jessykadazgaiatinhaz@hotmail.com	Jessica	@		f02f8e219005da5efc315491a73f2580	f	\N	2012-12-04 18:47:54.85822	2	1994-01-01	\N	f	jessykadazgaiatinhaz@hotmail.com	t
5043	Aline Nunes do Nascimento	alinenn7@gmail.com	Aline Nunes	@		c185f6c3e22d597b234412a6a10ec997	f	\N	2012-12-06 17:31:17.49497	2	1997-01-01	\N	f		t
4484	Anderson Lima Menezes	andersonlimajava5@hotmail.com.br	uchiha	@		16b5502b959eb8c0d42a13d8b42b8579	f	\N	2012-12-05 10:21:43.269116	1	1997-01-01	\N	f	sharingananderson_@hotmail.com	t
4424	Dayane da Silva Sousa	dayane-ssousa@hotmail.com.br	Dayah' 	@		0bdcddd737de1bb60fbb2d82f596493a	f	\N	2012-12-04 17:27:27.020444	2	1993-01-01	\N	f	dayaneesiilva@hotmail.com	t
4490	Antonio Soares	antoniosoares_1a@hotmail.com	Antonio	@		4060264a474f3d67c214071fdb8f03a9	f	\N	2012-12-05 10:25:34.213447	1	1992-01-01	\N	f	antoniosoares@hotmail.com	t
5148	Breno Macedo Da Silva	Brenno-troll@hotmail.com	Slardark	@		be7423a52fc5006f3621a0c95830d2b0	f	\N	2012-12-07 00:08:27.16657	1	1993-01-01	\N	f	Brenno-troll@hotmail.com	t
4495	Roberto Pereira da Silva	roberto9974@live.com	pereira	@		39160c6524dc3edb0a365c0d2484da58	f	\N	2012-12-05 10:29:59.342523	1	1997-01-01	\N	f	roberto9974@live.com	t
4499	Fabiana da silva costa	fabiana_1a@hotmail.com	biazinha	@bialoketes2		53f6cbc7630faedf51843490a22673ef	f	\N	2012-12-05 10:32:05.069653	2	1997-01-01	\N	f	bia.lokete1@hotmail.com	t
3710	Jordy Ferreira Gomes	jordymunhoois@hotmail.com	jordyf	@		fe8f32a1b1963a95edd0f98691b73d4d	f	\N	2012-11-26 23:30:31.223658	1	1993-01-01	\N	f		t
4502	Francisco Cleilton Dos Santos Silva	francisco_cleilton@hotmail.com	clecle	@cleilton144		70b5d8e2e948fd4a693f92088ebf72cc	f	\N	2012-12-05 10:34:01.360957	1	1997-01-01	\N	f	francisco_cleilton@hotmail.com	t
4504	Romário Ferreira Ribeiro	mx9romario@gmail.com	Romário	@		a7c8ac61bab833459e994df77eac6617	f	\N	2012-12-05 10:35:33.18423	1	1995-01-01	\N	f	mx9-romario@hotmail.om	t
5072	Ueliton Sousa Dodó	uelitonsd@gmail.com	Ueliton	@uelitonsousa		2e27b38f339d9a954c538446bb813516	f	\N	2012-12-06 19:51:52.015093	1	1986-01-01	\N	f	ueliton21sd@hotmail.com	t
5174	VIviane de Meneses Santos	vivane_demeneses@hotmail.com	Viviane	@		5e0d1af841dc008642594105a55a98ec	f	\N	2012-12-07 09:22:02.596594	2	1996-01-01	\N	f		t
4792	Lucas Emanoel de Lima Sousa	llucas_emanoel@hotmail.com	 Bussuzim'	@lLucasitap		7c07900b6dbcde304d7c9d216f3172b5	f	\N	2012-12-06 08:33:42.563501	1	1996-01-01	\N	f	lucassousafla@hotmail.com	t
5197	Paulo Roberto da Costa Souza	pauloroberto392@gmail.com	Paulo Roberto	@		a722888342b2c51817c2d2f75165bc00	f	\N	2012-12-07 10:34:17.579363	1	1996-01-01	\N	f		t
4744	valeska	eska.gomes@hotmail.com	Valeska	@		d9937b5a57fec1c9f09f12443eeb499b	f	\N	2012-12-05 22:22:08.132689	2	1995-01-01	\N	f		t
5220	NATALIA XAVIER DE OLIVEIRA	natalia_vier@hotmail.com	NATALIA	@		9f74b213baaa480c2af0a8a1b2e2b64d	f	\N	2012-12-07 10:49:19.721289	2	1995-01-01	\N	f		t
5241	Emanuele Farias OLiveira Neta	altemar_turismo10@yahoo.com	Manuzinha	@		fb1c5fef6b875ac94a20a93a5f8612fc	f	\N	2012-12-07 11:05:38.631481	2	1997-01-01	\N	f		t
5404	Eliza de Lima Silva	eliza.criador13@gmail.com	Eliza Lima	@		aca3c4c51bee79f2af5f7fe26022ef7a	f	\N	2012-12-08 10:31:27.354466	0	2011-01-01	\N	f		t
5280	Jéssica Da Silva Santos	jessica.deus16@gmail.com	Jéssica	@		9db9b252fec8adc8aff13bfe62421972	f	\N	2012-12-07 14:08:08.041619	2	1995-01-01	\N	f		t
5450	Jackison Iury Vidal de Sousa	jacksoniury@hotmail.com	Jackison Iury	@		d97abf31fd534c641992ca4656e8403a	f	\N	2012-12-08 23:37:47.631989	1	1993-01-01	\N	f	jacksoniury@hotmail.com	t
5427	GLEWTON	glewtonaguiar@hotmail.com	GORDIM	@		74214539f9b14be92b37964b874fb5a3	f	\N	2012-12-08 13:02:13.212853	1	1995-01-01	\N	f	glewtonaguiar@hotmail.com	t
3652	Luciane Vieira SilvaDias	luciane.vsd@gmail.com	Thaiaaa	@		a35afbd28ff272652f49b6bd1d859470	f	\N	2012-11-23 22:25:52.608977	2	1988-01-01	\N	f		t
2127	vitor mateus felix ribeiro	vitoor.mateus@hotmail.com	vitinho	@		b495ce55022fa5168afbba92771421f5	f	\N	2011-11-23 18:02:10.024237	1	1996-01-01	\N	f	vitoor.mateus@hotmail.com	t
4470	Helena Oliveira	hellennarockmh@hotmail.com	Helena Azuos	@		305c467214c908741cdf02429acc07f5	f	\N	2012-12-05 09:35:15.355387	2	1997-01-01	\N	f	hellennarockmh@hotmail.com	t
4431	lucas cardoso matos	lucascardos@hotmail.com	lucas123	@		4da55d5920a2cd57e4382f3746f9b889	f	\N	2012-12-04 19:36:51.95851	1	1992-01-01	\N	f		t
4298	daiane da silva coutinho	daiannesilva2010@gmail.com	daiane coutinho	@		32f9cedb542be89a634a70e6c3cfc481	f	\N	2012-12-03 16:39:07.27992	2	1994-01-01	\N	f	daiannesilva2010@gmail.com	t
4433	RENAN CEZAR MARTINS DE FARIAS	renan_cezar@msn.com	Renan Cezar	@		f7beea8dd709716607b2ceeb7d5d76aa	f	\N	2012-12-04 20:18:52.940932	1	1991-01-01	\N	f	renanseliga@gmail.com	t
3817	ADELIANIA HENRIQUE DA COSTA	adelianiahenrique@gmail.com	Liania	@		32bf677ef34abd31a7c4b88beeb96e1d	f	\N	2012-11-28 10:12:23.772422	2	1988-01-01	\N	f	adelianiahenrique@gmail.com	t
4718	Lívia dos Santos Feijão	liviafeijao@gmail.com	Lívia Feijão	@		6969132a7ff099a907f3f20ca25d677c	f	\N	2012-12-05 20:58:02.477134	2	1993-01-01	\N	f		t
5004	Marília Andrade	liadriele@gmail.com	Mary Andrade	@		99a39e04c5de40f6b8fe75976ff044b5	f	\N	2012-12-06 16:17:23.172434	2	1996-01-01	\N	f	liadriele@gmail.com	t
4478	Ana Patricia Henrique Damasceno	patricia_henrique_@hotmail.com	Patricia	@		61b2fcbfe10841d9c703bf3a35f45b35	f	\N	2012-12-05 10:13:21.866553	2	1993-01-01	\N	f	patricia_henrique_@hotmail.com	t
4485	Maria Vanessa Moura Piauí da Silva	vanessamoura_1a@yahoo.com.br	Vanessa Moura	@		ec27cd888e5307c4d135ad078ad8ae04	f	\N	2012-12-05 10:21:44.999353	2	1996-01-01	\N	f	vanessa_barbygirl@hotmail.com	t
1090	Francisco Amsterdan Duarte da Silva	amster_duarte@hotmail.com	Amsterdan	@		fdd4209c6fd9355c4b66258e97288836	t	2012-12-05 22:45:30.760082	2011-11-20 21:12:16.04893	1	1995-01-01	\N	f	amster_duarte@hotmail.com	t
4491	Lucas da Silva Oliveira	luquinhas.ce@hotmail.com	Tenho não	@		291603820297f6f2ff1869498015c074	f	\N	2012-12-05 10:25:43.821558	1	1997-01-01	\N	f	luquinhas.ce@hotmail.com	t
4496	Antonio Igor Mendes de Freitas	igormendesfreitas@gmail.com	Igãozão	@igormendes97		0d9a868fb6bf3d041caca36f87f72914	f	\N	2012-12-05 10:30:32.961413	1	1997-01-01	\N	f	igormendesfreitas@gmail.com	t
4500	Mariana Matias Lopes	marianamatias@outlook.com	Mariana	@		9e2be529e4e211fe3edb50d267b1867b	f	\N	2012-12-05 10:32:08.342061	2	1997-01-01	\N	f		t
5044	Iully Melo Silva	iully.anne@hotmail.com	Iully Melo	@		6aee6032a5de958d33f5fcef7f4d46ad	f	\N	2012-12-06 17:33:59.547256	2	1997-01-01	\N	f		t
4503	FRANCISCO RENATO JORGE DE SOUSA	renato.sousa40@yahoo.com.br	RENATO	@		c4b740a50ea73f025bebaf16c849a293	f	\N	2012-12-05 10:34:12.37876	1	1992-01-01	\N	f	renato-de-sousa@hotmail.com	t
4778	Mikaele Costa	mikaele-costa_7@hotmail.com	Mikaele	@		77b9da3aefb232077c00788283ee0ec6	f	\N	2012-12-06 07:09:39.465342	2	1996-01-01	\N	f	mikaeleqcosta_7@hotmail.com	t
4505	Thalia de Medeiros Costa	gatinha-bol@hotmail.com	grilss	@gatinha123		11d49200e4e6925a02b7eb409740aa13	f	\N	2012-12-05 10:37:31.562141	2	1997-01-01	\N	f	gatinha-bol@hotmail.com	t
4506	Maria Edilene 	mariaedilenegomes123@hotmail.com	não tenho	@		016263ad0eca84f44e287eae03fbae77	f	\N	2012-12-05 10:38:23.894019	2	1996-01-01	\N	f	mariaedilenegomes123@hotmail.com	t
4507	Patrick Sousa da Silva	patrick_1a@hotmail.com.br	------	@		6c84cbd30cf9350a990bad2bcc1bec5f	f	\N	2012-12-05 10:39:22.045347	1	1997-01-01	\N	f		t
4508	Erika Carvalho de Sousa	erikacarvalho338@rocketmail.com	mekita	@erikaGleek		5597ea2e7ee935eefd81da99548d457e	f	\N	2012-12-05 10:43:35.804069	2	1994-01-01	\N	f	mekita24@hotmail.com	t
4793	Victor Silva	victiin_silva@live.com	Restart	@		bb18aa6b0bcd0c06f9b7d42af25ccfaf	f	\N	2012-12-06 08:34:29.119806	1	1995-01-01	\N	f	victor_gaiatin@hotmail.com	t
5337	Emanuele Farias Oliveira	emanuelefarias_13@yahoo.com	manuzinha	@		5bb2387669d7433ff2dc949dd7ae8a6d	f	\N	2012-12-07 21:24:53.656161	2	1997-01-01	\N	f		t
4825	ALYSSON SOUSA RODRIGUES	cromossomocarioteca@hotmail.com	ALYSSON	@		c173ab049292740499c1a192114fcf9e	f	\N	2012-12-06 09:36:19.502421	1	1996-01-01	\N	f	cromossomocarioteca@hotmail.com	t
5073	Eltyenio Almeida Coelho Dias	eltyenio_dias@hotmail.com	Eltyenio	@Eltyenio	http://www.facebook.com/eltyenio.dias	74c41989ad8394af2b102e891a6bc08b	f	\N	2012-12-06 19:53:12.895976	1	1993-01-01	\N	f	Eltyenio_a7@hotmail.com	t
5149	Kennet	kennetsales@gmail.com	Kendoshy	@		7d888e20bad5c65357674e831a95da70	f	\N	2012-12-07 00:22:59.434948	1	1994-01-01	\N	f	kennet.anderson.sales@facebook.com	t
4865	renata sousa de morais	renatasousamorais@gmail.com	renata	@		bc26c13be22a522ad8df94a3033cd233	f	\N	2012-12-06 10:34:09.047264	2	1988-01-01	\N	f		t
4877	Antonio Carlos Silva Oliveira	twistedmetalextrim@hotmail.com	antoniocarlos	@		ca5a7ca5047edeb960a010b51784fd46	f	\N	2012-12-06 11:09:09.881432	1	1993-01-01	\N	f		t
5175	Ana Flávia Santos Oliveira	favinha1521@hotmail.com	Ana Flávia	@		c498c25ee04594217376856c9270be28	f	\N	2012-12-07 09:24:02.582838	2	1995-01-01	\N	f		t
5198	Frank da Silva Ferreira	franky20021@live.com	Franki	@		83e1260e98654e65f316491a61f4dfbf	f	\N	2012-12-07 10:35:28.441684	1	1995-01-01	\N	f	franky20021@live.com	t
5221	SARA DA CRUZ SOBRAL	sara.sobral.cruz@gmail.com	SARA SOBRAL	@		f7e636a74af98ef86f6a2dec892e7d9e	f	\N	2012-12-07 10:49:19.864831	2	1994-01-01	\N	f		t
5405	Karoline Barroso Batista	karoline.barroso96@gmail.com	Karoline	@		9833f6057cf203932d14a93bec787605	f	\N	2012-12-08 10:31:29.408793	2	1996-01-01	\N	f		t
5242	 Nayane da silva	graci_ane1987@hotmail.com	nayane	@		7c1c9699980ec119c53dc7c6dcf888c5	f	\N	2012-12-07 11:05:46.366946	2	1995-01-01	\N	f		t
5451	Maria Elizabeth Magalhães Vieira	betinha_etno@hotmail.com	Elizab	@	http://verdadesingular.blogspot.com.br/	7b6cfd64307c3d97bd18a9364c067511	f	\N	2012-12-11 09:23:01.740986	2	1983-01-01	\N	f	betinha_etno@hotmail.com	t
4489	Alessandra Freitas da Costa	fiaesandro@hotmail.com	Sandrinha	@		4f0113f6b71eb5cee02e52a509281417	f	\N	2012-12-05 10:24:32.293569	2	1998-01-01	\N	f		t
4509	GUSTAVO PEREIRA ANTAO	gustavo-pereira@oi.com.br	Gustavo	@		976dedbb7caa2ba9924e94b7eca1cf88	f	\N	2012-12-05 10:46:15.42346	1	1988-01-01	\N	f	gustavo-pereira@oi.com.br	t
4510	Vanessa da Silva Rabelo	gatawanessasilva@hotmail.com	Vanessa	@		0008f6c175e951786e76fcc0a8a333eb	f	\N	2012-12-05 10:47:46.427267	2	1997-01-01	\N	f		t
4719	MARIA IARA ARAUJO SOUSA	araujomariaiara@gmail.com	IARA MARIA	@		008b683b2d134146f16933b1b011c050	f	\N	2012-12-05 21:06:32.838149	2	1995-01-01	\N	f	ARAUJOMARIAIARA@GMAIL.COM	t
4511	Sara Maria do Nascimento e Silva	Saramary_sr@hotmail.com	Sarinha	@		2aa3de55cf69264d959a3ed688986015	f	\N	2012-12-05 10:48:09.926262	2	1996-01-01	\N	f	Saramary_sr@hotmail.com	t
4512	Joyce Girão Dias	joycegirao1a@yahoo.com.br	Joycee	@		3f9a475967bfc657734fc32facda1049	f	\N	2012-12-05 10:48:45.820102	2	1997-01-01	\N	f		t
4513	Rômulo Lucas Wanderley de Sousa	rlucasw@hotmail.com	Rômulo	@		eb474dd4d681f9834c8619c6141918fc	f	\N	2012-12-05 10:49:37.17952	1	1997-01-01	\N	f		t
4514	Francisca Evandra da Silva Lima	evandra1a@hotmail.com	Evandra	@		1298b5af7306d9ba54c005f0944d7c10	f	\N	2012-12-05 10:53:08.366759	2	1995-01-01	\N	f	evandra1a@hotmail.com	t
3599	Michel Pereira Machado	michelpm2@gmail.com	michelpm2	@		a09e89e29336502e745470a3b102921a	f	\N	2012-09-28 11:37:12.948995	1	2011-01-01	\N	f		t
4761	José Smith Batista dos santos	sumisujrock@hotmail.com	shuusumisu	@sumisu_sama		1e5b87243657a0e3c6aa7a45b8bc741d	f	\N	2012-12-05 23:13:16.705844	1	1992-01-01	\N	f	josesmithbatistadossantos@gmail.com	t
3359	ANDERSON DE SOUZA GABRIEL PEIXOTO	andersonpeixoto1@live.com	ANDERSON D	\N	\N	ee7c36208625ee35365cbf9ced607efc	f	\N	2012-01-10 18:25:45.313767	0	1980-01-01	\N	f	\N	f
4517	Giselly Kilvia Oliveira Aguiar	g_kilvia@hotmail.com	GisellyK	@		ad68461f330f0c28b8f4a516bf4bb8c0	f	\N	2012-12-05 10:58:18.48307	2	1994-01-01	\N	f	giselly.kilvia@facebook.com	t
4518	Maria Samilla Pinto Silva	samillasilva_@hotmail.com	Samilla	@		b95c98ca379c3e5353da7e3ed60b3a26	f	\N	2012-12-05 11:00:35.067347	2	1990-01-01	\N	f		t
5074	Fiama Lopes de Oliveira	fiamalopes5@gmail.com	fiamalopes	@		b317fcc559a6cb1f1f55f2c3f6496248	f	\N	2012-12-06 19:53:50.280422	2	1993-01-01	\N	f	fiamalopes@gmail.com	t
1326	JOSE EDILAN PONCIANO COSTA	madsonddias@hotmail.com	EDILAN	@		bd9cf6d64136da1855b3b32e1cb1e723	f	\N	2011-11-22 11:04:04.349696	1	1994-01-01	\N	f		t
5005	Aline Dias	alllynny@gmail.com	Aline Dias	@		9d6996c2d18509efcf324a3cba3c73c2	f	\N	2012-12-06 16:20:40.513981	2	1994-01-01	\N	f	aline-jesuscristo@hotmail.com	t
4520	Natália Martins Sousa	srtnatymartins@hotmail.com	natyyyyy	@		dfc0e832e492845e8a9085338bbc8b85	f	\N	2012-12-05 11:04:29.124936	2	1997-01-01	\N	f		t
4794	ghabriel dixon	ghabrieldixon@hotmail.com	ghabriel	@		a2a8f6f123f50e80e21283fe60ab2d7f	f	\N	2012-12-06 08:35:38.133553	1	1996-01-01	\N	f	ghabrieldixon@hotmail.com	t
2453	gabriel linhares de souza	linhares.biel@gmail.com	Gabriel	@		1d924890d86f91158fdb82d8b5f9594d	f	\N	2011-11-24 15:55:45.454539	1	1998-01-01	\N	f		t
4826	JEFFERSON DOUGLAS FERNANDES	jerffesson16@hotmail.com	jerffesson	@		ea81c10cd12579ff2c525d41fca6ca64	f	\N	2012-12-06 09:38:16.451985	1	1996-01-01	\N	f	jerffesson16@hotmail.com	t
5045	Fernando Lenys Silva Fernandes	d3blender@hotmail.com	Fernando	@		f89b54eee6f4ebc096fe8000ed3e6f9e	f	\N	2012-12-06 17:35:01.91042	1	1997-01-01	\N	f		t
4854	SAMILE FERNANDES MARTINS	samilyfernandes@gmail.com	Samily	@		b4dbbdf0e3293c63b4dbf6d647a28c6f	f	\N	2012-12-06 10:03:50.185558	2	1989-01-01	\N	f	samilyfernandes@gmail.com	t
4224	Leiliane Maria da Silva	leiliane0519@hotmail.com	Leilinha	@		a9dd8588183fbe470393a548959124a1	f	\N	2012-12-02 22:55:41.587603	2	1991-01-01	\N	f	leiliane0519@hotmail.com	t
4707	Bianca	bianca_carmo01@hotmail.com	Belezinha	@Bianca_Thominhas	https://www.facebook.com/bianca.ferreira2012	e9ca1e08a07a1fb630873675a25b098f	f	\N	2012-12-05 20:08:32.550062	2	1996-01-01	\N	f	bianca.gata100@hotmail.com	t
5338	Guilherme Augusto Silva de Freitas	guilhermeasdf27@gmail.com	Guilherme	@		e0e44c27a1dea22bc77739efd2be3cd1	f	\N	2012-12-07 21:40:08.839199	1	1997-01-01	\N	f		t
4878	JAEL ALMEIDA DE CARVALHO	jael33820565@hotmail.com	jael almeida	@		296fb9685423841f2126d2cfcb15083e	f	\N	2012-12-06 11:10:07.883794	1	1996-01-01	\N	f		t
4888	WILLIAM DE SOUZA PARENTE	williamsouzaparente@gmail.com	williiam souza	@		da501f79f86b58c90fe5832e354e20a2	f	\N	2012-12-06 11:41:46.669158	1	1992-01-01	\N	f		t
4899	Mardeson Macedo de Alencar	mardesonjk1@hotmail.com	Mardeson	@		0d23af2d2e72918f97cbb4b7802754e7	f	\N	2012-12-06 11:58:00.308259	1	1996-01-01	\N	f		t
5176	Francisco Edmar Alexandre da Silva	alexandreedmar8@hotmail.com	Edmar Alexandre	@		81010081249dfb593130da1aef4ad501	f	\N	2012-12-07 09:25:52.620734	1	1998-01-01	\N	f		t
5406	Francisco da Costa Bezerra Lira	fcostas2011@gmail.com	Francisco	@		a6b1cbedab7f02dc7dd7db40fc1d62dc	f	\N	2012-12-08 10:31:50.363735	1	1996-01-01	\N	f		t
5222	antonia Nadia Dos Santos Braga	alynnehcosta@hotmail.com	Nadinha	@		645c93e70b532aaeacc2502f9683dcf0	f	\N	2012-12-07 10:49:52.548829	2	1998-01-01	\N	f		t
5243	Antonio Dejaime Teofilo da Silva	dejaime7@hotmail.com	yellowboy	@		cd7fd4f6e1d133bf5b2fd98e7ce1ce27	f	\N	2012-12-07 11:11:17.010485	1	1996-01-01	\N	f	dejaime7@hotmail.com	t
5281	ORLEANA KARENE LIMA GOMES	orleanagomes@gmail.com	ORLEANA	@		814c1853acd342366377030894f7726f	f	\N	2012-12-07 14:08:49.466455	2	1980-01-01	\N	f		t
4525	Jéssica Patrícia Silva Vasconcelos	jpam_jp@hotmail.com	Jéssica	@		5ea572b114be9d47d4b9039eba7fd6c3	f	\N	2012-12-05 11:33:26.777413	2	1991-01-01	\N	f	jpam_jp@hotmail.com	t
4526	Matheus Messias Alves da Silva	matheus_messias@outlook.com	Messias	@MatheusMesias07		cccfacb6ec7ee82081e4b08cd52d6c33	f	\N	2012-12-05 11:35:40.648421	1	1996-01-01	\N	f	matheus_messias@outlook.com	t
4521	Madson Luiz Dantas Dias	m.dias-@hotmail.com	omadson	@omadson	http://omadson.wordpress.com	7ace895bbaeb89281614e62aa98c3dda	f	\N	2012-12-05 11:05:07.18942	1	1990-01-01	\N	f	m.dias-@hotmail.com	t
4527	José Wellington Araújo Farias Júnior	junior-farias13@hotmail.com	Júnior	@junior130995		7cace662c8de935f4789a93ea097b5d1	f	\N	2012-12-05 11:47:17.800377	1	1995-01-01	\N	f	junior.farias.1044@facebook.com	t
5006	BRENDO PEREIRA DE PAULO	brendodepaulo10@gmail.com	BRENDO	@		03c1355e80da528f09b1223a01fed974	f	\N	2012-12-06 16:23:47.567553	1	1995-01-01	\N	f		t
4762	Leilton Ramos de Oliveira	leiltonr@gmail.com	Leilton	@		aa65d9f9943f3cf25d6065bcd00bc1e8	f	\N	2012-12-05 23:14:13.422174	1	1982-01-01	\N	f		t
4779	Aline Suely Chagas Leitão	aline_suely100@hotmail.com	Aline 	@		8b7cc699efd34052eb6ca2fc26e7a254	f	\N	2012-12-06 07:44:36.16798	2	1993-01-01	\N	f	aline_suely100@hotmail.com	t
4531	Apolonio Alberto Barros e Silva	apolonio.barros@hotmail.com	Apolonio	@apolobarros		40ccb73e61a87c83090a67e5c1c8de03	f	\N	2012-12-05 11:54:04.002354	1	1996-01-01	\N	f	apolonio.barros@hotmail.com	t
5046	frenando mateus da silva lima	nanduhplay@hotmail.com	nandu    	@		8bea36c6af41d9b2bfbba1b852efce4d	f	\N	2012-12-06 17:39:35.027082	1	2000-01-01	\N	f		t
4795	Samuel  Azevedo de Abreu	prostituta2020@hotmail.com	Samuel Azevedo	@		306270d6080f4e025d987fae3a4379ac	f	\N	2012-12-06 08:35:55.755926	1	1996-01-01	\N	f		t
4533	Brena Talyta Pinho Martins	brenatalytapm_100@hotmail.com	BrenaT	@		a990794df3b8a6b4e3b41d85dbb57ac1	f	\N	2012-12-05 11:55:53.843731	2	1996-01-01	\N	f	brenatalytapm_100@hotmail.com	t
4532	Vitória Facundo Macedo	vitoriafacundo@hotmail.com	Vitória	@vitoriafacundo		804868e5e9374549fdd3374665e7262f	f	\N	2012-12-05 11:54:15.734792	2	1996-01-01	\N	f	vitoriafacundo@hotmail.com	t
4534	PEDRO LUCAS	peddroluccas@live.com	PEDDRO	@		77044cd2204589c626a8ea14b69a610f	f	\N	2012-12-05 11:57:22.279732	1	1996-01-01	\N	f	pedro_lucas2009_@hotmail.com	t
5075	Antonio Barros de Sousa Neto	a.barros.souza.neto@gmail.com	netinho	@		1f0e1ed2a27fce5959d3ff8e86702601	f	\N	2012-12-06 19:54:01.005336	1	1981-01-01	\N	f	a.barros.neto@hotmail.com	t
4827	Elane Gomes	elane15gomes@gmail.com	ElaneGomes	@		3e27a27361354913ff9bfa62dbfb5789	f	\N	2012-12-06 09:40:19.812179	2	1996-01-01	\N	f		t
4536	Francisco Jair  Lobo Vieira Filho 	jairlobo@outlook.com	CodingZero	@		a59399530a66350a8868bb56f1be803b	f	\N	2012-12-05 12:00:23.144196	1	1995-01-01	\N	f	jairlobo96@hotmail.com	t
5339	lucas teixeira da costa silva	luks.t3@gmail.com	lucas t	@		bbdf11ea16fe3a89dee43cf01120aeaf	f	\N	2012-12-07 21:42:37.515725	1	1993-01-01	\N	f	lucs_t@hotmail.com	t
4537	Antonio Raimundo Rocha Mendonça	antonioraimundo007@gmail.com	Raimundo	@		6efc25fc3df324920a4cf90b1b6a02eb	f	\N	2012-12-05 12:00:38.080987	1	1996-01-01	\N	f	antonioraimundo007@hotmail.com	t
4528	Francisco Ferreira da Silva Júnior	fransa_junior2008@hotmail.com	Júnior	@		74c5de09312b4501b13e8cc5c0b73bf9	f	\N	2012-12-05 11:47:54.906008	1	1997-01-01	\N	f	fransa_junior2008@hotmail.com	t
4841	KARINA COSTA MORAIS	karinacostamr@hotmail.com	karina	@		3606ab275a7ad9430eb59aa0046f7944	f	\N	2012-12-06 09:53:31.128957	2	1997-01-01	\N	f		t
5177	Francisco Anderson de Souza	andersoncreww111@hotmail.com	Anderson	@		b548e431464adbce59864102af1c48b4	f	\N	2012-12-07 09:29:56.620022	1	1996-01-01	\N	f		t
4855	PEDRO IGOR MARQUES TEIXEIRA	pedroigor.com@gmail.com	PEDRO IGOR	@		8fa8a15ed7d307f0ffb1ad20429c5882	f	\N	2012-12-06 10:05:41.620275	1	1992-01-01	\N	f	pedroigor40@hotmail.com	t
4866	Allef Bruno da Silva Freitas	allef@e-deas.com.br	Allef Br	@		4ab32b4afe36bd658bffa4c559320e02	f	\N	2012-12-06 10:34:23.333003	1	1993-01-01	\N	f		t
5200	Felipe Bruno	markalleson@hotmail.com	Felipe Bruno	@		e5b264767f063f92a42d3f225fa666e6	f	\N	2012-12-07 10:36:08.8015	1	1992-01-01	\N	f		t
4900	SAMUEL SAMPAIO MAGALHAES	samuel_sampaio_@hotmail.com	Samuel	@		d81d6b4e72567d8dfc971e5226d037b9	f	\N	2012-12-06 11:58:09.305411	1	1994-01-01	\N	f	samuelsampaio6a@yahoo.com.br	t
5244	RENATA DODO DOS SANTOS	renatads94@hotmail.com	Renata	@		ecf86da0b4b58791edc7ceabd91eceba	f	\N	2012-12-07 11:18:50.816722	2	1994-01-01	\N	f		t
383	Antonio Everardo Silva Diniz	everardovpr@gmail.com	everardo	@everardovpr		033399c38091c3dd29171680d2e61ece	t	2012-12-07 12:52:29.437754	2011-10-18 14:38:24.259655	1	1989-01-01	\N	f		t
5378	Pedro Albano Lopes Braga	pedro_little@hotmail.com	Hygness	@		d4de5abd91fc985405796f91c8018c94	f	\N	2012-12-08 10:01:31.464935	1	1995-01-01	\N	f		t
5282	Naira Sindel Maciel Pinto	nayrasindel@hotmail.com	Sindel	@		e518b34d27564a8efc4bc6a73fa9e760	f	\N	2012-12-07 14:09:11.093113	2	1996-01-01	\N	f	nayrasindel@hotmail.com	t
5299	Gabriel Araujo	gabriel.matematica@hotmail.com	Gabriel	@		b1135e879a90c7c4e821ed6ed61adc99	f	\N	2012-12-07 14:56:26.36948	1	1998-01-01	\N	f		t
2361	manuel agapito de sousa	manuel.agapito@yahoo.com.br	coleguinha	@		c3dcd885a5860a53d99724db3be0a4f8	f	\N	2011-11-24 11:59:41.128543	1	1991-01-01	\N	f		t
5324	Ellen Cristina Barbosa Nascimento	ellen@projetoejovem.com.br	EllenA	@		e09d6a4a8cb333979fb7b185d9fff012	f	\N	2012-12-07 17:30:27.212431	2	1979-01-01	\N	f		t
5407	Marcelo Lima Maia	Macello.lima19@gmail.com	Marcello	@		b3ce7cbc7957a5bf8a5983a1c88b148a	f	\N	2012-12-08 10:32:57.352025	0	2011-01-01	\N	f		t
4538	Francisca Wully Alves Paiva	wllyalves@hotmail.com	Wlly Alves	@Wllyalves		f86959e25c15c8f42a0ef588cea09aba	f	\N	2012-12-05 12:06:53.315994	2	1996-01-01	\N	f	wlly1000@hotmail.com	t
4540	Francisco Hederson Santos da Silva	hedersonsilva5@hotmail.com	Hederson	@		47dd973e056b7304b4509558041c2eb5	f	\N	2012-12-05 12:12:33.421412	1	1995-01-01	\N	f	herdersonsantos@gmail.com	t
4539	Raimundo Moreira Dias Neto	moreiradias2008@hotmail.com	Moreira	@		4ea0981de70d8c1c534656c1feb533a0	f	\N	2012-12-05 12:11:56.549693	1	1996-01-01	\N	f	moreiradias2008@hotmail.com	t
2014	Ismael Martins Macedo	ismaell.mm@gmail.com	Ismael Martins	@		7a2985ce14de89e8c97c6c1b1e57a6fc	f	\N	2011-11-23 15:27:06.822192	1	1992-01-01	\N	f		t
4721	Ricardo Valentim	ricardovalentimjunior@hotmail.com	Júnior	@		595655274a6504ac3d78d8032077a6a5	f	\N	2012-12-05 21:13:48.809529	1	1994-01-01	\N	f	ricardovalentimjunior@hotmail.com	t
4541	Thaynara Sousa Ferreira	thaynarasousavp@hotmail.com	Thaynara	@		60d0d2f7f3fbefedd50178a0d4f056da	f	\N	2012-12-05 12:18:23.45254	2	1996-01-01	\N	f		t
5007	Ana Jéssica	annajessicafreitas@gmail.com	Ana Jéssica	@		2ae6232b206e6b883b5ee44619aa1a3e	f	\N	2012-12-06 16:23:55.376102	2	1997-01-01	\N	f	jessica_gtloukajtm@hotmail.com	t
4543	Jorge Vitório Tavares	norbdus@gmail.com	Vitorio	@		fc6657b89fda6b3b26f9ac7321dbf760	f	\N	2012-12-05 12:28:12.140946	1	1980-01-01	\N	f	norbdus@gmail.com	t
4544	Thaynara Sousa Ferreira	thaynarasousa@outlook.com	Thaynara	@		f5e4f5bb59e05da82fa2003070cfcb31	f	\N	2012-12-05 12:28:33.220211	2	1996-01-01	\N	f		t
4542	Igor Duarte Braz	igorduartebraz@gmail.com	igor duarte	@		bd236d35a9fcb987c04aa07330c1a171	f	\N	2012-12-05 12:27:17.200889	1	1997-01-01	\N	f		t
4780	Ana Flávia da Silva	iranaflaviadasilva@yahoo.com.br	Irmã Flávia	@		07efaa73cfb5231c45d0a62655a1cad4	f	\N	2012-12-06 07:53:06.367018	1	1977-01-01	\N	f		t
4545	Luan Sales Rodrigues Uchoa	luan_g.t.o31@hotmail.com	LuH. Sallez	@		1238cf2a17a7330d87eb92a402bdfc3d	f	\N	2012-12-05 12:35:04.655802	1	1996-01-01	\N	f	luan_g.t.o31@hotmail.com	t
5340	francisca rosângela sousa da silva	rosangela_pinksusy@hotmail.com	rosangela	@		1dfa436503c30652155f7c60234439c7	f	\N	2012-12-07 21:43:47.358375	2	1994-01-01	\N	f	rosangela_pinksusy@hotmail.com	t
4547	Daylane de Oliveira Sales	daylanesales27@hotmail.com	Daylane Sales	@		9e7422fd5d57ba6a9f20a2d043975971	f	\N	2012-12-05 12:36:55.683593	2	1997-01-01	\N	f		t
5178	Allen William Magalhẽs  de Lira	allenwilliam@hotmail.com	XDDWily	@		dad5703f9d28696cb197dd4c314d8775	f	\N	2012-12-07 09:34:59.059281	1	1996-01-01	\N	f		t
4796	Taylan Vieira	taylan11t@gmail.com	Taylan	@		ca730d2bec717fa0984dcceb7abc295d	f	\N	2012-12-06 08:37:12.279608	1	1996-01-01	\N	f	taylan11t@hotmail.com	t
4550	Francisco Fabrício Pereira Marinho	fabricioffpm@hotmail.com	Bibito	@		cc54fd7d7b7f3e4fbe5dbf3833b66770	f	\N	2012-12-05 12:38:18.010392	1	1996-01-01	\N	f	fabricioffpm@hotmail.com	t
4552	Patricio Gerson Silva Vasconcelos	patricio_gerson@hotmail.com	Gerson	@		accf4f8d3a518137280f619f23368d8e	f	\N	2012-12-05 12:42:22.710988	1	1996-01-01	\N	f	patricio_gerson@hotmail.com	t
5224	Andre Luis Vieira Lemos	andre.luis.vireira.lemos@gmail.com	AndreLuis	@		5aedde6cd9add99a6134218b0b282a8a	f	\N	2012-12-07 10:50:36.929869	1	1990-01-01	\N	f		t
4553	Yône Maria Araujo Silva	yonemaria_phn@hotmail.com	Yône Maria	@		34ee9338188ffd788d9400eeeec49649	f	\N	2012-12-05 12:44:34.314935	2	1997-01-01	\N	f		t
4856	otavia sousa alves	tavinhaoya@hotmail.com	otavia	@		fdd500369a9c3d1a8c5f950bf577fe0b	f	\N	2012-12-06 10:06:40.936287	2	1988-01-01	\N	f	tavinhaoya@hotmail.com	t
4867	izadora Queiroz	izadorakeiroz@gmail.com	branquinha	@		cd2813f50175b86313e9b24f56113778	f	\N	2012-12-06 10:45:06.863949	2	1994-01-01	\N	f	izadorakeiroz@hotmail.com	t
1926	nayana	nanay1947@hotmail.com	luka/nana	@		62d939925d264316cbee10875d91205b	f	\N	2011-11-23 14:40:19.927737	2	1996-01-01	\N	f		t
5245	ANA KESIA ALMEIDA DA SILVA	kesialameidainf@gmail.com	ANA KESIA	@		cfe1465e4cd9eeeed71456ea478d2b12	f	\N	2012-12-07 11:19:30.435236	2	1995-01-01	\N	f		t
4901	KAROLINE ALCANTARA TRAJANO	karoline_alcantara@hotmail.com	karol trajano	@		11414329bdb8e80a113a09faacbebd7b	f	\N	2012-12-06 12:00:33.606545	2	1995-01-01	\N	f		t
4914	Karolaine Matos de Moraes	karolaine.matos@gmail.com	karolaine	@		26814cca0f5d7793c98c3beba077e15c	f	\N	2012-12-06 12:03:58.454176	0	1994-01-01	\N	f		t
5408	Thiago Ferreira de Araújo	Thiagoferrerxp@gmail.com	Thiago Ferrer	@		dba43ec362cf83bc791b7b87fbaee43b	f	\N	2012-12-08 10:34:10.396435	0	2011-01-01	\N	f		t
5263	Rafael Martins	rafagha@gmail.com	Rafael comelão	@		cee1b8a7c963c4b28e55ba50fb810559	f	\N	2012-12-07 13:24:16.809923	1	1990-01-01	\N	f		t
5283	Emanoelly Dos Santos Bezrra	emanoellydossantos4@gmail.com	Manu123	@		b7808676537720cfcf518ed9c5f6ed51	f	\N	2012-12-07 14:09:43.362598	2	1991-01-01	\N	f		t
5313	Daniel Pinheiro de Lima	danielpinheiro63@hotmail.com	Daniel	@		a62e53cde736d132ecdfce91f3d8ef56	f	\N	2012-12-07 16:44:07.248975	1	1997-01-01	\N	f		t
1089	Jailson Pessoa Pereira Filho	jailsontakiminase@gmail.com	Taki Minase	@Takiminase		1414704d499d312811ed5ebf7eb22389	t	2012-12-08 13:50:31.450199	2011-11-20 20:44:55.664742	1	1991-01-01	\N	f		t
5325	Eneida Raquel Alves DAlbuquerque	eneideraquel@gmail.com	EneideRaquel	@		f169cdcf96fdd5617131de97306ed838	f	\N	2012-12-07 17:33:12.034311	2	1981-01-01	\N	f		t
4554	Stefany Fernandes Silva	stefany_xgirl@hotmail.com	Stefany	@		c4880b89af6205ce3ea06a6d9aa4e82f	f	\N	2012-12-05 12:47:01.917774	2	1997-01-01	\N	f		t
4555	Laurenice Sousa da Silva	laurenice_sousa@bol.com.br	Laurenice	@		ff8bf761c3767fc2bcfacf389088bf6d	f	\N	2012-12-05 12:48:47.057359	2	1996-01-01	\N	f		t
4556	Antonia Alice Moura de Lima	alicemouralima@gmail.com	Alice Moura	@		96fb2688284d6cf9b99f84912a6d22ca	f	\N	2012-12-05 12:51:04.552119	2	1997-01-01	\N	f		t
5008	Ramon Tales	RTramodk@gmail.com	Laxuss	@		b17e1d3510b19bfa934e14a7d2ad68f8	f	\N	2012-12-06 16:24:08.754704	1	1996-01-01	\N	f	RTramondk@gmail.com	t
4764	Aurea Helena	aurea_helena_gabriel@hotmail.com	Aurinha	@		675fc77a48908bd4de9df988a8e1a782	f	\N	2012-12-05 23:23:22.465794	2	1988-01-01	\N	f		t
3424	HALECKSON HENRICK CONSTANTINO CUNHA	henrick_cc@hotmail.com	HALECKSON 	\N	\N	10044d1c10586d5d67e140168bfc7b08	f	\N	2012-01-10 18:26:08.69608	0	1980-01-01	\N	f	\N	f
4557	Marcos Vanderson	m_wanderson@live.com	mrvanderson	@		123571b8625fa0d594c1923e71fc1f27	f	\N	2012-12-05 12:59:05.652876	1	1995-01-01	\N	f	m_wanderson@live.com	t
4535	Francisco Felipe da Silva	lipinho_god@hotmail.com	Lipinho	@lipinho_god		7e04da88cbb8cc933c7b89fbfe121cca	f	\N	2012-12-05 11:57:43.219534	1	1996-01-01	\N	f	lipinho_god@hotmail.com	t
4558	Denis Oliveira	denis.olvra@gmail.com	denis.olvra	@denisOlvra		4fe20efb679e2d70365d0cbdf597cc4c	f	\N	2012-12-05 13:13:29.2664	1	1992-01-01	\N	f	denis.olvra@gmail.com	t
4559	Maria Luciana Almeida Pereira	marialuciana391@hotmail.com	Luciana	@		8b0dbeb35f71ce7c032fdf0f4f2b4754	f	\N	2012-12-05 13:16:56.393105	2	1997-01-01	\N	f		t
734	HELCIO WESLEY DE MENEZES LIMA	helciowesley@hotmail.com	HELCIO	@		fbd1c3f5c3cf9dc12bb9cd20f86a9a3c	f	\N	2011-11-11 02:15:21.882255	1	2011-01-01	\N	f	HELCIOMILENA@HOTMAIL.COM	t
4797	Lucas Carioca de Oliveira	lucas-carioca-oliveira@hotmail.com	Lucas Carioca	@		0935ff25fd86cd064c7235b0c9c5c2d4	f	\N	2012-12-06 08:38:31.677336	1	1996-01-01	\N	f	lucas-carioca-oliveira-bunitinho@hotmail.com	t
5127	Lukas Costa Fontes	lukasmengo@hotmail.com	Fontes	@		d83a6973aeb0a2c9d4349d70aaecc129	f	\N	2012-12-06 21:13:07.828052	1	1995-01-01	\N	f	lukasmengo@hotmail.com	t
5048	Euricio Santana da Silva	euriciosantana@gmail.com	Euricio Santana	@euriciosantana		e03e9d09785663f5dfca5413be728faa	f	\N	2012-12-06 17:44:54.460923	1	1979-01-01	\N	f		t
4562	Abraão Martins Fernandes Junior	junior_tuf_11@hotmail.com	AJ red bull	@		d92d7e7a0445e624f37c8cf9b64fc506	f	\N	2012-12-05 13:20:07.646274	1	1995-01-01	\N	f	junior_tuf_16@hotmail.com	t
4563	Ana Carla Bernardo Maciel	ana.karla_pink@hotmail.com.br	Ana Carla	@		3a82391051f9a5a6430450142ff59305	f	\N	2012-12-05 13:24:15.228561	2	1995-01-01	\N	f	ana.karla_pink@hotmail.com.br	t
4564	Ramon Felipe Paixão da Silva	ramon_tallica@hotmail.com	Ramon Felipe	@		57edb5dbb2187b14b03743e06730bbbf	f	\N	2012-12-05 13:35:10.876103	1	1987-01-01	\N	f	ramon_tallica@hotmail.com	t
4843	anderson	madara_andin@hotmail.com	andin1	@		022828670204836550608d92026c1c88	f	\N	2012-12-06 09:53:52.405389	1	1996-01-01	\N	f	andin_k2_@hotmail.com	t
4565	Nicolle	nicolle_mpe@hotmail.com	Nicolle	@		d4f67c6d4f6e34a5617f6df2594cc9e6	f	\N	2012-12-05 13:52:35.714285	2	1996-01-01	\N	f	nicolle_mpe@hotmail.com	t
4857	ALLAN KARDECK DA SILVA MANECO 	kdc.allan@gmail.com	ALLAN KARDECK	@		cd6be58ec5225cb20a93adb540eb662a	f	\N	2012-12-06 10:08:19.198417	1	1993-01-01	\N	f		t
4567	Anderson	anderson_aasa@hotmail.com	anderson	@		fb3ffa909b36e0a16e9999b2df542d5a	f	\N	2012-12-05 13:54:31.178687	1	1996-01-01	\N	f	andersonandrade14@yahoo.com.br	t
4868	Alyson Lima	alyson.2008@hotmail.com	Alyson	@fran_alyson		b7c5ad6471f37a70f6769f08f946dc25	f	\N	2012-12-06 10:56:16.292302	1	1993-01-01	\N	f	alyson.2008@hotmail.com	t
937	Valrenice Nascimnto da Costa	valrenicec@gmail.com	Valrenice	@valrenice		32b8953db22970b046e6a84247b0e5d5	t	2012-12-06 11:12:03.801364	2011-11-16 20:59:50.417532	2	2011-01-01	\N	f	valrenice@yahoo.com.br	t
5380	Lucas de Sousa Rodrigues	luki_nhask22@hotmail.com	lucasdousousa	@		684b886ce62497d9808874ddb9658f1c	f	\N	2012-12-08 10:07:24.407307	1	1993-01-01	\N	f	luki_nhask22@hotmail.com	t
5202	Marlineudo Francelino da Silva	ne_guinhoo@hotmail.com	Marlineudo	@		4ccfaea3a25720bffbe42f7a7ed53b6a	f	\N	2012-12-07 10:37:25.059535	1	1995-01-01	\N	f		t
4902	anderson moisés gomes ferreira	anderson.moises.gf@gmail.com	anderson	@		d5ff88c5f3e54655647e39a25f1a19af	f	\N	2012-12-06 12:00:42.691949	1	1996-01-01	\N	f		t
1519	Aloísio Silva de Sousa	aloisiocom@gmail.com	Aloisio Sousa	@aloisiosousa		60756530d19fbff7ab5e9800dc5189c2	f	\N	2011-11-22 17:13:48.652043	1	1980-01-01	\N	f	aloisiocom@gmail.com	t
5225	Antonia Sammya Ferreira	sammyaferreira_16@hotmail.com	samynha	@		f66a1ba3fe894c653d59077c62acd468	f	\N	2012-12-07 10:51:32.071235	2	1995-01-01	\N	f	sammyafereira_16@hotmail.com	t
5246	VANESSA DA COSTA GUIMARAES	vaanessa.guimaraes@gmail.com	VANESSA	@		673ad3926e7cbe0d5b3149b1853de021	f	\N	2012-12-07 11:21:29.575386	2	1995-01-01	\N	f		t
5409	jOELSON FREITAS	joelsonmd@hotmail.com	Joelson	@		4fdc7f559ffc1c03cb9caf57f0678a0b	f	\N	2012-12-08 10:45:18.761614	1	1992-01-01	\N	f		t
5284	FRANCISCA ERILANE DA SILVA	erilanelanny@gmail.com	ERILLANY	@		cc6100a8ccfba18c949b7ce1d1937f77	f	\N	2012-12-07 14:09:46.396426	2	1994-01-01	\N	f		t
5431	Lucas Mateus	l.matheus@live.com	L.Matheus	@CafetaoLM		217047b6d027902184ff432673a84c91	f	\N	2012-12-08 13:47:23.80616	1	1995-01-01	\N	f	tampinha_pequeno@hotmail.com	t
5009	WESLLEY RIBEIRO DA ROCHA	weslleyvx@hotmail.com	WESLLEY	@		95a183aea07f1226b7a3850f5ca38b6d	f	\N	2012-12-06 16:25:38.358958	1	1995-01-01	\N	f		t
4765	Janderson	jandersonsoares50@hotmail.com	Janderson	@		c3180f2786b6f39277b77d94860942a6	f	\N	2012-12-05 23:46:32.031771	1	1995-01-01	\N	f	jandersonsoares50@hotmail.com	t
4570	Antônia Taynara Ferreira Dourado	taynara.florsinha@hotmail.com	Taynara Dourado	@		c287d23a0a14dc7b0f9ccad40cc984fe	f	\N	2012-12-05 13:56:01.34444	2	1995-01-01	\N	f	taynara.handbal@hotmail.com	t
4566	John Hermeson de Lima Rodrigues	johnpcn@hotmail.com	John01	@		2f22af9cb71469c8cd7ade2d5f9d69db	f	\N	2012-12-05 13:53:03.053576	1	1984-01-01	\N	f	johnpcn@hotmail.com	t
4569	Apolonio Alberto Barros e Silva	apolonio.barros@gmail.com	Apolonio	@		21fd5f935ef8f0811e5bd28a40555afa	f	\N	2012-12-05 13:55:46.718098	1	1996-01-01	\N	f	apolonio.barros@hotmail.com	t
4782	Anderson de Souza Gabriel Peixoto	gabriel.neon1@hotmail.com	Babidi	@		4d7b29251b19b1e7fd6f65a8025dc0d0	f	\N	2012-12-06 07:55:01.064073	0	1987-01-01	\N	f	gabriel.neon1@hotmail.com	t
4575	Thiago abreu de Souza	tyago_verso@hotmail.com	Thiago Abreu	@		1c4b770246665261fdfe57941bbf9845	f	\N	2012-12-05 13:58:27.916612	1	1996-01-01	\N	f	tyago_verso@hotmail.com	t
4798	roberto	robertod2.2000@hotmail.com	betobagara	@		b37653f04f0c3797d86c67d9a2312c51	f	\N	2012-12-06 08:38:41.802218	1	1994-01-01	\N	f	robertod2.2000@hotmail.com	t
5128	luiz wellington da rocha silva 	luiswomanizer@hotmail.com	luizinho	@luizwellington1		d0aed4be203d798be5ac88ce9fd96adc	f	\N	2012-12-06 21:15:35.542615	1	1995-01-01	\N	f	luiswomanizer@hotmail.com	t
5049	Rosilene Serafim Carneiro	rosileneserafa@gmail.com	Serafim	@		52e5bb92f6f0782743381ab446a43528	f	\N	2012-12-06 18:04:03.624368	2	1994-01-01	\N	f	rosileneserafa@gmail.com	t
4578	Jheyne Lemos de Sousa	Jheynelemos@hotmail.com	Jheyne	@		f9f70be778dbb62fd3b18dbed39f1dd3	f	\N	2012-12-05 13:58:50.298559	2	1996-01-01	\N	f		t
4844	MARIA LARA CASTRO NASCIMENTO	laramanga1@hotmail.com	maria lara	@		3162188a2dccd9daaf0f00d9f9792d36	f	\N	2012-12-06 09:54:49.038253	2	1996-01-01	\N	f		t
4583	maryana santos	maryana-f@hotmail.com	*-*mary santos *-*	@		6985b15645497b47afbd900b8cbd33ee	f	\N	2012-12-05 13:59:14.85187	2	1996-01-01	\N	f	maryana-f@hotmail.com	t
4869	Sâmia Nogueira	samia.vmn@gmail.com	Sâmia Nogueira	@SamiaNogueira		5df4eb79b2a9d590b91430412ffa003a	f	\N	2012-12-06 10:57:57.961781	2	1990-01-01	\N	f	samia.nogueira@gmail.com	t
5180	Maria Gonçalves Cavalcante de Oliveira	mariagoncalves79@hotmail.com	Lourdes	@	http://www.facebook.com/mariagoncalveslourdes.cavalcante	60083060434d1bf2d68b46c4c2fc7bde	f	\N	2012-12-07 09:36:58.988272	2	2011-01-01	\N	f	mariagoncalves79@hotmail.com	t
4880	lenilton da mota de sousa filho	leniltonfilhok@yahoo.com.br	lenilton	@		fb6ab1fb7ad88d1dd0b783727a04bf38	f	\N	2012-12-06 11:14:34.919597	2	1989-01-01	\N	f		t
4568	Francisco Marcelo Ferreira da Silva	ffsmarcelo@gmail.com	Marcelo	@ffsmarcelo	http://www.itapiuna.com	7533625342ff20eb1788c756067ad75d	f	\N	2012-12-05 13:55:41.17806	1	1984-01-01	\N	f		t
4106	LUAN MATEUS FERREIRA MACIEL	luanmateus08@hotmail.com	luannn	@		7b9b35e0187545499bfcff67b5c95546	f	\N	2012-11-30 15:12:00.948697	1	1995-01-01	\N	f	luanmateus08@hotmail.com	t
5381	Francisco Thiago Oliveira Bevilaqua	Fthiagobevilaqua@gmail.com	Thiago	@		b740ad2aa627d66c9ac93d3339f6139c	f	\N	2012-12-08 10:10:18.575436	0	2011-01-01	\N	f		t
5203	Bruna Aguiar	brunaaguiar421@yahoo.com.br	Bruna Aguiar	@		e2bf3defe2490851e4b499127449bec3	f	\N	2012-12-07 10:39:14.070159	2	1995-01-01	\N	f		t
4590	Thiago Paz Muniz	thiago-paz-muniz@hotmail.com	Thiago Muniz	@		31626a7c703dce2c455ca1309abdaa50	f	\N	2012-12-05 14:07:19.145525	1	1991-01-01	\N	f	thiago-paz-muniz@hotmail.com	t
4921	Gizelly Simoes Rocha	gizellysrocha@gmail.com	Gizelly	@GizellySimoes		590054f51c806d535336e1609afd3812	f	\N	2012-12-06 12:06:08.350241	2	1982-01-01	\N	f	gizellysrocha@gmail.com	t
5226	Maria Leilane Moura Santos	leilanemoura@hotmail.com.br	leilinha	@		886601859535e89db29e15533f353100	f	\N	2012-12-07 10:52:33.681118	2	1997-01-01	\N	f	leilanemoura@hotmail.com.br	t
4923	Thomas Jefferson Ferrer da Silva	paulo_masseiro@hotmail.com	jefferson	@		ef081a938ed6545f3231b08c07429600	f	\N	2012-12-06 12:08:32.689505	1	1996-01-01	\N	f		t
4024	Maria Isabel Rodrigues Correia	isabeltaiba2711@hotmail.com	isabel	@		b10ddc45cffe2183457e759facdf7257	f	\N	2012-11-29 21:51:55.742716	2	1997-01-01	\N	f	isabel2711taiba@hotmail.com	t
4691	Cicero Ventura	ciceroventura@hotmail.com	Hacker k2	@		4eae7c001f40473c58cec575abc28403	f	\N	2012-12-05 19:45:53.31985	1	1996-01-01	\N	f	cicero_l0k0@hotmail.com	t
5410	allam  alves feitosa da silva	allam.alves0@hotmail.com	allamalves	@		7cf79a1e3bf1c9fbca08148ebdfebdf5	f	\N	2012-12-08 10:45:27.709583	1	1998-01-01	\N	f	allam.alves0@hotmail.com	t
5285	ROBSTON REINALDO FERREIRA GOMES	reinaldoferreira.007@gamil.com	REINALDO	@		ab673e9365add333c80c0ed5ed00783b	f	\N	2012-12-07 14:10:52.188803	1	1990-01-01	\N	f		t
5302	Ana Elba Rodrigues da Silva	elba_fadinha@hotmail.com	Elbinha	@		db53258e74a0d856ffbeed09ec8c17f1	f	\N	2012-12-07 15:05:50.214357	2	1994-01-01	\N	f		t
5314	Suzanne Rodrigues dos Santos	suzanne_rodrigues@hotmail.com	Suzanne	@		b7718fbec65ee4ae44822bd15a39613e	f	\N	2012-12-07 16:45:36.508866	2	1997-01-01	\N	f		t
5432	alan torres dos santos	alanfic@hotmail.com	alanfic	@		58989f1aa2ad89d4bb4a583d8311796b	f	\N	2012-12-08 14:03:17.986662	1	1992-01-01	\N	f		t
4589	jeam carlos coelho pereira	jeamjccp@gmail.com	jeam carlos	@jeam_ccp		fadb77e00ff14c29096b42659be8cc9d	f	\N	2012-12-05 14:02:00.00669	1	1996-01-01	\N	f	jeamjccp@gmail.com	t
4591	Elaine Guedes	sakura-cham1@hotmail.com	Elaine	@		c8a66f7331338a292e09b0ed5db57bed	f	\N	2012-12-05 14:15:54.775675	2	1997-01-01	\N	f	sakura-cham1@hotmail.com	t
4592	Wesley Lima	wesleylokkis2013@hotmail.com	wesley	@		907c0391017670ad01273da599621053	f	\N	2012-12-05 14:16:58.444056	1	1996-01-01	\N	f		t
4724	Weuller	weuller.sl@hotmail.com	x Euler	@		b62631eaaf86a35d9efa4c4eec71fe21	f	\N	2012-12-05 21:19:33.870198	1	1994-01-01	\N	f		t
4593	Lara Castro	laramanga@hotmail.com	Lara123	@		2111cd30d33de12a735da12bf656f928	f	\N	2012-12-05 14:17:59.74856	2	1996-01-01	\N	f		t
4594	Franscisco Sérgio Souza do Nascimento Filho	sergiofilho81@hotmail.com	Sérgio	@		6b1f8205360deb85cd44ea7aa73d0058	f	\N	2012-12-05 14:18:56.778171	1	1997-01-01	\N	f	sergiofilho81@hotmail.com	t
4736	Amanda	adesousamatos@yahoo.com.br	Amanda	@		9109cf335f8f4be4e6371c2c6625b608	f	\N	2012-12-05 21:39:31.641904	2	1996-01-01	\N	f		t
4766	Iago Felipe da Silva Tetéo	iagofelipe22@hotmail.com	iago felipe	@		63c9e74aeaa0fe4e6ceec8e534d1f1cf	f	\N	2012-12-06 00:09:10.5271	1	1997-01-01	\N	f		t
4598	José Carlos	kayotbbt@hotmail.com	Kayo12	@		f43aca2741bee5c0baa313613154bc92	f	\N	2012-12-05 14:22:13.451062	1	1996-01-01	\N	f	kayotbbt@hotmail.com	t
4596	Maria Luciana Almeida Pereira	almeidaluciana391@gmail.com	Luciana	@		e79be9d750b820a767088c56c646b4b6	f	\N	2012-12-05 14:21:00.328477	2	1997-01-01	\N	f		t
4783	SANDRA DE CARSIA DANIEL MONTEIRO	carsiamonteiro2011@hotmail.com	sandra	@		d05486b77b11a74fe2dc13b57c3f16ef	f	\N	2012-12-06 08:00:53.301263	2	1993-01-01	\N	f	carsiamonteiro2011@hotmail.com	t
4597	Sérgio Rodrigues Martins Lima	sergiojunior_limma@hotmail.com	Sérgio	@		d9bae3215f4677ddf2fa9972e0bf1c00	f	\N	2012-12-05 14:21:14.774609	1	1997-01-01	\N	f	sergiojunior_limma@hotmail.com	t
304	ROBSON DA SILVA SIQUEIRA	siqueira.robson.dasilva@gmail.com	Prof. Siqueira	@ProfSiqueira	http://www.comsolid.org	530a3fc02e01d7e042e33e1c85f7fbae	t	2012-12-05 14:31:32.902633	2011-10-14 13:28:50.541718	1	1975-01-01	\N	t	siqueira.robson.dasilva@gmail.com	t
4600	Maria Flaviane	meleiby@hotmail.com	flavinha	@		528ab273586f27b48f969cca9307be47	f	\N	2012-12-05 14:50:41.038118	2	1996-01-01	\N	f		t
1351	Diego do Nascimento Brito	Diiego.Britto@gmail.com	Diego Brito	@DieegoBritto		c4bf8f1a097a63a2cdb06c2d786c3e05	t	2012-12-05 14:51:32.391589	2011-11-22 11:31:57.514822	1	1993-01-01	\N	f	Diiego_x1@hotmail.com	t
4601	Abimael Malthus	kimera_parka@hotmail.com	maelzinho	@		4b9822c36fced40d90daf49ab1ca20ef	f	\N	2012-12-05 14:54:13.737876	0	1996-01-01	\N	f		t
4799	Maria Ferreira de Oliveira	mara.jhs2@hotmail.com	Mara linda	@		edf46c48aa3b905bcea4409aafe54c00	f	\N	2012-12-06 08:40:17.41072	2	1996-01-01	\N	f		t
5050	erisilvia silvia	erynha_crazy@hotmail.com	erynha	@		b88821658b5762703a69e0e8e78dec02	f	\N	2012-12-06 18:38:15.899249	2	1997-01-01	\N	f	erynha_crazy@hotmail.com	t
2131	Sabrina Nogueira da Rocha	sabrina-darocha@hotmail.com	Sabrininha	@		bdd5754a1790dc0732f7c5a319bcfdba	f	\N	2011-11-23 18:03:34.607902	2	1993-01-01	\N	f	sabrina-darocha@hotmail.com	t
5079	Lane Lima	leilane_odeioterceiro@hotmail.com	Leilane	@		cdabef3715054be6b15158235cd33d19	f	\N	2012-12-06 19:56:09.488742	2	1999-01-01	\N	f		t
4595	Carla de Getsemani	carlaget.javax@hotmail.com	Carla1	@		0f4b301c6c9f5e114558f2520cd893c3	f	\N	2012-12-05 14:20:38.634258	2	1995-01-01	\N	f	get.tecnofenix@gmail.com	t
5105	VALTER SALES NETO	vavaxpc@hotmail.com	VALTIM	@		2b16365ebdb9713e9526415767d2d3c6	f	\N	2012-12-06 20:11:27.985909	1	1995-01-01	\N	f	vavaxpc@hotmail.com	t
4599	FRANCISCO LANDEMBERG DE MENDONCA SANTOS	landembergmendonca@gmail.com	Landim	@Landemberg		f298c392ca097ba1408e64cb522238ea	f	\N	2012-12-05 14:23:08.245506	1	1996-01-01	\N	f	Landemberg@yahoo.com.br	t
5382	Cristiano Felipe de Mesquita Castro	cristiano.fmc@hotmail.com	Cristiano	@		0c756d9b4383938dc4d754e83f916a94	f	\N	2012-12-08 10:16:20.32426	0	1996-01-01	\N	f		t
4881	Gleiciane Sobrinho e Vasconcelos	grgleiciane@gmail.com	gleiciane	@		37621eee3519aac03a220be237b16b82	f	\N	2012-12-06 11:18:29.884276	2	1992-01-01	\N	f		t
4893	Pedro Vitor Lira Araujo	pedro.vitorlira@gmail.com	obamas	@		a5dfbbdc3480764d93a9aaeebb776aeb	f	\N	2012-12-06 11:42:52.226087	1	1993-01-01	\N	f	pedovitorliraaraujo@hotmail.com	t
4903	matheus moreira da silva	moreirace1@hotmail.com	moreira	@		00db38359eedb1ca5d02ea4cf629ef0c	f	\N	2012-12-06 12:01:38.147452	1	1996-01-01	\N	f		t
5010	Antonio Flavio Vieira da Silva	flaviovieira94@gmail.com	Flavio	@		a2a7484e9653e5a55feb0f7a5e4a05a8	f	\N	2012-12-06 16:26:32.121612	1	1994-01-01	\N	f		t
5204	Antonia Nayane da silva	nayanesilva2012@hotmail.com	nayane	@		5d190c441dc351297690fc5c6b65a434	f	\N	2012-12-07 10:40:29.139013	2	1995-01-01	\N	f		t
3769	Matheus coelho de sousa	matheuscoelho.sousa@gmail.com	Coelho	@		284f63747688096354e133e9631a2f41	f	\N	2012-11-27 19:11:25.613001	1	1996-01-01	\N	f		t
5411	Jéssica alves feitosa da silva	jessica.alves@hotmail.com	jessica	@		7f65dcdacd0a0a35b0d6ca6658656c54	f	\N	2012-12-08 10:47:20.919642	2	2000-01-01	\N	f	jessica.alves@hotmail.com	t
5248	maria wesla nogueira da silva	weslaejovem@gmail.com	weslla	@		762deb3a8152f7b428f5ee77e456027d	f	\N	2012-12-07 11:30:52.610476	2	1996-01-01	\N	f		t
5286	Fernanda Edwiges Rodrigues Pereira	fernandaedwigesrp@hotmail.com	Fernanda	@		9e45b059c3e8cdea0d29ba9a9a64f228	f	\N	2012-12-07 14:11:19.621288	2	1996-01-01	\N	f		t
5433	Paulo Emilio Silva de Souza	p.emilio93@hotmail.com	Emilio	@		8a4a0c1b0b0106636bdc0ebe62a28e58	f	\N	2012-12-08 14:03:50.439546	1	1993-01-01	\N	f	p.emilio93@hotmail.com	t
4607	Brenda da Silva	avyllaguimaraes@hotmail.com	brendinha	@		4e764666497b88b444aa2a0a11ba11ce	f	\N	2012-12-05 14:58:43.308122	2	1995-01-01	\N	f		t
4608	Mikael de Sousa Lopes	mikaelsousa66@gmail.com	mikael	@		d8710bdd3558682b04d04ea99eb0727f	f	\N	2012-12-05 14:59:52.612006	1	1996-01-01	\N	f		t
4725	Lucivan Castro Barroso	lucivanbarroso@mail.com	Takeshi	@		00c98120077d149ed8a046033abbc78c	f	\N	2012-12-05 21:35:16.773518	1	1992-01-01	\N	f	lucivan_takeshi_118@hotmail.com	t
4432	Robson Caetano de Lima	robyrapadura@hotmail.com	Robson	@		64adff6a16e2116a166b27d78ec7c6c0	f	\N	2012-12-04 20:10:35.608125	1	1992-01-01	\N	f		t
5011	Jeova de Lima Rogrigues	naraely2004@yahoo.com.br	jeovadelima	@		372ecdd46887f5714937fc70e065d804	f	\N	2012-12-06 16:27:07.977676	1	1994-01-01	\N	f		t
4767	Gesiel Chaves	gesiel.tecno@gmail.com	Ziel Chaves	@zielchaves		de0349feee8afb94a156a52e2c763e48	f	\N	2012-12-06 00:21:30.748501	1	1993-01-01	\N	f	chaveco14@gmail.com	t
4618	Renata Ferreira	renata_fereirra@hotmail.com	renathinha	@		9f511b73b7a190fe8ee416b140d0fd1a	f	\N	2012-12-05 15:48:55.833435	2	2011-01-01	\N	f	renata_fereirra@hotmail.com	t
4617	Larissa Lima	laryssa_lima11@hotmail.com	larissinha	@		d51adbd90c77f7a4528ae2f0cd1d9867	f	\N	2012-12-05 15:41:17.638229	2	2011-01-01	\N	f	laryssa_lima11@hotmail.com	t
4613	Brena Silva 	b-rena1231@hotmail.com	Breninha	@		ecfcdb0de8326f3cafb86a98b9ab2743	f	\N	2012-12-05 15:25:38.209531	2	2011-01-01	\N	f	brena_silva2012@gmail.com	t
1001	PAULO HENRIQUE COUTO VIEIRA	phzinn@hotmail.com	Paulo Couto	@phzinncouto	http://www.facebook.com/phzinncouto	adcebeafbb16fc1ac715d06e0d66b986	t	2012-12-05 15:30:55.710824	2011-11-18 14:36:56.710654	1	1992-01-01	\N	f	phzinn@hotmail.com	t
4605	Maria Brena	brena_cds30@hotmail.com	Breninha	@		d8fb445013ae951d37960d54f1ca0418	f	\N	2012-12-05 14:55:49.288226	2	2011-01-01	\N	f	brena_cds30@hotmail.com	t
4612	matheus de melo	matheusflamenguista.ce@gmail.com	matheuszim	@		c89f2d1fdfefe1109f2144960adc1feb	f	\N	2012-12-05 15:23:46.827251	1	2011-01-01	\N	f	matheusflamenguista.ce@gmail.com	t
4784	Nayara de Queiroz	nayaradequeirozfreitas@gmail.com	Nayca Nayara	@Nayca_Nayara		5dc098a24d89b16cb0f5190d9ac56276	f	\N	2012-12-06 08:27:17.994003	2	2011-01-01	\N	f	n.aya02@hotmail.com	t
4615	Rodrigo Melo	lirisrock@hotmail.com	F-ZEMA	@		6cf1afe4f7dbbb07b32e44f395b694c3	f	\N	2012-12-05 15:37:54.388574	1	1980-01-01	\N	f	lirisrock@hotmail.com	t
4616	Caroline Caetano Da Silva Macedo	camacedoo@gmail.com	Caroline	@		3c95f190bf1f48a0ed3ca96055193d47	f	\N	2012-12-05 15:38:54.393413	2	1993-01-01	\N	f	karolinehmacedo@hotmail.com	t
5051	CLERIVAN SOUSA DOS SANTOS PIRES	ivan_phc@hotmail.com	clerivan	@		5bff0f1e62e4a754da237ea7652b9569	f	\N	2012-12-06 18:56:34.391484	1	1989-01-01	\N	f		t
4614	Angelo de Medeiros Lima Junior	angelo_juniorr@hotmail.com	Junior	@		7a606d2853bd5520218b02c576e7798f	f	\N	2012-12-05 15:34:16.505044	1	1988-01-01	\N	f	angelo_juniorr@hotmail.com	t
4602	Maria Eduarda	duda.lr22@hotmail.com	Duda Lima	@		c6ef6e53500824e1258779859b7eff77	f	\N	2012-12-05 14:55:06.102835	2	2011-01-01	\N	f	duda.lr22@hotmail.com	t
4800	Francisco Glairton de Menezes	glairton.show@hotmail.com	molekinho	@		8f3b81523db2f03dd5f44381f6c85ba4	f	\N	2012-12-06 08:41:13.435699	1	1993-01-01	\N	f	molekinho_18@hotmail.com	t
4817	valber	valberaraujo10@gmail.com	valber	@		afc231bd7f5a911d246828f5da6081b5	f	\N	2012-12-06 09:05:28.902457	1	1995-01-01	\N	f		t
4619	Alice De Azevedo Marinho	aliceamarinho@gmail.com	Alice Azevedo	@aliiceazevedo		26950f73ded5b8539869782f1aa876fb	f	\N	2012-12-05 15:56:31.368576	2	1993-01-01	\N	f	aliceamarinho@gmail.com	t
5106	Luiz Felipe de Gusmão	luiz.f93@hotmail.com	felipe	@luizbarrao		a04b08427f12b35e8dead7ed5e455d0a	f	\N	2012-12-06 20:11:31.511228	1	1993-01-01	\N	f	l.felipe.barrao@hotmail.com	t
4832	Rômulo do Nascimento Rocha	roomulo_roch@hotmail.com	Rômulo	@		38e9b1bd93eb31457634a1e212cf760e	f	\N	2012-12-06 09:41:08.152837	1	1998-01-01	\N	f		t
5344	geslany maria alves do nascimento	geslanynascimento@gmail.com	laninha	@		03bb178809dd3b2bc22b5958aaeef478	f	\N	2012-12-07 21:44:27.214723	2	1996-01-01	\N	f	geslanynascimento@gmail.com	t
4846	JOAO PEDRO MATOS DA SILVA	jpedromatos96@yahoo.com.br	joão pedro	@		f9ed83f7263d39d0113e455e644a316e	f	\N	2012-12-06 09:56:14.795778	1	1996-01-01	\N	f		t
5129	Sabrina Nogueira da Rocha	sabrina.nogueira19@gmail.com	Sabrininha	@		2cfac4b86361960351c6d52665db0289	f	\N	2012-12-06 21:27:43.590191	2	1993-01-01	\N	f	sabrina-darocha@hotmail.com	t
3711	Antonio Anselmo da Silva	programadorantonio@gmail.com	Antonio Anselmo	@linuxanselmo	http://portal.antonioanselmo.com	ffef25d4cfc4dd13cef1f5f5529deb2a	f	\N	2012-11-26 23:36:06.00348	0	1977-01-01	\N	f	linuxanselmo@ig.com.br	t
4882	Banda Síntese	bandasintese@hotmail.com	Síntese	@	http://sintese-meular.wix.com/oficial	1bf533927a624f53987dcdd57e9be5f8	f	\N	2012-12-06 11:39:26.45442	1	1998-01-01	\N	f	bandasintese@hotmail.com	t
5182	Thomas Andersson Lucas Pecheco de araújo	thomas.araujo50@gmail.com	Thomas	@		6d4e5bce65eaf6ed5ffdfc977dfef5c4	f	\N	2012-12-07 09:38:56.07188	1	1994-01-01	\N	f		t
5383	anderson gomes andrade	gomes.andrade1@gmail.com	anderson	@andersongomes07		9d7f104b94b5e8ccc73e16a669dc7d12	f	\N	2012-12-08 10:16:54.176848	1	1994-01-01	\N	f		t
5205	Felipe Freitas Oliveira	f_freitas_12@hotmail.com	Felipe Freitas	@		49c7cb605dc65ebe61a61160b09df517	f	\N	2012-12-07 10:40:31.649296	1	1995-01-01	\N	f		t
5412	Francisco Janderson Moreno de Oliveira	fcojandersonoliveira@gmail.com	Janderson	@		97babf8cc9e601cc50a38775667d2339	f	\N	2012-12-08 10:59:23.084907	0	2011-01-01	\N	f		t
5434	wendel de sousa terceiro	wdesousaterceiro@yahoo.com.br	wendel3	@		f8317eaf73542b5975530289d5a48146	f	\N	2012-12-08 14:13:38.015935	1	1982-01-01	\N	f		t
4620	Iam Bruno da Fonseca Sales	iambrunof@hotmail.com	thanatos	@iambruno_		7ec8269b233268ec87d9e3eeb7d5a37e	f	\N	2012-12-05 15:56:35.772542	1	1995-01-01	\N	f	iambrunof@hotmail.com	t
4621	Nadia Sousa Gadelha	nadiagadelha94@gmail.com	Nadia Gadelha	@		30de8ede285047d935f05f7886b6b3ab	f	\N	2012-12-05 15:56:48.66026	2	1994-01-01	\N	f	nadiagadelha_15@hotmail.com	t
4726	Samuel Elias Andrade Gomes	samuel.elias.a@hotmail.com	Samuel	@Samuell_elias		041f22f0a7db33da0fceac99ccd10aaf	f	\N	2012-12-05 21:35:42.006509	1	1996-01-01	\N	f	eu_samuelandrade@hotmail.com	t
4622	cindh araujo soares	cindh.soares@hotmail.com	Cindh Soares	@		ea140503b5767ba25012f4d13c195862	f	\N	2012-12-05 15:58:16.69517	2	1994-01-01	\N	f		t
4623	Thalyson Maia Pinheiro	thlyson@gmail.com	thlyson	@		ae5367e5014ce66ddcfabbb01ccb643a	f	\N	2012-12-05 15:58:22.121581	1	1994-01-01	\N	f	thallyson-ce@hotmail.com	t
4624	Anderson Pereira dos Santos	andersonnp1@hotmail.com	Anderson Santos	@		960acbff0de63898787106767dfe2e59	f	\N	2012-12-05 16:01:20.295264	1	1993-01-01	\N	f		t
5012	Larissa dos Santos Farias	larissasf1@gmail.com	Larissa	@		c780d75d8cb2731fefe9bc1d9e53a88f	f	\N	2012-12-06 16:27:30.035365	2	1997-01-01	\N	f		t
4750	Jardel Saldanha	jardel.saldanha@gmail.com	Jardel	@		4344d6f7ca71f9eff1406a9f7a712a1f	f	\N	2012-12-05 22:34:28.253318	1	1993-01-01	\N	f	jardel.saldanha@gmail.com	t
4768	Joseph Messias	messiasph@hotmail.com	messias	@		305a4c1c544765ec97165eb974f72acc	f	\N	2012-12-06 00:23:59.965512	1	1996-01-01	\N	f	messiaspk@hotmail.com	t
4785	Bruno de Oliveira Rodrigues	brunno.oliveiras2@hotmail.com	Brunno	@		622e60ca3e3512065daf164af64b2058	f	\N	2012-12-06 08:30:07.437181	1	1995-01-01	\N	f		t
4626	Charles Muller Gomes Jardim	charles1993muller@hotmail.com	Muller	@		c7b47d578a723d0a5a121d5a15210364	f	\N	2012-12-05 16:10:40.365083	1	1993-01-01	\N	f	charles1993muller@hotmail.com	t
5052	Bruno Castro	bruno_bcastro@hotmail.com	Lobão	@		24a2ef4a47eb0583ef4bb5106e10a2a7	f	\N	2012-12-06 19:10:24.109163	1	1900-01-01	\N	f		t
5130	Jefferson Cruz Nascimento	jeffersoncruz110@gmail.com	Jeffinho	@		5a249254e0d4076863675ee6c1310b9b	f	\N	2012-12-06 21:30:58.305587	1	1992-01-01	\N	f	jeffersoncruz110@gmail.com	t
4818	roberto 	robertbmw.v8@gmail.com	mestredosmesttres	@		e927dde4e074efedeb5bf41e9b45c83c	f	\N	2012-12-06 09:08:58.57021	1	1994-01-01	\N	f	robertod2.2000@hotmail.com	t
4833	mariane da silva costa	marianesilva_1a@yahoo.com.br	mariane1	@		0d6ced739707ee7a9e32a1da2cd04eec	f	\N	2012-12-06 09:48:27.942609	2	1996-01-01	\N	f	marianecosta14@walla.com	t
5107	Leticia Queiros de Oliveira	dada_rebelde_forever@hotmail.com	leticia	@		1cbc1e181339ea92208383a9e5f64092	f	\N	2012-12-06 20:11:35.040965	2	1994-01-01	\N	f	dada_rebelde_forever@hotmail.com	t
4847	Misael Torres Martins	mtorresmbr@gmail.com	Misael	@mtorresmbr		7882adbb84145d748e42caf3ebd939df	f	\N	2012-12-06 09:56:58.400937	1	1981-01-01	\N	f	mtorresmbr@gmail.com	t
1097	KAIO HEIDE SAMPAIO NOBREGA	kaio.heide@gmail.com	Kaio '-'	@kaioheide		1e56795f2ac9bb8cc54a09c189aeed87	t	2012-12-06 10:14:42.845146	2011-11-21 09:15:53.279655	1	1993-01-01	\N	f	bladerwarriorangel@hotmail.com	t
5183	Rayane da Silva Vieira	rayanesilvaejovem@gmail.com	Rayane	@		5cf084e43f62a501848a6aa55f6df223	f	\N	2012-12-07 09:39:57.642876	2	1996-01-01	\N	f		t
5345	francisca mirtes alves da silva	mirtes.alves.23@gmail.com	myrttes	@		d077d90de9032834fba0a4043d5c763b	f	\N	2012-12-07 21:45:20.233937	2	1994-01-01	\N	f	mirtes_cearamor@hotmail.com	t
3446	JOELSON FREITAS DE OLIVEIRA	jhoelsonmd@hotmail.com	JOELSON FR	\N	\N	92e2c2b0e87e9c02ccdca1c3f6286eb9	f	\N	2012-01-10 18:26:15.487591	0	1980-01-01	\N	f	\N	f
5206	Nardo Mazollyne da Silva Souza	nardomazollyne@gmail.com	nardo.	@		94beff10850e83ab8de78c992aca9e68	f	\N	2012-12-07 10:40:35.337824	1	2011-01-01	\N	f	nardomazollyne@hotmail.com	t
4904	Rafaelson	rafaelsonmarques@hotmail.com	FAESON	@		4c25d0c411103e95267131aba28e4e87	f	\N	2012-12-06 12:01:44.789645	1	1995-01-01	\N	f	rafaelsonradicalg3@hotmail.com	t
5228	Edka Cândido Alves	edkalves@hotmail.com	dikinha	@		8fa2622dfbf408221f9fe5ab4610a186	f	\N	2012-12-07 10:54:58.951268	2	1992-01-01	\N	f	kittydeocara@hotmail.com	t
5384	NILVALDO MESSIAS BEZERRA	nivaldo-b@ig.com.br	NIVALDO	@		56ca25425d6723c7de3b9f3a0c1fc599	f	\N	2012-12-08 10:17:27.196467	1	1966-01-01	\N	f		t
2351	Francisco Diego Lima Freitas	diego.freitas92@gmail.com	Freitasdl	@Freitasdl		573a2b657b2db276f49e2ca5f495afcd	f	\N	2011-11-24 11:45:13.923953	1	1992-01-01	\N	f	diego.freitas92@gmail.com	t
5250	Mayara Vieira Bastos	mayvpbastos@gmail.com	Mayara	@		c5e91dc5d1e0f778464a5fadc23d33d0	f	\N	2012-12-07 11:47:16.763551	2	1986-01-01	\N	f		t
5268	Jamille Kerollane da Silva	jamille132@hotmail.com	Jamille	@		bcadff8e3cc1bee7a0732697d9c1660b	f	\N	2012-12-07 13:58:38.390421	2	1994-01-01	\N	f		t
5287	Herverson Fernandes Clemente	herverson1995@gmail.com	Herverson	@		f3641b9a7f6c5785c0050e054463401f	f	\N	2012-12-07 14:11:38.797889	1	1995-01-01	\N	f		t
5413	Antonio Alves Lopes Filho	tonyalveslopes@gmail.com	Alves Tony	@		ba7c7c8e0edc41a4b20386e640490734	f	\N	2012-12-08 11:01:18.738205	1	1992-01-01	\N	f		t
5435	ALINE MARIA DA SILVA FREITAS	aline_freitas27@ymail.com	Aline Freitas	@		93dba18e111e88a6c7963bcce551fe69	f	\N	2012-12-08 14:14:23.166432	2	1995-01-01	\N	f	aline_freitas27@hotmail.com	t
4639	Danilo Vieira da Silva	danilovieirasilva18@gmail.com	Danilo Silva	@		75db19a3498cdaa481f3d6ccbabcd588	f	\N	2012-12-05 16:23:17.89938	1	1994-01-01	\N	f	daniloreggueiro@hotmail.com	t
1756	LAKILSON BARROSO E SILVA 	lakilson@yahoo.com.br	LAKILSON	@		9612110be4c1f771fe98b512f20454e8	f	\N	2011-11-23 09:31:59.405008	1	1981-01-01	\N	f	lakilson@yahoo.com.br	t
4640	Anderson Pereira dos Santos	andersonnp10@gmail.com	Anderson Pereira	@		de531ae6d9f8f82b41180d6ca47d5231	f	\N	2012-12-05 16:56:49.518345	1	1993-01-01	\N	f		t
4727	jackson	jacksonsouzalopes@gmail.com	jackosn	@		fb8232ddb2c0890c4c3863b114b15938	f	\N	2012-12-05 21:35:47.166191	1	2011-01-01	\N	f	dj_3000_@hotmail.com	t
4642	Luanderson Pereira Da Silva	fubuvpg@gmail.com	zulu negao	@		518956020f03771f51e997446fb2cecd	f	\N	2012-12-05 17:00:25.418434	1	1993-01-01	\N	f	zulu_854@hotmail.com	t
4643	rafae laitte	rafael.leite95@gmail.com	cabelo	@		1a925b147d50132a6c94918153cbeb73	f	\N	2012-12-05 17:02:05.04716	1	1995-01-01	\N	f	faelzinhowkp@gmail.com	t
4641	Mateus Rocha Rodrigues	mateus-r.r@hotmail.com	Mateus	@		2440560cecff67cb8e2ece474965993b	f	\N	2012-12-05 16:57:21.81665	1	1995-01-01	\N	f	mateus-r.r@hotmail.com	t
5013	ANA DARLING MARTINS DA SILVA	anadarlingmartins@hotmail.com	ANA DARLLING	@		7fe560cdb2a8ca9f2e1e187cbcae07db	f	\N	2012-12-06 16:27:34.820881	2	1988-01-01	\N	f		t
4644	Ana Carla	anacarlasousa64@hotmail.com	AnaCarla	@		b301418563e27c31e6d3a171d2011f14	f	\N	2012-12-05 17:08:08.439063	2	1996-01-01	\N	f	aninha--20@hotmail.com	t
4751	Nathan Bezerra	rebosteiro@hotmail.com	Nathan	@		539bf9cbc81a95ab7da39b6341cd1338	f	\N	2012-12-05 22:39:46.963943	1	1995-01-01	\N	f	nathan.2612@hotmail.com	t
4645	alinne santos epifanio	alinne.santos.epifanio@hgmail.com	alinne	@		183c0f85d4359d89d060d8a59715d189	f	\N	2012-12-05 17:09:18.043636	2	1985-01-01	\N	f		t
4646	samuel	samuel.rodrigues1995@gmail.com	rodrigues	@		80f7053718bb82c27c6ff41b94d9eb76	f	\N	2012-12-05 17:12:38.131481	1	1995-01-01	\N	f	samuel.seliga@hotmail.com	t
4647	Bruno Silva	brunnosiilva0717@gmail.com	Silvaa	@		f52e5eadd4242c261fc41d6c40ca9bce	f	\N	2012-12-05 17:13:05.127026	1	1994-01-01	\N	f	brunokeiroz_@hotmail.com	t
4769	tiago angelo	tiagoangelrock@hotmail.com	angelo	@		cfb5302488740de1078ec3b9e1259826	f	\N	2012-12-06 00:30:30.729275	1	1988-01-01	\N	f	tiagoangelrock@hotmail.com	t
4648	karine oliveira de lima	karinneoliveiradelima@gmail.com	kakazinha!	@		ec7f0b86189ba0e030fd0f6f4578fa2c	f	\N	2012-12-05 17:13:36.339001	2	1994-01-01	\N	f		t
4649	Camila	alimac.cbc@gmail.com	Camylla	@		d34fb09700e6f54fc9bfc05b54cdfd44	f	\N	2012-12-05 17:13:46.333863	2	1990-01-01	\N	f	alimac.cbc@gmail.com	t
4786	João Paulo de Sousa Leonardo	joaopaulo_sousaleonardo@hotmail.com	João Paulo	@		fde901d0407e58b9c9b833080e900aaf	f	\N	2012-12-06 08:31:01.28756	1	1996-01-01	\N	f		t
5131	Leandro Danubio da Silva	leandrodanubio@live.com	Leandro Danubio	@LeandroDanubio	http://www.g7noticias.com/	b4b46c6bfc44a2cda5820660dae37c52	f	\N	2012-12-06 21:33:58.676721	1	1990-01-01	\N	f	leandrodanubio@hotmail.com	t
4802	Rafael de Sousa Damasceno	rafaelsd14@yahoo.com.br	Rafael	@		613ae61ee87c087563d0129263a341e6	f	\N	2012-12-06 08:44:06.370953	1	1996-01-01	\N	f		t
5081	rafael viana de sousa mendes	rafaelmendesviana@gmail.com	rafael	@		08149598ac1dec6ad72f215c272d1eaf	f	\N	2012-12-06 20:01:20.70224	1	1992-01-01	\N	f	rafaelmendesviana@gmail.com	t
4630	Amanda Lima Cardoso	amandinha_lc@hotmail.com	MissyMandy	@MissyMandyLC		b660d117f45e3c2da4795ac40fcf290b	f	\N	2012-12-05 16:19:24.064404	2	1991-01-01	\N	f	amandinha_lc@hotmail.com	t
4657	Jamile da Silva Freitas	jamile1603@hotmail.com	mile16	@		86baebe11ee20a6f3dc5563b3f763286	f	\N	2012-12-05 17:33:15.506332	2	1992-01-01	\N	f	jamile.freitas.79@facebook.com	t
4834	RENATO GOMES DA SILVA FILHO	renato2gomes@hotmail.com	renato	@		9a64d04a9e049119c7a155efc6f8cd8c	f	\N	2012-12-06 09:50:55.377743	1	1997-01-01	\N	f		t
2616	nario rafael claudino dos santos	nario_faizu@yahoo.com.br	\\\\The PRIMOGENITO//	@		cfe2071d4fb24b164f16fa48d9ffa7eb	f	\N	2011-11-25 19:54:14.444827	1	1992-01-01	\N	f		t
4848	CLAUBER CUNHA DE LIMA	claubercunha@bol.com.br	clauber	@		8d6a2cd80136f22d130868b3de035301	f	\N	2012-12-06 09:57:00.06644	1	1978-01-01	\N	f		t
4861	Antônio Renan de Araújo Belarmino	renanbelarmino11@hotmail.com	Rennan	@		f3306f6eab6d248f766684257711388a	f	\N	2012-12-06 10:14:23.243836	1	1996-01-01	\N	f		t
5184	Airton Filho Nascimento da Costa	airtonflh@gmail.com	Airton Filho	@		3d82650adec2627f584cca6002631d60	f	\N	2012-12-07 09:40:26.060538	1	1993-01-01	\N	f		t
4873	Alyson Lima	alyson.limasales@gmail.com	Alyson	@fran_alyson		839c2fa9c919fba65d0ce7e9fe9c4b17	f	\N	2012-12-06 11:02:44.502203	1	1993-01-01	\N	f	alyson.2008@hotmail.com	t
5346	juliana maia dos santos	juliamaia7@gmail.com	juliana	@		3ee7beef48af093769e5bffaa6d69aa6	f	\N	2012-12-07 21:49:01.345995	2	1986-01-01	\N	f		t
5207	Walesca Alves Mendes	walescaejovem@gmail.com	Walesca	@		d088e8882c089462e347c75fc2668366	f	\N	2012-12-07 10:40:47.611034	2	1997-01-01	\N	f	leska82@hotmail.com	t
1000	Jéssica Brito da Silva	jessica16jordison@hotmail.com	Jéh Jordison	@jjordison_01		415b9eb965d2d981afdb168eedb154f3	t	2012-12-07 11:54:31.27573	2011-11-18 14:14:48.538447	2	1991-01-01	\N	f	jessica16jordison@hotmail.com	t
5385	MATEUS MONTEIRO FERNANDES	mateuzinhosak@gmail.com	MATEUS	@		c41245d86bd934958d5bf0ab52920b14	f	\N	2012-12-08 10:19:18.523301	1	1996-01-01	\N	f		t
5414	Francisco Djeimerson Sousa Mota	Djeymerson@hotmail.com	Djeymerson	@		7755d3cc31543e71b0eba14f1e81166f	f	\N	2012-12-08 11:01:50.489133	0	2011-01-01	\N	f		t
5436	Egon Tiago Barbosa de Castro	egontiago@hotmail.com	Tiago1	@		456ae4109a8716ef1256f6620da4d3d9	f	\N	2012-12-08 14:29:01.516063	1	1987-01-01	\N	f		t
753	Miquéias Amaro Evangelista	miqueiasinformatica@gmail.com	Miquéias Amaro	@miqueiasamaro		200820e3227815ed1756a6b531e7e0d2	t	2012-12-05 17:48:08.330886	2011-11-11 17:28:54.527884	1	1994-01-01	\N	f	iceblaze2010@hotmail.com	t
319	Halina Alves de Amorim	hallina_taua@hotmail.com	nininha	@		c73267bc5c198a42ee7fe8d447f6b583	t	2012-12-05 17:51:47.627683	2011-10-14 20:15:33.255429	2	1989-01-01	\N	f	hallina_taua@hotmail.com	t
4658	Jefferson Sousa Alencar	jefferson_al_alencar@hotmail.com	J.Alencar	@		bdfb7792568f18d928bffe1c578599ee	f	\N	2012-12-05 18:01:27.598638	1	1994-01-01	\N	f	jefferson.so.alencar@gmail.com	t
4728	PATRICIA OLIVEIRA SANTOS	PATRICIA.O.SANTTOS@GMAIL.COM	PATRICIA	@		ff248973a246d5fd8d8b03d9e5474abe	f	\N	2012-12-05 21:35:47.866177	2	1994-01-01	\N	f	PATTY_SANTOSGT@HOTMAIL.COM	t
4659	Geciliane Araújo de Lima	gecy.g2010@hotmail.com	Geciliane	@		cf8d33ef7bf7135ddf4bea42f7e19df5	f	\N	2012-12-05 18:30:40.219304	2	1996-01-01	\N	f	geciliane2011@hotmail.com	t
4660	Antônio Gleiciano Vieira de Lima	gleicianovieira@gmail.com	itachi-san	@		e9464fec158f4d887f7bc025312a600a	f	\N	2012-12-05 18:38:04.370304	1	1985-01-01	\N	f	antoniogleiciano@hotmail.com	t
4752	Amanda	anderson_aasa@yahoo.com.br	Amanda	@		3874ec7ceb6b68f902b35005ef8ba354	f	\N	2012-12-05 22:39:48.561247	2	1996-01-01	\N	f		t
5054	Claudemir Sampaio	sampaiodias1988@hotmail.com	Claudemir	@		a49fd8600fdbf64847183b3f4f0654b2	f	\N	2012-12-06 19:15:56.179856	1	1988-01-01	\N	f		t
5082	Antenúsia Alves Ferreira	antenusia_gatinha@hotmail.com	Nuzinha	@niquinhabraga	http://www.tumblr.com/dashboard	209f1610f7021ef80f40cafdd65fc351	f	\N	2012-12-06 20:05:46.118668	2	1998-01-01	\N	f	antenusia_gatinha@hotmail.com	t
4803	alex bruno torres martins	alex88btm@hotmail.com	亞歷克斯	@		1c71b02f8dfd8907aeddfcdf3b8da0a0	f	\N	2012-12-06 08:44:17.107026	1	1996-01-01	\N	f	alex88btm@hotmail.com	t
5132	Davi Pereira dos Santos	xdavipereira@gmail.com	Davi ~*	@		a967aff75de3671d89eccdd7fc0c8a03	f	\N	2012-12-06 21:34:43.835898	1	1994-01-01	\N	f	uchihadavi15@hotmail.com	t
4820	diego taylan   delima oliveira	diego.taylan.duda@hotmail.com	Dieguinho	@		9fea168b456476657ab5df6b4deca14a	f	\N	2012-12-06 09:14:46.045875	1	1997-01-01	\N	f	diego.taylan.duda@hotmail.com	t
4673	Eriverton	erivertonrs@gmail.com	Eriverton	@		7f7b770187be204b4356d81f3e528076	f	\N	2012-12-05 18:45:47.435504	1	1990-01-01	\N	f	erivertonrs@hotmail.com	t
4835	ANTONIO FELIPE ALVES GUIA	felipealves05@yahoo.com.br	felipe alves	@		9e621b7aee6a216fa3dbe1f3c3c9ed20	f	\N	2012-12-06 09:51:18.748698	1	1995-01-01	\N	f		t
5347	natalia de oliveira 	natylianara@gmail.com	natylianara	@		1643e3b4fb2f657c483136f2d89ddbc2	f	\N	2012-12-07 21:49:09.273727	2	1993-01-01	\N	f	natylianara@hotmail.com.br	t
5158	Eltemir Anselmo	u_nemesis@hotmail.com	Segredo	@		7cfab48a82704e0405d39e2696f380e6	f	\N	2012-12-07 00:43:11.812975	1	1989-01-01	\N	f		t
4675	Renato Almeida do Nascimento	renatomengo10@hotmail.com	renato	@renato_vh		09bc75b6e31c193fba673bba8e99a398	f	\N	2012-12-05 18:52:23.109624	1	1996-01-01	\N	f	renatoalmeida096@hotmail.com	t
4862	Kaio Heide Sampaio Nobrega	kaio.heide18@gmail.com	KAIO HEIDE	@		111d095b8e9c726eeb3e5c7368e2db80	f	\N	2012-12-06 10:15:55.903983	0	1993-01-01	\N	f		t
4672	felype sales barbosa 	felypesales2010@hotmail.com	Felipe	@		890b9046afbacaec6026627b43c9438f	f	\N	2012-12-05 18:45:37.489844	1	1995-01-01	\N	f		t
4874	gerson duarte de melo	duartegerson.duarte@gmail.com	 não tenho apelido	@		8f2f83aec7b90915bffb90fd0e284039	f	\N	2012-12-06 11:03:27.588327	1	1981-01-01	\N	f		t
4674	Julio rodrigues	rodriguesjulio84@gmail.com	Julio rodrigues	@		e17f0f0621365185612b1494f541a534	f	\N	2012-12-05 18:48:05.955019	1	1997-01-01	\N	f		t
4896	mllena kettre braga 	millenakettre@hotmail.com	millena	@		c1d691a0a7ad6d7567d35b87eb6887e2	f	\N	2012-12-06 11:50:30.044532	2	1997-01-01	\N	f	millenakettre@hotmail.com	t
4905	Anderson Gabriel Leite Da silva	nego12345@live.com	andersson	@		811d53bce82f740c498225c074dacd17	f	\N	2012-12-06 12:01:56.626275	1	1999-01-01	\N	f		t
5185	Maria Gonçalves Cavalcante de Oliveira	marialourdesgoncalves21@gmail.com	Lourdes	@	http://www.facebook.com/mariagoncalveslourdes.cavalcante	56e6990a717dc519b64a0e4d11cafa49	f	\N	2012-12-07 09:47:39.02395	2	2011-01-01	\N	f	mariagoncalves79@hotmail.com	t
4912	Clara Virginia Trindade Pereira	clarinhamorissette@hotmail.com	royalpain	@		aab65ed7ed67092742bd66e94a77193b	f	\N	2012-12-06 12:02:52.426259	2	1996-01-01	\N	f	clarinhamorissette@hotmail.com	t
5386	antônio Jeová de Araujo Souza	jeova.msn@hotmail.com	jheataraujo	@		67b0a581c9d36763fc0de699f520abe2	f	\N	2012-12-08 10:21:00.666805	1	1984-01-01	\N	f	jeovasojhe@hotmail.com	t
5208	Luana Vera Paixão Silva	luana_ibr@hotmail.com	Luana Paixão	@		876beed78f1629ee1245e7f54406f6d1	f	\N	2012-12-07 10:42:02.986003	2	1996-01-01	\N	f		t
5415	José Valmir Moreira Menezes Júnior	bobjuniordk@hotmail.com	Valmir	@		500a0a5747ab63c3cf25b6e4a71ac6aa	f	\N	2012-12-08 11:03:17.923537	1	1993-01-01	\N	f		t
5270	SOLANGE MARIA RODRIGUES	solangerodrigues64@gmail.com	SOLANGE	@		56820ecc0f07d2b7e4d72be2f4f0c331	f	\N	2012-12-07 14:02:29.357222	2	1964-01-01	\N	f		t
5288	ESTERNILANE DA SILVA DE ASSIS	esternilanesliva@hotmail.com	ESTERNILANE	@		066b08f6aa529a88314f888c7d8b0922	f	\N	2012-12-07 14:11:44.721442	2	1984-01-01	\N	f		t
5437	José Raimundo Araújo Neto	araujo.neto@live.com	Netinho	@		5320ddd293d5957d2da42f7491cf0dff	f	\N	2012-12-08 14:34:17.234515	1	1992-01-01	\N	f		t
4679	leonardo de lima peixoto	leo.pctec@gmail.com	leo.pctec	@		e3c623156e618ace5af61ee1e1d8c95d	f	\N	2012-12-05 19:04:28.38177	1	1993-01-01	\N	f		t
4465	Ricardo	ricardodavid1325@hotmail.com	Ricardo	@		abc3a6adcdb4de5cbe123cddcee4d038	f	\N	2012-12-05 09:29:36.289594	1	1996-01-01	\N	f	camararicardo10@yahoo.com.br	t
4729	Carlos Daniel de Lima Nogueira	carlosdaniellimanogueira@gmail.com	carlos	@carlosdao95		ab2fc8b6bdd47c0e1d10bbe355a8217b	f	\N	2012-12-05 21:35:48.95954	1	1995-01-01	\N	f	carlosdaniel.dc@hotmail.com	t
4753	Hildernando dos Santos Costa	hilderdam@yahoo.com.br	Hilder	@		cd174d775566d2cd7802118fdfcf3c79	f	\N	2012-12-05 22:45:20.283672	1	1997-01-01	\N	f	hilderdam@yahoo.com.br	t
4685	Keliane Rocha	kelianercocha27@gmail.com	Keilly	@		93b7d7ef19c686e0f33f9f0db6e55943	f	\N	2012-12-05 19:31:00.02603	2	1990-01-01	\N	f		t
4686	Carlos Henrique Andrade Silva	chaderr@hotmail.com.br	Chasss	@		33a9e759184dc16b376999d3c0099abd	f	\N	2012-12-05 19:31:22.577185	1	1995-01-01	\N	f		t
5055	Alexsandro dos Santos	whiti_philips@hotmail.com	Alexsandro	@		a25e78254051a2eabe350bbea30fafae	f	\N	2012-12-06 19:17:36.048506	1	1989-01-01	\N	f		t
5133	Danilo Alves da Silva	daniloalves526@gmail.com	Danilo	@		ac1834c58f226236742934008479375a	f	\N	2012-12-06 21:37:29.893524	1	1995-01-01	\N	f		t
4687	Jefferson Cruz Alves	jefferson.stylo@hotmail.com	jefferson	@		ccf4f399b9643cc56740cbb1854e629f	f	\N	2012-12-05 19:34:00.591491	1	1995-01-01	\N	f	gt_jefferson@hotmail.com	t
4689	Maria Angelica Ferreira Pontes	angelikapf@hotmail.com	Angelica	@		1519adf7d121b86357abf3a7c25b22d1	f	\N	2012-12-05 19:35:34.181519	2	1996-01-01	\N	f	angelikapf@hotmail.com	t
4804	Samuel Elias Andrade Gomes	samuell_elias@hotmail.com	Samuel	@		31b7e3ab759c6e8c02a8c89dffb8198a	f	\N	2012-12-06 08:44:58.246698	1	1996-01-01	\N	f		t
4690	Kelvin Roger	krallessa@gmail.com	Kelvin	@		529fdb5b1d71a7149da79af7de6c5ecc	f	\N	2012-12-05 19:37:57.298074	1	1996-01-01	\N	f	krallessa@gmail.com	t
374	Jonathan	jw.silva2@gmail.com	jhonne	@Jhonewilliam		78842815248300fa6ae79f7776a5080a	t	2012-12-05 19:42:12.033846	2011-10-18 09:14:59.968665	1	1990-01-01	\N	f	jhonn.william@facebook.com	t
4688	JEYMERSON	jeymersonsoares@gmail.com	jeymerson	@		da205281fcbd12ba2c6858621b2bfac9	f	\N	2012-12-05 19:34:37.02297	1	1996-01-01	\N	f	jeymerson_santos@hotmail.com	t
5110	Leticia Queiros de Oliveira	dayaneesiilva@hotmail.com	leticia	@		5069c0ecdf5efa1c851c329e68d647e5	f	\N	2012-12-06 20:12:38.67032	2	1994-01-01	\N	f	dayaneesiilva@hotmail.com	t
5159	Betuel Clarentino da Silva	betuelclarentino@hotmail.com	Betuel	@betosouza2		4489039f850e94c1f7c63f0c90aa89b1	f	\N	2012-12-07 00:47:54.894468	1	1994-01-01	\N	f	betuelclarentino@hotmail.com	t
4692	Anderson de Souza Gabriel Peixoto	ndersonpeixoto1@live.com	Babidi	@		cb126944e27814019aac34ecf1d21d1b	f	\N	2012-12-05 19:47:54.919129	1	1987-01-01	\N	f	gabriel.neon1@hotmail.com	t
4684	Luciana Gomes de Andrade	luciana.gomes.a@gmail.com	l     	@		e79be9d750b820a767088c56c646b4b6	f	\N	2012-12-05 19:30:10.594762	2	1994-01-01	\N	f		t
5271	MARIANA OLIVEIRA DO AMARANTE	mariianaamarante@gmail.com	MARIANA  AMARANTE	@		12819006268413e2902a1d66d29971cd	f	\N	2012-12-07 14:02:40.498676	2	1994-01-01	\N	f		t
4693	ELIADE MOREIRA DA SILVA	ELIIADEBOL@GMAL.COM	PADAWAN	@		48c1919ace13269af0ee2838f81ed9d3	f	\N	2012-12-05 19:51:37.896795	1	1986-01-01	\N	f	ELIADEBOL@GMAIL.COM	t
5186	JOsé Ribamar Rocha 	rochajose436@yahoo.com.br	Zézinho	@		60e3ae8ea8e37bc2afbbeb7cef4020ad	f	\N	2012-12-07 09:53:10.006558	1	2001-01-01	\N	f		t
5348	Francisco Ari Josino Junior	ririari@gmail.com	ririari	@ririari		a9046f1e738911987e3ae3c84b0f4b1f	f	\N	2012-12-07 22:02:32.430003	1	1990-01-01	\N	f	arijr@outlook.com	t
4850	BRENDA NUNES BEZERRA	brendanunesbezerra@yahoo.com.br	brenda nunes	@		b54d9dee26557ccb04a179665a65eb4f	f	\N	2012-12-06 09:59:33.518875	2	1996-01-01	\N	f		t
5209	josé Alan Bezerra Bomfim	josealan007@gmail.com	Alan Bezerra	@		eaebfa8db04b481b7c40eabe1ebf5058	f	\N	2012-12-07 10:43:19.396911	1	1996-01-01	\N	f		t
4863	Priscila França	mariadosprazeres.feitosa@gmail.com	priscilafranca	@		e6f7c16fed03a6337af60a80d4a0766a	f	\N	2012-12-06 10:16:57.878821	2	1992-01-01	\N	f		t
1602	VALRENICE NASCIMENTO DA COSTA	valrenice@yahoo.com.br	Maria Costa	@		3e457d35659cf4935e29d0ed25ae10bf	f	\N	2011-11-22 19:09:45.980141	2	2011-01-01	\N	f		t
4886	Pedro Vitor Lira Araujo	vitorlira@gmail.com	obamas	@		6ff2601285a5e09c1864561d866faf22	f	\N	2012-12-06 11:41:23.649211	1	1993-01-01	\N	f	pedovitorliraaraujo@hotmail.com	t
4897	ISAAC PEREIRA BATISTA	isaac.knd@gmail.com	Isaac Pereira	@		b7fe3f5561e1cd1b151393859c39ddd7	f	\N	2012-12-06 11:53:32.662003	1	1994-01-01	\N	f	isaacpereirabatista@bol.com.br	t
5231	NATALIA XAVIER DE OLIVEIRA	nataliaxavier0@gmail.com	NATALIA	@		05fbad29c05c933b24d5e4f1079e2d0a	f	\N	2012-12-07 10:57:02.724293	2	1995-01-01	\N	f		t
5252	Robson Rodrigues de Oliveira	robsonoliveira.r@gmai.com	Robson	@		9e80689a5f8d20199625dd185da885b3	f	\N	2012-12-07 11:56:49.043543	1	1992-01-01	\N	f		t
5387	RENATA RODRIGUES BEZERRA	renatinha_f.e.l.i.z@hotmail.com	RENATA	@		4357c8469b9cb7c6e4bbf29d1767a3f7	f	\N	2012-12-08 10:21:37.668281	2	1995-01-01	\N	f		t
5289	MARIA ZENILDA DE BRITO OLIVEIRA	zenilfa@hotmail.com	ZENILDA	@		364d126d5a39c866d8abac6ec96ef57b	f	\N	2012-12-07 14:13:19.346435	2	1978-01-01	\N	f		t
5416	José Linderberg de Andrade Manezes	Lindemberg12andrade@hotmail.com	Andrade	@		0a5b929c1cb44675335f986e6c5656e2	f	\N	2012-12-08 11:05:11.086934	0	2011-01-01	\N	f		t
5438	Christiano Machado da COsta	christianomachado10@gmail.com	Chriss	@		b4637d975fd51d8e29310b38f6acbd33	f	\N	2012-12-08 14:36:28.062255	1	1997-01-01	\N	f		t
4700	Flávio Tavares Possidônio Júnior	j.mengo@hotmail.com	.......	@		2a290c9f59c338e1aa8d79e6f6899a7c	f	\N	2012-12-05 20:00:47.655088	1	1996-01-01	\N	f	j.mengo@hotmail.com	t
4696	Marina dos Santos Lima	marynnalima023@gmail.com	Marina 	@		a497dbfc24c47278cbc4a915d8917ab3	f	\N	2012-12-05 19:56:41.755933	2	1994-01-01	\N	f		t
4697	Lucas Cruz Soares	lucas.cruz023@gmail.com	Lucas Cruz	@		95e70f4b35ff34b398d5a5dd65263117	f	\N	2012-12-05 19:57:47.213798	1	1991-01-01	\N	f		t
4730	Brena Mouzinho dos Santos	brenamouzinho.s@gmail.com	Mouzinho	@		83ea17880838dbab0d11a6452ba1a5ce	f	\N	2012-12-05 21:35:52.428615	2	1994-01-01	\N	f	Brena_mouzinho@hotmail.com	t
5016	Kalebe Hebrom	kalebehebrom@hotmail.com	Kalebe	@		43424a33ec3a41d2777c2a3e5ad09965	f	\N	2012-12-06 16:28:47.812328	1	1996-01-01	\N	f	kalebehebrom@hotmail.com	t
4698	André William Marinho Fama	andrewilliammarinhofama@gmail.com	André William	@marinhofama		9e6c0a1fb06733cd51d05e5bbd13d40b	f	\N	2012-12-05 19:59:30.090868	1	1994-01-01	\N	f	andrewillian_@hotmail.com	t
4694	Gabriel Moreira do Amaral Souza	gabrielmdoas@yahoo.com.br	✝Akuma✝	@		e8653ab13f3c8c3c4734e723d5699bab	f	\N	2012-12-05 19:52:14.567218	1	1996-01-01	\N	f	gabrielmdoas@yahoo.com.br	t
4699	Isabel Frota	isabel-frota@hotmail.com	Isabel	@		6ce4f5136f6a880f5594fab8cef5c1dd	f	\N	2012-12-05 19:59:53.301253	2	1997-01-01	\N	f	isabel-frota@hotmail.com	t
4754	Amanda de Sousa Matos	lyza.guynever@gmail.com	Amanda	@		332b2a98448d2359105381865ea0b1a7	f	\N	2012-12-05 22:47:25.674003	2	1996-01-01	\N	f		t
4701	Daniel Anderson	danielandersondasilva@gmail.com	Daniel	@		010279c4b2ac9791f55a0bf4622bd684	f	\N	2012-12-05 20:03:36.455094	1	1993-01-01	\N	f		t
4702	Álvaro David Marinho Fama	davidmarinhofama@gmail.com	D@vid 	@Alvarolavigne		870b04fa3fd3cb91ece48de3755209e2	f	\N	2012-12-05 20:04:53.370498	1	1992-01-01	\N	f	deidara_david@hotmail.com	t
5304	TIAGO DOS SANTOS ALVES	tiago01alves@hotmail.com	TIAGO ALVES	@		d45e96b71c6d4e562f4645040f56fcea	f	\N	2012-12-07 15:17:29.841184	1	1990-01-01	\N	f		t
4703	FERNANDO FABIO DE SOUZA FILHO	fernandofabiofilho@bol.com.br	Scout69	@		26c3a7c86d947804e3326af74a7bd811	f	\N	2012-12-05 20:04:56.859196	1	1977-01-01	\N	f	fernandofabiofilho@bol.com.br	t
5056	JEAN FELIPE SILVA RODRIGUES	accoletivojereissati@gmail.com	Jean Felipe	@		e7776b4ec5bf031102013ca0b6ac0d29	f	\N	2012-12-06 19:21:08.056025	1	1986-01-01	\N	f	jeanparabolico@yahoo.com.br	t
4805	Elisabeth da silva martins	betthsangalo@hotmail.com	beth sangalo	@		7f9913103e60e124a96875a1b14190a0	f	\N	2012-12-06 08:47:15.410485	2	1985-01-01	\N	f	betthsangalo@hotmail.com	t
5134	Carla Eamnuela 	krlla.manu@gmail.com	Carllynha	@		cb94b5a50db0482ac8ba86ad12507578	f	\N	2012-12-06 21:37:38.481262	2	1991-01-01	\N	f	krlla.manu@gmail.com	t
4822	Cleirton Monte	cleirtonm@gmail.com	Cleirton	@		be2f4012c195358eaaef1b0d12ee153e	f	\N	2012-12-06 09:26:25.751676	1	1991-01-01	\N	f	cleirtonm@gmail.com	t
5084	Leticia Queiros de Oliveira	leticiaqueiros@hotmail.com	leticia	@		bee8610f711dfb2ac753ae6f54389b53	f	\N	2012-12-06 20:05:57.195459	2	1998-01-01	\N	f	leticiaqueiros@hotmail.com	t
4851	João Marcos Silva Araújo	joaomarcos.jms@hotmail.com	João Marcos	@		4aed6a587ed68cae6fc5417029cd3560	f	\N	2012-12-06 10:02:30.651407	1	1996-01-01	\N	f		t
4864	Francisco Cleilton da Costa Ferreira	franciscocleiltoncosta@yahoo.com	snobbish	@		cb1a45dbe02b8f8d05b76f06848cf62c	f	\N	2012-12-06 10:25:14.782304	1	1982-01-01	\N	f	sddsurf@hotmail.com	t
5111	Ravel Anderson da Silva Pinheiro	ravelpinheiro@outlook.com	Ravel1994	@RavelAnderson		a632897d610c6549e63f2a3dfc51e67e	f	\N	2012-12-06 20:14:49.220038	1	1994-01-01	\N	f	ravelanderson@facebook.com	t
4875	ANTONIO SANTOS BORGES FILHO	a.filho4444@gmail.com	Ant Filho	@		6ea5a04d80285ad9076cb75dd90c726b	f	\N	2012-12-06 11:04:24.43691	1	1993-01-01	\N	f		t
5160	Lucas Alves Pereira	llucas-vab@hotmail.com	Luquinhas	@		f8a4ce17c7c9b3491ec49f0290687fa4	f	\N	2012-12-07 01:01:00.223298	1	1994-01-01	\N	f	llucas-vab@hotmail.com	t
4887	Bruno Nobre de Lima	analistanobre@gmail.com	brunonobre	@		df3784a0a499efe5e25e16c4d1c40d13	f	\N	2012-12-06 11:41:31.362778	0	1986-01-01	\N	f		t
4898	cinthia maria silva oliveira	cinthiasurfistinha@hotmail.com	fofinha	@		470ce6f6601e44b64ee2534dc4d52d40	f	\N	2012-12-06 11:55:58.215852	2	1997-01-01	\N	f	cinthiasurfistinha@hotmail.com	t
5187	MARCOS ROBERTO DOS SANTOS PONANZINI	marcos@ecoletas.com.br	MARCOS ROBERTO	@		96e322b718b0c7aced74c60b45a0d4dd	f	\N	2012-12-07 10:14:26.597133	1	1969-01-01	\N	f		t
5349	Gisele Pereira dos Santos	gijeleps@gmail.com	Gisele	@		7fac8ddac708934f33cd8339a4092238	f	\N	2012-12-07 22:04:10.394686	2	1989-01-01	\N	f		t
5210	Antonia Derlania Amaral da Silva	derlaniaejovem@gmail.com	Laninha	@		b9ff1cf33136b348bd68598d2d594bb0	f	\N	2012-12-07 10:43:29.553641	2	1995-01-01	\N	f		t
5232	Ana Lucia dos Sntos Alves	aninhaluz1998@hotmail.com	aninha	@		f000722e9e338b936efcb23d18255879	f	\N	2012-12-07 10:58:39.745689	2	1998-01-01	\N	f		t
5388	Italo de Jesus Costa	ItaloJcosta@hotmail.com	Jesus  1	@		b933da51febee5248587279a09a2567a	f	\N	2012-12-08 10:23:20.358795	0	2011-01-01	\N	f		t
5272	Alessandra Monteiro	lelemonteiro@hotmail.com	Lele Monteiro	@		4a129556c2ddce14c00c084a8e740aab	f	\N	2012-12-07 14:02:53.470833	2	1997-01-01	\N	f		t
1152	ALDISIO GONÇALVES MEDEIROS	aldisiog@gmail.com	AldisioGM	@		32927a24aa78cce12276f42298585293	t	2012-12-08 11:06:06.462503	2011-11-21 17:45:37.098164	1	1992-01-01	\N	f		t
5315	Dauda Cande	cande.dauda@hotmail.com	Dauda1	@		19143ece1b72d89c511c407cf436cddd	f	\N	2012-12-07 16:46:00.188466	1	1988-01-01	\N	f		t
5439	Francisco Elison Rabelo Moreira	elissonp2k@hotmail.com	Elison	@		5c38d3d42bf89c252b43b9ec913fafa9	f	\N	2012-12-08 14:53:50.559639	1	1992-01-01	\N	f		t
5017	WESLLEY SOARES PEREIRA	weslleysoares@gmail.com	WESLLEY	@		e477180027edde171b5bed04bb128ee4	f	\N	2012-12-06 16:29:07.130578	1	1993-01-01	\N	f		t
4105	JOSE LUCAS DA SILVA XAVIER	lucasxavier1934@hotmail.com	lucass	@		a42458a9c5b661d49d1e0e81f345ee2e	f	\N	2012-11-30 15:05:40.923603	1	1995-01-01	\N	f	lucasxavier1934@hotmail.com	t
4929	thainara	tainarabrandao2@gmail.com	tainabra	@		43739f005261fda78c1ec5a39ec45b24	f	\N	2012-12-06 12:19:36.871599	2	1996-01-01	\N	f	tainaraejw@hotmail.com	t
4930	Francisco Antonio Gomes Soares	tchescoezyzyl@gmail.com	tchesco	@		b81156842d525a5c4bc8a871f7664acf	f	\N	2012-12-06 12:19:45.454059	1	1992-01-01	\N	f	franciscorubronegro@hotmail.com	t
4917	Francisco Ericles simeão da silva	f.ericles@hotmail.com	montanha	@		b0b9ea9b29da1033a56bd1d8330fd69e	f	\N	2012-12-06 12:05:21.571324	1	1995-01-01	\N	f	f.ericles@hotmail.com	t
5057	Antonio Fernando da Silva	fernandosilva2.0@hotmail.com	Fernando	@		df7e55bbc0d0be7c892e1b0ce8754076	f	\N	2012-12-06 19:22:13.924507	1	1978-01-01	\N	f		t
4821	CARLOS ANTONIO VITORIANO DE FREITAS	carlosafreitas_10@hotmail.com	CARLINHOS	@		1f4f84aab2ed159acddd763582d4f413	f	\N	2012-12-06 09:23:14.786724	1	1985-01-01	\N	f	carlosafreitas_10@hotmail.com	t
5112	Francisco Dian de Oliveira	dianferreira2013@gmail.com	Dias1313	@		e41d4aaa7a177367deca99fc73b3b6dd	f	\N	2012-12-06 20:16:34.523859	0	1995-01-01	\N	f		t
4932	 Antonio Marcos Araraujo Gomes	marcos222gomes@gmail.com	 Marcos	@		868dc263e845f469f8c967f83683eea6	f	\N	2012-12-06 12:40:16.758328	1	1992-01-01	\N	f	marcos222gomes@gmail.com	t
5135	Francisco Igor do Nascimento Rabelo	igorrabello17@gmail.com	igor rabello	@		13a20d807b025a11caf3db8bbc15545c	f	\N	2012-12-06 21:41:05.803994	1	1994-01-01	\N	f		t
5350	Cristian Lennon Castro Girão	lennonfla_tj@hotmail.com	Kakázinho	@		3d2e4566fcaffcac28bda7fa4fccf2a5	f	\N	2012-12-07 22:18:50.808596	1	1997-01-01	\N	f	lennonfla_tj@hotmail.com	t
5161	alexandre	aleks.oliver@yahoo.com.br	aleksoliver	@		ce554a950ecb807ab32aa80c04e4f469	f	\N	2012-12-07 01:28:01.65093	1	1989-01-01	\N	f	alexandreoliveiradeoliveira@facebook.com	t
5389	JOYCE ELANIA MACIEL PIMENTA	joyyciinhaa@hotmail.com	ELANIA	@		e51a03490066834ebb3881c458c6e885	f	\N	2012-12-08 10:23:33.129014	2	1995-01-01	\N	f		t
5188	vladiana castelo branco saraiva 	vladianacastelo@gmail.com	vladia	@		ea9fef7ce9a10b3846c3f305883e931f	f	\N	2012-12-07 10:19:30.670792	2	1997-01-01	\N	f	vladianacastelo@gmail.com	t
5211	José Aglailton de A da Silva	joseaglailton@gmail.com	Aglailton	@		f072a72b7e5d9004e68ba6eec2baf139	f	\N	2012-12-07 10:45:07.201961	1	1995-01-01	\N	f		t
5417	Ricardo Rebouças dos Santos	tec_ricardo@hotmail.com	Ricardo	@		eb941656503c1676bf8dc7e6243fe163	f	\N	2012-12-08 11:11:34.165471	1	1978-01-01	\N	f		t
5254	Daniel Lopes Nascimento	daniellopesdonascimento@gmail.com	Daniel1	@		09c321d4643cb6b9ea7f86aa8112b594	f	\N	2012-12-07 11:58:20.748427	1	1994-01-01	\N	f		t
5269	Paula Edwiges	paula.edwiges@hotmail.com	Paulinha	@		c8cdc3d11a6ea0c18be3fd4303418595	f	\N	2012-12-07 14:00:40.973472	2	1997-01-01	\N	f	pjmrbd@hotmail.com	t
5291	STENIO FERREIRA NASCIMENTO	steniogordo@hotmail.com	STENIO	@		1015e00cf0f6a46bd4a249daa0a906e9	f	\N	2012-12-07 14:23:44.153101	1	1994-01-01	\N	f		t
5305	Edimar Vieira Machado	edimarvieira001@gmail.com	Edimar	@		920f756f6ae65420d7df474a860ab6b7	f	\N	2012-12-07 15:30:35.391621	1	1995-01-01	\N	f		t
5440	Bruno Gabriel de Oliveira Santos	mayararithelly_mr16@homtail.com	Gabriel	@		535bb3a28158f4ffdf5b759ef5467e9b	f	\N	2012-12-08 15:03:12.968508	1	2001-01-01	\N	f		t
5316	JEFFERSON JAMIE GOMES SOUZA	jamie.gomes.souza@gmail.com	JEFFERSON	@		69f353ac70f78663644f0726d0310362	f	\N	2012-12-07 16:47:04.290929	1	1988-01-01	\N	f		t
5326	Monique Lima Ferreira	moniquelimaferreira@gmail.com	Monique	@		a35934c9849ae5caef53500905ccaf13	f	\N	2012-12-07 17:34:22.184633	2	1986-01-01	\N	f		t
5334	Paula Edwiges	pjmrbd@hotmail.com	Paulinha	@		9db7b77433753aa2aad25011909bc6ef	f	\N	2012-12-07 19:04:13.592071	2	1997-01-01	\N	f	pjmrbd@hotmail.com	t
4933	ADRIANO SOBRINHO DE CARVALHO	adrisobri@ig.com.br	adrisobri	@		d33c5d49846aff0e1700a77454b1e099	f	\N	2012-12-06 12:48:22.99465	1	1981-01-01	\N	f		t
4934	Francisco Italo da Silva Abreu	italoti@hotmail.com	Tohruu	@		78ba74db51d27eedc58a365e934f62bb	f	\N	2012-12-06 13:01:04.80467	1	1992-01-01	\N	f	italoti@hotmail.com	t
5018	Anderson Gomes Siqueira	andinhogomez@gmail.com	Anderson	@		7d6b37cd394c2d71ea10be9470ea27d8	f	\N	2012-12-06 16:29:19.166433	1	1995-01-01	\N	f		t
5058	DANIEL BARROS LEITE DE ARAÚJO	daniel.barros.140@gmail.com	Daniel Barros	@		9ecf599d6daf06e6dd65fa07cb3c3930	f	\N	2012-12-06 19:24:51.787331	1	1990-01-01	\N	f		t
5189	Antonio Felipe Mateus do Nascimento	ant.felipe.mateus@gmail.com	Bonnei	@		e99e175ebad49188585e593e7c3686bd	f	\N	2012-12-07 10:20:26.884289	1	1996-01-01	\N	f		t
5418	Francisco de Assis Souza Alves	tecaltoifce2010marac@gmail.com	Francisco	@		64f2448e5deb3d89b5d373d4f82056f0	f	\N	2012-12-08 11:39:08.979132	1	1974-01-01	\N	f		t
5273	REYNALDO RODRIGO SILVA LOPES	rodrigolopes220@gmail.com	RODRIGO LOPES	@		0fbc987137b6bcb6075c2600f74d5105	f	\N	2012-12-07 14:04:59.201539	1	1996-01-01	\N	f		t
5441	jad oliveira fugueiredo	jad_figueiredo@hotmail.com	jadfigueiredo	@		b71bdf57089a044485777915fbfb66ff	f	\N	2012-12-08 15:04:50.443072	2	1996-01-01	\N	f	jad_figueiredo@hotmail.com	t
5292	Josué gomes dino 	josuejgd@hotmail.com	Josué 	@		f33186c7b0e329940083eb813f49d749	f	\N	2012-12-07 14:28:44.988392	1	1997-01-01	\N	f	josuejgd@hotmail.com	t
5306	PIERRE AUGUSTE RENOIR SOUSA EUFRASIO	ronoir.ti@gmail.com	PIERRE RENOIR	@		b7e645e6b47bf6f1d220cf9f610cb785	f	\N	2012-12-07 15:34:47.40244	1	1978-01-01	\N	f		t
5327	CID NASCIMENTO VASCONCELOS	cid_nascimento@hotmail.com	CID NASCIMENTO	@		f64be4d13fe723498508a37ae41b9ed3	f	\N	2012-12-07 17:37:11.351863	1	1993-01-01	\N	f		t
5335	Alessandra Monteiro 	lele11princess@hotmail.com	lelemonteiro	@		48c496f9b492fe197c759e913eb858e0	f	\N	2012-12-07 19:36:03.779381	2	1997-01-01	\N	f	lele11princess@hotmail.com	t
4935	Israel Nogueira	powxscontato@gmail.com	Israel	@powxs		afeaaef7bad3b1db779f299956dbe7d1	f	\N	2012-12-06 13:03:45.518383	1	1996-01-01	\N	f		t
4936	Wanderson Lopes 	wandersonmetal@gmail.com	Binho Lopes	@_binhocrazy	http://www.facebook.com/binhocrazy	d2be278e22c03f3a8d93d834b670bae6	f	\N	2012-12-06 13:14:27.412106	0	1994-01-01	\N	f	wandersonmetal@gmail.com	t
4937	Niriane Alves	niriane.seliga@gmail.com	Niriane	@		0062a7ac52d0dadb307987aa0c2564bf	f	\N	2012-12-06 13:21:26.364884	2	1992-01-01	\N	f	niriane.seliga@gmail.com	t
5019	Sabrina Silva dos Santos	sabrinasantos040@gmail.com	Sabrina	@		e807f1fcf82d132f9bb018ca6738a19f	f	\N	2012-12-06 16:29:41.787394	2	1995-01-01	\N	f	sabrinaslva290@hotmail.com	t
5059	JHONAMYSTEFANE DA SILVA MARQUES	jhonamyaff@gmail.com	JHONAMYSTEFANE	@		af2393b4e10cc980cc6c8883199224f2	f	\N	2012-12-06 19:32:20.71124	1	1985-01-01	\N	f		t
5190	JAIR CARVALHO FREIRE	jaircarvalho@yahoo.com.br	JAIR CARVALHO	@		36512c6db2ac05a0522db9fe50dae8c9	f	\N	2012-12-07 10:21:24.863174	1	1999-01-01	\N	f		t
5391	Priscila Dayane Paulino de Albuquerque	dayane27-2007@hotmail.com	Priscila	@		61bb94f5f171938a2873587e3845a466	f	\N	2012-12-08 10:24:11.499999	2	1996-01-01	\N	f		t
539	Priscila Luana Bezerra Araújo	priscilaluana.lba@gmail.com	zitrone	@		ec48619bd4403cd2fb887bc9b83e2921	t	2012-12-07 12:01:32.983113	2011-11-04 09:00:38.209587	2	1994-01-01	\N	f	priscilaluana.lba@gmail.com	t
5274	MARIA NATHALIA SOUSA CIPRIANO	nathaliasousa96@gmail.com	NATHALIA	@		77f39039ba7697396b876fb8e4184ed7	f	\N	2012-12-07 14:05:15.24939	2	1996-01-01	\N	f		t
5419	Quézia Araújo Silva	quezia.matematica@hotmail.com	Quézia	@		787ae4a08c4e7a67ca9ee64b0bc83a88	f	\N	2012-12-08 11:46:32.678398	2	1996-01-01	\N	f		t
5293	JUCIARIAS MEDEIROS NASCIMENTO	juciarias@gamil.com	JUCIARIAS	@		3a4a19106fa6fd011e610b8efde30e05	f	\N	2012-12-07 14:29:31.994663	2	1986-01-01	\N	f		t
5307	THIAGO BRUNO PEREIRA DE OLIVEIRA	thiagobruno1355@hotmail.com	THIAGO BRUNO	@		393955f34cf45805e2a95853dd54d40f	f	\N	2012-12-07 15:54:44.658689	1	1997-01-01	\N	f		t
5318	Sara Nascimeto de Araujo	sarahwilliamsstangier@gmail.com	Sara Nascimento	@		aeb533c7105f95fe677fd6ac464a7ed7	f	\N	2012-12-07 16:47:39.15856	2	1996-01-01	\N	f		t
5442	Lara Priscila Gomes Pereira	larapriscila07@hotmai.com	Priscila	@		9c913dfd1f0d5a1c30c08b4a166df27c	f	\N	2012-12-08 15:31:48.577406	2	1995-01-01	\N	f		t
5328	Lucas Neves Lima	lucasneves94@hotmail.com	Lucas Neves	@		7437051d7e5f71230c1a43db5476751d	f	\N	2012-12-07 17:47:22.516349	0	1994-01-01	\N	f		t
5336	Thiago Beviláqua	fthiagobevilaqua@gmail.com	Thiago	@		61cd98574adbb2985f755d673bc34fab	f	\N	2012-12-07 19:45:31.702345	1	1991-01-01	\N	f		t
4940	Valeria Alves	niriane.alves@gmail.com	Valéria	@		c1afdc0c24943d1ae28f2e87348c2de5	f	\N	2012-12-06 13:23:21.829054	2	1997-01-01	\N	f		t
4941	fernando kennedy barroso	fernandokennedy2012@gmail.com	Feerkennedy	@feerkennedy		64a6b3fbc61b6b15ffdd9a90e9f6d79f	f	\N	2012-12-06 13:32:01.42736	1	1994-01-01	\N	f	fernando__kennedy@hotmail.com	t
5020	MARIA EDILEIDE DA SILVA SANTOS	edileidesilvasantos@gmail.com	EDILEIDE	@		eb8864127b0bf5056c0763e98bdad428	f	\N	2012-12-06 16:30:54.650502	2	1991-01-01	\N	f		t
4907	PAULA RITHIELE FERREIRA RODRIGUES	rithielle_hta123@hotmail.com	paula rithiele	@		7879de52f7ddfcf7fd1ee7c7e71ca453	f	\N	2012-12-06 12:02:12.760756	2	1996-01-01	\N	f		t
4388	Paulo Mendonça júnior	paulomendonca13@gmail.com	Paulo Mendonca	@		8ceb3a52173f96b92d6eec6269518c56	f	\N	2012-12-04 13:41:22.416455	1	1964-01-01	\N	f		t
4942	RONNIS PEREIRA	ronnis.seliga@gmail.com	Ronnis Pereira	@		e59ce42ab7ab1a74e5ae6399a0851bdb	f	\N	2012-12-06 13:55:32.557519	1	1990-01-01	\N	f		t
5060	Mykele Alves	mikelyibc@gmail.com	Pithely	@mikelyalves		c750463f342e8078f45af0c9253cb7d2	f	\N	2012-12-06 19:37:01.75313	2	1995-01-01	\N	f	mikely_alves2009@hotmail.com	t
4944	Yohana Almeida	almeida.yohana@gmail.com	Yohana	@		551eda47d66df44d73b52d1f8fc75e07	f	\N	2012-12-06 14:02:47.3398	2	1995-01-01	\N	f	ravena_xispe@hotmail.com	t
5164	Rafael Alans	rafael.alans@gmail.com	rafael	@		42b4e39e6f8678194d441e4aa2b08934	f	\N	2012-12-07 05:12:20.472151	1	1994-01-01	\N	f	rafael.alans@gmail.com	t
4945	Gabriela Rocha Araujo	rocha.gabriela10@yahoo.com	Gabriela	@		50e2bf6b5e5a8468cf40875ac2a06ac1	f	\N	2012-12-06 14:02:57.932037	2	1995-01-01	\N	f		t
5353	José Anchieta de Queiroz Junior	anchieta.junior@gmail.com	Anchieta	@		82f18dedcbbf297cec17a787350d8888	f	\N	2012-12-07 22:32:30.648509	1	1987-01-01	\N	f		t
4946	Cleiton Francelino da Costa	cleiton_costa_@hotmail.com	Cleiton	@		4ee8c287449032410a574f90f888da1e	f	\N	2012-12-06 14:05:31.838672	1	1996-01-01	\N	f		t
5214	antonia Nadia Dos Santos Braga	kacyaline@yahoo.com	nadinha	@		aae136b6a74a40249be187e1d3a92efc	f	\N	2012-12-07 10:46:44.044229	2	1998-01-01	\N	f		t
4949	luiz vitor dos rêis santos	novatoluizvithor@gmail.com	Victhor	@		31b8c84b7f69ce0052cdeba97479d889	f	\N	2012-12-06 14:12:53.575504	1	1996-01-01	\N	f	novatoluizvithor@hotmail.com	t
1722	FRANCISCO OTÁVIO DE MENEZES FILHO	otavio.ce@gmail.com	Otávio	@		0e46f7cc8673afc070965b7d916ee0c2	f	\N	2011-11-23 08:40:10.594814	1	2011-01-01	\N	f		t
564	Thiago Martins Brandao	thiagomartins444@gmail.com	thiago	@		e47d516d344b75724f88ee9bd2892b0a	t	2012-12-07 12:01:46.190278	2011-11-04 09:12:13.389433	1	1994-01-01	\N	f	thiago-santos-martins@hotmail.com	t
1789	Lyza Guynever Modesto Nogueira	lyzaguynever@hotmail.com	Lyza Guynever	@LGuynever		f637e96da45842aa6a59579df711d7ea	f	\N	2011-11-23 10:21:48.230991	2	1995-01-01	\N	f	lyza.guynever@gmail.com	t
4950	carlos da silva brito	carlosga102008@hotmail.com	carlinhos	@		6c7c9f18f9032f246f58d1f4a9f661b5	f	\N	2012-12-06 14:16:06.273791	1	1995-01-01	\N	f		t
4951	jeron scwantz	jeronschwatz@gmail.com	jeronschwatz	@		2a3dc53183f511131229cfe6b687d44a	f	\N	2012-12-06 14:18:17.548662	1	1995-01-01	\N	f		t
5392	CRISTIANO SILVA DO NASCIMENTO	cristianoxd02@hotmail.com	CRISTIANO	@		1c0c25c185c433825a38cd645ca6a5d1	f	\N	2012-12-08 10:24:59.968566	1	1995-01-01	\N	f		t
4952	Julia Fernandes	julhinha.f@gmail.com	Julhinha	@		aa96a1744ef9ecc0744d2eeace34218c	f	\N	2012-12-06 14:20:57.834429	2	1998-01-01	\N	f	julhinha.f@gmail.com	t
5275	Barbara Thays Dos Santos Saraiva	barbarathais9@gmail.com	Barbara	@		967349913bcc677189536dca4dd447d3	f	\N	2012-12-07 14:05:41.26235	2	1997-01-01	\N	f		t
4953	Francisco Otávio de Menezes Filho	otavio.ce@hotmail.com	Otavioo	@		3e6ae16c341ea90c5f9596fd996ef085	f	\N	2012-12-06 14:22:04.78097	1	1982-01-01	\N	f		t
5294	Edvania Alice Sousa da Costa	edv12@hotmail.com	Alice1	@		170e1ab9b8abd9992b4ef53cb21e6f0b	f	\N	2012-12-07 14:29:35.610985	2	1996-01-01	\N	f		t
5308	GEORGE VINICIUS DE SOUZA VIANA	gv_nespd@hotmail.com	GEORGE VINICIUS	@		03ff920345f34f33b52bcc5a0019fbaa	f	\N	2012-12-07 15:56:59.725144	1	1998-01-01	\N	f		t
5443	mARCOS GABRIEL SANTOS	gbvesgo@hotmail.com	marcos	@		763c846b6eb9cdba2a2c11af4fa52aac	f	\N	2012-12-08 15:49:57.230227	1	1993-01-01	\N	f		t
5329	Maria Jéssica da Silva	jessica.euamojm@hotmail.com	jéssica	@		a74388eee3182467b262f4d491182a46	f	\N	2012-12-07 18:17:14.38304	2	1996-01-01	\N	f	jessica.euamojm@hotmail.com	t
5021	Raul Silveira Barbosa	raul301@gmail.com	Raul301	@		9aff90b8eb62ff7fb5c12ac8230d4b67	f	\N	2012-12-06 16:36:43.975799	1	1995-01-01	\N	f		t
4960	Silmara Evaristo Carvalho	silmaraevaristo@Hotmail.com	Silmara	@		be6beb3e27fef7f776d9a10346ce5002	f	\N	2012-12-06 14:32:27.380506	2	1992-01-01	\N	f	silmaraevaristo@Hotmail.com	t
3670	Camila Brena Gomes Alves	camila.bga21@gmail.com	Camila BGA	@CamilaBGA		f5ffc847c2072ffb5fda82edd30bc19f	f	\N	2012-11-25 11:51:01.898842	2	1991-01-01	\N	f	camilabrena@hotmail.com	t
5139	Hericson Araújo	play8714@hotmail.com	Hericson	@Hericson_Play		20e7ebc66252143300bf1ff933d92d6b	f	\N	2012-12-06 21:56:58.298571	1	1991-01-01	\N	f	play8714@hotmail.com	t
5165	Kleber	klebervdasilva@hotmail.com	Crucuz	@		a8c9de7ae23cc5765589b134bd6884ae	f	\N	2012-12-07 07:17:35.094721	0	1992-01-01	\N	f	klebervdasilva@hotmail.com	t
4962	Joyce Costa de Sousa	joyce.jerosaia@gmail.com	Joyce Costa	@JoyCSousa		e517eb89633abe6bddae8988f9be1d2d	f	\N	2012-12-06 14:34:33.706272	2	1993-01-01	\N	f	joyce_jerosaia@hotmail.com	t
352	Jonas Bazilio Pereira	jonasbazilio@gmail.com	bazilio	@		db434efb95f5fc257d2de7819988e1e0	t	2012-12-07 10:26:11.329565	2011-10-17 16:38:28.523557	1	1993-01-01	\N	f	jonasbazilio@gmail.com	t
4964	Jeova de Lima Rogrigues	mixely_gat@hotmail.com	jeovadelima	@		6d3662be0ff652fe56e06755667b0aff	f	\N	2012-12-06 14:36:15.150645	1	1994-01-01	\N	f		t
5215	PEDRO RICARDO CARVALHO DE OLIVEIRA	0291121@gmail.com	PEDRO RICARDO	@		26353072316cd21906167a40d543d18f	f	\N	2012-12-07 10:46:51.982183	1	1991-01-01	\N	f		t
5237	antonia Nadia Dos Santos Braga	nadiasantos.ejovem@gmail.com	Nadinha	@		e803d2f6a05d9a50f1cdf9b2d7bb2cc0	f	\N	2012-12-07 11:01:44.635158	2	1998-01-01	\N	f		t
4966	FERNANDO LUIS SOARES BARROS	ft.com.br@gmail.com	GEERTZ	@		9a27ff13bbdaf05da360a10c33144366	f	\N	2012-12-06 14:38:31.55339	0	1991-01-01	\N	f	ft.com.br@gmail.com	t
5393	Heverson Fernandes Clemente	Heverson1995@gmail.com	Heverson	@		ef7977829e572074ece6b6d1d8be767f	f	\N	2012-12-08 10:25:46.683765	0	2011-01-01	\N	f		t
5256	Maria Lidiane dos Santos	lidianne19@hotmail.com	lidinha	@		756fe209d4b940d9c4c785e74f4b88c8	f	\N	2012-12-07 12:21:14.88696	2	1983-01-01	\N	f		t
4968	francisco ian costa avila	iancostaavila@gmail.com	ian costa	@		e0078e087eafd79671e958fa2c7bec5a	f	\N	2012-12-06 14:39:42.532187	1	1995-01-01	\N	f	iancosta77@yanhoo.com	t
5276	Lucas Pereira Nascimento	lucas.remoum@gmail.com	Luquinhas	@		1defb74a1c8694865bca1e9f36f754b0	f	\N	2012-12-07 14:05:57.521699	1	1995-01-01	\N	f	lucas.remo1@hotmail.com	t
4963	David Alves Dias	davidkilaboy@gmail.com	Jackie Chan	@DavidDias		e04fd9cad256b221ae98d0ced2b3f594	f	\N	2012-12-06 14:34:52.394901	1	2011-01-01	\N	f	david25694@hotmail.com	t
4967	Andressa Ferreira de Araujo	dreeh.milla@gmail.com	Andressa Ferreira	@dreehfkn		aabbc4b8169b8c795d8926cc74a9fc05	f	\N	2012-12-06 14:39:30.446619	2	1995-01-01	\N	f	andressa_1804@hotmail.com	t
5295	Walber Florencio de Almeida	walverfa@gmail.com	Walber	@		e05317c90af02d3508c7efe27a9b2cf0	f	\N	2012-12-07 14:31:26.46891	1	1995-01-01	\N	f		t
5421	Tatiane Ayala	tati.ifce@gmail.com	Taty Ayala	@		12ff6a5418e17e9d9e55f93b0d2fb628	f	\N	2012-12-08 11:48:58.432687	2	1993-01-01	\N	f		t
5309	Celso Brunno Rocha Custódio 	celsobrunno10@hotmail.com	Brunneca	@Celso_Brunno		0dff9a9630df0f08756a68fd1638c060	f	\N	2012-12-07 16:03:17.257195	1	1994-01-01	\N	f	celsobrunno10@hotmail.com	t
5320	Carla Cruz Vasconcelos	carlosdaniel.dc@hotmail.com	Carlinha	@		2204f8aa7b9f894a874240273dcbda5d	f	\N	2012-12-07 17:13:05.980739	2	1996-01-01	\N	f		t
5444	Elionai Sales Mauveira	elionnai@hotmail.com	Elionai	@		0dfe3e1431b8b104f54e1e47c61b5a79	f	\N	2012-12-08 15:51:37.143535	1	1991-01-01	\N	f		t
4971	Hortemila Paiva Castro	milla.dreeh@gmail.com	Milla'	@HortemilaCastro		305b07633a471075c0e83955a8c8d76d	f	\N	2012-12-06 14:43:53.974793	2	1996-01-01	\N	f	milinha_levy@amores.com	t
4972	Jacymara Sousa	jacy.pk@gmail.com	Jacymara	@JacymaraSousa		72d949ca51310eb6a5e2553aabb6f6c9	f	\N	2012-12-06 14:44:21.556996	2	1995-01-01	\N	f	jacymara.girl@hotmail.com	t
5022	Pedro Alberto Moraes Pessoa	pedroalbertomoraes@hotmail.com	Pedro1	@		dc965d3846c34ddda78bf3ecfee3ce83	f	\N	2012-12-06 16:43:37.847221	1	1990-01-01	\N	f		t
4973	Maria do Socorro Carvalho Freire	socorro_fleire.3@hotmail.com	Socorro	@		5333b09a5450e4daf7dbb55dc4dc31d2	f	\N	2012-12-06 14:44:37.619926	2	1984-01-01	\N	f		t
4974	Gabriel Rodrigues Mesquita	gabrimes6@gmail.com	gabriel	@		e96a2b96f8f428ee85febee5e0e0545c	f	\N	2012-12-06 14:45:20.83545	1	1993-01-01	\N	f	gabriel-mesquita100amigos@hotmail.com	t
5062	Raimundo Jobson Catro Barbosa	jobson.castro35@gmail.com	jobson	@		e7cb6b5fab127d4cfc319044a5e56544	f	\N	2012-12-06 19:38:33.432136	1	1995-01-01	\N	f	jobson.castro@hotmail.com	t
5140	Emanuel Domingos	emanuelsdrock@gmail.com	Emanuel Domingos	@		522991a5b6b2c34a2cf87e9b55d70b76	f	\N	2012-12-06 22:23:40.9417	1	1990-01-01	\N	f	emanuelsdrock@gmail.com	t
5394	ANA SANARA DA ROCHA XIMENES	sanararx@hotmail.com	SANARA	@		342193ce6c87785e6b5517b5e03e4b1d	f	\N	2012-12-08 10:26:30.813054	2	1996-01-01	\N	f		t
4978	Samantha Mourão Farias	samantha.mf@gmail.com	Samantha	@		28187bc256dce51764f467e24e6c7b10	f	\N	2012-12-06 14:48:07.611633	2	1988-01-01	\N	f		t
5192	layslandia de souza santos	sousalays7@gmail.com	layslandia]	@		71e9abe26aea881a932b318d951a03c0	f	\N	2012-12-07 10:27:57.826552	2	1995-01-01	\N	f	layslandiasouza16@hotmail.com	t
4979	Uirapora Maia do Carmo	uira@culturalivre.org	Uirááa	@		e055104019fbadfb989780f90c69b9e4	f	\N	2012-12-06 14:49:11.289058	2	1986-01-01	\N	f		t
4980	Damaris Sena Ferreira	ddamaryssenna@hotmail.com	Damaris	@		b91d76fcac74e29524ecd4cc2a120bc2	f	\N	2012-12-06 14:49:19.322298	2	1994-01-01	\N	f		t
4976	Alex Sousa 	patocross800@gmail.com	Alex Sousa 	@alexsousa		648ed389120cd4f50c14277c11ed41d0	f	\N	2012-12-06 14:45:33.212868	1	1995-01-01	\N	f	patocross_@hotmail.com	t
4970	francisca monalisse vaz de oliveira	monalisevaz@gmail.com	alisse	@		667e2142b802e732902f192ac83f7285	f	\N	2012-12-06 14:43:34.160242	2	1994-01-01	\N	f	monalisevaz@gmail.com	t
5216	Ygor Elisson Oliveira Silva	ygorelisson.darkhorse@gmail.com	Ygor Elisson	@		44ac685414d208288b96c14f8ed42e3d	f	\N	2012-12-07 10:47:01.196053	1	1996-01-01	\N	f		t
4977	Paloma	palloma.eufrasio@gmail.com	pallominha	@PalomaEufrasio3		2a2cb5eda88c1274db4164874186fc21	f	\N	2012-12-06 14:45:51.62157	2	1996-01-01	\N	f	palomaeufrasio_8@yahoo.com	t
4982	helton carlos de jesus castro	heltoncarlos77@gmail.com	helton	@		6ed54894f1aba93c99eeb8dffac39d12	f	\N	2012-12-06 14:52:58.580819	1	1986-01-01	\N	f		t
4983	Cirley Venâncio	cirleymendespro@hotmail.com	Cirley	@		3f7eea6718caeb3a564f6b86833b714c	f	\N	2012-12-06 14:53:01.634951	1	1994-01-01	\N	f	cirleymendespro@hotmail.com	t
5422	Natália Dos Santos Lima	n.santos.lima@bol.com.br	Natália	@		937861ccb288247cd4236f3cea3c3cb6	f	\N	2012-12-08 11:49:22.530597	2	1989-01-01	\N	f		t
5257	Gabriel	gabriel_785biel@hotmail.com	Gabriel	@		4eb584c8ccb6c0fcff6ee0e649e3892a	f	\N	2012-12-07 12:28:52.108266	1	1995-01-01	\N	f	gabriel_785biel@hotmail.com	t
4984	Yasmim Gomes Barbosa	yaasmimgb@gmail.com	Yasmim	@YaasmimGs		9c92f1711adc3cb2fdbe649ceef33747	f	\N	2012-12-06 14:54:46.22449	2	1996-01-01	\N	f	yasmim11158@hotmail.com	t
4975	Gelmo Sousa	g.misterb@gmail.com	Omlleg	@GelmoSousa		8b811a84625a8d81001e9aeaf02860cd	f	\N	2012-12-06 14:45:24.194335	1	1994-01-01	\N	f		t
5277	MAISA MARTINS DA SILVA	maisamartins00@gmail.com	MAISA MARTINS	@		bf0e5b144d37d074f8bff1e303994f0b	f	\N	2012-12-07 14:06:35.671914	2	1995-01-01	\N	f		t
5445	Shyena Morais da Costa	shymorais@hotmail.com	Shyena	@		74c946d0636688f6a28b7c504f47e288	f	\N	2012-12-08 16:09:00.562696	2	1990-01-01	\N	f		t
5310	Lorena Oliveira de Lima	lorena.oliverlima@hotmail.com	Loris!	@lorislimaa		b6e57c35c5ff527429972776d3b029c6	f	\N	2012-12-07 16:06:40.91718	2	1996-01-01	\N	f	loo.lima@hotmail.com	t
4985	Elayne da Silva Ferreira	elayne_ferreira@live.com	Elayne	@		997366d3029a103e6a05cb521f0b5b67	f	\N	2012-12-06 14:55:55.946715	2	1995-01-01	\N	f		t
4961	HERIVELTON DOS SANTOS GAMA	heriveltonsantos10@gmail.com	herivelton	@		1a38c7ae0dfd82b996014aaaac35927c	f	\N	2012-12-06 14:33:51.025755	1	1990-01-01	\N	f		t
4986	Isabor Soares Pinheiro	isabor.pinheiro@gmail.com	Isabor	@IsaborSoares		8a6a2f7fe8b2bb97cab208e1f8e6133f	f	\N	2012-12-06 14:58:03.971343	2	1997-01-01	\N	f	isabor.soares@facebook.com	t
415	Bryan Ávila Cavalcante	bryancavalcante@hotmail.com	PeDeChiclete	@		0bd7862a349fa5817592dba6a75d1ac8	t	2012-12-06 14:58:22.003664	2011-10-22 15:37:37.476046	1	1996-01-01	\N	f	bryancavalcante@hotmail.com	t
5023	Bruno Albuquerque dos Santos	bruno_2005_M@hotmail.com	Bruno1	@		82648e67d607e74b246ec22e6ff37530	f	\N	2012-12-06 16:45:57.726415	1	1989-01-01	\N	f		t
4987	Cristian Araujo de Oliveira	cristian.oliveira123@gmail.com	Cristian	@cristian_o11		a0c655e4eceea58cbd30b55c2c21d5e4	f	\N	2012-12-06 14:58:49.3966	1	1993-01-01	\N	f	cristian.oliveira11@gmail.com	t
4969	francisca mayara de sousa mesquita	mayaramesquita2@gmail.com	mayara	@mayara_mesquita		c52b01048daab488765c48dbbfedfb64	f	\N	2012-12-06 14:43:05.974886	2	1992-01-01	\N	f	mayaramesquita2@gmail.com	t
4988	Karem Laryssa Cavalcante de Oliveira	karemlaryssa.22@gmail.com	Karem Laryssa	@KaremKl19	http://www.facebook.com/karem.oliveira.96?ref=tn_tnmn	ed08f58d475738207eb7e281144f31a1	f	\N	2012-12-06 15:01:05.045885	2	1996-01-01	\N	f	kakabestfriend@hotmail.com	t
4989	Edilene de Mesquita Camelo	edilene.pek@gmail.com	Pekena	@EdileneMesquih		897baf6dd926e06c1ffcb20739bae2eb	f	\N	2012-12-06 15:08:02.687303	2	1996-01-01	\N	f	edilene.mesquita@hotmail.com	t
1134	MARIA SIMONE PEREIRA CORDEIRO	simonemanda@hotmail.com	simone	@		40f7bc3df36b0d84e34fbf9c22fa3b9f	t	2012-12-06 15:14:29.555414	2011-11-21 15:17:35.148062	2	1975-01-01	\N	f	simonemanda@hotmail.com	t
5063	Fabio Correia	correiafabio063@gmail.com	fabio correia	@		ef11ece4a7a58ce7476ee32e2e2fc860	f	\N	2012-12-06 19:39:21.742525	1	1995-01-01	\N	f	correiafabio063@gmail.com	t
4990	Catiane Higino	catchrist@gmail.com	catiane	@		e98fc6ccd8c73d3a15576c839141bfb3	f	\N	2012-12-06 15:16:32.095424	2	1986-01-01	\N	f		t
5141	Gabriel Carlos Costa	gabriel.gcc7@gmail.com	Gabriel	@		f025d3c3ed00a1f771039951f609084f	f	\N	2012-12-06 22:33:21.210747	1	1997-01-01	\N	f	gabriel.gcc@hotmil.com	t
4991	Naílton	nailton-hmb@hotmail.com	Naílton	@		b036f344c25e6670f2cf4b9e48995b47	f	\N	2012-12-06 15:17:45.580703	1	1995-01-01	\N	f	nailton-hmb@hotmail.com	t
4992	Ivania Santos	ivaniajf@gmail.com	ivania	@		d5b66e50eaf613096b6a7d1e0d41b9df	f	\N	2012-12-06 15:19:27.900853	2	1994-01-01	\N	f		t
1828	Maria Aparecida	aparecidaferreira639@gmail.com	Cidinha	@		81b971483c874acbd28b109ed046dfed	f	\N	2011-11-23 10:39:39.331447	2	1986-01-01	\N	f	aparecidasouzafds@yahoo.com.br	t
5356	Felipe Stefano Guedes Mesquita	stefano.molko@gmail.com	Stefano	@		1e1b5a401d26941f1906b2ce1149ae94	f	\N	2012-12-08 00:14:22.327338	1	1992-01-01	\N	f	stefano.molko@gmail.com	t
4993	ana lidia de oliveira santiago	lilicamoraes@hotmail.com	Lidiaana	@		07644c61304043c940e7894f15855974	f	\N	2012-12-06 15:29:36.702627	2	1998-01-01	\N	f		t
1009	francisco wanderson	wandinholoves2@gmail.com	chuck norris	@wandinholoves2		e10adc3949ba59abbe56e057f20f883e	f	\N	2011-11-18 16:31:12.171281	1	1994-01-01	\N	f	wandinholoves2@hotmail.com	t
4994	Letícia Lima	sobrenaturaldemas@hotmail.com	Leticia	@Leticialima24		2753ffdaf0b98341f3dd30b13bde7dd6	f	\N	2012-12-06 15:41:16.32439	2	1999-01-01	\N	f	sobrenaturaldemas@hotmail.com	t
4965	Amara Lívia Alves Ferreira	amaraliviaa@gmail.com	Marinha	@amaralivia123	http://www.tumblr.com/dashboard	a5c1ffd77f6ab3f45297ec97ac234b5a	f	\N	2012-12-06 14:37:14.321271	2	1996-01-01	\N	f	amaralivia@gmail.com	t
5311	ANTONIO ARNALDO SANTOS JUNIOR	antonio_arnaldo@hotmail.com	ARNALDO JUNIOR	@		d659b58e9f8e07b04769a8c2d3bc09dc	f	\N	2012-12-07 16:13:44.526068	1	1990-01-01	\N	f	antonio_arnaldo@htimail.com	t
4995	Fernando Junior	juninhofield@gmail.com	Juninhofield	@		89b1d2778469f18f54fa43c8365b3005	f	\N	2012-12-06 15:48:43.281234	1	1992-01-01	\N	f		t
5395	Francimara Gracielle dos Santos Aires	gracielleAires29@gmail.com	Gracy Aires	@		d4809cfa549101d3869394cfcf97a1d2	f	\N	2012-12-08 10:27:33.230576	0	2011-01-01	\N	f		t
5258	Maria Lidiane dos Santos	mouralidianne@gmail.com	lidinha	@		9d1ff4ed7c6d2f715d10df387e3e7807	f	\N	2012-12-07 12:40:23.036092	2	1983-01-01	\N	f		t
5278	LARISSA MARIA FERREIRA O NASCIMENTO	larissamaria544@gmail.com	LARISSA	@		d89e261931ae9f2c22fd49c1a30b5d13	f	\N	2012-12-07 14:06:59.166352	2	1996-01-01	\N	f		t
5423	Camila Raquel Teixeira	camilarft@gmail.com	Camila	@		801b75328f1ae87beef1e6063b4b2c7a	f	\N	2012-12-08 11:50:39.521349	2	1986-01-01	\N	f		t
5446	INARA RIBEIRO MORAIS	inararibeiro@gmail.com	INARA RIBEIRO	@		1af0231bb7acbc018ba9399c3f16e5c9	f	\N	2012-12-08 16:13:48.811709	2	1983-01-01	\N	f		t
4997	Larissa Moura de Araújo	larinha_moura13@hotmail.com	Larissa	@		acdd75e8df5cc6288afa9339651d4eb2	f	\N	2012-12-06 16:08:43.669586	2	1995-01-01	\N	f	larinha_moura13@hotmail.com	t
4996	LIDIA DE SOUSA GOMES	lidia.324@hotmail.com	Lidinha	@		79849684b002ac39e0d959455c9c857e	f	\N	2012-12-06 15:59:39.873093	2	1992-01-01	\N	f	lidia.324@hotmail.com	t
472	Hewerson Alves Freitas	hewerson.freitas@gmail.com	Hewerson	@hewersonfreitas	http://www.falaqueeucodifico.blogspot.com	2221f50a96fa097c2f35097baac14467	t	2012-12-06 22:36:47.535921	2011-11-02 20:24:46.441408	1	1990-01-01	\N	f	h_alvesf@yahoo.com.br	t
4998	ANDERSON ROBSON SANTOS SILVA	anderson_robson@life.com	ANDERSON	@		b31a1a984820ba729e4fc86f948bf54c	f	\N	2012-12-06 16:09:28.983483	1	1996-01-01	\N	f		t
5024	Káthia Janaína	kathiaguimaraes10@gmail.com	Káthia	@		4590b12c49f1f912ad19759acf44de13	f	\N	2012-12-06 16:49:42.271828	2	1992-01-01	\N	f	kathiajanaina@facebook.com	t
5194	Cácia Aline Costa Santos	kacialinecs@gmail.com	Lininha	@Alinnycs	https://sites.google.com/site/avidadeumaestudante/	bcedfdb1a345337ba9f2f01365165f66	f	\N	2012-12-07 10:31:00.682387	2	1996-01-01	\N	f	alynnehcosta@hotmail.com	t
5357	LUIS GEOVANNY SARAIVA BARRETO	geovany.saraiva@gmail.com	Geosaraiva	@		4370bfa1706d6484962b430549f1dac8	f	\N	2012-12-08 02:19:14.356831	1	1993-01-01	\N	f	Geo_v_ny@hotmail.com	t
5240	Regina Pereira da Silva Neta	professora.reginapereira@gmail.com	ReginaPereira	@		58ed8d012110d5ad5e525091a9d5b24e	f	\N	2012-12-07 11:03:26.349495	2	1981-01-01	\N	f		t
5064	denise da silva	denise_fv@hotmail.com	denise	@		9cfa7903d20df2e2b0adb105bd2a1756	f	\N	2012-12-06 19:39:40.426168	2	1993-01-01	\N	f	denise_fv@hotmail.com	t
5259	Giselle Valentim	dinhavalentim10@hotmail.com	Giíh Valentim	@		2971d6d3be27940bba7fc210844d0691	f	\N	2012-12-07 12:40:41.592811	2	1995-01-01	\N	f	gisellevalentim@hotmail.com	t
5396	Antonio Lucas Dos Santos Neris	lucasneris96@gmail.com	Antonio Lucas	@		02817c6df6ed823cbb1d52d22900951e	f	\N	2012-12-08 10:27:50.369648	1	1996-01-01	\N	f		t
5279	DRIELY SALES PESSOA	drielysales0@gmail.com	DRIELY SALES	@		d239b98383ddfe05dbd9ff44561eb2af	f	\N	2012-12-07 14:08:04.678142	2	1995-01-01	\N	f		t
5298	Antonio Matheus Xavier	mateusmorello@live.com	Mateus	@		a6a4f968c8e7789ec519f310bdd5bdc2	f	\N	2012-12-07 14:54:48.385239	1	1995-01-01	\N	f		t
5424	matheus de medeiros barbosa	matheus.cara1995@hotmail.com	matheus	@		f25f5ff41832d45b024b8dc69852da89	f	\N	2012-12-08 12:06:33.138725	1	1995-01-01	\N	f	matheus.cara1995@hotmail.com	t
5323	Alberwanderson Marques	eletrofran.wanderson@gmail.com	plyks®	@		244bed2bbde835a47c77b4f6d082d80c	f	\N	2012-12-07 17:24:52.628188	1	1989-01-01	\N	f	Plyks1@gmail.com	t
5447	RAFAEL SANTOS COSTA	fael_uchiha@hotmail.com	rAFAEL fael	@		56ad270b571b296c0870c8fa4bab5611	f	\N	2012-12-08 16:17:07.330082	1	1992-01-01	\N	f		t
\.


--
-- Data for Name: pessoa_arquivo; Type: TABLE DATA; Schema: public; Owner: -
--

COPY pessoa_arquivo (id_pessoa, foto) FROM stdin;
\.


--
-- Name: pessoa_id_pessoa_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('pessoa_id_pessoa_seq', 5451, true);


--
-- Data for Name: sala; Type: TABLE DATA; Schema: public; Owner: -
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
-- Name: sala_id_sala_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('sala_id_sala_seq', 10, true);


--
-- Data for Name: sexo; Type: TABLE DATA; Schema: public; Owner: -
--

COPY sexo (id_sexo, descricao_sexo, codigo_sexo) FROM stdin;
0	Não Informado	N
1	Masculino	M
2	Feminino	F
\.


--
-- Data for Name: tipo_evento; Type: TABLE DATA; Schema: public; Owner: -
--

COPY tipo_evento (id_tipo_evento, nome_tipo_evento) FROM stdin;
1	Palestra
2	Minicurso
3	Oficina
\.


--
-- Name: tipo_evento_id_tipo_evento_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('tipo_evento_id_tipo_evento_seq', 1, false);


--
-- Data for Name: tipo_mensagem_email; Type: TABLE DATA; Schema: public; Owner: -
--

COPY tipo_mensagem_email (id_tipo_mensagem_email, descricao_tipo_mensagem_email) FROM stdin;
1	Confirma��o de cadastro
2	Recuperar senha
3	Recuparar senha telematica
\.


--
-- Data for Name: tipo_usuario; Type: TABLE DATA; Schema: public; Owner: -
--

COPY tipo_usuario (id_tipo_usuario, descricao_tipo_usuario) FROM stdin;
1	Coordena��o
2	Organiza��o
3	Participante
\.


--
-- Name: caravana_encontro_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY caravana_encontro
    ADD CONSTRAINT caravana_encontro_pk PRIMARY KEY (id_caravana, id_encontro);


--
-- Name: caravana_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY caravana
    ADD CONSTRAINT caravana_pk PRIMARY KEY (id_caravana);


--
-- Name: dificuldade_evento_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY dificuldade_evento
    ADD CONSTRAINT dificuldade_evento_pk PRIMARY KEY (id_dificuldade_evento);


--
-- Name: encontro_horario_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY encontro_horario
    ADD CONSTRAINT encontro_horario_pkey PRIMARY KEY (id_encontro_horario);


--
-- Name: encontro_participante_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY encontro_participante
    ADD CONSTRAINT encontro_participante_pk PRIMARY KEY (id_encontro, id_pessoa);


--
-- Name: encontro_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY encontro
    ADD CONSTRAINT encontro_pk PRIMARY KEY (id_encontro);


--
-- Name: estado_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY estado
    ADD CONSTRAINT estado_pk PRIMARY KEY (id_estado);


--
-- Name: evento_arquivo_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY evento_arquivo
    ADD CONSTRAINT evento_arquivo_pk PRIMARY KEY (id_evento_arquivo);


--
-- Name: evento_demanda_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY evento_demanda
    ADD CONSTRAINT evento_demanda_pk PRIMARY KEY (evento, id_pessoa);


--
-- Name: evento_palestrante_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY evento_palestrante
    ADD CONSTRAINT evento_palestrante_pk PRIMARY KEY (id_evento, id_pessoa);


--
-- Name: evento_participacao_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY evento_participacao
    ADD CONSTRAINT evento_participacao_pk PRIMARY KEY (evento, id_pessoa);


--
-- Name: evento_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY evento
    ADD CONSTRAINT evento_pk PRIMARY KEY (id_evento);


--
-- Name: evento_realizacao_multipla_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY evento_realizacao_multipla
    ADD CONSTRAINT evento_realizacao_multipla_pkey PRIMARY KEY (evento_realizacao_multipla);


--
-- Name: evento_realizacao_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY evento_realizacao
    ADD CONSTRAINT evento_realizacao_pk PRIMARY KEY (evento);


--
-- Name: instituicao_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY instituicao
    ADD CONSTRAINT instituicao_pk PRIMARY KEY (id_instituicao);


--
-- Name: mensagem_email_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mensagem_email
    ADD CONSTRAINT mensagem_email_pk PRIMARY KEY (id_encontro, id_tipo_mensagem_email);


--
-- Name: municipio_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY municipio
    ADD CONSTRAINT municipio_pk PRIMARY KEY (id_municipio);


--
-- Name: pessoa_arquivo_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pessoa_arquivo
    ADD CONSTRAINT pessoa_arquivo_pk PRIMARY KEY (id_pessoa);


--
-- Name: pessoa_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pessoa
    ADD CONSTRAINT pessoa_pk PRIMARY KEY (id_pessoa);


--
-- Name: sala_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sala
    ADD CONSTRAINT sala_pk PRIMARY KEY (id_sala);


--
-- Name: sexo_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sexo
    ADD CONSTRAINT sexo_pk PRIMARY KEY (id_sexo);


--
-- Name: tipo_evento_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tipo_evento
    ADD CONSTRAINT tipo_evento_pk PRIMARY KEY (id_tipo_evento);


--
-- Name: tipo_mensagem_email_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tipo_mensagem_email
    ADD CONSTRAINT tipo_mensagem_email_pk PRIMARY KEY (id_tipo_mensagem_email);


--
-- Name: tipo_usuario_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tipo_usuario
    ADD CONSTRAINT tipo_usuario_pk PRIMARY KEY (id_tipo_usuario);


--
-- Name: caravana_encontro_responsavel_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX caravana_encontro_responsavel_idx ON caravana_encontro USING btree (id_encontro, responsavel);


--
-- Name: email_uidx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX email_uidx ON pessoa USING btree (email);


--
-- Name: evento_arquivomd5_uidx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX evento_arquivomd5_uidx ON evento_arquivo USING btree (nome_arquivo_md5);


--
-- Name: evento_realizacaomultipla_uidx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX evento_realizacaomultipla_uidx ON evento_realizacao_multipla USING btree (evento, data, hora_inicio, hora_fim);


--
-- Name: instituicao_indx_unq; Type: INDEX; Schema: public; Owner: -; Tablespace: 
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
-- Name: caravana_caravana_encontro_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY caravana_encontro
    ADD CONSTRAINT caravana_caravana_encontro_fk FOREIGN KEY (id_caravana) REFERENCES caravana(id_caravana);


--
-- Name: caravana_criador_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY caravana
    ADD CONSTRAINT caravana_criador_fkey FOREIGN KEY (criador) REFERENCES pessoa(id_pessoa);


--
-- Name: caravana_encontro_encontro_participante_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY encontro_participante
    ADD CONSTRAINT caravana_encontro_encontro_participante_fk FOREIGN KEY (id_caravana, id_encontro) REFERENCES caravana_encontro(id_caravana, id_encontro);


--
-- Name: dificuldade_evento_evento_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento
    ADD CONSTRAINT dificuldade_evento_evento_fk FOREIGN KEY (id_dificuldade_evento) REFERENCES dificuldade_evento(id_dificuldade_evento);


--
-- Name: encontro_caravana_encontro_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY caravana_encontro
    ADD CONSTRAINT encontro_caravana_encontro_fk FOREIGN KEY (id_encontro) REFERENCES encontro(id_encontro);


--
-- Name: encontro_encontro_participante_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY encontro_participante
    ADD CONSTRAINT encontro_encontro_participante_fk FOREIGN KEY (id_encontro) REFERENCES encontro(id_encontro);


--
-- Name: encontro_evento_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento
    ADD CONSTRAINT encontro_evento_fk FOREIGN KEY (id_encontro) REFERENCES encontro(id_encontro);


--
-- Name: estado_municipio_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY municipio
    ADD CONSTRAINT estado_municipio_fk FOREIGN KEY (id_estado) REFERENCES estado(id_estado);


--
-- Name: evento_evento_palestrante_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_palestrante
    ADD CONSTRAINT evento_evento_palestrante_fk FOREIGN KEY (id_evento) REFERENCES evento(id_evento);


--
-- Name: evento_evento_realizacao_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_realizacao
    ADD CONSTRAINT evento_evento_realizacao_fk FOREIGN KEY (id_evento) REFERENCES evento(id_evento);


--
-- Name: evento_realizacao_evento_demanda_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_demanda
    ADD CONSTRAINT evento_realizacao_evento_demanda_fk FOREIGN KEY (evento) REFERENCES evento_realizacao(evento);


--
-- Name: evento_realizacao_evento_participacao_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_participacao
    ADD CONSTRAINT evento_realizacao_evento_participacao_fk FOREIGN KEY (evento) REFERENCES evento_realizacao(evento);


--
-- Name: evento_realizacao_multipla_evento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_realizacao_multipla
    ADD CONSTRAINT evento_realizacao_multipla_evento_fkey FOREIGN KEY (evento) REFERENCES evento_realizacao(evento);


--
-- Name: evento_responsavel_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento
    ADD CONSTRAINT evento_responsavel_fkey FOREIGN KEY (responsavel) REFERENCES pessoa(id_pessoa);


--
-- Name: instituicao_caravana_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY caravana
    ADD CONSTRAINT instituicao_caravana_fk FOREIGN KEY (id_instituicao) REFERENCES instituicao(id_instituicao);


--
-- Name: instituicao_encontro_participante_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY encontro_participante
    ADD CONSTRAINT instituicao_encontro_participante_fk FOREIGN KEY (id_instituicao) REFERENCES instituicao(id_instituicao);


--
-- Name: municipio_caravana_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY caravana
    ADD CONSTRAINT municipio_caravana_fk FOREIGN KEY (id_municipio) REFERENCES municipio(id_municipio);


--
-- Name: municipio_encontro_participante_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY encontro_participante
    ADD CONSTRAINT municipio_encontro_participante_fk FOREIGN KEY (id_municipio) REFERENCES municipio(id_municipio);


--
-- Name: pessoa_caravana_encontro_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY caravana_encontro
    ADD CONSTRAINT pessoa_caravana_encontro_fk FOREIGN KEY (responsavel) REFERENCES pessoa(id_pessoa);


--
-- Name: pessoa_encontro_participante_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY encontro_participante
    ADD CONSTRAINT pessoa_encontro_participante_fk FOREIGN KEY (id_pessoa) REFERENCES pessoa(id_pessoa);


--
-- Name: pessoa_evento_demanda_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_demanda
    ADD CONSTRAINT pessoa_evento_demanda_fk FOREIGN KEY (id_pessoa) REFERENCES pessoa(id_pessoa);


--
-- Name: pessoa_evento_palestrante_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_palestrante
    ADD CONSTRAINT pessoa_evento_palestrante_fk FOREIGN KEY (id_pessoa) REFERENCES pessoa(id_pessoa);


--
-- Name: pessoa_evento_participacao_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_participacao
    ADD CONSTRAINT pessoa_evento_participacao_fk FOREIGN KEY (id_pessoa) REFERENCES pessoa(id_pessoa);


--
-- Name: sala_evento_realizacao_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento_realizacao
    ADD CONSTRAINT sala_evento_realizacao_fk FOREIGN KEY (id_sala) REFERENCES sala(id_sala);


--
-- Name: sexo_pessoa_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY pessoa
    ADD CONSTRAINT sexo_pessoa_fk FOREIGN KEY (id_sexo) REFERENCES sexo(id_sexo);


--
-- Name: tipo_evento_evento_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY evento
    ADD CONSTRAINT tipo_evento_evento_fk FOREIGN KEY (id_tipo_evento) REFERENCES tipo_evento(id_tipo_evento);


--
-- Name: tipo_mensagem_email_mensagem_email_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mensagem_email
    ADD CONSTRAINT tipo_mensagem_email_mensagem_email_fk FOREIGN KEY (id_tipo_mensagem_email) REFERENCES tipo_mensagem_email(id_tipo_mensagem_email);


--
-- Name: tipo_usuario_encontro_participante_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY encontro_participante
    ADD CONSTRAINT tipo_usuario_encontro_participante_fk FOREIGN KEY (id_tipo_usuario) REFERENCES tipo_usuario(id_tipo_usuario);


--
-- Name: public; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

