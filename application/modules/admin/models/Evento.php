<?php

/**
 * Description of Evento
 *
 * @author atila
 */
class Admin_Model_Evento extends Application_Model_Evento {

    public function listarOutrosPalestrantes($idEvento) {
        $sql = "SELECT p.id_pessoa, p.nome, epa.confirmado
            FROM evento_palestrante epa
            INNER JOIN pessoa p ON epa.id_pessoa = p.id_pessoa
            WHERE epa.id_evento = ? ORDER BY p.nome ASC";
        return $this->getAdapter()->fetchAll($sql, $idEvento);
    }

    public function listarHorarios($idEvento) {
        $select = "SELECT evento, descricao, TO_CHAR(data, 'DD/MM/YYYY') AS data,
            TO_CHAR(hora_inicio, 'HH24:MI') as inicio, TO_CHAR(hora_fim, 'HH24:MI') as fim,
            nome_sala FROM evento_realizacao er INNER JOIN sala s ON (er.id_sala = s.id_sala)
            WHERE id_evento = ? ORDER BY data ASC, hora_inicio ASC";
        return $this->getAdapter()->fetchAll($select, $idEvento);
    }

    public function programacaoParcial($id_encontro, $show = 'all') {
        $sql = "SELECT e.id_evento, nome_tipo_evento, nome_evento,
            nome, nome_sala, TO_CHAR(data, 'DD/MM/YYYY') as data,
            TO_CHAR(hora_inicio, 'HH24:MM') as hora_inicio,
            TO_CHAR(hora_fim, 'HH24:MM') as hora_fim, resumo, descricao,
            id_pessoa, twitter, ( SELECT COUNT(*) FROM evento_palestrante ep
            WHERE ep.id_evento = er.id_evento ) as outros, validada
            FROM evento e
            INNER JOIN pessoa p ON (e.responsavel = p.id_pessoa)
            INNER JOIN tipo_evento te ON (te.id_tipo_evento = e.id_tipo_evento)
            LEFT JOIN evento_realizacao er on e.id_evento = er.id_evento
            LEFT JOIN sala s on er.id_sala = s.id_sala
            WHERE id_encontro = ? ";

        if ("valid" === $show) {
            $sql .= " AND validada = TRUE ";
        } else if ("undefined" === $show) {
            $sql .= " AND validada = FALSE ";
        }

        $sql .= "ORDER BY data asc, hora_inicio asc";
        return $this->getAdapter()->fetchAll($sql, array($id_encontro));
    }

    public function getTotalEvents() {
        $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'staging');
        $id = $config->encontro->codigo;

        $sql = "SELECT COUNT(id_evento)
            FROM evento
            WHERE id_encontro = ? AND id_tipo_evento in (1, 2, 3)";
        return $this->getAdapter()->fetchCol($sql, array($id));
    }

    /**
     * Lista eventos mostrados no module admin.
     * @param array $data [ 0: id_encontro ]
     *    Opcionais [ 1: nome_evento, 2: id_tipo_evento, 3: validada ]
     * @return array
     */
    public function buscaEventosAdmin($data) {
        $select = "SELECT id_evento, nome_tipo_evento, nome_evento, validada, data_submissao, nome, email
			FROM evento e INNER JOIN pessoa p ON (e.responsavel = p.id_pessoa)
			INNER JOIN tipo_evento te ON (te.id_tipo_evento = e.id_tipo_evento)
			WHERE id_encontro = ?";
        $auxCont = 0;
        $where[$auxCont] = $data[0];

        if ($data[1] != NULL && $data[4] != NULL) {
            switch ($data[4]) {
                case 'titulo':
                    $column = 'nome_evento';
                    break;
                case 'nome':
                    $column = 'nome';
                    break;
                case 'email':
                    $column = 'email';
                    break;
                default:
                    throw new Exception('Opção de busca não definida.');
                    break;
            }
            $select .= " AND {$column} ILIKE ? ";
            $data[1] = "%" . $data[1] . "%";
            //$select = $select . '  AND nome_evento ilike ? ';
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
}
