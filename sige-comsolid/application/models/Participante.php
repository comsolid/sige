<?php


class Application_Model_Participante extends Zend_Db_Table_Abstract
{
  protected $_name = 'encontro_participante';
  protected $_sequence = false;
  protected $_primary= array('id_pessoa', 'id_encontro');
  
  protected $_referenceMap = array(  
               array(  'refTableClass' => 'Application_Model_Pessoa',  
               'refColumns' => 'id_pessoa',  
               'columns' => 'id_pessoa',  
               'onDelete'=> self::RESTRICT,  
               'onUpdate'=> self::RESTRICT),
               
               array('refTableClass' => 'Application_Model_Encontro',  
               'refColumns' => 'id_encontro',  
               'columns' => 'id_encontro',  
               'onDelete'=> self::RESTRICT,  
               'onUpdate'=> self::RESTRICT) );  
               
       
               
  protected $_dependentTables = array('pessoa','encontro','municipio','tipo_usuario','caravana','instituicao' );  
	
	public function getMinhaCaravana($data){
      	$select = "SELECT c.id_caravana, apelido_caravana, nome_municipio, apelido_instituicao, p.nome
FROM caravana_encontro ce INNER JOIN pessoa p ON (ce.responsavel = p.id_pessoa)
                          INNER JOIN encontro_participante ep ON (ep.id_caravana = ce.id_caravana AND ep.id_encontro = ce.id_encontro)
                          INNER JOIN caravana c ON (ce.id_caravana = c.id_caravana) 
                     LEFT OUTER JOIN instituicao i ON (c.id_instituicao = i.id_instituicao)
                          INNER JOIN municipio m ON (c.id_municipio = m.id_municipio)
WHERE ce.id_encontro = ?
  AND ep.id_pessoa = ?";
      	
      	return $this->getAdapter()->fetchAll($select,$data);
      }
      
      public function getMinhasCaravanaResponsavel($data){
      	$select = "SELECT c.id_caravana, apelido_caravana, nome_municipio, apelido_instituicao, p.nome
FROM caravana_encontro ce INNER JOIN pessoa p ON (ce.responsavel = p.id_pessoa)
                          INNER JOIN caravana c ON (ce.id_caravana = c.id_caravana) 
                     LEFT OUTER JOIN instituicao i ON (c.id_instituicao = i.id_instituicao)
                          INNER JOIN municipio m ON (c.id_municipio = m.id_municipio)
WHERE ce.id_encontro = ? AND p.id_pessoa = ?";
      	
      	return $this->getAdapter()->fetchAll($select,$data);
      } 
      public function sairDaCaravana($data){
      	$select = "UPDATE encontro_participante SET id_caravana = NULL WHERE id_encontro = ? AND id_pessoa = ?";
      	return $this->getAdapter()->fetchAll($select,$data);
      }
      
         public function excluirMinhaCaravanaResponsavel($data){
      	$select = "DELETE FROM caravana_encontro WHERE id_encontro = ? AND id_caravana = ?";
      	return $this->getAdapter()->fetchAll($select,$data);
      }
      public function isParticipantes($data){  	  	
	  	  	$select= " SELECT id_pessoa FROM pessoa WHERE  email=? ";
	  	  	$id=$this->getAdapter()->fetchAll($select,$data);
	  	  	if(count($id)>0){
	  	  		return true;
	  	  	}
  		return false;
	  	
	  }

}
