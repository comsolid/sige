<?php
class Application_Model_EmailConfirmacao extends Zend_Db_Table_Abstract {
	
	protected $_name = 'mensagem_email';
	protected $_primary = array('id_encontro','id_tipo_mensagem_email');
	
	public function getMsgConfirmacao($idEncrontro) {
		$config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'emailmsg');
		return $this->find($idEncrontro,$config->email->confirmacao)->current();
	}
	
	public function getMsgCorrecao($idEncrontro) {		
		$config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'emailmsg');
		return $this->find($idEncrontro,$config->email->correcao)->current();
	}

	public function send($idpessoa,$idEncrontro) {
		
		$mail = new Zend_Mail();
		$pessoa = new Application_Model_Pessoa();
		$linha = $pessoa->find($idpessoa);
		$linha = $linha[0];
		$pessoa->email = $linha->email;
		$pessoa->gerarSenha();

		$emailText = $this->getMsgConfirmacao($idEncrontro);

		$emailText->mensagem = str_replace('{nome}', utf8_decode ($linha->nome), $emailText->mensagem);

		$emailText->mensagem = str_replace('{email}', $linha->email, $emailText->mensagem);
		$emailText->mensagem = str_replace('{senha}', $pessoa->senha, $emailText->mensagem);
		if (empty($emailText->link)) {
         $link = "#";
      } else {
         $link = $emailText->link;
      }
      $emailText->mensagem = str_replace('{href_link}', $link, $emailText->mensagem);
		$mail->setBodyHtml($emailText->mensagem);
		$mail->addTo($linha->email, $linha->nome);
		$mail->setSubject($emailText->assunto);

		$mail->send();
	}
	
	public function sendCorrecao($idpessoa,$idEncrontro) {
		
		$mail = new Zend_Mail();
		$pessoa = new Application_Model_Pessoa();
		$linha = $pessoa->find($idpessoa);
		$linha = $linha->current();
		$pessoa->email = $linha->email;
		$pessoa->gerarSenha();

		$emailText = $this->getMsgCorrecao($idEncrontro);

		$emailText->mensagem = str_replace('{nome}', $linha->nome, $emailText->mensagem);

		$emailText->mensagem = str_replace('{email}', $linha->email, $emailText->mensagem);
		$emailText->mensagem = str_replace('{senha}', $pessoa->senha, $emailText->mensagem);
		$emailText->mensagem = str_replace('{href_link}', $emailText->link, $emailText->mensagem);
		$mail->setBodyHtml($emailText->mensagem);
		$mail->addTo($linha->email, $linha->nome);
		$mail->setSubject($emailText->assunto);

		$mail->send();
	}

}