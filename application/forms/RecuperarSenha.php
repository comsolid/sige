<?php

class Application_Form_RecuperarSenha extends Zend_Form {

	public function init() {
        $login = $this->createElement('text', 'email');
        $login->setRequired(true);
        $login->addValidator('EmailAddress');
        $login->addErrorMessage(_("Invalid E-mail."));
        $login->setAttrib('class', 'form-control input-lg');
        $login->setAttrib('placeholder', _('E-mail'));

        $this->addElement($login);
		if (!\Zend_Session::$_unitTestEnabled) {
			$this->addElement($this->_captcha());
		}
        $submit = $this->createElement('submit', 'submit', array('label' => _('Confirm')));
        $submit->setAttrib('class', 'btn btn-lg btn-info btn-block');
        $this->addElement($submit);
	}

	protected function _captcha() {
		$e = new Zend_Form_Element_Captcha('captcha', array(
			'label' => _('Prove that you are human, enter the characters below'),
			'required' => true,
			'captcha' => array(
				'captcha' => 'Image',
				'font' => APPLICATION_PATH . '/../public/font/FreeSans.ttf',
				'wordLen' => 6,
				'height' => 50,
				'width' => 150,
				'timeout' => 300,
				'imgDir' => APPLICATION_PATH . '/../public/captcha',
				'imgUrl' => Zend_Controller_Front::getInstance()->getBaseUrl() . '/captcha',
				'dotNoiseLevel' => 10,
				'lineNoiseLevel' => 2,
				'messages' => array(
					'badCaptcha' => _('Entered value is not valid.')
				)
			)
		));
		return $e;
	}
}
