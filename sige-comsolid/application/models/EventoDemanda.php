<?php

class Application_Model_EventoDemanda extends Zend_Db_Table_Abstract
{
  protected $_name = 'evento_demanda';
  protected $_sequence = false;
  protected $_primary= array('evento', 'id_pessoa');
  
  /*protected $_referenceMap = array(  
               array(  'refTableClass' => 'Application_Model_Pessoa',  
               'refColumns' => 'id_pessoa',  
               'columns' => 'id_pessoa',  
               'onDelete'=> self::RESTRICT,  
               'onUpdate'=> self::RESTRICT),
               
               array('refTableClass' => 'Application_Model_EventoRealizacao',  
               'refColumns' => 'evento',  
               'columns' => 'evento',  
               'onDelete'=> self::RESTRICT,  
               'onUpdate'=> self::RESTRICT) );  */
               
  protected $_dependentTables = array('pessoa','evento_realizacao');  
  
  public function remover($data){
		$this->delete($data);
  }
  public function getMeusEvento($data){
  	$select= "SELECT er.evento, nome_tipo_evento, nome_evento, TO_CHAR(data, 'DD/MM/YYYY') as data, TO_CHAR(hora_inicio, 'HH:MM') AS hora_inicio, TO_CHAR(hora_fim, 'HH:MM') AS hora_fim
FROM evento_demanda ed INNER JOIN evento_realizacao er ON (ed.evento = er.evento) INNER JOIN evento e ON (er.id_evento = e.id_evento) INNER JOIN tipo_evento te ON (e.id_tipo_evento = te.id_tipo_evento)
WHERE e.id_encontro = ? AND ed.id_pessoa = ?";
  	
  	return $this->getAdapter()->fetchAll($select,$data);
  }
}
