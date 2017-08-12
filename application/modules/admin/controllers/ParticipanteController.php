<?php

class Admin_ParticipanteController extends Sige_Controller_AdminAction {

    public function init() {
        $this->_helper->layout->setLayout('twbs3-admin/layout');
        $this->view->menu = new Sige_Desktop_AdminSidebarLeftMenu($this->view, 'registration');

        $this->_helper->getHelper('AjaxContext')
            ->addActionContext('ajax-buscar', 'json')
            ->addActionContext('presenca', 'json')
            ->addActionContext('ajax-buscar-nao-inscritos', 'json')
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

        $cache = Zend_Registry::get('cache_common');
        $ps = $cache->load('prefsis');
        $idEncontro = (int) $ps->encontro["id_encontro"];

        $pessoas = new Application_Model_Pessoa();
        $termo = $this->_request->getParam("termo");
        $buscar_por = $this->_request->getParam("buscar_por");
        $this->view->lista = $pessoas->buscaPessoas($idEncontro, $buscar_por, $termo);
    }

    /**
     * Mapeada como
     *    /pre-inscricao
     */
    public function preInscricaoAction()
    {
        $this->autenticacao();
        $this->view->menu = new Sige_Desktop_AdminSidebarLeftMenu($this->view, 'pre-registration');
        $this->view->title = $this->t->_('Pre-Registration');
        $this->view->subtitle = $this->t->_('Use for register and confirm participants manually');
    }

    public function ajaxBuscarNaoInscritosAction()
    {
        if (!$this->autenticacao(true)) {
            return;
        }

        $cache = Zend_Registry::get('cache_common');
        $ps = $cache->load('prefsis');
        $id_encontro = (int) $ps->encontro["id_encontro"];
        $pessoas = new Application_Model_Pessoa();
        $termo = $this->_request->getParam("termo");
        $buscar_por = $this->_request->getParam("buscar_por");
        $this->view->lista = $pessoas->buscarNaoInscritos($id_encontro, $buscar_por, $termo);
    }

    /**
     * Mapeada como:
     *    /u/confirmar/:id
     *    /u/desfazer-confirmar/:id
     *    /u/inscrever-confirmar/:id
     * @return type
     */
    public function presencaAction() {
        if (!$this->autenticacao(true)) {
            return;
        }

        $id = $this->_getParam('id', 0);
        $confirmar = $this->_getParam('confirmar', NULL);
        $cache = Zend_Registry::get('cache_common');
        $ps = $cache->load('prefsis');
        $idEncontro = (int) $ps->encontro["id_encontro"];
        $model = new Application_Model_Pessoa();
        try {
            if ($confirmar == NULL) {
                $ultimo = $model->buscarUltimoEncontro($id);
                $this->view->last = $ultimo;
                if (! $ultimo) throw new Exception($this->t->_('Participant never logged in or not confirm e-mail.'));

                $ultimo['id_encontro'] = $idEncontro;
                $ultimo['validado'] = 't';
                $ultimo['data_validacao'] = new Zend_Db_Expr('now()');
                $sql = "INSERT INTO encontro_participante (id_encontro, id_pessoa,
                    id_instituicao, id_municipio, validado, data_validacao,
                    confirmado, data_confirmacao) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    RETURNING confirmado, data_cadastro, data_confirmacao
                ";
                $expNow = new Zend_Db_Expr('now()');
                $result = $model->getAdapter()->query($sql, array(
                    $idEncontro,
                    $id,
                    $ultimo['id_instituicao'],
                    $ultimo['id_municipio'],
                    't',
                    $expNow,
                    't',
                    $expNow,
                ));
                $this->view->msg = $this->t->_("Participant registered and confirmed.");
            } else {
                if ($confirmar == 't') {
                    $data = 'now()';
                    $this->view->msg = $this->t->_("Participant confirmed.");
                } else {
                    $data = 'null';
                    $this->view->msg = $this->t->_("Participant confirmation undone.");
                }
                $sql = "UPDATE encontro_participante SET confirmado = ?,
                    data_confirmacao = {$data} where id_pessoa = ? AND id_encontro = ?
                    RETURNING confirmado, data_cadastro, data_confirmacao
                ";
                $result = $model->getAdapter()->query($sql, array($confirmar, $id, $idEncontro));
            }
            $this->view->ok = true;
            $this->view->result = $result->fetch();
        }
        catch(Exception $e) {
            $this->view->ok = false;
            $this->view->erro = "Ocorreu um erro inesperado.<br/>Detalhes: " . $e->getMessage();
        }
    }
}
