<?php
class ParticipanteController extends Zend_Controller_Action {

	public function init() {
      $sessao = Zend_Auth::getInstance()->getIdentity();
		$this->view->menu=new Application_Form_Menu($this->view,'inicio', $sessao['administrador']);
	}

	private function autenticacao() {
		if (!Zend_Auth::getInstance()->hasIdentity()) {
         $session = new Zend_Session_Namespace();
         $session->setExpirationSeconds(60 * 60 * 1); // 1 minuto
         $session->url = $_SERVER['REQUEST_URI'];
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

      $eventoDemanda = new Application_Model_EventoDemanda();
      $eventoParticipante = $eventoDemanda->listar(array($idEncontro, $idPessoa));
      $this->view->listaParticipanteEventoTabela =$eventoParticipante;
	}

	/**
	 * Mapeada como
	 * 	/participar
	 */
	public function criarAction() {
		$this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-1.8.3.min.js'));
		$this->view->headScript()->appendFile($this->view->baseUrl('js/select2.js'));
		$this->view->headScript()->appendFile($this->view->baseUrl('js/parsley.i18n/messages.pt_br.js'));
		$this->view->headScript()->appendFile($this->view->baseUrl('js/parsley.min.js'));
		$this->view->headScript()->appendFile($this->view->baseUrl('js/participante/salvar.js'));
		$this->view->headLink()->appendStylesheet($this->view->baseUrl('css/form.css'));
		$this->view->headLink()->appendStylesheet($this->view->baseUrl('css/select2.css'));
		$this->view->headLink()->appendStylesheet($this->view->baseUrl('css/participante/criar.css'));
		
		$this->view->menu="";
		$form = new Application_Form_Pessoa();
		$this->view->form = $form;
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
         unset ($data['captcha']);
			// inseri no banco ... e mantem uma trasacao 
         $adapter = $pessoa->getAdapter();
			try {
				$adapter->beginTransaction();
				$idPessoa = $pessoa->insert($data);
				$data2['id_pessoa'] = $idPessoa;
				$participante->insert($data2);

			} catch (Zend_Db_Exception $ex) {
				$adapter->rollBack();
				$sentinela = 1;

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
		$this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-1.8.3.min.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/participante/jquery-ui-1.10.0.tabs-only.js'));
		$this->view->headScript()->appendFile($this->view->baseUrl('js/select2.js'));
		$this->view->headScript()->appendFile($this->view->baseUrl('js/participante/salvar.js'));

		$this->view->headLink()->appendStylesheet($this->view->baseUrl('css/form.css'));
		
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/screen.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/jqueryui-bootstrap/jquery-ui-1.8.16.custom.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/jqueryui-bootstrap/jquery.ui.1.8.16.ie.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/select2.css'));

		$sessao = Zend_Auth::getInstance()->getIdentity();
		
		$idPessoa = $sessao["idPessoa"];
		$idEncontro = $sessao["idEncontro"];
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
         $sentinela = 0;
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
				$adapter->rollBack();
				$sentinela = 1;
				$form->getElement('email')->setAttrib('mensagem', 'e-mail invalido');
            $this->_helper->flashMessenger->addMessage(
                    array('error' => 'Ocorreu um erro inesperado.<br/>Detalhes: '
                        . $ex->getMessage()));
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
                  $this->_helper->flashMessenger->addMessage(
                     array('error' => 'Nova senha não confere!'));
					}
				} else {
               $this->_helper->flashMessenger->addMessage(
                     array('error' => 'Senha antiga incorreta!'));
				}
			}
		}
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
         $this->_helper->flashMessenger->addMessage(
                     array('error' => 'Participante não encontrado.'));
         return;
      }
      $this->view->id = $id;
      $this->view->user = $model->fetchRow($sql);
   }
   
   public function certificadosAction() {
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/screen.css'));
      $sessao = Zend_Auth :: getInstance()->getIdentity();
		$idPessoa = $sessao["idPessoa"];
      
      $model = new Application_Model_Participante();
      $this->view->certsParticipante = $model->listarCertificadosParticipante($idPessoa);
      $this->view->certsPalestrante = $model->listarCertificadosPalestrante($idPessoa);
      $this->view->certsPalestrante = array_merge($this->view->certsPalestrante,
              $model->listarCertificadosPalestrantesOutros($idPessoa));
   }
   
   public function certificadoParticipanteAction() {
      $this->_helper->layout()->disableLayout();
      $this->_helper->viewRenderer->setNoRender(true);
      
      $sessao = Zend_Auth :: getInstance()->getIdentity();
		$idPessoa = $sessao["idPessoa"];
      $idEncontro = $this->_getParam('id_encontro', 0);
      
      $model = new Application_Model_Participante();
      $rs = $model->listarCertificadosParticipante($idPessoa, $idEncontro);
      
      if (is_null($rs)) {
         $this->_helper->flashMessenger->addMessage(
                 array('error' => 'Você não participou deste Encontro.'));
         return $this->_helper->redirector->goToRoute(array(
                     'controller' => 'participante',
                     'action' => 'certificados'), 'default', true);
      }
      
      try {
         $certificado = new Sige_Pdf_Certificado();
         $pdfData = $certificado->participante(array(
             'nome' => $rs['nome'],
             'id_encontro' => $rs['id_encontro'], // serve para identificar o modelo
             'encontro' => $rs['nome_encontro'],
         ));
         header("Content-Disposition: inline; filename=certificado-participante.pdf");
         header("Content-type: application/x-pdf");
         echo $pdfData;
      } catch (Exception $e) {
         $this->_helper->flashMessenger->addMessage(
                    array('error' => 'Ocorreu um erro inesperado.<br/>Detalhes: '
                        . $e->getMessage()));
         return $this->_helper->redirector->goToRoute(array (
                  'controller' => 'participante',
                  'action' => 'certificados'), 'default', true);
      }
   }
   
   /**
    * certificado Teste 
    */
   public function certificadoPalestranteAction() {
      $this->_helper->layout()->disableLayout();
      $this->_helper->viewRenderer->setNoRender(true);
      
      $sessao = Zend_Auth :: getInstance()->getIdentity();
		$idPessoa = $sessao["idPessoa"];
      $idEvento = $this->_getParam('id', 0);
      
      $model = new Application_Model_Participante();
      $rs = $model->listarCertificadosPalestrante($idPessoa, $idEvento);
      // palestrante em evento_palestrante
      if (is_null($rs)) {
         $rs = $model->listarCertificadosPalestrantesOutros($idPessoa, $idEvento);
      }
      
      if (is_null($rs)) {
         $this->_helper->flashMessenger->addMessage(
                 array('error' => 'Você não apresentou esse trabalho neste Encontro.'));
         return $this->_helper->redirector->goToRoute(array(
                     'controller' => 'participante',
                     'action' => 'certificados'), 'default', true);
      }
      
      try {
         $certificado = new Sige_Pdf_Certificado();
         // Get PDF document as a string
         $pdfData = $certificado->palestrante(array(
             'nome' => $rs['nome'],
             'id_encontro' => $rs['id_encontro'], // serve para identificar o modelo
             'encontro' => $rs['nome_encontro'],
             'tipo_evento' => $rs['nome_tipo_evento'],
             'nome_evento' => $rs['nome_evento']
         ));

         header("Content-Disposition: inline; filename=certificado-palestrante.pdf");
         header("Content-type: application/x-pdf");
         echo $pdfData;
      } catch (Exception $e) {
         $this->_helper->flashMessenger->addMessage(
                    array('error' => 'Ocorreu um erro inesperado.<br/>Detalhes: '
                        . $e->getMessage()));
         return $this->_helper->redirector->goToRoute(array (
                  'controller' => 'participante',
                  'action' => 'certificados'), 'default', true);
      }
   }
}