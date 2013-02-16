<?php
class EventoController extends Zend_Controller_Action {

	public function init() {
      $sessao = Zend_Auth::getInstance()->getIdentity();
		$this->view->menu = new Application_Form_Menu($this->view, 'inicio', $sessao['administrador']);
	}
   
   private function autenticacao() {
		if (!Zend_Auth::getInstance()->hasIdentity()) {
			return $this->_helper->redirector->goToRoute(array(), 'login', true);
		}
	}

   /**
    * Mapeada como
    *    /submissao 
    */
	public function indexAction() {
      $this->autenticacao();
		$this->view->headLink()->appendStylesheet($this->view->baseUrl('css/tabela_sort.css'));
		$this->view->headLink()->appendStylesheet($this->view->baseUrl('css/tipsy.css'));
      
      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-1.6.2.min.js'));
		$this->view->headScript()->appendFile($this->view->baseUrl('js/jquery.dataTables.js'));
		$this->view->headScript()->appendFile($this->view->baseUrl('js/jquery.tipsy.js'));
		$this->view->headScript()->appendFile($this->view->baseUrl('js/evento/inicio.js'));
		

		$this->view->menu->setAtivo('submissao');
		$sessao = Zend_Auth :: getInstance()->getIdentity();

		$idPessoa = $sessao["idPessoa"];
		$idEncontro = $sessao["idEncontro"];

		$evento = new Application_Model_Evento();
		$select = $evento->select();
		$rows = $evento->fetchAll($select->where('responsavel = ?', $idPessoa)->where('id_encontro = ?', $idEncontro));
		$this->view->meusEventos = array ();

		foreach ($rows as $linha) {
			$tipo_evento = $linha->findDependentRowset('Application_Model_TipoEvento')->current();
			
         ($linha->validada) ?
            $linha->validada = '<i class="icon-thumbs-up"></i> Sim' :
            $linha->validada = '<i class="icon-thumbs-down"></i> Não';
         
			$linha->data_submissao = date('d/m/Y', strtotime($linha->data_submissao));

			$this->view->meusEventos[] = array_merge($tipo_evento->toArray(), $linha->toArray());
		}
	}
   
   public function ajaxBuscarAction() {
      $this->autenticacao();
      $this->_helper->layout()->disableLayout();
      $this->_helper->viewRenderer->setNoRender(true);
      
      $sessao = Zend_Auth::getInstance()->getIdentity();
      $idPessoa = $sessao["idPessoa"];
      $idEncontro = $sessao["idEncontro"];
      
      $eventos = new Application_Model_Evento();
      $data = array(
          $idEncontro,
          $idPessoa,
          $idPessoa,
          $this->_request->getParam("data"),
          intval($this->_request->getParam("id_tipo_evento")),
          $this->_request->getParam("termo")
      );
      $rs = $eventos->buscaEventos($data);
      
      $json = new stdClass;
      $json->size = count($rs);
      $json->itens = array();

		foreach($rs as $value) {
			$descricao = $value['nome_evento'];
			if (! empty($value['descricao'])) {
				$descricao = "{$descricao} ({$value['descricao']})";
			}
			
         $json->itens[] = array(
             "{$value['nome_tipo_evento']}",
             "{$descricao}",
             "{$value['data']}",
             "{$value['h_inicio']} - {$value['h_fim']}",
             "<a id=\"{$value['evento']}\" class=\"marcar no-bottom\">
                  <i class=\"icon-bookmark\"></i> Marcar</a>"
         );
      }
      
      header("Pragma: no-cache");
      header("Cache: no-cahce");
      header("Cache-Control: no-cache, must-revalidate");
      header("Content-type: text/json");
      echo json_encode($json);
   }
   
   public function ajaxInteresseAction() {
      $this->autenticacao();
      $this->_helper->layout()->disableLayout();
      $this->_helper->viewRenderer->setNoRender(true);
      
      $sessao = Zend_Auth::getInstance()->getIdentity();
      $idPessoa = $sessao["idPessoa"];
      
      $json = new stdClass;
      try {
         $eventoDemanda = new Application_Model_EventoDemanda();
         $data = array(
             'evento' => intval($this->_request->getParam("id")),
             'id_pessoa' => $idPessoa
         );
         $eventoDemanda->insert($data);
         $json->ok = true;
      } catch (Zend_Db_Exception $ex) {
         $json->ok = false;
         $json->erro = "Ocorreu um erro inesperado ao marcar interesse em evento.<br/>Detalhes"
                 . $ex->getMessage();
      }
      header("Pragma: no-cache");
      header("Cache: no-cahce");
      header("Cache-Control: no-cache, must-revalidate");
      header("Content-type: text/json");
      echo json_encode($json);
   }

	public function submeterAction() {
      $this->autenticacao();
		$this->view->menu->setAtivo('submissao');
		$this->view->headLink()->appendStylesheet($this->view->baseUrl('css/form-evento.css'));
		$data = $this->getRequest()->getPost();
		if (isset ($data['cancelar'])) {
			return $this->_helper->redirector->goToRoute(array(), 'submissao', true);
		}

		$sessao = Zend_Auth::getInstance()->getIdentity();
		$idPessoa = $sessao["idPessoa"];
		$idEncontro = $sessao["idEncontro"];

		$form = new Application_Form_Evento();
		$this->view->form = $form;

		if ($this->getRequest()->isPost() && $form->isValid($data)) {
			$evento = new Application_Model_Evento();
			$data = $form->getValues();
			try {
				$data['id_encontro'] = $idEncontro;
				$data['responsavel'] = $idPessoa;
				$evento->insert($data);
            
            $this->_helper->flashMessenger->addMessage(
                    array('success' => 'Trabalho submetido. Aguarde contato por e-mail.'));
				return $this->_helper->redirector->goToRoute(array (
					'controller' => 'evento'
				), null, true);
			} catch (Zend_Db_Exception $ex) {
            $this->_helper->flashMessenger->addMessage(
                     array('error' => 'Ocorreu um erro inesperado.<br/>Detalhes: '
                         . $ex->getMessage()));
			}
		}
	}

	public function editarAction() {
      $this->autenticacao();
		$this->view->menu->setAtivo('submissao');
		$this->view->headLink()->appendStylesheet($this->view->baseUrl('css/tabela_sort.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/form-evento.css'));
		$this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-1.6.2.min.js'));
		$this->view->headScript()->appendFile($this->view->baseUrl('js/jquery.dataTables.js'));
		
		$data = $this->getRequest()->getPost();

		$idEvento = $this->_request->getParam('id', 0);
		$form = new Application_Form_Evento();
		$this->view->form = $form;

		$evento = new Application_Model_Evento();
		$evento_realizacao = new Application_Model_EventoRealizacao();

		$select = $evento->select();
		$select_realizacao = $evento_realizacao->select();
      
      /* lista de horários */
		$this->view->realizacao = array ();
		$linhas_realizacao = $evento_realizacao->fetchAll($select_realizacao->where('id_evento = ?', $idEvento));

		foreach ($linhas_realizacao as $linha) {
			$sala = $linha->findDependentRowset('Application_Model_Sala')->current();
			$linha->data= date('d/m/Y', strtotime($linha->data));
			$concatena = array_merge($linha->toArray(), $sala->toArray());
			$this->view->realizacao[] = $concatena;
		}
      
      $sessao = Zend_Auth::getInstance()->getIdentity();
      $idPessoa = $sessao["idPessoa"];
      $admin = $sessao["administrador"]; // boolean
      
  		if (isset($data['cancelar'])) {
         return $this->redirecionar($admin, $idEvento);
      }
      
		if ($this->getRequest()->isPost()) {
         if ($form->isValid($data)) {
            $data = $form->getValues();
            $select = $evento->getAdapter()->quoteInto('id_evento = ?', $idEvento);
            try {
               if ($idPessoa != $data['responsavel'] and ! $admin) {
                  $this->_helper->flashMessenger->addMessage(
                          array('error' => 'Somente o autor pode editar o Evento.'));
                  return $this->redirecionar();
               } else {
                  $evento->update($data, $select);
                  $this->_helper->flashMessenger->addMessage(
                        array('success' => 'Evento atualizado com sucesso.'));
                  return $this->redirecionar($admin, $idEvento);
               }
            } catch (Zend_Db_Exception $ex) {
               $this->_helper->flashMessenger->addMessage(
                     array('error' => 'Ocorreu um erro inesperado.<br/>Detalhes: '
                         . $ex->getMessage()));
            }
         } else {
            $form->populate($data);
         }
      } else {
         $row = $evento->fetchRow($select->where('id_evento = ?', $idEvento));
         if (! is_null($row)) {
            $array = $row->toArray();
            // verificar se ao editar o id_pessoa da sessão é o mesmo do evento
            // e se não é admin, sendo admin é permitido editar
            if ($idPessoa != $array['responsavel'] and ! $admin) {
               $this->_helper->flashMessenger->addMessage(
                     array('error' => 'Somente o autor pode editar o Evento.'));
               return $this->redirecionar();
            } else {
               $form->populate($row->toArray());
            }
         } else {
            $this->_helper->flashMessenger->addMessage(
                     array('error' => 'Evento não encontrado.'));
            return $this->redirecionar($admin, $idEvento);
         }
      }
   }
   
   public function programacaoAction() {
      $this->view->menu->setAtivo('programacao');
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/screen.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/prettify.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/jqueryui-bootstrap/jquery-ui-1.8.16.custom.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/jqueryui-bootstrap/jquery.ui.1.8.16.ie.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/evento/programacao.css'));
      
      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-1.6.2.min.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-ui-1.8.16.custom.min.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/prettify.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/init.prettify.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/evento/programacao.js'));
      
      $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'staging');
		$idEncontro = $config->encontro->codigo;
      $model = new Application_Model_Evento();
      $this->view->lista = $model->programacao($idEncontro);
   }
   
   public function interesseAction() {
      $this->autenticacao();
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/tabela_sort.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/screen.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/jqueryui-bootstrap/jquery-ui-1.8.16.custom.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/jqueryui-bootstrap/jquery.ui.1.8.16.ie.css'));
      
      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-1.6.2.min.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-ui-1.8.16.custom.min.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery.dataTables.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/evento/busca_evento.js'));

      $sessao = Zend_Auth::getInstance()->getIdentity();
      $idEncontro = $sessao["idEncontro"];
      $idPessoa = $sessao["idPessoa"];

      $eventos = new Application_Model_Evento();
      // usada para mostrar dias que possuem eventos
      $this->view->listaEvento = $eventos->getEventos($idEncontro);
      $this->view->idEncontro = $idEncontro;
      $this->view->idPessoa = $idPessoa;

      $tipoEventos = new Application_Model_TipoEvento();
      $this->view->tipoEvento = $tipoEventos->fetchAll();

      $eventoRealizacao = new Application_Model_EventoRealizacao();
      $eventoRealizacao = $eventoRealizacao->fetchAll();

      $this->view->eventosTabela = array();
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
   
   public function desfazerInteresseAction() {
      $this->autenticacao();
      $sessao = Zend_Auth::getInstance()->getIdentity();
      $idPessoa = $sessao["idPessoa"];
      
      $model = new Application_Model_EventoDemanda();
      
      if ($this->getRequest()->isPost()) {
         $del = $this->getRequest()->getPost('del');
         $id = (int) $this->getRequest()->getPost('id');
         
         if (!isset($id) || $id == 0) {
            $this->_helper->flashMessenger->addMessage(
                     array('error' => 'Evento não encontrado.'));
            $this->_helper->redirector->goToRoute(array(
             'controller' => 'participante',
             'action' => 'index'), 'default', true);
            
         } else if ($del == "confimar") {
            
            try {
               $where = array(
                   "evento = ?"    => $id,
                   "id_pessoa = ?" => $idPessoa);
               $model->delete($where);
               $this->_helper->flashMessenger->addMessage(
                        array('success' => 'Evento desmarcado com sucesso.'));
            } catch (Exception $e) {
               $this->_helper->flashMessenger->addMessage(
                       array('error' => 'Ocorreu um erro inesperado.<br/>Detalhes: '
                           . $e->getMessage()));
            }
         }
         $this->_helper->redirector->goToRoute(array(
             'controller' => 'participante',
             'action' => 'index'), 'default', true);
      } else {
         $id = $this->_getParam('id', 0);
         if ($id == 0) {
            $this->_helper->flashMessenger->addMessage(
                     array('error' => 'Evento não encontrado.'));
            $this->_helper->redirector->goToRoute(array(
             'controller' => 'participante',
             'action' => 'index'), 'default', true);
            
         } else {
            $idEncontro = $sessao["idEncontro"];
            $where = array($idEncontro, $idPessoa, $id);
            try {
               $this->view->evento = $model->lerEvento($where);
            } catch (Exception $e) {
               $this->_helper->flashMessenger->addMessage(
                       array('error' => 'Ocorreu um erro inesperado.<br/>Detalhes: '
                           . $e->getMessage()));
               $this->_helper->redirector->goToRoute(array(
                  'controller' => 'participante',
                  'action' => 'index'), 'default', true);
            }
         }
      }
   }
   
   /**
    * Mapeada como
    *    /e/:id 
    */
   public function verAction() {
      $this->view->menu->setAtivo('programacao');
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/screen.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/prettify.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/jqueryui-bootstrap/jquery-ui-1.8.16.custom.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/jqueryui-bootstrap/jquery.ui.1.8.16.ie.css'));
      
      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-1.6.2.min.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-ui-1.8.16.custom.min.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/prettify.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/init.prettify.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/evento/ver.js'));
      
      try {
         $idEvento = $this->_request->getParam('id', 0);
         $evento = new Application_Model_Evento();
         $data = $evento->buscaEventoPessoa($idEvento);
         if (empty($data)) {
            $this->_helper->flashMessenger->addMessage(
                        array('notice' => 'Evento não encontrado.'));
         } else {
            $this->view->evento = $data[0];
         }
      } catch (Exception $e) {
         $this->_helper->flashMessenger->addMessage(
                       array('error' => 'Ocorreu um erro inesperado.<br/>Detalhes: '
                           . $e->getMessage()));
      }
   }
   
   public function outrosPalestrantesAction() {
      $this->view->menu->setAtivo('submissao');
      
      $evento = new Application_Model_Evento();
      $idEvento = $this->_request->getParam('id', 0);
      
      $cancelar = $this->getRequest()->getPost('cancelar');
      if (isset($cancelar)) {
         return $this->_helper->redirector->goToRoute(array(), 'submissao', true);
      }
      
      if ($this->getRequest()->isPost()) {
         $submit = $this->getRequest()->getPost('submit');
         if ($submit == "confimar") {
            $array_id_pessoas = explode(",", $this->getRequest()->getPost('array_id_pessoas'));
            
            if (count($array_id_pessoas) == 1 && empty($array_id_pessoas[0])) {
               $this->_helper->flashMessenger->addMessage(
                        array('notice' => 'Nenhum palestrante foi selecionado.'));
            } else {
               try {
                  $numParticipantes = 0;
                  foreach ($array_id_pessoas as $value) {
                     $value = intval($value);
                     $numParticipantes += $evento->adicionarPalestranteEvento($idEvento, $value);
                  }
                  $this->_helper->flashMessenger->addMessage(
                             array('success' => "{$numParticipantes} palestrante(s) adicionado(s) ao evento com sucesso."));
               } catch (Zend_Db_Exception $ex) {
                  if ($ex->getCode() == 23505) {
                     $this->_helper->flashMessenger->addMessage(
                             array('error' => 'Palestrante(s) já existe(m) no evento.'));
                  } else {
                     $this->_helper->flashMessenger->addMessage(
                             array('error' => 'Ocorreu um erro inesperado.<br/>Detalhes: '
                                 . $ex->getMessage()));
                  }
               }
            }
         }
      }
      
      // listar palestrantes
      try {
         $data = $evento->buscaEventoPessoa($idEvento);
         if (empty($data)) {
            $this->_helper->flashMessenger->addMessage(
                    array('notice' => 'Evento não encontrado.'));
         } else {
            $this->view->evento = $data[0];
            
            // checa as permissão do usuário, para editar somente seus eventos
            $sessao = Zend_Auth::getInstance()->getIdentity();
            if ($this->view->evento['id_pessoa'] != $sessao['idPessoa']) {
               $this->_helper->flashMessenger->addMessage(
                    array('notice' => 'Você não tem permissão de editar este evento.'));
               return $this->_helper->redirector->goToRoute(array(), 'submissao', true);
            }
         }

         $palestrantes = $evento->getAdapter()->fetchAll("SELECT p.id_pessoa,
                  p.nome, p.email
           FROM evento_palestrante ep
           INNER JOIN pessoa p ON ep.id_pessoa = p.id_pessoa
           WHERE ep.id_evento = ?", array($idEvento));
         $this->view->palestrantes = $palestrantes;
      } catch (Exception $e) {
         $this->_helper->flashMessenger->addMessage(
                 array('error' => 'Ocorreu um erro inesperado.<br/>Detalhes: '
                     . $e->getMessage()));
      }
   }
   
   public function ajaxBuscarParticipanteAction() {
      $this->_helper->layout()->disableLayout();
      $this->_helper->viewRenderer->setNoRender(true);
      $sessao = Zend_Auth::getInstance()->getIdentity();
      $idPessoa = $sessao["idPessoa"];
      $idEncontro = $sessao["idEncontro"];
      
      $model = new Application_Model_Pessoa();
      $termo = $this->_request->getParam("termo", "");
      
      $json = new stdClass;
      $json->results = array();
      
      $rs = $model->getAdapter()->fetchAll(
         "SELECT p.id_pessoa,
               p.email
         FROM pessoa p
         INNER JOIN encontro_participante ep ON p.id_pessoa = ep.id_pessoa
         WHERE p.email LIKE lower(?)
         AND p.id_pessoa <> ?
         AND ep.id_encontro = ?
         AND ep.validado = true ",
              array("{$termo}%", $idPessoa, $idEncontro));
      $json->size = count($rs);
      foreach ($rs as $value) {
         $obj = new stdClass;
         $obj->id = "{$value['id_pessoa']}";
         $obj->text = "{$value['email']}";
         array_push($json->results, $obj);
      }
      
      header("Pragma: no-cache");
      header("Cache: no-cahce");
      header("Cache-Control: no-cache, must-revalidate");
      header("Content-type: text/json");
      echo json_encode($json);
   }
   
   public function deletarPalestranteAction() {
      $this->_helper->layout()->disableLayout();
      $this->_helper->viewRenderer->setNoRender(true);
      
      $pessoa = $this->_getParam('pessoa', 0);
      $evento = $this->_getParam('evento', 0);
      if ($pessoa > 0 and $evento > 0) {
         $model = new Application_Model_Evento();
         try {
            $model->getAdapter()->delete("evento_palestrante",                  "id_pessoa = {$pessoa} AND id_evento = {$evento}");
            $this->_helper->flashMessenger->addMessage(
                    array('success' => 'Palestrante removido do evento com sucesso.'));
         } catch (Exception $e) {
            $this->_helper->flashMessenger->addMessage(
                     array('error' => 'Ocorreu um erro inesperado.<br/>Detalhes: '
                         . $e->getMessage()));
         }
      } else {
         $this->_helper->flashMessenger->addMessage(
                        array('notice' => 'Nenhum palestrante foi selecionado.'));
      }
      $this->_helper->redirector->goToRoute(array('controller' => 'evento',
          'action' => 'outros-palestrantes', 'id' => $evento), 'default', true);
   }
   
   public function tagsAction() {
      $model = new Application_Model_EventoTags();
      $idEvento = $this->_getParam('id', 0);
      $this->view->tags = $model->listarPorEvento($idEvento);
      $this->view->id_evento = $idEvento;
   }
   
   public function ajaxBuscarTagsAction() {
      $this->_helper->layout()->disableLayout();
      $this->_helper->viewRenderer->setNoRender(true);
      
      $model = new Application_Model_EventoTags();
      $termo = $this->_getParam('termo', "");
      $rs = $model->listarTags($termo);
      
      $json = new stdClass;
      $json->itens = array();
      foreach ($rs as $value) {
         $obj = new stdClass;
         $obj->id = "{$value['id']}";
         $obj->text = "{$value['descricao']}";
         array_push($json->itens, $obj);
      }
      
      header("Pragma: no-cache");
      header("Cache: no-cahce");
      header("Cache-Control: no-cache, must-revalidate");
      header("Content-type: text/json");
      echo json_encode($json);
   }
   
   public function ajaxSalvarTagAction() {
      $this->_helper->layout()->disableLayout();
      $this->_helper->viewRenderer->setNoRender(true);
      
      $model = new Application_Model_EventoTags();
      $json = new stdClass;
      try {
         $id_tag = $this->_getParam('id', 0);
         $id_evento = $this->_getParam('id_evento', 0);
         $id = $model->insert(array('id_tag' => $id_tag, 'id_evento' => $id_evento));
         if ($id > 0) {
            $json->ok = true;
            $json->msg = "Tag adicionada com sucesso.";
         } else {
            $json->ok = false;
            $json->erro = "Ocorreu um erro inesperado ao salvar <b>tag</b>.";
         }
      } catch (Exception $e) {
         if ($e->getCode() == 23505) {
            $json->erro = "Tag já existe.";
         } else {
            $json->erro = "Ocorreu um erro inesperado ao salvar <b>tag</b>.<br/>Detalhes"
                    . $e->getMessage();
         }
         $json->ok = false;
      }
      
      header("Pragma: no-cache");
      header("Cache: no-cahce");
      header("Cache-Control: no-cache, must-revalidate");
      header("Content-type: text/json");
      echo json_encode($json);
   }
   
   public function ajaxCriarTagAction() {
      $this->_helper->layout()->disableLayout();
      $this->_helper->viewRenderer->setNoRender(true);
      
      $model = new Application_Model_EventoTags();
      $json = new stdClass;
      try {
         $descricao = $this->_getParam('descricao', "");
         $id = $model->getAdapter()->insert("tags", array('descricao' => $descricao));
         $json->ok = true;
         $json->id = $id;
      } catch (Exception $e) {
         if ($e->getCode() == 23505) {
            $json->erro = "Tag já existe.";
         } else {
            $json->erro = "Ocorreu um erro inesperado ao salvar <b>tag</b>.<br/>Detalhes"
                    . $e->getMessage();
         }
         $json->ok = false;
      }
      
      header("Pragma: no-cache");
      header("Cache: no-cahce");
      header("Cache-Control: no-cache, must-revalidate");
      header("Content-type: text/json");
      echo json_encode($json);
   }

   private function redirecionar($admin = false, $id = 0) {
      if ($admin) {
         $this->_helper->redirector->goToRoute(array(
             'module' => 'admin',
             'controller' => 'evento',
             'action' => 'detalhes',
             'id' => $id), 'default', true);
      } else {
         $this->_helper->redirector->goToRoute(array(), 'submissao', true);
      }
   }
}