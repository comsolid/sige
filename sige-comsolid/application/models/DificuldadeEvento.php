<?php

class Application_Model_DificuldadeEvento extends Zend_Db_Table_Abstract {
	
   protected $_name = 'dificuldade_evento';
   protected $_primary = 'id_dificuldade_evento';
   protected $_referenceMap = array(  
            array(
					'refTableClass' => 'Application_Model_Evento',  
               'refColumns' => 'id_dificuldade_evento',  
               'columns' => 'id_dificuldade_evento',  
               'onDelete'=> self::CASCADE,  
               'onUpdate'=> self::RESTRICT
            ));
}

