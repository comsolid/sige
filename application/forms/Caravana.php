<?php

class Application_Form_Caravana extends Zend_Form {

    public function init() {

        $submit = new Zend_Form_Element_Submit('submit');
                $submit->setLabel(_("Confirm"))
                        ->setAttrib('id', 'submitbutton')
                        ->setAttrib('class', 'btn btn-primary');

        $this->addElements(array(
            $this->_nome_caravana(),
            $this->_apelido_caravana(),
            $this->_id_municipio(),
            $this->_id_instituicao(),
            $submit
        ));
    }

    protected function _nome_caravana() {
        $e = new Zend_Form_Element_Text('nome_caravana');
        $e->setLabel('* ' . _('Caravan name:'));
        $e->setRequired(true);
        $e->addValidator('Regex', false, array('/^(\w|[áéíóúçãõ]|-|\s)+$/'));
        $e->addValidator('StringLength', false, array(1, 100))
            ->addErrorMessage(_("You enter a name too small (min. 1) or the name has invalid characters."));
        $e->addFilter('StripTags');
        $e->addFilter('StringTrim');
        $e->setAttrib('class', 'form-control');

        return $e;
    }

    protected function _apelido_caravana() {
        $apelido_caravana = $this->createElement('text', 'apelido_caravana', array('label' => '* ' . _('Codename:')));
        $apelido_caravana->setRequired(true)
                ->addValidator('stringLength', false, array(1, 100))
                //Apelido muito pequeno (min. 1)
                ->addErrorMessage(_("Codename is too small (min. 1)."));
        $apelido_caravana->addFilter('StripTags');
        $apelido_caravana->addFilter('StringTrim');
        $apelido_caravana->setAttrib('class', 'form-control');
        return $apelido_caravana;
    }

    protected function _id_municipio() {
        $model = new Application_Model_Municipio();
        $list = $model->fetchAll(null, 'nome_municipio');

        $e = $this->createElement('select', 'id_municipio', array('label' => _('District:')));
        $e->setAttrib("class", "form-control select2");
        foreach ($list as $item) {
            $e->addMultiOptions(array($item->id_municipio => $item->nome_municipio));
        }
        return $e;
    }

    protected function _id_instituicao() {
        $model = new Application_Model_Instituicao();
        $list = $model->fetchAll(null, 'nome_instituicao');

        $e = $this->createElement('select', 'id_instituicao', array('label' => _('Institution:')));
        $e->setAttrib("class", "form-control select2");
        foreach ($list as $item) {
            $e->addMultiOptions(array($item->id_instituicao => $item->nome_instituicao));
        }
        return $e;
    }
}
