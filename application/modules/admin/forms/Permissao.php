<?php

class Admin_Form_Permissao extends Zend_Form {

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

        $this->addElement($this->_admin())
            ->addElement($this->_tipo_usuario())
            ->addElement($submit);
    }

    private function _admin() {
        $e = new Zend_Form_Element_Checkbox('admin');
        $e->setLabel(_('Is administrator?') . ":");
        $e->setAttrib('data-on-color', 'success');
        $e->setAttrib('data-off-color', 'danger');
        $e->setAttrib('data-on-text', _('Yes'));
        $e->setAttrib('data-off-text', _('No'));
        return $e;
    }

    private function _tipo_usuario() {
        $e = new Zend_Form_Element_Select('id_tipo_usuario');
		$e->setRequired(true);
		$e->setLabel(_('User type') . ":");
        $e->setAttrib('class', 'form-control');
        $model = new Application_Model_TipoUsuario();
        $rs = $model->fetchAll();
        foreach ($rs as $row) {
            $e->addMultiOption($row->id_tipo_usuario, $row->descricao_tipo_usuario);
        }
        return $e;
    }
}
