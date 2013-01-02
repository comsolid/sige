<?php
class Application_Form_Login extends Zend_Form {
	
	public function init() {
		$this->setAction($this->getView()->url())
           ->setMethod('post');
       
    $login = $this->createElement('text', 'email',array('label' => 'Login/E-mail: '));
    $login->setRequired(true)
          ->addValidator('EmailAddress')
          ->addErrorMessage("E-mail invalido");
      
	$senha = $this->createElement('password', 'senha',array('label' => 'Senha: '));
    $senha ->addValidator('stringLength', false, array(6, 255))
          ->setRequired(true)
          ->addErrorMessage("Você digitou uma senha muito pequeno ou muito grande");
          
    
         $this->addElement($login)
			   ->addElement($senha);
	    $botao = $this->createElement('submit',' confirmar')->removeDecorator('DtDdWrapper');
		$this->addElement($botao);
		$botao = $this->createElement('reset', 'cancelar')->removeDecorator('DtDdWrapper');
		$this->addElement($botao);
                
	}
}

