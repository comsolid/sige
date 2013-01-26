<?php

class IndexController extends Zend_Controller_Action {

   public function init() {

   }

   public function indexAction() {
		
	}

	public function loginAction() {
		$form = new Application_Form_Login();
		$this->view->form = $form;
	  	$this->view->headLink()->appendStylesheet($this->view->baseUrl('css/form.css'));
		$data = $this->getRequest()->getPost();

		if ($this->getRequest()->isPost() && $form->isValid($data)) {
			$data = $form->getValues();
			$pessoa = new Application_Model_Pessoa();

			$resultadoConsulta = $pessoa->avaliaLogin($data['email'], $data['senha']);

			if (sizeof($resultadoConsulta) > 0) {
				if ($resultadoConsulta['valido']) {

					$idPessoa = $resultadoConsulta['id_pessoa'];
					$administrador = $resultadoConsulta['administrador'];
					$apelido = $resultadoConsulta['apelido'];
               $twitter = $resultadoConsulta['twitter'];
               
               $validaCadastroPessoa = $pessoa->find($idPessoa);

               if ($validaCadastroPessoa[0]->cadastro_validado == false) {
                  $where = $pessoa->getAdapter()->quoteInto('id_pessoa = ?', $idPessoa);

                  $pessoa->update(array('cadastro_validado' => true), $where);
               }
					
					$config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'staging');
					$idEncontro = $config->encontro->codigo;
					
					// FIXME: seja lá o que seja isso
					// pelo que dá pra perceber quando o usuário não está no encontro atual
					// ele é adicionado ao encontro.
               $rs = $pessoa->buscaUltimoEncontro($idPessoa);
					$result = $rs[0];
					if($pessoa->verificaEncontro($idEncontro, $idPessoa) == false) {
						
						$result['id_encontro'] = intval($idEncontro);
						// TODO: buscar apenas as colunas desejadas para evitar esses unset's em buscaUltimoEncontro
						unset($result['data_cadastro']);
						unset($result['validado']);
						unset($result['data_validacao']);
						unset($result['confirmado']);
						unset($result['data_confirmacao']);

						// WTF?!?
						$encontro = array();
						foreach ($result as $r){
							$encontro[] =  $r;
						}
					   $pessoa->atualizaEncontro($encontro);
                  $this->_helper->flashMessenger->addMessage(
                     array('success' => 'Bem-vindo de volta. Sua inscrição foi confirmada!'));
					} else if (! $result['validado']) {
                  // se participante ainda não está validado no encontro
                  // devemos validar
                  // TODO: refazer este trecho!!!!
                  $adapter = $pessoa->getAdapter();
                  $adapter->fetchAll("UPDATE encontro_participante
                     SET validado = 't', data_validacao = now()
                     WHERE id_pessoa = {$result['id_pessoa']}
                     AND id_encontro = {$idEncontro}");
               }

					$auth = Zend_Auth::getInstance();
					$storage = $auth->getStorage();

					$storage->write(array(
						"idPessoa" => $idPessoa,
						"administrador" => $administrador,
						"apelido" => $apelido,
						"idEncontro" => $idEncontro,
                  "twitter" => $twitter
					));

					return $this->_helper->redirector->goToRoute(array (
						'controller' => 'participante',
						'action' => 'index'
					), 'default', true);

				} else {
               $this->_helper->flashMessenger->addMessage(
                     array('error' => 'Senha está incorreta.'));
				}

			} else {
            $this->_helper->flashMessenger->addMessage(
                     array('error' => 'Login está incorreto.'));
			}
		}
	}

	public function logoutAction() {
		$auth = Zend_Auth :: getInstance();
		$storage = $auth->clearIdentity();

		return $this->_helper->redirector->goToRoute(array(), 'login', true);
	}
   
   public function recuperarSenhaAction() {
      $form = new Application_Form_RecuperarSenha();
      $this->view->form = $form;
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/form.css'));

      $data = $this->getRequest()->getPost();

      if ($this->getRequest()->isPost() && $form->isValid($data)) {
         $data = $form->getValues();

         $pessoa = new Application_Model_Pessoa();

         $select = $pessoa->select()->from('pessoa', array(
                     "id_pessoa"
                 ))->where("email = ?", $data['email']);

         $resultado = $pessoa->fetchAll($select);

         if (sizeof($resultado) > 0) {

            $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'staging');
            $idEncontro = $config->encontro->codigo;

            $mail = new Application_Model_EmailConfirmacao();
            $mail->sendCorrecao($resultado[0]->id_pessoa, $idEncontro);
            $this->_helper->flashMessenger->addMessage(
                     array('success' => 'E-mail enviado com sucesso, verifique seu e-mail.'));
         } else {
            $this->_helper->flashMessenger->addMessage(
                     array('error' => 'E-mail não cadastrado.'));
         }
      }
   }
   
   public function sobreAction() {
      $sessao = Zend_Auth::getInstance()->getIdentity();
      $this->view->menu = new Application_Form_Menu($this->view, 'inicio', $sessao['administrador']);
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/screen.css'));
   }
}