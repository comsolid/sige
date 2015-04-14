<?php

class Admin_Model_Sistema extends Zend_Db_Table_Abstract {

    protected $_name = '';

    public function infoPostgres() {
        $sql = "select version(), to_char(now(), 'DD/MM/YYYY HH24:MI:SS') as datetime";
        return $this->getAdapter()->fetchRow($sql);
    }
}
