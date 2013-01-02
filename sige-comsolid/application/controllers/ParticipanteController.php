<?php
class ParticipanteController extends Zend_Controller_Action {

	public function init() {
		$this->view->menu=new Application_Form_Menu($this->view,'inicio');
	}

	public function autenticacaoAction() {
		/* Initialize action controller here */
		if (!Zend_Auth :: getInstance()->hasIdentity()) {
			return $this->_helper->redirector->goToRoute(array (
				'controller' => 'login',
				'action' => 'login'
			), null, true);
		}
	}

	public function indexAction() {
	   $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/tabela_sort.css'));
	   $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-1.6.2.min.js'));
	   $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery.dataTables.js'));
	   $this->view->headScript()->appendFile($this->view->baseUrl('js/participante/inicio.js'));
	   
		$this->autenticacaoAction();
		$sessao = Zend_Auth :: getInstance()->getIdentity();
		$idPessoa = $sessao["idPessoa"];
		$idEncontro = $sessao["idEncontro"];
		$administrador = $sessao["administrador"];

		if ($administrador) {
			return $this->_helper->redirector->goToRoute(array (
					'controller' => 'administrador',
					'action' => 'index'
				), null, true);
				
		} else {
			$pessoa = new Application_Model_Pessoa();
			$pessoa = $pessoa->find($idPessoa);
			$this->view->pessoa = $pessoa[0];
/*
			$participante = new Application_Model_Participante();
			$participante = $participante->find($idPessoa, $idEncontro);
			$participante = $participante[0];

			$this->view->participante = $participante->findDependentRowset('Application_Model_Pessoa')->current();

			if ($participante->id_caravana != null) {
				$this->view->caravana = $participante->findDependentRowset('Application_Model_Caravana')->current()->apelido_caravana;
			}

			$this->view->instituicao = $participante->findDependentRowset('Application_Model_Instituicao')->current();
			$this->view->municipio = $participante->findDependentRowset('Application_Model_Municipio')->current();

			$sexo = new Application_Model_Pessoa();
			$sexo = $sexo->find($idPessoa);
			$sexo = $sexo[0];
			$this->view->sexo = $sexo->findDependentRowset('Application_Model_Sexo')->current();
*/
			$eventoDemanda = new Application_Model_EventoDemanda();
			$select = $eventoDemanda->select();
			$eventoParticipante = $eventoDemanda->getMeusEvento(array($idEncontro, $idPessoa));
			$this->view->listaParticipanteEventoTabela =$eventoParticipante;
		}

	}

	public function addAction() {
		$this->view->menu="";
		$form = new Application_Form_Pessoa();
		$form->setAction($this->view->url(array('controller'=>'participante','action'=>'add')));
		$this->view->form = $form;
		$this->view->headLink()->appendStylesheet($this->view->baseUrl('css/form.css'));
		$data = $this->getRequest()->getPost();

		if ($this->getRequest()->isPost() && $form->isValid($data)) {
			$data = $form->getValues();
			$data['twitter'] = '@' . $data['twitter'];
			$pessoa = new Application_Model_Pessoa();
			$participante = new Application_Model_Participante();

			$config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'staging');
			$idEncontro = $config->encontro->codigo;

			$idPessoa = 0;
			//id_encontro
			$data2 = array (
				'id_encontro' => $idEncontro,
				'id_municipio' => $data['municipio'],
				'id_instituicao' => $data['instituicao']
			);
			unset ($data['municipio']);
			unset ($data['instituicao']);
			// inseri no banco ... e mantem uma trasacao 
			try {
				$adapter = $pessoa->getAdapter();
				$adapter->beginTransaction();
				$idPessoa = $pessoa->insert($data);
				$data2['id_pessoa'] = $idPessoa;
				$participante->insert($data2);
				$adapter->commit();

			} catch (Zend_Db_Exception $ex) {
				$adapter->rollBack();
				$sentinela = 1;
				//$form->getElement('email')->addErrorMessage('e-mail ja cadastrado');
				
				// 23505UNIQUE VIOLATION
				echo $ex->getMessage() . $ex->getCode();
				//throw $ex;
				//echo "E-mail ja cadastrado!";
			}
			// codigo responsavel por enviar email para confirmacao 
			//echo "ID PESSOA" . $idPessoa;
			try {
				if ($idPessoa > 0) {
					$mail = new Application_Model_EmailConfirmacao();
					$mail->send($idPessoa, $idEncontro);
					$data = array (
						'email_enviado' => 'true'
					);
					$where = $pessoa->getAdapter()->quoteInto('id_pessoa = ?', $idPessoa);
					$pessoa->update($data, $where);
				}
			} catch (Zend_Db_Exception $ex) {

				echo $ex->getMessage();
				//throw $ex;
			}
			if ($sentinela == 0)
				return $this->_helper->redirector->goToRoute(array (
					'controller' => 'participante',
					'action' => 'sucesso'
				), null, true);

		}

	}

	public function editAction() {
	$this->autenticacaoAction();

		$sessao = Zend_Auth :: getInstance()->getIdentity();
		
		$idPessoa = $sessao["idPessoa"];
		$idEncontro = $sessao["idEncontro"];
		$this->view->headLink()->appendStylesheet($this->view->baseUrl('css/form.css'));
		$form = new Application_Form_PessoaEdit();
		$form->setAction($this->view->url(array('controller'=>'participante','action'=>'edit')));
		$this->view->form = $form;

		$pessoa = new Application_Model_Pessoa();
		$participante = new Application_Model_Participante();

		$result = $pessoa->find($idPessoa);
		$linha = $result[0];
		$linha->twitter = str_replace('@', "", $linha->twitter);

		$result = $participante->find($idPessoa, $idEncontro);
		$linha1 = $result[0];

		$form->populate(array_merge($linha->toArray(), $linha1->toArray()));

		$data = $this->getRequest()->getPost();

		if ($this->getRequest()->isPost() && $form->isValid($data)) {
			$data = $form->getValues();
			$data['twitter'] = '@' . $data['twitter'];

			$data2 = array (
				'id_encontro' => $idEncontro,
				'id_municipio' => $data['id_municipio'],
				'id_instituicao' => $data['id_instituicao']
			);

			unset ($data['id_municipio']);
			unset ($data['id_instituicao']);
			//alterar no banco ... e mantem uma trasacao 
			try {

				$adapter = $pessoa->getAdapter();
				$adapter->beginTransaction();

				$where = $pessoa->getAdapter()->quoteInto('id_pessoa = ?', $idPessoa);
				$pessoa->update($data, $where);

				$data2['id_pessoa'] = $idPessoa;

				$where = $participante->getAdapter()->quoteInto('id_pessoa = ?', $idPessoa) . $participante->getAdapter()->quoteInto(' AND id_encontro = ? ', $idEncontro);

				$participante->update($data2, $where);

				$adapter->commit();

			} catch (Zend_Db_Exception $ex) {
				$adapter->rollBack();
				$sentinela = 1;
				$form->getElement('email')->setAttrib('mensagem', 'e-mail invalido');
				// 23505UNIQUE VIOLATION
				echo $ex->getMessage() . $ex->getCode();
				//throw $ex;
			}
			// codigo responsavel por enviar email para confirmacao 

			if ($sentinela == 0) {
				return $this->_helper->redirector->goToRoute(array (
					'controller' => 'participante',
					'action' => 'index'
				), null, true);
			}
		}

	}

	public function sucessoAction() {
		$this->view->menu="";
	}

	public function alterarsenhaAction() {
		//echo $this->getBaseURL();
		$this->view->menu->setAtivo('alterarsenha');
		$this->autenticacaoAction();
		
		$form = new Application_Form_AlterarSenha();
		$form->setAction($this->view->url(array('controller'=>'participante','action'=>'alterarsenha')));
		$this->view->form = $form;
		$this->view->headLink()->appendStylesheet($this->view->baseUrl('css/form.css'));

		$data = $this->getRequest()->getPost();

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
							'controller' => 'participante',
							'action' => 'index'
						), null, true);

					} else {

						echo "nova senha não confere!";
					}

				} else {
					echo "senha antiga incorreta!";
				}

			}

		}
	}

	public function pessoaaddeventoAction() {
	   $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/tabela_sort.css'));
	   $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-1.6.2.min.js'));
	   $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery.dataTables.js'));
	   $this->view->headScript()->appendFile($this->view->baseUrl('js/evento/busca_evento.js'));
	   $this->autenticacaoAction();
		$sessao = Zend_Auth :: getInstance()->getIdentity();
		$idEncontro = $sessao["idEncontro"];
		$idPessoa = $sessao["idPessoa"];

		//$this->view->headScript()->appendFile('/js/jquery-1.6.2.min.js');
		
		$eventos = new Application_Model_Evento();
		$this->view->listaEvento = $eventos->getEventos(1);
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
		$this->autenticacaoAction();

		$sessao = Zend_Auth :: getInstance()->getIdentity();
		$idPessoa = $sessao["idPessoa"];
		
		$idEvento = intval($this->_request->getParam("evento"));
		
		
		$data =array("evento = ? "=>$idEvento,"id_pessoa=? "=>$idPessoa);
		
		$eventoDemanda = new Application_Model_EventoDemanda();
		$eventoDemanda->remover($data);
		
		return $this->_helper->redirector->goToRoute(array ('controller' => 'participante','action' => 'index'), null, true);
		
	}

}