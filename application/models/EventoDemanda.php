<?php

/**
 * Modelo para tabela "evento_demanda"
 */
class Application_Model_EventoDemanda extends Zend_Db_Table_Abstract {

   protected $_name = 'evento_demanda';
   protected $_sequence = false;
   protected $_primary = array('evento', 'id_pessoa');
   //protected $_dependentTables = array('pessoa', 'evento_realizacao');

   /**
    * @deprecated since version 1.3.0
    * @param type $data
    */
   public function remover($data) {
      $this->delete($data);
   }

	/**
    * Lista eventos de interesse do usuário.
	 * @param array $data [ 0: id_encontro, 1: id_pessoa ]
	 */
   public function listar($data) {
      $select = "SELECT e.id_evento, er.evento, nome_tipo_evento, nome_evento,
         TO_CHAR(data, 'DD/MM/YYYY') as data, TO_CHAR(hora_inicio, 'HH24:MM') AS hora_inicio,
         TO_CHAR(hora_fim, 'HH24:MM') AS hora_fim, validada, nome_sala
         FROM evento_demanda ed INNER JOIN evento_realizacao er ON (ed.evento = er.evento)
         INNER JOIN evento e ON (er.id_evento = e.id_evento)
         INNER JOIN tipo_evento te ON (e.id_tipo_evento = te.id_tipo_evento)
         INNER JOIN sala s ON (er.id_sala = s.id_sala)
         WHERE e.id_encontro = ? AND ed.id_pessoa = ? ORDER BY data ASC, hora_inicio ASC ";

      return $this->getAdapter()->fetchAll($select, $data);
   }

   /**
    * Utilização
    *    /evento/desfazer-interesse
    * 
    * Ler evento para confirmação de desfazer interesse.
    * @param array $data [ 0: id_encontro, 1: id_pessoa, 2: id_evento ]
    */
   public function lerEvento($data) {
      $select = "SELECT ed.evento, nome_tipo_evento, nome_evento,
         TO_CHAR(data, 'DD/MM/YYYY') as data, TO_CHAR(hora_inicio, 'HH24:MM') AS hora_inicio,
         TO_CHAR(hora_fim, 'HH24:MM') AS hora_fim
         FROM evento_demanda ed INNER JOIN evento_realizacao er ON (ed.evento = er.evento)
         INNER JOIN evento e ON (er.id_evento = e.id_evento)
         INNER JOIN tipo_evento te ON (e.id_tipo_evento = te.id_tipo_evento)
         WHERE e.id_encontro = ? AND ed.id_pessoa = ? AND ed.evento = ? ";

      $row = $this->getAdapter()->fetchRow($select, $data);
      if (is_null($row)) {
         throw new Exception("Evento não encontrado.");
      }
      return $row;
   }
}
