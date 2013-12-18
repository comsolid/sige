<?php

/**
 * Description of Encontro
 *
 * @author atila
 */
class Admin_Model_Encontro extends Application_Model_Encontro {
   
   public function listar() {
      $sql = "SELECT id_encontro, nome_encontro, apelido_encontro,
         TO_CHAR(data_inicio, 'DD/MM/YYYY') as data_inicio,
         TO_CHAR(data_fim, 'DD/MM/YYYY') as data_fim,
         TO_CHAR(periodo_submissao_inicio, 'DD/MM/YYYY') as periodo_submissao_inicio,
         TO_CHAR(periodo_submissao_fim, 'DD/MM/YYYY') as periodo_submissao_fim
         FROM encontro ORDER BY id_encontro DESC LIMIT 10";
      return $this->getAdapter()->fetchAll($sql);
   }
   
   /**
    * Utilização
    *    /admin/encontro/criar
    * @param array $values
    */
   public function criar($values) {
      $param = array(
          $values['nome_encontro'],
          $values['apelido_encontro'],
          $values['data_inicio'],
          $values['data_fim'],
          $values['periodo_submissao_inicio'],
          $values['periodo_submissao_fim'],
      );
      $sql = "INSERT INTO encontro(
            nome_encontro, apelido_encontro, data_inicio, data_fim,
            periodo_submissao_inicio, periodo_submissao_fim)
            VALUES (?, ?,
            TO_DATE(?, 'DD/MM/YYYY'),
            TO_DATE(?, 'DD/MM/YYYY'),
            TO_DATE(?, 'DD/MM/YYYY'),
            TO_DATE(?, 'DD/MM/YYYY')) RETURNING id_encontro";
      $rs = $this->getAdapter()->fetchRow($sql, $param);
      return $rs['id_encontro'];
   }
   
   public function atualizar($values, $id_encontro) {
      $param = array(
          $values['nome_encontro'],
          $values['apelido_encontro'],
          $values['data_inicio'],
          $values['data_fim'],
          $values['periodo_submissao_inicio'],
          $values['periodo_submissao_fim'],
          $id_encontro,
      );
      $sql = "UPDATE encontro
         SET nome_encontro = ?, apelido_encontro = ?,
         data_inicio = TO_DATE(?, 'DD/MM/YYYY'),
         data_fim = TO_DATE(?, 'DD/MM/YYYY'),
         periodo_submissao_inicio = TO_DATE(?, 'DD/MM/YYYY'),
         periodo_submissao_fim = TO_DATE(?, 'DD/MM/YYYY')
       WHERE id_encontro = ?";
      $this->getAdapter()->query($sql, $param);
   }
   
   public function ler($id_encontro) {
      $sql = "SELECT id_encontro, nome_encontro, apelido_encontro,
         TO_CHAR(data_inicio, 'DD/MM/YYYY') as data_inicio,
         TO_CHAR(data_fim, 'DD/MM/YYYY') as data_fim,
         TO_CHAR(periodo_submissao_inicio, 'DD/MM/YYYY') as periodo_submissao_inicio,
         TO_CHAR(periodo_submissao_fim, 'DD/MM/YYYY') as periodo_submissao_fim
       FROM encontro
       WHERE id_encontro = ?";
      return $this->getAdapter()->fetchRow($sql, array($id_encontro));
   }
}
