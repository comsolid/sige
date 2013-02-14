<?php

/**
 * Description of Encontro
 *
 * @author atila
 */
class Admin_Model_Encontro extends Application_Model_Encontro {
   
   public function listar() {
      $sql = "SELECT id_encontro, nome_encontro, apelido_encontro,
         to_char(data_inicio, 'DD/MM/YYYY') as data_inicio,
         to_char(data_fim, 'DD/MM/YYYY') as data_fim
         FROM encontro ORDER BY id_encontro DESC LIMIT 10";
      return $this->getAdapter()->fetchAll($sql);
   }
}

?>
