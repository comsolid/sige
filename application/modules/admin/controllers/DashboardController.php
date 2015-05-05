<?php

class Admin_DashboardController extends Sige_Controller_AdminAction {

    public function init() {
        $this->_helper->layout->setLayout('twbs3-admin/layout');
        $this->view->menu = new Sige_Desktop_AdminSidebarLeftMenu($this->view, 'dashboard');

        $this->_helper->getHelper('AjaxContext')
            ->addActionContext('ajax-user-registration', 'json')
            ->addActionContext('ajax-total-events', 'json')
            ->initContext();
    }

    public function indexAction() {
        $this->autenticacao();

        $this->view->title = $this->t->_('Dashboard');

        $model = new Admin_Model_EncontroParticipante();
        $cache = Zend_Registry::get('cache_common');
        $ps = $cache->load('prefsis');
        $idEncontro = (int) $ps->encontro["id_encontro"];
        $this->view->latest_members = $model->listarUltimosMembros($idEncontro);
    }

    public function ajaxUserRegistrationAction() {
        if (!$this->autenticacao(true)) {
            return;
        }

        if ($this->getRequest()->isPost()) {
            $model = new Admin_Model_EncontroParticipante();
            $this->view->num_participants = $model->getTotalUserRegistration();
            $this->view->ok = true;
        } else {
            $this->view->error = $this->t->_('Request could not be completed.');
        }
    }

    public function ajaxTotalEventsAction() {
        if (!$this->autenticacao(true)) {
            return;
        }

        if ($this->getRequest()->isPost()) {
            $model = new Admin_Model_Evento();
            $this->view->num_events = $model->getTotalEvents();
            $this->view->ok = true;
        } else {
            $this->view->error = $this->t->_('Request could not be completed.');
        }
    }
}
