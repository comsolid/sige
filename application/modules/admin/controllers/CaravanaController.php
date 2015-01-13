<?php
class Admin_CaravanaController extends Zend_Controller_Action {

    public function init() {
        if (!Zend_Auth::getInstance()->hasIdentity()) {
            $session = new Zend_Session_Namespace();
            $session->setExpirationSeconds(60 * 60 * 1); // 1 minuto
            $session->url = $_SERVER['REQUEST_URI'];
            return $this->_helper->redirector->goToRoute(array(), 'login', true);
        }

        $sessao = Zend_Auth::getInstance()->getIdentity();
        if (!$sessao["administrador"]) {
            return $this->_helper->redirector->goToRoute(array('controller' => 'participante', 'action' => 'index'), 'default', true);
        }

        $this->_helper->layout->setLayout('twbs3-admin/layout');
        $this->view->menu = new Sige_Desktop_AdminSidebarLeftMenu($this->view, 'caravan');
    }

    public function indexAction() {
        $this->view->title = _('Caravans');
    }

    public function ajaxBuscarAction() {
        $this->_helper->layout()->disableLayout();
        $this->_helper->viewRenderer->setNoRender(true);
        $sessao = Zend_Auth::getInstance()->getIdentity();
        $idEncontro = $sessao["idEncontro"];
        $termo = $this->_request->getParam("termo", "");
        $model = new Admin_Model_Caravana();
        $rs = $model->buscar($idEncontro, $termo);
        $json = new stdClass;
        $json->size = count($rs);
        $json->itens = array();
        foreach ($rs as $value) {
            if ($value['validada']) {
                $validada = '<span class="label label-success">' . _("Yes") . '</span>';
                $url = '<a href="' . $this->view->url(array(
                    'id' => $value["id_caravana"]),
                    'invalidar_caravana', true) . '" class="btn btn-danger"><i class="fa fa-times"></i> ' . _("Invalidate") . '</a>';
            } else {
                $validada = '<span class="label label-danger">' . _("No") . '</span>';
                $url = '<a href="' . $this->view->url(array(
                    'id' => $value["id_caravana"]),
                    'validar_caravana', true) . '" class="btn btn-success"><i class="fa fa-check"></i> ' . _("Validate") . '</a>';
            }
            $json->itens[] = array(
                "{$value['nome_caravana']}",
                "{$value['apelido_caravana']}",
                "{$value['nome']}",
                "{$value['nome_municipio']}",
                "{$value['apelido_instituicao']}",
                "{$validada}",
                "{$value['num_h']}",
                "{$value['num_m']}",
                $url
            );
        }
        header("Pragma: no-cache");
        header("Cache: no-cache");
        header("Cache-Control: no-cache, must-revalidate");
        header("Content-type: text/json");
        echo json_encode($json);
    }

    /**
     * Mapeada como
     * 	/c/validar/:id
     * 	/c/invalidar/:id
     */
    public function situacaoAction() {
        $this->_helper->layout()->disableLayout();
        $this->_helper->viewRenderer->setNoRender(true);
        $id = $this->_getParam('id', 0);
        $validar = $this->_getParam('validar', 'f');
        $sessao = Zend_Auth::getInstance()->getIdentity();
        $idEncontro = $sessao["idEncontro"];
        $model = new Application_Model_Caravana();
        try {
            $select = "UPDATE caravana_encontro SET validada = ? WHERE id_caravana = ? AND id_encontro = ?";
            $model->getAdapter()->fetchAll($select, array($validar, $id, $idEncontro));
            $this->_helper->flashMessenger->addMessage(array('success' => 'Caravana atualizada com sucesso.'));
        }
        catch(Exception $ex) {
            $this->_helper->flashMessenger->addMessage(array('danger' => 'Ocorreu um erro inesperado.<br/>Detalhes: ' . $ex->getMessage()));
        }
        return $this->_helper->redirector->goToRoute(array('module' => 'admin', 'controller' => 'caravana', 'action' => 'index'), 'default', true);
    }
}
