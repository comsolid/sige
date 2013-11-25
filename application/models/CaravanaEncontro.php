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
		
	  
	public function buscaParticipantes($idCaravana, $idEncontro) {
	  	$select= "SELECT p.id_pessoa,nome FROM pessoa p INNER JOIN encontro_participante ep ON (p.id_pessoa = ep.id_pessoa)
					WHERE id_encontro = ? AND id_caravana = ? ORDER BY nome";
  	
  		return $this->getAdapter()->fetchAll($select,array($idEncontro,$idCaravana));
	}  
	  
	public function addParticipantesNaCaravana($data) {
	  	  	
	  	$select= "UPDATE encontro_participante SET id_caravana = ? WHERE id_encontro = ?  " .
	  	  			" AND id_pessoa IN (SELECT p.id_pessoa FROM pessoa p INNER JOIN encontro_participante ep ON (p.id_pessoa = ep.id_pessoa)" .
	  	  			" WHERE id_encontro = ? AND id_caravana IS NULL AND email IN (? ";
	  	$quant = count($data);
	  	for ($i=4 ;$i<$quant;$i=$i+1 ) {
			$select .= ", ?";
		}
		$select .= ")) ";

  		return $this->getAdapter()->fetchAll($select,$data);
	}
     
	public function updateParticipantesCaravana($where) {
	  	  	
	  	$select= "UPDATE encontro_participante SET id_caravana = ? WHERE id_encontro = ?
	  	  			AND id_pessoa IN
                  (SELECT p.id_pessoa FROM pessoa p 
                  INNER JOIN encontro_participante ep ON (p.id_pessoa = ep.id_pessoa)
	  	  			WHERE id_encontro = ? AND id_caravana IS NULL AND p.id_pessoa IN (";
			  	
      $quant = count($where);
      $numParam = 3;
      $pessoas_validas = 0;
      // concatena os id_pessoa que vem de $data
		for ($i = $numParam; $i < $quant; $i++) {
         if (intval($where[$i]) > 0) {
            $select .= " ?";
            if ($i < $quant - 1) {
               $select .= ", ";
            }
            $pessoas_validas++;
         } else {
            unset($where[$i]);
         }
      }
      $select .= ")) ";
      if ($pessoas_validas > 0) {
         $this->getAdapter()->fetchAll($select,$where);
         return 1; // true
      } else {
         return 0; // false
      }
	}
     
	public function deletarParticipante($data) {
	  	$select= "UPDATE encontro_participante SET id_caravana = NULL WHERE id_encontro = ? AND id_pessoa = ? ";
  		$this->getAdapter()->fetchAll($select,$data);
	}

	public function lerParticipanteCaravana($idEncontro = 0, $idPessoa = 0) {
		$select = "SELECT c.id_caravana, apelido_caravana, nome_municipio, apelido_instituicao, p.nome
                     FROM caravana_encontro ce INNER JOIN pessoa p ON (ce.responsavel = p.id_pessoa)
                          INNER JOIN encontro_participante ep ON (ep.id_caravana = ce.id_caravana AND ep.id_encontro = ce.id_encontro)
                          INNER JOIN caravana c ON (ce.id_caravana = c.id_caravana) 
                     LEFT OUTER JOIN instituicao i ON (c.id_instituicao = i.id_instituicao)
                          INNER JOIN municipio m ON (c.id_municipio = m.id_municipio)
                     WHERE ce.id_encontro = ?
                     AND ep.id_pessoa = ?";
      $rs = $this->getAdapter()->fetchAll($select, array($idEncontro, $idPessoa));
		if (count($rs) > 0) {
			return $rs[0];
		}
		return null;
	}

	public function lerResponsavelCaravana($idEncontro = 0, $idPessoa = 0) {
		$select = "SELECT c.id_caravana, apelido_caravana, nome_municipio, apelido_instituicao, p.nome
                  FROM caravana_encontro ce INNER JOIN pessoa p ON (ce.responsavel = p.id_pessoa)
                          INNER JOIN caravana c ON (ce.id_caravana = c.id_caravana) 
                     LEFT OUTER JOIN instituicao i ON (c.id_instituicao = i.id_instituicao)
                          INNER JOIN municipio m ON (c.id_municipio = m.id_municipio)
                  WHERE ce.id_encontro = ? AND p.id_pessoa = ?";
      $rs = $this->getAdapter()->fetchAll($select, array($idEncontro, $idPessoa));
		if (count($rs) > 0) {
			return $rs[0];
		}
		return null;
	}

	/**
	 * @deprecated
	 */
	public function validaCaravana($idCaravana) {
     	$select = "UPDATE caravana_encontro SET validada = 'T' WHERE id_caravana = ?";
      	
		return $this->getAdapter()->fetchAll($select,$idCaravana);
   }

   /**
	 * @deprecated
	 */
	public function invalidaCaravana($idCaravana) {
		$select = "UPDATE caravana_encontro SET validada = 'F'  WHERE id_caravana = ?";
		
		return $this->getAdapter()->fetchAll($select,$idCaravana);
	}
}
	
?>
