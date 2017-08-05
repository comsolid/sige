<?php

define('TOKEN_BYTE_SIZE', 24);
define('TOKEN_VALIDADE', '24 hours');

class Application_Model_Pessoa extends Zend_Db_Table_Abstract
{
    protected $_name = 'pessoa';
    protected $_primary = 'id_pessoa';

    protected $_referenceMap = array(
        array(
            'refTableClass' => 'Application_Model_Participante',
            'refColumns' => 'id_pessoa',
            'columns' => 'id_pessoa',
            'onDelete' => self::CASCADE,
            'onUpdate' => self::RESTRICT,
        ),
        array(
            'refTableClass' => 'Application_Model_Evento',
            'refColumns' => 'responsavel',
            'columns' => 'id_pessoa',
            'onDelete' => self::CASCADE,
            'onUpdate' => self::RESTRICT,
        ),
        array(
            'refTableClass' => 'Application_Model_EventoDemanda',
            'refColumns' => 'id_pessoa',
            'columns' => 'id_pessoa',
            'onDelete' => self::CASCADE,
            'onUpdate' => self::RESTRICT,
        ),
    );

    /**
     * @deprecated
     *
     * @param [type] $email [description]
     */
    public function gerarSenha($email)
    {
        try {
            $qryIsValid = $this->getAdapter()->quoteInto('SELECT funcGerarSenha(?) AS c ', $email);
            $senha = $this->getAdapter()->query($qryIsValid)->fetch();

            return $senha['c'];
        } catch (Exception $ex) {
        }
    }

    /**
     * Verifica validade do token existente. Retorna o token caso esteja válido,
     * gera um novo caso contrário.
     *
     * @param [type] $id_pessoa [description]
     */
    public function gerarToken($id_pessoa)
    {
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

    private function gravarTokenNoBanco($token, $id_pessoa)
    {
        $sql = "
            UPDATE {$this->_name}
                SET token = ?,
                token_validade = NOW() + '".TOKEN_VALIDADE."'
            WHERE id_pessoa = ?
        ";
        return $this->getAdapter()->query($sql, array($token, $id_pessoa));
    }

    private function gerarHash($str)
    {
        return hash('sha256', $str);
    }

    private function obterTokenDoBanco($id_pessoa)
    {
        $sql = "
			SELECT token, current_timestamp < token_validade as token_valido
			FROM {$this->_name}
			WHERE id_pessoa = ?
		";
        return $this->getAdapter()->fetchRow($sql, array($id_pessoa));
    }

    private function gerarNovoToken()
    {
        return base64_encode(mcrypt_create_iv(TOKEN_BYTE_SIZE));
    }

    public function verificarToken($id_pessoa, $hashedToken)
    {
        $result = $this->obterTokenDoBanco($id_pessoa);
        $hashVerificacao = $this->gerarHash($result['token']);
        if ($hashedToken !== $hashVerificacao) {
            throw new Exception(_("Verification Token to Recover Password invalid or doesn't exists."));
        }

        if (!$result['token_valido']) {
            throw new Exception(_('Verification Token to Recover Password expired. Try again accessing Forgot My Password.'));
        }

        return true;
    }

    public function resetarToken($id_pessoa)
    {
        $where = $this->getAdapter()->quoteInto('id_pessoa = ?', $id_pessoa);
        $this->update(array(
            'token' => null,
            'token_validade' => null,
        ), $where);
    }

    /**
     * A partir da senha informada gera um hash blowfish e salva o valor
     * Utilização
     * 		/index/definir-senha
     * 		/participante/alterar-senha.
     *
     * @param [int]    $id_pessoa [description]
     * @param [string] $senha     [description]
     */
    public function setNovaSenha($id_pessoa, $senha)
    {
        $db = $this->getAdapter();
        $where = $db->quoteInto('id_pessoa = ?', $id_pessoa);

        $lib = new PasswordLib\PasswordLib();
        $hash = $lib->createPasswordHash($senha);

        $this->update(array('senha' => $hash), $where);
    }

    /**
     * Utilização
     * 	/login
     * 	/participante/alterar-senha.
     */
    public function avaliaLogin($login, $senha)
    {
        $sql = 'SELECT id_pessoa, administrador, apelido, senha,
        	twitter, cadastro_validado
        	FROM pessoa WHERE email = ?';
        $where = array($login);
        $result = $this->getAdapter()->fetchRow($sql, $where);
        if (!$result) {
            throw new Exception(_('E-mail not found.'));
        }

        $lib = new PasswordLib\PasswordLib();
        $verified = $lib->verifyPasswordHash($senha, $result['senha']);
        if ($verified) {
            return $result;
        }

        return;
    }

	/**
	 * Busca por participantes através do nome, e-mail, instituto, caravana ou
	 * município. Traz todos os participantes do encontro e os que não fizeram
	 * pré-inscrição. Dessa forma irá permitir a recepção inscrever e confirmar
	 * presença do participante sem a necessidade do participante ter feito a
	 * pré-inscrição, agilizando o processo.
	 * @param  integer $id_encontro encontro atual
	 * @param  string $buscar_por  coluna a ser usada como restrição
	 * @param  string $termo       termo a ser usado como restrição
	 * @return array|null              lista de participantes, limitada a 20
	 */
    public function buscaPessoas($id_encontro, $buscar_por = 'nome', $termo = '')
    {
        $select = 'SELECT p.id_pessoa as id, p.nome, p.cadastro_validado, apelido, email, twitter,
			nome_municipio, apelido_instituicao, nome_caravana, ep.confirmado, ep.data_cadastro,
			ep.data_confirmacao FROM encontro_participante ep
			RIGHT JOIN pessoa p ON (ep.id_pessoa = p.id_pessoa)
			LEFT OUTER JOIN instituicao i ON (ep.id_instituicao = i.id_instituicao)
			LEFT JOIN municipio m ON (ep.id_municipio = m.id_municipio)
			LEFT OUTER JOIN caravana c ON (ep.id_caravana = c.id_caravana)
			WHERE id_encontro = ?
		';

        $where = '';
        $restricao = '';
        $params = array(
            $id_encontro,
        );
		$orderBy = ' ORDER BY ep.data_cadastro DESC NULLS LAST ';
        if (!empty($termo)) {
            $restricao = "%{$termo}%";
            if ($buscar_por == 'nome') {
                $where = ' AND p.nome ILIKE ? ';
            } elseif ($buscar_por == 'municipio') {
                $where = ' AND nome_municipio ilike ? ';
            } elseif ($buscar_por == 'caravana') {
                $where = ' AND nome_caravana ilike ? ';
            } elseif ($buscar_por == 'instituicao') {
                $where = ' AND apelido_instituicao ilike ? ';
            } else {
                $where = ' AND p.email like lower(?) ';
            }
            $params[] = $restricao;
			$orderBy = ' ORDER BY p.nome ASC ';
        }

        return $this->getAdapter()->fetchAll($select.$where.$orderBy.' LIMIT 20', $params);
    }

	public function buscarNaoInscritos($id_encontro, $buscar_por = 'nome', $termo = '')
	{
		$select = 'SELECT p.id_pessoa as id, p.nome, p.apelido, p.email, p.twitter,
			p.data_cadastro, p.cadastro_validado, p.data_validacao_cadastro
			FROM pessoa p
		';

        $where = '';
        $restricao = '';
		$params = array();
		$orderBy = ' ORDER BY data_cadastro DESC ';
        if (!empty($termo)) {
            $restricao = "%{$termo}%";
            if ($buscar_por == 'nome') {
                $where = ' WHERE p.nome ILIKE ? ';
            } else {
                $where = ' WHERE p.email like lower(?) ';
            }
            $params[] = $restricao;
			$orderBy = ' ORDER BY nome ASC ';
        }
        $select .= $where.' EXCEPT
        SELECT p1.id_pessoa as id, p1.nome, p1.apelido, p1.email, p1.twitter,
        p1.data_cadastro, p1.cadastro_validado, p1.data_validacao_cadastro
        FROM pessoa p1
        INNER JOIN encontro_participante ep ON p1.id_pessoa = ep.id_pessoa
        WHERE ep.id_encontro = ?';
        $params[] = $id_encontro;

        return $this->getAdapter()->fetchAll($select.$orderBy.' LIMIT 20', $params);
	}

    public function buscaPessoasCoordenacao($data)
    {
        $select = 'SELECT p.id_pessoa, nome, apelido, email FROM encontro_participante ep
			INNER JOIN pessoa p ON (ep.id_pessoa = p.id_pessoa)
			WHERE id_encontro = ? AND id_tipo_usuario = 1'; // 1: coordenação
        return $this->getAdapter()->fetchAll($select, $data);
    }

    public function buscaPessoasOrganizacao($data)
    {
        $select = 'SELECT p.id_pessoa, nome, apelido, email FROM encontro_participante ep
			INNER JOIN pessoa p ON (ep.id_pessoa = p.id_pessoa)
			WHERE id_encontro = ? AND id_tipo_usuario = 2'; // 2: organização
        return $this->getAdapter()->fetchAll($select, $data);
    }

    public function verificaEncontro($idEncontro, $idPessoa)
    {
        $select = 'SELECT id_pessoa from encontro_participante where id_encontro = ? AND id_pessoa = ?';
        $resp = $this->getAdapter()->fetchRow($select, array($idEncontro, $idPessoa));
        if ($resp == null) {
            return false;
        }

        return true;
    }

    public function buscarUltimoEncontro($idPessoa)
    {
        $select = 'SELECT id_encontro, id_pessoa, id_instituicao, id_municipio,
				id_tipo_usuario, validado FROM encontro_participante
				WHERE id_pessoa = ? ORDER BY id_encontro DESC LIMIT 1';
        return $this->getAdapter()->fetchRow($select, $idPessoa);
    }

    /**
     * @deprecated
     */
    public function atualizaEncontro($encontro)
    {
        $select = 'insert into encontro_participante(id_encontro, id_pessoa,id_instituicao,id_municipio,id_caravana,id_tipo_usuario)
			values(?,?,?,?,?,?)';

        return $this->getAdapter()->fetchAll($select, $encontro);
    }

    public function buscarPermissaoUsuarios($idEncontro, $termo = '',
           $buscar_por = 'nome', $tipo_usuario = 0)
    {
        $sql = 'SELECT p.id_pessoa, p.nome, p.apelido,
               p.email, p.administrador, tu.id_tipo_usuario, tu.descricao_tipo_usuario
         FROM encontro_participante ep
         INNER JOIN pessoa p ON ep.id_pessoa = p.id_pessoa
         INNER JOIN tipo_usuario tu ON ep.id_tipo_usuario = tu.id_tipo_usuario
         WHERE ep.id_encontro = ? ';
        $where = array($idEncontro);
        if (!empty($termo)) {
            if ($buscar_por == 'nome') {
                $sql .= ' AND p.nome ILIKE ? ';
                $where[] = "%{$termo}%";
            } elseif ($buscar_por == 'email') {
                $sql .= ' AND p.email ILIKE ? ';
                $where[] = "%{$termo}%";
            } elseif ($buscar_por == 'id_pessoa') {
                $sql .= ' AND p.id_pessoa = ? ';
                $where[] = (int) $termo;
            }
        }

        if ($tipo_usuario > 0) {
            $sql .= ' AND tu.id_tipo_usuario = ? ';
            $where[] = $tipo_usuario;
        }

        $sql .= ' ORDER BY p.nome LIMIT 50 ';

        return $this->getAdapter()->fetchAll($sql, $where);
    }

    public function listarSlideShare($slideshareUsername)
    {
        if (empty($slideshareUsername)) {
            return;
        }

        try {
            $config = new Zend_Config_Ini(APPLICATION_PATH.'/configs/application.ini', 'staging');
            $api_key = $config->slideshare->api_key;
            $shared_secret = $config->slideshare->shared_secret;

            // Caso o slideshare não esteja configurado retorna null.
            // TODO: jogar exceção para melhor mostrar ao usuário o que realmente
            // aconteceu. Do modo que está agora mostra como se o usuário
            // não tivesse configurado sua conta no slideshare!
            if (empty($api_key) || empty($shared_secret)) {
                return;
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

    public function buscaParticipantes($id_encontro, $where = null, $col_order = 'p.nome', $limit = null)
    {
        $sql = '
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
        ';

        if (!empty($where)) {
            $sql .= 'AND '.$where;
        }

        if (!empty($col_order)) {
            $sql .= ' ORDER BY '.$this->getOrderAcentos($col_order);
        }

        if (!empty($limit)) {
            $sql .= ' LIMIT '.$limit;
        }

        return $this->getAdapter()->fetchAll($sql, array($id_encontro));
    }

    // order desconsiderando acentos diacrílicos
    // http://valdeka.wordpress.com/2009/12/07/dicas-postgresql/
    public function getOrderAcentos($coluna = 'p.nome', $asc = true)
    {
        $s = "lower(translate({$coluna}, 'ÁÀÂÃÄáàâãäÉÈÊËéèêëÍÌÎÏíìîïÓÒÕÔÖóòôõöÚÙÛÜúùûüÇç', 'AAAAAaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuCc')) ";
        $asc ? $s .= 'ASC' : $s .= 'DESC';

        return $s;
    }

    /**
     * Verifica se a pessoa existe.
     */
    public function existe($id_pessoa)
    {
        $sql = '
            SELECT EXIST(
                SELECT *
                FROM pessoa
                WHERE id_pessoa = ?
            )';

        return $this->getAdapter()->fetchOne($sql, array($id_pessoa));
    }

    public function isAdmin($id_pessoa)
    {
        $sql = "
            SELECT EXIST(
                SELECT *
                FROM pessoa
                WHERE id_pessoa = ? AND administrador = 't'
            )";

        return $this->getAdapter()->fetchOne($sql, array($id_pessoa));
    }

    /**
     * Cria nova pessoa.
     *
     * @param {[array]} $data dados vindos do formulário
     */
    public function criar($data)
    {
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
            (empty($data['cpf']) ? null : $data['cpf']),
            (empty($data['telefone']) ? null : $data['telefone']),
        );
        $result = $this->getAdapter()->fetchRow($sql, $params);

        return $result['id_pessoa'];
    }

    /**
     * Atualiza dados da pessoa.
     *
     * @param {[array]}   $data      dados vindos do formulário
     * @param {[integer]} $id_pessoa
     */
    public function atualizar($data, $id_pessoa)
    {
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
            (empty($data['cpf']) ? null : $data['cpf']),
            (empty($data['telefone']) ? null : $data['telefone']),
            $id_pessoa,
        );

        $this->getAdapter()->query($sql, $params);
    }
}
