<?php
class Admin_CaravanaController extends Sige_Controller_AdminAction {

    public function init() {
        $sessao = Zend_Auth::getInstance()->getIdentity();
        if (!$sessao["administrador"]) {
            return $this->_helper->redirector->goToRoute(array('controller' => 'participante', 'action' => 'index'), 'default', true);
        }

        $this->_helper->layout->setLayout('twbs3-admin/layout');
        $this->view->menu = new Sige_Desktop_AdminSidebarLeftMenu($this->view, 'caravan');

        $this->_helper->getHelper('AjaxContext')
            ->addActionContext('ajax-buscar', 'json')
            ->initContext();
    }

    public function indexAction() {
        $this->autenticacao();

        $this->view->title = _('Caravans');
    }

    public function ajaxBuscarAction() {
        if (!$this->autenticacao(true)) {
            return;
        }

        $cache = Zend_Registry::get('cache_common');
        $ps = $cache->load('prefsis');
        $idEncontro = (int) $ps->encontro["id_encontro"];

        $termo = $this->_request->getParam("termo", "");
        $model = new Admin_Model_Caravana();

        $rs = $model->buscar($idEncontro, $termo);
        $this->view->size = count($rs);
        $this->view->itens = array();

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
            $this->view->itens[] = array(
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
    }

    /**
     * Mapeada como
     * 	/c/validar/:id
     * 	/c/invalidar/:id
     */
    public function situacaoAction() {
        $this->autenticacao();

        $this->_helper->layout()->disableLayout();
        $this->_helper->viewRenderer->setNoRender(true);

        $id = $this->_getParam('id', 0);
        $validar = $this->_getParam('validar', 'f');

//        $sessao = Zend_Auth::getInstance()->getIdentity();
//        $idEncontro = $sessao["idEncontro"]; // UNSAFE
        $cache = Zend_Registry::get('cache_common');
        $ps = $cache->load('prefsis');
        $idEncontro = (int) $ps->encontro["id_encontro"];

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
