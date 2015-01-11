<?php

class Zend_View_Helper_MailTo extends Zend_View_Helper_Abstract {

    private $BREAK_LINE = "%0D%0A%0D%0A";

    public function mailTo($horario, $nome, $email, $tipo_evento, $evento) {
        $template = "mailto:{$email}?body=Olá {$nome},{$this->BREAK_LINE}
estamos contactando-o sobre - {$tipo_evento}: {$evento}.{$this->BREAK_LINE}
Seu horário será: dia {$horario['data']}, de {$horario['inicio']} às {$horario['fim']}.{$this->BREAK_LINE}
Responda este e-mail confirmando ou sugerindo melhor horário.{$this->BREAK_LINE}
Obrigado pela atenção.{$this->BREAK_LINE}
&subject={$tipo_evento} - {$evento}";
        return $template;
    }
}
