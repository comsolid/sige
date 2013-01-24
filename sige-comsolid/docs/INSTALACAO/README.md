SiGE - Sistema de Gerência de Eventos
=====================================

Instalação
----------

Programas necessários:

* PostgreSQL;
* php5

### Schema da Base de dados

A instalação da base de dados é feita pelo arquivo `ddl-schema-2013.sql`. Abra o arquivo
e defina alguns parâmetros:

Encoding do servidor

~~~
SET client_encoding = 'LATIN1';
~~~

Permissão ao usuário do banco de dados

~~~
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;
~~~

Modifique `postgres` para seu usuário.

Note que o script possui `START TRANSACTION;` e `ROLLBACK;`. Faça um teste inicial
e execute o script para se certificar que tudo irá correr bem. Por fim remova-os
e execute realmente o script.

### Dados iniciais do sistema

A inserção dos dados iniciais pode ser encontrada em `ddl-dados-iniciais.sql`.
Modifique as tabelas `estado, instituicao, municipio e sala` de acordo com sua necessidade.

**obs.:** para base de dados que usam codificação `LATIN1` utilize o script `ddl-dados-iniciais-latin1.sql`.

As outras tabelas já estão devidamente preparadas.

Teste a execução de script e remova `START TRANSACTION;` e `ROLLBACK;`.

### Criando um novo encontro

O primeiro passo para criar um encontro, e adicionar um registro na tabela `encontro`
da seguinte forma:

~~~
INSERT INTO encontro(nome_encontro, apelido_encontro, data_inicio, data_fim, ativo)
    VALUES ('Encontro de Software Livre', 'I ESL', '2013-11-07', '2013-11-09', true);
~~~

**obs.:** a coluna `ativo` será removida em breve.

Depois verifique o `id_encontro` gerado e crie dois registros na tabela `mensagem_email`,
um para cada mensagem de `tipo_mensagem_email`:

~~~
INSERT INTO mensagem_email(id_encontro, id_tipo_mensagem_email,
		mensagem, assunto, link)
    VALUES (1, 1, 'Nome: {nome}, E-mail: {email}, Senha: {senha},
    	<a href="{href_link}" target="_blank">Clique aqui</a>',
    	'I ESL - Cadastro Encontro',
    	'http://www.els.org/login');
~~~

**obs.:** Note que a `mensagem` traz elementos dentro de `{}`. Eles são utilizados no PHP
para substiruir valores reais, tornando a mensagem dinâmica.

Vale lembrar que a mensagem pode ser escrita em HTML. Coloque apenas tags referentes ao `body`.

Da mesma forma crie a mensagem de recuperação de senha:

~~~
INSERT INTO mensagem_email(id_encontro, id_tipo_mensagem_email,
		mensagem, assunto, link)
    VALUES (1, 2, 'Nome: {nome}, E-mail: {email}, Senha: {senha},
    	<a href="{href_link}" target="_blank">Clique aqui</a>',
    	'I ESL - Recuperar Senha',
    	'http://www.els.org/login');
~~~

Por ser um exemplo, as mensagens ficaram uma muito parecida com a outra. Você deve adaptar
de acordo com seu encontro.
