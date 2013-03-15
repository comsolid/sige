<?php

class Mobile_IndexController extends Zend_Controller_Action {

   public function init() {
      $this->_helper->layout->setLayout('mobile');
   }
}
