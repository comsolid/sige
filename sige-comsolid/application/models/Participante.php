<?php

class Application_Model_Participante extends Zend_Db_Table_Abstract {

   protected $_name = 'encontro_participante';
   protected $_sequence = false;
   protected $_primary = array('id_pessoa', 'id_encontro');
   protected $_referenceMap = array(
       array('refTableClass' => 'Application_Model_Pessoa',
           'refColumns' => 'id_pessoa',
           'columns' => 'id_pessoa',
           'onDelete' => self::RESTRICT,
           'onUpdate' => self::RESTRICT),
       array('refTableClass' => 'Application_Model_Encontro',
           'refColumns' => 'id_encontro',
           'columns' => 'id_encontro',
           'onDelete' => self::RESTRICT,
           'onUpdate' => self::RESTRICT));
   
   protected $_dependentTables = array('pessoa', 'encontro', 'municipio', 'tipo_usuario', 'caravana', 'instituicao');

	/**
	 * @deprecated use CaravanaEncontro#lerParticipanteCaravana
	 */
   public function getMinhaCaravana($data) {
      $select = "SELECT c.id_caravana, apelido_caravana, nome_municipio, apelido_instituicao, p.nome
                     FROM caravana_encontro ce INNER JOIN pessoa p ON (ce.responsavel = p.id_pessoa)
                          INNER JOIN encontro_participante ep ON (ep.id_caravana = ce.id_caravana AND ep.id_encontro = ce.id_encontro)
                          INNER JOIN caravana c ON (ce.id_caravana = c.id_caravana) 
                     LEFT OUTER JOIN instituicao i ON (c.id_instituicao = i.id_instituicao)
                          INNER JOIN municipio m ON (c.id_municipio = m.id_municipio)
                     WHERE ce.id_encontro = ?
                     AND ep.id_pessoa = ?";

      return $this->getAdapter()->fetchAll($select, $data);
   }

	/**
	 * @deprecated use CaravanaEncontro#lerResponsavelCaravana
	 */
   public function getMinhasCaravanaResponsavel($data) {
      $select = "SELECT c.id_caravana, apelido_caravana, nome_municipio, apelido_instituicao, p.nome
                  FROM caravana_encontro ce INNER JOIN pessoa p ON (ce.responsavel = p.id_pessoa)
                          INNER JOIN caravana c ON (ce.id_caravana = c.id_caravana) 
                     LEFT OUTER JOIN instituicao i ON (c.id_instituicao = i.id_instituicao)
                          INNER JOIN municipio m ON (c.id_municipio = m.id_municipio)
                  WHERE ce.id_encontro = ? AND p.id_pessoa = ?";

      return $this->getAdapter()->fetchAll($select, $data);
   }

   public function sairDaCaravana($data) {
      $select = "UPDATE encontro_participante SET id_caravana = NULL WHERE id_encontro = ? AND id_pessoa = ?";
      return $this->getAdapter()->fetchAll($select, $data);
   }

   public function excluirMinhaCaravanaResponsavel($data) {
      $select = "DELETE FROM caravana_encontro WHERE id_encontro = ? AND id_caravana = ?";
      return $this->getAdapter()->fetchAll($select, $data);
   }

   public function isParticipantes($data) {
      $select = " SELECT id_pessoa FROM pessoa WHERE  email=? ";
      $id = $this->getAdapter()->fetchAll($select, $data);
      if (count($id) > 0) {
         return true;
      }
      return false;
   }

   public function listarCertificadosParticipante($idPessoa, $idEncontro = null) {
      $sql = "SELECT ep.id_encontro,
            p.id_pessoa,
            UPPER(nome) as nome,
            nome_encontro
         FROM encontro_participante ep
         INNER JOIN pessoa p ON ep.id_pessoa = p.id_pessoa
         INNER JOIN encontro en ON ep.id_encontro = en.id_encontro
         WHERE ep.validado = TRUE
         AND ep.confirmado = TRUE
         AND p.id_pessoa = ? ";
      if (! is_null($idEncontro)) {
         $sql .= " AND ep.id_encontro = ? ";
         $rs = $this->getAdapter()->fetchAll($sql, array($idPessoa, $idEncontro));
         if (count($rs) > 0) {
            return $rs[0];
         } else {
            return null;
         }
      }
      return $this->getAdapter()->fetchAll($sql, array($idPessoa));
   }

   /**
    *
    * @param int $idPessoa obtem a partir da sessão e certifica-se que é o palestrante realmente
    * @param int $idEvento evento apresentado.
    * @return type 
    */
   public function listarCertificadosPalestrante($idPessoa, $idEvento = null) {
      $sql = "SELECT distinct id_evento,
               ep.id_encontro,
               p.id_pessoa,
               nome_tipo_evento,
               nome_evento,
               UPPER(nome) as nome,
               nome_encontro
         FROM evento e
         INNER JOIN pessoa p ON (e.responsavel = p.id_pessoa)
         INNER JOIN encontro_participante ep ON e.id_encontro = ep.id_encontro
         INNER JOIN tipo_evento te ON (te.id_tipo_evento = e.id_tipo_evento)
         INNER JOIN encontro en ON e.id_encontro = en.id_encontro
         WHERE p.id_pessoa = ?
         AND e.validada = TRUE
         AND ep.validado = TRUE
         AND ep.confirmado = TRUE
         AND e.apresentado = TRUE ";
      if (! is_null($idEvento)) {
         $sql .= " AND e.id_evento = ? ";
         $rs = $this->getAdapter()->fetchAll($sql, array($idPessoa, $idEvento));
         if (count($rs) > 0) {
            return $rs[0];
         } else {
            return null;
         }
      }
      return $this->getAdapter()->fetchAll($sql, array($idPessoa));
   }

   public function listarCertificadosPalestrantesOutros($idPessoa, $idEvento = null) {
      $sql = "SELECT distinct e.id_evento,
               ep.id_encontro,
               p.id_pessoa,
               nome_tipo_evento,
               nome_evento,
               p.nome,
               nome_encontro
         FROM evento e
         INNER JOIN encontro_participante ep ON e.id_encontro = ep.id_encontro
         INNER JOIN evento_palestrante epa ON e.id_evento = epa.id_evento
         INNER JOIN pessoa p ON epa.id_pessoa = p.id_pessoa
         INNER JOIN tipo_evento te ON (te.id_tipo_evento = e.id_tipo_evento)
         INNER JOIN encontro en ON e.id_encontro = en.id_encontro
         WHERE epa.id_pessoa = ?
         AND e.validada = TRUE
         AND ep.validado = TRUE
         AND ep.confirmado = TRUE
         AND e.apresentado = TRUE
         AND epa.confirmado = TRUE ";
      if (! is_null($idEvento)) {
         $sql .= " AND epa.id_evento = ? ";
         $rs = $this->getAdapter()->fetchAll($sql, array($idPessoa, $idEvento));
         if (count($rs) > 0) {
            return $rs[0];
         } else {
            return null;
         }
      }
      return $this->getAdapter()->fetchAll($sql, array($idPessoa));
   }
}
