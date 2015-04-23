<?php

class Admin_Form_MensagemEmail extends Zend_Form {

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
            $this->_id_tipo_mensagem_email(),
            $this->_mensagem(),
            $this->_assunto(),
            $this->_link(),
            $this->_assinatura_siteoficial(),
            $this->_assinatura_email(),
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

    protected function _id_tipo_mensagem_email() {
        $e = new Zend_Form_Element_Hidden('id_tipo_mensagem_email');
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

    protected function _mensagem() {
        $e = new Zend_Form_Element_Hidden('mensagem');
        $e->setLabel(_('Message') . ":")
                ->setRequired(true)
                ->addFilter('StringTrim');

        $e->setDecorators(array(
            'ViewHelper',
            'Description',
            'Errors',
            array('HtmlTag', ''),
            array('Label', ''),
        ));
        return $e;
    }

    protected function _assunto() {
        $e = new Zend_Form_Element_Text('assunto');
        $e->setLabel(_('Subject') . ":")
                ->setRequired(true)
                ->addValidator('StringLength', false, array(1, 200))
                ->addFilter('StripTags')
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

    protected function _link() {
        $e = new Zend_Form_Element_Text('link');
        $e->setLabel(_('Link') . ":")
                ->addValidator('StringLength', false, array(1, 70))
                ->addFilter('StripTags')
                ->addFilter('StringTrim')
                ->setAttrib('class', 'form-control')
                ->setAttrib('placeholder', 'ex. http://www.esl.org/login');

        $e->setDecorators(array(
            'ViewHelper',
            'Description',
            'Errors',
            array('HtmlTag', ''),
            array('Label', ''),
        ));
        return $e;
    }

    protected function _assinatura_siteoficial() {
        $e = new Zend_Form_Element_Text('assinatura_siteoficial');
        $e->setLabel('Link para site oficial (assinatura):')
                ->addValidator('StringLength', false, array(1, 70))
                ->addFilter('StripTags')
                ->addFilter('StringTrim')
                ->setAttrib('class', 'form-control')
                ->setAttrib('placeholder', 'ex. http://www.esl.org/');

        $e->setDecorators(array(
            'ViewHelper',
            'Description',
            'Errors',
            array('HtmlTag', ''),
            array('Label', ''),
        ));
        return $e;
    }

    protected function _assinatura_email() {
        $e = new Zend_Form_Element_Text('assinatura_email');
        $e->setLabel('E-mail da assinatura:')
                ->addValidator('StringLength', false, array(1, 70))
                ->addValidator('EmailAddress', TRUE)
                ->addFilter('StripTags')
                ->addFilter('StringTrim')
                ->setAttrib('class', 'form-control')
                ->setAttrib('placeholder', 'ex. seuemail@host.com.br');

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
