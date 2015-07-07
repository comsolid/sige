SiGE v2 - Sistema de Gerência de Eventos (Conference Manager System)
====

[![Build Status](https://travis-ci.org/comsolid/sige.svg?branch=master)](https://travis-ci.org/comsolid/sige)

![Tela inicial | Home screen](https://raw.githubusercontent.com/comsolid/sige/master/docs/screenshots/shot-20150706-15030-1unhls0.png)

Segurança | Security
----

O SiGE anterior guardava suas senhas em MD5, o que era uma prática comum mas que a tempos se tornou uma prática insegura, isso devido a facilidade em quebrar senhas criptografadas com esse algoritmo.

Na nova versão as senhas são guardadas usando a criptografia bcrypt. Isso torna o armazenamento de senhas muito mais seguro, mesmo que a senha não seja. Isso se deve ao modo de armazenamento que é feito com a senha juntamente com um salt (hash concatenado com a senha original).

Entretanto isso não é feito automaticamente. Se você já participou de um COMSOLiD anterior você ainda está com a senha em MD5. Para atualizar basta pedir para mudar a senha ou recuperar a senha.

The previous version of SiGE kept their passwords in MD5, which was a common practice but the times became an unsafe practice that because of the ease in breaking passwords encrypted with this algorithm.

In the new version the passwords are stored using the bcrypt encryption. This makes storage more secure passwords, even if the password is not. This is due to storage is done so that the password along with a salt (hashed concatenated with the original password).

However this is not done automatically. If you've ever attended a previous COMSOLiD you are still with the password in MD5. To update just ask to change the password or recover the password.

Layout (front-end)
---

A mudança mais notável de cara é o layout. Estamos usando o Twitter Bootstrap 3 como front-end do sistema. Isso nos permitiu uma interface melhor de manter além de ser bonita.

The most notable change of face is the layout. We are using the Twitter Bootstrap 3 as system front-end. This allowed us a better interface to maintain as well as being beautiful.

Certificados
---

Agora além dos certificados de participação do encontro e certificado de palestrante também tem a opção de certificados de participação em uma palestra, minicurso ou oficina. Por ser algo novo apenas os eventos com COMSOLiD 7 e 8 terão essa opção disponível. Se você veio para o COMSOLiD 7 (2014) você deve lembrar que assinou uma lista de frequência. Essa lista servirá para nós sabermos quem participou e disponibilizar o certificado através do SiGE.

Avatar
---

Uma das coisas que achamos que faltava era a presença de um avatar para os participantes, para que as pessoas conheçam a pessoa que vai palestrar. O serviço escolhido foi o Gravatar, um serviço criado pelo WordPress e trata exatamente de fornecer um local para você configurar seu avatar e que aplicativos de terceiros possam utilizar sem ter que implementar no sistema. Uma das vantagens do uso do Gravatar é que ele funciona com seu endereço de e-mail, para o SiGE era a melhor solução já que usamos o e-mail como login.

Por fim
---

Além disso tudo tem muito bug removido, pequenas features, enfim muitos detalhes resolvidos a cada ano, a cada encontro.
