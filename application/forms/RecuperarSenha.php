<?php

class Application_Form_RecuperarSenha extends Zend_Form {
	
	public function init() {
       
    $login = $this->createElement('text', 'email',array('label' => 'E-mail: '));
    $login->setRequired(true)
          ->addValidator('EmailAddress')
          ->addErrorMessage("E-mail invalido");
      
    $this->addElement($login);
	$botao = $this->createElement('submit', 'confimar')->removeDecorator('DtDdWrapper');
	$this->addElement($botao);
	$botao = $this->createElement('reset', 'cancelar')->removeDecorator('DtDdWrapper');
	$this->addElement($botao);
	
	}
	
}
