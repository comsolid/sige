<?php

abstract class Sige_Controller_AdminAction extends Sige_Controller_Action {

    protected function autenticacao($isAjax = false) {
        if (! Zend_Auth::getInstance()->hasIdentity()) {
            if ($isAjax) {
                // if is ajax request, let js handle redirect properly ;)
                $session = new Zend_Session_Namespace();
                if (isset($session->url)) {
                    unset($session->url);
                }

                $this->view->error = _("Permission denied.");
                $this->_response->setHttpResponseCode(403);
                return false;
            } else {
                $session = new Zend_Session_Namespace();
                $session->setExpirationSeconds(60 * 60 * 1); // 1 minuto
                $session->url = $_SERVER['REQUEST_URI'];

                return $this->_helper->redirector->goToRoute(array(), 'login', true);
            }
        }

        $sessao = Zend_Auth::getInstance()->getIdentity();
        if (! $sessao["administrador"]) {
            if($this->getRequest()->isXmlHttpRequest()) {
                $this->view->error = _("Unauthorized.");
                $this->_response->setHttpResponseCode(401);
                return false;
            } else {
                return $this->_helper->redirector->goToRoute(array(
                            'controller' => 'participante',
                            'action' => 'index'), 'default', true);
            }
        }

        return true;
    }
}
