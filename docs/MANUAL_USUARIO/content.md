# Manual do Usuário

Este manual serve para o administrador do SiGE entender como funciona as telas do usuário.
Pretendemos mostrar cada tela e identificar sua função.

## Telas de acesso de usuários deslogados

São telas de acesso público, onde qualquer usuário pode acessar.

### Página inicial \label{home}

Mapeada como: `/ [application/IndexController.index]`

Primeira página do sistema, contendo o banner, links para a inscrição \ref{inscricao}
e login \ref{login}, além de contador regressivo para o evento.

### Login \label{login}

Mapeada como: `/login [application/IndexController.login]`

Página comum de login, onde o e-mail e a senha são requeridos. Contém links para
Esqueci minha senha \ref{esqueci-senha} e inscrição \ref{inscricao}.

### Inscrição \label{inscricao}

Mapeada como : `/participar [application/ParticipanteController.criar]`

Página para preenchimento dos dados necessário para se cadastrar. Logo após o cadastro
um e-mail é enviado para o usuário contendo alguns dados dele, além de uma senha gerada
automaticamente pelo sistema.

#### OBSERVAÇÃO:

esse sistema de enviar a senha deve mudar em breve, pois isso pode causar um
problema de segurança.

### Esqueci minha senha \label{esqueci-senha}

Mapeada como: `/recuperar-senha [application/IndexController.recuperar-senha]`

Nessa tela apenas o e-mail é requerido. Logo em seguida uma nova senha gerada
pelo sistema é enviada para o e-mail do usuário.

#### OBSERVAÇÃO:

essa tela deve mudar muito. Pedir apenas o e-mail pode gerar ataque de DoS,
troca de senhas não desejadas, etc.

Para começar teremos um Captcha, além do pedido de outros dados.

### Sobre \label{sobre}

Mapeada como: `/sobre [application/IndexController.sobre]`

Página com os envolvidos no projeto, tecnologias utilizadas.

### Programação \label{programacao}

Mapeada como: `/programacao [application/EventoController.programacao]`

Página com toda a programação do evento, com detalhes sobre o palestrante,
horário, conteúdo abordado, etc.

### Detalhes do evento \label{evento}

Mapeada como: `/e/:id [application/EventoController.ver]`

Página com todos os detalhes do evento, se é palestra, mini-curso ou
oficina, o horário, nível, links para compartilhar em redes sociais
e comentários usando a plataforma [disqus](http://disqus.com/).

#### NOTA:

usamos a palavra **Encontro** para definir um conjunto de eventos. **Evento**
é definido como uma palestra, mini-curos ou oficina.

### Página do usuário \label{usuario}

Mapeada como: `/u/:id [application/ParticipanteController.ver]`

Cada usuário tem uma página pública onde é mostrado alguns detalhes sobre ele
como bio, twitter, apresentações do slideshare.

#### OBSERVAÇÃO:

devido a uma mudança no RSS do slideshare, alguns usuários apresentam problemas
com a visualização das suas apresentações mesmo colocando o usuário do slideshare
corretamente. Para isso precisamos usar a nova [api](http://apiexplorer.slideshare.net/).

## Telas de acesso de usuários logados

### Participante \label{participante}

Mapeada como: `/participante [application/ParticipanteController.index]`

Tela inicial logo após login, tanto para usuário comum quanto para administrador.
Nela temos uma lista de interesses, bem como o link para
ver e adicionar interesse \ref{interesse} em palestras, mini-cursos ou oficinas.

### Interesse em Eventos \label{interesse}

Mapeado como: `/evento/interesse [application/EventoController.interesse]`

Tela de visualização e busca de eventos do interesse do participante, para que ele
possa marcar e depois ver uma lista somente com os eventos que tem interesse
(ver \ref{participante}).

É possível ver eventos por dia e por tipo, além de ver o horário. Assim o participante
vai para o que mais se adequada ao seu tempo no Encontro.

#### OBSERVAÇÃO:

Marcar um evento como interesse não garante a vaga do participante na palestra. Em outra
versão do SiGE será possível ver a demanda e selecionar uma sala adequada ao tamanho
do evento.

### Caravana \label{caravana}

Mapeada como: `/caravana [application/CaravanaController.index]`

Esta tela é para quem quer ser responsável por uma caravana. Basta clicar em Criar Caravana
\ref{criar-caravana} e preencher os dados e definir os participantes que farão parte da
Caravana.

#### NOTA:

Esta tela serve principalmente de controle de homens e mulheres que vem na Caravana,
ainda mais quando eles tem que passar mais de um dia. Assim é possível separar os
homens das mulheres à noite e arrumar locais condizentes com o número de pessoas
do mesmo gênero.

#### NOTA 2:

Ao ser adicionado numa caravana, o participante ver os dados de sua caravana junto com
um link caso queira sair. Pode ser porque decidiu não ir mais, ou foi colocado por engano.

### Criar Caravana \label{criar-caravana}

Mapeada como: `/caravana/criar [application/CaravanaController.criar]`

Nessa tela o responsável pela caravana preenche os dados requeridos. Logo após ele é redirecionado
a tela da Caravana \ref{caravana}, onde agora é possível adicionar os participantes
\ref{participantes-caravana}.

### Participantes da Caravana \label{participantes-caravana}

Mapeada como: `/caravana/participantes`

`[application/CaravanaController.participantes]`

Tela acessada somente pelo Responsável pela Caravana, onde é possível adicionar os
participantes da caravana através de seu endereço de e-mail.

#### OBSERVAÇÃO:

O endereço de e-mail aparecerá somente se o participantes estiver cadastrado
no Encontro atual, mesmo que ele tenha participado de outros.

### Editar Caravana \label{editar-caravana}

Mapeada como: `/caravana/editar [application/CaravanaController.editar]`

Tela para edição dos dados da Caravana, acessada somente pelo Responsável pela Caravana.

### Submissão de trabalhos \label{submissao}

Mapeado como: `/submissao [application/EventoController.index]`

Página que lista os trabalhos submetidos, bem como um link para submeter um
trabalho \ref{submeter}.

### Submeter trabalho \label{submeter}

Mapeado como: `/evento/submeter [application/EventoController.submeter]`

Tela para preenchimento dos dados do trabalho (ou evento).

### Editar evento \label{editar-evento}

Mapeado como: `/evento/editar/id/:id [application/EventoController.editar]`

Tela para edição dos dados do evento.

#### OBSERVAÇÃO:

Tanto a tela Submeter Trabalho \ref{submeter} quanto Editar evento \ref{editar-evento}
só podem ser acessadas no período de submissão de trabalho definido pelo Administrador
ao criar o evento. Apenas um administrador pode submeter trabalho após o período de
submissão.

### Adicionar outros palestrantes \label{add-palestrantes}

Mapeada como: `/evento/outros-palestrantes/id/:id`

`[application/EventoController.outros-palestrantes]`

Alguns eventos podem demandar mais de uma pessoa para ser realizado. Esse é o propósito
dessa tela, assim todos os envolvidos recebem certificado de palestrante.

### Criar / Editar tags \label{tags}

Mapeada como: `/evento/tags/id/:id [application/EventoController.tags]`

Adiciona e edita tags do evento. As tags indicam quais tecnologias a serem utilizadas,
ou ferramentas específicas, sistema, etc.

#### OBSERVAÇÃO:

É possível ver as tags nos Detalhes do evento \ref{evento} mas ainda não é possível
fazer buscas ou qualquer outro uso. Isso será feito em uma outra versão do SiGE.

### Página pessoal do usuário \label{pagina-pessoal}

Mapeada como: `/participante/ver [application/ParticipanteController.ver]`

Acessada ao clicar no nome de usuário na parte superior da tela à direita, perto
do link de logout.

Página pessoal contendo suas informações, assim como links para Editar dados
pessoais \ref{participante-editar}, Alterar Senha \ref{alterar-senha},
Certificados \ref{certificados}.

### Editar dados pessoais \label{participante-editar}

Mapeada como: `/participante/editar [application/ParticipanteController.editar]`

Edição de dados pessoais e de redes sociais.

### Alterar Senha \label{alterar-senha}

Mapeada como: `/participante/alterar-senha`

`[application/ParticipanteController.alterar-senha]`

Requer senha antiga, nova senha e repetição da nova senha.

### Certificados \label{certificados}

Mapeada como: `/participantes/certificados`

`[application/ParticipanteController.certificados]`

Lista com certificados de participação e que foi palestrante.