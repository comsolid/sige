<?php

/**
 * Description of MensagemEmail
 *
 * @author atila
 */
class Admin_Model_MensagemEmail extends Application_Model_EmailConfirmacao {

    private $html_templates = array(
        1 => 'confirmacao-inscricao.html',
        2 => 'recuperar-senha.html',
        3 => 'confirmacao-submissao.html',
        4 => 'confirmacao-reinscricao.html',
    );

    /**
     * Cria as mensagens padrão para um novo encontro.
     * @param int $id_encontro
     * @param string $apelido_encontro
     */
    public function criarMensagensPadrao($id_encontro, $apelido_encontro) {
        $this->_criarMensagemConfirmacaoPadrao($id_encontro, $apelido_encontro);
        $this->_criarMensagemRecuperarSenhaPadrao($id_encontro, $apelido_encontro);
        $this->_criarMensagemConfirmacaoSubmissao($id_encontro, $apelido_encontro);
        $this->_criarMensagemConfirmacaoInscricao($id_encontro, $apelido_encontro);
    }

    /**
     *
     * @param int $id_encontro
     * @param string $apelido_encontro
     */
    private function _criarMensagemConfirmacaoPadrao($id_encontro, $apelido_encontro) {
        $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'emailmsg');
        $this->_criarMensagemPadrao($id_encontro, $apelido_encontro, $config->email->confirmacao_inscricao);
    }

    /**
     *
     * @param int $id_encontro
     * @param string $apelido_encontro
     */
    private function _criarMensagemConfirmacaoSubmissao($id_encontro, $apelido_encontro) {
        $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'emailmsg');
        $this->_criarMensagemPadrao($id_encontro, $apelido_encontro, $config->email->confirmacao_submissao);
    }

    /**
     *
     * @param int $id_encontro
     * @param string $apelido_encontro
     */
    private function _criarMensagemRecuperarSenhaPadrao($id_encontro, $apelido_encontro) {
        $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'emailmsg');
        $this->_criarMensagemPadrao($id_encontro, $apelido_encontro, $config->email->recuperacao_senha);
    }

    /**
     *
     * @param int $id_encontro
     * @param string $apelido_encontro
     */
    private function _criarMensagemConfirmacaoInscricao($id_encontro, $apelido_encontro) {
        $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'emailmsg');
        $this->_criarMensagemPadrao($id_encontro, $apelido_encontro, $config->email->confirmacao_reinscricao);
    }

    private function _criarMensagemPadrao($id_encontro, $apelido_encontro, $id_tipo_mensagem) {
        $row = $this->getAdapter()->fetchRow("SELECT descricao_tipo_mensagem_email
            FROM tipo_mensagem_email WHERE id_tipo_mensagem_email = ? ", array($id_tipo_mensagem));

        $filename = APPLICATION_PATH . '/../public/email-templates/' . $this->html_templates[$id_tipo_mensagem];
        if (file_exists($filename)) {
            $mensagem = file_get_contents($filename);
        } else {
            throw new Exception(_('The html templates files must be at /public/email-templates directory.'));
        }

        $params = array(
            'id_encontro' => $id_encontro,
            'id_tipo_mensagem_email' => $id_tipo_mensagem,
            'mensagem' => $mensagem,
            'assunto' => "{$apelido_encontro}: {$row['descricao_tipo_mensagem_email']}"
        );
        $this->insert($params);
    }
}
