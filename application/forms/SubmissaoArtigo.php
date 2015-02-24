<?php

class Application_Form_SubmissaoArtigo extends Zend_Form {

    public function init() {
        $this->setAttrib("data-validate", "parsley");
        $this->setName('submissao-artigo');

        $this->addElements(array(
            $this->_nome_evento(),
            $this->_resumo(),
            $this->_arquivo(),
        ));

        $responsavel = $this->createElement('hidden', 'responsavel');
        $this->addElement($responsavel);

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

    protected function _nome_evento() {
        $e = new Zend_Form_Element_Text('nome_evento');
        $e->setLabel(_('Title:'))
                ->setRequired(true)
                ->addValidator('StringLength', false, array(1, 255))
                ->setAttrib("data-required", "true")
                ->setAttrib("data-rangelength", "[1,255]")
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

    protected function _resumo() {
        $e = new Zend_Form_Element_Textarea('resumo');
        $e->setLabel(_('Abstract:'))
                ->setRequired(true)
                ->setAttrib('rows', 10)
                ->setAttrib("data-required", "true")
                ->addFilter('StringTrim')
                ->setAttrib('class', 'form-control')
                ->addValidator('stringLength', false, array(20))
                ->addFilter(new Sige_Filter_HTMLPurifier)
                ->addErrorMessage("Resumo com número insuficiente de caracteres (mín. 20).");

        $e->setDecorators(array(
            'ViewHelper',
            'Description',
            'Errors',
            array('HtmlTag', ''),
            array('Label', ''),
        ));
        return $e;
    }

    protected function _arquivo() {
        $e = new Zend_Form_Element_File('arquivo');
        $e->setLabel(_('PDF File:'))
                ->setRequired(true)
                // garante um unico arquivo
                ->addValidator('Count', false, 1)
                // limite de 5 MB
                ->addValidator('Size', false, 5242880) //
                ->setMaxFileSize(5242880)
                // somente extensao PDF
                ->addValidator('Extension', false, 'pdf')
                ->setValueDisabled(true);
        return $e;
    }

}
