<?php

class Mobile_EventoController extends Zend_Controller_Action {

   public function init() {
      $this->_helper->layout->setLayout('mobile');
   }

   public function programacaoAction() {
      
      $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'staging');
      $idEncontro = $config->encontro->codigo;
      
      $model = new Application_Model_Evento();
      // usada para mostrar dias que possuem eventos
      $this->view->diasEncontro = $model->listarDiasDoEncontro($idEncontro);
      $this->view->lista = $model->programacao($idEncontro);
      
      $menu = new Sige_Mobile_Menu($this->view, "programacao");
      $this->view->menu = $menu;
   }

   /**
    * Mapeada como
    *    /mobile/e/:id
    */
   public function verAction() {
      $menu = new Sige_Mobile_Menu($this->view, "programacao");
      $this->view->menu = $menu;
      
      try {
         $idEvento = $this->_request->getParam('id', 0);
         $evento = new Application_Model_Evento();
         $data = $evento->buscaEventoPessoa($idEvento);
         if (empty($data)) {
            $this->_helper->flashMessenger->addMessage(
                    array('notice' => 'Evento não encontrado.'));
         } else {
            $this->view->evento = $data[0];
            $this->view->outros = $evento->buscarOutrosPalestrantes($idEvento);

            $modelTags = new Application_Model_EventoTags();
            $this->view->tags = $modelTags->listarPorEvento($idEvento);
         }
      } catch (Exception $e) {
         $this->_helper->flashMessenger->addMessage(
                 array('error' => 'Ocorreu um erro inesperado.<br/>Detalhes: '
                     . $e->getMessage()));
      }
   }
}

