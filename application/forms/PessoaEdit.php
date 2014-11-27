<?php

class Application_Form_PessoaEdit extends Application_Form_Pessoa {

    public function init() {
        $this->addElement($this->_nome())
              ->addElement($this->_apelido())
              ->addElement($this->_sexo())
              ->addElement($this->_municipio())
              ->addElement($this->_instituicao())
              ->addElement($this->_nascimento())
              ->addElement($this->_cpf())
              ->addElement($this->_telefone())
              ->addElement($this->_bio())
              ->addElement($this->_twitter())
              ->addElement($this->_facebook())
              ->addElement($this->_slideshare())
              ->addElement($this->_endereco_internet());

        $submit = new Zend_Form_Element_Submit('submit');
        $submit->setLabel(_("Confirm"))
              ->setAttrib('id', 'submitbutton')
              ->setAttrib('class', 'btn btn-primary');
        $submit->setDecorators(array(
            'ViewHelper',
            'Description',
            'Errors',
        ));
        $this->addElement($submit);
    }

    protected function _bio() {
        $e = new Zend_Form_Element_Textarea('bio');
        $e->setLabel('Bio:')
              ->setAttrib('rows', 5)
              ->setAttrib('placeholder', _('Write a little about yourself...'))
              ->addFilter('StripTags')
              ->addFilter('StringTrim');
        $e->setAttrib('class', 'form-control');
        return $e;
    }

    protected function _slideshare() {
        $e = $this->createElement('text', 'slideshare', array('label' => 'Slideshare: '));
        $e->addValidator('regex', false, array('/^[A-Za-z0-9_]*$/'))
              ->addErrorMessage(_("Invalid Slideshare username"));
        $e->setAttrib('class', 'form-control');
        return $e;
    }
}
