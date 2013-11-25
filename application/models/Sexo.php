<?php
class Application_Model_Sexo extends Zend_Db_Table_Abstract {

	protected $_name = 'sexo';
	protected $_primary = 'id_sexo';
	protected $_referenceMap = array(  
            array(  'refTableClass' => 'Application_Model_Pessoa',  
               'refColumns' => 'id_sexo',  
               'columns' => 'id_sexo',  
               'onDelete'=> self::CASCADE,  
               'onUpdate'=> self::RESTRICT));
}
?>
