<?php

class CaravanaController extends Zend_Controller_Action {

    public function init() {
        if (!Zend_Auth :: getInstance()->hasIdentity()) {
            $session = new Zend_Session_Namespace();
            $session->setExpirationSeconds(60 * 60 * 1); // 1 minuto
            $session->url = $_SERVER['REQUEST_URI'];
            return $this->_helper->redirector->goToRoute(array(), 'login', true);
        }

        $sessao = Zend_Auth::getInstance()->getIdentity();
        $this->view->menu = new Sige_Desktop_Menu($this->view, 'caravan', $sessao['administrador']);
        $this->_helper->layout->setLayout('twbs3/layout');
    }

    public function indexAction() {
        $cache = Zend_Registry::get('cache_common');
        $ps = $cache->load('prefsis');
        $id_encontro = (int) $ps->encontro["id_encontro"];
        $sessao = Zend_Auth::getInstance()->getIdentity();
        $model = new Application_Model_CaravanaEncontro();

        $this->view->participante = $model->lerParticipanteCaravana($id_encontro, $sessao["idPessoa"]);
        $this->view->caravanaResponsavel = $model->lerResponsavelCaravana($id_encontro, $sessao["idPessoa"]);
    }

    public function participantesAction() {
        $cancelar = $this->getRequest()->getPost('cancelar');
        if (isset($cancelar)) {
            return $this->_helper->redirector->goToRoute(array(
                        'controller' => 'caravana',
                        'action' => 'index'), null, true);
        }

        $cache = Zend_Registry::get('cache_common');
        $ps = $cache->load('prefsis');
        $idEncontro = (int) $ps->encontro["id_encontro"];
        $sessao = Zend_Auth::getInstance()->getIdentity();
        $idPessoa = $sessao["idPessoa"];

        $caravanaEncontro = new Application_Model_CaravanaEncontro();
        $rs = $caravanaEncontro->lerResponsavelCaravana($idEncontro, $idPessoa);
        $this->view->caravana = $rs;

        if ($this->getRequest()->isPost()) {
            $submit = $this->getRequest()->getPost('submit');
            if (isset($submit)) {
                $array_id_pessoas = explode(",", $this->getRequest()->getPost('array_id_pessoas'));
                // se não existir e-mail a ser adicionado a caravana
                // explode retorna array(0 => "") http://php.net/manual/pt_BR/function.explode.php
                if (count($array_id_pessoas) == 1 && empty($array_id_pessoas[0])) {
                    $this->_helper->flashMessenger->addMessage(
                            array('warning' => _('No participant was selected.')));
                } else {
                    $where = array(
                        $this->view->caravana['id_caravana'],
                        $idEncontro,
                        $idEncontro, // id_encontro usado em subquery
                    );
                    $where = array_merge($where, $array_id_pessoas);
                    try {
                        $result = $caravanaEncontro->updateParticipantesCaravana($where);
                        if ($result) {
                            $success = sprintf(
                            ngettext("One participant added to this caravan successfully.",
                                    "%d participants added to this caravan successfully.", $result), $result);
                            $this->_helper->flashMessenger->addMessage(
                                    array('success' => $success));
                        } else {
                            $this->_helper->flashMessenger->addMessage(
                                    array('warning' => _('No participant was added to this caravan.')));
                        }
                    } catch (Exception $e) {
                        $this->_helper->flashMessenger->addMessage(
                                array('danger' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
                                    . $e->getMessage()));
                    }
                }
            }
        }

        $this->view->participantes = $caravanaEncontro->buscaParticipantes($this->view->caravana['id_caravana'], $idEncontro);
    }

    public function ajaxBuscarParticipanteAction() {
        $this->_helper->layout()->disableLayout();
        $this->_helper->viewRenderer->setNoRender(true);
        $cache = Zend_Registry::get('cache_common');
        $ps = $cache->load('prefsis');
        $idEncontro = (int) $ps->encontro["id_encontro"];
        $sessao = Zend_Auth::getInstance()->getIdentity();
        $idPessoa = $sessao["idPessoa"];

        $model = new Application_Model_Pessoa();
        $termo = $this->_request->getParam("termo", "");

        $json = new stdClass;
        $json->results = array();

        $rs = $model->getAdapter()->fetchAll(
                "SELECT p.id_pessoa,
               p.email
         FROM pessoa p
         INNER JOIN encontro_participante ep ON p.id_pessoa = ep.id_pessoa
         WHERE p.email LIKE lower(?)
         AND p.id_pessoa <> ?
         AND ep.id_encontro = ?
         AND ep.id_caravana IS NULL
         AND ep.validado = true ", array("{$termo}%", $idPessoa, $idEncontro));
        $json->size = count($rs);
        foreach ($rs as $value) {
            $obj = new stdClass;
            $obj->id = "{$value['id_pessoa']}";
            $obj->text = "{$value['email']}";
            array_push($json->results, $obj);
        }

        header("Pragma: no-cache");
        header("Cache: no-cache");
        header("Cache-Control: no-cache, must-revalidate");
        header("Content-type: text/json");
        echo json_encode($json);
    }

    public function deletarParticipanteAction() {
        $this->_helper->layout()->disableLayout();
        $this->_helper->viewRenderer->setNoRender(true);

        $pessoa = $this->_getParam('pessoa', 0);
        if ($pessoa > 0) {
            $cache = Zend_Registry::get('cache_common');
            $ps = $cache->load('prefsis');
            $idEncontro = (int) $ps->encontro["id_encontro"];
            $where = array(
                $idEncontro,
                $pessoa,
            );
            $model = new Application_Model_CaravanaEncontro();
            try {
                $model->deletarParticipante($where);
                $this->_helper->flashMessenger->addMessage(
                        array('success' => _('Participant was removed from this caravan successfully.')));
            } catch (Exception $e) {
                $this->_helper->flashMessenger->addMessage(
                        array('danger' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
                            . $e->getMessage()));
            }
        } else {
            $this->_helper->flashMessenger->addMessage(
                    array('warning' => _('No participant was selected.')));
        }
        $this->_helper->redirector->goToRoute(array('controller' => 'caravana',
            'action' => 'participantes'), 'default', true);
    }

    public function sairAction() {
        $this->_helper->layout()->disableLayout();
        $this->_helper->viewRenderer->setNoRender(true);

        $sessao = Zend_Auth::getInstance()->getIdentity();
        $cache = Zend_Registry::get('cache_common');
        $ps = $cache->load('prefsis');
        $idEncontro = (int) $ps->encontro["id_encontro"];
        $model = new Application_Model_Participante();
        try {
            $model->sairDaCaravana(array($idEncontro, $sessao["idPessoa"]));
            $this->_helper->flashMessenger->addMessage(
                    array('success' => _('Participant was removed from this caravan successfully.')));
        } catch (Exception $e) {
            $this->_helper->flashMessenger->addMessage(
                    array('danger' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
                        . $e->getMessage()));
        }
        $this->_helper->redirector->goToRoute(array('controller' => 'caravana',
            'action' => 'index'), null, true);
    }

    public function criarAction() {
        $data = $this->getRequest()->getPost();
        if (isset($data['cancelar'])) {
            return $this->_helper->redirector->goToRoute(array(
                        'controller' => 'caravana',
                        'action' => 'index'
                            ), null, true);
        }

        $this->_helper->viewRenderer->setRender('salvar');
        $sessao = Zend_Auth::getInstance()->getIdentity();
        $cache = Zend_Registry::get('cache_common');
        $ps = $cache->load('prefsis');
        $idEncontro = (int) $ps->encontro["id_encontro"];
        $idPessoa = $sessao["idPessoa"];

        $caravana = new Application_Model_Caravana();

        if ($caravana->verificaCaravana($idPessoa, $idEncontro)) { // previne que o mesmo usuário crie 2 caravanas
            return $this->_helper->redirector->goToRoute(array(
                        'controller' => 'caravana',
                        'action' => 'editar'), null, true);
        }

        $form = new Application_Form_Caravana();
        $form->setAction($this->view->url(array('controller' => 'caravana', 'action' => 'criar')));

        $this->view->form = $form;
        $data = $this->getRequest()->getPost();

        if ($this->getRequest()->isPost() && $form->isValid($data)) {
            $caravana = new Application_Model_Caravana();
            $caravana_encontro = new Application_Model_CaravanaEncontro();
            $data = $form->getValues();

            $adapter = $caravana->getAdapter();
            try {
                $adapter->beginTransaction();
                $m_encontro = new Application_Model_Encontro();
                $data['criador'] = $idPessoa;

                $data2['id_encontro'] = $m_encontro->getEncontroAtual();
                $data2['responsavel'] = $idPessoa;
                $data2['id_caravana'] = $caravana->insert($data);

                $caravana_encontro->insert($data2);
                $adapter->commit();
                return $this->_helper->redirector->goToRoute(array(
                            'controller' => 'caravana',
                            'action' => 'index'), null, true);
            } catch (Zend_Db_Exception $ex) {
                $adapter->rollBack();
                // 23505 UNIQUE VIOLATION
                if ($ex->getCode() == 23505) {
                    $this->_helper->flashMessenger->addMessage(
                            array('danger' => _('A caravan with this description already exists.')));
                } else {
                    $this->_helper->flashMessenger->addMessage(
                            array('danger' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
                                . $ex->getMessage()));
                }
            }
        }

        $this->view->title = _('Create Caravan');
    }

    /**
     * TODO: criar um método só para criar e editar!
     * @return type
     */
    public function editarAction() {
        $data = $this->getRequest()->getPost();
        if (isset($data['cancelar'])) {
            return $this->_helper->redirector->goToRoute(array(
                        'controller' => 'caravana',
                        'action' => 'index'), null, true);
        }

        $this->_helper->viewRenderer->setRender('salvar');
        $sessao = Zend_Auth::getInstance()->getIdentity();
        $cache = Zend_Registry::get('cache_common');
        $ps = $cache->load('prefsis');
        $idEncontro = (int) $ps->encontro["id_encontro"];
        $idPessoa = $sessao["idPessoa"];

        $form = new Application_Form_Caravana();
        $form->setAction($this->view->url(array('controller' => 'caravana', 'action' => 'editar')));
        $this->view->form = $form;

        $caravana = new Application_Model_Caravana();
        $caravana_encontro = new Application_Model_CaravanaEncontro();

        $select = $caravana_encontro->select();
        $rows = $caravana_encontro->fetchAll($select->where('responsavel = ?', $idPessoa)->where('id_encontro = ?', $idEncontro));
        if (count($rows) == 0) {
            return $this->_helper->redirector->goToRoute(array(
                        'controller' => 'caravana',
                        'action' => 'index'), null, true);
        }
        $row = $rows[0];

        $select = $caravana->select();
        $dados_caravana = $caravana->find($row['id_caravana']);

        $dados_caravana = $dados_caravana[0];
        $form->populate($dados_caravana->toArray());

        if ($this->getRequest()->isPost() && $form->isValid($data)) {

            $data = $form->getValues();
            $where = $caravana->getAdapter()->quoteInto('id_caravana = ?', $dados_caravana['id_caravana']);

            try {
                $caravana->update($data, $where);
                return $this->_helper->redirector->goToRoute(array(
                            'controller' => 'caravana',
                            'action' => 'index'), null, true);
            } catch (Zend_Db_Exception $ex) {
                // 23505 UNIQUE VIOLATION
                if ($ex->getCode() == 23505) {
                    $this->_helper->flashMessenger->addMessage(
                            array('danger' => _('A caravan with this description already exists.')));
                } else {
                    $this->_helper->flashMessenger->addMessage(
                            array('danger' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
                                . $ex->getMessage()));
                }
            }
        }

        $this->view->title = _('Edit Caravan');
    }
}
