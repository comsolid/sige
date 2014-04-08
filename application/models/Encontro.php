<?php
class Application_Model_Encontro extends Zend_Db_Table_Abstract {
	
	protected $_name = 'encontro';
	protected $_primary = 'id_encontro';

	/**
	 * @deprecated utilize o arquivo application/configs/application.ini para configurar encontro atual
	 */
	public function getEncontroAtual() {
        $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'staging');
        $id = $config->encontro->codigo;
		$select = $this->select()->where('id_encontro = ?', $id);
		$rows = $this->fetchRow($select);
		return $rows->id_encontro;
	}
   
   /**
    * Retorna o periodo e indica se pode liberar submissão
    * @param type $id_encontro
    * @return type
    */
   public function isPeriodoSubmissao($id_encontro) {
      $sql = "SELECT TO_CHAR(periodo_submissao_inicio, 'DD/MM/YYYY') as periodo_submissao_inicio,
         TO_CHAR(periodo_submissao_fim, 'DD/MM/YYYY') as periodo_submissao_fim,
         (current_date BETWEEN periodo_submissao_inicio
             AND periodo_submissao_fim) AS liberar_submissao
         FROM encontro
         WHERE id_encontro = ?";
      return $this->getAdapter()->fetchRow($sql, array($id_encontro));
   }
}
