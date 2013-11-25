<?php
class Application_Model_Caravana extends Zend_Db_Table_Abstract {
   
	protected $_name = 'caravana';
	protected $_primary = 'id_caravana';
	protected $_referenceMap = array (
		array (
			'refTableClass' => 'Application_Model_Participante',
			'refColumns' => 'id_caravana',
			'columns' => 'id_caravana',
			'onDelete' => self :: CASCADE,
			'onUpdate' => self :: RESTRICT
		),
	);
	
	public function verificaCaravana($idPessoa,$idEncontro) {	
	
		$caravana_encontro = new Application_Model_CaravanaEncontro();
     	$select = $caravana_encontro->select();
		$rows = $caravana_encontro->fetchAll($select->where('responsavel = ?',$idPessoa)->where('id_encontro = ?', $idEncontro));
				
		if(count($rows)>0){	
		 	return true;
		} else {	
      	return false;  	
      }
   }
    

	public function busca($data) {
		$select = "SELECT c.id_caravana, nome_caravana, apelido_caravana, nome, 
         nome_municipio, apelido_instituicao, validada, COUNT(*)
         FROM caravana_encontro ce INNER JOIN caravana c ON (ce.id_caravana = c.id_caravana)
         INNER JOIN municipio m ON (c.id_municipio = m.id_municipio)
         INNER JOIN pessoa p ON (ce.responsavel = p.id_pessoa)
         LEFT OUTER JOIN instituicao i ON (c.id_instituicao = i.id_instituicao)
         WHERE ce.id_encontro = ? ";
		
		if ($data[1] != NULL) {
			$data[1] = "%{$data[1]}%";
         $select = "{$select} AND nome_caravana ilike ?
            GROUP BY c.id_caravana, nome_caravana, apelido_caravana, nome,
            nome_municipio, apelido_instituicao, validada";
		} else {
			unset($data[1]);
			$select = "{$select} GROUP BY c.id_caravana, nome_caravana,
            apelido_caravana, nome, nome_municipio, apelido_instituicao, validada";
		}
		return $this->getAdapter()->fetchAll($select,$data);
	}
}
?>
