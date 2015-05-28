<?php

define("TOKEN_BYTE_SIZE", 24);
define("TOKEN_VALIDADE", "24 hours");

class Application_Model_Pessoa extends Zend_Db_Table_Abstract {

	protected $_name = 'pessoa';
	protected $_primary = 'id_pessoa';

	protected $_referenceMap = array(
        array(
			'refTableClass' => 'Application_Model_Participante',
            'refColumns' => 'id_pessoa',
            'columns' => 'id_pessoa',
            'onDelete'=> self::CASCADE,
            'onUpdate'=> self::RESTRICT
		),
        array(
			'refTableClass' => 'Application_Model_Evento',
            'refColumns' => 'responsavel',
            'columns' => 'id_pessoa',
            'onDelete'=> self::CASCADE,
            'onUpdate'=> self::RESTRICT
		),
        array(
			'refTableClass' => 'Application_Model_EventoDemanda',
            'refColumns' => 'id_pessoa',
            'columns' => 'id_pessoa',
            'onDelete'=> self::CASCADE,
            'onUpdate'=> self::RESTRICT
		),
    );

	/**
	 * @deprecated
	 * @param [type] $email [description]
	 */
	public function gerarSenha($email) {
	   try {
			$qryIsValid = $this->getAdapter()->quoteInto("SELECT funcGerarSenha(?) AS c ", $email);
			$senha = $this->getAdapter()->query($qryIsValid)->fetch();
			return $senha['c'];
		}catch (Exception $ex) {
		}
	}

	/**
	 * Verifica validade do token existente. Retorna o token caso esteja válido,
	 * gera um novo caso contrário.
	 * @param [type] $id_pessoa [description]
	 */
	public function gerarToken($id_pessoa) {
        $result = $this->obterTokenDoBanco($id_pessoa);
        if ($result['token_valido']) {
			$result['hashedToken'] = $this->gerarHash($result['token']);
        } else {
            $result = array();
			$result['token'] = $this->gerarNovoToken();
			$result['hashedToken'] = $this->gerarHash($result['token']);
        }

		$this->gravarTokenNoBanco($result['token'], $id_pessoa);
		return $result;
    }

	private function gravarTokenNoBanco($token, $id_pessoa) {
		$sql = "
            UPDATE {$this->_name}
                SET token = ?,
                token_validade = NOW() + '" . TOKEN_VALIDADE . "'
            WHERE id_pessoa = ?
        ";
        return $this->getAdapter()->query($sql, array($token, $id_pessoa));
    }

	private function gerarHash($str) {
        return hash('sha256', $str);
    }

	private function obterTokenDoBanco($id_pessoa) {
		$sql = "
			SELECT token, current_timestamp < token_validade as token_valido
			FROM {$this->_name}
			WHERE id_pessoa = ?
		";
        return $this->getAdapter()->fetchRow($sql, array($id_pessoa));
    }

	private function gerarNovoToken() {
        return base64_encode(mcrypt_create_iv(TOKEN_BYTE_SIZE));
    }

	public function verificarToken($id_pessoa, $hashedToken) {
        $result = $this->obterTokenDoBanco($id_pessoa);
        $hashVerificacao = $this->gerarHash($result['token']);
        if ($hashedToken !== $hashVerificacao) {
            throw new Exception(_("Verification Token to Recover Password invalid or doesn't exists."));
        }

        if (!$result['token_valido']) {
            throw new Exception(_("Verification Token to Recover Password expired. Try again accessing Forgot My Password."));
        }
        return TRUE;
    }

	public function resetarToken($id_pessoa) {
        $where = $this->getAdapter()->quoteInto('id_pessoa = ?', $id_pessoa);
        $this->update(array(
            'token' => null,
            'token_validade' => null
        ), $where);
    }

	/**
	 * A partir da senha informada gera um hash blowfish e salva o valor
	 * Utilização
	 * 		/index/definir-senha
	 * 		/participante/alterar-senha
	 * @param [int] $id_pessoa [description]
	 * @param [string] $senha     [description]
	 */
	public function setNovaSenha($id_pessoa, $senha) {
        $db = $this->getAdapter();
        $where = $db->quoteInto('id_pessoa = ?', $id_pessoa);

		$lib = new PasswordLib\PasswordLib();
		$hash = $lib->createPasswordHash($senha);

        $this->update(array('senha' => $hash), $where);
    }

	/**
	 * Utilização
	 * 	/login
	 * 	/participante/alterar-senha
	 */
	public function avaliaLogin($login, $senha) {
    	$sql = "SELECT id_pessoa, administrador, apelido, senha,
        	twitter, cadastro_validado
        	FROM pessoa WHERE email = ?";
    	$where = array($login);
		$result = $this->getAdapter()->fetchRow($sql, $where);

		$lib = new PasswordLib\PasswordLib();
		$verified = $lib->verifyPasswordHash($senha, $result['senha']);
		if ($verified) {
			return $result;
		}
		return NULL;
	}

	public function buscaPessoas($data){
		 $select="SELECT p.id_pessoa, p.nome, p.cadastro_validado, apelido, email, twitter,
			nome_municipio, apelido_instituicao, nome_caravana, ep.confirmado
			FROM encontro_participante ep INNER JOIN pessoa p ON (ep.id_pessoa = p.id_pessoa)
			LEFT OUTER JOIN instituicao i ON (ep.id_instituicao = i.id_instituicao)
			INNER JOIN municipio m ON (ep.id_municipio = m.id_municipio)
			LEFT OUTER JOIN caravana c ON (ep.id_caravana = c.id_caravana)
			WHERE id_encontro = ? ";

		if ($data[2] == "nome") {
			if ($data[1] != NULL) {
				$data[1] = "%" . $data[1] . "%";
	        	$select = $select . ' AND p.nome ilike ? ';
			} else {
				unset($data[1]);
			}
		} else if ($data[2] == "municipio") {
			if($data[1] != NULL){
				$data[1] = "%" . $data[1] . "%";
	         	$select = $select . ' AND nome_municipio ilike ? ';
			}else{
				unset($data[1]);
			}
		} else if ($data[2] == "caravana") {
			if ($data[1] != NULL) {
				$data[1] = "%" . $data[1] . "%";
	        	$select = $select . ' AND nome_caravana ilike ? ';
			} else {
				unset($data[1]);
			}
		} else if ($data[2] == "instituicao") {
			if($data[1] != NULL){
				$data[1] = "%" . $data[1] . "%";
	        	$select = $select . ' AND apelido_instituicao ilike ? ';
			} else {
				unset($data[1]);
			}
		} else {
			if ($data[1] != NULL) {
				$data[1] = '%' . $data[1] . '%';
	        	$select = $select.' AND p.email like lower(?) ';
			} else {
				unset($data[1]);
			}
		}
		unset($data[2]);
		$select = $select.' ORDER BY p.nome ASC LIMIT 20';
		return $this->getAdapter()->fetchAll($select,$data);
	}

	public function buscaPessoasCoordenacao($data){
		$select = "SELECT p.id_pessoa, nome, apelido, email FROM encontro_participante ep
			INNER JOIN pessoa p ON (ep.id_pessoa = p.id_pessoa)
			WHERE id_encontro = ? AND id_tipo_usuario = 1"; // 1: coordenação
		return $this->getAdapter()->fetchAll($select,$data);
	}

	public function buscaPessoasOrganizacao($data){
		$select = "SELECT p.id_pessoa, nome, apelido, email FROM encontro_participante ep
			INNER JOIN pessoa p ON (ep.id_pessoa = p.id_pessoa)
			WHERE id_encontro = ? AND id_tipo_usuario = 2"; // 2: organização
		return $this->getAdapter()->fetchAll($select,$data);
	}

	public function verificaEncontro($idEncontro, $idPessoa){
		$select = "SELECT id_pessoa from encontro_participante where id_encontro = ? AND id_pessoa = ?";
		$resp = $this->getAdapter()->fetchRow($select, array($idEncontro, $idPessoa));
		if ($resp == null) {
			return false;
		}
		return true;
	}

	public function buscarUltimoEncontro($idPessoa) {
      //$select =  "SELECT id_encontro, id_pessoa, id_instituicao, id_municipio, id_caravana,
		$select =  "SELECT id_encontro, id_pessoa, id_instituicao, id_municipio,
				id_tipo_usuario, validado FROM encontro_participante
				WHERE id_pessoa = ? ORDER BY id_encontro DESC LIMIT 1";

		// "select * from encontro_participante where id_pessoa = ? order by id_pessoa desc limit 1";
		$rs = $this->getAdapter()->fetchAll($select, $idPessoa);
		if (count($rs) > 0) {
			return $rs[0];
		}
		return null;
	}

	/**
	 * @deprecated
	 */
	public function atualizaEncontro($encontro) {
		$select = "insert into encontro_participante(id_encontro, id_pessoa,id_instituicao,id_municipio,id_caravana,id_tipo_usuario)
			values(?,?,?,?,?,?)";
	   return $this->getAdapter()->fetchAll($select,$encontro);
	}

	public function buscarPermissaoUsuarios($idEncontro, $termo = "",
           $buscar_por = "nome", $tipo_usuario = 0) {

      $sql = "SELECT p.id_pessoa, p.nome, p.apelido,
               p.email, p.administrador, tu.id_tipo_usuario, tu.descricao_tipo_usuario
         FROM encontro_participante ep
         INNER JOIN pessoa p ON ep.id_pessoa = p.id_pessoa
         INNER JOIN tipo_usuario tu ON ep.id_tipo_usuario = tu.id_tipo_usuario
         WHERE ep.id_encontro = ? ";
      $where = array($idEncontro);
      if (! empty($termo)) {
         if ($buscar_por == "nome") {
            $sql .= " AND p.nome ILIKE ? ";
            $where[] = "%{$termo}%";
         } else if ($buscar_por == "email") {
            $sql .= " AND p.email ILIKE ? ";
            $where[] = "%{$termo}%";
         } else if ($buscar_por == "id_pessoa") {
            $sql .= " AND p.id_pessoa = ? ";
            $where[] = (int) $termo;
         }
      }

      if ($tipo_usuario > 0) {
         $sql .= " AND tu.id_tipo_usuario = ? ";
         $where[] = $tipo_usuario;
      }

      $sql .= " ORDER BY p.nome LIMIT 50 ";
      return $this->getAdapter()->fetchAll($sql, $where);
   }

   public function listarSlideShare($slideshareUsername) {
        if (empty($slideshareUsername)) {
            return null;
        }

        try {
            $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'staging');
            $api_key = $config->slideshare->api_key;
            $shared_secret = $config->slideshare->shared_secret;

            // Caso o slideshare não esteja configurado retorna null.
            // TODO: jogar exceção para melhor mostrar ao usuário o que realmente
            // aconteceu. Do modo que está agora mostra como se o usuário
            // não tivesse configurado sua conta no slideshare!
            if (empty($api_key) || empty($shared_secret)) {
                return null;
            }

            $service = new Zend_Service_SlideShare($api_key, $shared_secret);
            $offset = 0;
            $limit = 10;
            $slides = $service->getSlideShowsByUsername($slideshareUsername, $offset, $limit);
            return $slides;
        } catch (Exception $ex) {
            throw $ex;
        }
    }

	public function buscaParticipantes($id_encontro, $where = null, $col_order = "p.nome", $limit = null) {
        $sql = "
            SELECT
                p.id_pessoa, UPPER(p.nome) as nome, p.cadastro_validado,
                apelido, LOWER(email) as email, twitter, nome_municipio,
                apelido_instituicao, nome_caravana, ep.confirmado
            FROM encontro_participante ep
            INNER JOIN pessoa p ON (ep.id_pessoa = p.id_pessoa)
            LEFT OUTER JOIN instituicao i ON (ep.id_instituicao = i.id_instituicao)
            INNER JOIN municipio m ON (ep.id_municipio = m.id_municipio)
            LEFT OUTER JOIN caravana c ON (ep.id_caravana = c.id_caravana)
            WHERE id_encontro = ?
        ";

        if (!empty($where)) {
            $sql .= 'AND ' . $where;
        }

        if (!empty($col_order)) {
            $sql .= ' ORDER BY ' . $this->getOrderAcentos($col_order);
        }

        if (!empty($limit)) {
            $sql .= ' LIMIT ' . $limit;
        }
        return $this->getAdapter()->fetchAll($sql, array($id_encontro));
    }

	// order desconsiderando acentos diacrílicos
    // http://valdeka.wordpress.com/2009/12/07/dicas-postgresql/
    public function getOrderAcentos($coluna = "p.nome", $asc = true) {
        $s = "lower(translate({$coluna}, 'ÁÀÂÃÄáàâãäÉÈÊËéèêëÍÌÎÏíìîïÓÒÕÔÖóòôõöÚÙÛÜúùûüÇç', 'AAAAAaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuCc')) ";
        $asc ? $s.= "ASC" : $s .= "DESC";
        return $s;
    }

	/**
     * Verifica se a pessoa existe.
     */
    public function existe($id_pessoa) {
        $sql = "
            SELECT EXIST(
                SELECT *
                FROM pessoa
                WHERE id_pessoa = ?
            )";
        return $this->getAdapter()->fetchOne($sql, array($id_pessoa));
    }

    public function isAdmin($id_pessoa) {
        $sql = "
            SELECT EXIST(
                SELECT *
                FROM pessoa
                WHERE id_pessoa = ? AND administrador = 't'
            )";
        return $this->getAdapter()->fetchOne($sql, array($id_pessoa));
    }

	/**
	 * Cria nova pessoa
	 * @param  {[array]} $data dados vindos do formulário
	 */
	public function criar($data) {
		$sql = "INSERT INTO pessoa(nome, email, apelido, twitter, endereco_internet,
		            id_sexo, nascimento, facebook, cpf, telefone)
		    	VALUES (?, ?, ?, ?, ?, ?,
		            to_date(?, 'DD/MM/YYYY'), ?, ?, ?) RETURNING id_pessoa";
		$params = array(
			$data['nome'],
			$data['email'],
			$data['apelido'],
			$data['twitter'],
			$data['endereco_internet'],
			$data['id_sexo'],
			$data['nascimento'],
			$data['facebook'],
			(empty($data['cpf']) ? NULL : $data['cpf']),
			(empty($data['telefone']) ? NULL : $data['telefone'])
		);
		$result = $this->getAdapter()->fetchRow($sql, $params);
		return $result['id_pessoa'];
	}

	/**
	 * Atualiza dados da pessoa
	 * @param  {[array]} $data dados vindos do formulário
	 * @param  {[integer]} $id_pessoa
	 */
	public function atualizar($data, $id_pessoa) {
		$sql = "UPDATE pessoa
			  	SET nome = ?, apelido = ?, twitter = ?, endereco_internet = ?,
			       id_sexo = ?, nascimento = to_date(?, 'DD/MM/YYYY'), facebook = ?,
			       bio = ?, slideshare = ?, cpf = ?, telefone = ?
				WHERE id_pessoa = ?";
		$params = array(
			$data['nome'],
			$data['apelido'],
			$data['twitter'],
			$data['endereco_internet'],
			$data['id_sexo'],
			$data['nascimento'],
			$data['facebook'],
			$data['bio'],
			$data['slideshare'],
			(empty($data['cpf']) ? NULL : $data['cpf']),
			(empty($data['telefone']) ? NULL : $data['telefone']),
			$id_pessoa
		);

		$this->getAdapter()->query($sql, $params);
	}
}
