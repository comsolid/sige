START TRANSACTION;

--
-- Tabela: dificuldade_evento
--
INSERT INTO dificuldade_evento(id_dificuldade_evento, descricao_dificuldade_evento)
    VALUES (1, 'Básico'), (2, 'Intermediário'), (3, 'Avançado');

--
-- Tabela: estado
-- obs.: Adicione Estados segundo a demanda.
--
INSERT INTO estado(id_estado, nome_estado, codigo_estado)
    VALUES (1, 'Ceará', 'CE');

--
-- Tabela: instituicao
-- obs.: representa que o participante não vem de nenhuma instituição.
--
INSERT INTO instituicao(id_instituicao, nome_instituicao, apelido_instituicao)
    VALUES (1, '-------------', '-------------');

--
-- Tabela: municipio
-- obs.: Municípios ainda são cadastrados manualmente e possuem tipo serial.
--
INSERT INTO municipio(
            id_municipio, nome_municipio, id_estado)
    VALUES (1, 'Não informado', 1);

--
-- Tabela: sala
-- obs.: Salas ainda são cadastradas manualmente e possuem tipo serial.
--
INSERT INTO sala(id_sala, nome_sala)
    VALUES (1, 'Auditório');

--
-- Tabela: sexo
--
INSERT INTO sexo(id_sexo, descricao_sexo, codigo_sexo)
    VALUES (0, 'Não informado', 'N'), (1, 'Masculino', 'M'), (2, 'Feminino', 'F');

--
-- Tabela: tipo_evento
--
INSERT INTO tipo_evento(nome_tipo_evento)
    VALUES ('Palestra'), ('Minicurso'), ('Oficina');

--
-- Tabela: tipo_mensagem_email
--
INSERT INTO tipo_mensagem_email(
            id_tipo_mensagem_email, descricao_tipo_mensagem_email)
    VALUES (1, 'Confirmação de cadastro'), (2, 'Recuperar senha'),
           (3, 'Confirmação de submissão'), (4, 'Confirmação de inscrição');

--
-- Tabela: tipo_usuario
--
INSERT INTO tipo_usuario(
            id_tipo_usuario, descricao_tipo_usuario)
    VALUES (1, 'Coordenação'), (2, 'Organização'), (3, 'Participante');

--
-- Tabela: tipo_horario
--
INSERT INTO tipo_horario(
            id_tipo_horario, intervalo_minutos, horario_inicial, horario_final)
    VALUES (1, 30, '00:00:00', '23:00:00');

--
-- Tabela: encontro
--
INSERT INTO encontro(
            id_encontro, nome_encontro, apelido_encontro, data_inicio, data_fim,
            periodo_submissao_inicio, periodo_submissao_fim)
    VALUES (1, 'I Encontro de Software Livre', 'I ESL', CURRENT_DATE + 30, CURRENT_DATE + 33,
    CURRENT_DATE, CURRENT_DATE + 33);

--
-- Tabela: mensagem_email
--
INSERT INTO mensagem_email(
            id_encontro, id_tipo_mensagem_email, mensagem, assunto, link)
    VALUES (1, 1, 'Nome: {nome}, E-mail: {email}, Senha: {senha},
    	<a href="{href_link}" target="_blank">Clique aqui</a>',
    	'I ESL - Cadastro Encontro',
    	'http://www.esl.org/login');

INSERT INTO mensagem_email(
            id_encontro, id_tipo_mensagem_email, mensagem, assunto, link)
    VALUES (1, 2, 'Nome: {nome}, E-mail: {email}, Senha: {senha},
    	<a href="{href_link}" target="_blank">Clique aqui</a>',
    	'I ESL - Recuperar Senha',
    	'http://www.esl.org/login');

INSERT INTO mensagem_email(
            id_encontro, id_tipo_mensagem_email, mensagem, assunto, link)
    VALUES (1, 3, 'Nome: {nome}, E-mail: {email}, Senha: {senha},
    	<a href="{href_link}" target="_blank">Clique aqui</a>',
    	'I ESL - Confirmação de Submissão',
    	'http://www.esl.org/login');

INSERT INTO mensagem_email(
            id_encontro, id_tipo_mensagem_email, mensagem, assunto, link)
    VALUES (1, 4, 'Nome: {nome}, E-mail: {email}, Senha: {senha},
    	<a href="{href_link}" target="_blank">Clique aqui</a>',
    	'I ESL - Confirmação de Inscrição',
    	'http://www.esl.org/login');

--
-- Tabela: pessoa
--
INSERT INTO pessoa(
            id_pessoa, nome, email, apelido, senha, nascimento, administrador)
    VALUES (1, 'Admin', 'esl@esl.org', 'Admin', md5('123456'), CURRENT_DATE, 'T');

--
-- Tabela: encontro_participante
--
INSERT INTO encontro_participante(
            id_encontro, id_pessoa, id_instituicao, id_municipio, id_caravana,
            id_tipo_usuario, validado, data_validacao, data_cadastro, confirmado,
            data_confirmacao)
    VALUES (1, 1, 1, 1, NULL,
            1, 'T', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'T',
            CURRENT_TIMESTAMP);


COMMIT;
