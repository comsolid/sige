<?php

/**
 * Modelo para tabela "evento"
 */
class Application_Model_Evento extends Zend_Db_Table_Abstract {

    protected $_name = 'evento';
    protected $_primary = 'id_evento';
    protected $_referenceMap = array(
		array(
			'refTableClass' => 'Application_Model_EventoRealizacao',
			'refColumns' => 'id_evento',
			'columns' => 'id_evento',
			'onDelete' => self::CASCADE, 'onUpdate' => self::RESTRICT
		),
	);

	/**
     * @deprecated since version 1.2.2
     * @param type $idEncontro
     * @return type
     */
    public function getEventos($idEncontro) {
        $select = "SELECT DISTINCT(TO_CHAR(data, 'DD/MM/YYYY')) AS data FROM evento e
			INNER JOIN evento_realizacao er ON (e.id_evento = er.id_evento)
			WHERE id_encontro = ? ORDER BY TO_CHAR(data, 'DD/MM/YYYY')";
        return $this->getAdapter()->fetchAll($select, $idEncontro);
    }

    /**
     * Lista de datas onde há eventos no encontro.
     * @param int $idEncontro id do encontro atual
     * @return array
     */
    public function listarDiasDoEncontro($idEncontro) {
        $select = "SELECT DISTINCT(TO_CHAR(data, 'DD/MM/YYYY')) AS data FROM evento e
			INNER JOIN evento_realizacao er ON (e.id_evento = er.id_evento)
			WHERE id_encontro = ? ORDER BY TO_CHAR(data, 'DD/MM/YYYY')";
        return $this->getAdapter()->fetchAll($select, $idEncontro);
    }

    /**
     * Lista eventos do encontro, retirando os eventos do usuário logado.
     * Pode filtrar por data, tipo do evento ou parte do nome do evento.
     * TODO: melhorar passagem de parametro e forma com que parametros são tratados.
     * @param array $data [ 0: id_encontro, 1: !responsavel, 2: id_pessoa ]
     *    Opcionais [ 3: data, 4: id_tipo_evento, 5: nome_evento ]
     * @return array
     */
    public function buscaEventos($data) {
        $select = "SELECT er.evento, nome_tipo_evento, nome_evento,
         TO_CHAR(data, 'DD/MM/YYYY') as data, TO_CHAR(hora_inicio, 'HH24:MM') AS h_inicio,
         TO_CHAR(hora_fim, 'HH24:MI') AS h_fim, er.descricao
         FROM evento_realizacao er
         INNER JOIN evento e ON (er.id_evento = e.id_evento)
         INNER JOIN tipo_evento te ON (e.id_tipo_evento = te.id_tipo_evento)
         INNER JOIN pessoa p ON e.responsavel = p.id_pessoa
         WHERE e.id_encontro = ? AND e.validada AND e.responsavel <> ? AND evento
            NOT IN (SELECT evento FROM evento_demanda WHERE id_pessoa = ?) ";
        $auxCont = 0;
        $where[$auxCont] = $data[0];
        $auxCont++;
        $where[$auxCont] = $data[1];
        $auxCont++;
        $where[$auxCont] = $data[2];
        if ($data[3] != 'todas') {
            $select = $select . " AND data = to_date(?, 'DD/MM/YYYY') ";
            $auxCont = $auxCont + 1;
            $where[$auxCont] = $data[3];
        } else {
            unset($data[3]);
        }
        if ($data[4] > 0) {
            $auxCont = $auxCont + 1;
            $where[$auxCont] = $data[4];
            $select = $select . ' AND te.id_tipo_evento = ? ';
        } else {
            unset($data[4]);
        }
        if ($data[5] != NULL) {
            $auxCont = $auxCont + 1;
            $where[$auxCont] = '%' . $data[5] . '%';
            $select = $select . '  AND nome_evento ILIKE ? ';
        } else {
            unset($data[5]);
        }
        $select .= " LIMIT 100";
        return $this->getAdapter()->fetchAll($select, $where);
    }

    /**
     * Lista eventos mostrados no module admin.
     * @param array $data [ 0: id_encontro ]
     *    Opcionais [ 1: nome_evento, 2: id_tipo_evento, 3: validada ]
     * @return array
     */
    public function buscaEventosAdmin($data) {
        $select = "SELECT id_evento, nome_tipo_evento, nome_evento, validada, data_submissao, nome
			FROM evento e INNER JOIN pessoa p ON (e.responsavel = p.id_pessoa)
			INNER JOIN tipo_evento te ON (te.id_tipo_evento = e.id_tipo_evento)
			WHERE id_encontro = ?";
        $auxCont = 0;
        $where[$auxCont] = $data[0];

        if ($data[1] != NULL) {
            $data[1] = "%" . $data[1] . "%";
            $select = $select . '  AND nome_evento ilike ? ';
            $auxCont = $auxCont + 1;
            $where[$auxCont] = $data[1];
        } else {
            unset($data[1]);
        }

        if ($data[2] != 0) {
            $select = $select . ' AND e.id_tipo_evento = ? ';
            $auxCont = $auxCont + 1;
            $where[$auxCont] = $data[2];
        } else {
            unset($data[2]);
        }

        if ($data[3] != 0) {
            if ($data[3] == 1) {
                $data[3] = 'T';
            } else if ($data[3] == 2) {

                $data[3] = 'F';
            }
            $select = $select . ' AND e.validada = ? ';
            $auxCont = $auxCont + 1;
            $where[$auxCont] = $data[3];
        }

        //$select = $select.' limit 50';
        return $this->getAdapter()->fetchAll($select, $where);
    }

    /**
     * Lista todos os detalhes do evento.
     * TODO: retornar apenas elemento 0 do array! Tem impacto grande, verifique todos os usos.
     * @param int $idEvento
     * @return array
     */
    public function buscaEventoPessoa($idEvento) {
        $select = "
            SELECT
                id_pessoa, id_evento, nome_tipo_evento, nome_evento, validada,
                TO_CHAR(data_submissao, 'DD/MM/YYYY HH24:MI') as data_submissao,
                nome, resumo, tecnologias_envolvidas, perfil_minimo,
                descricao_dificuldade_evento, email, preferencia_horario, bio,
                apresentado, e.id_tipo_evento, id_artigo
            FROM evento e
            INNER JOIN pessoa p ON (e.responsavel = p.id_pessoa)
            INNER JOIN tipo_evento te ON (te.id_tipo_evento = e.id_tipo_evento)
            INNER JOIN dificuldade_evento de ON (de.id_dificuldade_evento = e.id_dificuldade_evento)
            WHERE e.id_evento = ? ";

        return $this->getAdapter()->fetchRow($select, $idEvento);
    }

    /**
     * @deprecated
     */
    public function validaEvento($idEvento) {
        $select = "UPDATE evento SET validada = 'T' WHERE id_evento = ?";
        return $this->getAdapter()->fetchAll($select, $idEvento);
    }

    /**
     * @deprecated
     */
    public function invalidaEvento($idEvento) {
        $select = "UPDATE evento SET validada = 'F'  WHERE id_evento = ?";
        return $this->getAdapter()->fetchAll($select, $idEvento);
    }

    /**
     * @deprecated
     */
    public function addResponsavel($data) {
        $select = "UPDATE evento SET  responsavel=?  WHERE  id_evento = ?";
        return $this->getAdapter()->fetchAll($select, $data);
    }

    /**
     * Lista a programação básica dos eventos.
     * @param int $id_encontro
     * @return array
     */
    public function programacao($id_encontro) {
        $sql = "SELECT er.id_evento, nome_tipo_evento, nome_evento,
         nome, nome_sala, TO_CHAR(data, 'DD/MM/YYYY') as data,
         TO_CHAR(hora_inicio, 'HH24:MI') as hora_inicio,
         TO_CHAR(hora_fim, 'HH24:MI') as hora_fim, resumo, descricao,
         id_pessoa, twitter, ( SELECT COUNT(*) FROM evento_palestrante ep
            WHERE ep.id_evento = er.id_evento ) as outros,
            TO_CHAR(data, 'DDMM') as dia_mes
         FROM evento e
         INNER JOIN pessoa p ON (e.responsavel = p.id_pessoa)
         INNER JOIN tipo_evento te ON (te.id_tipo_evento = e.id_tipo_evento)
         INNER JOIN evento_realizacao er on e.id_evento = er.id_evento
         INNER JOIN sala s on er.id_sala = s.id_sala
         WHERE id_encontro = ? and validada = true
         ORDER BY data asc, hora_inicio asc";
        return $this->getAdapter()->fetchAll($sql, array($id_encontro));
    }

    public function programacaoTv($id_encontro) {
        $sql = "SELECT evento, descricao, data, nome_sala as local,
        TO_CHAR(hora_inicio, 'HH24:MI') as hora_inicial,
        TO_CHAR(hora_fim, 'HH24:MI') as hora_final,
            nome_evento as titulo, te.nome_tipo_evento as tipo, nome as palestrante
            FROM evento_realizacao er
            INNER JOIN evento e ON er.id_evento = e.id_evento
            INNER JOIN tipo_evento te ON e.id_tipo_evento = te.id_tipo_evento
            INNER JOIN pessoa p ON e.responsavel = p.id_pessoa
            INNER JOIN sala s ON er.id_sala = s.id_sala
            WHERE id_encontro = ? and validada = true
            AND data = current_date and current_timestamp::time + interval '10 minutes' between hora_inicio and hora_fim
            ORDER BY data ASC, hora_inicio ASC";
        return $this->getAdapter()->fetchAll($sql, array($id_encontro));
    }

    public function programacaoTimeline($id_encontro) {
        $sql = "SELECT evento, descricao, data, nome_sala as local,
        TO_CHAR(hora_inicio, 'HH24:MI') as hora_inicial,
        TO_CHAR(hora_fim, 'HH24:MI') as hora_final,
            nome_evento as titulo, te.nome_tipo_evento as tipo, nome as palestrante
            FROM evento_realizacao er
            INNER JOIN evento e ON er.id_evento = e.id_evento
            INNER JOIN tipo_evento te ON e.id_tipo_evento = te.id_tipo_evento
            INNER JOIN pessoa p ON e.responsavel = p.id_pessoa
            INNER JOIN sala s ON er.id_sala = s.id_sala
            WHERE id_encontro = ? and validada = true
            ORDER BY data ASC, hora_inicio ASC";
        return $this->getAdapter()->fetchAll($sql, array($id_encontro));
    }

    /**
     * Adiciona palestrantes a um evento, retornando o número de linhas afetadas
     * para contar quantos realmente foram adicionados.
     * @param int $idEvento
     * @param int $idPessoa
     * @return int número de linhas afetadas.
     */
    public function adicionarPalestranteEvento($idEvento = 0, $idPessoa = 0) {
        if ($idEvento > 0 and $idPessoa > 0) {
            return $this->getAdapter()->insert("evento_palestrante", array(
                        'id_evento' => $idEvento,
                        'id_pessoa' => $idPessoa
            ));
        }
        return 0; // nenhuma linha afetada.
    }

    /**
     * Lista outros palestrantes de um evento, se houver.
     * @param int $idEvento
     * @return array
     */
    public function buscarOutrosPalestrantes($idEvento) {
        $sql = "SELECT p.id_pessoa, p.nome, p.twitter, p.apelido
               FROM evento_palestrante ep
               INNER JOIN pessoa p ON ep.id_pessoa = p.id_pessoa
               WHERE ep.id_evento = ?";
        return $this->getAdapter()->fetchAll($sql, array($idEvento));
    }

    /**
     * Utilização
     *    /evento/index mapeado como /submissao
     * @param int $id_encontro
     * @param int $responsavel
     * @return array
     */
    public function listarEventosParticipante($id_encontro, $responsavel) {
        $sql = "SELECT id_evento, nome_evento, validada, resumo,
                TO_CHAR(data_submissao, 'DD/MM/YYYY HH24:MI') as data_submissao,
                nome_tipo_evento, e.id_tipo_evento, id_artigo
            FROM evento e
            INNER JOIN tipo_evento te ON e.id_tipo_evento = te.id_tipo_evento
            WHERE id_encontro = ?
            AND responsavel = ?";
        return $this->getAdapter()->fetchAll($sql, array($id_encontro, $responsavel));
    }

    /**
     * Verifica se o evento pertence ao usuário logado ou se o usuário é admin.
     * Utilização
     *
     * @param int $id_evento
     * @param int $responsavel
     * @return bool
     */
    public function temPermissao($id_evento, $responsavel) {
        $sql = "
            SELECT EXIST(
                SELECT *
                FROM evento e
                WHERE id_evento = ? AND responsavel = ?
            )";
        return $this->getAdapter()->fetchOne($sql, array($id_evento, $responsavel));
    }

    public function getResponsavel($id_evento) {
        return $this->getAdapter()->fetchOne("SELECT responsavel FROM evento WHERE id_evento = ?", $id_evento);
    }

    public function deletarEvento($id_evento) {
        $db = $this->getAdapter();
        try {
            $db->beginTransaction();
            $db->delete("evento_realizacao", $this->getAdapter()->quoteInto("id_evento = ?", $id_evento));
            $db->delete("evento", $this->getAdapter()->quoteInto("id_evento = ?", $id_evento));
            $db->commit();
        } catch (Exception $ex) {
            $db->rollBack();
            throw $ex;
        }
    }

    public function deletarArtigo($id_evento, $id_artigo) {
        $db = $this->getAdapter();
        try {
            $db->beginTransaction();
            $db->delete("evento_realizacao", $this->getAdapter()->quoteInto("id_evento = ?", $id_evento));
            $db->delete("evento", $this->getAdapter()->quoteInto("id_evento = ?", $id_evento));
            $db->delete("artigo", $this->getAdapter()->quoteInto("id_artigo = ?", $id_artigo));
            $db->commit();
        } catch (Exception $ex) {
            $db->rollBack();
            throw $ex;
        }
    }

}
