<?php

class Admin_Model_Pessoa extends Application_Model_Pessoa {

    public function ajaxBuscarEmail($termo, $id_encontro, $id_evento_realizacao) {
        $sql = "SELECT p.id_pessoa as id,
            p.email as text
            FROM pessoa p
            INNER JOIN encontro_participante ep ON p.id_pessoa = ep.id_pessoa
            WHERE p.email LIKE lower(?)
            AND ep.id_encontro = ?
            AND ep.validado = true
            EXCEPT
            SELECT p.id_pessoa as id, p.email as text
            FROM pessoa p
            INNER JOIN evento_participacao ep ON p.id_pessoa = ep.id_pessoa
            WHERE id_evento_realizacao = ?";
        return $this->getAdapter()->fetchAll($sql, array("%{$termo}%", $id_encontro, $id_evento_realizacao));
    }
}
