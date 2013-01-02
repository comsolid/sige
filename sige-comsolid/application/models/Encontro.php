<?php
class Application_Model_Encontro extends Zend_Db_Table_Abstract {
	protected $_name = 'encontro';
	protected $_primary = 'id_encontro';
	
	public function getEncontroAtual() {

		$select = $this->select()->where('ativo = ?', 'true');
		$rows = $this->fetchAll($select);
		return $rows[0]->id_encontro;
	}
}