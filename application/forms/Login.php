<?php

class Application_Form_Login extends Zend_Form {

	public function init() {
		$this->setMethod('post');
		$this->setName('login');

        $this->addElement($this->_email())
			   ->addElement($this->_senha());
	    $submit = $this->createElement('submit', 'submit', array('label' => _('Login')));
        $submit->setAttrib('class', 'btn btn-lg btn-success btn-block');

		$this->addElement($submit);
	}

    protected function _email() {
        $e = $this->createElement('text', 'email');
        $e->setRequired(true);
        $e->addValidator('EmailAddress');
        $e->addErrorMessage(_("Invalid E-mail."));
        $e->setAttrib('class', 'form-control input-lg');
        $e->setAttrib('placeholder', _('E-mail'));
		$e->setAttrib("data-parsley-required", "true");
		$e->setAttrib("data-parsley-type", "email");
        return $e;
    }

    protected function _senha() {
        $e = $this->createElement('password', 'senha');
        $e->addValidator('StringLength', false, array(6, 20));
        $e->setRequired(true);
        $e->addErrorMessage(_("You enter a very small or very large password. Min.: 6, Max.: 20"));
        $e->setAttrib('class', 'form-control input-lg');
        $e->setAttrib('placeholder', _('Password'));
		$e->setAttrib("data-parsley-required", "true");
        return $e;
    }
}
