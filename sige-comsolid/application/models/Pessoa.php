<?php

class Application_Model_Pessoa extends Zend_Db_Table_Abstract
{
  protected $_name = 'pessoa';
  protected $_primary = 'id_pessoa';
  
 protected $_referenceMap = array(  
               array(  'refTableClass' => 'Application_Model_Participante',  
               'refColumns' => 'id_pessoa',  
               'columns' => 'id_pessoa',  
               'onDelete'=> self::CASCADE,  
               'onUpdate'=> self::RESTRICT), 
               
               array(  'refTableClass' => 'Application_Model_Evento',  
               'refColumns' => 'responsavel',  
               'columns' => 'id_pessoa',  
               'onDelete'=> self::CASCADE,  
               'onUpdate'=> self::RESTRICT),
               
               array(  'refTableClass' => 'Application_Model_EventoDemanda',  
               'refColumns' => 'id_pessoa',  
               'columns' => 'id_pessoa',  
               'onDelete'=> self::CASCADE,  
               'onUpdate'=> self::RESTRICT),
               
              );

	public function gerarSenha() {
	   try {
			$qryIsValid = $this->getAdapter()->quoteInto("SELECT funcGerarSenha(?) AS c ", $this->email);
			$senha=$this->getAdapter()->query($qryIsValid)->fetch();
			$this->senha= $senha['c'];
	     
			return $senha['c']; 
		}catch (Exception $ex) {
		  	
		}
	}
	
	public function avaliaLogin($login, $senha) {

		/*$select = $this->select()
			  		    ->from('pessoa', array("id_pessoa",
                       "administrador",
                       "apelido",
                       "(senha=md5('$senha')) AS valido",
                       'twitter'))
			  		   ->where("email = ?", $login);*/
      $sql = "select id_pessoa, administrador, apelido, (senha = md5(?)) as valido, twitter
         from pessoa where email = ? ";
      $where = array($senha, $login);
		$result = $this->getAdapter()->fetchAll($sql, $where);

		return $result[0];
	}
	
	public function buscaPessoas($data){
		 $select="SELECT p.id_pessoa, p.nome, p.cadastro_validado, apelido, email, twitter,
			nome_municipio, apelido_instituicao, nome_caravana, ep.confirmado
			FROM encontro_participante ep INNER JOIN pessoa p ON (ep.id_pessoa = p.id_pessoa)
			LEFT OUTER JOIN instituicao i ON (ep.id_instituicao = i.id_instituicao)
			INNER JOIN municipio m ON (ep.id_municipio = m.id_municipio)
			LEFT OUTER JOIN caravana c ON (ep.id_caravana = c.id_caravana)
			WHERE id_encontro = ? AND id_tipo_usuario = 3 "; // 3: participante
		
		if($data[2]=="nome"){
			if($data[1] != NULL){
				$data[1] = "%".$data[1]."%";
	         	$select = $select.' AND p.nome ilike ? ';
			}else{
				unset($data[1]);
			}
		} else if ($data[2] == "municipio") {
			if($data[1] != NULL){
				$data[1] = $data[1]."%";
	         	$select = $select.' AND nome_municipio ilike ? ';
			}else{
				unset($data[1]);
			}
		} else if ($data[2] == "caravana") {
			if($data[1] != NULL){
				$data[1] = $data[1]."%";
	         	$select = $select.' AND nome_caravana ilike ? ';
			}else{
				unset($data[1]);
			}
		} else if ($data[2] == "instituicao") {
			if($data[1] != NULL){
				$data[1] = $data[1]."%";
	         	$select = $select.' AND apelido_instituicao ilike ? ';
			}else{
				unset($data[1]);
			}
		}else{
			if($data[1] != NULL){
				$data[1] = $data[1]."%";
	         	$select = $select.' AND p.email ilike ? ';
			}else{
				unset($data[1]);
			}
		}
		unset($data[2]);	 
		$select = $select.' ORDER BY p.data_cadastro DESC LIMIT 20';
		return $this->getAdapter()->fetchAll($select,$data);
	}
	
	public function buscaPessoasCoordenacao($data){
		$select = "SELECT p.id_pessoa, nome, apelido, email FROM encontro_participante ep INNER JOIN pessoa p ON (ep.id_pessoa = p.id_pessoa) WHERE id_encontro = ? AND id_tipo_usuario = 1";
		
		return $this->getAdapter()->fetchAll($select,$data);
	}
	
	public function buscaPessoasOrganizacao($data){
		$select = "SELECT p.id_pessoa, nome, apelido, email FROM encontro_participante ep INNER JOIN pessoa p ON (ep.id_pessoa = p.id_pessoa) WHERE id_encontro = ? AND id_tipo_usuario = 2";
		
		return $this->getAdapter()->fetchAll($select,$data);
	}
	
	public function verificaEncontro($idEncontro, $idPessoa){
		$select = "SELECT * from encontro_participante where id_encontro = ? AND id_pessoa= ?";
		
		$resp = $this->getAdapter()->fetchAll($select,array($idEncontro,$idPessoa));
		
		if(sizeof($resp) == 0){
			return false;
		}
		
		return true;
	}
	
	
	public function buscaUltimoEncontro($idPessoa){
		$select =  "select * from encontro_participante where id_pessoa = ? order by id_pessoa desc limit 1";
		
		return $this->getAdapter()->fetchAll($select, $idPessoa);
	}
	
	public function atualizaEncontro($encontro){
		$select = "insert into encontro_participante(id_encontro, id_pessoa,id_instituicao,id_municipio,id_caravana,id_tipo_usuario) values(?,?,?,?,?,?)";
		
	   return $this->getAdapter()->fetchAll($select,$encontro);
	}
	
	public function buscarPermissaoUsuarios($idEncontro, $termo = "",
           $buscar_por = "nome", $tipo_usuario = 0) {
      
      $sql = "SELECT p.id_pessoa, p.nome, p.apelido,
               p.email, p.administrador, tu.id_tipo_usuario, tu.descricao_tipo_usuario
         FROM encontro_participante ep
         INNER JOIN pessoa p ON ep.id_pessoa = p.id_pessoa
         INNER JOIN tipo_usuario tu ON ep.id_tipo_usuario = tu.id_tipo_usuario
         WHERE ep.id_encontro = ? ";
      $where = array($idEncontro);
      if (! empty($termo)) {
         if ($buscar_por == "nome") {
            $sql .= " AND p.nome ILIKE ? ";
            $where[] = "%{$termo}%";
         } else if ($buscar_por == "email") {
            $sql .= " AND p.email ILIKE ? ";
            $where[] = "%{$termo}%";
         } else if ($buscar_por == "id_pessoa") {
            $sql .= " AND p.id_pessoa = ? ";
            $where[] = (int) $termo;
         }
      }
      
      if ($tipo_usuario > 0) {
         $sql .= " AND tu.id_tipo_usuario = ? ";
         $where[] = $tipo_usuario;
      }
      
      $sql .= " ORDER BY p.nome LIMIT 50 ";
      return $this->getAdapter()->fetchAll($sql, $where);
   }

}