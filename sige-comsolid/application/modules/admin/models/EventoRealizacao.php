<?php

/**
 * Description of EventoRealizacao
 *
 * @author atila
 */
class Admin_Model_EventoRealizacao extends Application_Model_EventoRealizacao {
   
   /**
    *
    * @param int $id 
    */
   public function ler($id = 0) {
      $sql = "SELECT er.evento,
               TO_CHAR(er.data, 'DD/MM/YYYY') AS DATA,
               TO_CHAR(er.hora_inicio, 'HH24:MI') AS hora_inicio,
               TO_CHAR(er.hora_fim, 'HH24:MI') AS hora_fim,
               er.descricao,
               s.nome_sala,
               e.nome_evento,
               p.nome
         FROM evento_realizacao er
         INNER JOIN sala s ON er.id_sala = s.id_sala
         INNER JOIN evento e ON er.id_evento = e.id_evento
         INNER JOIN pessoa p ON e.responsavel = p.id_pessoa
         WHERE er.evento = ?";
      $row = $this->getAdapter()->fetchAll($sql, $id);
      if (!$row[0]) {
         throw new Exception("Horário não encontrado.");
         return;
      }
      return $row[0];
   }
}

?>
