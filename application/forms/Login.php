<?php

class Application_Form_Login extends Zend_Form {
	
	public function init() {
		$this->setAction($this->getView()->url())
           ->setMethod('post');
    
        $this->addElement($this->_email())
			   ->addElement($this->_senha());
	    $submit = $this->createElement('submit', _('Login'))->removeDecorator('DtDdWrapper');
		$this->addElement($submit);
		$resetar = $this->createElement('reset', _('Reset'))->removeDecorator('DtDdWrapper');
		$this->addElement($resetar);
	}
   
    protected function _email() {
        $email = $this->createElement('text', 'email', array('label' => _('E-mail:')));
        $email->setRequired(true)
          ->addValidator('EmailAddress')
          ->addErrorMessage(_("Invalid E-mail."));
        return $email;
    }
   
    protected function _senha() {
        $senha = $this->createElement('password', 'senha', array('label' => _('Password:')));
        $senha->addValidator('stringLength', false, array(6, 255))
            ->setRequired(true)
            ->addErrorMessage(_("You enter a very small or very large password. Min.: 6, Max.: 255"));
        return $senha;
    }
}

