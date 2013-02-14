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
      
      $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'emailmsg');
      $this->view->confirmacao = $config->email->confirmacao;
      $this->view->correcao = $config->email->correcao;
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
            $modelMensagem = new Admin_Model_MensagemEmail();
            
            $model->getAdapter()->beginTransaction();
            try {
               $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'staging');
               $dbdf = $config->db->date->format;
               
               if (! empty($values['data_inicio'])) {
                  $date = new Zend_Date($values['data_inicio']);
                  $values['data_inicio'] = $date->toString($dbdf);
               }
               
               if (! empty($values['data_fim'])) {
                  $date = new Zend_Date($values['data_fim']);
                  $values['data_fim'] = $date->toString($dbdf);
               }
               
               $id = $model->insert($values);
               $modelMensagem->criarMensagensPadrao(
                       $id, $values['apelido_encontro']
               );
               $model->getAdapter()->commit();
               $this->_helper->flashMessenger->addMessage(
                     array('success' => 'Encontro criado com sucesso.'));
               return $this->_helper->redirector->goToRoute(array(
                  'module' => 'admin',
                  'controller' => 'encontro',
                  'action' => 'index'), 'default', true);
            } catch (Exception $e) {
               $model->getAdapter()->rollBack();
               $this->_helper->flashMessenger->addMessage(
                     array('error' => 'Ocorreu um erro inesperado.<br/>Detalhes: '
                         . $e->getMessage()));
            }
         } else {
            $form->populate($formData);
         }
      }
   }
   
   public function editarAction() {
      $form = new Admin_Form_Encontro();
      $this->view->form = $form;
      $model = new Admin_Model_Encontro();
      
      if ($this->getRequest()->isPost()) {
         $formData = $this->getRequest()->getPost();

         if (isset($formData['cancelar'])) {
            return $this->_helper->redirector->goToRoute(array(
                        'module' => 'admin',
                        'controller' => 'encontro'
                            ), 'default', true);
         }
         
         if ($form->isValid($formData)) {
            $id = $this->getRequest()->getParam('id', 0);
            $values = $form->getValues();
            
            try {
               $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'staging');
               $dbdf = $config->db->date->format;

               if (!empty($values['data_inicio'])) {
                  $date = new Zend_Date($values['data_inicio']);
                  $values['data_inicio'] = $date->toString($dbdf);
               }

               if (!empty($values['data_fim'])) {
                  $date = new Zend_Date($values['data_fim']);
                  $values['data_fim'] = $date->toString($dbdf);
               }
               $model->update($values, 'id_encontro = ' . $id);
               $this->_helper->flashMessenger->addMessage(
                     array('success' => 'Encontro atualizado com sucesso.'));
               return $this->_helper->redirector->goToRoute(array(
                  'module' => 'admin',
                  'controller' => 'encontro',
                  'action' => 'index'), 'default', true);
            } catch (Exception $e) {
               $this->_helper->flashMessenger->addMessage(
                     array('error' => 'Ocorreu um erro inesperado.<br/>Detalhes: '
                         . $e->getMessage()));
            }
         } else {
            $form->populate($formData);
         }
      } else {
         $id = $this->_getParam('id', 0);
         if ($id > 0) {
            $array = $model->fetchRow('id_encontro = ' . $id)->toArray();
            
            $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'staging');
            $appdf = $config->app->date->format;
            if (!empty($array['data_inicio'])) {
               $date = new Zend_Date($array['data_inicio']);
               $array['data_inicio'] = $date->toString($appdf);
            }

            if (!empty($array['data_fim'])) {
               $date = new Zend_Date($array['data_fim']);
               $array['data_fim'] = $date->toString($appdf);
            }
            
            $form->populate($array);
         }
      }
   }
   
   public function editarMensagemEmailConfirmacaoAction() {
      $form = new Admin_Form_MensagemEmail();
      $this->view->form = $form;
      $model = new Admin_Model_MensagemEmail();
      
      if ($this->getRequest()->isPost()) {
         $formData = $this->getRequest()->getPost();
         
         if (isset ($formData['cancelar'])) {
            return $this->_helper->redirector->goToRoute(array(
                'module' => 'admin',
                'controller' => 'encontro'
            ), 'default', true);
         }
         
         if ($form->isValid($formData)) {
            $data = array(
               'mensagem' => $form->getValue('mensagem'),
               'assunto' => $form->getValue('assunto'),
               'link' => $form->getValue('link')
            );
            $idEncontro = (int) $form->getValue('id_encontro');
            $idTipoMensagem = (int) $form->getValue('id_tipo_mensagem_email');
            try {
               $model->update($data,
                     "id_encontro = {$idEncontro}
                     AND id_tipo_mensagem_email = {$idTipoMensagem}");
               $this->_helper->flashMessenger->addMessage(
                  array('success' => 'Mensagem atualizada com sucesso.'));
               return $this->_helper->redirector->goToRoute(array(
                  'module' => 'admin',
                  'controller' => 'encontro',
                  'action' => 'index'), 'default', true);
            } catch(Exception $e) {
               $this->_helper->flashMessenger->addMessage(
                     array('error' => 'Ocorreu um erro inesperado.<br/>Detalhes: '
                         . $e->getMessage()));
            }
         } else {
            $form->populate($formData);
         }
      } else {
         $id = $this->_getParam('id', 0);
         $id_tipo_mensagem = $this->_getParam('id_tipo_mensagem', 0);
         if ($id > 0 and $id_tipo_mensagem > 0) {
            $row = $model->fetchRow("id_encontro = {$id} AND id_tipo_mensagem_email = {$id_tipo_mensagem}");
            $form->populate($row->toArray());
         }
      }
   }
}

