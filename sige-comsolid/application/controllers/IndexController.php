<?php

class IndexController extends Zend_Controller_Action
{

   public function init() {
      /* Initialize action controller here */
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

				if ($resultadoConsulta[0]->valido) {

					$idPessoa = $resultadoConsulta[0]->id_pessoa;
					$administrador = $resultadoConsulta[0]->administrador;
					$apelido = $resultadoConsulta[0]->apelido;
					
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
						"idEncontro" => $idEncontro
					));

					return $this->_helper->redirector->goToRoute(array (
						'controller' => 'participante',
						'action' => 'index'
					), null, true);

				} else {
					echo "<br><br>senha inválida.";
				}

			} else {
				echo "<br><br>usuário ou senha incorretos.";
			}
		}
	}

	public function logoutAction() {
		$auth = Zend_Auth :: getInstance();
		$storage = $auth->clearIdentity();

		return $this->_helper->redirector->goToRoute(array (
			'controller' => 'index',
			'action' => 'login'
		), null, true);
	}
}