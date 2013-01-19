<?php

class CaravanaController extends Zend_Controller_Action {

   public function init() {
      $this->view->menu = new Application_Form_Menu($this->view, 'caravana');
      if (!Zend_Auth :: getInstance()->hasIdentity()) {
         return $this->_helper->redirector->goToRoute(array(), 'login', true);
      }
   }

   public function indexAction() {

      $sessao = Zend_Auth::getInstance()->getIdentity();

      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/tabela_sort.css'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-1.6.2.min.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery.dataTables.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/caravana/index.js'));

      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/caravana/index.css'));
      $participante = new Application_Model_Participante();
      
      // @deprecated use sairAction
      if ($this->_request->getParam("sair") == 'caravana') {
         //echo $sessao["idEncontro"] . "rererere" . $sessao["idPessoa"];
         $participante->sairDaCaravana(array($sessao["idEncontro"], $sessao["idPessoa"]));
      }
      if ($this->_request->getParam("caravana_resp") == 'exclu' && intval($this->_request->getParam("idcaravana")) > 0) {
         $participante->excluirMinhaCaravanaResponsavel(array($sessao["idEncontro"], $this->_request->getParam("idcaravana")));
      }
      $participante1 = $participante->getMinhaCaravana(array($sessao["idEncontro"], $sessao["idPessoa"]));
      if (count($participante1) > 0) {
         $this->view->participante = $participante1[0];
      }
      $this->view->caravanaResponsavel = $participante->getMinhasCaravanaResponsavel(array($sessao["idEncontro"], $sessao["idPessoa"]));
   }

   public function participantesAction() {
      $cancelar = $this->getRequest()->getPost('cancelar');
      if (isset($cancelar)) {
         return $this->_helper->redirector->goToRoute(array(
                     'controller' => 'caravana',
                     'action' => 'index'
                         ), null, true);
      }
      
      $sessao = Zend_Auth::getInstance()->getIdentity();
      $idPessoa = $sessao["idPessoa"];
      $idEncontro = $sessao["idEncontro"];
      
      $participante = new Application_Model_Participante();
      $rs = $participante->getMinhasCaravanaResponsavel(array($idEncontro, $idPessoa));
      $this->view->caravana = $rs[0];
      
      $caravanaEncontro = new Application_Model_CaravanaEncontro();
      
      if ($this->getRequest()->isPost()) {
         $del = $this->getRequest()->getPost('del');
         if ($del == "confimar") {
            $array_id_pessoas = explode(",", $this->getRequest()->getPost('array_id_pessoas'));
            // se existirem e-mail a serem adicionados a caravana
            // explode retorna array(0 => "") http://php.net/manual/pt_BR/function.explode.php
            if (count($array_id_pessoas) == 1 && empty($array_id_pessoas[0])) {
               $this->_helper->flashMessenger->addMessage(
                        array('notice' => 'Nenhum participante foi selecionado.'));
            } else {
               $where = array(
                   $this->view->caravana['id_caravana'],
                   $sessao["idEncontro"],
                   $sessao["idEncontro"], // id_encontro usado em subquery
               );
               $where = array_merge($where, $array_id_pessoas);
               try {
                  $caravanaEncontro->updateParticipantesCaravana($where);
                  $this->_helper->flashMessenger->addMessage(
                          array('success' => 'Participantes adicionados à caravana com sucesso.'));
               } catch (Exception $e) {
                  $this->_helper->flashMessenger->addMessage(
                          array('error' => 'Ocorreu um erro inesperado.<br/>Detalhes: '
                              . $e->getMessage()));
               }
            }
         }
      }
      
      $this->view->participantes = $caravanaEncontro->buscaParticipantes($this->view->caravana['id_caravana'], $sessao["idEncontro"]);
   }
   
   public function ajaxBuscarParticipanteAction() {
      $this->_helper->layout()->disableLayout();
      $this->_helper->viewRenderer->setNoRender(true);
      $sessao = Zend_Auth::getInstance()->getIdentity();
      $idPessoa = $sessao["idPessoa"];
      $idEncontro = $sessao["idEncontro"];
      
      $model = new Application_Model_Pessoa();
      $termo = $this->_request->getParam("termo", "");
      
      $json = new stdClass;
      $json->results = array();
      
      $rs = $model->getAdapter()->fetchAll(
         "SELECT p.id_pessoa,
               p.email
         FROM pessoa p
         INNER JOIN encontro_participante ep ON p.id_pessoa = ep.id_pessoa
         WHERE p.email LIKE lower(?)
         AND p.id_pessoa <> ?
         AND ep.id_encontro = ?
         AND ep.id_caravana IS NULL
         AND ep.validado = true ",
              array("{$termo}%", $idPessoa, $idEncontro));
      foreach ($rs as $value) {
         $obj = new stdClass;
         $obj->id = "{$value['id_pessoa']}";
         $obj->text = "{$value['email']}";
         array_push($json->results, $obj);
      }
      
      header("Pragma: no-cache");
      header("Cache: no-cahce");
      header("Cache-Control: no-cache, must-revalidate");
      header("Content-type: text/json");
      echo json_encode($json);
   }
   
   public function deletarParticipanteAction() {
      $this->_helper->layout()->disableLayout();
      $this->_helper->viewRenderer->setNoRender(true);
      
      $pessoa = $this->_getParam('pessoa', 0);
      if ($pessoa > 0) {
         $sessao = Zend_Auth::getInstance()->getIdentity();
         $where = array(
             $sessao["idEncontro"],
             $pessoa
         );
         $model = new Application_Model_CaravanaEncontro();
         try {
            $model->removeParticipanteNaCaravana($where);
            $this->_helper->flashMessenger->addMessage(
                             array('success' => 'Participante removido da caravana com sucesso.'));
         } catch (Exception $e) {
               $this->_helper->flashMessenger->addMessage(
                       array('error' => 'Ocorreu um erro inesperado.<br/>Detalhes: '
                           . $e->getMessage()));
         }
      } else {
         $this->_helper->flashMessenger->addMessage(
                        array('notice' => 'Nenhum participante foi selecionado.'));
      }
      $this->_helper->redirector->goToRoute(array('controller' => 'caravana',
          'action' => 'participantes'), 'default', true);
   }
   
   public function sairAction() {
      $this->_helper->layout()->disableLayout();
      $this->_helper->viewRenderer->setNoRender(true);
      
      $sessao = Zend_Auth::getInstance()->getIdentity();
      $model = new Application_Model_Participante();
      try {
         $model->sairDaCaravana(array($sessao["idEncontro"], $sessao["idPessoa"]));
         $this->_helper->flashMessenger->addMessage(
                 array('success' => 'Participante removido da caravana com sucesso.'));
      } catch (Exception $e) {
         $this->_helper->flashMessenger->addMessage(
                 array('error' => 'Ocorreu um erro inesperado.<br/>Detalhes: '
                     . $e->getMessage()));
      }
      $this->_helper->redirector->goToRoute(array('controller' => 'caravana',
              'action' => 'index'), null, true);
   }

   /**
    * @deprecated 
    */
   public function addparticipanteAction() {
      $this->deprecated("caravana", "addparticipante");
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/caravana/index.css'));
      $emailInvalidos = null;
      $sessao = Zend_Auth :: getInstance()->getIdentity();
      $participante = new Application_Model_Participante();
      $this->view->item = $participante->getMinhasCaravanaResponsavel(array($sessao["idEncontro"], $sessao["idPessoa"]));
      $this->view->item = $this->view->item[0];
      $caravanaEncontro = new Application_Model_CaravanaEncontro();
      if (is_numeric($this->_request->ex)) {
         $participa[0] = $sessao["idEncontro"];
         $participa[1] = intVal($this->_request->ex);
         $caravanaEncontro->removeParticipanteNaCaravana($participa);
      }
      $form = new Application_Form_AddPartCaravana();
      $data = $this->getRequest()->getPost();

      if ($this->getRequest()->isPost() && $form->isValid($data)) {

         $arrayEmail = explode(",", $this->_request->participantes);

         $validator = new Zend_Validate_EmailAddress();
         $cont = 0;
         $quant = count($arrayEmail);
         for ($i = 0; $i < $quant; $i = $i + 1) {
            if (!$validator->isValid($arrayEmail[$i])) {

               $emailInvalidos[$cont] = $arrayEmail[$i];
               unset($arrayEmail[$i]);
               $cont = $cont + 1;
            }
         }
         $participantes[0] = $this->view->item['id_caravana'];
         $participantes[1] = $sessao["idEncontro"];
         $participantes[2] = $sessao["idEncontro"];
         $participantes = array_merge($participantes, $arrayEmail);
         $participantes +=$arrayEmail;
         if (count($arrayEmail) > 0)
            $caravanaEncontro->addParticipantesNaCaravana($participantes);
         if (count($emailInvalidos) > 0) {
            $this->view->emailInvalidos = "<fieldset><legend>Esses email são inválidos</legend>";
            foreach ($emailInvalidos as $email) {
               $this->view->emailInvalidos.= "<span>$email</span><br/>";
            }
            $this->view->emailInvalidos.="</fieldset>";
         }
         $quant = count($arrayEmail);
         for ($i = 0; $i < $quant; $i = $i + 1) {
            if ($participante->isParticipantes(array($arrayEmail[$i]))) {
               unset($arrayEmail[$i]);
            }
         }
         if (count($arrayEmail) > 0) {
            $form->getElement('participantes')->setDescription("Clique em confirmar para convidar essas pessoas");
         }
         $data['participantes'] = implode(',', $arrayEmail);
         $form->populate($data);
      }
      $this->view->form = $form;
      $this->view->caravanaPartici = $caravanaEncontro->buscaParticipantes($this->view->item['id_caravana'], $sessao["idEncontro"]);
   }

   public function criarAction() {

      $data = $this->getRequest()->getPost();
      if (isset($data['cancelar'])) {
         return $this->_helper->redirector->goToRoute(array(
                     'controller' => 'caravana',
                     'action' => 'index'
                         ), null, true);
      }
      $sessao = Zend_Auth::getInstance()->getIdentity();
      $idPessoa = $sessao["idPessoa"];
      $idEncontro = $sessao["idEncontro"];
      
      $caravana = new Application_Model_Caravana();

      if ($caravana->verificaCaravana($idPessoa, $idEncontro)) {
         return $this->_helper->redirector->goToRoute(array(
                     'controller' => 'caravana',
                     'action' => 'editar'), null, true);
      } else {

         $form = new Application_Form_Caravana();
         $form->setAction($this->view->url(array('controller' => 'caravana', 'action' => 'criar')));

         $this->view->form = $form;
         $data = $this->getRequest()->getPost();

         $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/form.css'));

         if ($this->getRequest()->isPost() && $form->isValid($data)) {
            $caravana = new Application_Model_Caravana();
            $caravana_encontro = new Application_Model_CaravanaEncontro();
            $data = $form->getValues();
            
            $adapter = $caravana->getAdapter();
            try {
               $adapter->beginTransaction();
               $m_encontro = new Application_Model_Encontro();
               $data['criador'] = $idPessoa;

               $data2['id_encontro'] = $m_encontro->getEncontroAtual();
               $data2['responsavel'] = $idPessoa;
               $data2['id_caravana'] = $caravana->insert($data);



               $caravana_encontro->insert($data2);
               $adapter->commit();
               return $this->_helper->redirector->goToRoute(array(
                           'controller' => 'caravana',
                           'action' => 'index'
                               ), null, true);
            } catch (Zend_Db_Exception $ex) {
               $adapter->rollBack();
               // 23505UNIQUE VIOLATION
               if ($ex->getCode() == 23505) {
                  $this->_helper->flashMessenger->addMessage(
                          array('error' => 'Já existe uma caravana com esta descrição.'));
               } else {
                  $this->_helper->flashMessenger->addMessage(
                          array('error' => 'Ocorreu um erro inesperado.<br/>Detalhes: '
                              . $ex->getMessage()));
               }
            }
         }
      }
   }

   public function editarAction() {

      $data = $this->getRequest()->getPost();
      if (isset($data['cancelar'])) {
         return $this->_helper->redirector->goToRoute(array(
                     'controller' => 'caravana',
                     'action' => 'index'
                         ), null, true);
      }

      $sessao = Zend_Auth :: getInstance()->getIdentity();
      $idPessoa = $sessao["idPessoa"];
      $idEncontro = $sessao["idEncontro"];


      $form = new Application_Form_Caravana();
      $form->setAction($this->view->url(array('controller' => 'caravana', 'action' => 'editar')));
      $this->view->form = $form;
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/form.css'));

      $caravana = new Application_Model_Caravana();
      $participante = new Application_Model_Participante();
      $caravana_encontro = new Application_Model_CaravanaEncontro();
      $pessoa = new Application_Model_Pessoa();

      $pessoa = $pessoa->find($idPessoa); //mandar ainda  o nome do criador para a view	
      $select = $caravana_encontro->select();
      $rows = $caravana_encontro->fetchAll($select->where('responsavel = ?', $idPessoa)->where('id_encontro = ?', $idEncontro));
      $rows = $rows[0];

      $select = $caravana->select();
      $dados_caravana = $caravana->find($rows['id_caravana']);

      $dados_caravana = $dados_caravana[0];

      $idCaravana = $rows['id_caravana'];

      $participantes = $caravana_encontro->buscaParticipantes($idCaravana, $idEncontro);

      $this->view->participantes = array();
      $this->view->participantes[] = $participantes;

      $form->populate($dados_caravana->toArray());


      $data = $this->getRequest()->getPost();

      if ($this->getRequest()->isPost() && $form->isValid($data)) {

         $data = $form->getValues();

         $select = $caravana->getAdapter()->quoteInto('id_caravana = ?', $dados_caravana['id_caravana']);

         try {
            $caravana->update($data, $select);

            return $this->_helper->redirector->goToRoute(array(
                        'controller' => 'caravana',
                        'action' => 'index'
                            ), null, true);
         } catch (Zend_Db_Exception $ex) {
            // 23505 UNIQUE VIOLATION
            if ($ex->getCode() == 23505) {
               $this->_helper->flashMessenger->addMessage(
                       array('error' => 'Já existe uma caravana com esta descrição.'));
            } else {
               $this->_helper->flashMessenger->addMessage(
                       array('error' => 'Ocorreu um erro inesperado.<br/>Detalhes: '
                           . $ex->getMessage()));
            }
         }
      }
   }

   public function buscaAction() {
      $sessao = Zend_Auth :: getInstance()->getIdentity();
      $idEncontro = $sessao["idEncontro"];
      $this->_helper->layout()->disableLayout();

      $caravana = new Application_Model_Caravana();

      $data = array(intval($idEncontro), $this->_request->getParam("nome_caravana"));

      //var_dump($data);
      $dataCaravana = $caravana->busca($data);

      //print_r($dataCaravana);
      $e = '<?xml version="1.0"?><busca><tbody id="resultadoCaravana"><![CDATA[';
      if (isset($dataCaravana))
         foreach ($dataCaravana as $value) {
            $validadaCaravana = "";
            if ($value['validada']) {
               $validadaCaravana = "TRUE";
            } else {
               $validadaCaravana = "FALSE";
            }

            $idCaravana = $value['id_caravana'];

            $e .= '<tr>
                    <td>' . $value['nome_caravana'] . '</td>
                    <td>' . $value['apelido_caravana'] . '</td>
                    <td>' . $value['nome'] . '</td>
                    <td>' . $value['nome_municipio'] . '</td>
                    <td>' . $value['apelido_instituicao'] . '</td>
                    <td>' . $validadaCaravana . '</td>
                    <td>' . $value['count'] . '</td>
                    <td><a href=' . $this->view->baseUrl('/administrador/validacaravana/id_caravana/' . $value["id_caravana"]) . '>Validar</a><td>		
                    <td><a href=' . $this->view->baseUrl('/administrador/invalidacaravana/id_caravana/' . $value["id_caravana"]) . '>invalidar</a><td>		
                </tr>';

            //<a href="<? echo $this->baseUrl('/administrador/validaCaravana/id_caravana/'.$value['id_caravana'])
            //	echo $value['nome_tipo_evento'];
         }//id="'.$value['id_caravana'].'"

      $this->getResponse()->setHeader('Content-Type', 'text/xml');
      $e .= ']]></tbody></busca>';

      echo $e;
   }

   private function deprecated($controller, $view) {
      $this->view->deprecated = "You are using a deprecated controller/view: {$controller}/{$view}";
   }

}

?>
