<?php

class ParticipanteController extends Zend_Controller_Action {

    public function init() {
        $sessao = Zend_Auth::getInstance()->getIdentity();
        $this->view->menu = new Application_Form_Menu($this->view, 'inicio', $sessao['administrador']);
    }

    private function autenticacao() {
        if (!Zend_Auth::getInstance()->hasIdentity()) {
            $session = new Zend_Session_Namespace();
            $session->setExpirationSeconds(60 * 60 * 1); // 1 minuto
            $session->url = $_SERVER['REQUEST_URI'];
            return $this->_helper->redirector->goToRoute(array(), 'login', true);
        }
    }

    public function indexAction() {
        $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/tabela_sort.css'));
        $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery.dataTables.js'));
        $this->view->headScript()->appendFile($this->view->baseUrl('js/participante/inicio.js'));

        $this->autenticacao();
        $sessao = Zend_Auth::getInstance()->getIdentity();
        $idPessoa = $sessao["idPessoa"];
        $idEncontro = $sessao["idEncontro"];

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

            $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'staging');
            $idEncontro = $config->encontro->codigo;

            $data2 = array(
                'id_encontro' => $idEncontro,
                'id_municipio' => $data['municipio'],
                'id_instituicao' => $data['instituicao']
            );
            unset($data['municipio']);
            unset($data['instituicao']);
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
                // 23505 = foreign key exception
                if ($ex->getCode() == 23505) {
                    $this->_helper->flashMessenger->addMessage(
                            array('error' => _('E-mail already registered.')));
                } else {
                    $this->_helper->flashMessenger->addMessage(
                            array('error' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
                                . $ex->getMessage()));
                }
            }
            // codigo responsavel por enviar email para confirmacao
            try {
                if (!empty($idPessoa) and $idPessoa > 0) {
                    $mail = new Application_Model_EmailConfirmacao();
                    $mail->send($idPessoa, $idEncontro);
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
                        array('error' => 'Ocorreu um erro inesperado ao enviar e-mail.<br/>Detalhes: '
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
        $idPessoa = $sessao["idPessoa"];
        $idEncontro = $sessao["idEncontro"];
        $form = new Application_Form_PessoaEdit();
        $this->view->form = $form;

        // TODO: refazer este trecho usando INNER JOIN no banco de dados
        // ao invés de array_merge, blargh!
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
                        array('error' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
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
    }

    public function sucessoAction() {
        $this->view->menu = "";
    }

    public function alterarSenhaAction() {
        $this->view->menu->setAtivo('alterarsenha');
        $this->autenticacao();

        $form = new Application_Form_AlterarSenha();
        $this->view->form = $form;

        $data = $this->getRequest()->getPost();
        if (isset($data['cancelar'])) {
            return $this->_helper->redirector->goToRoute(array(
                        'controller' => 'participante',
                        'action' => 'ver'
                            ), 'default', true);
        }

        if ($this->getRequest()->isPost() && $form->isValid($data)) {
            $data = $form->getValues();

            $pessoa = new Application_Model_Pessoa();
            $sessao = Zend_Auth::getInstance()->getIdentity();
            $email = $sessao["email"];

            $resultadoConsulta = $pessoa->avaliaLogin($email, $data['senhaAntiga']);

            if ($resultadoConsulta != null) {

                if ($resultadoConsulta['valido']) {

                    if ($data['senhaNova'] == $data['senhaNovaRepeticao']) {
                        $where = $pessoa->getAdapter()->quoteInto('id_pessoa = ?', $resultadoConsulta['id_pessoa']);

                        $novaSennha = array(
                            'senha' => md5($data['senhaNova'])
                        );
                        $pessoa->update($novaSennha, $where);

                        return $this->_helper->redirector->goToRoute(array(
                                    'controller' => 'participante'
                                        ), 'default', true);
                    } else {
                        $this->_helper->flashMessenger->addMessage(
                                array('error' => 'Nova senha não confere!'));
                    }
                } else {
                    $this->_helper->flashMessenger->addMessage(
                            array('error' => 'Senha antiga incorreta!'));
                }
            }
        }
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
                    array('error' => 'Participante não encontrado.'));
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
        $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/screen.css'));
        $sessao = Zend_Auth :: getInstance()->getIdentity();
        $idPessoa = $sessao["idPessoa"];

        $model = new Application_Model_Participante();
        $this->view->certsParticipante = $model->listarCertificadosParticipante($idPessoa);
        $this->view->certsPalestrante = $model->listarCertificadosPalestrante($idPessoa);
        $this->view->certsPalestrante = array_merge($this->view->certsPalestrante, $model->listarCertificadosPalestrantesOutros($idPessoa));
    }

    public function certificadoParticipanteAction() {
        $this->_helper->layout()->disableLayout();
        $this->_helper->viewRenderer->setNoRender(true);

        $sessao = Zend_Auth :: getInstance()->getIdentity();
        $idPessoa = $sessao["idPessoa"];
        $idEncontro = $this->_getParam('id_encontro', 0);

        $model = new Application_Model_Participante();
        $rs = $model->listarCertificadosParticipante($idPessoa, $idEncontro);

        if (is_null($rs)) {
            $this->_helper->flashMessenger->addMessage(
                    array('error' => 'Você não participou deste Encontro.'));
            return $this->_helper->redirector->goToRoute(array(
                        'controller' => 'participante',
                        'action' => 'certificados'), 'default', true);
        }

        try {
            $certificado = new Sige_Pdf_Certificado();
            $pdfData = $certificado->participante(array(
                'nome' => $rs['nome'],
                'id_encontro' => $rs['id_encontro'], // serve para identificar o modelo
                'encontro' => $rs['nome_encontro'],
            ));
            header("Content-Disposition: inline; filename=certificado-participante.pdf");
            header("Content-type: application/x-pdf");
            echo $pdfData;
        } catch (Exception $e) {
            $this->_helper->flashMessenger->addMessage(
                    array('error' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
                        . $e->getMessage()));
            return $this->_helper->redirector->goToRoute(array(
                        'controller' => 'participante',
                        'action' => 'certificados'), 'default', true);
        }
    }

    public function certificadoPalestranteAction() {
        $this->_helper->layout()->disableLayout();
        $this->_helper->viewRenderer->setNoRender(true);

        $sessao = Zend_Auth :: getInstance()->getIdentity();
        $idPessoa = $sessao["idPessoa"];
        $idEvento = $this->_getParam('id', 0);

        $model = new Application_Model_Participante();
        $rs = $model->listarCertificadosPalestrante($idPessoa, $idEvento);
        // palestrante em evento_palestrante
        if (is_null($rs)) {
            $rs = $model->listarCertificadosPalestrantesOutros($idPessoa, $idEvento);
        }

        if (is_null($rs)) {
            $this->_helper->flashMessenger->addMessage(
                    array('error' => 'Você não apresentou esse trabalho neste Encontro.'));
            return $this->_helper->redirector->goToRoute(array(
                        'controller' => 'participante',
                        'action' => 'certificados'), 'default', true);
        }

        try {
            $certificado = new Sige_Pdf_Certificado();
            // Get PDF document as a string
            $pdfData = $certificado->palestrante(array(
                'nome' => $rs['nome'],
                'id_encontro' => $rs['id_encontro'], // serve para identificar o modelo
                'encontro' => $rs['nome_encontro'],
                'tipo_evento' => $rs['nome_tipo_evento'],
                'nome_evento' => $rs['nome_evento']
            ));

            header("Content-Disposition: inline; filename=certificado-palestrante.pdf");
            header("Content-type: application/x-pdf");
            echo $pdfData;
        } catch (Exception $e) {
            $this->_helper->flashMessenger->addMessage(
                    array('error' => _('An unexpected error ocurred.<br/> Details:&nbsp;')
                        . $e->getMessage()));
            return $this->_helper->redirector->goToRoute(array(
                        'controller' => 'participante',
                        'action' => 'certificados'), 'default', true);
        }
    }

}
