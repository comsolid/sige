<?php

class Application_Model_Evento extends Zend_Db_Table_Abstract
{
  protected $_name = 'evento';
  protected $_primary = 'id_evento';
  
  protected $_referenceMap = array(  
               array(  'refTableClass' => 'Application_Model_EventoRealizacao',  
               'refColumns' => 'id_evento',  
               'columns' => 'id_evento',  
               'onDelete'=> self::CASCADE,  
               'onUpdate'=> self::RESTRICT));
  
  
  
  public function getEventos($idEncontro){
  $select="SELECT DISTINCT(TO_CHAR(data, 'DD/MM/YYYY')) AS data FROM evento e INNER JOIN evento_realizacao er ON (e.id_evento = er.id_evento) WHERE id_encontro = ? ORDER BY TO_CHAR(data, 'DD/MM/YYYY')";
		return $this->getAdapter()->fetchAll($select,$idEncontro);
	}  
	
	
	public function buscaEventos($data) {
      $select = "SELECT er.evento, nome_tipo_evento, nome_evento,
         TO_CHAR(data, 'DD/MM/YYYY') as data, TO_CHAR(hora_inicio, 'HH:MM') AS h_inicio,
         TO_CHAR(hora_fim, 'HH:MM') AS h_fim, er.descricao
         FROM evento_realizacao er
         INNER JOIN evento e ON (er.id_evento = e.id_evento)
         INNER JOIN tipo_evento te ON (e.id_tipo_evento = te.id_tipo_evento)
         INNER JOIN pessoa p ON e.responsavel = p.id_pessoa
         WHERE e.id_encontro = ? AND e.validada AND e.responsavel <> ? AND evento
            NOT IN (SELECT evento FROM evento_demanda WHERE id_pessoa = ?) ";
      $auxCont = 0;
      $where[$auxCont] = $data[0];
      $auxCont++;
      $where[$auxCont] = $data[1];
      $auxCont++;
      $where[$auxCont] = $data[2];
      if ($data[3] != 'todas') {
         $select = $select . ' AND data=?';
         $auxCont = $auxCont + 1;
         $where[$auxCont] = $data[3];
      } else {
         unset($data[3]);
      }
      if ($data[4] > 0) {
         $auxCont = $auxCont + 1;
         $where[$auxCont] = $data[4];
         $select = $select . ' AND te.id_tipo_evento=?';
      } else {
         unset($data[4]);
      }
      if ($data[5] != NULL) {
         $auxCont = $auxCont + 1;
         $where[$auxCont] = '%' . $data[5] . '%';
         $select = $select . '  AND nome_evento ilike ?';
      } else {
         unset($data[5]);
      }
      $select .= " LIMIT 100";
      return $this->getAdapter()->fetchAll($select, $where);
   }
      
   public function buscaEventosAdmin($data) {
      $select = "SELECT id_evento, nome_tipo_evento, nome_evento, validada, data_submissao, nome FROM evento e INNER JOIN pessoa p ON (e.responsavel = p.id_pessoa) INNER JOIN tipo_evento te ON (te.id_tipo_evento = e.id_tipo_evento) WHERE id_encontro = ?";
      $auxCont = 0;
      $where[$auxCont] = $data[0];

      if ($data[1] != NULL) {
         $data[1] = "%" . $data[1] . "%";
         $select = $select . '  AND nome_evento ilike ? ';
         $auxCont = $auxCont + 1;
         $where[$auxCont] = $data[1];
      } else {
         unset($data[1]);
      }

      if ($data[2] != 0) {
         $select = $select . ' AND e.id_tipo_evento = ? ';
         $auxCont = $auxCont + 1;
         $where[$auxCont] = $data[2];
      } else {
         unset($data[2]);
      }

      if ($data[3] != 0) {
         if ($data[3] == 1) {
            $data[3] = 'T';
         } else if ($data[3] == 2) {

            $data[3] = 'F';
         }
         $select = $select . ' AND e.validada = ? ';
         $auxCont = $auxCont + 1;
         $where[$auxCont] = $data[3];
      }

      //$select = $select.' limit 50';

      return $this->getAdapter()->fetchAll($select, $where);
   }
      
   public function buscaEventoPessoa($idEvento) {
      $select = "SELECT id_pessoa, id_evento, nome_tipo_evento, nome_evento, 
            validada, data_submissao, nome, resumo, curriculum, perfil_minimo, 
            descricao_dificuldade_evento, email, preferencia_horario FROM evento e 
            INNER JOIN pessoa p ON (e.responsavel = p.id_pessoa) 
            INNER JOIN tipo_evento te ON (te.id_tipo_evento = e.id_tipo_evento) 
            INNER JOIN dificuldade_evento de ON (de.id_dificuldade_evento = e.id_dificuldade_evento) 
            WHERE e.id_evento = ? ";

      return $this->getAdapter()->fetchAll($select, $idEvento);
   }

   public function validaEvento($idEvento) {
      $select = "UPDATE evento SET validada = 'T' WHERE id_evento = ?";

      return $this->getAdapter()->fetchAll($select, $idEvento);
   }

   public function invalidaEvento($idEvento) {
      $select = "UPDATE evento SET validada = 'F'  WHERE id_evento = ?";

      return $this->getAdapter()->fetchAll($select, $idEvento);
   }

   public function addResponsavel($data) {
      $select = "UPDATE evento SET  responsavel=?  WHERE  id_evento = ?";

      return $this->getAdapter()->fetchAll($select, $data);
   }
   
   public function programacao($id_encontro) {
      $sql = "SELECT er.id_evento, nome_tipo_evento, nome_evento,
         nome, nome_sala, data, hora_inicio, hora_fim, resumo, descricao,
         id_pessoa, twitter FROM evento e 
         INNER JOIN pessoa p ON (e.responsavel = p.id_pessoa) 
         INNER JOIN tipo_evento te ON (te.id_tipo_evento = e.id_tipo_evento)
         INNER JOIN evento_realizacao er on e.id_evento = er.id_evento
         INNER JOIN sala s on er.id_sala = s.id_sala
         WHERE id_encontro = ? and validada = true
         ORDER BY data asc, hora_inicio asc";
      return $this->getAdapter()->fetchAll($sql, array($id_encontro));
   }
}