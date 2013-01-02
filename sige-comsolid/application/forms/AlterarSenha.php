<?php

class Application_Form_AlterarSenha extends Zend_Form {
	
	public function init() {
		$sessao = Zend_Auth::getInstance()->getIdentity();
		
		$idPessoa =  $sessao["idPessoa"];
		$idEncontro =  $sessao["idEncontro"];
		$administrador = $sessao["administrador"];
		
		
		
		$this->setAction('/participante/alterarsenha')
           ->setMethod('post');
       
       
    $pessoa = new Application_Model_Pessoa();
    $pessoa = $pessoa->find($idPessoa);
        
    $login = $this->createElement('text', 'email',array('label' => 'Login/E-mail: '));
    $login->setRequired(true)
          ->addValidator('EmailAddress')
          ->setAttrib('readonly',true)
          ->setValue($pessoa[0]->email)
          ->addErrorMessage("E-mail invalido");
          
    $senhaAntiga = $this->createElement('password', 'senhaAntiga',array('label' => 'Senha Antiga: '));
    $senhaAntiga->addValidator('stringLength', false, array(6, 255))
          ->setRequired(true)
          ->addErrorMessage("Você digitou uma senha muito pequeno ou muito grande");
          
   $senhaNova = $this->createElement('password', 'senhaNova',array('label' => 'Senha Nova: '));
   $senhaNova ->addValidator('stringLength', false, array(6, 255))
          ->setRequired(true)
          ->addErrorMessage("Você digitou uma senha muito pequeno ou muito grande");
          
   $senhaNovaRepeticao = $this->createElement('password', 'senhaNovaRepeticao',array('label' => 'Repita a Nova Senha: '));
   $senhaNovaRepeticao ->addValidator('stringLength', false, array(6, 255))
          ->setRequired(true)
          ->addErrorMessage("Você digitou uma senha muito pequeno ou muito grande");       
    
    $this->addElement($login)
    	 ->addElement($senhaAntiga)
    	 ->addElement($senhaNova)
    	 ->addElement($senhaNovaRepeticao);
	$botao = $this->createElement('submit', 'confimar')->removeDecorator('DtDdWrapper');
	$this->addElement($botao);
	$botao = $this->createElement('reset', 'cancelar')->removeDecorator('DtDdWrapper');
	$this->addElement($botao);
	}
	
}