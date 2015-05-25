<?php

class Application_Form_RequisitarMudarEmail extends Zend_Form {

	public function init() {
		$this->setName('requisitar_mudar_email');

        $this->addElement($this->_email_anterior());
        $this->addElement($this->_novo_email());
        $this->addElement($this->_motivo());

		if (!\Zend_Session::$_unitTestEnabled) {
			$this->addElement($this->_captcha());
		}

        $submit = $this->createElement('submit', 'submit', array('label' => _('Confirm')));
        $submit->setAttrib('class', 'btn btn-lg btn-info btn-block');
        $this->addElement($submit);
	}

	protected function _email_anterior() {
		$e = $this->createElement('text', 'email_anterior');
        $e->setRequired(true);
        $e->addValidator('EmailAddress');
        $e->addErrorMessage(_("Invalid E-mail."));
        $e->setAttrib('class', 'form-control input-lg');
		$e->setAttrib("data-parsley-required", "true");
		$e->setAttrib("data-parsley-type", "email");
        $e->setLabel(_('Previous E-mail') . ':');

		return $e;
	}

	protected function _novo_email() {
		$e = $this->createElement('text', 'novo_email');
        $e->setRequired(true);
        $e->addValidator('EmailAddress');
        $e->addErrorMessage(_("Invalid E-mail."));
        $e->setAttrib('class', 'form-control input-lg');
		$e->setAttrib("data-parsley-required", "true");
		$e->setAttrib("data-parsley-type", "email");
        $e->setLabel(_('New E-mail') . ':');

		return $e;
	}

	protected function _motivo() {
        $e = new Zend_Form_Element_Textarea('motivo');
        $e->setLabel(_('Reason') . ':');
        $e->setRequired(true);
        $e->setAttrib('rows', 4);
        $e->setAttrib("data-parsley-required", "true");
        $e->setAttrib('placeholder', _('Describe why you want to change your e-mail address...'));
        $e->addFilter('StripTags');
        $e->addFilter('StringTrim');
		$e->addValidator('StringLength', false, array(10));
        $e->setAttrib('class', 'form-control');

        return $e;
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
