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
            // obtem de maneira segura somente parametros esperados.
            $data = $form->getValues();
            $model = new Application_Model_Pessoa();
            $resultadoConsulta = $model->avaliaLogin($data['email'], $data['senha']);
            if ($resultadoConsulta != null) {
                if ($resultadoConsulta['valido']) {
                    $idPessoa = $resultadoConsulta['id_pessoa'];
                    $administrador = $resultadoConsulta['administrador'];
                    $apelido = $resultadoConsulta['apelido'];
                    $twitter = $resultadoConsulta['twitter'];
                    $cadastro_validado = $resultadoConsulta['cadastro_validado'];
                    if ($cadastro_validado == false) {
                        $where = $model->getAdapter()->quoteInto('id_pessoa = ?', $idPessoa);
                        $model->update(array('cadastro_validado' => true), $where);
                    }
                    $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'staging');
                    $idEncontro = $config->encontro->codigo;
                    $result = $model->buscarUltimoEncontro($idPessoa);
                    $irParaEditar = false;
                    // se ultimo encontro do participante for diferente do atual
                    if ($model->verificaEncontro($idEncontro, $idPessoa) == false) {
                        $result['id_encontro'] = intval($idEncontro);
                        try {
                            $model->getAdapter()->insert("encontro_participante", $result);
                            $this->_helper->flashMessenger->addMessage(array('success' => _('Welcome back. Your registration was confirmed!<br/>Please update your profile data.')));
                            $irParaEditar = true;
                        } catch(Exception $e) {
                            $irParaEditar = false;
                            $this->_helper->flashMessenger->addMessage(array('error' => $e->getMessage()));
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
                    $storage->write(array("idPessoa" => $idPessoa, "administrador" => $administrador, "apelido" => $apelido, "idEncontro" => $idEncontro, "twitter" => $twitter, "email" => $data['email']));
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
        $auth = Zend_Auth::getInstance();
        $auth->clearIdentity();
        return $this->_helper->redirector->goToRoute(array(), 'index', true);
    }

    public function recuperarSenhaAction() {
        $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/form.css'));
        $form = new Application_Form_RecuperarSenha();
        $this->view->form = $form;
        $data = $this->getRequest()->getPost();
        if ($this->getRequest()->isPost() && $form->isValid($data)) {
            $data = $form->getValues();
            unset($data['captcha']);
            $pessoa = new Application_Model_Pessoa();
            $select = $pessoa->select()->from('pessoa', array("id_pessoa"))->where("email = ?", $data['email']);
            // TODO: usar fetchRow!
            $resultado = $pessoa->fetchAll($select);
            if (sizeof($resultado) > 0) {
                $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'staging');
                $idEncontro = $config->encontro->codigo;
                $mail = new Application_Model_EmailConfirmacao();
                $mail->sendCorrecao($resultado[0]->id_pessoa, $idEncontro, Application_Model_EmailConfirmacao::MSG_RECUPERAR_SENHA);
                $this->_helper->flashMessenger->addMessage(array('success' => _('E-mail successfully sent, check your e-mail.')));
                return $this->_helper->redirector->goToRoute(array(), 'index', true);
            } else {
                $this->_helper->flashMessenger->addMessage(array('error' => _('E-mail not found.')));
            }
        }
    }

    public function sobreAction() {
        $sessao = Zend_Auth::getInstance()->getIdentity();
        $this->view->menu = new Application_Form_Menu($this->view, 'inicio', $sessao['administrador']);
    }
}
