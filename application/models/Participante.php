<?php

/**
 * Modelo para tabela "encontro_participante"
 */
class Application_Model_Participante extends Zend_Db_Table_Abstract {

    protected $_name = 'encontro_participante';
    protected $_sequence = false;
    protected $_primary = array('id_pessoa', 'id_encontro');
    protected $_referenceMap = array(
        array('refTableClass' => 'Application_Model_Pessoa',
            'refColumns' => 'id_pessoa',
            'columns' => 'id_pessoa',
            'onDelete' => self::RESTRICT,
            'onUpdate' => self::RESTRICT),
        array('refTableClass' => 'Application_Model_Encontro',
            'refColumns' => 'id_encontro',
            'columns' => 'id_encontro',
            'onDelete' => self::RESTRICT,
            'onUpdate' => self::RESTRICT));

    protected $_dependentTables = array(
        'pessoa',
        'encontro',
        'municipio',
        'tipo_usuario',
        'caravana',
        'instituicao');

    /**
     * @deprecated use CaravanaEncontro#lerResponsavelCaravana
     */
    public function getMinhasCaravanaResponsavel($data) {
        $select = "SELECT c.id_caravana, apelido_caravana, nome_municipio, apelido_instituicao, p.nome
                  FROM caravana_encontro ce INNER JOIN pessoa p ON (ce.responsavel = p.id_pessoa)
                          INNER JOIN caravana c ON (ce.id_caravana = c.id_caravana)
                     LEFT OUTER JOIN instituicao i ON (c.id_instituicao = i.id_instituicao)
                          INNER JOIN municipio m ON (c.id_municipio = m.id_municipio)
                  WHERE ce.id_encontro = ? AND p.id_pessoa = ?";

        return $this->getAdapter()->fetchAll($select, $data);
    }

    /**
     * Remove usuário da caravana do encontro.
     * @param array $data [ 0: id_encontro, 1: id_pessoa ]
     */
    public function sairDaCaravana($data) {
        $select = "UPDATE encontro_participante SET id_caravana = NULL
         WHERE id_encontro = ? AND id_pessoa = ?";
        $this->getAdapter()->fetchAll($select, $data);
    }

    /**
     * @deprecated since version 1.3.0
     */
    public function excluirMinhaCaravanaResponsavel($data) {
        $select = "DELETE FROM caravana_encontro WHERE id_encontro = ? AND id_caravana = ?";
        return $this->getAdapter()->fetchAll($select, $data);
    }

    /**
     * @deprecated since version 1.3.0
     */
    public function isParticipantes($data) {
        $select = " SELECT id_pessoa FROM pessoa WHERE  email=? ";
        $id = $this->getAdapter()->fetchAll($select, $data);
        if (count($id) > 0) {
            return true;
        }
        return false;
    }

    /**
     * Retorna o certificado de participação do encontro.
     *
     * @param int $id_pessoa
     * @param int $id_encontro
     * @return mixed Zend_Db_Table_Row_Abstract|array ou null, caso não econtre.
     */
    public function listarCertificadosParticipanteEncontro($id_pessoa, $id_encontro = null) {
        $sql = "
        SELECT ep.id_encontro,
            p.id_pessoa,
            UPPER(nome) as nome,
            nome_encontro
        FROM encontro_participante ep
            INNER JOIN pessoa p ON ep.id_pessoa = p.id_pessoa
            INNER JOIN encontro en ON ep.id_encontro = en.id_encontro
        WHERE ep.validado = TRUE
            AND ep.confirmado = TRUE
            AND p.id_pessoa = ?
            AND certificados_liberados = TRUE
            -- AND CURRENT_DATE > en.data_fim + 30
        ";
        if (!is_null($id_encontro)) {
            $sql .= " AND ep.id_encontro = ? ";
            $rs = $this->getAdapter()->fetchAll($sql, array($id_pessoa, $id_encontro));
            if (count($rs) > 0) {
                return $rs[0];
            } else {
                return null;
            }
        }
        return $this->getAdapter()->fetchAll($sql, array($id_pessoa));
    }

    /**
     * Retorna o certificado de participação do evento.
     *
     * @param int $id_pessoa
     * @param int $id_evento
     * @return mixed Zend_Db_Table_Row_Abstract|array ou null, caso não econtre.
     */
    public function listarCertificadosParticipanteEvento($id_pessoa, $id_evento = null) {
        $sql = "
            SELECT
                en.id_encontro,
                e.id_evento,
                p.id_pessoa,
                UPPER(p.nome) as nome,
                en.nome_encontro,
                te.nome_tipo_evento,
                e.nome_evento,
                ROUND(SUM(EXTRACT(epoch FROM er.hora_fim - er.hora_inicio)/3600)::numeric,2) as carga_horaria

            FROM evento_participacao ep
            INNER JOIN evento_realizacao er ON er.evento = ep.id_evento_realizacao
            INNER JOIN evento e ON e.id_evento = er.id_evento
            INNER JOIN tipo_evento te ON te.id_tipo_evento = e.id_tipo_evento
            INNER JOIN encontro_participante enp ON e.id_encontro = enp.id_encontro
            INNER JOIN encontro en ON en.id_encontro = e.id_encontro
            INNER JOIN pessoa p ON p.id_pessoa = ep.id_pessoa

            WHERE
                e.validada = TRUE AND
                e.apresentado = TRUE AND
                enp.validado = TRUE AND
                enp.confirmado = TRUE AND
                certificados_liberados = TRUE AND
                p.id_pessoa = ?
                %%ID_EVENTO%%

            GROUP BY
                en.id_encontro, p.id_pessoa, p.nome, en.nome_encontro,
                e.nome_evento, te.nome_tipo_evento, e.nome_evento, e.id_evento;
        ";
        if (!is_null($id_evento)) {
            $sql = preg_replace("/%%ID_EVENTO%%/", "AND e.id_evento = ?", $sql);
            $rs = $this->getAdapter()->fetchAll($sql, array($id_pessoa, $id_evento));
            if (count($rs) > 0) {
                return $rs[0];
            } else {
                return null;
            }
        }
        $sql = preg_replace("/%%ID_EVENTO%%/", "", $sql);
        return $this->getAdapter()->fetchAll($sql, array($id_pessoa));
    }

    /**
     * Retorna a lista de certificados de palestrante dos eventos que $id_pessoa
     * palestrou ou um certificado específico, caso $id_evento seja especificado.
     *
     * @param int $id_pessoa obtem a partir da sessão e certifica-se que é o palestrante realmente
     * @param int $id_evento evento apresentado.
     * @return mixed Zend_Db_Table_Row_Abstract|array ou null, caso não econtre.
     */
    public function listarCertificadosPalestrante($id_pessoa, $id_evento = null) {
        $sql = "
            SELECT
                e.id_evento,
                enp.id_encontro,
                p.id_pessoa,
                te.nome_tipo_evento,
                e.nome_evento,
                UPPER(p.nome) as nome,
                en.nome_encontro,
		        -- er.hora_fim, er.hora_inicio
                ROUND(SUM(EXTRACT(epoch FROM er.hora_fim - er.hora_inicio)/3600)::numeric,2) as carga_horaria

            FROM evento e
            INNER JOIN pessoa p ON e.responsavel = p.id_pessoa
            INNER JOIN encontro_participante enp ON e.id_encontro = enp.id_encontro
            INNER JOIN tipo_evento te ON te.id_tipo_evento = e.id_tipo_evento
            INNER JOIN encontro en ON e.id_encontro = en.id_encontro
            INNER JOIN evento_realizacao er ON er.id_evento = e.id_evento

            WHERE
                p.id_pessoa = ?
                AND e.validada = TRUE
                AND enp.validado = TRUE
                AND enp.confirmado = TRUE
                AND e.apresentado = TRUE
                AND en.certificados_liberados = TRUE
                %%ID_EVENTO%%

            GROUP BY
                e.id_evento, enp.id_encontro, p.id_pessoa, te.nome_tipo_evento,
                e.nome_evento, p.nome, en.nome_encontro
         ";
        if (!is_null($id_evento)) {
            $sql = preg_replace("/%%ID_EVENTO%%/", "AND e.id_evento = ?", $sql);
            $rs = $this->getAdapter()->fetchAll($sql, array($id_pessoa, $id_evento));
            if (count($rs) > 0) {
                return $rs[0];
            } else {
                return null;
            }
        }
        $sql = preg_replace("/%%ID_EVENTO%%/", "", $sql);
        return $this->getAdapter()->fetchAll($sql, array($id_pessoa));
    }

    public function ler($id_pessoa, $id_encontro) {
       $sql = "SELECT p.id_pessoa, nome, email, apelido, twitter, endereco_internet,
               id_sexo, to_char(nascimento, 'DD/MM/YYYY') as nascimento,
               facebook, bio, slideshare, to_char(cpf, '00000000000') as cpf,
               telefone, id_instituicao, id_municipio
               FROM pessoa p
               INNER JOIN encontro_participante ep ON p.id_pessoa = ep.id_pessoa
               WHERE p.id_pessoa = ? AND id_encontro = ?";
        return $this->getAdapter()->fetchRow($sql, array($id_pessoa, $id_encontro));
    }

    /**
     * Retorna a lista de certificados de palestrante dos eventos que $id_pessoa
     * palestrou ou um certificado específico, caso $id_evento seja especificado.
     *
     * @param int $id_pessoa obtem a partir da sessão e certifica-se que é o palestrante realmente
     * @param int $id_evento evento apresentado.
     * @return mixed Zend_Db_Table_Row_Abstract|array ou null, caso não econtre.
     */
    public function listarCertificadosPalestrantesOutros($id_pessoa, $id_evento = null) {
        $sql = "
            SELECT e.id_evento,
                ep.id_encontro,
                p.id_pessoa,
                te.nome_tipo_evento,
                e.nome_evento,
                UPPER(p.nome) as nome,
                en.nome_encontro,
                -- er.hora_fim, er.hora_inicio
                ROUND(SUM(EXTRACT(epoch FROM er.hora_fim - er.hora_inicio)/3600)::numeric,2) as carga_horaria

            FROM evento e
            INNER JOIN encontro_participante ep ON e.id_encontro = ep.id_encontro
            INNER JOIN evento_palestrante epa ON e.id_evento = epa.id_evento
            INNER JOIN pessoa p ON epa.id_pessoa = p.id_pessoa
            INNER JOIN tipo_evento te ON (te.id_tipo_evento = e.id_tipo_evento)
            INNER JOIN encontro en ON e.id_encontro = en.id_encontro
            INNER JOIN evento_realizacao er ON er.id_evento = e.id_evento

            WHERE
                epa.id_pessoa = ?
                AND e.validada = TRUE
                AND ep.validado = TRUE
                AND ep.confirmado = TRUE
                AND e.apresentado = TRUE
                AND epa.confirmado = TRUE
                AND en.certificados_liberados = TRUE
                %%ID_EVENTO%%

            GROUP BY
                e.id_evento, ep.id_encontro, p.id_pessoa, te.nome_tipo_evento,
                e.nome_evento, p.nome, en.nome_encontro
         ";
        if (!is_null($id_evento)) {
            $sql = preg_replace("/%%ID_EVENTO%%/", "AND e.id_evento = ?", $sql);
            $rs = $this->getAdapter()->fetchAll($sql, array($id_pessoa, $id_evento));
            if (count($rs) > 0) {
                return $rs[0];
            } else {
                return null;
            }
        }
        $sql = preg_replace("/%%ID_EVENTO%%/", "", $sql);
        return $this->getAdapter()->fetchAll($sql, array($id_pessoa));
    }

    /**
     * Retorna a lista de certificados de palestrante dos artigos científicos
     * que $id_pessoa palestrou ou um certificado específico, caso $id_evento
     * seja especificado.
     *
     * @param int $id_pessoa obtem a partir da sessão e certifica-se que é o palestrante realmente
     * @param int $id_evento evento apresentado.
     * @return mixed Zend_Db_Table_Row_Abstract|array ou null, caso não econtre.
     */
    public function listarCertificadosPalestrantesArtigos($id_pessoa, $id_evento = null) {
        $sql = "
            SELECT
                e.id_evento,
                enp.id_encontro,
                p.id_pessoa,
                te.nome_tipo_evento,
                e.nome_evento,
                UPPER(p.nome) as nome,
                en.nome_encontro

            FROM evento e
            INNER JOIN pessoa p ON e.responsavel = p.id_pessoa
            INNER JOIN encontro_participante enp ON e.id_encontro = enp.id_encontro
            INNER JOIN tipo_evento te ON te.id_tipo_evento = e.id_tipo_evento
            INNER JOIN encontro en ON e.id_encontro = en.id_encontro

            WHERE
                p.id_pessoa = ?
                AND te.id_tipo_evento = 4 -- Artigo Científico
                AND e.validada = TRUE
                AND enp.validado = TRUE
                AND enp.confirmado = TRUE
                AND e.apresentado = TRUE
                AND en.certificados_liberados = TRUE
                %%ID_EVENTO%%

            GROUP BY
                e.id_evento, enp.id_encontro, p.id_pessoa, te.nome_tipo_evento,
                e.nome_evento, p.nome, en.nome_encontro
         ";
        if (!is_null($id_evento)) {
            $sql = preg_replace("/%%ID_EVENTO%%/", "AND e.id_evento = ?", $sql);
            $rs = $this->getAdapter()->fetchAll($sql, array($id_pessoa, $id_evento));
            if (count($rs) > 0) {
                return $rs[0];
            } else {
                return null;
            }
        }
        $sql = preg_replace("/%%ID_EVENTO%%/", "", $sql);
        return $this->getAdapter()->fetchAll($sql, array($id_pessoa));
    }

    public function dadosTicketInscricao($id_pessoa, $id_encontro) {
        $sql = "SELECT '+e' || ep.id_encontro || 'p' || p.id_pessoa as inscricao,
            UPPER(nome) as nome,
            nome_encontro,
            to_char(data_inicio, 'TMDD/MM') as data_inicio,
            to_char(data_fim, 'TMDD/MM') as data_fim,
            to_char(horario_inicial, 'HH24:MI') as hora_inicio,
            current_timestamp as timestamp
            FROM encontro_participante ep
            INNER JOIN pessoa p ON ep.id_pessoa = p.id_pessoa
            INNER JOIN encontro en ON ep.id_encontro = en.id_encontro
            INNER JOIN tipo_horario th ON en.id_tipo_horario = th.id_tipo_horario
            WHERE p.id_pessoa = ? AND en.id_encontro = ?";
        return $this->getAdapter()->fetchRow($sql, array($id_pessoa, $id_encontro));
    }
}
