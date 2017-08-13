<?php

/**
 * Modelo para tabela "mensagem_email"
 * Trata do envio de e-mail usando Zend_Mail.
 */
class Application_Model_EmailConfirmacao extends Zend_Db_Table_Abstract {

    const MSG_CONFIRMACAO = 1;
    const MSG_RECUPERAR_SENHA = 2;
    const MSG_CONFIRMACAO_SUBMISSAO = 3;
    const MSG_CONFIRMACAO_REINSCRICAO = 4;

    protected $_name = 'mensagem_email';
    protected $_primary = array('id_encontro', 'id_tipo_mensagem_email');
    private $config;

    public function __construct($config = array()) {
        parent::__construct($config);
        $this->config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'emailmsg');
    }

    /**
     * Obtem dados da mensagem de confirmação para e-mail.
     * @deprecated usar obterMensagem
     * @param int $idEncontro
     * @return Zend_Db_Table_Row_Abstract
     */
    public function getMsgConfirmacao($idEncontro) {
        return $this->find($idEncontro, $this->config->email->confirmacao_inscricao)->current();
    }

    /**
     * Obtem dados da mensagem de recuperação de senha para e-mail.
     * @deprecated usar obterMensagem
     * @param int $idEncontro
     * @return Zend_Db_Table_Row_Abstract
     */
    public function getMsgCorrecao($idEncontro) {
        return $this->find($idEncontro, $this->config->email->recuperacao_senha)->current();
    }

    private function obterMensagem($id_encontro, $id_tipo_mensagem_email) {
        $sql = 'SELECT mensagem, assunto, e.apelido_encontro,
        assinatura_email, assinatura_siteoficial
        FROM public.mensagem_email me
        INNER JOIN encontro e ON me.id_encontro = e.id_encontro
        WHERE me.id_encontro = ? AND id_tipo_mensagem_email = ?
        ';
        return $this->getAdapter()->fetchRow($sql, array($id_encontro, $id_tipo_mensagem_email));
    }

    /**
     * Envia e-mail para usuário com dados iniciais.
     * @param int $idpessoa
     * @param int $idEncrontro
     * @param int $tipoMensagem use as constantes definidas acima
     * <ul>
     *  <li>MSG_CONFIRMACAO</li>
     *  <li>MSG_RECUPERAR_SENHA</li>
     *  <li>MSG_CONFIRMACAO_REINSCRICAO</li>
     *  <li>MSG_CONFIRMACAO_SUBMISSAO</li>
     * </ul>
     * @param binary|null $pdf arquivo PDF em string binária, se não for null será enviado ao usuário em anexo
     * @throws Exception
     */
    public function send(
			$id_pessoa,
			$id_encontro,
			$tipoMensagem = Application_Model_EmailConfirmacao::MSG_CONFIRMACAO,
			$pdf = null
	) {
        $mail = new Zend_Mail();
        $pessoa = new Application_Model_Pessoa();
        $linha = $pessoa->find($id_pessoa)->current();

        $emailText = $this->obterMensagem($id_encontro, $tipoMensagem);
        switch ($tipoMensagem) {
            case Application_Model_EmailConfirmacao::MSG_CONFIRMACAO:
            case Application_Model_EmailConfirmacao::MSG_RECUPERAR_SENHA:
                $result = $pessoa->gerarToken($id_pessoa);
                $link = "http://" . $_SERVER["SERVER_NAME"] . "/index/definir-senha/hashedToken/"
                    . $result['hashedToken'] . "/id/" . $id_pessoa;

                break;
            case Application_Model_EmailConfirmacao::MSG_CONFIRMACAO_REINSCRICAO:
            case Application_Model_EmailConfirmacao::MSG_CONFIRMACAO_SUBMISSAO:
                $link = "http://" . $_SERVER["SERVER_NAME"] . "/login";
                break;
            default:
                throw new Exception(_("Send e-mail option not defined."));
        }

        $emailText['mensagem'] = str_replace('{nome}', $linha->nome, $emailText['mensagem']);
        $emailText['mensagem'] = str_replace('{email}', $linha->email, $emailText['mensagem']);
        $emailText['mensagem'] = str_replace('{href_link}', $link, $emailText['mensagem']);
        $emailText['mensagem'] = str_replace('{encontro}', $emailText['apelido_encontro'], $emailText['mensagem']);

        $mail->setBodyHtml(iconv($this->config->email->in_charset, $this->config->email->out_charset, $emailText['mensagem']));
        $mail->addTo($linha->email, $linha->nome);
        $mail->setSubject(iconv($this->config->email->in_charset, $this->config->email->out_charset, $emailText['assunto']));

		if ($pdf != null) {
			$at = new Zend_Mime_Part($pdf);
			$at->type        = 'application/pdf';
			$at->disposition = Zend_Mime::DISPOSITION_ATTACHMENT;
			$at->encoding    = Zend_Mime::ENCODING_BASE64;
			$at->filename    = 'ticket-inscricao.pdf';

			$mail->addAttachment($at);
		}

        $mail->send();
    }

    /**
     * @deprecated use send
     * @param type $idpessoa
     * @param type $idEncrontro
     */
    public function sendCorrecao($idpessoa, $idEncrontro) {
        $mail = new Zend_Mail();
        $pessoa = new Application_Model_Pessoa();
        $linha = $pessoa->find($idpessoa)->current();
        // $pessoa->email = $linha->email;
        $senha = $pessoa->gerarSenha($linha->email);
        $emailText = $this->getMsgCorrecao($idEncrontro);
        $emailText->mensagem = str_replace('{nome}', $linha->nome, $emailText->mensagem);
        $emailText->mensagem = str_replace('{email}', $linha->email, $emailText->mensagem);
        $emailText->mensagem = str_replace('{senha}', $senha, $emailText->mensagem);
        $emailText->mensagem = str_replace('{href_link}', $emailText->link, $emailText->mensagem);
        $mail->setBodyHtml(iconv($this->config->email->in_charset, $this->config->email->out_charset, $emailText->mensagem));
        $mail->addTo($linha->email, $linha->nome);
        $mail->setSubject(iconv($this->config->email->in_charset, $this->config->email->out_charset, $emailText->assunto));
        $mail->send();
    }
}
