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
   }

}

