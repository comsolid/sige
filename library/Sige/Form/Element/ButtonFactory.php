<?php

/**
 * Description of ButtonFactory
 *
 * @author atila
 */
class Sige_Form_Element_ButtonFactory {

    public static function createSubmit($name = "confirmar") {
        $submit = new Zend_Form_Element_Submit($name);
        $submit->removeDecorator('DtDdWrapper');
        return $submit;
    }

    public static function createCancel($name = "cancelar") {
        $cancel = new Sige_Form_Element_Link($name);
        $cancel->removeDecorator('DtDdWrapper');
        return $cancel;
    }

}
