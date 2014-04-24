<?php

class Admin_EventoController extends Zend_Controller_Action {

   public function init() {
      if (!Zend_Auth::getInstance()->hasIdentity()) {
         $session = new Zend_Session_Namespace();
         $session->setExpirationSeconds(60 * 60 * 1); // 1 minuto
         $session->url = $_SERVER['REQUEST_URI'];
         return $this->_helper->redirector->goToRoute(array(), 'login', true);
      }
      
      $sessao = Zend_Auth::getInstance()->getIdentity();
      if (! $sessao["administrador"]) {
         return $this->_helper->redirector->goToRoute(array('controller' => 'participante',
             'action' => 'index'), 'default', true);
      }
      $this->view->menu = new Application_Form_Menu($this->view, 'admin', true);
   }

   public function indexAction() {
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/tabela_sort.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/screen.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/jqueryui-bootstrap/jquery-ui-1.8.16.custom.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/jqueryui-bootstrap/jquery.ui.1.8.16.ie.css'));
      
      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-ui-1.8.16.custom.min.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery.dataTables.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('/js/admin/evento/index.js'));

      $tipoEventos = new Application_Model_TipoEvento();
      $this->view->tipoEvento = $tipoEventos->fetchAll();
   }

   public function detalhesAction() {
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/tabela_sort.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/screen.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/prettify.css'));
		$this->view->headLink()->appendStylesheet($this->view->baseUrl('css/form.css'));
		$this->view->headLink()->appendStylesheet($this->view->baseUrl('css/jqueryui-bootstrap/jquery-ui-1.8.16.custom.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/jqueryui-bootstrap/jquery.ui.1.8.16.ie.css'));

      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-migrate-1.2.1.min.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-ui-1.8.16.custom.min.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery.dataTables.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/prettify.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/init.prettify.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/admin/evento/detalhes.js'));

      $idEvento = $this->_request->getParam('id', 0);

      $evento = new Admin_Model_Evento();
      $data = $evento->buscaEventoPessoa($idEvento);
      $this->view->evento = $data[0];
      
      if ($data[0]['validada']) {
         $this->view->url_situacao = "<a href=\"/admin/evento/invalidar/{$idEvento}\" 
                 class=\"no-bottom\"><i class=\"icon-remove\"></i> " . _("Invalidate") . "</a>";
      } else {
         $this->view->url_situacao = "<a href=\"/admin/evento/validar/{$idEvento}\" 
                 class=\"no-bottom\"><i class=\"icon-ok\"></i> " . _("Validate") . "</a>";
      }
      
      if ($data[0]['apresentado']) {
         $this->view->url_apresentado = "<a href='{$this->view->url(array('id' => $idEvento),
                 'evento_desfazer_apresentado', true)}' class='no-bottom'>
                  <i class='icon-eye-close'></i> " . _("Undo presented") . "</a>";
      } else {
         $this->view->url_apresentado = "<a href='{$this->view->url(array('id' => $idEvento),
                 'evento_apresentado', true)}' class='no-bottom'>
                  <i class='icon-eye-open'></i> " . _("Presented") . "</a>";
      }

      $this->view->horarios = $evento->listarHorarios($idEvento);
      $this->view->outrosPalestrantes = $evento->listarOutrosPalestrantes($idEvento);
      
   }
   
   /**
    * Mapeada como:
    *    /admin/evento/validar/:id
    *    /admin/evento/invalidar/:id
    */
   public function situacaoAction() {
      $idEvento = $this->_getParam('id', 0);
      $validar = $this->_getParam('validar', 'f');

      $evento = new Application_Model_Evento();
      try {
         $sql = "UPDATE evento SET validada = ? WHERE id_evento = ?";
         $evento->getAdapter()->fetchAll($sql, array($validar, $idEvento));
      } catch (Exception $e) {
         $this->_helper->flashMessenger->addMessage(array('error' =>
             'Ocorreu um erro inesperado.<br/>Detalhes: ' . $e->getMessage()));
      }

      $this->_helper->redirector->goToRoute(array(
          'module' => 'admin',
          'controller' => 'evento',
          'action' => 'detalhes',
          'id' => $idEvento), 'default');
   }
   
   /**
    * Mapeada como
    *    /admin/evento/apresentado/:id
    *    /admin/evento/desfazer-apresentado/:id
    */
   public function situacaoPosEventoAction() {
      $idEvento = $this->_getParam('id', 0);
      $apresentado = $this->_getParam('apresentado', 'f');

      $evento = new Application_Model_Evento();
      try {
         $sql = "UPDATE evento SET apresentado = ? WHERE id_evento = ?";
         $evento->getAdapter()->fetchAll($sql, array($apresentado, $idEvento));
      } catch (Exception $e) {
         $this->_helper->flashMessenger->addMessage(array('error' =>
             'Ocorreu um erro inesperado.<br/>Detalhes: ' . $e->getMessage()));
      }

      $this->_helper->redirector->goToRoute(array(
          'module' => 'admin',
          'controller' => 'evento',
          'action' => 'detalhes',
          'id' => $idEvento), 'default');
   }

   public function ajaxBuscarAction() {
      $this->_helper->layout()->disableLayout();
      $this->_helper->viewRenderer->setNoRender(true);
      $sessao = Zend_Auth::getInstance()->getIdentity();
      $idEncontro = $sessao["idEncontro"];

      $eventos = new Application_Model_Evento();
      $data = array(
          intval($idEncontro), $this->_request->getParam("termo"),
          intval($this->_request->getParam("tipo")),
          intval($this->_request->getParam("situacao"))
      );

      $rs = $eventos->buscaEventosAdmin($data);
      $json = new stdClass;
      $json->size = count($rs);
      $json->itens = array();
      
      foreach($rs as $value) {
         if ($value['validada']) {
            $validada = _("Yes");
         } else {
            $validada = _("No");
         }
         
         $date = new Zend_Date($value['data_submissao']);
         
         $url = '<a href='
            . $this->view->baseUrl('/admin/evento/detalhes/id/' . $value["id_evento"])
            . ' class="no-bottom"><i class="icon-plus"></i> ' . _("Details") . '</a>';
         $json->itens[] = array(
             substr($value['nome_tipo_evento'], 0, 1),
             "{$value['nome_evento']}",
             "{$validada}",
             "{$date->toString("dd/MM/YYYY HH:mm")}",
             "{$value['nome']}",
             $url
         );
      }
      
      header("Pragma: no-cache");
      header("Cache: no-cahce");
      header("Cache-Control: no-cache, must-revalidate");
      header("Content-type: text/json");
      echo json_encode($json);
   }
   
   public function outrosPalestrantesAction() {
      $idPessoa = $this->_getParam('pessoa', 0);
      $idEvento = $this->_getParam('evento', 0);
      $confirmado = $this->_getParam('confirmar', 'f');
      $model = new Admin_Model_Evento();
      try {
         $sql = "UPDATE evento_palestrante SET confirmado = ? WHERE id_evento = ?
            AND id_pessoa = ?";
         $model->getAdapter()->fetchAll($sql, array($confirmado, $idEvento, $idPessoa));
         if ($confirmado == "f") {
            $msg = "Desfazer confirmação palestrante executada com sucesso.";
         } else {
            $msg = "Confirmação palestrante executada com sucesso.";
         }
         $this->_helper->flashMessenger->addMessage(
                     array('success' => $msg));
      } catch (Exception $e) {
         $this->_helper->flashMessenger->addMessage(array('error' =>
             'Ocorreu um erro inesperado.<br/>Detalhes: ' . $e->getMessage()));
      }
      
      $this->_helper->redirector->goToRoute(array(
          'module' => 'admin',
          'controller' => 'evento',
          'action' => 'detalhes',
          'id' => $idEvento), 'default');
   }
   
   public function programacaoParcialAction() {
      $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'staging');
      $id_encontro = $config->encontro->codigo;
      $model = new Admin_Model_Evento();
      $this->view->lista = $model->programacaoParcial($id_encontro);
   }
}

