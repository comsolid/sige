<?php

class Admin_ParticipanteController extends Zend_Controller_Action {

   public function init() {
      if (!Zend_Auth::getInstance()->hasIdentity()) {
         $this->_helper->redirector->goToRoute(array(), 'login', true);
         return;
      }
      $sessao = Zend_Auth::getInstance()->getIdentity();
      if (!$sessao ["administrador"]) {
         $this->_helper->redirector->goToRoute(array(
             'controller' => 'participante',
             'action' => 'index'), 'default', true);
      }
   }

   public function indexAction() {
      $sessao = Zend_Auth::getInstance()->getIdentity();
      $idEncontro = $sessao ["idEncontro"];

      //$select = "SELECT p.id_pessoa, nome, apelido, email, twitter, nome_municipio, apelido_instituicao, nome_caravana FROM encontro_participante ep INNER JOIN pessoa p ON (ep.id_pessoa = p.id_pessoa) LEFT OUTER JOIN instituicao i ON (ep.id_instituicao = i.id_instituicao) INNER JOIN municipio m ON (ep.id_municipio = m.id_municipio) LEFT OUTER JOIN caravana c ON (ep.id_caravana = c.id_caravana) WHERE id_encontro = ? AND id_tipo_usuario = 3;";
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/tabela_sort.css'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-1.6.2.min.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery.dataTables.js'));
      //$this->view->headScript()->appendFile($this->view->baseUrl('/js/administrador/inicio.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/administrador/busca_pessoas.js'));
      $this->view->idEncontro = $idEncontro;
   }

   public function ajaxBuscaAction() {
      $this->_helper->layout()->disableLayout();
      $this->_helper->viewRenderer->setNoRender(true);
      $pessoas = new Application_Model_Pessoa ();
      $dataTodosUsuarios = array($this->_request->getParam("idEncontro", 0), $this->_request->getParam("nomePessoa"), $this->_request->getParam("tbusca"));
      $data = $pessoas->buscaPessoas($dataTodosUsuarios);

      $json = new stdClass; // objeto anonymous http://va.mu/cEGn
      
      $json->size = count($data);
      $json->aaData = array();
      
      foreach ($data as $value) {
         if ($value['confirmado']) {
            $isValidado = "Confimado!";
            $acao = '<a href=' . $this->view->baseUrl('/u/desfazer-confirmar/' . $value["id_pessoa"]) . '>Invalidar</a>';
         } else {
            $acao = '<a href=' . $this->view->baseUrl('/u/confirmar/' . $value["id_pessoa"]) . '>Validar</a>';
            $isValidado = "Não confimado!";
         }
         $json->aaData[] = array(
             "{$value ['nome']}",
             "{$value ['apelido']}",
             "{$value ['email']}",
             "{$value ['nome_municipio']}",
             "{$value ['apelido_instituicao']}",
             "{$value ['nome_caravana']}",
             $isValidado,
             $acao
             /* TODO: concatenar com= ' <a title=\"Adicione esse autor ao evento desejado!\" href=\"' . $this->view->url(array('controller' => 'administrador', 'action' => 'addautor', 'idautor' => $value ['id_pessoa']), null, true) . '\" >Add Autor</a>' */
         );
      }
      
      header("Pragma: no-cache");
      header("Cache: no-cahce");
      header("Cache-Control: no-cache, must-revalidate");
      header("Content-type: text/json");
      echo json_encode($json);
      return;
   }
   
   public function presencaAction() {
      $id = $this->_getParam('id', 0);
      $confirmar = $this->_getParam('confirmar', 'f');
      $sessao = Zend_Auth::getInstance()->getIdentity();
      $idEncontro = $sessao ["idEncontro"];
      $model = new Application_Model_Pessoa();
      if ($confirmar == 't') {
         $data = 'now()';
      } else {
         $data = 'null';
      }
      $select = "UPDATE encontro_participante SET confirmado = ?, 
         data_confirmacao = {$data} where id_pessoa = ? AND id_encontro = ?";
      $model->getAdapter()->fetchAll($select, array($confirmar, $id, $idEncontro));
      return $this->_helper->redirector->goToRoute(array(), 'inscricoes', true);
   }
}

