<?php

class Admin_DashboardController extends Zend_Controller_Action {

    public function init() {
        if (!Zend_Auth::getInstance()->hasIdentity()) {
            $session = new Zend_Session_Namespace();
            $session->setExpirationSeconds(60 * 60 * 1); // 1 minuto
            $session->url = $_SERVER['REQUEST_URI'];
            return $this->_helper->redirector->goToRoute(array(), 'login', true);
        }

        $sessao = Zend_Auth::getInstance()->getIdentity();
        if (!$sessao["administrador"]) {
            return $this->_helper->redirector->goToRoute(array('controller' => 'participante', 'action' => 'index'), 'default', true);
        }

        $this->_helper->layout->setLayout('twbs3-admin/layout');
        $this->view->menu = new Sige_Desktop_AdminSidebarLeftMenu($this->view, 'dashboard');

        $this->_helper->getHelper('AjaxContext')
            ->addActionContext('ajax-user-registration', 'json')
            ->addActionContext('ajax-total-events', 'json')
            ->initContext();
    }

    public function indexAction() {
        $this->view->title = _('Dashboard');

        $model = new Admin_Model_EncontroParticipante();
        $cache = Zend_Registry::get('cache_common');
        $ps = $cache->load('prefsis');
        $idEncontro = (int) $ps->encontro["id_encontro"];
        $this->view->latest_members = $model->listarUltimosMembros($idEncontro);
    }

    public function ajaxUserRegistrationAction() {
        if ($this->getRequest()->isPost()) {
            $model = new Admin_Model_EncontroParticipante();
            $this->view->num_participants = $model->getTotalUserRegistration();
            $this->view->ok = true;
        } else {
            $this->view->error = _('Request could not be completed.');
        }
    }

    public function ajaxTotalEventsAction() {
        if ($this->getRequest()->isPost()) {
            $model = new Admin_Model_Evento();
            $this->view->num_events = $model->getTotalEvents();
            $this->view->ok = true;
        } else {
            $this->view->error = _('Request could not be completed.');
        }
    }
}
