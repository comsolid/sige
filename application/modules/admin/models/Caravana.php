<?php

class Admin_Model_Caravana extends Application_Model_Caravana {

	public function buscar($idEncontro = 0, $termo = "") {
		$sql = "SELECT c.id_caravana, nome_caravana, apelido_caravana, nome, 
			nome_municipio, apelido_instituicao, validada,
				 ( SELECT sum( CASE WHEN id_sexo = 1 THEN 1 ELSE 0 END )
					FROM pessoa p INNER JOIN encontro_participante ep ON p.id_pessoa = ep.id_pessoa
					INNER JOIN caravana_encontro ce ON ep.id_caravana = ce.id_caravana
					WHERE ep.id_encontro = ? AND c.id_caravana = ce.id_caravana ) AS num_h,
				 ( SELECT sum( CASE WHEN id_sexo = 2 THEN 1 ELSE 0 END )
					FROM pessoa p INNER JOIN encontro_participante ep on p.id_pessoa = ep.id_pessoa
					INNER JOIN caravana_encontro ce ON ep.id_caravana = ce.id_caravana
					WHERE ep.id_encontro = ? AND c.id_caravana = ce.id_caravana ) AS num_m
			FROM caravana_encontro ce INNER JOIN caravana c ON (ce.id_caravana = c.id_caravana)
			INNER JOIN municipio m ON (c.id_municipio = m.id_municipio)
			INNER JOIN pessoa p ON (ce.responsavel = p.id_pessoa)
			LEFT OUTER JOIN instituicao i ON (c.id_instituicao = i.id_instituicao)
			WHERE ce.id_encontro = ? ";
		if ($idEncontro == 0) {
			throw new Exception("Encontro não encontrado.");
		}

		$where = array($idEncontro, $idEncontro, $idEncontro);
		if (! empty($termo)) {
			$sql .= " AND nome_caravana ilike ? ";
			$where[] = "%{$termo}%";
		}

		$sql .= "GROUP BY c.id_caravana, nome_caravana,
			apelido_caravana, nome, nome_municipio, apelido_instituicao, validada";
		return $this->getAdapter()->fetchAll($sql, $where);
	}
}