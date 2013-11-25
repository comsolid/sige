<?php
class Application_Form_Login extends Zend_Form {
	
	public function init() {
		$this->setAction($this->getView()->url())
           ->setMethod('post');
      
	$senha = $this->createElement('password', 'senha', array('label' => 'Senha: '));
    $senha ->addValidator('stringLength', false, array(6, 255))
          ->setRequired(true)
          ->addErrorMessage("Você digitou uma senha muito pequena ou muito grande.");
          
    
         $this->addElement($this->_email())
			   ->addElement($senha);
	    $botao = $this->createElement('submit',' Entrar')->removeDecorator('DtDdWrapper');
		$this->addElement($botao);
		$botao = $this->createElement('reset', 'Limpar')->removeDecorator('DtDdWrapper');
		$this->addElement($botao);
                
	}
   
   protected function _email() {
      $email = $this->createElement('text', 'email', array('label' => 'E-mail: '));
      $email->setRequired(true)
          ->addValidator('EmailAddress')
          ->addErrorMessage("E-mail inválido.");
      return $email;
   }
   
   protected function _senha() {
      $senha = $this->createElement('password', 'senha', array('label' => 'Senha: '));
      $senha->addValidator('stringLength', false, array(6, 255))
              ->setRequired(true)
              ->addErrorMessage("Você digitou uma senha muito pequena ou muito grande.");
      return $senha;
   }
}

