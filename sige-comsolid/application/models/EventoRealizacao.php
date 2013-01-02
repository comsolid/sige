<?php

class Application_Model_EventoRealizacao extends Zend_Db_Table_Abstract
{
  protected $_name = 'evento_realizacao';
  protected $_primary = 'evento';
  
  protected $_referenceMap = array(  
               array(  'refTableClass' => 'Application_Model_EventoDemanda',  
               'refColumns' => 'evento',  
               'columns' => 'evento',  
               'onDelete'=> self::CASCADE,  
               'onUpdate'=> self::RESTRICT));
 
}