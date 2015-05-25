<?php
class IndexController extends Zend_Controller_Action {

    public function init() {
    }

    public function indexAction() {
        $hasIdentity = Zend_Auth::getInstance()->hasIdentity();

        $mobile = new Sige_Mobile_Browser();
        if ($mobile->isMobile()) {
            if ($hasIdentity) {
                return $this->_helper->redirector->goToRoute(array(), 'mobile', true);
            } else {
                return $this->_helper->redirector->goToRoute(array(), 'login', true);
            }
        } else if ($hasIdentity) {
            return $this->_helper->redirector->goToRoute(array('controller' => 'participante', 'action' => 'index'), 'default', true);
        }
        $this->_helper->layout->setLayout('twbs3/front-page');
    }

    /**
     * Mapeada como
     *    /login
     */
    public function loginAction() {
        $isMobile = false;
        $mobile = new Sige_Mobile_Browser();
        if ($mobile->isMobile()) {
            $this->_helper->layout->setLayout('mobile');
            $isMobile = true;
            $form = new Mobile_Form_Login();
            $this->_helper->viewRenderer('mobile-login');
        } else {
            $this->_helper->layout->setLayout('twbs3/front-page');
            $form = new Application_Form_Login();
        }
        $this->view->form = $form;
        $data = $this->getRequest()->getPost();
        if ($this->getRequest()->isPost() && $form->isValid($data)) {
            $data = $form->getValues();
            $model = new Application_Model_Pessoa();
            $resultadoConsulta = $model->avaliaLogin($data['email'], $data['senha']);
            if ($resultadoConsulta != NULL) {
                $idPessoa = $resultadoConsulta['id_pessoa'];
                $administrador = $resultadoConsulta['administrador'];
                $apelido = $resultadoConsulta['apelido'];
                $twitter = $resultadoConsulta['twitter'];
                $cadastro_validado = $resultadoConsulta['cadastro_validado'];
                if ($cadastro_validado == false) {
                    $where = $model->getAdapter()->quoteInto('id_pessoa = ?', $idPessoa);
                    $model->update(array('cadastro_validado' => true), $where);
                }
                $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', APPLICATION_ENV);
                $idEncontro = $config->encontro->codigo;
                $result = $model->buscarUltimoEncontro($idPessoa);
                $irParaEditar = false;
                // se ultimo encontro do participante for diferente do atual
                if ($model->verificaEncontro($idEncontro, $idPessoa) == false) {
                    $result['id_encontro'] = intval($idEncontro);
                    // forçar participante validado : issue #32
                    $result['validado'] = 't'; // true
                    $result['data_validacao'] = new Zend_Db_Expr('now()');
                    try {
                        $model->getAdapter()->insert("encontro_participante", $result);
                        $this->_helper->flashMessenger->addMessage(array('success' => _('Welcome back. Your registration was confirmed!<br/>Please update your profile data.')));
                        $irParaEditar = true;

                        $this->_enviarEmailConfirmacaoInscricao($idEncontro, $idPessoa);
                    } catch(Exception $e) {
                        $irParaEditar = false;
                        $this->_helper->flashMessenger->addMessage(array('danger' => $e->getMessage()));
                    }
                } else if (!$result['validado']) {
                    // se participante ainda não está validado no encontro
                    // devemos validar
                    $adapter = $model->getAdapter();
                    $adapter->fetchAll("UPDATE encontro_participante
                    SET validado = 't', data_validacao = now()
                    WHERE id_pessoa = {$result['id_pessoa']}
                    AND id_encontro = {$idEncontro}");
                }
                $auth = Zend_Auth::getInstance();
                $storage = $auth->getStorage();
                $storage->write(array(
                    "idPessoa" => $idPessoa,
                    "administrador" => $administrador,
                    "apelido" => $apelido,
                    "idEncontro" => $idEncontro, // TODO: remove unsafe idEncontro, get from cache!
                    "twitter" => $twitter,
                    "email" => $data['email']
                ));
                if ($isMobile) {
                    return $this->_helper->redirector->goToRoute(array(), 'mobile', true);
                } else if ($irParaEditar) {
                    return $this->_helper->redirector->goToRoute(array('controller' => 'participante', 'action' => 'editar'), 'default', true);
                } else {
                    $session = new Zend_Session_Namespace();
                    if (isset($session->url)) {
                        $this->_redirect($session->url, array('prependBase' => false));
                        unset($session->url);
                    } else {
                        return $this->_helper->redirector->goToRoute(array('controller' => 'participante', 'action' => 'index'), 'default', true);
                    }
                }
            } else {
                $this->_helper->flashMessenger->addMessage(array('danger' => _('E-mail or Password incorrect.')));
            }
        }
    }

    public function mobileLoginAction() {
        // empty action
        // usada no login para mudar view para jquery mobile.
    }

    public function logoutAction() {
        if (Zend_Auth::getInstance()->hasIdentity()) {
            $auth = Zend_Auth::getInstance();
            $auth->clearIdentity();
        }
        return $this->_helper->redirector->goToRoute(array(), 'index', true);
    }

    public function recuperarSenhaAction() {
        $this->_helper->layout->setLayout('twbs3/front-page');
        $form = new Application_Form_RecuperarSenha();
        $this->view->form = $form;
        $data = $this->getRequest()->getPost();
        if ($this->getRequest()->isPost() && $form->isValid($data)) {
            $data = $form->getValues();
            unset($data['captcha']);
            $pessoa = new Application_Model_Pessoa();
            $select = $pessoa->select()->from('pessoa', array("id_pessoa"))->where("email = ?", $data['email']);

            $resultado = $pessoa->fetchRow($select);
            if (!empty($resultado)) {
                $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', APPLICATION_ENV);
                $idEncontro = $config->encontro->codigo;
                $mail = new Application_Model_EmailConfirmacao();
                $mail->send($resultado->id_pessoa, $idEncontro, Application_Model_EmailConfirmacao::MSG_RECUPERAR_SENHA);
                $this->_helper->flashMessenger->addMessage(array('success' => _('E-mail successfully sent, check your e-mail.')));
                return $this->_helper->redirector->goToRoute(array(), 'login', true);
            } else {
                $this->_helper->flashMessenger->addMessage(array('danger' => _('E-mail not found.')));
            }
        }
    }

    public function sobreAction() {
        $this->_helper->layout->setLayout('twbs3/layout');
        if (Zend_Auth::getInstance()->hasIdentity()) {
            $sessao = Zend_Auth::getInstance()->getIdentity();
            $this->view->menu = new Sige_Desktop_Menu($this->view, 'inicio', $sessao['administrador']);
        }
    }

    public function definirSenhaAction() {
        $this->_helper->layout->setLayout('twbs3/front-page');

        $hashedToken = $this->getRequest()->getParam('hashedToken');
        if (empty($hashedToken)) {
            $this->_helper->flashMessenger->addMessage(
                    array('warning' => _('Verification token not informed.')));
            return $this->_helper->redirector->goToRoute(
                            array(), 'login', true);
        }

        $id = $this->getRequest()->getParam('id');
        if (empty($id)) {
            $this->_helper->flashMessenger->addMessage(
                    array('warning' => _('User not informed.')));
            return $this->_helper->redirector->goToRoute(
                            array(), 'login', true);
        }

        $pessoa = new Application_Model_Pessoa();
        try {
            $pessoa->verificarToken($id, $hashedToken);
        } catch (Exception $e) {
            $this->_helper->flashMessenger->addMessage(array('danger' => $e->getMessage()));
            return $this->_helper->redirector->goToRoute(array(), 'login', true);
        }

        $form = new Application_Form_DefinirSenha();

        if ($this->getRequest()->isPost() && $form->isValid($this->getRequest()->getPost())) {
            $values = $form->getValues();
            try {
                if (strcmp($values['nova_senha'], $values['repetir_nova_senha']) == 0) {
                    $pessoa->setNovaSenha($id, $values['nova_senha']);
                    $pessoa->resetarToken($id);

                    $this->_helper->flashMessenger->addMessage(
                            array('success' => _('Password successfully updated!')));
                    return $this->_helper->redirector->goToRoute(
                                    array(), 'login', true);
                } else {
                    $this->_helper->flashMessenger->addMessage(
                            array('warning' => _('The passwords must match!')));
                }
            } catch (Exception $e) {
                $this->_helper->flashMessenger->addMessage(
                        array('danger' => $e->getMessage()));
            }
        }

        // cria form e envia pra view
        $this->view->form = $form;
    }

    public function requisitarMudarEmailAction() {
        $this->_helper->layout->setLayout('twbs3/layout');

        $form = new Application_Form_RequisitarMudarEmail();

        if ($this->getRequest()->isPost() && $form->isValid($this->getRequest()->getPost())) {
            $data = $form->getValues();
            unset($data['captcha']);
            unset($data['submit']);

            $pessoa = new Application_Model_Pessoa();
            // 1. ver se e-mail existe.
            $from = $pessoa->select()->from('pessoa', array("id_pessoa"));
            $select = $from->where("email = ?", $data['email_anterior']);
            $resultado = $pessoa->fetchRow($select);
            if (!empty($resultado)) {
                // 2. ver se novo e-mail já existe. Se sim, não pode ser substituído
                $from2 = $pessoa->select()->from('pessoa', array("id_pessoa"));
                $select2 = $from2->where("email = ?", $data['novo_email']);
                $resultado2 = $pessoa->fetchRow($select2);
                if (empty($resultado2)) {
                    try {
                        $model = new Application_Model_MudarEmail();
                        $model->insert($data);

                        $this->_helper->flashMessenger->addMessage(
                                array('success' => _('Your request for change your e-mail was sent. Wait for an approval soon.')));

                        return $this->_helper->redirector->goToRoute(
                                        array(), 'login', true);
                    } catch (Exception $e) {
                        $this->_helper->flashMessenger->addMessage(
                                array('danger' => $e->getMessage()));
                    }
                } else {
                    $this->_helper->flashMessenger->addMessage(
                            array('warning' => _('The new E-mail address that you inform already exists!')));
                }
            } else {
                $this->_helper->flashMessenger->addMessage(
                        array('warning' => _('Your previous E-mail address was not found!')));
            }
        }
        $this->view->form = $form;
    }

    private function _enviarEmailConfirmacaoInscricao($idPessoa, $idEncontro) {
        $model = new Application_Model_Participante();
        $rs = $model->dadosTicketInscricao($idPessoa, $idEncontro);
        $pdf = new Sige_Pdf_Relatorio_TicketInscricao($rs);
        $binary = $pdf->obterPdf();

        $mail = new Application_Model_EmailConfirmacao();
        $mail->send(
            $idPessoa,
            $idEncontro,
            Application_Model_EmailConfirmacao::MSG_CONFIRMACAO_REINSCRICAO,
            $binary
        );
    }
}
