<?php
class Application_Model_Sala extends Zend_Db_Table_Abstract {

	protected $_name = 'sala';
	protected $_primary = 'id_sala';
	protected $_referenceMap = array(  
            array(  'refTableClass' => 'Application_Model_EventoRealizacao',  
               'refColumns' => 'id_sala',  
               'columns' => 'id_sala',  
               'onDelete'=> self::CASCADE,  
               'onUpdate'=> self::RESTRICT));
}
