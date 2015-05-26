<?php

/**
 *
 */
class Admin_Model_MudarEmail extends Application_Model_MudarEmail {

    public function listar() {
        $sql = "
            SELECT id, email_anterior, novo_email, motivo,
            to_char(data_submissao, 'DD/MM/YYYY HH24:MI:SS') as data_submissao,
            to_char(ultima_atualizacao, 'DD/MM/YYYY HH24:MI:SS') as ultima_atualizacao,
            atualizado_por, nome, status::varchar
            FROM pessoa_mudar_email pme
            LEFT JOIN pessoa p ON pme.atualizado_por = p.id_pessoa
            ORDER BY status NULLS FIRST, data_submissao DESC
        ";
        return $this->getAdapter()->fetchAll($sql);
    }

    public function trocarEmail($email_anterior, $novo_email) {
        $sql = "UPDATE pessoa SET email = ? WHERE email = ?";
        $this->getAdapter()->query($sql, array($novo_email, $email_anterior));
    }
}
