<?php

class Url_Validator extends Zend_Validate_Abstract
{
    const INVALID_URL = 'invalidUrl';

    protected $_messageTemplates = array(
        self::INVALID_URL   => "'%value%' is not a valid URL.",
    );

    public function isValid($value)
    {
        $valueString = (string) $value;
        $this->_setValue($valueString);

        if (!Zend_Uri::check($value)) {
            $this->_error(self::INVALID_URL);
            return false;
        }
        return true;
    }
}

class Application_Form_Pessoa extends Zend_Form {

	public function init() {
		$this->setAttrib("data-validate", "parsley");

		$this->addElement($this->_nome())
				->addElement($this->_email())
				->addElement($this->_apelido())
				->addElement($this->_sexo())
				->addElement($this->_twitter())
				->addElement($this->_facebook())
				->addElement($this->_endereco_internet())
				->addElement($this->_municipio())
				->addElement($this->_instituicao())
				->addElement($this->_nascimento())
                ->addElement($this->_cpf())
                ->addElement($this->_telefone())
                ->addElement($this->_captcha());

		$submit = $this->createElement('submit', 'submit', array('label' => _('Confirm')));
        $submit->setAttrib('class', 'btn btn-lg btn-primary btn-block');
        $this->addElement($submit);
	}
    
    protected function _nome() {
        $e = $this->createElement('text', 'nome', array('label' => '* ' . _('Name:')));
		$e->setRequired(true)
            ->setAttrib("data-required", "true")
            ->setAttrib("data-rangelength", "[1,100]")
            ->addValidator('regex', false, array('/^[ a-zA-ZáéíóúàìòùãẽĩõũâêîôûäëïöüçÁÉÍÓÚ]*$/'))
            ->addValidator('stringLength', false, array(1, 100))
            ->addErrorMessage(_("Name must have at least 1 character. Or contains invalid characters"));
        $e->setAttrib('class', 'form-control');
        return $e;
    }
    
    protected function _email() {
        $e = $this->createElement('text', 'email', array('label' => '* ' . _('E-mail:')));
		$e->setRequired(true)
            ->setAttrib("data-required", "true")
            ->setAttrib("data-type", "email")
            ->addValidator('EmailAddress')
            ->addErrorMessage(_("Invalid E-mail."));
        $e->setAttrib('class', 'form-control');
        return $e;
    }
    
    protected function _apelido() {
        $e = $this->createElement('text', 'apelido', array('label' => '* ' . _('Nickname:')));
		$e->setRequired(true)
            ->setAttrib("data-required", "true")
            ->setAttrib("data-rangelength", "[1,20]")
            ->addValidator('stringLength', false, array(1, 20))
            ->addFilter('StripTags')
            ->addFilter('StringTrim')
            ->addErrorMessage(_("Nickname must have at least 1, max. 20 characters"));
        $e->setAttrib('class', 'form-control');
        return $e;
    }
    
    protected function _sexo() {
        $model = new Application_Model_Sexo();
		$rs = $model->fetchAll(null, 'id_sexo ASC');
		$e = $this->createElement('radio', 'id_sexo', array('label' => _('Gender:')));
		$e->setRequired(true)
            ->setValue('0') // '0' valor padrão para 'Não Informado'
            ->setSeparator('');
        foreach($rs as $row) {
			$e->addMultiOption($row->id_sexo, $row->descricao_sexo);
		}
        //$e->setAttrib('class', 'form-control');
        return $e;
    }
    
    protected function _twitter() {
        $e = $this->createElement('text', 'twitter', array('label' => 'Twitter: @'));
		$e->addValidator('regex', false, array('/^[A-Za-z0-9_]*$/'))
           ->addErrorMessage(_("Invalid Twitter username"));
        $e->setAttrib('class', 'form-control');
        return $e;
    }
    
    protected function _facebook() {
        $e = $this->createElement('text', 'facebook', array('label' => 'Facebook:'));
		$e->addValidator('regex', false, array('/^[A-Za-z0-9_]*$/'))
            ->addErrorMessage(_("Invalid Facebook username"));
        $e->setAttrib('class', 'form-control');
        return $e;
    }
    
    protected function _endereco_internet() {
        $e = $this->createElement('text', 'endereco_internet', array('label' => _('Website:')));
		$e->addValidator(new Url_Validator)
            ->setAttrib("data-type", "urlstrict")
            ->addErrorMessage(_("Invalid website"));
        $e->setAttrib('class', 'form-control');
        return $e;
    }
    
    protected function _municipio() {
        $model = new Application_Model_Municipio();
		$list  = $model->fetchAll(null, 'nome_municipio');

		$e = $this->createElement('select', 'id_municipio', array('label' => _('District:')));
		foreach($list as $item) {
            $e->addMultiOptions(array($item->id_municipio => $item->nome_municipio));
		}
        $e->setAttrib('class', 'form-control select2');
        return $e;
    }
    
    protected function _instituicao() {
        $model = new Application_Model_Instituicao();
		$list  = $model->fetchAll(null, 'nome_instituicao');

		$e = $this->createElement('select', 'id_instituicao', array('label' => _('Institution:')));
		$e->setAttrib("class", "select2");
		foreach($list as $item) {
			$e->addMultiOptions(array($item->id_instituicao => $item->nome_instituicao));
		}
        $e->setAttrib('class', 'form-control select2');
        return $e;
    }

    /**
     * Uncomment this method if you want to use only the birth year
     * @return {[Zend_Form_Element_Select]}
     */
    protected function _nascimento() {
        $e = new Zend_Form_Element_Select('nascimento');
        $e->setLabel('* ' . _('Birth Date:'));
        $e->setAttrib("class", "form-control select2");
        $date = new Zend_Date();
        $ano = (int) $date->toString('YYYY');
        for($i = $ano; $i > 1899; $i--) {
            $e->addMultiOptions(array("01/01/$i" => "$i"));
        }

        return $e;
    }

    /**
     * Uncomment this method if you want to use the whole birth date
     * @return {[Zend_Form_Element_Text]}
     */
    /*protected function _nascimento() {
        $e = new Zend_Form_Element_Text('nascimento');
        $e->setLabel('* ' . _('Birth Date:'));
        $e->setRequired(true);
        $e->setAttrib("class", "date");
        $e->setAttrib("data-required", "true");
        $e->addFilter('StripTags');
        $e->addFilter('StringTrim');
        $e->addValidator(new Zend_Validate_Date(array('format' => 'dd/MM/yyyy')));

        return $e;
    }*/

    protected function _captcha() {
        // instalar: sudo apt-get install php5-gd
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

    protected function _cpf() {
        $e = new Zend_Form_Element_Text('cpf');
        $e->setLabel(_('SSN:')); // SSN: Social Security Number
        $e->addFilter('Digits');
        $e->addValidator(new Sige_Validate_Cpf());
        $e->setRequired(false); // change to true to be required.
        // $e->setAttrib("data-required", "true"); // uncomment for validation through js
        $e->setAttrib('class', 'form-control');
        return $e;
    }

    protected function _telefone() {
        $e = new Zend_Form_Element_Text('telefone');
        $e->setLabel(_('Phone Number:'));
        $e->addFilter('Digits');
        $e->setRequired(false);
        $e->setAttrib('class', 'form-control');
        return $e;
    }
}
