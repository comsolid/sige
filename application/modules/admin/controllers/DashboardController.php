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
    }

    public function indexAction() {
        $this->view->title = _('Dashboard');
    }

    public function ajaxUserRegistrationAction() {
        $this->_helper->layout()->disableLayout();
        $this->_helper->viewRenderer->setNoRender(true);

        $json = new stdClass;
        if ($this->getRequest()->isPost()) {
            $model = new Admin_Model_EncontroParticipante();
            $json->num_participants = $model->getTotalUserRegistration();
            $json->ok = true;
        } else {
            $json->error = _('Request could not be completed.');
        }

        header("Pragma: no-cache");
        header("Cache: no-cache");
        header("Cache-Control: no-cache, must-revalidate");
        header("Content-type: text/json");
        echo json_encode($json);
    }

    public function ajaxTotalEventsAction() {
        $this->_helper->layout()->disableLayout();
        $this->_helper->viewRenderer->setNoRender(true);

        $json = new stdClass;
        if ($this->getRequest()->isPost()) {
            $model = new Admin_Model_Evento();
            $json->num_events = $model->getTotalEvents();
            $json->ok = true;
        } else {
            $json->error = _('Request could not be completed.');
        }

        header("Pragma: no-cache");
        header("Cache: no-cache");
        header("Cache-Control: no-cache, must-revalidate");
        header("Content-type: text/json");
        echo json_encode($json);
    }
}
