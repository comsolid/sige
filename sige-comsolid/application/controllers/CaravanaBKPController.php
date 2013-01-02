<?php
class CaravanaController extends Zend_Controller_Action {
	
	
	 public function init()
    {
       $this->view->menu=new Application_Form_Menu($this->view,'caravana');
		if (!Zend_Auth :: getInstance()->hasIdentity()) {
			return $this->_helper->redirector->goToRoute(array (
				'controller' => 'login',
				'action' => 'login'
			), null, true);
		}
    }

    public function indexAction()
    {	
    	
    	$data = $this->getRequest()->getPost();
    	$sessao = Zend_Auth :: getInstance()->getIdentity();
    	
    	 $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/tabela_sort.css'));
	   $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-1.6.2.min.js'));
	   $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery.dataTables.js'));
	   $this->view->headScript()->appendFile($this->view->baseUrl('js/caravana/index.js'));
    	 
    	 $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/form.css'));
		$participante = new Application_Model_Participante();
		if($this->_request->getParam("sair")=='caravana'){
			echo $sessao["idEncontro"]."rererere".$sessao["idPessoa"];
    		$participante->sairDaCaravana(array($sessao["idEncontro"],$sessao["idPessoa"]));
    	}
    	if($this->_request->getParam("caravana_resp")=='exclu' && intval($this->_request->getParam("idcaravana"))>0){
    		$participante->excluirMinhaCaravanaResponsavel(array($sessao["idEncontro"],$this->_request->getParam("idcaravana")));
    	}
   		$participante1=$participante->getMinhaCaravana(array($sessao["idEncontro"],$sessao["idPessoa"]));
   		$participante1=$participante1[0];
    	$this->view->participante=$participante1;
    	$this->view->caravanaResponsavel=$participante->getMinhasCaravanaResponsavel(array($sessao["idEncontro"],$sessao["idPessoa"]));
    	
      	   
    }
    
    
    
    
   
    
    public function addAction() {
        
        $data = $this->getRequest()->getPost();
		if (isset($data['cancelar'])) {
			return $this->_helper->redirector->goToRoute(array (
					'controller' => 'participante',
					'action' => 'index'
				), null, true);
		}
        
        $sessao = Zend_Auth :: getInstance()->getIdentity();

		$idPessoa = $sessao["idPessoa"];
		
		$idEncontro = $sessao["idEncontro"];
		
		if($this->verificaCaravana($idPessoa,$idEncontro)){
			
			$this->editAction();
		
		}else{
		
		
		$form = new Application_Form_Caravana();
		$form->setAction($this->view->url(array('controller'=>'caravana','action'=>'add')));
		
		$this->view->form = $form;
		$data = $this->getRequest()->getPost();
			
        $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/form.css'));
        
        if ($this->getRequest()->isPost() && $form->isValid($data) )
	           {
	    	       $caravana = new Application_Model_Caravana();
	    	       $caravana_encontro = new Application_Model_CaravanaEncontro();
	    	       $data = $form->getValues();
	    	
	   	
	   	
			       try
		              {
		                 	$m_encontro = new Application_Model_Encontro();
		    	            $data['criador']=$idPessoa;
		    	
		    	            $data2['id_encontro']=$m_encontro->getEncontroAtual();
		    	            $data2['responsavel']=$idPessoa;
		    	            $data2['id_caravana']= $caravana->insert($data); 
		    	 
		   
		    	
		    	           	$caravana_encontro->insert($data2);
		    	           
		    	           	return $this->_helper->redirector->goToRoute(array (
							'controller' => 'caravana',
							'action' => 'index'
							), null, true);
		  
		             }
		                catch (Zend_Db_Exception $ex)
		              {
		          
		       
		       
		           // 23505UNIQUE VIOLATION
		                 echo  $ex->getMessage().$ex->getCode() ;
		             //throw $ex;
		              }


	             }   
 
		}
 }	
 
 
 public function editAction() {
 	
 		$data = $this->getRequest()->getPost();
		if (isset($data['cancelar'])) {
			return $this->_helper->redirector->goToRoute(array (
					'controller' => 'participante',
					'action' => 'index'
				), null, true);
		}
 	
	    $sessao = Zend_Auth :: getInstance()->getIdentity();
		$idPessoa = $sessao["idPessoa"];
		$idEncontro = $sessao["idEncontro"];
	  
		
		$form = new Application_Form_CaravanaEditar();
		$form->setAction($this->view->url(array('controller'=>'caravana','action'=>'edit')));
		$this->view->form = $form;
		$this->view->headLink()->appendStylesheet($this->view->baseUrl('css/form.css'));
		
		$caravana = new Application_Model_Caravana();
		$participante = new Application_Model_Participante();
		$caravana_encontro = new Application_Model_CaravanaEncontro();
		$pessoa = new Application_Model_Pessoa();
		
		$pessoa = $pessoa->find($idPessoa);	//mandar ainda  o nome do criador para a view	
		$select = $caravana_encontro->select();
		$rows = $caravana_encontro->fetchAll($select->where('responsavel = ?', $idPessoa)->where('id_encontro = ?', $idEncontro));
		$rows = $rows[0];

		$select = $caravana->select();
		$dados_caravana = $caravana->find($rows['id_caravana']);
		
		$dados_caravana = $dados_caravana[0];
		
		$idCaravana = $rows['id_caravana'];
		
		$participantes = $caravana_encontro->buscaParticipantes($idCaravana,$idEncontro);
		
		$this->view->participantes = array();
		$this->view->participantes[]=$participantes;
		
        $form->populate($dados_caravana->toArray());
		
		
		$data = $this->getRequest()->getPost();

		if ($this->getRequest()->isPost() && $form->isValid($data)) {

			$data = $form->getValues();

			$select=$caravana->getAdapter()->quoteInto('id_caravana = ?',$dados_caravana['id_caravana']);

			try {
				
				$caravana->update($data,$select);
				
				return $this->_helper->redirector->goToRoute(array (
				'controller' => 'participante',
				'action' => 'index'
				), null, true);
				
			} catch (Zend_Db_Exception $ex) {
				// 23505UNIQUE VIOLATION
				echo $ex->getMessage() . $ex->getCode();
				//throw $ex;
			}

		}
	}
	
	public function buscaAction(){
		$sessao = Zend_Auth :: getInstance()->getIdentity();
		$idEncontro = $sessao["idEncontro"];
		$this->_helper->layout()->disableLayout();
		
		$caravana = new Application_Model_Caravana();

		$data = array (intval($idEncontro), $this->_request->getParam("nome_caravana"));

		//var_dump($data);
		$dataCaravana = $caravana->busca($data);

		//print_r($dataCaravana);
		$e = '<?xml version="1.0"?><busca><tbody id="resultadoCaravana"><![CDATA[';
		if (isset ($dataCaravana))
			foreach ($dataCaravana as $value) {
				$validadaCaravana = "";
				if($value['validada']){
					$validadaCaravana = "TRUE";	
				}else{
					$validadaCaravana = "FALSE";
				}
				
				$e .= '<tr>
								<td>' . $value['nome_caravana'] . '</td>
								<td>' . $value['apelido_caravana'] . '</td>
								<td>' . $value['nome'] . '</td>
								<td>' . $value['nome_municipio'] . '</td>
								<td>' . $value['apelido_instituicao'] . '</td>
								<td>' . $validadaCaravana . '</td>
								<td>' . $value['count'] . '</td>
								<td><a id="'.$value['id_caravana'].'">Valida</td>
								<td><a id="'.$value['id_caravana'].'">Invalidar</td>
							</tr>';
				//	echo $value['nome_tipo_evento'];
			}
			

		$this->getResponse()->setHeader('Content-Type', 'text/xml');
		$e .= ']]></tbody></busca>';

		echo $e;
	}
			
    }
	

?>
