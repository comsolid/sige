<?php

class Admin_Form_MensagemCertificado extends Zend_Form {

    public function init() {
        $submit = new Zend_Form_Element_Submit('submit');
        $submit->setLabel(_("Confirm"))
        ->setAttrib('id', 'submitbutton')
        ->setAttrib('class', 'btn btn-primary pull-right');
        $submit->setDecorators(array(
            'ViewHelper',
            'Description',
            'Errors',
        ));

        $this->addElements(array(
            $this->_id_encontro(),
            $this->_tipo_mensagem_certificado(),
            $this->_mensagem(),
            $submit,
        ));
    }

    protected function _id_encontro() {
        $e = new Zend_Form_Element_Hidden('id_encontro');
        $e->addFilter('Int');
        $e->setDecorators(array(
            'ViewHelper',
            'Description',
            'Errors',
            array('HtmlTag', ''),
            array('Label', ''),
        ));
        return $e;
    }

    protected function _tipo_mensagem_certificado() {
        $e = new Zend_Form_Element_Hidden('tipo_mensagem_certificado');
        $e->setDecorators(array(
            'ViewHelper',
            'Description',
            'Errors',
            array('HtmlTag', ''),
            array('Label', ''),
        ));
        return $e;
    }

    protected function _mensagem() {
        $e = new Zend_Form_Element_Textarea('mensagem');
        $e->setLabel('Mensagem:')
                ->setRequired(true)
                ->setAttrib('rows', 10)
                ->addFilter('StringTrim')
                ->setAttrib('class', 'form-control');

        $e->setDecorators(array(
            'ViewHelper',
            'Description',
            'Errors',
            array('HtmlTag', ''),
            array('Label', ''),
        ));
        return $e;
    }

}
