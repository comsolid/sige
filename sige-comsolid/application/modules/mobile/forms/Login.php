<?php

class Mobile_Form_Login extends Application_Form_Login {

   public function init() {
      $this->addElement($this->_email());
      $this->addElement($this->_senha());
   }

   protected function _email() {
      $e = parent::_email();
      $e->setAttrib("data-clear-btn", "true")
        ->setDecorators(array(
            'ViewHelper',
            'Description',
            'Errors',
            array('HtmlTag', ''),
            array('Label', ''),
      ))
      ->getDecorator('label')->setOption('tag', null);
      return $e;
   }
   
   protected function _senha() {
      $e = parent::_senha();
      $e->setAttrib("data-clear-btn", "true")
        ->setDecorators(array(
            'ViewHelper',
            'Description',
            'Errors',
            array('HtmlTag', ''),
            array('Label', ''),
      ))
      ->getDecorator('label')->setOption('tag', null);
      return $e;
   }
}

