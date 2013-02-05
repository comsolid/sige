<?php

class Admin_EncontroController extends Zend_Controller_Action {

   public function init() {
      if (!Zend_Auth::getInstance()->hasIdentity()) {
         return $this->_helper->redirector->goToRoute(array(), 'login', true);
      }

      $sessao = Zend_Auth::getInstance()->getIdentity();
      if (!$sessao["administrador"]) {
         return $this->_helper->redirector->goToRoute(array('controller' => 'participante',
                     'action' => 'index'), 'default', true);
      }
      $this->view->menu = new Application_Form_Menu($this->view, 'admin', true);
   }

   public function indexAction() {
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/tabela_sort.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/screen.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/prettify.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/jqueryui-bootstrap/jquery-ui-1.8.16.custom.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/jqueryui-bootstrap/jquery.ui.1.8.16.ie.css'));

      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-1.6.2.min.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery.dataTables.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/prettify.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/init.prettify.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('/js/admin/encontro/index.js'));
      
      $model = new Admin_Model_Encontro();
      $this->view->lista = $model->listar();
   }

   public function criarAction() {
      $form = new Admin_Form_Encontro();
      $this->view->form = $form;
      
      if ($this->getRequest()->isPost()) {
         $formData = $this->getRequest()->getPost();
         
         if (isset ($formData['cancelar'])) {
            return $this->_helper->redirector->goToRoute(array(
                'module' => 'admin',
                'controller' => 'encontro'
            ), 'default', true);
         }
         
         if ($form->isValid($formData)) {
            $values = $form->getValues();
            $model = new Admin_Model_Encontro();
            try {
               $model->insert($values);
               $this->_helper->flashMessenger->addMessage(
                     array('sucess' => 'Encontro criado com sucesso.'));
            } catch (Exception $e) {
               $this->_helper->flashMessenger->addMessage(
                     array('error' => 'Ocorreu um erro inesperado.<br/>Detalhes: '
                         . $e->getMessage()));
            }
         } else {
            $form->populate($formData);
         }
      }
   }
   
   public function editarMensagemEmailConfirmacaoAction() {
      $form = new Admin_Form_MensagemEmail();
      $this->view->form = $form;
   }
}

