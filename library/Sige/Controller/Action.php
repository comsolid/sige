<?php

abstract class Sige_Controller_Action extends Zend_Controller_Action {

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
                if (isset($_SERVER['REQUEST_URI'])) {
                    $session = new Zend_Session_Namespace();
                    $session->setExpirationSeconds(60 * 60 * 1); // 1 minuto
                    $session->url = $_SERVER['REQUEST_URI'];
                }
                return $this->_helper->redirector->goToRoute(array(), 'login', true);
            }
        }

        return true;
    }

    protected function _utf8_remove_acentos($str) {
        $keys = array();
        $values = array();
        $from = "áàãâéêíóôõúüçÁÀÃÂÉÊÍÓÔÕÚÜÇ";
        $to = "aaaaeeiooouucAAAAEEIOOOUUC";
        preg_match_all('/./u', $from, $keys);
        preg_match_all('/./u', $to, $values);
        $mapping = array_combine($keys[0], $values[0]);
        return strtr($str, $mapping);
    }

    protected function _stringToFilename($str) {
        $str = strtolower($this->_utf8_remove_acentos($str));
        $str = preg_replace("/ /", "_", $str);
        $str = preg_replace("/[^a-zA-Z0-9_\s]/", "", $str);
        return $str;
    }

    protected function fixObjectSession(&$object) {
        if (!is_object($object) && gettype($object) == 'object') {
            return ($object = unserialize(serialize($object)));
        }
        return $object;
    }
}
