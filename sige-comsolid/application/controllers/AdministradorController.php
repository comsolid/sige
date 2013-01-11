<?php
class AdministradorController extends Zend_Controller_Action {
	
	public function init() {
		if (! Zend_Auth::getInstance ()->hasIdentity ()) {
			return $this->_helper->redirector->goToRoute ( array ('controller' => 'login', 'action' => 'login' ), null, true );
		}
		$this->autenticacao();
	}
	
	public function autenticacao() {
		
		$sessao = Zend_Auth::getInstance ()->getIdentity ();
		
		if (! $sessao ["administrador"]) {
			return $this->_helper->redirector->goToRoute ( array ('controller' => 'participante', 'action' => 'index' ), null, true );
		}
	
	}
	public function addautorAction() {
		if (! Zend_Auth::getInstance ()->hasIdentity ()) {
			return $this->_helper->redirector->goToRoute ( array ('controller' => 'login', 'action' => 'login' ), null, true );
		
		}
		if (intval($this->_request->idautor)==0) {
			return $this->_helper->redirector->goToRoute ( array ('controller' => 'administrador', 'action' => 'index' ), null, true );
		
		}else{
			$sessao = Zend_Auth :: getInstance()->getIdentity();
			$idEncontro = $sessao["idEncontro"];
	
			$eventos = new Application_Model_Evento();
			$data = array (intval($idEncontro), "",0,0);
	
			//var_dump($data);
	
			$this->view->eventos= $eventos->buscaEventosAdmin($data);
			
			if ($this->getRequest()->isPost() && intval($this->_request->idautor)>0 && intval($this->_request->evento)>0){
				$eventos->addResponsavel(array(intval($this->_request->idautor),intval($this->_request->evento)));
				return $this->_helper->redirector->goToRoute ( array ('controller' => 'administrador', 'action' => 'index' ), null, true );
			}
		}
	}
	public function indexAction() {
		$this->deprecated("administrador", "index");
		$sessao = Zend_Auth::getInstance ()->getIdentity ();
		$idEncontro = $sessao ["idEncontro"];
		
		//$select = "SELECT p.id_pessoa, nome, apelido, email, twitter, nome_municipio, apelido_instituicao, nome_caravana FROM encontro_participante ep INNER JOIN pessoa p ON (ep.id_pessoa = p.id_pessoa) LEFT OUTER JOIN instituicao i ON (ep.id_instituicao = i.id_instituicao) INNER JOIN municipio m ON (ep.id_municipio = m.id_municipio) LEFT OUTER JOIN caravana c ON (ep.id_caravana = c.id_caravana) WHERE id_encontro = ? AND id_tipo_usuario = 3;";
		

		$this->view->headLink ()->appendStylesheet ( $this->view->baseUrl ( 'css/tabela_sort.css' ) );
		$this->view->headScript ()->appendFile ( $this->view->baseUrl ( 'js/jquery-1.6.2.min.js' ) );
		$this->view->headScript ()->appendFile ( $this->view->baseUrl ( 'js/jquery.dataTables.js' ) );
		//$this->view->headScript()->appendFile($this->view->baseUrl('/js/administrador/inicio.js'));
		$this->view->headScript ()->appendFile ( $this->view->baseUrl ( 'js/administrador/busca_pessoas.js' ) );
		
		$this->view->idEncontro = $idEncontro;
	
	}
	
	public function buscaAction() {
		$this->_helper->layout()->disableLayout ();
		/*$this->view->headLink()->appendStylesheet('/css/tabela_sort.css');
		$this->view->headScript()->appendFile('/js/jquery-1.6.2.min.js');
		$this->view->headScript()->appendFile('/js/jquery.dataTables.js');
		//$this->view->headScript()->appendFile('/js/administrador/inicio.js');
		*/
		$pessoas = new Application_Model_Pessoa ();
		$dataTodosUsuarios = array (intval ( $this->_request->getParam ( "idEncontro" ) ), $this->_request->getParam ( "nomePessoa" ), $this->_request->getParam ( "tbusca" ));
		$data = $pessoas->buscaPessoas( $dataTodosUsuarios );
		
		
		/*$e = '<?xml version="1.0"?><busca><tbody id="resultado"><![CDATA[';*/
		$edom= '{"size":'.count($data).',"aaData":[';
		if (is_array($data)){
			$conte=0;
			
			foreach ( $data as $value ) {
				if($conte!=0){$edom.=',';}
				
				$isValidado = "";
				$acao = "";
				if($value['confirmado']){
					$isValidado = "Confimado!";
					$acao = '<a href=' . $this->view->baseUrl('/administrador/invalidapessoa/id_pessoa/'.$value["id_pessoa"]) . '>Invalidar</a>';
				}else{
					$acao = '<a href=' . $this->view->baseUrl('/administrador/validapessoa/id_pessoa/'.$value["id_pessoa"]) . '>Validar</a>';
					$isValidado = "NÃO CONFIMADO!";
					
				}
				
				$edom.= '["'.$value ['nome'].'","'. $value ['apelido'].'","'.$value ['email'].'","'.$value ['nome_municipio'].'","'.$value ['apelido_instituicao'].'","'.$value ['nome_caravana'].'","' .$isValidado.'","' .$acao.' <a title=\"Adicione esse autor ao evento desejado!\" href=\"' .$this->view->url(array('controller'=>'administrador','action'=>'addautor','idautor'=>$value ['id_pessoa']),null,true). '\" >Add Autor</a>"]';
				 $conte=1;
				/*$e .= '<tr>
												<td>' . $value ['nome'] . '</td>
												<td>' . $value ['apelido'] . '</td>
												<td>' . $value ['email'] . '</td>
												<td>' . $value ['twitter'] . '</td>
												<td>' . $value ['nome_municipio'] . '</td>
												<td>' . $value ['apelido_instituicao'] . '</td>
												<td>' . $value ['nome_caravana'] . '</td>
											</tr>';*/
			
		//	echo $value['nome_tipo_evento'];
			

			}
		}
		$edom.= ']}';
		//$this->getResponse ()->setHeader ( 'Cache-Control: no-cache', 'must-revalidate' );
		
		echo  $edom;
		
	}
	
	public function buscacoordenacaoAction() {
		$this->_helper->layout ()->disableLayout ();
		/*$this->view->headLink()->appendStylesheet('/css/tabela_sort.css');
		$this->view->headScript()->appendFile('/js/jquery-1.6.2.min.js');
		$this->view->headScript()->appendFile('/js/jquery.dataTables.js');
		//$this->view->headScript()->appendFile('/js/administrador/inicio.js');
		*/
		//autenticação e pega o id do encontro pela sessão
		$this->_helper->layout ()->disableLayout ();
		
		$pessoas = new Application_Model_Pessoa ();
		
		$data = array (intval ( $this->_request->getParam ( "idEncontro" ) ) );
		
		//var_dump($data);
		$dataCoordenacao = $pessoas->buscaPessoasCoordenacao ( $data );
		
		$e = '<?xml version="1.0"?><busca><tbody id="resultadoCoordenacao"><![CDATA[';
		if (isset ( $dataCoordenacao ))
			foreach ( $dataCoordenacao as $value ) {
				$e .= '<tr>
												<td>' . $value ['nome'] . '</td>
												<td>' . $value ['apelido'] . '</td>
												<td>' . $value ['email'] . '</td>
											</tr>';
			
		//	echo $value['nome_tipo_evento'];
			

			}
		
		$this->getResponse ()->setHeader ( 'Content-Type', 'text/xml' );
		$e .= ']]></tbody></busca>';
		
		echo $e;
	}
	
	public function buscaorganizacaoAction() {
		//autenticação e pega o id do encontro pela sessão
		$this->_helper->layout ()->disableLayout ();
		
		/*$this->view->headLink()->appendStylesheet('/css/tabela_sort.css');
		$this->view->headScript()->appendFile('/js/jquery-1.6.2.min.js');
		$this->view->headScript()->appendFile('/js/jquery.dataTables.js');
		*/
		//$this->view->headScript()->appendFile('/js/administrador/inicio.js');
		

		$pessoas = new Application_Model_Pessoa ();
		
		$data = array (intval ( $this->_request->getParam ( "idEncontro" ) ) );
		
		//var_dump($data);
		$dataOrganizacao = $pessoas->buscaPessoasOrganizacao ( $data );
		
		$e = '<?xml version="1.0"?><busca><tbody id="resultadoOrganizacao"><![CDATA[';
		if (isset ( $dataOrganizacao ))
			foreach ( $dataOrganizacao as $value ) {
				$e .= '<tr>
												<td>' . $value ['nome'] . '</td>
												<td>' . $value ['apelido'] . '</td>
												<td>' . $value ['email'] . '</td>
											</tr>';
			
		//	echo $value['nome_tipo_evento'];
			

			}
		
		$this->getResponse ()->setHeader ( 'Content-Type', 'text/xml' );
		$e .= ']]></tbody></busca>';
		
		echo $e;
	}
	
	public function buscacaravanaadministradorAction() {
		
		$this->view->headLink ()->appendStylesheet ( $this->view->baseUrl ( 'css/tabela_sort.css' ) );
		$this->view->headScript ()->appendFile ( $this->view->baseUrl ( 'js/jquery-1.6.2.min.js' ) );
		$this->view->headScript ()->appendFile ( $this->view->baseUrl ( 'js/jquery.dataTables.js' ) );
		// $this->view->headScript()->appendFile($this->view->baseUrl('/js/caravana/inicio.js'));
		$this->view->headScript ()->appendFile ( $this->view->baseUrl ( '/js/caravana/busca_caravana.js' ) );
	
	}
	
	public function buscaatividadeadministradorAction() {
      $this->deprecated("administrador", "buscaatividadeadministrador");
		$this->view->headLink ()->appendStylesheet ( $this->view->baseUrl ( 'css/tabela_sort.css' ) );
		$this->view->headScript ()->appendFile ( $this->view->baseUrl ( 'js/jquery-1.6.2.min.js' ) );
		$this->view->headScript ()->appendFile ( $this->view->baseUrl ( 'js/jquery.dataTables.js' ) );
		// $this->view->headScript()->appendFile($this->view->baseUrl('/js/caravana/inicio.js'));
		$this->view->headScript ()->appendFile ( $this->view->baseUrl ( '/js/evento/busca_evento_admin.js' ) );
		
		$tipoEventos = new Application_Model_TipoEvento();
		$this->view->tipoEvento = $tipoEventos->fetchAll();
	}
	
	public function relatoriosadministradorAction() {
	
	}
	
	public function verdetalheseventoAction() {
      $this->deprecated("administrador", "verdetalhesevento");
		$this->view->headLink ()->appendStylesheet ( $this->view->baseUrl ( 'css/tabela_sort.css' ) );
		$this->view->headScript ()->appendFile ( $this->view->baseUrl ( 'js/jquery-1.6.2.min.js' ) );
		$this->view->headScript ()->appendFile ( $this->view->baseUrl ( '/js/administrador/teste.js' ) );
		$this->view->headScript ()->appendFile ( $this->view->baseUrl ( 'js/jquery.dataTables.js' ) );
		$this->view->headLink ()->appendStylesheet ( $this->view->baseUrl ( 'css/form.css' ) );
	   $this->view->headScript()->appendFile($this->view->baseUrl('/js/administrador/altera_palestrante.js'));
		

		$data = $this->getRequest()->getPost ();
		
		$idEvento = intval ( $this->_request->getParam ( 'id_evento' ) );
		
		$evento = new Application_Model_Evento ();
		$data = $evento->buscaEventoPessoa ( $idEvento );
		
		$form = new Application_Form_EventoDetalhes ();
		$this->view->form = $form;
		
		if ($data [0] ['validada']) {
			$data [0] ['validada'] = "TRUE";
		
		} else {
			$data [0] ['validada'] = "FALSE";
		}
		
		$form->populate ( $data [0] );
		$this->view->idEvento = $idEvento;
		$this->view->nomeEvento = $data [0] ['nome_evento'];
		
		$select = "SELECT evento, descricao, TO_CHAR(data, 'DD/MM/YYYY') AS data, TO_CHAR(hora_inicio, 'HH24:MI') as inicio, TO_CHAR(hora_fim, 'HH24:MI') as fim, nome_sala FROM evento_realizacao er INNER JOIN sala s ON (er.id_sala = s.id_sala) WHERE id_evento = ?";
		$data = $evento->getAdapter ()->fetchAll ( $select, $idEvento );
		
		$this->view->horarios = $data;
		
		/*
		$data = $this->getRequest()->getPost();

		if ($this->getRequest()->isPost() && $form->isValid($data)) {
			$data = $form->getValues();
			
			$evento =  new Application_Model_Evento();
			
		}*/
	}
	
	public function validaeventoAction() {
		$idEvento = intval ( $this->_request->getParam ( 'id_evento' ) );
		
		$evento = new Application_Model_Evento ();
		$data = $evento->validaEvento ( $idEvento );
		
		return $this->_helper->redirector->goToRoute ( array ('controller' => 'administrador', 'action' => 'buscaatividadeadministrador' ), null, true );
	}
	
	public function invalidaeventoAction() {
		$idEvento = intval ( $this->_request->getParam ( 'id_evento' ) );
		
		$evento = new Application_Model_Evento ();
		$data = $evento->invalidaEvento ( $idEvento );
		
		return $this->_helper->redirector->goToRoute ( array ('controller' => 'administrador', 'action' => 'buscaatividadeadministrador' ), null, true );
	}
	
	public function excluihorarioAction() {
		$idHorario = intval ( $this->_request->getParam ( 'id_horario' ) );
		$idEvento = intval ( $this->_request->getParam ( 'id_evento' ) );
		
		$this->view->idEvento = $idEvento;
		$horario = new Application_Model_EventoRealizacao ();
		
		try {
			
			$select = "DELETE FROM evento_realizacao_multipla WHERE evento = ?";
			$data = $horario->getAdapter ()->fetchAll ( $select, $idHorario );
			
			$select = "DELETE FROM evento_realizacao WHERE evento = ?";
			$data = $horario->getAdapter ()->fetchAll ( $select, $idHorario );
			
			
			
			return $this->_helper->redirector->goToRoute ( array ('controller' => 'administrador', 'action' => 'verdetalhesevento', 'id_evento' => $idEvento ), null, true );
		
		} catch ( Zend_Db_Exception $ex ) {
			
			 if ($ex->getCode() == 23503){
			 	echo "<br>Esse hórario não pode ser removido, já há participantes inscritos nesse hórario";
			 }
		
		}
	
	}
	
	public function validacaravanaAction(){
		$sessao = Zend_Auth::getInstance ()->getIdentity ();
		$idEncontro = $sessao ["idEncontro"];
		$idCaravana = intval ( $this->_request->getParam ( 'id_caravana' ) );
		
		$caracavana = new Application_Model_Caravana();
		echo $idCaravana;
		$select = "UPDATE caravana_encontro set validada = TRUE where id_caravana = ? AND id_encontro = ?";
      	
      	$caracavana->getAdapter()->fetchAll($select,array($idCaravana,$idEncontro));
		
		return $this->_helper->redirector->goToRoute ( array ('controller' => 'administrador', 'action' => 'buscacaravanaadministrador' ), null, true );
		
	}
	
	public function invalidacaravanaAction(){
		$sessao = Zend_Auth::getInstance ()->getIdentity ();
		$idEncontro = $sessao ["idEncontro"];
		$idCaravana = intval ( $this->_request->getParam ( 'id_caravana' ) );
		
		$caracavana = new Application_Model_Caravana();
		echo $idEncontro;
		
		$select = "UPDATE caravana_encontro set validada = FALSE where id_caravana = ? AND id_encontro = ?";
      	
      	$caracavana->getAdapter()->fetchAll($select,array($idCaravana,$idEncontro));
		
		return $this->_helper->redirector->goToRoute ( array ('controller' => 'administrador', 'action' => 'buscacaravanaadministrador' ), null, true );
		
	}

	
	public function adicionarhorarioAction() {
		$this->view->headLink ()->appendStylesheet ( $this->view->baseUrl ( 'css/tabela_sort.css' ) );
		$this->view->headScript ()->appendFile ( $this->view->baseUrl ( 'js/jquery-1.6.2.min.js' ) );
		$this->view->headScript ()->appendFile ( $this->view->baseUrl ( 'js/jquery.dataTables.js' ) );
		$this->view->headLink ()->appendStylesheet ( $this->view->baseUrl ( 'css/form.css' ) );
		
		$idEvento = $this->_request->getParam ( 'id_evento' );
		$nomeEvento = $this->_request->getParam ( 'nome_evento' );
		
		$form = new Application_Form_Horarios ();
		$form->setDescricao ( $nomeEvento );
		$form->cria ();
		$this->view->form = $form;
		
		
		$evento = new Application_Model_EventoRealizacao();
		$select = "SELECT TO_CHAR(data, 'DD/MM/YYYY') as data, TO_CHAR(hora_inicio, 'HH24:MI') as hora_inicio, TO_CHAR(hora_fim, 'HH24:MI') as hora_fim FROM evento_realizacao WHERE id_evento = ?";
		
		$this->view->idEvento = $idEvento;
		$this->view->horariosEventos = $evento->getAdapter()->fetchAll($select,$idEvento);
		
		
		$data = $this->getRequest()->getPost();
		if ($this->getRequest()->isPost() && $form->isValid( $data )) {
			$data = $form->getValues();
			unset($data['horarios']);
			$data['id_evento'] = $idEvento;
			$id = $evento->insert( $data );

			if ($id > 0) {
				return $this->_helper->redirector->goToRoute ( array ('controller' => 'administrador', 'action' => 'verdetalhesevento', 'id_evento' => $idEvento ), 'default', true );
			}
			
			/*$dataHorario = array ();
			
			foreach ( $data as $chave => $item ) {
				if ($chave != "descricao" && $chave != "salas" && $chave != "data" && $item != "0") {
					$dataHorario [] = $item;
				}
			}
			
			$confirmaHorario = true;
			
			foreach ( $dataHorario as $h ) {
				$ok = true;
				$horarios = split ( "_", $h );
				
				$horariosConfirmado = $evento->fetchAll ();
				
				foreach ( $horariosConfirmado as $item ) {
					
					if ($item->id_sala == $data ["salas"] && $item->data == $data ["data"] && $item->hora_inicio == $horarios [0]) {
						$confirmaHorario = false;
						$ok = false;
						$sala = $item->findDependentRowset('Application_Model_Sala')->current()->nome_sala;
		                $e = $item->findDependentRowset('Application_Model_Evento')->current()->nome_evento;
						
						echo "O evento $nomeEvento no hórario de $horarios[0] às $horarios[1] no dia $item->data<br>, não pode ser escolhido, já haverá o evento $e nesse hórario<br><br>";
						
						break;
					}
				
				}
				
				if ($ok) {
					$dadosEvento = array ('id_evento' => $idEvento, 'id_sala' => $data ["salas"], 'data' => $data ["data"], 'hora_inicio' => $horarios [0], 'hora_fim' => $horarios [1], 'descricao' => $nomeEvento );
					
					$id = $evento->insert ( $dadosEvento );
					
					$select = "INSERT INTO evento_realizacao_multipla (evento, data, hora_inicio, hora_fim) VALUES (?,?,?,?)"; 
					
					$evento->getAdapter ()->fetchAll ($select, array($id,$data["data"],$horarios [0],$horarios [1]));
					
					
			      echo "O evento $nomeEvento foi adicinado no hórario de $horarios[0] às $horarios[1] no dia $item->data<br>";
				} 
			
			}
			
			if ($confirmaHorario) {
				return $this->_helper->redirector->goToRoute ( array ('controller' => 'administrador', 'action' => 'verdetalhesevento', 'id_evento' => $idEvento ), null, true );
			}*/
		
		}
	
	}
	
	public function trocapalestranteAction(){
		//$this->getHelper('layout')->disableLayout();
		
		$sessao = Zend_Auth::getInstance ()->getIdentity ();
		$idEncontro = $sessao ["idEncontro"];

		$this->view->headLink ()->appendStylesheet ( $this->view->baseUrl ( 'css/tabela_sort.css' ) );
		$this->view->headScript ()->appendFile ( $this->view->baseUrl ( 'js/jquery-1.6.2.min.js' ) );
		$this->view->headScript ()->appendFile ( $this->view->baseUrl ( 'js/jquery.dataTables.js' ) );
		//$this->view->headScript()->appendFile($this->view->baseUrl('/js/administrador/inicio.js'));
		$this->view->headScript ()->appendFile ( $this->view->baseUrl ( 'js/administrador/troca_palestrante.js' ) );
		
		$this->view->idEncontro = $idEncontro;
		
	}
	
	
	public function alterapalestranteAction(){
		$this->_helper->layout()->disableLayout();
		
		
		
		$pessoas = new Application_Model_Pessoa ();
		$dataTodosUsuarios = array (intval ( $this->_request->getParam ( "idEncontro" ) ), $this->_request->getParam ( "nomePessoa" ) );
		$data = $pessoas->buscaPessoas( $dataTodosUsuarios );
		
	
		$edom= '{"size":'.count($data).',"aaData":[';
		if (isset ( $data )){
			$conte=0;
			
			foreach ( $data as $value ) {
				if($conte!=0){$edom.=',';}

				$acao = '<a href=' . $this->view->baseUrl('/administrador/verdetalhesevento/id_pessoa/'.$value["id_pessoa"]) . '>Alterar</a>';
				
				$edom.= '["'.$value ['nome'].'","'. $value ['apelido'].'","'.$value ['email'].'","'.$value ['twitter'].'","'.$value ['nome_municipio'].'","'.$value ['apelido_instituicao'].'","'.$value ['nome_caravana'].'","' . $acao .'"]';
				 $conte=1;
					

			}
		}
		$edom.= ']}';
		
		echo  $edom;
		
	}
	
	public function validapessoaAction(){
		$idpessoa = $this->_request->getParam ( 'id_pessoa' );
		
		
		$sessao = Zend_Auth::getInstance ()->getIdentity ();
		$idEncontro = $sessao ["idEncontro"];
		$pessoa = new Application_Model_Pessoa();
		
		$select = "UPDATE encontro_participante SET confirmado = TRUE, data_confirmacao = now() where id_pessoa = ? AND id_encontro = ?";
		
		$pessoa->getAdapter()->fetchAll($select,array($idpessoa, $idEncontro));
		
		return $this->_helper->redirector->goToRoute ( array ('controller' => 'administrador', 'action' => 'index' ), null, true );
	}
	
	public function invalidapessoaAction(){
		$idpessoa = $this->_request->getParam ( 'id_pessoa' );
		
		
		$sessao = Zend_Auth::getInstance ()->getIdentity ();
		$idEncontro = $sessao ["idEncontro"];
		$pessoa = new Application_Model_Pessoa();
		
		$select = "UPDATE encontro_participante SET confirmado = FALSE, data_confirmacao = NULL where id_pessoa = ? AND id_encontro = ?";
		
		$pessoa->getAdapter()->fetchAll($select,array($idpessoa, $idEncontro));
		
		return $this->_helper->redirector->goToRoute ( array ('controller' => 'administrador', 'action' => 'index' ), null, true );
	}

   private function deprecated($controller, $view) {
		$this->view->deprecated = "You are using a deprecated controller/view: {$controller}/{$view}";
	}
}