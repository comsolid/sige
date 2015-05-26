<?php

class Admin_UsuarioController extends Sige_Controller_AdminAction {

    public function init() {
        $this->_helper->layout->setLayout('twbs3-admin/layout');
        $this->view->menu = new Sige_Desktop_AdminSidebarLeftMenu($this->view, 'config');

        // $this->_helper->getHelper('AjaxContext')
        //     ->addActionContext('ajax-buscar-usuarios', 'json')
        //     ->initContext();
    }

    public function pedidosMudancaEmailAction() {
        $this->autenticacao();

        $this->view->title = $this->t->_('Requests for e-mail change');

        $model = new Admin_Model_MudarEmail();
        $this->view->list = $model->listar();
    }

    public function mudarEmailAction() {
        $this->autenticacao();

        $id = (int) $this->_getParam('id', 0);
        $status = $this->_getParam('status', 'f');

        if ($id < 1 or ! in_array($status, array('f', 't'))) {
            $this->_helper->flashMessenger->addMessage(
                    array('warning' => $this->t->_('Parameters not set correctly.')));
            return $this->_helper->redirector->goToRoute(array(
                'module' => 'admin',
                'controller' => 'usuario',
                'action' => 'pedidos-mudanca-email'), 'default', true);
        }

        $sessao = Zend_Auth::getInstance()->getIdentity();
        $id_pessoa = $sessao["idPessoa"];

        $model = new Admin_Model_MudarEmail();
        $adapter = $model->getAdapter();
        try {
            $adapter->beginTransaction();
            $params = array(
                'ultima_atualizacao' => new Zend_Db_Expr('now()'),
                'atualizado_por' => $id_pessoa,
                'status' => $status
            );
            $where = $model->getAdapter()->quoteInto('id = ?', $id);
            $model->update($params, $where);

            if ($status == 't') {
                $row = $model->fetchRow(
                    $model->select()
                        ->where('id = ?', $id)
                );
                $model->trocarEmail($row['email_anterior'], $row['novo_email']);
            }

            $this->_helper->flashMessenger->addMessage(array('success' => $this->t->_('Request status changed successfully.')));
            $adapter->commit();
        } catch (Zend_Db_Exception $e) {
            $adapter->rollBack();

            if ($e->getCode() == 23505) {
                $this->_helper->flashMessenger->addMessage(
                        array('danger' => $this->t->_('Another person has the new e-mail requested.')));
            } else {
                $this->_helper->flashMessenger->addMessage(
                        array('danger' => $this->t->_('An unexpected error ocurred.<br/> Details:&nbsp;')
                            . $e->getMessage()));
            }
        }

        return $this->_helper->redirector->goToRoute(array(
            'module' => 'admin',
            'controller' => 'usuario',
            'action' => 'pedidos-mudanca-email'), 'default', true);
    }
}
