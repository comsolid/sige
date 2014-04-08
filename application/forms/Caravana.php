<?php

class Application_Form_Caravana extends Zend_Form {

    public function init() {

        $nome_caravana = $this->createElement('text', 'nome_caravana', array('label' => '* ' . _('Caravan name:')));
        $nome_caravana->setRequired(true)
                ->addValidator('regex', false, array('/^(\w|[áéíóúçãõ]|-|\s)+$/'))
                ->addValidator('stringLength', false, array(1, 100))
                //Você digitou um nome muito pequeno (min. 1) ou contém caracteres inválidos
                ->addErrorMessage(_("You enter a name too small (min. 1) or the name has invalid characters."));

        $apelido_caravana = $this->createElement('text', 'apelido_caravana', array('label' => '* ' . _('Codename:')));
        $apelido_caravana->setRequired(true)
                ->addValidator('stringLength', false, array(1, 100))
                //Apelido muito pequeno (min. 1)
                ->addErrorMessage(_("Codename is too small (min. 1)."));


        $cidade = new Application_Model_Municipio();
        $listaCiddades = $cidade->fetchAll(null, 'nome_municipio');

        $municipio = $this->createElement('select', 'id_municipio', array('label' => _('District:')));
        $municipio->setAttrib("class", "select2");
        foreach ($listaCiddades as $item) {
            $municipio->addMultiOptions(array($item->id_municipio => $item->nome_municipio));
        }

        $ins = new Application_Model_Instituicao();
        $listaIns = $ins->fetchAll(null, 'nome_instituicao');

        $instituicao = $this->createElement('select', 'id_instituicao', array('label' => _('Institution:')));
        $instituicao->setAttrib("class", "select2");
        foreach ($listaIns as $item) {
            $instituicao->addMultiOptions(array($item->id_instituicao => $item->nome_instituicao));
        }

        $submit = $this->createElement('submit', 'confimar', array('label' => _('Confirm')))
                ->removeDecorator('DtDdWrapper');

        $cancelar = $this->createElement('submit', 'cancelar', array('label' => _('Cancel')))
                ->removeDecorator('DtDdWrapper');
        $cancelar->setAttrib('class', 'submitCancelar');

        $this->addElement($nome_caravana)
                ->addElement($apelido_caravana)
                ->addElement($municipio)
                ->addElement($instituicao)
                ->addElement($submit)
                ->addElement($cancelar);
    }

}