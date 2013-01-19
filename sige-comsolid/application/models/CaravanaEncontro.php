<?php
class Application_Model_CaravanaEncontro extends Zend_Db_Table_Abstract {
	protected $_name = 'caravana_encontro';
	  protected $_primary= array('id_caravana', 'id_encontro');
	  
	  
	  protected $_referenceMap = array(  
               array(  'refTableClass' => 'Application_Model_Caravana',  
               'refColumns' => 'id_caravana',  
               'columns' => 'id_caravana',  
               'onDelete'=> self::RESTRICT,  
               'onUpdate'=> self::RESTRICT),
               
               array('refTableClass' => 'Application_Model_Encontro',  
               'refColumns' => 'id_encontro',  
               'columns' => 'id_encontro',  
               'onDelete'=> self::RESTRICT,  
               'onUpdate'=> self::RESTRICT) );
               
	  
	  public function buscaParticipantes($idCaravana,$idEncontro){
	  	  	$select= "SELECT p.id_pessoa,nome FROM pessoa p INNER JOIN encontro_participante ep ON (p.id_pessoa = ep.id_pessoa)
					WHERE id_encontro = ? AND id_caravana = ? ORDER BY nome";
  	
  			return $this->getAdapter()->fetchAll($select,array($idEncontro,$idCaravana));
	  	
	  }  
	  
	  public function addParticipantesNaCaravana($data){
	  	  	
	  	  	$select= "UPDATE encontro_participante SET id_caravana = ? WHERE id_encontro = ?  " .
	  	  			" AND id_pessoa IN (SELECT p.id_pessoa FROM pessoa p INNER JOIN encontro_participante ep ON (p.id_pessoa = ep.id_pessoa)" .
	  	  			" WHERE id_encontro = ? AND id_caravana IS NULL AND email IN (? ";
			  	$quant = count($data);
			  	for ($i=4 ;$i<$quant;$i=$i+1 ) { $select.=", ?";}$select.=")) ";
			  
  		return $this->getAdapter()->fetchAll($select,$data);
	  	
	  }
     
	  public function updateParticipantesCaravana($where) {
	  	  	
	  	  	$select= "UPDATE encontro_participante SET id_caravana = ? WHERE id_encontro = ?
	  	  			AND id_pessoa IN
                  (SELECT p.id_pessoa FROM pessoa p 
                  INNER JOIN encontro_participante ep ON (p.id_pessoa = ep.id_pessoa)
	  	  			WHERE id_encontro = ? AND id_caravana IS NULL AND p.id_pessoa IN (? ";
			  	
         $quant = count($where);
         $numParam = 4;
         // concatena os id_pessoa que vem de $data
			for ($i = $numParam; $i < $quant; $i = $i + 1) {
            $select .= ", ?";
         }
         $select .= ")) ";
         return $this->getAdapter()->fetchAll($select,$where);
	  }
     
	  public function removeParticipanteNaCaravana($data){
	  	  	$select= "UPDATE encontro_participante SET id_caravana = NULL WHERE id_encontro = ?   AND id_pessoa =? ";
  		return $this->getAdapter()->fetchAll($select,$data);
	  	
	  }  
	  
	  
	 
	  
	  
	 public function validaCaravana($idCaravana){
      	$select = "UPDATE caravana_encontro SET validada = 'T' WHERE id_caravana = ?";
      	
      	return $this->getAdapter()->fetchAll($select,$idCaravana);
      }
      
      public function invalidaCaravana($idCaravana){
      	$select = "UPDATE caravana_encontro SET validada = 'F'  WHERE id_caravana = ?";
      	
      	return $this->getAdapter()->fetchAll($select,$idCaravana);
      	
      }  
	  
}
	
?>
