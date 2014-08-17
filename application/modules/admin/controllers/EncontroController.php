<?php

class Admin_EncontroController extends Zend_Controller_Action {

   public function init() {
      if (!Zend_Auth::getInstance()->hasIdentity()) {
         $session = new Zend_Session_Namespace();
         $session->setExpirationSeconds(60 * 60 * 1); // 1 minuto
         $session->url = $_SERVER['REQUEST_URI'];
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

               $id = $model->criar($values);
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
                     array('error' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
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
            $id_encontro = $this->getRequest()->getParam('id', 0);
            $values = $form->getValues();

            try {
               $model->atualizar($values, $id_encontro);
               $this->_helper->flashMessenger->addMessage(
                     array('success' => 'Encontro atualizado com sucesso.'));
               return $this->_helper->redirector->goToRoute(array(
                  'module' => 'admin',
                  'controller' => 'encontro',
                  'action' => 'index'), 'default', true);
            } catch (Exception $e) {
               $this->_helper->flashMessenger->addMessage(
                     array('error' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
                         . $e->getMessage()));
            }
         } else {
            $form->populate($formData);
         }
      } else {
         $id_encontro = $this->_getParam('id', 0);
         if ($id_encontro > 0) {
            $array = $model->ler($id_encontro);
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

            if (isset($formData['cancelar'])) {
                return $this->_helper->redirector->goToRoute(array(
                            'module' => 'admin',
                            'controller' => 'encontro'), 'default', true);
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
                    $model->update($data, "id_encontro = {$idEncontro}
                     AND id_tipo_mensagem_email = {$idTipoMensagem}");
                    $this->_helper->flashMessenger->addMessage(
                            array('success' => _('Message successfully updated.')));
                    return $this->_helper->redirector->goToRoute(array(
                                'module' => 'admin',
                                'controller' => 'encontro',
                                'action' => 'index'), 'default', true);
                } catch (Exception $e) {
                    $this->_helper->flashMessenger->addMessage(
                            array('error' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
                                . $e->getMessage()));
                }
            } else {
                $form->populate($formData);
            }
        } else {
            $id = (int) $this->_getParam('id', 0);
            $id_tipo_mensagem = (int) $this->_getParam('id_tipo_mensagem', 0);
            if ($id > 0 and $id_tipo_mensagem > 0) {
                $row = $model->fetchRow("id_encontro = {$id} AND id_tipo_mensagem_email = {$id_tipo_mensagem}");
                $form->populate($row->toArray());
            }

            if ($id_tipo_mensagem == Application_Model_EmailConfirmacao::MSG_CONFIRMACAO) {
                $this->view->title = _("Edit e-mail confirmation message");
            } else {
                $this->view->title = _("Edit e-mail recover password message");
            }
        }
    }
}
