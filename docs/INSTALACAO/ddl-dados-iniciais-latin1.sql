start transaction;

set client_enconding = 'LATIN1';

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
INSERT INTO municipio(nome_municipio, id_estado)
    VALUES ('Não informado', 1);
   
--
-- Tabela: sala
-- obs.: Salas ainda são cadastradas manualmente e possuem tipo serial.
--
INSERT INTO sala(nome_sala)
    VALUES ('Auditório');

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
    VALUES (1, 'Confirmação de cadastro'), (2, 'Recuperar senha');

--
-- Tabela: tipo_usuario
--
INSERT INTO tipo_usuario(
            id_tipo_usuario, descricao_tipo_usuario)
    VALUES (1, 'Coordenação'), (2, 'Organização'), (3, 'Participante');
    
ROLLBACK;
