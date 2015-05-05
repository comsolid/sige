<?php

trait Sige_Translate_Abstract {

    protected $t;

    public function __construct() {
        if(!Zend_Registry::isRegistered('Zend_Translate')){
            $bootstrap = Zend_Registry::get('Bootstrap');
            $bootstrap->bootstrap(array('Translator'));
        }
        $this->t = Zend_Registry::get('Zend_Translate');
    }
}
