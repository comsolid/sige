<?php

class Admin_EventoController extends Zend_Controller_Action {

   public function init() {
      /* Initialize action controller here */
   }

   public function indexAction() {
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/tabela_sort.css'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-1.6.2.min.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery.dataTables.js'));
      // $this->view->headScript()->appendFile($this->view->baseUrl('/js/caravana/inicio.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('/js/evento/busca_evento_admin.js'));

      $tipoEventos = new Application_Model_TipoEvento();
      $this->view->tipoEvento = $tipoEventos->fetchAll();
   }

}

