<?php

/**
 * Description of MensagemEmail
 *
 * @author atila
 */
class Admin_Model_MensagemEmail extends Application_Model_EmailConfirmacao {

    /**
     * Cria as mensagens padrão para um novo encontro.
     * @param int $id_encontro
     * @param string $apelido_encontro
     */
    public function criarMensagensPadrao($id_encontro, $apelido_encontro) {
        $this->_criarMensagemConfirmacaoPadrao($id_encontro, $apelido_encontro);
        $this->_criarMensagemRecuperarSenhaPadrao($id_encontro, $apelido_encontro);
        $this->_criarMensagemConfirmacaoSubmissao($id_encontro, $apelido_encontro);
    }

    /**
     * 
     * @param int $id_encontro
     * @param string $apelido_encontro
     */
    private function _criarMensagemConfirmacaoPadrao($id_encontro, $apelido_encontro) {
        $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'emailmsg');
        // $config->email->confirmacao_inscricao
        $this->_criarMensagemPadrao($id_encontro, $apelido_encontro, $config->email->confirmacao_inscricao);
    }

    /**
     * 
     * @param int $id_encontro
     * @param string $apelido_encontro
     */
    private function _criarMensagemConfirmacaoSubmissao($id_encontro, $apelido_encontro) {
        $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'emailmsg');
        // $config->email->confirmacao
        $this->_criarMensagemPadrao($id_encontro, $apelido_encontro, $config->email->confirmacao_submissao);
    }

    /**
     * 
     * @param int $id_encontro
     * @param string $apelido_encontro
     */
    private function _criarMensagemRecuperarSenhaPadrao($id_encontro, $apelido_encontro) {
        $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'emailmsg');
        // $config->email->recuperacao_senha
        $this->_criarMensagemPadrao($id_encontro, $apelido_encontro, $config->email->recuperacao_senha);
    }

    private function _criarMensagemPadrao($id_encontro, $apelido_encontro, $id_tipo_mensagem) {
        $row = $this->getAdapter()->fetchRow("SELECT descricao_tipo_mensagem_email
         FROM tipo_mensagem_email WHERE id_tipo_mensagem_email = ? ", array($id_tipo_mensagem));

        $params = array(
            'id_encontro' => $id_encontro,
            'id_tipo_mensagem_email' => $id_tipo_mensagem,
            'mensagem' => 'Nome: {nome}, E-mail: {email}, Senha: {senha}, <a href="{href_link}" target="_blank">Clique aqui</a>',
            'assunto' => "{$apelido_encontro}: {$row['descricao_tipo_mensagem_email']}"
        );
        $this->insert($params);
    }

}
