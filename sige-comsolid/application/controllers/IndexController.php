<?php

class IndexController extends Zend_Controller_Action
{

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
					
					$config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'staging');
					$idEncontro = $config->encontro->codigo;
					
					// FIXME: seja lá o que seja isso
					// pelo que dá pra perceber quando o usuário não está no encontro atual
					// ele é adicionado ao encontro.
					if($pessoa->verificaEncontro($idEncontro, $idPessoa) == false) {
						
						$p = $pessoa->buscaUltimoEncontro($idPessoa);
						$result = $p[0];
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
					// echo "<br><br>senha inválida.";
               $this->_helper->flashMessenger->addMessage(
                     array('error' => 'Senha está incorreta.'));
				}

			} else {
				// echo "<br><br>usuário ou senha incorretos.";
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
            // echo "E-mail enviado com sucesso, verifique seu e-mail.";
            $this->_helper->flashMessenger->addMessage(
                     array('success' => 'E-mail enviado com sucesso, verifique seu e-mail.'));
         } else {
            // echo "E-mail não cadastrado.";
            $this->_helper->flashMessenger->addMessage(
                     array('error' => 'E-mail não cadastrado.'));
         }
      }
   }
}