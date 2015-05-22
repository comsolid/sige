<?php

class Application_Form_DefinirSenha extends Zend_Form {

    public function init() {
        $this->setName('definir-senha');

        $submit = new Zend_Form_Element_Submit('submit');
        $submit->setLabel(_('Confirm'));
        $submit->setAttrib('class', 'btn btn-lg btn-success btn-block');

        $this->addElement($this->_novaSenha());
        $this->addElement($this->_repetirNovaSenha());
        $this->addElement($submit);
    }

    private function _novaSenha() {
        $e = new Zend_Form_Element_Password('nova_senha');
        $e->setRequired(true);
        $e->addFilter('StripTags');
        $e->addFilter('StringTrim');
        $e->setAttrib('data-parsley-required', 'true');
        $e->setAttrib('data-parsley-length', '[6,15]');
        $e->addValidator('stringLength', false, array(6, 15));
        $e->setAttrib('placeholder', _('New Password'));
        $e->setAttrib('class', 'form-control input-lg');
		$e->setAttrib('autocomplete', 'off');
		$e->setAttrib('autofocus', 'autofocus');
        return $e;
    }

    private function _repetirNovaSenha() {
        $e = new Zend_Form_Element_Password('repetir_nova_senha');
        $e->setRequired(true);
        $e->addFilter('StripTags');
        $e->addFilter('StringTrim');
        $e->setAttrib('data-parsley-required', 'true');
        $e->setAttrib('data-parsley-equalto', '#nova_senha');
        $e->addValidator('stringLength', false, array(6, 15));
        $e->setAttrib('placeholder', _('Repeat New Password'));
        $e->setAttrib('class', 'form-control input-lg');

        return $e;
    }

}
