<?php

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
   
   public function programacaoParcial($id_encontro) {
      $sql = "SELECT er.id_evento, nome_tipo_evento, nome_evento,
         nome, nome_sala, TO_CHAR(data, 'DD/MM/YYYY') as data,
         TO_CHAR(hora_inicio, 'HH24:MM') as hora_inicio,
         TO_CHAR(hora_fim, 'HH24:MM') as hora_fim, resumo, descricao,
         id_pessoa, twitter, ( SELECT COUNT(*) FROM evento_palestrante ep
            WHERE ep.id_evento = er.id_evento ) as outros, validada
         FROM evento e 
         INNER JOIN pessoa p ON (e.responsavel = p.id_pessoa) 
         INNER JOIN tipo_evento te ON (te.id_tipo_evento = e.id_tipo_evento)
         INNER JOIN evento_realizacao er on e.id_evento = er.id_evento
         INNER JOIN sala s on er.id_sala = s.id_sala
         WHERE id_encontro = ?
         ORDER BY data asc, hora_inicio asc";
      return $this->getAdapter()->fetchAll($sql, array($id_encontro));
   }
}
