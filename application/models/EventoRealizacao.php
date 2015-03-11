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
    * Retorna nome do evento caso haja eventos no mesmo horário ou entre horários
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

    public function listarHorariosPorEvento($id_evento) {
        $sql = "SELECT to_char(data, 'DD \"de\" TMMon') as data, to_char(hora_inicio, 'HH24:MI') as hora_inicio,
                to_char(hora_fim, 'HH24:MI') as hora_fim, descricao, nome_sala
                FROM evento_realizacao er
                INNER JOIN sala s ON er.id_sala = s.id_sala
                WHERE id_evento = ?
                ORDER BY data, hora_inicio";
        return $this->getAdapter()->fetchAll($sql, array($id_evento));
    }

    /**
     * Utilização
     *    
     * @param array $values
     */
    public function criar($values) {
        $param = array(
            $values['id_evento'],
            $values['id_sala'],
            $values['data'],
            $values['hora_inicio'],
            $values['hora_fim'],
            $values['descricao'],
        );
        $sql = "
            INSERT INTO {$this->_name} (
                id_evento, id_sala, data, hora_inicio, hora_fim, descricao
            ) VALUES (
            ?, 
            ?,
            TO_DATE(?, 'DD/MM/YYYY'),
            ?,
            ?, 
            ?
            ) RETURNING evento; ";
        $resultset = $this->getAdapter()->fetchRow($sql, $param);
        return $resultset['evento'];
    }

    /**
     * Utilização
     *    
     * @param array $values
     */
    public function atualizar($values, $evento) {
        $param = array(
            $values['id_sala'],
            $values['data'],
            $values['hora_inicio'],
            $values['hora_fim'],
            $values['descricao'],
            $evento,
        );
        $sql = "
            UPDATE {$this->_name} SET
                id_sala=?, 
                data=TO_DATE(?, 'DD/MM/YYYY'),
                hora_inicio=?,
                hora_fim=?,
                descricao=?
            WHERE evento = ? ";
        return $this->getAdapter()->query($sql, $param);
    }

}
