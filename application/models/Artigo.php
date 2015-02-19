<?php

class Application_Model_Artigo extends Zend_Db_Table_Abstract {

    protected $_name = 'artigo';
    protected $_primary = 'id_artigo';

    /**
     * Utilização
     *    /evento/enviar-artigo
     */
    public function inserirDocumento($dados, $nomearquivo_original, $tamanho, $responsavel, $id_encontro, $titulo) {
        $sql = "INSERT INTO {$this->_name} (dados, criado, nomearquivo_original, tamanho, responsavel, id_encontro, titulo)
            VALUES (decode(?, 'hex'), now(), ?, ?, ?, ?, ?) RETURNING id_artigo; ";
        return $this->getAdapter()->fetchOne($sql, array($dados, $nomearquivo_original, $tamanho, $responsavel, $id_encontro, $titulo));
    }

    /**
     * Utilização
     *    /evento/index -> /submissao
     * @param type $id_artigo
     * @return type
     */
    public function getArtigo($id_artigo) {
        $sql = "SELECT encode(dados, 'base64') as dados,
            nomearquivo_original, responsavel
            FROM {$this->_name}
            WHERE id_artigo = ?";
        return $this->getAdapter()->fetchRow($sql, array($id_artigo));
    }

    public function listarArtigosParticipante($id_encontro, $responsavel) {
        $sql = "
            SELECT 
                nomearquivo_original, tamanho, dados, 
                TO_CHAR(criado, 'DD/MM/YYYY HH24:MI:SS') as criado,
                responsavel, id_encontro, id_artigo, titulo
            FROM {$this->_name} 
            WHERE 
                responsavel = ? 
                AND id_encontro = ? 
        ";
        return $this->getAdapter()->fetchAll($sql, array($responsavel, $id_encontro));
    }

    /**
     * Verifica se o artigo pertence ao usuário logado ou se o usuário é admin.
     * Utilização
     * 
     * @param int $id_artigo
     * @param int $responsavel
     * @return bool
     */
    public function temPermissao($id_artigo, $responsavel) {
        $sql = "
            SELECT EXIST(
                SELECT *
                FROM artigo
                WHERE id_artigo = ? AND responsavel = ?
            )";
        return $this->getAdapter()->fetchOne($sql, array($id_artigo, $responsavel));
    }

    /**
     * Obtem todos os artigos de um determinado encontro ou de um conjunto 
     * específico de encontros.
     * @param int|array $id_encontro
     * @param bool $status
     * @return assoc array
     */
    public function buscaArtigos($id_encontro, $status = "todos") {
        $encontros_array = array();
        if (!is_array($id_encontro)) {
            array_push($encontros_array, $id_encontro);
        } else {
            $encontros_array = $id_encontro;
        }

        $where_id_encontro = null;
        $ultimo = end($encontros_array);
        foreach ($encontros_array as $id) {
            if ($ultimo == $id) {
                $where_id_encontro .= "artigo.id_encontro = ?";
            } else {
                $where_id_encontro .= "artigo.id_encontro = ? OR ";
            }
        }

        if ($status === "validados") {
            $where_validados = "AND validada = 't'";
        } elseif ($status === "nao-validados") {
            $where_validados = "AND validada = 'f'";
        } else {
            $where_validados = null;
        }

        $sql = "
            SELECT DISTINCT
                nome, email, nomearquivo_original, tamanho, 
                encode(dados, 'base64') as dados, validada, 
                TO_CHAR(criado, 'DD/MM/YYYY HH24:MI:SS') as criado,
                artigo.responsavel, artigo.id_encontro, artigo.id_artigo, 
                titulo, evento.id_evento, encontro.apelido_encontro
            FROM {$this->_name}, evento, pessoa, encontro
            WHERE 
                evento.id_artigo = artigo.id_artigo AND 
                pessoa.id_pessoa = artigo.responsavel AND 
                encontro.id_encontro = artigo.id_encontro AND (
                {$where_id_encontro}
                ) {$where_validados}
            ORDER BY encontro.apelido_encontro ASC, nome ASC
        ";
        return $this->getAdapter()->fetchAll($sql, $encontros_array);
    }

}
