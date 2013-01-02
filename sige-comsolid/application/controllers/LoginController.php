<?php
class LoginController extends Zend_Controller_Action {

	public function init() {
		/* Initialize action controller here */
	
		
	}

	public function indexAction() {
		// action body

	}

	public function loginAction() {
		$form = new Application_Form_Login();
		$form->setAction($this->view->url());
          // ->setMethod('post');
		$this->view->form = $form;
	  	$this->view->headLink()->appendStylesheet($this->view->baseUrl('css/form.css'));
		$data = $this->getRequest()->getPost();

		if ($this->getRequest()->isPost() && $form->isValid($data)) {
			$data = $form->getValues();
			$pessoa = new Application_Model_Pessoa();

			$resultadoConsulta = $pessoa->avaliaLogin($data['email'], $data['senha']);

			

			if (sizeof($resultadoConsulta) > 0) {

				if ($resultadoConsulta[0]->valido == true) {

					$idPessoa = $resultadoConsulta[0]->id_pessoa;
					$administrador = $resultadoConsulta[0]->administrador;
					$apelido = $resultadoConsulta[0]->apelido;
					
					/*
					$validaCadastroPessoa = $pessoa->find($idPessoa);
					
					if($validaCadastroPessoa[0]->cadastro_validado == false ){
						$where = $pessoa->getAdapter()->quoteInto('id_pessoa = ?', $idPessoa);
						
						$pessoa->update(array('cadastro_validado'=>true), $where);
					}*/
					
								 

					$config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'staging');
					$idEncontro = $config->encontro->codigo;
					
					
					if($pessoa->verificaEncontro($idEncontro, $idPessoa) == false){
						
						$p = $pessoa->buscaUltimoEncontro($idPessoa);
						$result = $p[0];
						$result['id_encontro'] = intval($idEncontro);
						unset($result['data_cadastro']);
						unset($result['validado']);
						unset($result['data_validacao']);
						unset($result['confirmado']);
						unset($result['data_confirmacao']);
						
						$encontro = array();
						
						foreach ($result as $r){
							$encontro[] =  $r;
						}
						
					    $pessoa->atualizaEncontro($encontro);
					}
					

					$auth = Zend_Auth :: getInstance();
					$storage = $auth->getStorage();

					$storage->write(array (
						"idPessoa" => $idPessoa,
						"administrador" => $administrador,
						 "apelido" => $apelido,
						"idEncontro" => $idEncontro
					));

					return $this->_helper->redirector->goToRoute(array (
						'controller' => 'participante',
						'action' => 'index'
					), null, true);

				} else {
					echo "<br><br>senha invalida";
				}

			} else {
				echo "<br><br>usuário ou senha incorretos";
			}

		}
	}

	public function logoutAction() {
		$auth = Zend_Auth :: getInstance();
		$storage = $auth->clearIdentity();

		return $this->_helper->redirector->goToRoute(array (
			'controller' => 'login',
			'action' => 'login'
		), null, true);
	}

	public function recuperarsenhaAction() {
		//$this->view->menu=new Application_Form_Menu($this->view,'alterarsenha');
		$form = new Application_Form_RecuperarSenha();
		$form->setAction($this->view->url(array('controller'=>'login','action'=>'recuperarsenha')));
		$this->view->form = $form;
		$this->view->headLink()->appendStylesheet($this->view->baseUrl('css/form.css'));

		$data = $this->getRequest()->getPost();

		if ($this->getRequest()->isPost() && $form->isValid($data)) {
			$data = $form->getValues();

			$pessoa = new Application_Model_Pessoa();

			$select = $pessoa->select()->from('pessoa', array (
				"id_pessoa"
			))->where("email = ?", $data['email']);

			$resultado = $pessoa->fetchAll($select);

			if (sizeof($resultado) > 0) {

				$config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'staging');
				$idEncontro = $config->encontro->codigo;

				$mail = new Application_Model_EmailConfirmacao();
				$mail->sendCorrecao($resultado[0]->id_pessoa, $idEncontro);

				echo "e-mail enviado com sucesso, verifique seu e-mail";

			} else {

				echo "e-mail não cadastrado";
			}

		}
	}
}