<?php

class Mobile_ParticipanteController extends Zend_Controller_Action {

   public function init() {
      $this->_helper->layout->setLayout('mobile');
      if (!Zend_Auth::getInstance()->hasIdentity()) {
         $session = new Zend_Session_Namespace();
         $session->setExpirationSeconds(60 * 60 * 1); // 1 minuto
         $session->url = $_SERVER['REQUEST_URI'];
         // TODO: criar login mobile
         return $this->_helper->redirector->goToRoute(array(), 'login', true);
      }
   }

   public function indexAction() {
      $sessao = Zend_Auth::getInstance()->getIdentity();
		$idPessoa = $sessao["idPessoa"];
		$idEncontro = $sessao["idEncontro"];

      $eventoDemanda = new Application_Model_EventoDemanda();
      $eventoParticipante = $eventoDemanda->listar(array($idEncontro, $idPessoa));
      $this->view->listaParticipanteEventoTabela =$eventoParticipante;
   }

}

