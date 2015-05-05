<?php
class Admin_EncontroController extends Sige_Controller_AdminAction {

    public function init() {
        $this->_helper->layout->setLayout('twbs3-admin/layout');
        $this->view->menu = new Sige_Desktop_AdminSidebarLeftMenu($this->view, 'config');
    }

    public function indexAction() {
        $this->autenticacao();

        $this->view->title = _('Conferences');

        $model = new Admin_Model_Encontro();
        $this->view->lista = $model->listar();
        $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'emailmsg');
        $this->view->confirmacao = $config->email->confirmacao_inscricao;
        $this->view->correcao = $config->email->recuperacao_senha;
        $this->view->confirmacao_submissao = $config->email->confirmacao_submissao;
        $this->view->confirmacao_reinscricao = $config->email->confirmacao_reinscricao;
    }

    public function criarAction() {
        $this->autenticacao();

        $this->view->title = _('New Conference');
        $this->_helper->viewRenderer->setRender('salvar');
        $form = new Admin_Form_Encontro();
        $this->view->form = $form;
        if ($this->getRequest()->isPost()) {
            $formData = $this->getRequest()->getPost();
            if (isset($formData['cancelar'])) {
                return $this->_helper->redirector->goToRoute(array(
                    'module' => 'admin',
                    'controller' => 'encontro'), 'default', true);
            }
            if ($form->isValid($formData)) {
                $values = $form->getValues();
                $model = new Admin_Model_Encontro();
                $modelMensagem = new Admin_Model_MensagemEmail();
                $model->getAdapter()->beginTransaction();
                try {
                    $id = $model->criar($values);
                    $modelMensagem->criarMensagensPadrao($id, $values['apelido_encontro']);
                    $model->getAdapter()->commit();
                    $this->_helper->flashMessenger->addMessage(array('success' => 'Encontro criado com sucesso.'));
                    return $this->_helper->redirector->goToRoute(array(
                        'module' => 'admin',
                        'controller' => 'encontro',
                        'action' => 'index'), 'default', true);
                }
                catch(Exception $e) {
                    $model->getAdapter()->rollBack();
                    $this->_helper->flashMessenger->addMessage(array('danger' => _('An unexpected error ocurred.<br/> Details:&nbsp;') . $e->getMessage()));
                }
            } else {
                $form->populate($formData);
            }
        }
    }

    public function editarAction() {
        $this->autenticacao();

        $this->view->title = _('Edit Conference');
        $this->_helper->viewRenderer->setRender('salvar');
        $form = new Admin_Form_Encontro();
        $this->view->form = $form;
        $model = new Admin_Model_Encontro();
        if ($this->getRequest()->isPost()) {
            $formData = $this->getRequest()->getPost();
            if (isset($formData['cancelar'])) {
                return $this->_helper->redirector->goToRoute(array(
                    'module' => 'admin',
                    'controller' => 'encontro'), 'default', true);
            }
            if ($form->isValid($formData)) {
                $id_encontro = $this->getRequest()->getParam('id', 0);
                $values = $form->getValues();
                try {
                    $model->atualizar($values, $id_encontro);
                    $this->_helper->flashMessenger->addMessage(array('success' => 'Encontro atualizado com sucesso.'));
                    return $this->_helper->redirector->goToRoute(array(
                        'module' => 'admin',
                        'controller' => 'encontro',
                        'action' => 'index'), 'default', true);
                }
                catch(Exception $e) {
                    $this->_helper->flashMessenger->addMessage(array('danger' => _('An unexpected error ocurred.<br/> Details:&nbsp;') . $e->getMessage()));
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
        $this->autenticacao();

        $form = new Admin_Form_MensagemEmail();
        $this->view->form = $form;
        $model = new Admin_Model_MensagemEmail();
        if ($this->getRequest()->isPost()) {
            $formData = $this->getRequest()->getPost();

            if ($form->isValid($formData)) {
                $data = array('mensagem' => $form->getValue('mensagem'), 'assunto' => $form->getValue('assunto'), 'link' => $form->getValue('link'));
                $idEncontro = (int) $form->getValue('id_encontro');
                $idTipoMensagem = (int) $form->getValue('id_tipo_mensagem_email');
                try {
                    $model->update($data, "id_encontro = {$idEncontro}
                     AND id_tipo_mensagem_email = {$idTipoMensagem}");
                    $this->_helper->flashMessenger->addMessage(array('success' => _('Message successfully updated.')));
                    return $this->_helper->redirector->goToRoute(array(
                        'module' => 'admin',
                        'controller' => 'encontro',
                        'action' => 'index'), 'default', true);
                }
                catch(Exception $e) {
                    $this->_helper->flashMessenger->addMessage(array('danger' => _('An unexpected error ocurred.<br/> Details:&nbsp;') . $e->getMessage()));
                }
            } else {
                $form->populate($formData);
            }
        }

        $id = (int)$this->_getParam('id', 0);
        $id_tipo_mensagem = (int)$this->_getParam('id_tipo_mensagem', 0);

        switch ($id_tipo_mensagem) {
            case Application_Model_EmailConfirmacao::MSG_CONFIRMACAO:
                $this->view->title = _("Edit e-mail confirmation message");
                break;
            case Application_Model_EmailConfirmacao::MSG_RECUPERAR_SENHA:
                $this->view->title = _("Edit e-mail recover password message");
                break;
            case Application_Model_EmailConfirmacao::MSG_CONFIRMACAO_SUBMISSAO:
                $this->view->title = _("Edit e-mail submission confirmation message");
                break;
            case Application_Model_EmailConfirmacao::MSG_CONFIRMACAO_REINSCRICAO:
                $this->view->title = _("Edit e-mail registration confirmation message");
                break;
            default:
                $this->_helper->flashMessenger->addMessage(array('info' => _('E-mail message not find.')));
                return $this->_helper->redirector->goToRoute(array(
                    'module' => 'admin',
                    'controller' => 'encontro',
                    'action' => 'index'), 'default', true);
        }

        if ($id > 0 and $id_tipo_mensagem > 0) {
            // TODO: usar bindings
            $row = $model->fetchRow("id_encontro = {$id} AND id_tipo_mensagem_email = {$id_tipo_mensagem}");
            $form->populate($row->toArray());
        }
    }

    public function editarMensagemCertificadoAction() {
        $this->autenticacao();

        $tipo_mensagem = $this->_getParam('tipo_mensagem_certificado');
        switch ($tipo_mensagem) {
            case "certificados_template_participante_encontro":
                $this->view->title = _('Participant of Conference Template');
                $this->view->options = array(
                    '{nome}',
                    '{encontro}'
                );
                break;
            case "certificados_template_palestrante_evento":
                $this->view->title = _('Event Speaker Template');
                $this->view->options = array(
                    '{nome}',
                    '{encontro}',
                    '{tipo_evento}',
                    '{nome_evento}',
                    '{carga_horaria}'
                );
                break;
            case "certificados_template_participante_evento":
                $this->view->title = _('Participant of Event Template');
                $this->view->options = array(
                    '{nome}',
                    '{encontro}',
                    '{tipo_evento}',
                    '{nome_evento}',
                    '{carga_horaria}'
                );
                break;
            default:
                throw new Exception(_('Certificate type unknow.'));
        }

        $form = new Admin_Form_MensagemCertificado();
        $model_encontro = new Admin_Model_Encontro();

        if ($this->getRequest()->isPost()) {
            $formData = $this->getRequest()->getPost();

            if (isset($formData['cancelar'])) {
                return $this->_helper->redirector->goToRoute(array(
                            'module' => 'admin',
                            'controller' => 'encontro'
                                ), 'default', true);
            }

            if ($form->isValid($formData)) {
                $id_encontro = (int) $form->getValue('id_encontro');
                $tipo_mensagem = $form->getValue('tipo_mensagem_certificado');

                if ($id_encontro < 1) {
                    throw new Exception("Encontro não encontrado.");
                }

                $data = array(
                    $tipo_mensagem => $form->getValue("mensagem"),
                );

                try {
                    $model_encontro->update($data, "id_encontro = {$id_encontro}");
                    $this->_helper->flashMessenger->addMessage(
                            array('success' => 'Mensagem atualizada com sucesso.'));
                } catch (Exception $e) {
                    $this->_helper->flashMessenger->addMessage(
                            array('error' => 'Ocorreu um erro inesperado.<br/>Detalhes: '
                                . $e->getMessage()));
                }
            } else {
                $form->populate($formData);
            }
        }

        $id_encontro = (int) $this->_getParam('id_encontro');
        $tipo_mensagem = $this->_getParam('tipo_mensagem_certificado');
        if ($id_encontro > 0 and ! empty($tipo_mensagem)) {
            $row = $model_encontro->lerMensagemCertificado($id_encontro, $tipo_mensagem);
            if ($row == null) {
                $this->_helper->flashMessenger->addMessage(
                        array('warning' => _('Conference not found.')));
                return $this->_helper->redirector->goToRoute(array(
                            'module' => 'admin',
                            'controller' => 'encontro',
                            'action' => 'index'), 'default', true);
            }
            $row["tipo_mensagem_certificado"] = $tipo_mensagem;
            $form->populate($row);

            $this->view->pdf = $model_encontro->gerarCertificadoPreview($id_encontro, $tipo_mensagem);
        }
        $this->view->form = $form;
    }
}
