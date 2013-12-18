<?php

class Admin_ParticipanteController extends Zend_Controller_Action {

   public function init() {
      if (!Zend_Auth::getInstance()->hasIdentity()) {
         $session = new Zend_Session_Namespace();
         $session->setExpirationSeconds(60 * 60 * 1); // 1 minuto
         $session->url = $_SERVER['REQUEST_URI'];
         $this->_helper->redirector->goToRoute(array(), 'login', true);
         return;
      }
      $sessao = Zend_Auth::getInstance()->getIdentity();
      if (!$sessao ["administrador"]) {
         $this->_helper->redirector->goToRoute(array(
             'controller' => 'participante',
             'action' => 'index'), 'default', true);
      }
      $this->view->menu = new Application_Form_Menu($this->view, 'admin', true);
      
   }

   /**
    * Mapeada como
    *    /inscricoes 
    */
   public function indexAction() {
      $sessao = Zend_Auth::getInstance()->getIdentity();
      $idEncontro = $sessao ["idEncontro"];

      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/tabela_sort.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/screen.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/jqueryui-bootstrap/jquery-ui-1.8.16.custom.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/jqueryui-bootstrap/jquery.ui.1.8.16.ie.css'));

      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-ui-1.8.16.custom.min.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery.dataTables.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/admin/participante/index.js'));
      $this->view->idEncontro = $idEncontro;
   }

   public function ajaxBuscarAction() {
      $this->_helper->layout()->disableLayout();
      $this->_helper->viewRenderer->setNoRender(true);
      $pessoas = new Application_Model_Pessoa ();
      $termo = $this->_request->getParam("termo");
      $dataTodosUsuarios = array($this->_request->getParam("idEncontro", 0), $termo, $this->_request->getParam("tipo"));
      $data = $pessoas->buscaPessoas($dataTodosUsuarios);

      $json = new stdClass; // objeto anonymous http://va.mu/cEGn
      
      $json->size = count($data);
      $json->aaData = array();
      
      foreach ($data as $value) {
         if ($value['confirmado']) {
            $isValidado = "Confimado!";
            $acao = "<a class=\"situacao\" 
               data-url=\"/u/desfazer-confirmar/{$value["id_pessoa"]}\">Desfazer</a>";
         } else {
            $isValidado = "Não confimado!";
            $acao = "<a class=\"situacao\"
               data-url=\"/u/confirmar/{$value["id_pessoa"]}\">Confirmar</a>";
         }
         $json->aaData[] = array(
             "{$value ['nome']}",
             "{$value ['apelido']}",
             "{$value ['email']}",
             "{$value ['nome_municipio']}",
             "{$value ['apelido_instituicao']}",
             "{$value ['nome_caravana']}",
             $isValidado,
             $acao
         );
      }
      
      header("Pragma: no-cache");
      header("Cache: no-cahce");
      header("Cache-Control: no-cache, must-revalidate");
      header("Content-type: text/json");
      echo json_encode($json);
   }
   
   /**
    * Mapeada como:
    *    /u/confirmar/:id
    *    /u/desfazer-confirmar/:id
    * @return type 
    */
   public function presencaAction() {
      $this->_helper->layout()->disableLayout();
      $this->_helper->viewRenderer->setNoRender(true);
      
      $id = $this->_getParam('id', 0);
      $confirmar = $this->_getParam('confirmar', 'f');
      $sessao = Zend_Auth::getInstance()->getIdentity();
      $idEncontro = $sessao ["idEncontro"];
      $model = new Application_Model_Pessoa();
      
      $json = new stdClass;
      try {
         if ($confirmar == 't') {
            $data = 'now()';
            $json->msg = "Participante confirmado.";
         } else {
            $data = 'null';
            $json->msg = "Desfazer confirmação participante com sucesso.";
         }
         $select = "UPDATE encontro_participante SET confirmado = ?, 
         data_confirmacao = {$data} where id_pessoa = ? AND id_encontro = ?";
         $model->getAdapter()->fetchAll($select, array($confirmar, $id, $idEncontro));
         $json->ok = true;
      } catch (Exception $e) {
         $json->ok = false;
         $json->erro = "Ocorreu um erro inesperado ao marcar interesse em <b>evento</b>.<br/>Detalhes"
                 . $e->getMessage();
      }

      header("Pragma: no-cache");
      header("Cache: no-cahce");
      header("Cache-Control: no-cache, must-revalidate");
      header("Content-type: text/json");
      echo json_encode($json);
   }
}

