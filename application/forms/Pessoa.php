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

		$nome = $this->createElement('text', 'nome', array('label' => '* ' . _('Name:')));
		$nome->setRequired(true)
            ->setAttrib("data-required", "true")
            ->setAttrib("data-rangelength", "[1,100]")
            ->addValidator('regex', false, array('/^[ a-zA-ZáéíóúàìòùãẽĩõũâêîôûäëïöüçÁÉÍÓÚ]*$/'))
            ->addValidator('stringLength', false, array(1, 100))
            ->addErrorMessage(_("Name must have at least 1 character. Or contains invalid characters"));

		$email = $this->createElement('text', 'email', array('label' => '* ' . _('E-mail:')));
		$email->setRequired(true)
            ->setAttrib("data-required", "true")
            ->setAttrib("data-type", "email")
            ->addValidator('EmailAddress')
            ->addErrorMessage(_("Invalid E-mail."));

		$apelido = $this->createElement('text', 'apelido', array('label' => '* ' . _('Nickname:')));
		$apelido->setRequired(true)
            ->setAttrib("data-required", "true")
            ->setAttrib("data-rangelength", "[1,20]")
            ->addValidator('stringLength', false, array(1, 20))
            ->addFilter('StripTags')
            ->addFilter('StringTrim')
            ->addErrorMessage(_("Nickname must have at least 1, max. 20 characters"));

        $modelSexo = new Application_Model_Sexo();
		$rs = $modelSexo->fetchAll(null, 'id_sexo ASC');
		$sexo = $this->createElement('radio', 'id_sexo', array('label' => _('Gender:')));
		$sexo->setRequired(true)
            ->setValue('0') // '0' valor padrão para 'Não Informado'
            ->setSeparator('');
        foreach($rs as $row) {
			$sexo->addMultiOption($row->id_sexo, $row->descricao_sexo);
		}

		$twitter = $this->createElement('text', 'twitter', array('label' => 'Twitter: @'));
		$twitter->addValidator('regex', false, array('/^[A-Za-z0-9_]*$/'))
           ->addErrorMessage(_("Invalid Twitter username"));

		$facebook = $this->createElement('text', 'facebook', array('label' => 'Facebook:'));
		$facebook->addValidator('regex', false, array('/^[A-Za-z0-9_]*$/'))
            ->addErrorMessage(_("Invalid Facebook username"));

		$site = $this->createElement('text', 'endereco_internet', array('label' => _('Website:')));
		$site->addValidator(new Url_Validator)
            ->setAttrib("data-type", "urlstrict")
            ->addErrorMessage(_("Invalid website"));

		$cidade = new Application_Model_Municipio();
		$listaCiddades  = $cidade->fetchAll(null, 'nome_municipio');

		$municipio = $this->createElement('select', 'municipio', array('label' => _('District:')));
		$municipio->setAttrib("class", "select2");
		foreach($listaCiddades as $item) {
            $municipio->addMultiOptions(array($item->id_municipio => $item->nome_municipio));
		}

		$ins = new Application_Model_Instituicao();
		$listaIns  = $ins->fetchAll(null, 'nome_instituicao');

		$instituicao = $this->createElement('select', 'instituicao', array('label' => _('Institution:')));
		$instituicao->setAttrib("class", "select2");
		foreach($listaIns as $item) {
			$instituicao->addMultiOptions(array($item->id_instituicao => $item->nome_instituicao));
		}

		$this->addElement($nome)
				->addElement($email)
				->addElement($apelido)
				->addElement($sexo)
				->addElement($twitter)
				->addElement($facebook)
				->addElement($site)
				->addElement($municipio)
				->addElement($instituicao)
				->addElement($this->_nascimento())
                ->addElement($this->_cpf())
                ->addElement($this->_telefone())
                ->addElement($this->_captcha());

		$submit = $this->createElement('submit', _('Confirm'))->removeDecorator('DtDdWrapper');
		$this->addElement($submit);
		$resetar = $this->createElement('reset', _('Reset'))->removeDecorator('DtDdWrapper');
		$this->addElement($resetar);
	}

    /**
     * Uncomment this method if you want to use only the birth year
     * @return {[Zend_Form_Element_Select]}
     */
    protected function _nascimento() {
        $e = new Zend_Form_Element_Select('nascimento');
        $e->setLabel('* ' . _('Birth Date:'));
        $e->setAttrib("class", "select2");
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

        return $e;
    }

    protected function _telefone() {
        $e = new Zend_Form_Element_Text('telefone');
        $e->setLabel(_('Phone Number:'));
        $e->addFilter('Digits');
        $e->setRequired(false);

        return $e;
    }
}
