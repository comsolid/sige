<?php

class Application_Form_RecuperarSenha extends Zend_Form {

	public function init() {
        $login = $this->createElement('text', 'email',array('label' => _('E-mail:')));
        $login->setRequired(true)
            ->addValidator('EmailAddress')
            ->addErrorMessage(_("Invalid E-mail."));

        $this->addElement($login);
        $this->addElement($this->_captcha());
        $submit = $this->createElement('submit', _('Confirm'))->removeDecorator('DtDdWrapper');
        $this->addElement($submit);
        $resetar = $this->createElement('reset', _('Reset'))->removeDecorator('DtDdWrapper');
        $this->addElement($resetar);
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

		$e->setDecorators(array(
			'Description',
			'Errors',
			array('HtmlTag', '<dd/>'),
			array('Label', '<dt/>'),
		));
		return $e;
	}
}
