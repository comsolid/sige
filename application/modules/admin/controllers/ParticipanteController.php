<?php

class Admin_ParticipanteController extends Sige_Controller_AdminAction {

    public function init() {
        $this->_helper->layout->setLayout('twbs3-admin/layout');
        $this->view->menu = new Sige_Desktop_AdminSidebarLeftMenu($this->view, 'registration');

        $this->_helper->getHelper('AjaxContext')
            ->addActionContext('ajax-buscar', 'json')
            ->addActionContext('presenca', 'json')
            ->initContext();
    }

    /**
     * Mapeada como
     *    /inscricoes
     */
    public function indexAction() {
        $this->autenticacao();
        $this->view->title = $this->t->_('Registration');

        $cache = Zend_Registry::get('cache_common');
        $ps = $cache->load('prefsis');
        $idEncontro = (int) $ps->encontro["id_encontro"];
        $this->view->idEncontro = $idEncontro;
    }

    public function ajaxBuscarAction() {
        if (!$this->autenticacao(true)) {
            return;
        }

        $pessoas = new Application_Model_Pessoa();
        $termo = $this->_request->getParam("termo");
        $dataTodosUsuarios = array($this->_request->getParam("idEncontro", 0), $termo, $this->_request->getParam("tipo"));
        $data = $pessoas->buscaPessoas($dataTodosUsuarios);
        $this->view->size = count($data);
        $this->view->aaData = array();
        foreach ($data as $value) {
            if ($value['confirmado']) {
                $isValidado = '<span class="label label-success">' . $this->t->_("Confirmed!") . '</span>';
                $acao = "<a href=\"#\" class=\"situacao\"
               data-url=\"/u/desfazer-confirmar/{$value["id_pessoa"]}\">" . $this->t->_("Undo") . "</a>";
            } else {
                $isValidado = '<span class="label label-danger">' . $this->t->_("Not confirmed!") . '</span>';
                $acao = "<a href=\"#\" class=\"situacao\"
               data-url=\"/u/confirmar/{$value["id_pessoa"]}\">" . $this->t->_("Confirm") . "</a>";
            }
            $this->view->aaData[] = array("{$value['nome']}", "{$value['apelido']}", "{$value['email']}", "{$value['nome_municipio']}", "{$value['apelido_instituicao']}", "{$value['nome_caravana']}", $isValidado, $acao);
        }
    }

    /**
     * Mapeada como:
     *    /u/confirmar/:id
     *    /u/desfazer-confirmar/:id
     * @return type
     */
    public function presencaAction() {
        if (!$this->autenticacao(true)) {
            return;
        }

        $id = $this->_getParam('id', 0);
        $confirmar = $this->_getParam('confirmar', 'f');
        $cache = Zend_Registry::get('cache_common');
        $ps = $cache->load('prefsis');
        $idEncontro = (int) $ps->encontro["id_encontro"];
        $model = new Application_Model_Pessoa();
        try {
            if ($confirmar == 't') {
                $data = 'now()';
                $this->view->msg = $this->t->_("Participant confirmed.");
            } else {
                $data = 'null';
                $this->view->msg = $this->t->_("Participant confirmation undone.");
            }
            $select = "UPDATE encontro_participante SET confirmado = ?,
                data_confirmacao = {$data} where id_pessoa = ? AND id_encontro = ?";
            $model->getAdapter()->query($select, array($confirmar, $id, $idEncontro));
            $this->view->ok = true;
        }
        catch(Exception $e) {
            $this->view->ok = false;
            $this->view->erro = "Ocorreu um erro inesperado ao marcar interesse em <b>evento</b>.<br/>Detalhes" . $e->getMessage();
        }
    }
}
