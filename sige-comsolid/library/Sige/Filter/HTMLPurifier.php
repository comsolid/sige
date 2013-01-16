<?php

/**
 * @author atilacamurca
 */
class Sige_Filter_HTMLPurifier implements Zend_Filter_Interface {

   /**
    *
    * @var HTMLPurifier 
    */
   protected $purifier;

   public function __construct($options = null) {
      // lista de chaves para $config->set($key, $value)
      HTMLPurifier_Bootstrap::registerAutoload();
      $config = HTMLPurifier_Config::createDefault();
      $config->set('HTML.Strict', true);
      $config->set('Attr.EnableID', true);
      $config->set('HTML.TargetBlank', true);
      $this->purifier = new HTMLPurifier($config);
   }

   public function filter($value) {
      return $this->purifier->purify($value);
   }

}
