<?php

class Admin_Form_Horarios extends Zend_Form {

    private $id_encontro;
    private  $descricao;
    const HORA_INI = 'hora_inicio';
    const HORA_FIM = 'hora_fim';


    /**
    * @return the $descricao
    */
    public function getDescricao() {
        return $this->descricao;
    }

    /**
    * @param field_type $descricao
    */
    public function setDescricao($descricao) {
        $this->descricao = $descricao;
    }

    public function init() {
        $cache = Zend_Registry::get('cache_common');
        $ps = $cache->load('prefsis');
        $this->id_encontro = (int) $ps->encontro["id_encontro"];

        $this->setMethod("post");

        $this->addElement($this->_descricao())
        ->addElement($this->_id_sala())
        ->addElement($this->_data())
        ->addElement($this->_hora(self::HORA_INI, 'Horário Inicio:'))
        ->addElement($this->_hora(self::HORA_FIM, 'Horário Término:'));

        $submit = new Zend_Form_Element_Submit('submit');
        $submit->setLabel(_("Confirm"))
            ->setAttrib('id', 'submitbutton')
            ->setAttrib('class', 'btn btn-primary pull-right');
        $submit->setDecorators(array(
            'ViewHelper',
            'Description',
            'Errors',
        ));
        $this->addElement($submit);
    }

    protected function _descricao() {
        $e = new Zend_Form_Element_Text('descricao');
        $e->setLabel(_('Description:'));
        $e->addValidator('StringLength', false, array(1,100));
        $e->setAttrib("data-rangelength", "[1,100]");
        $e->addFilter('StripTags');
        $e->addFilter('StringTrim');
        $e->setAttrib('class', 'form-control');
        $e->setAttrib('placeholder', _('Class 1 or Part 1...'));

        $e->setDecorators(array(
            'ViewHelper',
            'Description',
            'Errors',
            array('HtmlTag', ''),
            array('Label', ''),
        ));
        return $e;
    }

    protected function _id_sala() {
        $e = new Zend_Form_Element_Select('id_sala');
        $e->setRequired(true);
        $e->setLabel(_('Place:'));
        $e->setAttrib('class', 'form-control');
        $model = new Application_Model_Sala();
        $rs = $model->fetchAll();
        foreach ($rs as $item) {
            $e->addMultiOption($item->id_sala, $item->nome_sala);
        }

        $e->setDecorators(array(
            'ViewHelper',
            'Description',
            'Errors',
            array('HtmlTag', ''),
            array('Label', ''),
        ));
        return $e;
    }

    protected function _data() {
        $model = new Application_Model_Encontro();
        $where = $model->getAdapter()->quoteInto('id_encontro = ?', $this->id_encontro);
        $row = $model->fetchRow($where);
        $element = $this->createElement('radio', 'data', array('label' => 'Data: '));
        $data_ini = new Zend_Date($row->data_inicio, 'YYYY-MM-dd');
        $data_fim = new Zend_Date($row->data_fim, 'YYYY-MM-dd');
        while ($data_ini <= $data_fim) {
            $element->addMultiOption($data_ini->toString('dd/MM/YYYY'), $data_ini->toString('dd/MM/YYYY'));
            $data_ini->add(1, Zend_Date::DAY);
        }
        $element->setRequired(true)->addErrorMessage(_("Choose a date to the event."));

        $element->setDecorators(array(
            'ViewHelper',
            'Description',
            'Errors',
            array('HtmlTag', ''),
            array('Label', ''),
        ));

        return $element;
    }

    protected function _hora($id, $label) {
        $e = new Zend_Form_Element_Select($id);
        $e->setRequired(true);
        $e->setLabel($label);
        $e->setAttrib('class', 'form-control');

        $model = new Application_Model_Encontro();
        $sql = "SELECT intervalo_minutos, horario_inicial, horario_final
            FROM encontro e
            INNER JOIN tipo_horario th ON e.id_tipo_horario = th.id_tipo_horario
            WHERE e.id_encontro = ?";
        $row = $model->getAdapter()->fetchRow($sql, array($this->id_encontro));

        $hora_aux = $hora_min = new Zend_Date($row['horario_inicial'], 'HH:mm:ss');
        $hora_max = new Zend_Date($row['horario_final'], 'HH:mm:ss');
        while ($hora_aux <= $hora_max) {
            if (self::HORA_INI == $id and $hora_aux == $hora_max) {
                $hora_aux->add($row['intervalo_minutos'], Zend_Date::MINUTE);
                continue;
            } else if (self::HORA_FIM == $id and $hora_aux == new Zend_Date($row['horario_inicial'], 'HH:mm:ss')) {
                $hora_aux->add($row['intervalo_minutos'], Zend_Date::MINUTE);
                continue;
            }
            $e->addMultiOption($hora_aux->toString('HH:mm'), $hora_aux->toString('HH:mm'));
            $hora_aux->add($row['intervalo_minutos'], Zend_Date::MINUTE);
        }
        return $e;
    }
}
