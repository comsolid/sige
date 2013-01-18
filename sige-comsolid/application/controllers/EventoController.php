<?php
class EventoController extends Zend_Controller_Action {

	public function init() {
		//Initialize action controller here 
		if (!Zend_Auth :: getInstance()->hasIdentity()) {
			return $this->_helper->redirector->goToRoute(array (), 'login', true);
		}
		$this->view->menu = new Application_Form_Menu($this->view, 'inicio');
	}

   /**
    * Mapeada como
    *    /submissao 
    */
	public function indexAction() {
		$this->view->headLink()->appendStylesheet($this->view->baseUrl('css/tabela_sort.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/font-awesome.min.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/font-awesome-ie7.min.css'));
		$this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-1.6.2.min.js'));
		$this->view->headScript()->appendFile($this->view->baseUrl('js/jquery.dataTables.js'));
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
	
	public function addenvpAction() {
		$this->view->headLink()->appendStylesheet($this->view->baseUrl('css/form.css'));
		//$sessao = Zend_Auth :: getInstance()->getIdentity();
		//	$idEncontro = $sessao["idEncontro"];
		$this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-1.6.2.min.js'));
		$this->view->headScript()->appendFile($this->view->baseUrl('js/evento/busca_evento.js'));
		$eventos = new Application_Model_Evento();
		$this->view->listaEvento = $eventos->getEventos(3);
		
		$config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'staging');
		$this->view->idEncontro = $config->encontro->codigo;
		$tipoEventos = new Application_Model_TipoEvento();
		$this->view->tipoEvento = $tipoEventos->fetchAll();
	}
   
   public function ajaxBuscarAction() {
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
         $json->itens[] = array(
             "{$value['nome_tipo_evento']}",
             "{$value['nome_evento']}",
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
         // $e = '{ erro:true,"size":' . count($data) . ',"aaData":[]}';
         // echo $e;
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

   /**
    * @deprecated use ajaxBuscarAction
    * @return type 
    */
	public function buscaAction() {
		$this->_helper->layout()->disableLayout();
		$sessao = Zend_Auth :: getInstance()->getIdentity();
		$idPessoa = $sessao["idPessoa"];
		$conte=0;
		if ($this->_request->getParam("acao") == 'add') {
			try {
				$eventoDemanda = new Application_Model_EventoDemanda();
				$data = array (
					'evento' => intval($this->_request->getParam("evento")),
					'id_pessoa' => $this->_request->getParam("idPessoa")
				);
				$eventoDemanda->insert($data);

			} catch (Zend_Db_Exception $ex) {
				$e = '{ erro:true,"size":'.count($data).',"aaData":[]}';
				echo $e;
			}

			$eventos = new Application_Model_Evento();
			$data = array (
				intval($this->_request->getParam("idEncontro")),
				$idPessoa,
				$this->_request->getParam("data"),
				intval($this->_request->getParam("id_tipo_evento")),
				$this->_request->getParam("nome_evento")
			);
			$data = $eventos->buscaEventos($data);
			$e = '{"size":'.count($data).',"aaData":[';
			if (isset ($data))
				foreach ($data as $value) {
					if($conte!=0){$e .=',';}
					$e .= '["' . $value['nome_tipo_evento'] . '","' . $value['nome_evento'] . '","' . $value['data'] . '","'.$value['h_inicio'] . '","'.$value['h_fim'] . '","<a id=\"'. $value['evento'].'\">ADD</a>"]';
					$conte++;
				}
			$e .= ']}';
			echo $e;
			return;

		} else {

			$eventos = new Application_Model_Evento();
			$data = array (
				intval($this->_request->getParam("idEncontro")),
				$idPessoa,
				$this->_request->getParam("data"),
				intval($this->_request->getParam("id_tipo_evento")),
				$this->_request->getParam("nome_evento")
			);
			$data = $eventos->buscaEventos($data);

		$e = '{"size":'.count($data).',"aaData":[';
			if (isset ($data))
				foreach ($data as $value) {
					if($conte!=0){$e .=',';}
					$e .= '["' . $value['nome_tipo_evento'] . '","' . $value['nome_evento'] . '","' . $value['data'] . '","' . $value['h_inicio'] . '","' . $value['h_fim'] . '","<a id=\"' . $value['evento']. '\">ADD</a>"]';
					$conte++;
				}
			$e .= ']}';
			echo $e;
		}

	}

	public function buscaadminAction() {
		$this->_helper->layout()->disableLayout();
		$sessao = Zend_Auth :: getInstance()->getIdentity();
		$idEncontro = $sessao["idEncontro"];

		$eventos = new Application_Model_Evento();
		$data = array (
			intval($idEncontro), $this->_request->getParam("nome_evento"),intval($this->_request->getParam("tipo_evento")),intval($this->_request->getParam("atividade")));

		//var_dump($data);

		$data = $eventos->buscaEventosAdmin($data);

		$e = '<?xml version="1.0"?><busca><tbody id="resultadoAtividades"><![CDATA[';
		if (isset ($data))
			foreach ($data as $value) {
				if($value['validada']){
					$validada = "T";
				}else{
					$validada = "F";
				}
				
				$e .= '<tr>
							<td>' . $value['nome_tipo_evento'] . '</td>
							<td>' . $value['nome_evento'] . '</td>
							<td>' . $validada . '</td>
							<td>' . $value['data_submissao'] . '</td>
							<td>' . $value['nome'] . '</td>
							<td><a href=' . $this->view->baseUrl('/administrador/verdetalhesevento/id_evento/'.$value["id_evento"]) . '>Detalhes</a><td>		
						</tr>';
				//	echo $value['nome_tipo_evento'];

			}

		$this->getResponse()->setHeader('Content-Type', 'text/xml');
		$e .= ']]></tbody></busca>';

		echo $e;
		return;
	}

	/**
	 * @Deprecated
	 */
	public function meuseventosAction() {
		$this->deprecated("evento", "meuseventos");
		$this->view->headLink()->appendStylesheet($this->view->baseUrl('css/tabela_sort.css'));
		$this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-1.6.2.min.js'));
		$this->view->headScript()->appendFile($this->view->baseUrl('js/jquery.dataTables.js'));
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
			($linha->validada) ? $linha->validada = 'Sim' : $linha->validada = 'Não';
			$linha->data_submissao = date('d/m/Y', strtotime($linha->data_submissao));

			$this->view->meusEventos[] = array_merge($tipo_evento->toArray(), $linha->toArray());
		}
	}

	/**
	 * @Deprecated
	 */
	public function addAction() {
		$this->deprecated("evento", "add");
		$data = $this->getRequest()->getPost();
		if (isset ($data['cancelar'])) {
			return $this->_helper->redirector->goToRoute(array (
				'controller' => 'evento',
				'action' => 'meuseventos'
			), null, true);
		}

		$sessao = Zend_Auth :: getInstance()->getIdentity();

		$this->view->headLink()->appendStylesheet($this->view->baseUrl('css/form.css'));
		$idPessoa = $sessao["idPessoa"];
		$idEncontro = $sessao["idEncontro"];

		$form = new Application_Form_Evento();
		$form->setAction($this->view->url(array (
			'controller' => 'evento',
			'action' => 'add'
		)));
		$this->view->form = $form;

		$data = $this->getRequest()->getPost();

		if ($this->getRequest()->isPost() && $form->isValid($data)) {
			$evento = new Application_Model_Evento();
			$data = $form->getValues();
			try {
				$m_encontro = new Application_Model_Encontro();

				$data['id_encontro'] = $m_encontro->getEncontroAtual();
				$data['responsavel'] = $idPessoa;
				$evento->insert($data);

				return $this->_helper->redirector->goToRoute(array (
					'controller' => 'evento',
					'action' => 'meuseventos'
				), null, true);
			} catch (Zend_Db_Exception $ex) {
				// 23505UNIQUE VIOLATION
				echo $ex->getMessage() . $ex->getCode();
				//throw $ex;
			}
		}
	}

	public function submeterAction() {
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
				// DONE: colocar erro em flashMessage
				// echo $ex->getMessage() . $ex->getCode();
            $this->_helper->flashMessenger->addMessage(
                     array('error' => 'Ocorreu um erro inesperado.<br/>Detalhes: '
                         . $ex->getMessage()));
			}
		}
	}

	/**
	 * @Deprecated
	 */
	public function editAction() {
		$this->deprecated("evento", "edit");
		$this->view->headLink()->appendStylesheet($this->view->baseUrl('css/tabela_sort.css'));
		$this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-1.6.2.min.js'));
		$this->view->headScript()->appendFile($this->view->baseUrl('js/jquery.dataTables.js'));
		//$this->view->headScript()->appendFile($this->view->baseUrl('js/evento/inicio.js'));
		
		$data = $this->getRequest()->getPost();
		
		if (isset ($data['cancelar'])) {
			return $this->_helper->redirector->goToRoute(array (
				'controller' => 'evento'
			), null, true);
		}
		$sessao = Zend_Auth :: getInstance()->getIdentity();
		$this->view->headLink()->appendStylesheet($this->view->baseUrl('css/form.css'));

		$idPessoa = $sessao["idPessoa"];
		$idEncontro = $sessao["idEncontro"];
		$idEvento = $this->_request->getParam('id_evento');

		$form = new Application_Form_EventoEditar();
		$form->setAction($this->view->url(array (
			'controller' => 'evento',
			'action' => 'edit'
		)));
		$this->view->form = $form;

		$pessoa = new Application_Model_Pessoa();
		$evento = new Application_Model_Evento();
		$evento_realizacao = new Application_Model_EventoRealizacao();

		$select = $evento->select();
		$select_realizacao = $evento_realizacao->select();

		$result = $pessoa->find($idPessoa);
		$linha_pessoa = $result[0];

		$this->view->realizacao = array ();

		$linhas_realizacao = $evento_realizacao->fetchAll($select_realizacao->where('id_evento = ?', $idEvento));

		foreach ($linhas_realizacao as $linha) {

			$sala = $linha->findDependentRowset('Application_Model_Sala')->current();
			$linha->data= date('d/m/Y', strtotime($linha->data));
			$concatena = array_merge($linha->toArray(), $sala->toArray());
			$this->view->realizacao[] = $concatena;

		}

		$rows = $evento->fetchAll($select->where('id_evento = ?', $idEvento)->where('responsavel = ?', $idPessoa));

		if (count($rows) > 0) {

			//Verifica se o evento foi validado e coloca 'sim' ou 'não' no formulario de acordo com isso
			 ($rows->current()->validada) ? $rows->current()->validada = 'Sim' : $rows->current()->validada = 'Não';

			//Coloca data no formato correto 
			$rows->current()->data_submissao = date('d/m/Y', strtotime($rows->current()->data_submissao));

			$form->populate(array_merge($linha_pessoa->toArray(), $rows->current()->toArray()));
		}

		if ($this->getRequest()->isPost() && $form->isValid($data)) {

			$data = $form->getValues();

			$select = $evento->getAdapter()->quoteInto('id_evento = ?', $idEvento);

			try {
				//retira os campos que nunca vao sofrer alteração
				unset ($data['validada']);
				unset ($data['nome']);

				$evento->update($data, $select);

				/*return $this->_helper->redirector->goToRoute(array (
					'controller' => 'evento',
					'action' => 'meuseventos'
				), null, true);*/

			} catch (Zend_Db_Exception $ex) {
				// 23505UNIQUE VIOLATION
				echo $ex->getMessage() . $ex->getCode();
				//throw $ex;
			}

		}
	}

	public function editarAction() {
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
               // DONE: colocar erro em flashMessage
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
               // DONE: colocar erro em flashMessage
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
      $this->view->menu->setAtivo('submissao');
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/screen.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/prettify.css'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-1.6.2.min.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/prettify.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/init.prettify.js'));
      $sessao = Zend_Auth::getInstance()->getIdentity();
      $model = new Application_Model_Evento();
      $this->view->lista = $model->programacao($sessao["idEncontro"]);
   }
   
   public function interesseAction() {
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/tabela_sort.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/screen.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/jqueryui-bootstrap/jquery-ui-1.8.16.custom.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/jqueryui-bootstrap/jquery.ui.1.8.16.ie.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/font-awesome.min.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/font-awesome-ie7.min.css'));
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
      
      $sessao = Zend_Auth::getInstance()->getIdentity();
      $idPessoa = $sessao["idPessoa"];
      
      $model = new Application_Model_EventoDemanda();
      
      if ($this->getRequest()->isPost()) {
         $del = $this->getRequest()->getPost('del');
         $id = (int) $this->getRequest()->getPost('id');
         
         if (!isset($id)) {
            $this->_helper->flashMessenger->addMessage(
                     array('error' => 'Evento não encontrado.'));
            
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
         $idEncontro = $sessao["idEncontro"];
         $where = array($idEncontro, $idPessoa, $id);
         try {
            $this->view->evento = $model->lerEvento($where);
         } catch (Exception $e) {
            $this->_helper->flashMessenger->addMessage(
                       array('error' => $e->getMessage()));
         }
      }
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

   private function deprecated($controller, $view) {
		$this->view->deprecated = "You are using a deprecated controller/view: {$controller}/{$view}";
	}
}