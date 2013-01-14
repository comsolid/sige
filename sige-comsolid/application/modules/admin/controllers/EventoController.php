<?php

class Admin_EventoController extends Zend_Controller_Action {

   public function init() {
      if (!Zend_Auth::getInstance()->hasIdentity()) {
         return $this->_helper->redirector->goToRoute(array(), 'login', true);
      }
      
      $sessao = Zend_Auth::getInstance()->getIdentity();
      if (! $sessao["administrador"]) {
         return $this->_helper->redirector->goToRoute(array('controller' => 'participante',
             'action' => 'index'), 'default', true);
      }
   }

   public function indexAction() {
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/tabela_sort.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/screen.css'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-1.6.2.min.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery.dataTables.js'));
      // $this->view->headScript()->appendFile($this->view->baseUrl('/js/caravana/inicio.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('/js/admin/evento/index.js'));

      $tipoEventos = new Application_Model_TipoEvento();
      $this->view->tipoEvento = $tipoEventos->fetchAll();
   }

   public function detalhesAction() {
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/tabela_sort.css'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-1.6.2.min.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('/js/administrador/teste.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery.dataTables.js'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/form.css'));
      //$this->view->headLink()->appendStylesheet($this->view->baseUrl('css/print.css'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/screen.css'));
      $this->view->headScript()->appendFile($this->view->baseUrl('/js/administrador/altera_palestrante.js'));

      $data = $this->getRequest()->getPost();

      $idEvento = $this->_request->getParam('id', 0);

      $evento = new Application_Model_Evento ();
      $data = $evento->buscaEventoPessoa($idEvento);
      $this->view->evento = $data[0];

      $this->view->idEvento = $idEvento;
      $this->view->nomeEvento = $data [0] ['nome_evento'];
      
      if ($data[0]['validada']) {
         $this->view->msg_situacao = "Invalidar";
         $this->view->url_situacao = "/admin/evento/invalidar/{$idEvento}";
      } else {
         $this->view->msg_situacao = "Validar";
         $this->view->url_situacao = "/admin/evento/validar/{$idEvento}";
      }

      $select = "SELECT evento, descricao, TO_CHAR(data, 'DD/MM/YYYY') AS data, TO_CHAR(hora_inicio, 'HH24:MI') as inicio, TO_CHAR(hora_fim, 'HH24:MI') as fim, nome_sala FROM evento_realizacao er INNER JOIN sala s ON (er.id_sala = s.id_sala) WHERE id_evento = ?";
      $data = $evento->getAdapter()->fetchAll($select, $idEvento);

      $this->view->horarios = $data;
   }
   
   /**
    * Mapeada como:
    *    /admin/evento/validar/:id
    *    /admin/evento/invalidar/:id
    */
   public function situacaoAction() {
      $idEvento = $this->_request->getParam('id', 0);
      $validar = $this->_getParam('validar', 'f');

      $evento = new Application_Model_Evento ();
      if ($validar == 't') {
         // TODO: criar apenas um método para validar ou invalidar
         $data = $evento->validaEvento($idEvento);
      } else {
         $data = $evento->invalidaEvento($idEvento);
      }
      $this->_helper->redirector->goToRoute(array(
          'module' => 'admin',
          'controller' => 'evento',
          'action' => 'detalhes',
          'id' => $idEvento), 'default');
   }
   
   public function ajaxBuscarAction() {
      $this->_helper->layout()->disableLayout();
      $this->_helper->viewRenderer->setNoRender(true);
      $sessao = Zend_Auth::getInstance()->getIdentity();
      $idEncontro = $sessao["idEncontro"];

      $eventos = new Application_Model_Evento();
      $data = array(
          intval($idEncontro), $this->_request->getParam("termo"), intval($this->_request->getParam("tipo")), intval($this->_request->getParam("situacao")));

      //var_dump($data);

      $rs = $eventos->buscaEventosAdmin($data);
      $json = new stdClass;
      $json->size = count($rs);
      $json->itens = array();
      
      foreach($rs as $value) {
         if ($value['validada']) {
            $validada = "Sim";
         } else {
            $validada = "Não";
         }
         
         $date = new Zend_Date($value['data_submissao']);
         
         $url = '<a href=' . $this->view->baseUrl('/admin/evento/detalhes/id/' . $value["id_evento"]) . '>Detalhes</a>';
         $json->itens[] = array(
             substr($value['nome_tipo_evento'], 0, 1),
             "{$value['nome_evento']}",
             "{$validada}",
             "{$date->toString("dd/MM/YYYY HH:mm")}",
             "{$value['nome']}",
             $url
         );
      }
      
      header("Pragma: no-cache");
      header("Cache: no-cahce");
      header("Cache-Control: no-cache, must-revalidate");
      header("Content-type: text/json");
      echo json_encode($json);
   }
}

