<?php

class Admin_Model_EventoParticipacao extends Zend_Db_Table_Abstract {

    protected $_name = 'evento_participacao';

    public function listar($id_evento_realizacao) {
        $sql = "SELECT p.id_pessoa, nome, email
            FROM evento_participacao ep
            INNER JOIN pessoa p ON ep.id_pessoa = p.id_pessoa
            WHERE id_evento_realizacao = ?";
        return $this->getAdapter()->fetchAll($sql, array($id_evento_realizacao));
    }

    /**
     * [adicionarEmMassa description]
     * @param [int] $id_evento_realizacao [description]
     * @param [array] $array_id_pessoas     [description]
     */
    public function adicionarEmMassa($id_evento_realizacao, $array_id_pessoas) {
        $count = 0;
        foreach ($array_id_pessoas as $item) {
            $this->insert(array(
                'id_evento_realizacao' => $id_evento_realizacao,
                'id_pessoa' => $item
            ));
            $count++;
        }
        return $count;
    }
}
