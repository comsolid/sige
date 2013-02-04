<?php

class Application_Model_Instituicao extends Zend_Db_Table_Abstract {
	
	protected $_name = 'instituicao';
	protected $_primary = 'id_instituicao';
	protected $_referenceMap = array(  
               array(  'refTableClass' => 'Application_Model_Participante',  
               'refColumns' => 'id_instituicao',  
               'columns' => 'id_instituicao',  
               'onDelete'=> self::CASCADE,  
               'onUpdate'=> self::RESTRICT));
}