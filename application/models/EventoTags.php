<?php

/**
 * Modelo para tabela "evento_tags"
 *
 * @author atila
 */
class Application_Model_EventoTags extends Zend_Db_Table_Abstract {
   
   protected $_name = 'evento_tags';
	protected $_primary = array('id_evento', 'id_tag');
   
   /**
    * Lista tags de um evento.
    * @param int $idEvento
    * @return array
    */
   public function listarPorEvento($idEvento) {
      $sql = "SELECT t.id,
               t.descricao
        FROM evento_tags et
        INNER JOIN tags t ON et.id_tag = t.id
        WHERE et.id_evento = ?";
      return $this->getAdapter()->fetchAll($sql, array($idEvento));
   }
   
   /**
    * Lista todas as tags semelhantes ao valor de $like.
    * @param string $like
    * @return array
    */
   public function listarTags($like) {
      $sql = "SELECT * FROM tags WHERE descricao ILIKE ?";
      return $this->getAdapter()->fetchAll($sql, array("%{$like}%"));
   }
}

?>
