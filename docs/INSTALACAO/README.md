% SiGE - Sistema de Gerência de Eventos
% Equipe COMSOLiD

# Instalação e Configuração

Programas necessários:

* PostgreSQL;
* Apache HTTP Server;
* php5;
* Zend Framework;
* subversion (opcional);

## Base de dados

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
INSERT INTO encontro(nome_encontro, apelido_encontro, data_inicio, data_fim,
    periodo_submissao_inicio, periodo_submissao_fim)
    VALUES ('I Encontro de Software Livre', 'I ESL', '2013-11-07', '2013-11-09',
    '2013-05-01', '2013-11-06');
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

Outro ponto importante é configurar o *enconding* ao inserir um encontro e suas mensagens.
Para isso adicione `SET client_encoding = 'LATIN1';` no início do *insert*.

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

**obs.:** esse passo serve somente para o primeiro encontro. Os demais podem ser criados
a partir do SiGE em `/adim/encontro/criar/`.

## SiGE

### Zend

A versão utilizada pelo SiGE é [Zend 1.12.3][Zend_1.12.3].

[Zend_1.12.3]: http://framework.zend.com/downloads/latest#ZF1 "Zend 1.12.3"

A instalação é bem simples. Basta copiarmos o Zend para um diretório de bibliotecas do sistema.
Baixe o pacote Full, descompacte e siga as instruções em um terminal:

~~~
$ sudo su
# mv ZendFramework-1.12.1 /usr/local/lib
# cd /usr/local/lib
# ln -s ZendFramework-1.12.3 zend
~~~

### Baixando SiGE do Github

Para realizar clone da última versão do SiGE:

~~~
$ git clone https://github.com/comsolid/sige.git
~~~

**obs.:** é necessário instalar o git. No Ubuntu podemos instalar através do comando:

~~~
$ sudo apt-get install git
~~~

**obs.:** instale a partir do repositório somente se você está interessado em contribuir,
estudar o código ou apenas testando.

### Baixando versão estável SiGE

Procure pela versão mais atual do SiGE em:

<https://github.com/comsolid/sige/releases>

Renomeie a pasta para `sige` caso necessário.

### Configurando VirtualHost

Para simular um host no mundo real que utiliza Zend precisamos criar um VirtualHost no apache.
Com o Apache devidamente instalado, crie um arquivo em `/etc/apache2/sites-enable/`
chamado `sige`. Nele copie o seguinte conteúdo, modificando conforme necessidade:

~~~
<VirtualHost *:80>
   ServerName sige.local

   DocumentRoot /var/www/sige/public
   <Directory "/var/www/sige/public">
      AllowOverride All
   </Directory>
</VirtualHost>
~~~

Adicionaremos o `ServerName` ao `/etc/hosts`:

~~~
127.0.0.1       localhost
# adicione a linha abaixo
127.0.0.1       sige.local
~~~

Habilite o `mod rewrite` do apache: `$ sudo a2enmod rewrite`.

Reinicie o Apache: `$ sudo service apache2 restart`.

### Instalar o Zend no SiGE

A instalação é bem simples, apenas crie um link simbólico dentro do diretório do
projeto (daqui para frente chamadado de `${SiGE}`) em `${SIGE}/library`:

~~~
$ sudo su
# cd /var/www/sige/library
# ln -s /usr/local/lib/zend/library/Zend
~~~

### Permitir escrita para HTMLPurifier e Captcha

É necessário dar permissão total a dois diretórios, faça:

~~~
$ cd ${SiGE}/library/HTMLPurifier/DefinitionCache/
$ mkdir Serializer
$ chmod 777 Serializer/
$ cd ${SiGE}/public/
$ mkdir captcha
$ chmod 777 captcha/
~~~

### Configurar conexão com base de dados

Com o projeto configurado vamos editar os parâmetros de conexão com o PostgreSQL.
Dentro do diretório do projeto abra o arquivo `${SiGE}/application/configs/application.ini`
e edite os parâmetros abaixo:

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
resources.mail.transport.host = "smtp.esl.com"; servidor gmail: smtp.gmail.com
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

### Certificados

Os arquivos relativos aos certificados, participante e palestrante, ficam localizados
em `${SiGE}/public/img/certificados/`. Lá teremos um diretório `default/` que contém
arquivos iniciais para que um certificado possa ser gerado sem nenhuma configuração.

Para criar certificados para um determinado encontro devemos criar um diretório
em `${SiGE}/public/img/certificados/` com o `id_encontro` do encontro. Por exemplo,
se `id_encontro` for 1, criaremos o diretório `${SiGE}/public/img/certificados/1/`.

Utilize os arquivos `modelo.svg` e `assinatura-modelo.svg` dentro de `${SiGE}/public/img/certificados/default/`
como modelos para a criação de seus certificados. Eles possuem as marcações e os tamanhos
específicos. Os tamanhos são:

**Arquivo**            **Tamanho**
-----------            -------------------------------------------------
modelo.svg             1052x744 (mesmo tamanho de uma folha A4 paisagem)
assinatura-modelo.svg  250x140

**obs.:** o arquivo `modelo.svg` possui camadas para que ao trabalhar em cima do molde
você não se atrapalhe com outros objetos. Usando Inkscape acesse as camadas com o comando
*Shift + Ctrl + L*.

Após finalização do modelo, exporte o arquivo para **JPG**. Como o Inkscape não
exporta diretamente para essa extensão, utilize o GIMP para essa tarefa.

O certificado do SiGE suporta até três assinaturas. Para isso você deve exportar o arquivo
de assinatura da seguinte forma: `assinatura-1.png` - para que a assinatura apareça
a esquerda do certificado, `assinatura-2.png` - para que a assinatura apareça no centro
e `assinatura-3.png` - para que apareça a direita.

As assinaturas são opcionais e podem ser usadas da maneira que você deseja. Por exemplo,
se você possui um certificado que tenha algum detalhes no centro você pode optar por
criar apenas as assinaturas `assinatura-1.png` e `assinatura-3.png`.

**obs.:** Note que o arquivo de assinaturas possui a extensão **PNG**. Por ser uma
imagem pequena e que necessita de *alpha*, optamos por usá-la.

Abaixo uma simulação da árvore de diretórios `${SiGE}/public/img/certificados/`:

~~~
${SiGE}/public/img/certificados/
|
+ -- 1/
|    |
|    + -- modelo.jpg
|         assinatura-1.png
|         assinatura-3.png
|
+ -- default/
     |
     + -- modelo.jpg
          modelo.svg
          assinatura-modelo.png
          assinatura-1.png
~~~

### Dados do evento

#### Contagem Regressiva

Para modficar a data e os dados referentes a contagem regressiva que aparece na página
inicial do SiGE vá até o arquivo `${SiGE}/public/js/index/index.js`
e modifique as linhas:

~~~
// data do evento
ts = new Date(2013, 10, 5),
~~~

**obs.:** lembrando que em Javascript os meses vão de 0 a 11.

~~~
month
    Integer value representing the month, beginning with 0 for January to 11 for December.
~~~

Fonte: <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date>

e

~~~
// mude para o nome do seu evento
MSG_EVENTO = "para o ESL I!";
~~~

#### Twitter

No arquivo `${SiGE}/application/configs/application.ini`
altere as linhas:

~~~
twitter.username = "els"; sem "@"
twitter.hashtags = "els1"; sem "#" e separadas por ","
~~~

### Cores do sistema

Para alterar a cor dos _links_ abra o `arquivo ${SiGE}/public/css/sigecss.css` altere o trecho:

~~~
#corpo a {
   /* ... */
}
~~~

Para alterar a cor dos menus abra o arquivo `arquivo ${SiGE}/public/css/sigecss.css` altere o trecho:

~~~
#menu {
   /* ... */
}

#menu a {
   /* ... */
}

#menu a.active, #menu a:hover {
   /* ... */
}
~~~

### Banner do Sistema

Para alterar o banner geral basta substituir o arquivo `${SiGE}/public/imagens/layout/topo_sige.png`.
As dimensões são: **962x135**.

### Versão Móvel

Edite o arquivo `application/layouts/scripts/mobile.phtml`:

Linha 44: `<h1>COMSOLiD <?=date('Y') ?></h1>`
