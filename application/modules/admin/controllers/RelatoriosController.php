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
         return $this->_helper->redirector->goToRoute(array('controller' => 'participante',
                     'action' => 'index'), 'default', true);
      }
      $this->view->menu = new Application_Form_Menu($this->view, 'admin', true);
   }

   public function indexAction() {
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/screen.css'));
   }
   
   public function inscricoesPorDiaAction() {
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/screen.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/morris.css'));
      
      $this->view->headScript()->appendFile($this->view->baseUrl('js/raphael-min.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/morris.min.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/sprintf-0.6.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/admin/relatorio/relatorio-utils.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/admin/relatorio/inscricoes-por-dia.js'));
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
      } catch (Exception $e) {
         $json->erro = "Ocorreu um erro inesperado ao salvar <b>tag</b>.<br/>Detalhes"
                    . $e->getMessage();
         $json->ok = false;
      }
      
      header("Pragma: no-cache");
      header("Cache: no-cahce");
      header("Cache-Control: no-cache, must-revalidate");
      header("Content-type: text/json");
      echo json_encode($json);
   }
   
   public function inscricoesHorarioAction() {
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/screen.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/morris.css'));
      
      $this->view->headScript()->appendFile($this->view->baseUrl('js/raphael-min.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/morris.min.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/sprintf-0.6.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/admin/relatorio/relatorio-utils.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/admin/relatorio/inscricoes-horario.js'));
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
         $json->erro = "Ocorreu um erro inesperado ao salvar <b>tag</b>.<br/>Detalhes"
                 . $e->getMessage();
         $json->ok = false;
      }

      header("Pragma: no-cache");
      header("Cache: no-cahce");
      header("Cache-Control: no-cache, must-revalidate");
      header("Content-type: text/json");
      echo json_encode($json);
   }
   
   public function inscricoesSexoAction() {
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/screen.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/morris.css'));
      
      $this->view->headScript()->appendFile($this->view->baseUrl('js/raphael-min.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/morris.min.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/sprintf-0.6.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/admin/relatorio/relatorio-utils.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/admin/relatorio/inscricoes-sexo.js'));
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
         $json->erro = "Ocorreu um erro inesperado ao salvar <b>tag</b>.<br/>Detalhes"
                 . $e->getMessage();
         $json->ok = false;
      }

      header("Pragma: no-cache");
      header("Cache: no-cahce");
      header("Cache-Control: no-cache, must-revalidate");
      header("Content-type: text/json");
      echo json_encode($json);
   }
   
   public function inscricoesMunicipioAction() {
		$model = new Admin_Model_EncontroParticipante();
		$config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'staging');
      $id_encontro = $config->encontro->codigo;
		$rs = $model->relatorioInscricoesMunicipio($id_encontro);
		$this->view->list = $rs;
	}
   
   public function inscricoesMunicipio15MaisAction() {
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/screen.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/morris.css'));
      
      $this->view->headScript()->appendFile($this->view->baseUrl('js/raphael-min.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/morris.min.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/sprintf-0.6.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/admin/relatorio/relatorio-utils.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/admin/relatorio/inscricoes-municipio-15-mais.js'));
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
      } catch (Exception $e) {
         $json->erro = "Ocorreu um erro inesperado ao salvar <b>tag</b>.<br/>Detalhes"
                 . $e->getMessage();
         $json->ok = false;
      }

      header("Pragma: no-cache");
      header("Cache: no-cahce");
      header("Cache-Control: no-cache, must-revalidate");
      header("Content-type: text/json");
      echo json_encode($json);
   }
}

