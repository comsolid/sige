<?php

class Application_Form_Evento extends Zend_Form {
   
   private $modoEdicao = false;
   
   public function __construct($options = null) {
      parent::__construct($options);
      if (!is_null($options)) {
         if (isset($options['modo_edicao'])) {
            $this->modoEdicao = $options['modo_edicao'];
         }
      }
   }

   public function init() {
      
      $this->setName('Evento');

      $this->addElements(array(
          $this->_nome_evento(),
          $this->_id_tipo_evento(),
          $this->_id_dificuldade_evento(),
          $this->_perfil_minimo(),
          //$this->_curriculum(),
          $this->_resumo(),
          $this->_id_encontro(),
          $this->_preferencia_horario(),
          /*$this->_validada(),
          $this->_responsavel(),
          $this->_data_validacao(),
          $this->_apresentado()*/
      ));
      
      $botao = $this->createElement('submit', 'confimar')->removeDecorator('DtDdWrapper');
      $this->addElement($botao);
      $botao = $this->createElement('submit', 'cancelar')->removeDecorator('DtDdWrapper');
      $botao->setAttrib('class', 'submitCancelar');
      $this->addElement($botao);
		
   	/*$nome_evento = $this->createElement('text', 'nome_evento',array('label' => 'Titulo: '));
   	$nome_evento->addValidator('stringLength', false, array(1,100))
					// FIXME: pra que isso? ->addValidator('regex', false, array('/^[0-9a-zA-Záéíóúàìòùãẽĩõũâêîôûäëïöüç]*$/'))
   				->setAllowEmpty(false)
          		->setRequired(true)
               ->setDecorators(array(
                  'ViewHelper',
                  'Description',
                  'Errors',
                  array('HtmlTag', ''),
                  array('Label', ''),
               ));
          		//->addErrorMessage("Campo contém caracteres invalidos e/ou é muito pequeno.");

		$perfil_minimo = $this->createElement('textarea', 'perfil_minimo',array('label' => 'Perfil Minimo: '));
   	$perfil_minimo->setAttrib('cols', '40')
    			  ->setAttrib('rows', '4')
   				  ->setAllowEmpty(false)
          		  ->setRequired(true)
          		  ->addValidator('stringLength', false, array(10))
          		  ->addErrorMessage("Perfil com numero insuficiente de caracteres (min. 10).");
          		  
		$curriculum = $this->createElement('textarea', 'curriculum',array('label' => 'Curriculum: '));
   	$curriculum->setAttrib('cols', '40')
    		->setAttrib('rows', '4')
   			->setAllowEmpty(false)
          	->setRequired(true)
  			->addValidator('stringLength', false, array(10))
          	->addErrorMessage("Curriculum com numero insuficiente de caracteres (min. 10).");
          		  
		$resumo = $this->createElement('textarea', 'resumo',array('label' => 'Resumo: '));
   	$resumo->setAttrib('rows', '4')
            ->setAttrib('class', 'ckeditor')
   			->setAllowEmpty(false)
          	->setRequired(true)
          	->addValidator('stringLength', false, array(10))
            ->addFilter(new Sige_Filter_HTMLPurifier)
          	->addErrorMessage("Resumo com numero insuficiente de caracteres (min. 10).")
            ->setDecorators(array(
               'ViewHelper',
               'Description',
               'Errors',
               array('HtmlTag', ''),
               array('Label', ''),
            ));
          	
          	
		$tipo_evento = new Application_Model_TipoEvento();
   	$tipo_evento = $tipo_evento->fetchAll();
   	$nome_tipo_evento = $this->createElement('select', 'id_tipo_evento',array('label' => 'Tipo Atividade: '));
   	
   	foreach($tipo_evento as $item) {
   		$nome_tipo_evento->addMultiOptions(array($item->id_tipo_evento => $item->nome_tipo_evento));	
   	}
   	
   	$dificuldade_evento = new Application_Model_DificuldadeEvento();
   	$listaDificuldade  = $dificuldade_evento->fetchAll();
   	$descricao_dificuldade_evento = $this->createElement('select', 'id_dificuldade_evento',array('label' => 'Nivel: '));
   	foreach($listaDificuldade as $item) {
   		$descricao_dificuldade_evento->addMultiOptions(array($item->id_dificuldade_evento => $item->descricao_dificuldade_evento));	
   	}
   
		$encontro = $this->createElement('hidden', 'id_encontro');
    
		$this->addElement($nome_evento)
			->addElement($nome_tipo_evento)
			->addElement($descricao_dificuldade_evento)
			->addElement($perfil_minimo)
			->addElement($curriculum)
    	   ->addElement($encontro)
			->addElement($resumo);
    	$botao = $this->createElement('submit', 'confimar')->removeDecorator('DtDdWrapper');
		$this->addElement($botao);
		$botao = $this->createElement('submit', 'cancelar')->removeDecorator('DtDdWrapper');
		$botao->setAttrib('class','submitCancelar');
		$this->addElement($botao);*/
	}
   
   protected function _nome_evento() {
      $e = new Zend_Form_Element_Text('nome_evento');
      $e->setLabel('Título:')
              ->setRequired(true)
              ->addValidator('StringLength', false, array(1, 100))
              ->addFilter('StripTags')
              ->addFilter('StringTrim')
              ->setAttrib('class', 'large');

      $e->setDecorators(array(
          'ViewHelper',
          'Description',
          'Errors',
          array('HtmlTag', ''),
          array('Label', ''),
      ));
      return $e;
   }
   
   protected function _id_tipo_evento() {
      $e = new Zend_Form_Element_Select('id_tipo_evento');
      $e->setRequired(true)
              ->setLabel('Tipo Atividade:');
      $model = new Application_Model_TipoEvento();
      $rs = $model->fetchAll();
      foreach ($rs as $item) {
         $e->addMultiOption($item->id_tipo_evento, $item->nome_tipo_evento);
      }
      
      $e->setDecorators(array(
          'ViewHelper',
          'Description',
          'Errors',
          array('HtmlTag', ''),
          array('Label', ''),
      ));
      return $e;
   }
   
   protected function _id_dificuldade_evento() {
      $e = new Zend_Form_Element_Select('id_dificuldade_evento');
      $e->setRequired(true)
              ->setLabel('Nível:');
      $model = new Application_Model_DificuldadeEvento();
      $rs = $model->fetchAll();
      foreach ($rs as $item) {
         $e->addMultiOption($item->id_dificuldade_evento, $item->descricao_dificuldade_evento);
      }
      
      $e->setDecorators(array(
          'ViewHelper',
          'Description',
          'Errors',
          array('HtmlTag', ''),
          array('Label', ''),
      ));
      return $e;
   }
   
   protected function _perfil_minimo() {
      $e = new Zend_Form_Element_Textarea('perfil_minimo');
      $e->setLabel('Perfil Mínimo:')
              ->setRequired(true)
              ->setAttrib('rows', 10)
              ->addFilter('StripTags')
              ->addFilter('StringTrim');

      $e->setDecorators(array(
          'ViewHelper',
          'Description',
          'Errors',
          array('HtmlTag', ''),
          array('Label', ''),
      ));
      return $e;
   }
   
   protected function _curriculum() {
      $e = new Zend_Form_Element_Textarea('curriculum');
      $e->setLabel('Curriculum:')
              ->setRequired(true)
              ->setAttrib('rows', 10)
              ->addFilter('StripTags')
              ->addFilter('StringTrim');

      $e->setDecorators(array(
          'ViewHelper',
          'Description',
          'Errors',
          array('HtmlTag', ''),
          array('Label', ''),
      ));
      return $e;
   }
   
   protected function _id_encontro() {
      $e = new Zend_Form_Element_Hidden('id_encontro');
      return $e;
   }
   
   protected function _resumo() {
      $e = new Zend_Form_Element_Textarea('resumo');
      $e->setLabel('Resumo:')
              ->setRequired(true)
              ->setAttrib('rows', 10)
              ->addFilter('StringTrim')
              ->setAttrib('class', 'ckeditor')
              ->addValidator('stringLength', false, array(10))
              ->addFilter(new Sige_Filter_HTMLPurifier)
          	  ->addErrorMessage("Resumo com numero insuficiente de caracteres (min. 10).");

      $e->setDecorators(array(
          'ViewHelper',
          'Description',
          'Errors',
          array('HtmlTag', ''),
          array('Label', ''),
      ));
      return $e;
   }
   
   protected function _preferencia_horario() {
      $e = new Zend_Form_Element_Textarea('preferencia_horario');
      $e->setLabel('Preferência de horário:')
              ->setRequired(true)
              ->setAttrib('rows', 5)
              ->setAttrib('placeholder', 'Data e horário mais conveniente...')
              ->addFilter('StripTags')
              ->addFilter('StringTrim');

      $e->setDecorators(array(
          'ViewHelper',
          'Description',
          'Errors',
          array('HtmlTag', ''),
          array('Label', ''),
      ));
      return $e;
   }
}
