<?php

class Application_Model_TipoEvento extends Zend_Db_Table_Abstract {

	protected $_name = 'tipo_evento';
	protected $_primary = 'id_tipo_evento';
	protected $_referenceMap = array(  
            array(  'refTableClass' => 'Application_Model_Evento',  
               'refColumns' => 'id_tipo_evento',  
               'columns' => 'id_tipo_evento',  
               'onDelete'=> self::CASCADE,  
               'onUpdate'=> self::RESTRICT));
}
