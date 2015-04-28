<?php

class EventoController extends Zend_Controller_Action {

    public function init() {
        $sessao = Zend_Auth::getInstance()->getIdentity();
        $this->view->menu = new Sige_Desktop_Menu($this->view, 'home', $sessao['administrador']);
        $this->_helper->layout->setLayout('twbs3/layout');

        $this->_helper->getHelper('AjaxContext')
            ->addActionContext('ajax-buscar', 'json')
            ->addActionContext('ajax-interesse', 'json')
            ->addActionContext('ajax-programacao', 'json')
            ->addActionContext('ajax-programacao-timeline', 'json')
            ->addActionContext('ajax-buscar-tags', 'json')
            ->addActionContext('ajax-salvar-tag', 'json')
            ->addActionContext('ajax-criar-tag', 'json')
            ->addActionContext('ajax-deletar-tag', 'json')
            ->addActionContext('ajax-desfazer-interesse', 'json')
            ->addActionContext('ajax-buscar-participante', 'json')
            ->initContext();
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
        $cache = Zend_Registry::get('cache_common');
        $ps = $cache->load('prefsis');
        $idEncontro = (int) $ps->encontro["id_encontro"];

        $idPessoa = $sessao["idPessoa"];

        $model_evento = new Application_Model_Evento();
        $this->view->meusEventos = $model_evento->listarEventosParticipante($idEncontro, $idPessoa);
        //$model_artigo = new Application_Model_Artigo();
        //$this->view->meusArtigos = $model_artigo->listarArtigosParticipante($idEncontro, $idPessoa);
    }

    public function ajaxBuscarAction() {
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

        $this->view->size = count($rs);
        $this->view->itens = array();

        foreach ($rs as $value) {
            $descricao = $value['nome_evento'];
            if (!empty($value['descricao'])) {
                $descricao = "{$descricao} ({$value['descricao']})";
            }

            // TODO: montar html no cliente, enviar apenas os dados.
            $this->view->itens[] = array(
                "<span class=\"label label-primary\">{$value['nome_tipo_evento']}</span> {$descricao}",
                "{$value['data']}",
                "{$value['h_inicio']} - {$value['h_fim']}",
                "<a id=\"{$value['evento']}\" class=\"marcar btn btn-default\">
                  <i class=\"fa fa-bookmark\"></i> " . _("Bookmark") . "</a>"
            );
        }
    }

    public function ajaxInteresseAction() {
        if (!$this->autenticacao(true)) {
            return;
        }

        $sessao = Zend_Auth::getInstance()->getIdentity();
        $idPessoa = $sessao["idPessoa"];

        try {
            $eventoDemanda = new Application_Model_EventoDemanda();
            $data = array(
                'evento' => intval($this->_request->getParam("id")),
                'id_pessoa' => $idPessoa
            );
            $eventoDemanda->insert($data);
            $this->view->ok = true;
        } catch (Zend_Db_Exception $ex) {
            $this->view->ok = false;
            $this->view->erro = _("An unexpected error ocurred while bookmarking the event.<br/> Details:&nbsp;")
                    . $ex->getMessage();
        }
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
            $warning = sprintf(_("The submission period goes from %s to %s."), $rs['periodo_submissao_inicio'], $rs['periodo_submissao_fim']);
            $this->_helper->flashMessenger->addMessage(
                    array('warning' => $warning));
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
                        array('danger' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
                            . $ex->getMessage()));
            }
        }
    }

    public function enviarArtigoAction() {
        $this->autenticacao();
        $this->view->menu->setAtivo('submission');

        $sessao = Zend_Auth::getInstance()->getIdentity();
        $id_pessoa = intval($sessao["idPessoa"]);
        $cache = Zend_Registry::get('cache_common');
        $ps = $cache->load('prefsis');
        $id_encontro = (int) $ps->encontro["id_encontro"];
        $admin = $sessao["administrador"]; // boolean

        $encontro = new Application_Model_Encontro();
        $rs = $encontro->isPeriodoSubmissao($id_encontro);
        if ($rs['liberar_submissao'] == null and ! $admin) {
            $warning = sprintf(_("The submission period goes from %s to %s."), $rs['periodo_submissao_inicio'], $rs['periodo_submissao_fim']);
            $this->_helper->flashMessenger->addMessage(
                    array('warning' => $warning));
            return $this->_helper->redirector->goToRoute(array(
                        'controller' => 'evento'), 'default', true);
        }

        $form = new Application_Form_SubmissaoArtigo();
        if ($this->getRequest()->isPost()) {
            $formData = $this->getRequest()->getPost();
            if (isset($formData['cancelar'])) {
                return $this->_helper->redirector->goToRoute(array(), 'submissao', true);
            }
            if ($form->isValid($formData)) {
                $uploadedData = $form->getValues();
                try {
                    $uploadedData['id_encontro'] = $id_encontro;
                    $uploadedData['responsavel'] = $id_pessoa;
                    $uploadedData["id_tipo_evento"] = Application_Model_TipoEvento::ARTIGO;
                    $titulo = $uploadedData['nome_evento'];

                    // Salvando PDF na tabela artigo
                    $artigos_ids = $this->_artigoSalvaPdf(
                            $form->arquivo, $id_pessoa, $id_encontro, $titulo);

                    // Enviando artigo por email
                    $this->_artigoCriarEmail();
                    // Salvando o evento
                    $evento = new Application_Model_Evento();
                    $uploadedData["id_artigo"] = array_pop($artigos_ids);
                    unset($uploadedData["arquivo"]);
                    $evento->insert($uploadedData);
                    $this->_helper->flashMessenger->addMessage(
                            array('success' => _('Paper sent. Wait for contact by e-mail.')));
                    $this->_helper->redirector->goToRoute(array(
                        'controller' => 'evento'), null, true);
                } catch (Exception $ex) {
                    $this->_helper->flashMessenger->addMessage(
                            array('error' => _('An unexpected error ocurred.<br/> Details:&nbsp;') . $ex->getMessage()));
                }
            } else {
                $form->populate($formData);
            }
        }
        $this->view->form = $form;
    }

    public function editarAction() {
        $this->autenticacao();
        $this->_helper->viewRenderer->setRender('salvar');
        $this->view->menu->setAtivo('submission');

        $sessao = Zend_Auth::getInstance()->getIdentity();
        $cache = Zend_Registry::get('cache_common');
        $ps = $cache->load('prefsis');
        $id_encontro = (int) $ps->encontro["id_encontro"];

        $admin = $sessao["administrador"]; // boolean
        $idPessoa = $sessao["idPessoa"];
        $idEvento = $this->_request->getParam('id', 0);

        if (isset($data['cancelar'])) {
            return $this->redirecionar($admin, $idEvento);
        }

        $encontro = new Application_Model_Encontro();
        $rs = $encontro->isPeriodoSubmissao($id_encontro);
        if ($rs['liberar_submissao'] == null and ! $admin) {
            $warning = sprintf(_("The submission period goes from %s to %s."), $rs['periodo_submissao_inicio'], $rs['periodo_submissao_fim']);
            $this->_helper->flashMessenger->addMessage(
                    array('warning' => $warning));
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
                                array('danger' => _('Only the author can edit the Event.')));
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
                            array('danger' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
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
                            array('danger' => _('Only the author can edit the Event.')));
                    return $this->redirecionar();
                } else {
                    $form->populate($row->toArray());
                }
            } else {
                $this->_helper->flashMessenger->addMessage(
                        array('danger' => _('Event not found.')));
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

    public function programacaoTvAction() {
        $this->_helper->layout->setLayout('full-page');
    }

    public function ajaxProgramacaoAction() {
        $cache = Zend_Registry::get('cache_common');
        $ps = $cache->load('prefsis');
        $id_encontro = (int) $ps->encontro["id_encontro"];

        $evento_model = new Application_Model_Evento();
        $this->view->results = $evento_model->programacaoTv($id_encontro);
    }

    public function ajaxProgramacaoTimelineAction() {
        $cache = Zend_Registry::get('cache_common');
        $ps = $cache->load('prefsis');
        $id_encontro = (int) $ps->encontro["id_encontro"];

        $evento_model = new Application_Model_Evento();
        $this->view->results = $evento_model->programacaoTimeline($id_encontro);
    }

    public function timelineAction() {
        $this->_helper->layout->setLayout("timeline");
    }

    public function timelineStaticAction() {
        $this->_helper->layout->setLayout("timeline");
    }

    public function interesseAction() {
        $this->autenticacao();
        $sessao = Zend_Auth::getInstance()->getIdentity();

        $cache = Zend_Registry::get('cache_common');
        $ps = $cache->load('prefsis');
        $idEncontro = (int) $ps->encontro["id_encontro"];
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

        // TODO: refezer este trecho usando join ao invés de findDependentRowset
        $this->view->eventosTabela = array();
        foreach ($eventoRealizacao as $item) {

            $eventoItem = $item->findDependentRowset('Application_Model_Evento')->current();
            $tipoItem = $eventoItem->findDependentRowset('Application_Model_TipoEvento')->current();

            $this->view->eventosTabela[] = array_merge($item->toArray(), $eventoItem->toArray(), $tipoItem->toArray());
        }
    }

    public function ajaxDesfazerInteresseAction() {
        if (!$this->autenticacao(true)) {
            return;
        }

        if ($this->getRequest()->isPost()) {
            $sessao = Zend_Auth::getInstance()->getIdentity();
            $idPessoa = $sessao["idPessoa"];
            $model = new Application_Model_EventoDemanda();
            $id = (int) $this->getRequest()->getPost('id_evento');
            try {
                $where = array(
                    "evento = ?" => $id,
                    "id_pessoa = ?" => $idPessoa
                );
                $model->delete($where);
                $this->view->ok = true;
                $this->view->msg = _('Bookmark successfully removed.');
            } catch (Exception $e) {
                $this->view->ok = false;
                $this->view->error = _('An unexpected error ocurred.<br/> Details:&nbsp;') . $e->getMessage();
            }
        } else {
            $this->view->ok = false;
            $this->view->error = _("The request can not be completed.");
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
                        array('warning' => _('Event not found.')));
            } else {
                $this->view->evento = $data;
                $this->view->outros = $evento->buscarOutrosPalestrantes($idEvento);

                $modelTags = new Application_Model_EventoTags();
                $this->view->tags = $modelTags->listarPorEvento($idEvento);
            }
        } catch (Exception $e) {
            $this->_helper->flashMessenger->addMessage(
                    array('danger' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
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
                        array('warning' => _('No speakers selected.')));
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
                                array('danger' => ngettext('Speaker already exists in this event.', 'One or more speakers exists in this event', $count_array_id_pessoas)));
                    } else {
                        $this->_helper->flashMessenger->addMessage(
                                array('danger' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
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
                        array('warning' => _('Event not found.')));
            } else {
                $this->view->evento = $data;

                // checa as permissão do usuário, para editar somente seus eventos
                $sessao = Zend_Auth::getInstance()->getIdentity();
                if ($this->view->evento['id_pessoa'] != $sessao['idPessoa']) {
                    $this->_helper->flashMessenger->addMessage(
                            array('warning' => _("You don't have permission to edit this event.")));
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
                    array('danger' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
                        . $e->getMessage()));
        }
    }

    public function ajaxBuscarParticipanteAction() {
        if (!$this->autenticacao(true)) {
            return;
        }

        $sessao = Zend_Auth::getInstance()->getIdentity();
        $cache = Zend_Registry::get('cache_common');
        $ps = $cache->load('prefsis');
        $id_encontro = (int) $ps->encontro["id_encontro"];
        $id_pessoa = $sessao["idPessoa"];

        $termo = $this->_request->getParam("termo", "");
        try {
            $model_participante = new Application_Model_Participante();
            $rs = $model_participante->buscarParticipantePorEmail($termo, $id_pessoa, $id_encontro);
            $this->view->size = count($rs);
            $this->view->results = $rs;
        } catch (Zend_Db_Exception $e) {
            $this->view->error = _('Error on fetching results.');
        }
    }

    public function deletarArtigoAction() {
        $this->_helper->layout()->disableLayout();
        $this->_helper->viewRenderer->setNoRender(true);

        $id_artigo = $this->_getParam('artigo', 0);
        $id_evento = $this->_getParam('evento', 0);
        $model_pessoa = new Application_Model_Pessoa();
        $model_evento = new Application_Model_Evento();

        try {
            if ($id_artigo < 1 || $id_evento < 1) {
                throw new Exception("Parâmetros inválidos. Tente novamente do início ou contate o administrador.");
            }

            $this->autenticacao();
            $sessao = Zend_Auth::getInstance()->getIdentity();
            $id_pessoa_sessao = $sessao["idPessoa"];
            $id_pessoa_db = $model_evento->getResponsavel($id_evento);
            if ($id_pessoa_db != $id_pessoa_sessao && !$model_pessoa->isAdmin()) {
                throw new Exception("Você não é administrador para executar esta ação.");
            }
            $model_evento->deletarEvento($id_evento);
            $this->_helper->flashMessenger->addMessage(
                    array('success' => 'Artigo removido com sucesso.'));
        } catch (Exception $e) {
            $this->_helper->flashMessenger->addMessage(
                    array('danger' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
                        . $e->getMessage()));
        }

        $this->_helper->redirector->goToRoute(array(
            'controller' => 'evento',
            'action' => 'index',
                ), 'default', true);
    }

    public function deletarEventoAction() {
        $this->_helper->layout()->disableLayout();
        $this->_helper->viewRenderer->setNoRender(true);

        $id_evento = $this->_getParam('evento', 0);
        $model_pessoa = new Application_Model_Pessoa();
        $model_evento = new Application_Model_Evento();

        try {
            if ($id_evento < 1) {
                throw new Exception("Parâmetros inválidos. Tente novamente do início ou contate o administrador.");
            }

            $this->autenticacao();
            $sessao = Zend_Auth::getInstance()->getIdentity();
            $id_pessoa_sessao = $sessao["idPessoa"];
            $id_pessoa_db = $model_evento->getResponsavel($id_evento);
            if ($id_pessoa_db != $id_pessoa_sessao && !$model_pessoa->isAdmin()) {
                throw new Exception("Você não é administrador para executar esta ação.");
            }
            $model_evento->deletarEvento($id_evento);
            $this->_helper->flashMessenger->addMessage(
                    array('success' => 'Evento removido com sucesso.'));
        } catch (Zend_Db_Exception $ex) {
            if ($ex->getCode() == 23503) {
                $this->_helper->flashMessenger->addMessage(
                        array('info' => _("This event could not be deleted.")));
            } else {
                $this->_helper->flashMessenger->addMessage(
                        array('danger' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
                            . $ex->getMessage()));
            }
        }

        $this->_helper->redirector->goToRoute(array(
            'controller' => 'evento',
            'action' => 'index',
                ), 'default', true);
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
                        array('danger' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
                            . $e->getMessage()));
            }
        } else {
            $this->_helper->flashMessenger->addMessage(
                    array('warning' => _('No speaker was selected.')));
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
                    array('warning' => _('Event not found.')));
            return $this->_helper->redirector->goToRoute(array(), 'submissao', true);
        } else {
            $this->view->evento = $data;
        }
    }

    public function ajaxBuscarTagsAction() {
        if (!$this->autenticacao(true)) {
            return;
        }

        $model = new Application_Model_EventoTags();
        $termo = $this->_getParam('termo', "");
        $this->view->itens = $model->listarTags($termo);
    }

    public function ajaxSalvarTagAction() {
        if (!$this->autenticacao(true)) {
            return;
        }

        $model = new Application_Model_EventoTags();
        try {
            $id_tag = $this->_getParam('id', 0);
            $id_evento = $this->_getParam('id_evento', 0);
            $id = $model->insert(array('id_tag' => $id_tag, 'id_evento' => $id_evento));
            if ($id > 0) {
                $this->view->ok = true;
                $this->view->msg = _("Tag added successfully.");
            } else {
                $this->view->ok = false;
                $this->view->error = _("An unexpected error ocurred while saving <b>tag</b>.");
            }
        } catch (Exception $e) {
            if ($e->getCode() == 23505) {
                $this->view->error = _("Tag already added.");
            } else {
                $this->view->error = _("An unexpected error ocurred while saving <b>tag</b>. Details:&nbsp;")
                        . $e->getMessage();
            }
            $this->view->ok = false;
        }
    }

    public function ajaxCriarTagAction() {
        if (!$this->autenticacao(true)) {
            return;
        }

        $model = new Application_Model_EventoTags();
        try {
            $descricao = $this->_getParam('descricao', "");
            $model->getAdapter()->insert("tags", array('descricao' => $descricao));
            $this->view->ok = true;
            $this->view->id = $model->getAdapter()->lastSequenceId("tags_id_seq");
        } catch (Exception $e) {
            if ($e->getCode() == 23505) {
                $this->view->error = _("Tag already exists.");
            } else {
                $this->view->error = _("An unexpected error ocurred while saving <b>tag</b>. Details:&nbsp;")
                        . $e->getMessage();
            }
            $this->view->ok = false;
        }
    }

    public function ajaxDeletarTagAction() {
        if (!$this->autenticacao(true)) {
            return;
        }

        $model = new Application_Model_EventoTags();
        try {
            $id = $this->_getParam('id', 0);
            $id_evento = $this->_getParam('id_evento', 0);
            $where = $model->getAdapter()->quoteInto("id_tag = ?", $id);
            $where .= $model->getAdapter()->quoteInto("AND id_evento = ?", $id_evento);
            $affected = $model->delete($where);
            if ($affected > 0) {
                $this->view->ok = true;
                $this->view->msg = _("Tag removed successfully.");
            } else {
                $this->view->error = _("Tag not found.");
                $this->view->ok = false;
            }
        } catch (Exception $e) {
            $this->view->error = _("An unexpected error ocurred while saving <b>tag</b>. Details:&nbsp;")
                    . $e->getMessage();
            $this->view->ok = false;
        }
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

    public function downloadArtigoAction() {
        $this->autenticacao();
        $this->_helper->layout->disableLayout();
        $this->_helper->viewRenderer->setNoRender();

        $sessao = Zend_Auth::getInstance()->getIdentity();
        $idPessoa = $sessao["idPessoa"];
        $admin = $sessao["administrador"];

        $id_artigo = (int) $this->getRequest()->getParam("artigo", 0);
        if ($id_artigo < 1) {
            return $this->_redirecionar($admin);
        }

        $model_artigo = new Application_Model_Artigo();
        $result = $model_artigo->getArtigo($id_artigo);

        if ($result != NULL) {
            // Verifica se tem permissao
            if (!$admin && $result["responsavel"] != $idPessoa) {
                $this->_helper->flashMessenger->addMessage(
                        //array('error' => 'Este artigo não lhe pertence. Você não tem permissão para ler artigos alheios.'));
                        array('error' => _("This paper doesn't belongs to you. You don't have permission to read someone else's papers.")));
                return $this->_redirecionar();
            }

            $pdf = $result['dados'];
            header('Content-type: application/pdf');
            header('Content-Disposition: attachment; filename="' . $result['nomearquivo_original'] . '"');

            try {
                echo base64_decode($pdf);
            } catch (Zend_Pdf_Exception $e) {
                $this->_helper->flashMessenger->addMessage(
                        //array('error' => 'O arquivo não é um documento pdf válido.<br/>Detalhes: '
                        array('error' => _("The file is not a valid PDF document.<br/>Details: ")
                            . $e->getMessage()));
            }
        } else {
            $this->_helper->flashMessenger->addMessage(
                    //array('error' => 'Não foi possível carregar o Artigo.'));
                    array('error' => _("The Paper could not be loaded.")));
            return $this->_helper->redirector->goToRoute(array(
                        'module' => 'evento',
                        'controller' => 'index'), 'default', false);
        }
    }

    private function _artigoSalvaPdf($p_arquivo, $responsavel, $id_encontro, $titulo) {
        $files = $p_arquivo->getFileInfo();
        $artigos = array();
        foreach ($files as $fileInfo) {
            try {
                $source = $fileInfo['tmp_name'];
                $nome = $fileInfo['name'];
                $tamanho = $fileInfo['size'];

                $finfo = finfo_open(FILEINFO_MIME_TYPE);
                $mime = finfo_file($finfo, $source);
                if (strcmp($mime, 'application/pdf') == 0) {
                    $data = file_get_contents($source);
                    $escaped = bin2hex($data);

                    $model = new Application_Model_Artigo();
                    $id_artigo = $model->inserirDocumento($escaped, $nome, $tamanho, $responsavel, $id_encontro, $titulo);
                    array_push($artigos, $id_artigo);
                } else {
                    //throw new Exception("Este arquivo PDF pode estar corrompido. "
                    //    . "Por favor, verifique se o arquivo é realmente um PDF válido.");
                    throw new Exception(_("This PDF file might be corrupted. Please check if this is a valid PDF file."));
                }
            } catch (Zend_Db_Exception $e) {
                throw $e;
            } catch (Exception $e) {
                throw $e;
            }
        }
        return $artigos;
    }

    private function _artigoCriarEmail() {
        // TODO
    }

}
