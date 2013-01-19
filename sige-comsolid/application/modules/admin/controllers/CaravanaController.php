<?php

class Admin_CaravanaController extends Zend_Controller_Action {

   public function init() {
      if (!Zend_Auth::getInstance()->hasIdentity()) {
         return $this->_helper->redirector->goToRoute(array(), 'login', true);
      }

      $sessao = Zend_Auth::getInstance()->getIdentity();
      if (!$sessao["administrador"]) {
         return $this->_helper->redirector->goToRoute(array('controller' => 'participante',
                     'action' => 'index'), 'default', true);
      }
   }

   public function indexAction() {
      $this->view->headLink ()->appendStylesheet ( $this->view->baseUrl ( 'css/tabela_sort.css' ) );
		$this->view->headScript ()->appendFile ( $this->view->baseUrl ( 'js/jquery-1.6.2.min.js' ) );
		$this->view->headScript ()->appendFile ( $this->view->baseUrl ( 'js/jquery.dataTables.js' ) );
		// $this->view->headScript()->appendFile($this->view->baseUrl('/js/caravana/inicio.js'));
		$this->view->headScript ()->appendFile ( $this->view->baseUrl ( '/js/admin/caravana/index.js' ) );
   }

   public function ajaxBuscarAction() {
      $this->_helper->layout()->disableLayout();
      $this->_helper->viewRenderer->setNoRender(true);
      
      $sessao = Zend_Auth :: getInstance()->getIdentity();
      $idEncontro = $sessao["idEncontro"];
      
      $termo = $this->_request->getParam("termo", "");
      $model = new Application_Model_Caravana();
      $where = array(
          $idEncontro,
          $termo
      );
      $rs = $model->busca($where);
      $json = new stdClass;
      $json->size = count($rs);
      $json->itens = array();
      
      foreach($rs as $value) {
          if ($value['validada']) {
             $validada = "Sim";
          } else {
             $validada = "Não";
          }
          $json->itens[] = array(
              "{$value['nome_caravana']}",
              "{$value['apelido_caravana']}",
              "{$value['nome']}",
              "{$value['nome_municipio']}",
              "{$value['apelido_instituicao']}",
              "{$validada}",
              "{$value['count']}",
              '<a href=' . $this->view->baseUrl('/administrador/validacaravana/id_caravana/' . $value["id_caravana"]) . '>Validar</a>',
              '<a href=' . $this->view->baseUrl('/administrador/invalidacaravana/id_caravana/' . $value["id_caravana"]) . '>invalidar</a>'
          );
      }
      header("Pragma: no-cache");
      header("Cache: no-cahce");
      header("Cache-Control: no-cache, must-revalidate");
      header("Content-type: text/json");
      echo json_encode($json);
   }
}

