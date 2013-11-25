<?php

/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 * Description of Evento
 *
 * @author atila
 */
class Admin_Model_Evento extends Application_Model_Evento {
   
   public function listarOutrosPalestrantes($idEvento) {
      $sql = "SELECT p.id_pessoa, p.nome, epa.confirmado
         FROM evento_palestrante epa
         INNER JOIN pessoa p ON epa.id_pessoa = p.id_pessoa
         WHERE epa.id_evento = ?";
      return $this->getAdapter()->fetchAll($sql, $idEvento);
   }
   
   public function listarHorarios($idEvento) {
      $select = "SELECT evento, descricao, TO_CHAR(data, 'DD/MM/YYYY') AS data,
         TO_CHAR(hora_inicio, 'HH24:MI') as inicio, TO_CHAR(hora_fim, 'HH24:MI') as fim,
         nome_sala FROM evento_realizacao er INNER JOIN sala s ON (er.id_sala = s.id_sala)
         WHERE id_evento = ?";
      return $this->getAdapter()->fetchAll($select, $idEvento);
   }
}

?>
