<?php

class UsuarioController extends Zend_Controller_Action
{
   public function getForm()
   {
       // create form as above
       return $form;
   }

   public function indexAction()
   {
       // render user/form.phtml
       $this->view->form = $this->getForm();
       $this->render('form');
   }

   public function loginAction()
   {
       if (!$this->getRequest()->isPost()) {
           return $this->_forward('index');
       }
       $form = $this->getForm();
       if (!$form->isValid($_POST)) {
           // Failed validation; redisplay form
           $this->view->form = $form;
           return $this->render('form');
       }

       $values = $form->getValues();
       // now try and authenticate....
   }
}

    
?>
