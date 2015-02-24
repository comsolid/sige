<?php

class Application_Model_Encontro extends Zend_Db_Table_Abstract {

    protected $_name = 'encontro';
    protected $_primary = 'id_encontro';

    /**
     * @deprecated utilize o arquivo application/configs/application.ini para configurar encontro atual
     */
    public function getEncontroAtual() {
        $select = $this->select()->where('ativo = ?', 'true');
        $rows = $this->fetchAll($select);
        return $rows[0]->id_encontro;
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

    /**
     * Retorna todos os encontros do dado ano
     * @param int $ano
     * @return assoc array
     */
    public function buscaEncontrosPorAno($ano) {
        $sql = "
            SELECT *
            FROM encontro
            WHERE EXTRACT(YEAR FROM data_inicio) = ?
         ";
        return $this->getAdapter()->fetchAll($sql, $ano);
    }

    /**
     * Retorna o encontro pelo id
     * @param int $id_encontro
     * @return assoc array
     */
    public function buscaEncontro($id_encontro) {
        $sql = "
            SELECT *
            FROM encontro
            WHERE id_encontro = ?
         ";
        return $this->getAdapter()->fetchRow($sql, $id_encontro);
    }

    /**
     * Retorna o encontro pelo id com o nome do municipio.
     * @param int $id_encontro
     * @return assoc array
     */
    public function buscaComMunicipio($id_encontro) {
        $sql = "
            SELECT e.*, nome_municipio
            FROM encontro e
            INNER JOIN municipio m ON m.id_municipio = e.id_municipio
            WHERE id_encontro = ?
         ";
        return $this->getAdapter()->fetchRow($sql, $id_encontro);
    }

}
