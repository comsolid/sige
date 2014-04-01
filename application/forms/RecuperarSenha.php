<?php

class Application_Form_RecuperarSenha extends Zend_Form {
	
	public function init() {
        $login = $this->createElement('text', 'email',array('label' => _('E-mail:')));
        $login->setRequired(true)
            ->addValidator('EmailAddress')
            ->addErrorMessage(_("Invalid E-mail."));

        $this->addElement($login);
        $submit = $this->createElement('submit', _('Confirm'))->removeDecorator('DtDdWrapper');
        $this->addElement($submit);
        $resetar = $this->createElement('reset', _('Reset'))->removeDecorator('DtDdWrapper');
        $this->addElement($resetar);
	}
}
