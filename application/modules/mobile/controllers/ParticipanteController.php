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
        $cache = Zend_Registry::get('cache_common');
        $ps = $cache->load('prefsis');
        $idEncontro = (int) $ps->encontro["id_encontro"];
        $idPessoa = $sessao["idPessoa"];
//        $idEncontro = $sessao["idEncontro"]; // UNSAFE

      $eventoDemanda = new Application_Model_EventoDemanda();
      $eventoParticipante = $eventoDemanda->listar(array($idEncontro, $idPessoa));
      $this->view->listaParticipanteEventoTabela = $eventoParticipante;
      
      $menu = new Sige_Mobile_Menu($this->view, "inicio");
      $this->view->menu = $menu;
   }

   public function verAction() {
      $menu = new Sige_Mobile_Menu($this->view, "participante");
      $this->view->menu = $menu;
      
      $model = new Application_Model_Pessoa();
      $id = $this->_getParam('id', "");
      if (!empty($id)) {
         if (is_numeric($id)) {
            $sql = $model->getAdapter()->quoteInto('id_pessoa = ?', $id);
         } else {
            $sql = $model->getAdapter()->quoteInto('twitter = ?', $id);
         }
      } else if (Zend_Auth::getInstance()->hasIdentity()) {
         $sessao = Zend_Auth::getInstance()->getIdentity();
         if (!empty($sessao["twitter"])) {
            $sql = $model->getAdapter()->quoteInto('twitter = ?', $sessao["twitter"]);
            $id = $sessao["twitter"];
         } else {
            $sql = $model->getAdapter()->quoteInto('id_pessoa = ?', $sessao["idPessoa"]);
            $id = $sessao["idPessoa"];
         }
      } else {
         $this->_helper->flashMessenger->addMessage(
                 array('danger' => 'Participante não encontrado.'));
         return;
      }
      $this->view->id = $id;
      $this->view->user = $model->fetchRow($sql);
   }
}

