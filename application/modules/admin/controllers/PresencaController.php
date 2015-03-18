<?php

class Admin_PresencaController extends Zend_Controller_Action {

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

        $this->_helper->layout->setLayout('twbs3-admin/layout');
        $this->view->menu = new Sige_Desktop_AdminSidebarLeftMenu($this->view, 'events');
    }

    public function indexAction() {
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
        $this->_helper->layout()->disableLayout();
        $this->_helper->viewRenderer->setNoRender(true);
        $cache = Zend_Registry::get('cache_common');
        $ps = $cache->load('prefsis');
        $idEncontro = (int) $ps->encontro["id_encontro"];
        $sessao = Zend_Auth::getInstance()->getIdentity();
        //$idPessoa = $sessao["idPessoa"];

        $model = new Admin_Model_Pessoa();
        $termo = $this->_request->getParam("termo", "");
        $id_evento_realizacao = (int) $this->_request->getParam("id_evento_realizacao", 0);

        $json = new stdClass;
        $rs = $model->ajaxBuscarEmail($termo, $idEncontro, $id_evento_realizacao);
        $json->size = count($rs);
        $json->results = $rs;

        header("Pragma: no-cache");
        header("Cache: no-cache");
        header("Cache-Control: no-cache, must-revalidate");
        header("Content-type: text/json");
        echo json_encode($json);
    }

    public function salvarAction() {
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
