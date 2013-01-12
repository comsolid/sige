<?php

class Admin_HorarioController extends Zend_Controller_Action {

   public function init() {
      /* Initialize action controller here */
   }

   public function criarAction() {
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/tabela_sort.css'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-1.6.2.min.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery.dataTables.js'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/form.css'));

      $idEvento = $this->_request->getParam('id');
      $nomeEvento = $this->_request->getParam('nome_evento');

      $form = new Application_Form_Horarios();
      $form->setDescricao($nomeEvento);
      $form->cria();
      $this->view->form = $form;

      $model = new Application_Model_EventoRealizacao();
      $select = "SELECT TO_CHAR(data, 'DD/MM/YYYY') as data, TO_CHAR(hora_inicio, 'HH24:MI') as hora_inicio, TO_CHAR(hora_fim, 'HH24:MI') as hora_fim FROM evento_realizacao WHERE id_evento = ?";

      $this->view->idEvento = $idEvento;
      $this->view->horariosEventos = $model->getAdapter()->fetchAll($select, $idEvento);

      $data = $this->getRequest()->getPost();
      if ($this->getRequest()->isPost() && $form->isValid($data)) {
         $data = $form->getValues();
         //unset($data['horarios']);
         $data['id_evento'] = $idEvento;
         
         try {
            // TODO: verificar se já existem horários no mesmo dia, na mesma sala
            // antes de salvar.
            $sessao = Zend_Auth::getInstance()->getIdentity();
            $idEncontro = $sessao ["idEncontro"];
            $existe = $model->existeHorario(array(
                $idEncontro,
                $data['id_sala'],
                $data['data'],
                $data['hora_inicio'],
                $data['hora_fim']
            ));
            
            if (! $existe) {
               $model->insert($data);
               return $this->_helper->redirector->goToRoute(array(
                           'module' => 'admin',
                           'controller' => 'evento',
                           'action' => 'detalhes',
                           'id' => $idEvento), 'default', true);
            } else {
               echo "Já existe um evento no mesmo dia, mesma sala e mesmo horário.";
            }
         } catch (Exception $e) {
            echo $e->getMessage();
         }
         
         /* $dataHorario = array ();

           foreach ( $data as $chave => $item ) {
           if ($chave != "descricao" && $chave != "salas" && $chave != "data" && $item != "0") {
           $dataHorario [] = $item;
           }
           }

           $confirmaHorario = true;

           foreach ( $dataHorario as $h ) {
           $ok = true;
           $horarios = split ( "_", $h );

           $horariosConfirmado = $evento->fetchAll ();

           foreach ( $horariosConfirmado as $item ) {

           if ($item->id_sala == $data ["salas"] && $item->data == $data ["data"] && $item->hora_inicio == $horarios [0]) {
           $confirmaHorario = false;
           $ok = false;
           $sala = $item->findDependentRowset('Application_Model_Sala')->current()->nome_sala;
           $e = $item->findDependentRowset('Application_Model_Evento')->current()->nome_evento;

           echo "O evento $nomeEvento no hórario de $horarios[0] às $horarios[1] no dia $item->data<br>, não pode ser escolhido, já haverá o evento $e nesse hórario<br><br>";

           break;
           }

           }

           if ($ok) {
           $dadosEvento = array ('id_evento' => $idEvento, 'id_sala' => $data ["salas"], 'data' => $data ["data"], 'hora_inicio' => $horarios [0], 'hora_fim' => $horarios [1], 'descricao' => $nomeEvento );

           $id = $evento->insert ( $dadosEvento );

           $select = "INSERT INTO evento_realizacao_multipla (evento, data, hora_inicio, hora_fim) VALUES (?,?,?,?)";

           $evento->getAdapter ()->fetchAll ($select, array($id,$data["data"],$horarios [0],$horarios [1]));


           echo "O evento $nomeEvento foi adicinado no hórario de $horarios[0] às $horarios[1] no dia $item->data<br>";
           }

           }

           if ($confirmaHorario) {
           return $this->_helper->redirector->goToRoute ( array ('controller' => 'administrador', 'action' => 'verdetalhesevento', 'id_evento' => $idEvento ), null, true );
           } */
      }
   }

   public function editarAction() {
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/tabela_sort.css'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery-1.6.2.min.js'));
      $this->view->headScript()->appendFile($this->view->baseUrl('js/jquery.dataTables.js'));
      $this->view->headLink()->appendStylesheet($this->view->baseUrl('css/form.css'));

      $form = new Application_Form_Horarios();
      $form->cria();
      $this->view->form = $form;
      
      $model = new Application_Model_EventoRealizacao();
      $evento = $this->_request->getParam('evento', 0);

      if ($this->getRequest()->isPost()) {
         $formData = $this->getRequest()->getPost();
         if ($form->isValid($formData)) {
            $id = $this->_request->getParam('id', 0);
            $data = $form->getValues();
            $data['id_evento'] = $evento;

            try {
               $sessao = Zend_Auth::getInstance()->getIdentity();
               $idEncontro = $sessao ["idEncontro"];
               $existe = $model->existeHorario(array(
                  $idEncontro,
                  $data['id_sala'],
                  $data['data'],
                  $data['hora_inicio'],
                  $data['hora_fim']
               ));
               
               if (! $existe) {
                  $model->update($data, 'evento = ' . $id);
                  return $this->_helper->redirector->goToRoute(array(
                              'module' => 'admin',
                              'controller' => 'evento',
                              'action' => 'detalhes',
                              'id' => $evento), 'default', true);
               } else {
                  echo "Já existe um evento no mesmo dia, mesma sala e mesmo horário.";
               }
            } catch (Exception $e) {
               // TODO: colocar erro em flashMessage
               echo $e->getMessage();
            }
         } else {
            $form->populate($formData);
         }
      } else {
         $id = $this->_getParam('id', 0);
         if ($id > 0) {
            $form->populate($model->fetchRow("evento = " . $id)->toArray());
         }
      }
      
      $select = "SELECT TO_CHAR(data, 'DD/MM/YYYY') as data, 
         TO_CHAR(hora_inicio, 'HH24:MI') as hora_inicio, 
         TO_CHAR(hora_fim, 'HH24:MI') as hora_fim FROM evento_realizacao 
         WHERE id_evento = ?";
      $this->view->idEvento = $evento;
      $this->view->horariosEventos = $model->getAdapter()->fetchAll($select, $evento);
   }

}

