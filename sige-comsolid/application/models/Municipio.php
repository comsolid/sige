<?php

class Application_Model_Municipio extends Zend_Db_Table_Abstract {
	
	protected $_name = 'municipio';
	protected $_primary = 'id_municipio';
	protected $_referenceMap = array(  
               array(  'refTableClass' => 'Application_Model_Participante',  
               'refColumns' => 'id_municipio',  
               'columns' => 'id_municipio',  
               'onDelete'=> self::CASCADE,  
               'onUpdate'=> self::RESTRICT));
}


