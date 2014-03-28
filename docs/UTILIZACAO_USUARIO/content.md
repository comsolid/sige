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

Página com todos os detalhes do evento, se é palestra, mini-curso ou
oficina, o horário, nível, links para compartilhar em redes sociais
e comentários usando a plataforma [disqus](http://disqus.com/).

#### NOTA:

usamos a palavra **Encontro** para definir um conjunto de eventos. **Evento**
é definido como uma palestra, mini-curos ou oficina.

### Página do usuário \label{usuario}

Cada usuário tem uma página pública onde é mostrado alguns detalhes sobre ele
como bio, twitter, apresentações do slideshare.

#### OBSERVAÇÃO:

devido a uma mudança no RSS do slideshare, alguns usuários apresentam problemas
com a visualização das suas apresentações mesmo colocando o usuário do slideshare
corretamente. Para isso precisamos usar a nova [api](http://apiexplorer.slideshare.net/).

## Telas de acesso de usuários logados