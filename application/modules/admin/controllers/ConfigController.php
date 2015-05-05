<?php

class Admin_ConfigController extends Sige_Controller_AdminAction {

    public function init() {
        $this->_helper->layout->setLayout('twbs3-admin/layout');
        $this->view->menu = new Sige_Desktop_AdminSidebarLeftMenu($this->view, 'config');

        $this->_helper->getHelper('AjaxContext')
            ->addActionContext('ajax-buscar-usuarios', 'json')
            ->initContext();
    }

    public function indexAction() {
        $this->autenticacao();

        $this->view->title = $this->t->_('Configurations');
    }

    public function permissaoUsuariosAction() {
        $this->autenticacao();

        $this->view->title = $this->t->_('User permissions');
    }

    public function ajaxBuscarUsuariosAction() {
        if (!$this->autenticacao(true)) {
            return;
        }

        $sessao = Zend_Auth::getInstance()->getIdentity();
        $cache = Zend_Registry::get('cache_common');
        $ps = $cache->load('prefsis');
        $idEncontro = (int) $ps->encontro["id_encontro"];

        $model = new Application_Model_Pessoa();
        try {
            $data = $model->buscarPermissaoUsuarios(
                    $idEncontro,
                    $this->_request->getParam("termo", ""),
                    $this->_request->getParam("buscar_por", ""),
                    $this->_request->getParam("tipo_usuario", 0)
            );

            $this->view->size = count($data);
            $this->view->aaData = array();

            foreach ($data as $value) {
                if ($value['administrador']) {
                    $admin = "<i class='fa fa-unlock'></i> Admin";
                } else {
                    $admin = "<i class='fa fa-lock'></i> Usuário";
                }
                $acao = "<a href=\"/admin/config/editar-permissao/id/{$value['id_pessoa']}\"
                    class=\"btn btn-default\"><i class=\"fa fa-edit\"></i> "
                    . $this->t->_("Edit permission") . "</a>";

                $this->view->aaData[] = array(
                    "{$value ['nome']}",
                    "{$value ['apelido']}",
                    "{$value ['email']}",
                    "{$admin}<br/>{$value['descricao_tipo_usuario']}",
                    $acao
                );
            }
        } catch (Exception $e) {
            $this->view->erro = $e->getMessage();
        }
    }

    public function editarPermissaoAction() {
        $this->autenticacao();

        $this->view->title = $this->t->_('Edit Permission');

        $cache = Zend_Registry::get('cache_common');
        $ps = $cache->load('prefsis');
        $idEncontro = (int) $ps->encontro["id_encontro"];

        $model = new Application_Model_Pessoa();
        $form = new Admin_Form_Permissao();
        $this->view->form = $form;

        if ($this->getRequest()->isPost()) {
            $formData = $this->getRequest()->getPost();
            if ($form->isValid($formData)) {

                $cancelar = $this->getRequest()->getPost('cancelar');
                if (isset($cancelar)) {
                    return $this->_helper->redirector->goToRoute(array(
                                'module' => 'admin',
                                'controller' => 'config',
                                'action' => 'permissao-usuarios'), 'default', true);
                }

                $id = $this->getRequest()->getParam('id', 0);
                $admin = ((bool) $form->getValue('admin') ? 't' : 'f');
                $id_tipo_usuario = $form->getValue('id_tipo_usuario');

                $adapter = $model->getAdapter();
                try {
                    $adapter->beginTransaction();
                    $model->update(array('administrador' => $admin), 'id_pessoa = ' . $id);

                    $adapter->update("encontro_participante", array('id_tipo_usuario' => $id_tipo_usuario), "id_encontro = {$idEncontro} AND id_pessoa = {$id}");
                    $adapter->commit();
                    return $this->_helper->redirector->goToRoute(array(
                                'module' => 'admin',
                                'controller' => 'config',
                                'action' => 'permissao-usuarios'), 'default', true);
                } catch (Exception $e) {
                    $this->_helper->flashMessenger->addMessage(
                            array('danger' => 'Ocorreu um erro inesperado.<br/>Detalhes: '
                                . $e->getMessage()));
                    $adapter->rollBack();
                }
            } else {
                $form->populate($formData);
            }
        } else {
            $id = $this->_getParam('id', 0);
            if ($id > 0) {
                $rs = $model->buscarPermissaoUsuarios($idEncontro, $id, "id_pessoa");
                $data = $rs[0];
                $form->populate(array(
                    'admin' => $data['administrador'],
                    'id_tipo_usuario' => $data['id_tipo_usuario']
                ));
                $this->view->usuario = $data['nome'];
            }
        }
    }

    public function limparCacheAction() {
        $this->autenticacao();

        $this->_helper->layout()->disableLayout();
        $this->_helper->viewRenderer->setNoRender(true);

        try {
            $cache = Zend_Registry::get('cache_common');
            $cache->clean(Zend_Cache::CLEANING_MODE_ALL); // limpa todos os caches
            // $cache->remove('cache_common'); // limpa somente cache espeficico

            $this->_helper->flashMessenger->addMessage(
                    array('success' => 'Cache foi limpo com sucesso.'));
        } catch (Exception $e) {
            $this->_helper->flashMessenger->addMessage(
                    array('error' => 'Ocorreu um erro inesperado.<br/>Detalhes: '
                        . $e->getMessage()));
        }
        return $this->_helper->redirector->goToRoute(array(
                    'module' => 'admin',
                    'controller' => 'config',
                    'action' => 'index'), 'default', true);
    }

    public function infoSistemaAction() {
        $this->autenticacao();

        $this->view->title = $this->t->_('System Info');

        $sistema = new Admin_Model_Sistema();
        $this->view->postgres = $sistema->infoPostgres();
    }
}
