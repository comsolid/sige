<?php

class ParticipanteController extends Sige_Controller_Action {

    public function init() {
        $sessao = Zend_Auth::getInstance()->getIdentity();
        $this->view->menu = new Sige_Desktop_Menu($this->view, 'inicio', $sessao['administrador']);
        $this->_helper->layout->setLayout('twbs3/layout');
    }

    public function indexAction() {
        $this->autenticacao();
        $sessao = Zend_Auth::getInstance()->getIdentity();
        $cache = Zend_Registry::get('cache_common');
        $ps = $cache->load('prefsis');
        $idEncontro = (int) $ps->encontro["id_encontro"];
        $idPessoa = $sessao["idPessoa"];

        $eventoDemanda = new Application_Model_EventoDemanda();
        $eventoParticipante = $eventoDemanda->listar(array($idEncontro, $idPessoa));
        $this->view->listaParticipanteEventoTabela = $eventoParticipante;
    }

    /**
     * Mapeada como
     * 	/participar
     */
    public function criarAction() {
        $this->view->menu = "";
        $form = new Application_Form_Pessoa();
        $this->view->form = $form;
        $data = $this->getRequest()->getPost();

        if ($this->getRequest()->isPost() && $form->isValid($data)) {
            $data = $form->getValues();
            $pessoa = new Application_Model_Pessoa();
            $participante = new Application_Model_Participante();

            $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', APPLICATION_ENV);
            $idEncontro = $config->encontro->codigo;

            $data2 = array(
                'id_encontro' => $idEncontro,
                'id_municipio' => $data['id_municipio'],
                'id_instituicao' => $data['id_instituicao']
            );
            unset($data['id_municipio']);
            unset($data['id_instituicao']);
            unset($data['captcha']);

            $adapter = $pessoa->getAdapter();
            try {
                $adapter->beginTransaction();
                $idPessoa = $pessoa->criar($data);
                $data2['id_pessoa'] = $idPessoa;
                $participante->insert($data2);
                // the commit occurs only after send email!
            } catch (Zend_Db_Exception $ex) {
                $adapter->rollBack();
                $sentinela = 1;

                if ($ex->getCode() == 23505) {
                    $this->_helper->flashMessenger->addMessage(
                            array('warning' => _('E-mail already registered.')));
                } else {
                    $this->_helper->flashMessenger->addMessage(
                            array('danger' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
                                . $ex->getMessage()));
                }
            }
            // codigo responsavel por enviar email para confirmacao
            try {
                if (!empty($idPessoa) and $idPessoa > 0) {
                    $rs = $participante->dadosTicketInscricao($idPessoa, $idEncontro);
                    $pdf = new Sige_Pdf_Relatorio_TicketInscricao($rs);
                    $binary = $pdf->obterPdf();

                    $mail = new Application_Model_EmailConfirmacao();
                    $mail->send(
                        $idPessoa,
                        $idEncontro,
                        Application_Model_EmailConfirmacao::MSG_CONFIRMACAO,
                        $binary
                    );

                    $data = array(
                        'email_enviado' => 'true'
                    );
                    $where = $pessoa->getAdapter()->quoteInto('id_pessoa = ?', $idPessoa);
                    $pessoa->update($data, $where);
                }
            } catch (Exception $ex) {
                $adapter->rollBack();
                $sentinela = 1;
                $this->_helper->flashMessenger->addMessage(
                        array('danger' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
                            . $ex->getMessage()));
            }

            if ($sentinela == 0) {
                $adapter->commit();
                return $this->_helper->redirector->goToRoute(array(
                            'controller' => 'participante',
                            'action' => 'sucesso'), 'default', true);
            }
        }
    }

    public function editarAction() {
        $this->autenticacao();

        $sessao = Zend_Auth::getInstance()->getIdentity();
        $cache = Zend_Registry::get('cache_common');
        $ps = $cache->load('prefsis');
        $idEncontro = (int) $ps->encontro["id_encontro"];
        $idPessoa = $sessao["idPessoa"];
        $form = new Application_Form_PessoaEdit();
        $this->view->form = $form;

        $pessoa = new Application_Model_Pessoa();
        $participante = new Application_Model_Participante();
        $result = $participante->ler($idPessoa, $idEncontro);
        $form->populate($result);
        $data = $this->getRequest()->getPost();

        if ($this->getRequest()->isPost() && $form->isValid($data)) {
            $data = $form->getValues();

            $data2 = array(
                'id_encontro' => $idEncontro,
                'id_municipio' => $data['id_municipio'],
                'id_instituicao' => $data['id_instituicao']
            );

            unset($data['id_municipio']);
            unset($data['id_instituicao']);

            $sentinela = 0;
            $adapter = $pessoa->getAdapter();
            try {
                $adapter->beginTransaction();

                //$where = $pessoa->getAdapter()->quoteInto('id_pessoa = ?', $idPessoa);
                $pessoa->atualizar($data, $idPessoa);

                $where = $participante->getAdapter()
                                ->quoteInto('id_pessoa = ?', $idPessoa)
                        . $participante->getAdapter()
                                ->quoteInto(' AND id_encontro = ? ', $idEncontro);
                $participante->update($data2, $where);
                $adapter->commit();
            } catch (Zend_Db_Exception $ex) {
                $adapter->rollBack();
                $sentinela = 1;
                $this->_helper->flashMessenger->addMessage(
                        array('danger' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
                            . $ex->getMessage()));
            }

            // codigo responsavel por enviar email para confirmacao
            if ($sentinela == 0) {
                return $this->_helper->redirector->goToRoute(array(
                            'controller' => 'participante',
                            'action' => 'ver'
                                ), 'default', true);
            }
        }
        $this->view->id = $idPessoa;
        $sql = $pessoa->getAdapter()->quoteInto('id_pessoa = ?', $idPessoa);
        $this->view->user = $pessoa->fetchRow($sql);
    }

    public function sucessoAction() {
        $this->view->menu = "";
    }

    public function alterarSenhaAction() {
        $this->autenticacao();

        $sessao = Zend_Auth::getInstance()->getIdentity();
        $idPessoa = $sessao["idPessoa"];

        $pessoa = new Application_Model_Pessoa();
        $form = new Application_Form_AlterarSenha();
        $this->view->form = $form;

        $data = $this->getRequest()->getPost();

        if ($this->getRequest()->isPost() && $form->isValid($data)) {
            $data = $form->getValues();
            $email = $sessao["email"];
            $resultadoConsulta = $pessoa->avaliaLogin($email, $data['senhaAntiga']);

            if ($resultadoConsulta != null) {

                if ($resultadoConsulta['valido']) {

                    if ($data['senhaNova'] == $data['senhaNovaRepeticao']) {
                        $pessoa->setNovaSenha($resultadoConsulta['id_pessoa'], $data['senhaNova']);
                        $this->_helper->flashMessenger->addMessage(
                                array('success' => _('Password successfully updated!')));

                        return $this->_helper->redirector->goToRoute(array(
                                    'controller' => 'participante'
                                        ), 'default', true);
                    } else {
                        $this->_helper->flashMessenger->addMessage(
                                array('warning' => _('The passwords must match!')));
                    }
                } else {
                    $this->_helper->flashMessenger->addMessage(
                            array('danger' => _('Old password incorrect.')));
                }
            }
        }

        $this->view->id = $idPessoa;
        $sql = $pessoa->getAdapter()->quoteInto('id_pessoa = ?', $idPessoa);
        $this->view->user = $pessoa->fetchRow($sql);
    }

    public function verAction() {
        $model = new Application_Model_Pessoa();
        $id = $this->_getParam('id', "");
        if (!empty($id)) {
            if (is_numeric($id)) {
                $sql = $model->getAdapter()->quoteInto('id_pessoa = ?', $id);
            } else {
                $sql = $model->getAdapter()->quoteInto('twitter = ?', $id);
            }
            $this->view->mostrarEditar = false;
        } else if (Zend_Auth::getInstance()->hasIdentity()) {
            $sessao = Zend_Auth::getInstance()->getIdentity();
            if (!empty($sessao["twitter"])) {
                $sql = $model->getAdapter()->quoteInto('twitter = ?', $sessao["twitter"]);
                $id = $sessao["twitter"];
            } else {
                $sql = $model->getAdapter()->quoteInto('id_pessoa = ?', $sessao["idPessoa"]);
                $id = $sessao["idPessoa"];
            }
            $this->view->mostrarEditar = true;
        } else {
            $this->_helper->flashMessenger->addMessage(
                    array('danger' => 'Participante não encontrado.'));
            return;
        }
        $this->view->id = $id;
        $this->view->user = $model->fetchRow($sql);
        try {
            if (isset($this->view->user->slideshare)) {
                $this->view->slides = $model->listarSlideShare($this->view->user->slideshare);
            }
        } catch (Exception $e) {
            $this->view->slideshareError = $e->getMessage();
        }
    }

    public function certificadosAction() {
        $this->autenticacao();
        $sessao = Zend_Auth::getInstance()->getIdentity();
        $id_pessoa = $sessao["idPessoa"];
        $this->view->menu->setAtivo('certificados');

        $model = new Application_Model_Participante();
        $this->view->certsParticipanteEncontro = $model->listarCertificadosParticipanteEncontro($id_pessoa);
        $this->view->certsParticipanteEvento = $model->listarCertificadosParticipanteEvento($id_pessoa);
//        $this->view->certsPalestrante = array_merge($model->listarCertificadosPalestrante($id_pessoa), $model->listarCertificadosPalestrantesOutros($id_pessoa), $model->listarCertificadosPalestrantesArtigos($id_pessoa));
        $this->view->certsPalestrante = array_merge($model->listarCertificadosPalestrante($id_pessoa), $model->listarCertificadosPalestrantesOutros($id_pessoa));

        $this->view->id = $id_pessoa;
        $pessoa = new Application_Model_Pessoa();
        $sql = $pessoa->getAdapter()->quoteInto('id_pessoa = ?', $id_pessoa);
        $this->view->user = $pessoa->fetchRow($sql);
    }

    public function certificadoParticipanteEncontroAction() {
        $this->_helper->layout()->disableLayout();
        $this->_helper->viewRenderer->setNoRender(true);

        $this->autenticacao();
        $sessao = Zend_Auth::getInstance()->getIdentity();
        $id_pessoa = $sessao["idPessoa"];
        $id_encontro = $this->_getParam('id_encontro', 0);

        $model = new Application_Model_Participante();
        $rs = $model->listarCertificadosParticipanteEncontro($id_pessoa, $id_encontro);

        if (is_null($rs)) {
            $this->_helper->flashMessenger->addMessage(
                    array('error' => 'Este certificado ainda não está disponível.'));
            return $this->_helper->redirector->goToRoute(array(
                        'controller' => 'participante',
                        'action' => 'certificados'), 'default', true);
        }

        try {
            $certificado = new Sige_Pdf_Certificado();
            $pdfData = $certificado->participanteEncontro(array(
                'nome' => $rs['nome'],
                'id_encontro' => $rs['id_encontro'], // serve para identificar o modelo
                'encontro' => $rs['nome_encontro'],
            ));
            $filename = "certificado_participante_"
                    . $this->_stringToFilename($rs["nome_encontro"])
                    . ".pdf";
            header("Content-Disposition: inline; filename={$filename}");
            header("Content-type: application/x-pdf");
            echo $pdfData;
        } catch (Exception $e) {
            $this->_helper->flashMessenger->addMessage(
                    array('danger' => 'Ocorreu um erro inesperado.<br/>Detalhes: '
                        . $e->getMessage()));
            return $this->_helper->redirector->goToRoute(array(
                        'controller' => 'participante',
                        'action' => 'certificados'), 'default', true);
        }
    }

    public function certificadoParticipanteEventoAction() {
        $this->_helper->layout()->disableLayout();
        $this->_helper->viewRenderer->setNoRender(true);

        $this->autenticacao();
        $sessao = Zend_Auth::getInstance()->getIdentity();
        $id_pessoa = $sessao["idPessoa"];
        $id_evento = $this->_getParam('id_evento', null);

        $model = new Application_Model_Participante();
        $rs = $model->listarCertificadosParticipanteEvento($id_pessoa, $id_evento);

        if (is_null($rs)) {
            $this->_helper->flashMessenger->addMessage(
                    array('danger' => 'Você não participou deste Encontro.'));
            return $this->_helper->redirector->goToRoute(array(
                        'controller' => 'participante',
                        'action' => 'certificados'), 'default', true);
        }

        try {
            $certificado = new Sige_Pdf_Certificado();
            $pdfData = $certificado->participanteEvento(array(
                'nome' => $rs['nome'],
                'id_encontro' => $rs['id_encontro'], // serve para identificar o modelo
                'encontro' => $rs['nome_encontro'],
                'tipo_evento' => $rs['nome_tipo_evento'],
                'nome_evento' => $rs['nome_evento'],
                'carga_horaria' => $rs['carga_horaria'],
            ));
            $filename = "certificado_participante_"
                    . $this->_stringToFilename($rs["nome_encontro"]) . "_"
                    . $this->_stringToFilename($rs["nome_evento"])
                    . ".pdf";
            header("Content-Disposition: inline; filename={$filename}");
            header("Content-type: application/x-pdf");
            echo $pdfData;
        } catch (Exception $e) {
            $this->_helper->flashMessenger->addMessage(
                    array('danger' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
                        . $e->getMessage()));
            return $this->_helper->redirector->goToRoute(array(
                        'controller' => 'participante',
                        'action' => 'certificados'), 'default', true);
        }
    }

    public function certificadoPalestranteAction() {
        $this->_helper->layout()->disableLayout();
        $this->_helper->viewRenderer->setNoRender(true);

        $this->autenticacao();
        $sessao = Zend_Auth::getInstance()->getIdentity();
        $id_pessoa = $sessao["idPessoa"];
        $id_evento = $this->_getParam('id', 0);

        $model = new Application_Model_Participante();
        $rs = $model->listarCertificadosPalestrante($id_pessoa, $id_evento);
        // palestrante em evento_palestrante
        if (is_null($rs)) {
            $rs = $model->listarCertificadosPalestrantesOutros($id_pessoa, $id_evento);
        }

        if (is_null($rs)) {
            $this->_helper->flashMessenger->addMessage(
                    array('danger' => 'Você não apresentou esse trabalho neste Encontro.'));
            return $this->_helper->redirector->goToRoute(array(
                        'controller' => 'participante',
                        'action' => 'certificados'), 'default', true);
        }

        try {
            $certificado = new Sige_Pdf_Certificado();
            // Get PDF document as a string
            $pdfData = $certificado->palestranteEvento(array(
                'nome' => $rs['nome'],
                'id_encontro' => $rs['id_encontro'], // serve para identificar o modelo
                'encontro' => $rs['nome_encontro'],
                'tipo_evento' => $rs['nome_tipo_evento'],
                'nome_evento' => $rs['nome_evento'],
                'carga_horaria' => $rs['carga_horaria'],
            ));
            $filename = "certificado_palestrante_"
                    . $this->_stringToFilename($rs["nome_encontro"]) . "_"
                    . $this->_stringToFilename($rs["nome_evento"])
                    . ".pdf";
            header("Content-Disposition: inline; filename={$filename}");
            header("Content-type: application/x-pdf");
            echo $pdfData;
        } catch (Exception $e) {
            $this->_helper->flashMessenger->addMessage(
                    array('danger' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
                        . $e->getMessage()));
            return $this->_helper->redirector->goToRoute(array(
                        'controller' => 'participante',
                        'action' => 'certificados'), 'default', true);
        }
    }

    public function ticketAction() {
        $this->autenticacao();

        $this->_helper->layout()->disableLayout();
        $this->_helper->viewRenderer->setNoRender(true);

        $sessao = Zend_Auth::getInstance()->getIdentity();
        $cache = Zend_Registry::get('cache_common');
        $ps = $cache->load('prefsis');
        $id_encontro = (int) $ps->encontro["id_encontro"];
        $id_pessoa = $sessao["idPessoa"];

        $model = new Application_Model_Participante();
        $rs = $model->dadosTicketInscricao($id_pessoa, $id_encontro);
        $pdf = new Sige_Pdf_Relatorio_TicketInscricao($rs);
        try {
            $pdf->gerarPdf();
        } catch (Exception $e) {
            $this->_helper->flashMessenger->addMessage(
                    array('danger' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
                        . $e->getMessage()));
            return $this->_helper->redirector->goToRoute(array(
                        'controller' => 'participante',
                        'action' => 'ver'), 'default', true);
        }
    }
}
