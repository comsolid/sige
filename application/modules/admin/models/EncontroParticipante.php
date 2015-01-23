<?php

/**
 * Description of EncontroParticipante
 *
 * @author atila
 */
class Admin_Model_EncontroParticipante extends Zend_Db_Table_Abstract {

   protected $_name = 'encontro_participante';
	protected $_primary = array("id_encontro", "id_pessoa");

   public function relatorioIncricoesPorDia($idEncontro) {
      $sql = "SELECT TO_CHAR(data_cadastro, 'YYYY-MM-DD') AS \"data\", COUNT(*) AS \"num\"
         FROM encontro_participante
         WHERE id_encontro = ?
         GROUP BY TO_CHAR(data_cadastro, 'YYYY-MM-DD')
         ORDER BY TO_CHAR(data_cadastro, 'YYYY-MM-DD') DESC;";
      return $this->getAdapter()->fetchAll($sql, array($idEncontro));
   }

   public function relatorioInscricoesHorario($idEncontro) {
      $sql = "SELECT TO_CHAR(data_cadastro, 'HH24') || 'h' AS horario, COUNT(*) AS num
         FROM encontro_participante
         WHERE id_encontro = ?
         GROUP BY TO_CHAR(data_cadastro, 'HH24')
         ORDER BY TO_CHAR(data_cadastro, 'HH24') DESC;";
      return $this->getAdapter()->fetchAll($sql, array($idEncontro));
   }

   public function relatorioInscricoesSexo($idEncontro) {
      $sql = "SELECT descricao_sexo AS sexo, COUNT(*) AS num
         FROM pessoa p INNER JOIN sexo s ON (s.id_sexo = p.id_sexo)
                       INNER JOIN encontro_participante ep ON (ep.id_pessoa = p.id_pessoa)
         WHERE id_encontro = ?
         GROUP BY descricao_sexo
         ORDER BY COUNT(*) DESC;";
      return $this->getAdapter()->fetchAll($sql, array($idEncontro));
   }

   public function relatorioInscricoesMunicipio($idEncontro, $limit = null) {
      /*$sql = "SELECT nome_municipio AS municipio, COUNT(*) AS num
         FROM encontro_participante ep
         INNER JOIN municipio m ON (m.id_municipio = ep.id_municipio)
         WHERE id_encontro = ?
         GROUP BY nome_municipio
         ORDER BY COUNT(*) DESC
         LIMIT 15;";*/
      $sql = "SELECT nome_municipio AS municipio, COUNT(*) AS num,
			(SELECT COUNT(ep1.id_pessoa) FROM encontro_participante ep1
				 WHERE ep1.id_encontro = ?
				 AND confirmado = true
				 AND ep1.id_municipio =  ep.id_municipio) as confirmados
			FROM encontro_participante ep
			INNER JOIN municipio m ON (m.id_municipio = ep.id_municipio)
			WHERE id_encontro = ?
			GROUP BY nome_municipio, ep.id_municipio
			ORDER BY COUNT(*) DESC";
		if ($limit != null && is_numeric($limit)) {
			$sql .= " LIMIT {$limit} ";
		}
      return $this->getAdapter()->fetchAll($sql, array($idEncontro, $idEncontro));
   }

    public function getTotalUserRegistration() {
        $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'staging');
        $id = $config->encontro->codigo;
        $sql = "SELECT COUNT(ep.id_pessoa)
            FROM pessoa p
            INNER JOIN encontro_participante ep ON (ep.id_pessoa = p.id_pessoa)
            WHERE id_encontro = ?";
        return $this->getAdapter()->fetchCol($sql, array($id));
    }
}

?>
