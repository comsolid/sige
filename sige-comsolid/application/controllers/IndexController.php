<?php

class IndexController extends Zend_Controller_Action
{

    public function init()
    {
        /* Initialize action controller here */
    }

    public function indexAction()
    {
		return $this->_helper->redirector->goToRoute(array (
						'controller' => 'login',
						'action' => 'login'
					), null, true);
    }

}

