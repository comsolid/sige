<?php

/**
 * Modelo para tabela "evento_realizacao"
 */
class Application_Model_EventoRealizacao extends Zend_Db_Table_Abstract {

   protected $_name = 'evento_realizacao';
   protected $_primary = 'evento';
   protected $_referenceMap = array(
       array('refTableClass' => 'Application_Model_EventoDemanda',
           'refColumns' => 'evento',
           'columns' => 'evento',
           'onDelete' => self::CASCADE,
           'onUpdate' => self::RESTRICT));

   /**
    *	Retorna nome do evento caso haja eventos no mesmo horário ou entre horários
    * reservados, false caso contrário.
    * @param array $data [ 0: id_encontro, 1: id_sala, 2: data, 3: hora_inicio, 4: hora_fim ]
    * @return mixed Nome do evento caso exista, ou false caso contrário.
    */
   public function existeHorario($data) {
      $sql = "SELECT er.evento
         FROM evento_realizacao er
         INNER JOIN evento e ON er.id_evento = e.id_evento
         WHERE id_encontro = ?
         AND id_sala = ?
         AND data = TO_DATE(?, 'DD/MM/YYYY')
         AND hora_inicio = ?
         AND hora_fim = ?
         OR (? BETWEEN hora_inicio AND hora_fim - '00:01'
            AND id_sala = ?
            AND data = TO_DATE(?, 'DD/MM/YYYY') ) ";
      $where = array(
          $data[0],
          $data[1],
          $data[2],
          $data[3],
          $data[4],
          $data[3],
          $data[1],
          $data[2]
      );
      $rs = $this->getAdapter()->fetchAll($sql, $where);
      if (count($rs) > 0) {
         return $rs[0]['evento'];
      }
      return false;
   }

}