<?php

class Admin_PresencaController extends Sige_Controller_AdminAction {

    public function init() {
        $this->_helper->layout->setLayout('twbs3-admin/layout');
        $this->view->menu = new Sige_Desktop_AdminSidebarLeftMenu($this->view, 'events');

        $this->_helper->getHelper('AjaxContext')
            ->addActionContext('ajax-buscar-participante', 'json')
            ->initContext();
    }

    public function indexAction() {
        $this->autenticacao();

        $this->view->title = $this->t->_('Presence List');

        $id_evento = (int) $this->_request->getParam('id', 0);
        $id_evento_realizacao = (int) $this->_request->getParam('id_evento_realizacao', 0);
        $this->view->id = $id_evento;
        $this->view->id_evento_realizacao = $id_evento_realizacao;

        $evento = new Admin_Model_Evento();
        $evento_result = $evento->buscaEventoPessoa($id_evento);
        if (!$evento_result) {
            $this->_helper->flashMessenger->addMessage(array('error' =>
                'Evento não encontrado.'));
            return $this->_helper->redirector->goToRoute(array(
                        'module' => 'admin',
                        'controller' => 'evento',
                        'action' => 'index',
                            ), 'default');
        }
        $this->view->evento = $evento_result;

        $model = new Admin_Model_EventoParticipacao();
        $this->view->participantes = $model->listar($id_evento_realizacao);
    }

    public function ajaxBuscarParticipanteAction() {
        if (!$this->autenticacao(true)) {
            return;
        }

        $cache = Zend_Registry::get('cache_common');
        $ps = $cache->load('prefsis');
        $idEncontro = (int) $ps->encontro["id_encontro"];
        $sessao = Zend_Auth::getInstance()->getIdentity();
        $id_pessoa = $sessao["idPessoa"];

        $model = new Admin_Model_Pessoa();
        $termo = $this->_request->getParam("termo", "");
        $id_evento_realizacao = (int) $this->_request->getParam("id_evento_realizacao", 0);

        try {
            $rs = $model->ajaxBuscarEmail($termo, $id_pessoa, $idEncontro, $id_evento_realizacao);
            $this->view->size = count($rs);
            $this->view->results = $rs;
        } catch (Zend_Db_Exception $e) {
            $this->view->error = $this->t->_('Error on fetching results.');
        }
    }

    public function salvarAction() {
        $this->autenticacao();

        $id_evento = (int) $this->_request->getParam('id', 0);
        $id_evento_realizacao = (int) $this->_request->getParam('id_evento_realizacao', 0);

        if ($this->getRequest()->isPost()) {
            $submit = $this->getRequest()->getPost('submit');
            if (isset($submit)) {
                $array_id_pessoas = explode(",", $this->getRequest()->getPost('array_id_pessoas'));
                if (count($array_id_pessoas) == 1 && empty($array_id_pessoas[0])) {
                    $this->_helper->flashMessenger->addMessage(
                            array('warning' => 'Nenhum participante foi selecionado.'));
                } else {
                    $model = new Admin_Model_EventoParticipacao();
                    try {
                        $count = $model->adicionarEmMassa($id_evento_realizacao, $array_id_pessoas);
                        $this->_helper->flashMessenger->addMessage(
                                array('success' => $count . ' participantes adicionados com sucesso.'));
                    } catch (Zend_Db_Exception $e) {
                        if ($e->getCode() == 23505) {
                            $this->_helper->flashMessenger->addMessage(
                                    array('warning' => 'Um ou mais e-mails já existem.'));
                        } else {
                            $this->_helper->flashMessenger->addMessage(
                                    array('danger' => 'Ocorreu um erro inesperado.<br/>Detalhes: ' . $e->getMessage())
                            );
                        }
                    } catch (Exception $e) {
                        $this->_helper->flashMessenger->addMessage(
                                array('danger' => 'Ocorreu um erro inesperado.<br/>Detalhes: ' . $e->getMessage())
                        );
                    }
                }
            }
        }

        $this->_helper->redirector->goToRoute(array(
            'module' => 'admin',
            'controller' => 'presenca',
            'action' => 'index',
            'id' => $id_evento,
            'id_evento_realizacao' => $id_evento_realizacao
                ), 'default', true);
    }

    public function deletarAction() {
        $this->autenticacao();

        $id_evento = (int) $this->_request->getParam('id_evento', 0);
        $id_evento_realizacao = (int) $this->_request->getParam('id_evento_realizacao', 0);
        $id_pessoa = (int) $this->_request->getParam('id_pessoa', 0);

        try {
            $model = new Admin_Model_EventoParticipacao();
            $model->delete(array(
                'id_pessoa = ?' => $id_pessoa,
                'id_evento_realizacao = ?' => $id_evento_realizacao,
            ));
            $this->_helper->flashMessenger->addMessage(
                    array('success' => 'Participante deletado com sucesso.'));
        } catch (Exception $e) {
            $this->_helper->flashMessenger->addMessage(
                    array('error' => 'Ocorreu um erro inesperado.<br/>Detalhes: ' . $e->getMessage())
            );
        }

        $this->_helper->redirector->goToRoute(array(
            'module' => 'admin',
            'controller' => 'presenca',
            'action' => 'index',
            'id' => $id_evento,
            'id_evento_realizacao' => $id_evento_realizacao
        ), 'default', true);
    }

}
