<?php
class EventoController extends Zend_Controller_Action {

	public function init() {
		//Initialize action controller here 
		if (!Zend_Auth :: getInstance()->hasIdentity()) {
			return $this->_helper->redirector->goToRoute(array (
				'controller' => 'index',
				'action' => 'login'
			), null, true);
		}
		$this->view->menu = new Application_Form_Menu($this->view, 'inicio');
	}

	public function indexAction() {
		// TODO: criar route para sige.comsolid.org/submissao
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
		$this->view->headLink()->appendStylesheet($this->view->baseUrl('css/form.css'));
		$data = $this->getRequest()->getPost();
		if (isset ($data['cancelar'])) {
			return $this->_helper->redirector->goToRoute(array(
				'controller' => 'evento'
			), null, true);
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
				$m_encontro = new Application_Model_Encontro();

				$data['id_encontro'] = $m_encontro->getEncontroAtual();
				$data['responsavel'] = $idPessoa;
				$evento->insert($data);

				return $this->_helper->redirector->goToRoute(array (
					'controller' => 'evento'
				), null, true);
			} catch (Zend_Db_Exception $ex) {
				// TODO: colocar erro em flashMessage
				echo $ex->getMessage() . $ex->getCode();
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
		$this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-1.6.2.min.js'));
		$this->view->headScript()->appendFile($this->view->baseUrl('js/jquery.dataTables.js'));
		//$this->view->headScript()->appendFile($this->view->baseUrl('js/evento/inicio.js'));
		
		$data = $this->getRequest()->getPost();
		
		if (isset ($data['cancelar'])) {
			return $this->_helper->redirector->goToRoute(array (
				'controller' => 'evento'
			), null, true);
		}
		$sessao = Zend_Auth::getInstance()->getIdentity();
		$this->view->headLink()->appendStylesheet($this->view->baseUrl('css/form.css'));

		$idPessoa = $sessao["idPessoa"];
		$idEncontro = $sessao["idEncontro"];
		$idEvento = $this->_request->getParam('id', 0);

		$form = new Application_Form_EventoEditar();
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
				unset ($data['data_submissao']);

				$evento->update($data, $select);

				return $this->_helper->redirector->goToRoute(array (
					'controller' => 'evento'
				), null, true);

			} catch (Zend_Db_Exception $ex) {
				// TODO: colocar erro em flashMessage
				echo $ex->getMessage() . $ex->getCode();
			}
		}
	}
   
   public function programacaoAction() {
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/screen.css'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-1.6.2.min.js'));
      $sessao = Zend_Auth::getInstance()->getIdentity();
      $model = new Application_Model_Evento();
      $this->view->lista = $model->programacao($sessao["idEncontro"]);
   }

	private function deprecated($controller, $view) {
		$this->view->deprecated = "You are using a deprecated controller/view: {$controller}/{$view}";
	}
}