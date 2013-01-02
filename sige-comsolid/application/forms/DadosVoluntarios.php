<?php
class Application_Form_DadosVoluntarios extends Zend_Form {
	
	public function init() {
		$this->setAction('/login/recuperarsenha')
           ->setMethod('post');
       
    $login = $this->createElement('text', 'email',array('label' => 'Login/E-mail: '));
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