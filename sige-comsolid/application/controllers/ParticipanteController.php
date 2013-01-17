<?php
class ParticipanteController extends Zend_Controller_Action {

	public function init() {
		$this->view->menu=new Application_Form_Menu($this->view,'inicio');
	}

	private function autenticacao() {
		if (!Zend_Auth::getInstance()->hasIdentity()) {
			return $this->_helper->redirector->goToRoute(array(), 'login', true);
		}
	}

	public function indexAction() {
	   $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/tabela_sort.css'));
	   $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-1.6.2.min.js'));
	   $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery.dataTables.js'));
	   $this->view->headScript()->appendFile($this->view->baseUrl('js/participante/inicio.js'));
	   
		$this->autenticacao();
		$sessao = Zend_Auth::getInstance()->getIdentity();
		$idPessoa = $sessao["idPessoa"];
		$idEncontro = $sessao["idEncontro"];
		$administrador = $sessao["administrador"];

		if ($administrador) {
			return $this->_helper->redirector->goToRoute(array(), 'inscricoes', true);
		} else {
			//$pessoa = new Application_Model_Pessoa();
			//$pessoa = $pessoa->find($idPessoa);
			//$this->view->pessoa = $pessoa[0];

			$eventoDemanda = new Application_Model_EventoDemanda();
			$select = $eventoDemanda->select();
			$eventoParticipante = $eventoDemanda->getMeusEvento(array($idEncontro, $idPessoa));
			$this->view->listaParticipanteEventoTabela =$eventoParticipante;
		}
	}

	public function criarAction() {
		$this->view->menu="";
		$form = new Application_Form_Pessoa();
		$this->view->form = $form;
		$this->view->headLink()->appendStylesheet($this->view->baseUrl('css/form.css'));
		$data = $this->getRequest()->getPost();

		if ($this->getRequest()->isPost() && $form->isValid($data)) {
			$data = $form->getValues();
			$pessoa = new Application_Model_Pessoa();
			$participante = new Application_Model_Participante();

			$config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'staging');
			$idEncontro = $config->encontro->codigo;

			$data2 = array (
				'id_encontro' => $idEncontro,
				'id_municipio' => $data['municipio'],
				'id_instituicao' => $data['instituicao']
			);
			unset ($data['municipio']);
			unset ($data['instituicao']);
			// inseri no banco ... e mantem uma trasacao 
         $adapter = $pessoa->getAdapter();
			try {
				$adapter->beginTransaction();
				$idPessoa = $pessoa->insert($data);
				$data2['id_pessoa'] = $idPessoa;
				$participante->insert($data2);

			} catch (Zend_Db_Exception $ex) {
            // DONE: colocar erro em flashMessage
				$adapter->rollBack();
				$sentinela = 1;
				//$form->getElement('email')->addErrorMessage('e-mail ja cadastrado');
				
				// echo $ex->getMessage() . $ex->getCode();
            // 23505 UNIQUE VIOLATION
            if ($ex->getCode() == 23505) {
               $this->_helper->flashMessenger->addMessage(
                       array('error' => 'E-mail já cadastrado.'));
            } else {
               $this->_helper->flashMessenger->addMessage(
                        array('error' => 'Ocorreu um erro inesperado.<br/>Detalhes: '
                           . $ex->getMessage()));
            }
			}
			// codigo responsavel por enviar email para confirmacao 
			//echo "ID PESSOA" . $idPessoa;
			try {
				if (! empty($idPessoa) and $idPessoa > 0) {
					$mail = new Application_Model_EmailConfirmacao();
					$mail->send($idPessoa, $idEncontro);
					$data = array (
						'email_enviado' => 'true'
					);
					$where = $pessoa->getAdapter()->quoteInto('id_pessoa = ?', $idPessoa);
					$pessoa->update($data, $where);
				}
			} catch (Exception $ex) {
            $adapter->rollBack();
				$sentinela = 1;
            // DONE: colocar erro em flashMessage
				// echo $ex->getMessage();
            $this->_helper->flashMessenger->addMessage(
                     array('error' => 'Ocorreu um erro inesperado ao enviar e-mail.<br/>Detalhes: '
                         . $ex->getMessage()));
			}

			if ($sentinela == 0) {
            $adapter->commit();
				return $this->_helper->redirector->goToRoute(array (
					'controller' => 'participante',
					'action' => 'sucesso'
				), 'default', true);
			}
		}
	}

	public function editarAction() {
		$this->autenticacao();

		$sessao = Zend_Auth :: getInstance()->getIdentity();
		
		$idPessoa = $sessao["idPessoa"];
		$idEncontro = $sessao["idEncontro"];
		$this->view->headLink()->appendStylesheet($this->view->baseUrl('css/form.css'));
		$form = new Application_Form_PessoaEdit();
		$this->view->form = $form;

		$pessoa = new Application_Model_Pessoa();
		$participante = new Application_Model_Participante();

		$result = $pessoa->find($idPessoa);
		$linha = $result[0];

		$result = $participante->find($idPessoa, $idEncontro);
		$linha1 = $result[0];

		$form->populate(array_merge($linha->toArray(), $linha1->toArray()));

		$data = $this->getRequest()->getPost();

		if ($this->getRequest()->isPost() && $form->isValid($data)) {
			$data = $form->getValues();

			$data2 = array (
				'id_encontro' => $idEncontro,
				'id_municipio' => $data['id_municipio'],
				'id_instituicao' => $data['id_instituicao']
			);

			unset ($data['id_municipio']);
			unset ($data['id_instituicao']);
			//alterar no banco ... e mantem uma trasacao 
         $adapter = $pessoa->getAdapter();
			try {
				$adapter->beginTransaction();
            
				$where = $pessoa->getAdapter()->quoteInto('id_pessoa = ?', $idPessoa);
				$pessoa->update($data, $where);
				$data2['id_pessoa'] = $idPessoa;
				$where = $participante->getAdapter()
                        ->quoteInto('id_pessoa = ?', $idPessoa)
                    . $participante->getAdapter()
                        ->quoteInto(' AND id_encontro = ? ', $idEncontro);
				$participante->update($data2, $where);
				$adapter->commit();

			} catch (Zend_Db_Exception $ex) {
            // DONE: colocar erro em flashMessage
				$adapter->rollBack();
				$sentinela = 1;
				$form->getElement('email')->setAttrib('mensagem', 'e-mail invalido');
				// 23505UNIQUE VIOLATION
				// echo $ex->getMessage() . $ex->getCode();
            $this->_helper->flashMessenger->addMessage(
                    array('error' => 'Ocorreu um erro inesperado.<br/>Detalhes: '
                        . $ex->getMessage()));
				//throw $ex;
			}
			// codigo responsavel por enviar email para confirmacao 

			if ($sentinela == 0) {
				return $this->_helper->redirector->goToRoute(array (
					'controller' => 'participante',
					'action' => 'index'
				), 'default', true);
			}
		}
	}

	public function sucessoAction() {
		$this->view->menu="";
	}
	
	public function alterarSenhaAction() {
		//echo $this->getBaseURL();
		$this->view->menu->setAtivo('alterarsenha');
		$this->autenticacao();
		
		$form = new Application_Form_AlterarSenha();
		$this->view->form = $form;
		$this->view->headLink()->appendStylesheet($this->view->baseUrl('css/form.css'));

		$data = $this->getRequest()->getPost();
		if (isset ($data['cancelar'])) {
			return $this->_helper->redirector->goToRoute(array (
				'controller' => 'participante'
			), 'default', true);
			return;
		}

		if ($this->getRequest()->isPost() && $form->isValid($data)) {
			$data = $form->getValues();

			$pessoa = new Application_Model_Pessoa();

			$resultadoConsulta = $pessoa->avaliaLogin($data['email'], $data['senhaAntiga']);

			if (sizeof($resultadoConsulta) > 0) {

				if ($resultadoConsulta[0]->valido == true) {

					if ($data['senhaNova'] == $data['senhaNovaRepeticao']) {
						$where = $pessoa->getAdapter()->quoteInto('id_pessoa = ?', $resultadoConsulta[0]->id_pessoa);

						$novaSennha = array (
							'senha' => md5($data['senhaNova'])
						);
						$pessoa->update($novaSennha, $where);

						return $this->_helper->redirector->goToRoute(array (
							'controller' => 'participante'
						), 'default', true);
					} else {
						// DONE: colocar erro em flashMessage
						// echo "nova senha não confere!";
                  $this->_helper->flashMessenger->addMessage(
                     array('error' => 'Nova senha não confere!'));
					}
				} else {
					// echo "senha antiga incorreta!";
               $this->_helper->flashMessenger->addMessage(
                     array('error' => 'Senha antiga incorreta!'));
				}
			}
		}
	}

   /**
    * @deprecated use evento/interesse
    */
	public function pessoaaddeventoAction() {
      $this->deprecated("participante", "pessoaaddevento");
	   $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/tabela_sort.css'));
	   $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-1.6.2.min.js'));
	   $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery.dataTables.js'));
	   $this->view->headScript()->appendFile($this->view->baseUrl('js/evento/busca_evento.js'));
	   $this->autenticacao();
		$sessao = Zend_Auth::getInstance()->getIdentity();
		$idEncontro = $sessao["idEncontro"];
		$idPessoa = $sessao["idPessoa"];

		//$this->view->headScript()->appendFile('/js/jquery-1.6.2.min.js');
		
		$eventos = new Application_Model_Evento();
      // usada para mostrar dias que possuem eventos
		$this->view->listaEvento = $eventos->getEventos($idEncontro);
		$this->view->idEncontro = $idEncontro;
		$this->view->idPessoa = $idPessoa;
		
		$tipoEventos = new Application_Model_TipoEvento();
		$this->view->tipoEvento = $tipoEventos->fetchAll();

		$eventoRealizacao = new Application_Model_EventoRealizacao();
		$eventoRealizacao = $eventoRealizacao->fetchALL();

		$this->view->eventosTabela = array ();
		foreach ($eventoRealizacao as $item) {

			$eventoItem = $item->findDependentRowset('Application_Model_Evento')->current();
			$tipoItem = $eventoItem->findDependentRowset('Application_Model_TipoEvento')->current();

			$this->view->eventosTabela[] = array_merge($item->toArray(), $eventoItem->toArray(), $tipoItem->toArray());
		}

		$form = new Application_Form_PessoaAddEvento();
		$this->view->form = $form;

		$form->criarFormulario($this->view->eventosTabela);

		$data = $this->getRequest()->getPost();

		if ($this->getRequest()->isPost() && $form->isValid($data)) {
			$data = $form->getValues();

		}

	}
	
	public function excluieventoAction(){
		$this->autenticacao();

		$sessao = Zend_Auth::getInstance()->getIdentity();
		$idPessoa = $sessao["idPessoa"];
		
		$idEvento = intval($this->_request->getParam("evento"));
		
		
		$data =array("evento = ? "=>$idEvento,"id_pessoa=? "=>$idPessoa);
		
		$eventoDemanda = new Application_Model_EventoDemanda();
		$eventoDemanda->remover($data);
		
		return $this->_helper->redirector->goToRoute(array ('controller' => 'participante','action' => 'index'), null, true);
	}
   
   public function verAction() {
      $model = new Application_Model_Pessoa();
      $id = $this->_getParam('id', "");
      if (! empty($id)) {
         if (is_numeric($id)) {
            $sql = $model->getAdapter()->quoteInto('id_pessoa = ?', $id);
         } else {
            $sql = $model->getAdapter()->quoteInto('twitter = ?', $id);
         }
         $this->view->mostrarEditar = false;
      } else if (Zend_Auth::getInstance()->hasIdentity()) {
         $sessao = Zend_Auth::getInstance()->getIdentity();
         if (! empty($sessao["twitter"])) {
            $sql = $model->getAdapter()->quoteInto('twitter = ?', $sessao["twitter"]);
            $id = $sessao["twitter"];
         } else {
            $sql = $model->getAdapter()->quoteInto('id_pessoa = ?', $sessao["idPessoa"]);
            $id = $sessao["idPessoa"];
         }
         $this->view->mostrarEditar = true;
      } else {
         // DONE: colocar erro em flashMessage
         // echo "Participante não encontrado.";
         $this->_helper->flashMessenger->addMessage(
                     array('error' => 'Participante não encontrado.'));
         return;
      }
      $this->view->id = $id;
      $this->view->user = $model->fetchRow($sql);
   }
   
   public function certificadoPalestranteAction() {
      $this->_helper->layout()->disableLayout();
      $this->_helper->viewRenderer->setNoRender(true);
      
      // include auto-loader class
      require_once 'Zend/Loader/Autoloader.php';

      // register auto-loader
      $loader = Zend_Loader_Autoloader::getInstance();
      
      $pdf = new Zend_Pdf();
      $page1 = $pdf->newPage(Zend_Pdf_Page::SIZE_A4_LANDSCAPE);
      $font = Zend_Pdf_Font::fontWithName(Zend_Pdf_Font::FONT_HELVETICA);
      $page1->setFont($font, 12);
      
      $image = Zend_Pdf_Image::imageWithPath(dirname(__FILE__)
                      . '/../../public/img/bg-certificado.png');
      $page1->drawImage($image, 10, 60, 960, 436);
      
      $page1->drawText('Certificamos que Júlio Neves participou do COMSOLiD+5', 120, 350, 'UTF-8');
      
      $pdf->pages[] = ($page1);
      $pdf->save(dirname(__FILE__) . '/../../tmp/certificado-palestrante.pdf');
      // Get PDF document as a string 
      $pdfData = $pdf->render();
      
      header("Content-Disposition: inline; filename=certificado-palestrante.pdf");
      header("Content-type: application/x-pdf");
      echo $pdfData;
   }

	private function deprecated($controller, $view) {
		$this->view->deprecated = "You are using a deprecated controller/view: {$controller}/{$view}";
	}
}