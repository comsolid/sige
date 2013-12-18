<?php

class CaravanaController extends Zend_Controller_Action {

   public function init() {
      if (!Zend_Auth :: getInstance()->hasIdentity()) {
         $session = new Zend_Session_Namespace();
         $session->setExpirationSeconds(60 * 60 * 1); // 1 minuto
         $session->url = $_SERVER['REQUEST_URI'];
         return $this->_helper->redirector->goToRoute(array(), 'login', true);
      }
      
      $sessao = Zend_Auth::getInstance()->getIdentity();
      $this->view->menu = new Application_Form_Menu($this->view, 'caravana', $sessao['administrador']);
   }

   public function indexAction() {

      $sessao = Zend_Auth::getInstance()->getIdentity();

      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/tabela_sort.css'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery.dataTables.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/caravana/index.js'));

      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/caravana/index.css'));
      $model = new Application_Model_CaravanaEncontro();
      
      $this->view->participante = $model->lerParticipanteCaravana($sessao["idEncontro"], $sessao["idPessoa"]);
      $this->view->caravanaResponsavel = $model->lerResponsavelCaravana($sessao["idEncontro"], $sessao["idPessoa"]);
   }

   public function participantesAction() {
      $cancelar = $this->getRequest()->getPost('cancelar');
      if (isset($cancelar)) {
         return $this->_helper->redirector->goToRoute(array(
                     'controller' => 'caravana',
                     'action' => 'index'), null, true);
      }
      
      $sessao = Zend_Auth::getInstance()->getIdentity();
      $idPessoa = $sessao["idPessoa"];
      $idEncontro = $sessao["idEncontro"];
      
      $participante = new Application_Model_Participante();
      // TODO: usar CaravanaEncontro#lerResponsavelCaravana
      $rs = $participante->getMinhasCaravanaResponsavel(array($idEncontro, $idPessoa));
      $this->view->caravana = $rs[0];
      
      $caravanaEncontro = new Application_Model_CaravanaEncontro();
      
      if ($this->getRequest()->isPost()) {
         $submit = $this->getRequest()->getPost('submit');
         if ($submit == "confimar") {
            $array_id_pessoas = explode(",", $this->getRequest()->getPost('array_id_pessoas'));
            // se existirem e-mail a serem adicionados a caravana
            // explode retorna array(0 => "") http://php.net/manual/pt_BR/function.explode.php
            if (count($array_id_pessoas) == 1 && empty($array_id_pessoas[0])) {
               $this->_helper->flashMessenger->addMessage(
                        array('notice' => 'Nenhum participante foi selecionado.'));
            } else {
               $where = array(
                   $this->view->caravana['id_caravana'],
                   $sessao["idEncontro"],
                   $sessao["idEncontro"], // id_encontro usado em subquery
               );
               $where = array_merge($where, $array_id_pessoas);
               try {
                  $result = $caravanaEncontro->updateParticipantesCaravana($where);
                  if ($result) {
                     $this->_helper->flashMessenger->addMessage(
                             array('success' => 'Participantes adicionados à caravana com sucesso.'));
                  } else {
                     $this->_helper->flashMessenger->addMessage(
                             array('notice' => 'Nenhum participante adicionado à caravana.'));
                  }
                  
               } catch (Exception $e) {
                  $this->_helper->flashMessenger->addMessage(
                          array('error' => 'Ocorreu um erro inesperado.<br/>Detalhes: '
                              . $e->getMessage()));
               }
            }
         }
      }
      
      $this->view->participantes = $caravanaEncontro->buscaParticipantes($this->view->caravana['id_caravana'], $sessao["idEncontro"]);
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
         AND ep.id_caravana IS NULL
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
   
   public function deletarParticipanteAction() {
      $this->_helper->layout()->disableLayout();
      $this->_helper->viewRenderer->setNoRender(true);
      
      $pessoa = $this->_getParam('pessoa', 0);
      if ($pessoa > 0) {
         $sessao = Zend_Auth::getInstance()->getIdentity();
         $where = array(
             $sessao["idEncontro"],
             $pessoa
         );
         $model = new Application_Model_CaravanaEncontro();
         try {
            $model->deletarParticipante($where);
            $this->_helper->flashMessenger->addMessage(
                             array('success' => 'Participante removido da caravana com sucesso.'));
         } catch (Exception $e) {
               $this->_helper->flashMessenger->addMessage(
                       array('error' => 'Ocorreu um erro inesperado.<br/>Detalhes: '
                           . $e->getMessage()));
         }
      } else {
         $this->_helper->flashMessenger->addMessage(
                        array('notice' => 'Nenhum participante foi selecionado.'));
      }
      $this->_helper->redirector->goToRoute(array('controller' => 'caravana',
          'action' => 'participantes'), 'default', true);
   }
   
   public function sairAction() {
      $this->_helper->layout()->disableLayout();
      $this->_helper->viewRenderer->setNoRender(true);
      
      $sessao = Zend_Auth::getInstance()->getIdentity();
      $model = new Application_Model_Participante();
      try {
         $model->sairDaCaravana(array($sessao["idEncontro"], $sessao["idPessoa"]));
         $this->_helper->flashMessenger->addMessage(
                 array('success' => 'Participante removido da caravana com sucesso.'));
      } catch (Exception $e) {
         $this->_helper->flashMessenger->addMessage(
                 array('error' => 'Ocorreu um erro inesperado.<br/>Detalhes: '
                     . $e->getMessage()));
      }
      $this->_helper->redirector->goToRoute(array('controller' => 'caravana',
              'action' => 'index'), null, true);
   }

   public function criarAction() {
		$this->view->headScript()->appendFile($this->view->baseUrl('js/select2.js'));
		$this->view->headScript()->appendFile($this->view->baseUrl('js/caravana/salvar.js'));
		$this->view->headLink()->appendStylesheet($this->view->baseUrl('css/select2.css'));
		$this->view->headLink()->appendStylesheet($this->view->baseUrl('css/form.css'));
		
      $data = $this->getRequest()->getPost();
      if (isset($data['cancelar'])) {
         return $this->_helper->redirector->goToRoute(array(
                     'controller' => 'caravana',
                     'action' => 'index'
                         ), null, true);
      }
      $sessao = Zend_Auth::getInstance()->getIdentity();
      $idPessoa = $sessao["idPessoa"];
      $idEncontro = $sessao["idEncontro"];
      
      $caravana = new Application_Model_Caravana();

      if ($caravana->verificaCaravana($idPessoa, $idEncontro)) { // previne que o mesmo usuário crie 2 caravanas
         return $this->_helper->redirector->goToRoute(array(
                     'controller' => 'caravana',
                     'action' => 'editar'), null, true);
      } else {

         $form = new Application_Form_Caravana();
         $form->setAction($this->view->url(array('controller' => 'caravana', 'action' => 'criar')));

         $this->view->form = $form;
         $data = $this->getRequest()->getPost();

         if ($this->getRequest()->isPost() && $form->isValid($data)) {
            $caravana = new Application_Model_Caravana();
            $caravana_encontro = new Application_Model_CaravanaEncontro();
            $data = $form->getValues();
            
            $adapter = $caravana->getAdapter();
            try {
               $adapter->beginTransaction();
               $m_encontro = new Application_Model_Encontro();
               $data['criador'] = $idPessoa;

               $data2['id_encontro'] = $m_encontro->getEncontroAtual();
               $data2['responsavel'] = $idPessoa;
               $data2['id_caravana'] = $caravana->insert($data);

               $caravana_encontro->insert($data2);
               $adapter->commit();
               return $this->_helper->redirector->goToRoute(array(
                           'controller' => 'caravana',
                           'action' => 'index'), null, true);
            } catch (Zend_Db_Exception $ex) {
               $adapter->rollBack();
               // 23505 UNIQUE VIOLATION
               if ($ex->getCode() == 23505) {
                  $this->_helper->flashMessenger->addMessage(
                          array('error' => 'Já existe uma caravana com esta descrição.'));
               } else {
                  $this->_helper->flashMessenger->addMessage(
                          array('error' => 'Ocorreu um erro inesperado.<br/>Detalhes: '
                              . $ex->getMessage()));
               }
            }
         }
      }
   }

   public function editarAction() {
		$this->view->headScript()->appendFile($this->view->baseUrl('js/select2.js'));
		$this->view->headScript()->appendFile($this->view->baseUrl('js/caravana/salvar.js'));
		$this->view->headLink()->appendStylesheet($this->view->baseUrl('css/select2.css'));
		$this->view->headLink()->appendStylesheet($this->view->baseUrl('css/form.css'));

      $data = $this->getRequest()->getPost();
      if (isset($data['cancelar'])) {
         return $this->_helper->redirector->goToRoute(array(
                     'controller' => 'caravana',
                     'action' => 'index'), null, true);
      }

      $sessao = Zend_Auth::getInstance()->getIdentity();
      $idPessoa = $sessao["idPessoa"];
      $idEncontro = $sessao["idEncontro"];

      $form = new Application_Form_Caravana();
      $form->setAction($this->view->url(array('controller' => 'caravana', 'action' => 'editar')));
      $this->view->form = $form;

      $caravana = new Application_Model_Caravana();
      //$participante = new Application_Model_Participante();
      $caravana_encontro = new Application_Model_CaravanaEncontro();
      //$pessoa = new Application_Model_Pessoa();

      //$pessoa = $pessoa->find($idPessoa); //mandar ainda  o nome do criador para a view	
      $select = $caravana_encontro->select();
      $rows = $caravana_encontro->fetchAll($select->where('responsavel = ?', $idPessoa)->where('id_encontro = ?', $idEncontro));
      $row = $rows[0];

      $select = $caravana->select();
      $dados_caravana = $caravana->find($row['id_caravana']);

      $dados_caravana = $dados_caravana[0];

      /*$idCaravana = $rows['id_caravana'];

      $participantes = $caravana_encontro->buscaParticipantes($idCaravana, $idEncontro);

      $this->view->participantes = array();
      $this->view->participantes[] = $participantes;*/

      $form->populate($dados_caravana->toArray());
      $data = $this->getRequest()->getPost();

      if ($this->getRequest()->isPost() && $form->isValid($data)) {

         $data = $form->getValues();
         $where = $caravana->getAdapter()->quoteInto('id_caravana = ?', $dados_caravana['id_caravana']);

         try {
            $caravana->update($data, $where);

            return $this->_helper->redirector->goToRoute(array(
                        'controller' => 'caravana',
                        'action' => 'index'), null, true);
         } catch (Zend_Db_Exception $ex) {
            // 23505 UNIQUE VIOLATION
            if ($ex->getCode() == 23505) {
               $this->_helper->flashMessenger->addMessage(
                       array('error' => 'Já existe uma caravana com esta descrição.'));
            } else {
               $this->_helper->flashMessenger->addMessage(
                       array('error' => 'Ocorreu um erro inesperado.<br/>Detalhes: '
                           . $ex->getMessage()));
            }
         }
      }
   }
}
