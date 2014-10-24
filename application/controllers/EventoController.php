<?php

class EventoController extends Zend_Controller_Action {

    public function init() {
        $sessao = Zend_Auth::getInstance()->getIdentity();
        $this->view->menu = new Sige_Desktop_Menu($this->view, 'home', $sessao['administrador']);
        $this->_helper->layout->setLayout('twbs3');
    }

    private function autenticacao($isAjax = false) {
        if (!Zend_Auth::getInstance()->hasIdentity()) {
            $session = new Zend_Session_Namespace();
            $session->setExpirationSeconds(60 * 60 * 1); // 1 minuto
            $session->url = $_SERVER['REQUEST_URI'];
            if ($isAjax) {
                $json = new stdClass;
                $json->erro = _("Permission denied.");
                header("Pragma: no-cache");
                header("Cache: no-cache");
                header("Cache-Control: no-cache, must-revalidate");
                header("Content-type: text/json");
                echo json_encode($json);
                return false;
            } else {
                return $this->_helper->redirector->goToRoute(array(), 'login', true);
            }
        }
        return true;
    }

    /**
     * Mapeada como
     *    /submissao
     */
    public function indexAction() {
        $this->autenticacao();
        $this->view->menu->setAtivo('submission');
        $sessao = Zend_Auth::getInstance()->getIdentity();

        $idPessoa = $sessao["idPessoa"];
        $idEncontro = $sessao["idEncontro"];

        $evento = new Application_Model_Evento();
        $this->view->eventos = $evento->listarEventosParticipante($idEncontro, $idPessoa);
    }

    public function ajaxBuscarAction() {
        $this->_helper->layout()->disableLayout();
        $this->_helper->viewRenderer->setNoRender(true);
        if (!$this->autenticacao(true)) {
            return;
        }

        $sessao = Zend_Auth::getInstance()->getIdentity();
        $idPessoa = $sessao["idPessoa"];
        $idEncontro = $sessao["idEncontro"];

        $eventos = new Application_Model_Evento();
        $data = array(
            $idEncontro,
            $idPessoa,
            $idPessoa,
            $this->_request->getParam("data"),
            intval($this->_request->getParam("id_tipo_evento")),
            $this->_request->getParam("termo")
        );
        $rs = $eventos->buscaEventos($data);

        $json = new stdClass;
        $json->size = count($rs);
        $json->itens = array();

        foreach ($rs as $value) {
            $descricao = $value['nome_evento'];
            if (!empty($value['descricao'])) {
                $descricao = "{$descricao} ({$value['descricao']})";
            }

            $json->itens[] = array(
                "{$value['nome_tipo_evento']}",
                "{$descricao}",
                "{$value['data']}",
                "{$value['h_inicio']} - {$value['h_fim']}",
                "<a id=\"{$value['evento']}\" class=\"marcar no-bottom\">
                  <i class=\"icon-bookmark\"></i> " . _("Bookmark") . "</a>"
            );
        }

        header("Pragma: no-cache");
        header("Cache: no-cache");
        header("Cache-Control: no-cache, must-revalidate");
        header("Content-type: text/json");
        echo json_encode($json);
    }

    public function ajaxInteresseAction() {
        $this->_helper->layout()->disableLayout();
        $this->_helper->viewRenderer->setNoRender(true);
        if (!$this->autenticacao(true)) {
            return;
        }

        $sessao = Zend_Auth::getInstance()->getIdentity();
        $idPessoa = $sessao["idPessoa"];

        $json = new stdClass;
        try {
            $eventoDemanda = new Application_Model_EventoDemanda();
            $data = array(
                'evento' => intval($this->_request->getParam("id")),
                'id_pessoa' => $idPessoa
            );
            $eventoDemanda->insert($data);
            $json->ok = true;
        } catch (Zend_Db_Exception $ex) {
            $json->ok = false;
            $json->erro = _("An unexpected error ocurred while bookmarking the event.<br/> Details:&nbsp;")
                    . $ex->getMessage();
        }
        header("Pragma: no-cache");
        header("Cache: no-cahce");
        header("Cache-Control: no-cache, must-revalidate");
        header("Content-type: text/json");
        echo json_encode($json);
    }

    public function submeterAction() {
        $this->autenticacao();
        $this->_helper->viewRenderer->setRender('salvar');
        $this->view->menu->setAtivo('submission');

        $sessao = Zend_Auth::getInstance()->getIdentity();
        $id_pessoa = $sessao["idPessoa"];
        $id_encontro = $sessao["idEncontro"];
        $admin = $sessao["administrador"]; // boolean

        $encontro = new Application_Model_Encontro();
        $rs = $encontro->isPeriodoSubmissao($id_encontro);
        if ($rs['liberar_submissao'] == null and ! $admin) {
            $notice = sprintf(_("The submission period goes from %s to %s."), $rs['periodo_submissao_inicio'], $rs['periodo_submissao_fim']);
            $this->_helper->flashMessenger->addMessage(
                    array('notice' => $notice));
            return $this->_helper->redirector->goToRoute(array(
                        'controller' => 'evento'), 'default', true);
        }

        $data = $this->getRequest()->getPost();
        $form = new Application_Form_Evento();
        $this->view->form = $form;

        if ($this->getRequest()->isPost() && $form->isValid($data)) {
            $evento = new Application_Model_Evento();
            $data = $form->getValues();
            try {
                $data['id_encontro'] = $id_encontro;
                $data['responsavel'] = $id_pessoa;
                $evento->insert($data);

                $this->_helper->flashMessenger->addMessage(
                        array('success' => _('Paper was submitted. Wait for a contact by e-mail.')));
                return $this->_helper->redirector->goToRoute(array(
                            'controller' => 'evento'
                                ), null, true);
            } catch (Zend_Db_Exception $ex) {
                $this->_helper->flashMessenger->addMessage(
                        array('error' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
                            . $ex->getMessage()));
            }
        }
    }

    public function editarAction() {
        $this->autenticacao();
        $this->_helper->viewRenderer->setRender('salvar');
        $this->view->menu->setAtivo('submission');

        $sessao = Zend_Auth::getInstance()->getIdentity();
        $id_encontro = $sessao["idEncontro"];
        $admin = $sessao["administrador"]; // boolean
        $idPessoa = $sessao["idPessoa"];
        $idEvento = $this->_request->getParam('id', 0);

        if (isset($data['cancelar'])) {
            return $this->redirecionar($admin, $idEvento);
        }

        $encontro = new Application_Model_Encontro();
        $rs = $encontro->isPeriodoSubmissao($id_encontro);
        if ($rs['liberar_submissao'] == null and ! $admin) {
            $notice = sprintf(_("The submission period goes from %s to %s."), $rs['periodo_submissao_inicio'], $rs['periodo_submissao_fim']);
            $this->_helper->flashMessenger->addMessage(
                    array('notice' => $notice));
            return $this->_helper->redirector->goToRoute(array(
                        'controller' => 'evento'), 'default', true);
        }

        $data = $this->getRequest()->getPost();
        $form = new Application_Form_Evento();
        $this->view->form = $form;

        $evento = new Application_Model_Evento();
        $evento_realizacao = new Application_Model_EventoRealizacao();

        $select = $evento->select();

        /* lista de horários */
        $this->view->realizacao = $evento_realizacao->listarHorariosPorEvento($idEvento);

        if ($this->getRequest()->isPost()) {
            if ($form->isValid($data)) {
                $data = $form->getValues();
                $select = $evento->getAdapter()->quoteInto('id_evento = ?', $idEvento);
                try {
                    if ($idPessoa != $data['responsavel'] and ! $admin) {
                        $this->_helper->flashMessenger->addMessage(
                                array('error' => _('Only the author can edit the Event.')));
                        return $this->redirecionar();
                    } else {
                        $data['id_encontro'] = $id_encontro;
                        $data['responsavel'] = $idPessoa;
                        $evento->update($data, $select);
                        $this->_helper->flashMessenger->addMessage(
                                array('success' => _('Event successfully updated.')));
                        return $this->redirecionar($admin, $idEvento);
                    }
                } catch (Zend_Db_Exception $ex) {
                    $this->_helper->flashMessenger->addMessage(
                            array('error' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
                                . $ex->getMessage()));
                }
            } else {
                $form->populate($data);
            }
        } else {
            $row = $evento->fetchRow($select->where('id_evento = ?', $idEvento));
            if (!is_null($row)) {
                $array = $row->toArray();
                // verificar se ao editar o id_pessoa da sessão é o mesmo do evento
                // e se não é admin, sendo admin é permitido editar
                if ($idPessoa != $array['responsavel'] and ! $admin) {
                    $this->_helper->flashMessenger->addMessage(
                            array('error' => _('Only the author can edit the Event.')));
                    return $this->redirecionar();
                } else {
                    $form->populate($row->toArray());
                }
            } else {
                $this->_helper->flashMessenger->addMessage(
                        array('error' => _('Event not found.')));
                return $this->redirecionar($admin, $idEvento);
            }
        }
    }

    public function programacaoAction() {
        $this->view->menu->setAtivo('schedule');
        $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'staging');
        $idEncontro = $config->encontro->codigo;
        $model = new Application_Model_Evento();
        $this->view->lista = $model->programacao($idEncontro);
    }

    public function interesseAction() {
        $this->autenticacao();
        $sessao = Zend_Auth::getInstance()->getIdentity();
        $idEncontro = $sessao["idEncontro"];
        $idPessoa = $sessao["idPessoa"];

        $eventos = new Application_Model_Evento();
        // usada para mostrar dias que possuem eventos
        $this->view->diasEncontro = $eventos->listarDiasDoEncontro($idEncontro);
        $this->view->idEncontro = $idEncontro;
        $this->view->idPessoa = $idPessoa;

        $tipoEventos = new Application_Model_TipoEvento();
        $this->view->tipoEvento = $tipoEventos->fetchAll();

        $model = new Application_Model_EventoRealizacao();
        $eventoRealizacao = $model->fetchAll();

        $this->view->eventosTabela = array();
        foreach ($eventoRealizacao as $item) {

            $eventoItem = $item->findDependentRowset('Application_Model_Evento')->current();
            $tipoItem = $eventoItem->findDependentRowset('Application_Model_TipoEvento')->current();

            $this->view->eventosTabela[] = array_merge($item->toArray(), $eventoItem->toArray(), $tipoItem->toArray());
        }

        $form = new Application_Form_PessoaAddEvento();
        $this->view->form = $form;

        $form->criarFormulario($this->view->eventosTabela);

        $data = $this->getRequest()->getPost();

        if ($this->getRequest()->isPost() && $form->isValid($data)) {
            $data = $form->getValues();
        }
    }

    public function ajaxDesfazerInteresseAction() {
        $this->_helper->layout()->disableLayout();
        $this->_helper->viewRenderer->setNoRender(true);
        $this->autenticacao();

        $json = new stdClass;
        if ($this->getRequest()->isPost()) {
            $sessao = Zend_Auth::getInstance()->getIdentity();
            $idPessoa = $sessao["idPessoa"];
            $model = new Application_Model_EventoDemanda();
            $id = (int) $this->getRequest()->getPost('id_evento');
            try {
                $where = array(
                    "evento = ?" => $id,
                    "id_pessoa = ?" => $idPessoa);
                $model->delete($where);
                $json->ok = true;
            } catch (Exception $e) {
                $json->ok = false;
                $json->error = _('An unexpected error ocurred.<br/> Details:&nbsp;') . $e->getMessage();
            }
        } else {
            $json->ok = false;
            $json->error = _("The request can not be completed.");
        }

        header("Pragma: no-cache");
        header("Cache: no-cache");
        header("Cache-Control: no-cache, must-revalidate");
        header("Content-type: text/json");
        echo json_encode($json);
    }

    /**
     * @deprecated use ajaxDesfazerInteresseAction
     */
    public function desfazerInteresseAction() {
        $this->autenticacao();
        $sessao = Zend_Auth::getInstance()->getIdentity();
        $idPessoa = $sessao["idPessoa"];

        $model = new Application_Model_EventoDemanda();

        if ($this->getRequest()->isPost()) {
            $del = $this->getRequest()->getPost('del');
            $id = (int) $this->getRequest()->getPost('id');

            if (!isset($id) || $id == 0) {
                $this->_helper->flashMessenger->addMessage(
                        array('error' => _('Event not found.')));
                $this->_helper->redirector->goToRoute(array(
                    'controller' => 'participante',
                    'action' => 'index'), 'default', true);
            } else if ($del == "confimar") {

                try {
                    $where = array(
                        "evento = ?" => $id,
                        "id_pessoa = ?" => $idPessoa);
                    $model->delete($where);
                    $this->_helper->flashMessenger->addMessage(
                            array('success' => _('Event was successfully removed from the Bookmarks.')));
                } catch (Exception $e) {
                    $this->_helper->flashMessenger->addMessage(
                            array('error' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
                                . $e->getMessage()));
                }
            }
            $this->_helper->redirector->goToRoute(array(
                'controller' => 'participante',
                'action' => 'index'), 'default', true);
        } else {
            $id = $this->_getParam('id', 0);
            if ($id == 0) {
                $this->_helper->flashMessenger->addMessage(
                        array('error' => _('Event not found.')));
                $this->_helper->redirector->goToRoute(array(
                    'controller' => 'participante',
                    'action' => 'index'), 'default', true);
            } else {
                $idEncontro = $sessao["idEncontro"];
                $where = array($idEncontro, $idPessoa, $id);
                try {
                    $this->view->evento = $model->lerEvento($where);
                } catch (Exception $e) {
                    $this->_helper->flashMessenger->addMessage(
                            array('error' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
                                . $e->getMessage()));
                    $this->_helper->redirector->goToRoute(array(
                        'controller' => 'participante',
                        'action' => 'index'), 'default', true);
                }
            }
        }
    }

    /**
     * Mapeada como
     *    /e/:id
     */
    public function verAction() {
        $this->view->menu->setAtivo('schedule');
        try {
            $idEvento = $this->_request->getParam('id', 0);
            $evento = new Application_Model_Evento();
            $data = $evento->buscaEventoPessoa($idEvento);
            if (empty($data)) {
                $this->_helper->flashMessenger->addMessage(
                        array('notice' => _('Event not found.')));
            } else {
                $this->view->evento = $data[0];
                $this->view->outros = $evento->buscarOutrosPalestrantes($idEvento);

                $modelTags = new Application_Model_EventoTags();
                $this->view->tags = $modelTags->listarPorEvento($idEvento);
            }
        } catch (Exception $e) {
            $this->_helper->flashMessenger->addMessage(
                    array('error' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
                        . $e->getMessage()));
        }
    }

    public function outrosPalestrantesAction() {
        $this->autenticacao();
        $this->view->menu->setAtivo('submission');

        $evento = new Application_Model_Evento();
        $idEvento = $this->_request->getParam('id', 0);

        $cancelar = $this->getRequest()->getPost('cancelar');
        if (isset($cancelar)) {
            return $this->_helper->redirector->goToRoute(array(), 'submissao', true);
        }

        $submit = $this->getRequest()->getPost('submit');
        if ($this->getRequest()->isPost() && isset($submit)) {

            $array_id_pessoas = explode(",", $this->getRequest()->getPost('array_id_pessoas'));
            $count_array_id_pessoas = count($array_id_pessoas);
            if (empty($array_id_pessoas[0])) {
                $this->_helper->flashMessenger->addMessage(
                        array('notice' => _('No speakers selected.')));
            } else {
                $numParticipantes = 0;
                try {
                    foreach ($array_id_pessoas as $value) {
                        $value = intval($value);
                        $numParticipantes += $evento->adicionarPalestranteEvento($idEvento, $value);
                    }

                    $success = sprintf(
                            ngettext("One speaker added to this event successfully.", "%d speakers added to this event successfully.", $numParticipantes), $numParticipantes);
                    $this->_helper->flashMessenger->addMessage(
                            array('success' => $success));
                } catch (Zend_Db_Exception $ex) {
                    if ($ex->getCode() == 23505) {
                        $this->_helper->flashMessenger->addMessage(
                                array('error' => ngettext('Speaker already exists in this event.', 'One or more speakers exists in this event', $count_array_id_pessoas)));
                    } else {
                        $this->_helper->flashMessenger->addMessage(
                                array('error' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
                                    . $ex->getMessage()));
                    }
                }
            }
        }

        // listar palestrantes
        try {
            $data = $evento->buscaEventoPessoa($idEvento);
            if (empty($data)) {
                $this->_helper->flashMessenger->addMessage(
                        array('notice' => _('Event not found.')));
            } else {
                $this->view->evento = $data[0];

                // checa as permissão do usuário, para editar somente seus eventos
                $sessao = Zend_Auth::getInstance()->getIdentity();
                if ($this->view->evento['id_pessoa'] != $sessao['idPessoa']) {
                    $this->_helper->flashMessenger->addMessage(
                            array('notice' => _("You don't have permission to edit this event.")));
                    return $this->_helper->redirector->goToRoute(array(), 'submissao', true);
                }
            }

            $palestrantes = $evento->getAdapter()->fetchAll("SELECT p.id_pessoa, p.nome, p.email
                FROM evento_palestrante ep
                INNER JOIN pessoa p ON ep.id_pessoa = p.id_pessoa
                WHERE ep.id_evento = ?", array($idEvento));
            $this->view->palestrantes = $palestrantes;
        } catch (Exception $e) {
            $this->_helper->flashMessenger->addMessage(
                    array('error' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
                        . $e->getMessage()));
        }
    }

    public function ajaxBuscarParticipanteAction() {
        $this->_helper->layout()->disableLayout();
        $this->_helper->viewRenderer->setNoRender(true);
        if (!$this->autenticacao(true)) {
            return;
        }

        $sessao = Zend_Auth::getInstance()->getIdentity();
        $idPessoa = $sessao["idPessoa"];
        $idEncontro = $sessao["idEncontro"];

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

    public function deletarPalestranteAction() {
        $this->autenticacao();
        $this->_helper->layout()->disableLayout();
        $this->_helper->viewRenderer->setNoRender(true);

        $pessoa = (int) $this->_getParam('pessoa', 0);
        $evento = (int) $this->_getParam('evento', 0);
        if ($pessoa > 0 and $evento > 0) {
            $model = new Application_Model_Evento();
            try {
                $model->getAdapter()->delete("evento_palestrante", "id_pessoa = {$pessoa}
                    AND id_evento = {$evento}");
                $this->_helper->flashMessenger->addMessage(
                        array('success' => _('Speaker was successfuly removed from the event.')));
            } catch (Exception $e) {
                $this->_helper->flashMessenger->addMessage(
                        array('error' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
                            . $e->getMessage()));
            }
        } else {
            $this->_helper->flashMessenger->addMessage(
                    array('notice' => _('No speaker was selected.')));
        }
        $this->_helper->redirector->goToRoute(array('controller' => 'evento',
            'action' => 'outros-palestrantes', 'id' => $evento), 'default', true);
    }

    public function tagsAction() {
        $this->autenticacao();
        $this->view->menu->setAtivo('submission');
        $model = new Application_Model_EventoTags();
        $idEvento = $this->_getParam('id', 0);
        $this->view->tags = $model->listarPorEvento($idEvento);

        $evento = new Application_Model_Evento();
        $data = $evento->buscaEventoPessoa($idEvento);
        if (empty($data)) {
            $this->_helper->flashMessenger->addMessage(
                    array('notice' => _('Event not found.')));
            return $this->_helper->redirector->goToRoute(array(), 'submissao', true);
        } else {
            $this->view->evento = $data[0];
        }
    }

    public function ajaxBuscarTagsAction() {
        $this->_helper->layout()->disableLayout();
        $this->_helper->viewRenderer->setNoRender(true);
        if (!$this->autenticacao(true)) {
            return;
        }

        $model = new Application_Model_EventoTags();
        $termo = $this->_getParam('termo', "");
        $rs = $model->listarTags($termo);

        $json = new stdClass;
        $json->itens = array();
        foreach ($rs as $value) {
            $obj = new stdClass;
            $obj->id = "{$value['id']}";
            $obj->text = "{$value['descricao']}";
            array_push($json->itens, $obj);
        }

        header("Pragma: no-cache");
        header("Cache: no-cahce");
        header("Cache-Control: no-cache, must-revalidate");
        header("Content-type: text/json");
        echo json_encode($json);
    }

    public function ajaxSalvarTagAction() {
        $this->_helper->layout()->disableLayout();
        $this->_helper->viewRenderer->setNoRender(true);
        if (!$this->autenticacao(true)) {
            return;
        }

        $model = new Application_Model_EventoTags();
        $json = new stdClass;
        try {
            $id_tag = $this->_getParam('id', 0);
            $id_evento = $this->_getParam('id_evento', 0);
            $id = $model->insert(array('id_tag' => $id_tag, 'id_evento' => $id_evento));
            if ($id > 0) {
                $json->ok = true;
                $json->msg = _("Tag added successfully.");
            } else {
                $json->ok = false;
                $json->erro = _("An unexpected error ocurred while saving <b>tag</b>.");
            }
        } catch (Exception $e) {
            if ($e->getCode() == 23505) {
                $json->erro = _("Tag already added.");
            } else {
                $json->erro = _("An unexpected error ocurred while saving <b>tag</b>. Details:&nbsp;")
                        . $e->getMessage();
            }
            $json->ok = false;
        }

        header("Pragma: no-cache");
        header("Cache: no-cahce");
        header("Cache-Control: no-cache, must-revalidate");
        header("Content-type: text/json");
        echo json_encode($json);
    }

    public function ajaxCriarTagAction() {
        $this->_helper->layout()->disableLayout();
        $this->_helper->viewRenderer->setNoRender(true);
        if (!$this->autenticacao(true)) {
            return;
        }

        $model = new Application_Model_EventoTags();
        $json = new stdClass;
        try {
            $descricao = $this->_getParam('descricao', "");
            $model->getAdapter()->insert("tags", array('descricao' => $descricao));
            $json->ok = true;
            $json->id = $model->getAdapter()->lastSequenceId("tags_id_seq");
        } catch (Exception $e) {
            if ($e->getCode() == 23505) {
                $json->erro = _("Tag already exists.");
            } else {
                $json->erro = _("An unexpected error ocurred while saving <b>tag</b>. Details:&nbsp;")
                        . $e->getMessage();
            }
            $json->ok = false;
        }

        header("Pragma: no-cache");
        header("Cache: no-cahce");
        header("Cache-Control: no-cache, must-revalidate");
        header("Content-type: text/json");
        echo json_encode($json);
    }

    public function ajaxDeletarTagAction() {
        $this->_helper->layout()->disableLayout();
        $this->_helper->viewRenderer->setNoRender(true);
        if (!$this->autenticacao(true)) {
            return;
        }

        $model = new Application_Model_EventoTags();
        $json = new stdClass;
        try {
            $id = $this->_getParam('id', 0);
            $id_evento = $this->_getParam('id_evento', 0);
            $where = $model->getAdapter()->quoteInto("id_tag = ?", $id);
            $where .= $model->getAdapter()->quoteInto("AND id_evento = ?", $id_evento);
            $affected = $model->delete($where);
            if ($affected > 0) {
                $json->ok = true;
                $json->msg = _("Tag removed successfully.");
            } else {
                $json->erro = _("Tag not found.");
                $json->ok = false;
            }
        } catch (Exception $e) {
            $json->erro = _("An unexpected error ocurred while saving <b>tag</b>. Details:&nbsp;")
                    . $e->getMessage();
            $json->ok = false;
        }

        header("Pragma: no-cache");
        header("Cache: no-cahce");
        header("Cache-Control: no-cache, must-revalidate");
        header("Content-type: text/json");
        echo json_encode($json);
    }

    private function redirecionar($admin = false, $id = 0) {
        if ($admin) {
            $this->_helper->redirector->goToRoute(array(
                'module' => 'admin',
                'controller' => 'evento',
                'action' => 'detalhes',
                'id' => $id), 'default', true);
        } else {
            $this->_helper->redirector->goToRoute(array(), 'submissao', true);
        }
    }

}
