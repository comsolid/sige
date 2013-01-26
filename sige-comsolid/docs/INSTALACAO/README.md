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
    VALUES ('I Encontro de Software Livre', 'I ESL', '2013-11-07', '2013-11-09', true);
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
    	'http://www.esl.org/login');
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
    	'http://www.esl.org/login');
~~~

Por ser um exemplo, as mensagens ficaram uma muito parecida com a outra. Você deve adaptar
de acordo com seu encontro.

<!--
TODO: demonstrar configuração do projeto, fazendo checkout e instalando o zend
-->

### Configurar conexão com base de dados

Com o projeto configurado vamos editar os parâmetros de conexão com o PostgreSQL.
Dentro do diretório do projeto (daqui para frente chamadado de `${SiGE}`) abra o
arquivo `${SiGE}/application/configs/application.ini` e edite os parâmetros abaixo:

~~~
resources.db.params.host     = "localhost" 
resources.db.params.dbname   = "database"  
resources.db.params.username = "postgres" 
resources.db.params.password = "**secret**"
~~~

### Configurar SMTP para envio de e-mail

Temos também que configurar o envio de e-mail para validar participantes, recuperação de
senhas, etc. Ainda no arquivo `${SiGE}/application/configs/application.ini` edite o trecho:

~~~
resources.mail.transport.type = "smtp"; não precisa editar
resources.mail.transport.host = "smtp.mail.com"
resources.mail.transport.port = "587";465
resources.mail.transport.ssl  = "tls"
resources.mail.transport.auth = "login"; não precisa editar
resources.mail.transport.username   = "esl@esl.org";
resources.mail.transport.password   = "**secret**"
resources.mail.transport.register   = true; True by default 
resources.mail.defaultFrom.email    = "esl@esl.org"
resources.mail.defaultFrom.name     = "I ESL"
resources.mail.defaultReplyTo.email = "esl@esl.org"
resources.mail.defaultReplyTo.name  = "I ESL"
~~~

**obs.:** para a linha `resources.mail.transport.port`:

* 587 is the Outgoing server (SMTP) port for IMAP. It uses a TLS 
encryption connection. 
* 465 is the Outgoing server (SMTP) port for pop. It uses an SSL 
encryption connection.

Mais detalhes em [Zend_Mail][Zend_Mail].

[Zend_Mail]: http://framework.zend.com/manual/1.12/en/zend.application.available-resources.html#zend.application.available-resources.mail "Zend_Mail"

### Configurar Encontro

Após criar um encontro no banco de dados, temos um `id_encontro`. No arquivo
`${SiGE}/application/configs/application.ini` edite a linha:

~~~
encontro.codigo = 1
~~~

### Crie o primeiro usuário administrador

Abra o SiGE no navegador e crie um usuário. Se tudo der certo um e-mail com uma
senha padrão foi enviado para você. Tente fazer um login.

No banco de dados, na tebela `pessoa`, modifique a coluna `administrador` para `true`.

