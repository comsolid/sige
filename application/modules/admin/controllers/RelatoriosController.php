<?php
class Admin_RelatoriosController extends Zend_Controller_Action {

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
        $this->view->menu = new Sige_Desktop_AdminSidebarLeftMenu($this->view, 'reports');
    }

    public function indexAction() {
        $this->view->title = _('Conference Reports');
    }

    public function inscricoesPorDiaAction() {
        $this->view->title = _('Registrations per day');
        $this->view->subtitle = _('Reports');
    }

    public function ajaxInscricoesPorDiaAction() {
        $this->_helper->layout()->disableLayout();
        $this->_helper->viewRenderer->setNoRender(true);

        $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'staging');
        $idEncontro = $config->encontro->codigo;

        $model = new Admin_Model_EncontroParticipante();
        try {
            $rs = $model->relatorioIncricoesPorDia($idEncontro);
            $json = new stdClass;
            $json->size = count($rs);
            $json->array = array();
            $json->ok = true;
            foreach ($rs as $value) {
                $obj = new stdClass;
                $obj->data = "{$value['data']}";
                $obj->num = "{$value['num']}";
                array_push($json->array, $obj);
            }
        }
        catch(Exception $e) {
            $json->error = "Ocorreu um erro inesperado.<br/>Detalhes: " . $e->getMessage();
            $json->ok = false;
        }

        header("Pragma: no-cache");
        header("Cache: no-cache");
        header("Cache-Control: no-cache, must-revalidate");
        header("Content-type: text/json");
        echo json_encode($json);
    }

    public function inscricoesHorarioAction() {
        $this->view->title = _('Registrations per hour of day');
        $this->view->subtitle = _('Reports');
    }

    public function ajaxInscricoesHorarioAction() {
        $this->_helper->layout()->disableLayout();
        $this->_helper->viewRenderer->setNoRender(true);

        $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'staging');
        $idEncontro = $config->encontro->codigo;

        $model = new Admin_Model_EncontroParticipante();
        try {
            $rs = $model->relatorioInscricoesHorario($idEncontro);
            $json = new stdClass;
            $json->size = count($rs);
            $json->array = array();
            $json->ok = true;
            foreach ($rs as $value) {
                $obj = new stdClass;
                $obj->horario = "{$value['horario']}";
                $obj->num = "{$value['num']}";
                array_push($json->array, $obj);
            }
        } catch (Exception $e) {
            $json->error = "Ocorreu um erro inesperado.<br/>Detalhes: " . $e->getMessage();
            $json->ok = false;
        }

        header("Pragma: no-cache");
        header("Cache: no-cache");
        header("Cache-Control: no-cache, must-revalidate");
        header("Content-type: text/json");
        echo json_encode($json);
    }

    public function inscricoesSexoAction() {
        $this->view->title = _('Registrations per gender');
        $this->view->subtitle = _('Reports');
    }

    public function ajaxInscricoesSexoAction() {
        $this->_helper->layout()->disableLayout();
        $this->_helper->viewRenderer->setNoRender(true);

        $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'staging');
        $idEncontro = $config->encontro->codigo;

        $model = new Admin_Model_EncontroParticipante();
        try {
            $rs = $model->relatorioInscricoesSexo($idEncontro);
            $json = new stdClass;
            $json->size = count($rs);
            $json->array = array();
            $json->ok = true;
            foreach ($rs as $value) {
                $obj = new stdClass;
                $obj->value = (int) $value['num'];
                $obj->label = "{$value['sexo']}";
                array_push($json->array, $obj);
            }
        } catch (Exception $e) {
            $json->error = "Ocorreu um erro inesperado.<br/>Detalhes: " . $e->getMessage();
            $json->ok = false;
        }

        header("Pragma: no-cache");
        header("Cache: no-cache");
        header("Cache-Control: no-cache, must-revalidate");
        header("Content-type: text/json");
        echo json_encode($json);
    }

    public function inscricoesMunicipioAction() {
        $this->view->title = _('Registrations per district (All)');
        $this->view->subtitle = _('Reports');

        $model = new Admin_Model_EncontroParticipante();
        $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'staging');
        $id_encontro = $config->encontro->codigo;
        $rs = $model->relatorioInscricoesMunicipio($id_encontro);
        $this->view->list = $rs;
    }

    public function inscricoesMunicipio15MaisAction() {
        $this->view->title = _('Registrations per district (15+)');
        $this->view->subtitle = _('Reports');
    }

    public function ajaxInscricoesMunicipio15MaisAction() {
        $this->_helper->layout()->disableLayout();
        $this->_helper->viewRenderer->setNoRender(true);

        $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'staging');
        $idEncontro = $config->encontro->codigo;

        $model = new Admin_Model_EncontroParticipante();
        try {
            $limit = 15;
            $rs = $model->relatorioInscricoesMunicipio($idEncontro, $limit);
            $json = new stdClass;
            $json->size = count($rs);
            $json->array = array();
            $json->ok = true;
            foreach ($rs as $value) {
                $obj = new stdClass;
                $obj->municipio = "{$value['municipio']}";
                $obj->num = "{$value['num']}";
                $obj->confirmados = "{$value['confirmados']}";
                array_push($json->array, $obj);
            }
        }
        catch(Exception $e) {
            $json->error = "Ocorreu um erro inesperado.<br/>Detalhes: " . $e->getMessage();
            $json->ok = false;
        }

        header("Pragma: no-cache");
        header("Cache: no-cache");
        header("Cache-Control: no-cache, must-revalidate");
        header("Content-type: text/json");
        echo json_encode($json);
    }

    public function artigosListaPdfAction() {
        $this->_helper->layout()->disableLayout();
        $this->_helper->viewRenderer->setNoRender(true);

        $ano = (int) $this->getRequest()->getParam("ano", 0);
        $status = $this->getRequest()->getParam("status");
        if ($ano < 1980) {
            $this->_helper->flashMessenger->addMessage(array(
                'error' => "Ano inválido. Comece de novo. "
                . "Caso o erro persista, contate o administrador."));
            return $this->_helper->redirector->goToRoute(array(), 'default', true);
        }

        $model_encontro = new Application_Model_Encontro();
        $encontros = $model_encontro->buscaEncontrosPorAno($ano);
        if (empty($encontros)) {
            $this->_helper->flashMessenger->addMessage(
                    array('warning' => "Nenhum encontro cadastrado para o ano {$ano}."));
            return $this->_helper->redirector->goToRoute(array(
                        'module' => 'admin',
                        'controller' => 'relatorios',
                        'action' => 'index'), 'default', true);
        }
        // Compativel com PHP < 5.5
        $id_encontros_array = array();
        foreach ($encontros as $encontro) {
            array_push($id_encontros_array, $encontro["id_encontro"]);
        }
        // PHP >= 5.5
//        $id_encontros_array = array_column($encontros, "id_encontro"); 

        $model_artigo = new Application_Model_Artigo();
        $rel = $model_artigo->buscaArtigos($id_encontros_array, $status);
        if (empty($rel)) {
            $this->_helper->flashMessenger->addMessage(
                    array("alert" => "O relatório não possui nenhum registro."));
            return $this->_helper->redirector->goToRoute(array(
                        'module' => 'admin',
                        'controller' => 'relatorios',
                        'action' => 'index'), 'default', true);
        }

        $pdf = new Sige_Pdf_Relatorio_ArtigosLista($rel, array(
            "ano" => $ano,
            "status" => $status,
        ));
        try {
            $pdf->gerarPdf();
        } catch (Exception $e) {
            throw new Exception("Erro ao gerar PDF: " . $e->getMessage());
        }
    }

    public function artigosListaXlsAction() {
        $ano = (int) $this->getRequest()->getParam("ano", 0);
        $status = $this->getRequest()->getParam("status");
        if ($ano < 1980) {
            $this->_helper->flashMessenger->addMessage(array(
                'error' => "Ano inválido. Comece de novo. "
                . "Caso o erro persista, contate o administrador."));
            return $this->_helper->redirector->goToRoute(array(), 'default', true);
        }

        $model_encontro = new Application_Model_Encontro();
        $encontros = $model_encontro->buscaEncontrosPorAno($ano);
        if (empty($encontros)) {
            $this->_helper->flashMessenger->addMessage(
                    array('warning' => "Nenhum encontro cadastrado para o ano {$ano}."));
            return $this->_helper->redirector->goToRoute(array(
                        'module' => 'admin',
                        'controller' => 'relatorios',
                        'action' => 'index'), 'default', true);
        }
        // Compativel com PHP < 5.5
        $id_encontros_array = array();
        foreach ($encontros as $encontro) {
            array_push($id_encontros_array, $encontro["id_encontro"]);
        }
        // PHP >= 5.5
//        $id_encontros_array = array_column($encontros, "id_encontro"); 

        $model_artigo = new Application_Model_Artigo();
        $rel = $model_artigo->buscaArtigos($id_encontros_array, $status);
        if (empty($rel)) {
            $this->_helper->flashMessenger->addMessage(
                    array("alert" => "O relatório não possui nenhum registro."));
            return $this->_helper->redirector->goToRoute(array(
                        'module' => 'admin',
                        'controller' => 'relatorios',
                        'action' => 'index'), 'default', true);
        }

        $xls = new Sige_Xls_Exportar($rel, array(
            'apelido_encontro',
            'titulo',
            'nome',
            'email',
                ), array(
            'Evento',
            'Título',
            'Nome',
            'E-mail',
        ));
        $this->_helper->layout->disableLayout();
        $this->_helper->viewRenderer->setNoRender();

        $xls->exportar("relatorio_artigos_sige_" . date("Y-m-d-His") . ".xls");
    }

    public function inscricoesListaXlsAction() {
        $this->_helper->layout()->disableLayout();
        $this->_helper->viewRenderer->setNoRender(true);

        $id_encontro = (int) $this->getRequest()->getParam("id_encontro", 0);
        $status = $this->getRequest()->getParam("status");
        if ($id_encontro < 1) {
            $this->_helper->flashMessenger->addMessage(array(
                'error' => "Encontro inválido. Comece de novo. "
                . "Caso o erro persista, contate o administrador."));
            return $this->_helper->redirector->goToRoute(array(), 'default', true);
        }

        $model_pessoa = new Application_Model_Pessoa();
        switch ($status) {
            case "confirmadas":
                // inscrições confirmadas
                $rel = $model_pessoa->buscaParticipantes($id_encontro, "ep.confirmado='t'");
                break;
            case "nao-confirmadas":
                // inscrições não confirmadas
                $rel = $model_pessoa->buscaParticipantes($id_encontro, "ep.confirmado='f'");
                break;
            default:
                $status = "todas";
                // todas as inscrições
                $rel = $model_pessoa->buscaParticipantes($id_encontro);
                break;
        }

        $model_encontro = new Application_Model_Encontro();
        $encontro = $model_encontro->fetchRow("id_encontro = {$id_encontro}");

        if (empty($encontro)) {
            $this->_helper->flashMessenger->addMessage(
                    array('error' => "Encontro ($encontro) inexistente."));
            return $this->_helper->redirector->goToRoute(array(
                        'module' => 'admin',
                        'controller' => 'relatorios',
                        'action' => 'index'), 'default', true);
        }
        if (empty($rel)) {
            $this->_helper->flashMessenger->addMessage(
                    array("alert" => "O relatório não possui nenhum registro."));
            return $this->_helper->redirector->goToRoute(array(
                        'module' => 'admin',
                        'controller' => 'relatorios',
                        'action' => 'index'), 'default', true);
        }

        $xls = new Sige_Xls_Exportar($rel, array(
            'nome',
            'email',
            'nome_municipio',
            'confirmado',
                ), array(
            'Nome',
            'E-mail',
            'Município',
            'Confirmado?',
            'Obs.',
        ));
        $this->_helper->layout->disableLayout();
        $this->_helper->viewRenderer->setNoRender();

        $xls->exportar("relatorio_inscricoes_sige_" . date("Y-m-d-His") . ".xls");
    }

    public function inscricoesListaPdfAction() {
        $id_encontro = (int) $this->getRequest()->getParam("id_encontro", 0);
        $status = $this->getRequest()->getParam("status");
        if ($id_encontro < 1) {
            $this->_helper->flashMessenger->addMessage(array(
                'error' => "Encontro inválido. Comece de novo. "
                . "Caso o erro persista, contate o administrador."));
            return $this->_helper->redirector->goToRoute(array(), 'default', true);
        }

        $model_pessoa = new Application_Model_Pessoa();
        switch ($status) {
            case "confirmadas":
                // inscrições confirmadas
                $rel = $model_pessoa->buscaParticipantes($id_encontro, "ep.confirmado='t'");
                break;
            case "nao-confirmadas":
                // inscrições não confirmadas
                $rel = $model_pessoa->buscaParticipantes($id_encontro, "ep.confirmado='f'");
                break;
            default:
                $status = "todas";
                // todas as inscrições
                $rel = $model_pessoa->buscaParticipantes($id_encontro);
                break;
        }

        $model_encontro = new Application_Model_Encontro();
        $encontro = $model_encontro->fetchRow("id_encontro = {$id_encontro}");

        if (empty($encontro)) {
            $this->_helper->flashMessenger->addMessage(
                    array('error' => "Encontro ($encontro) inexistente."));
            return $this->_helper->redirector->goToRoute(array(
                        'module' => 'admin',
                        'controller' => 'relatorios',
                        'action' => 'index'), 'default', true);
        }
        if (empty($rel)) {
            $this->_helper->flashMessenger->addMessage(
                    array("alert" => "O relatório não possui nenhum registro."));
            return $this->_helper->redirector->goToRoute(array(
                        'module' => 'admin',
                        'controller' => 'relatorios',
                        'action' => 'index'), 'default', true);
        }

        $pdf = new Sige_Pdf_Relatorio_InscricaoEncontro($rel, array(
            "apelido_encontro" => $encontro["apelido_encontro"],
            "status" => $status,
        ));
        try {
            $pdf->gerarPdf();
        } catch (Exception $e) {
            throw new Exception("Erro ao gerar PDF: " . $e->getMessage());
        }
    }

}
