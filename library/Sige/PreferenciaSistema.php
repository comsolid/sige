<?php

/**
 * Description of PreferenciaSistema
 *
 * @author samir
 */
class Sige_PreferenciaSistema extends Zend_Controller_Plugin_Abstract {

    public $encontro;
    
    function __construct() {
        $this->getEncontro();
    }

        public function getEncontro() {
        $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', APPLICATION_ENV);
        try {
            $db = new Zend_Db_Adapter_Pdo_Pgsql(array(
                'host' => $config->resources->db->params->host,
                'port' => $config->resources->db->params->port,
                'username' => $config->resources->db->params->username,
                'password' => $config->resources->db->params->password,
                'dbname' => $config->resources->db->params->dbname
            ));
            $id_encontro = $config->encontro->codigo;
            $sql = "
            SELECT * FROM encontro WHERE id_encontro=? ;
                ";
            $this->encontro = $db->fetchRow($sql, $id_encontro);
        } catch (Exception $e) {
            throw new Exception("Erro ao se conectar com o banco de dados.<br>Detalhes: "
            . $e->getMessage());
        }
    }

}
