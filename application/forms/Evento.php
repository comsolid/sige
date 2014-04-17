<?php

class Application_Form_Evento extends Zend_Form {
   
   private $modoEdicao = false;
   
   /**
    * @deprecated
    * @param type $options 
    */
   public function __construct($options = null) {
      parent::__construct($options);
      if (!is_null($options)) {
         if (isset($options['modo_edicao'])) {
            $this->modoEdicao = $options['modo_edicao'];
         }
      }
   }

   public function init() {
      $this->setAttrib("data-validate", "parsley");
      $this->setName('Evento');

      $this->addElements(array(
          $this->_nome_evento(),
          $this->_id_tipo_evento(),
          $this->_id_dificuldade_evento(),
          $this->_perfil_minimo(),
          $this->_resumo(),
          $this->_id_encontro(),
          $this->_tecnologias_envolvidas(),
          $this->_preferencia_horario(),
      ));
      
      $responsavel = $this->createElement('hidden', 'responsavel');
      $this->addElement($responsavel);
      
      $submit = Sige_Form_Element_ButtonFactory::createSubmit();
      $submit->setLabel(_("Confirm"));
      $this->addElement($submit);
      $cancel = Sige_Form_Element_ButtonFactory::createCancel();
      $cancel->setUrl(_("Cancel"),
              array(), 'submissao', true);
      $this->addElement($cancel);
	}
   
   protected function _nome_evento() {
      $e = new Zend_Form_Element_Text('nome_evento');
      $e->setLabel(_('Title:'))
              ->setRequired(true)
              ->addValidator('StringLength', false, array(1, 100))
              ->setAttrib("data-required", "true")
              ->setAttrib("data-rangelength", "[1,100]")
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
              ->setLabel(_('Event type:'));
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
              ->setLabel(_('Level:'));
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
      $e->setLabel(_('Minimum profile:'))
              ->setRequired(true)
              ->setAttrib('rows', 6)
              ->setAttrib("data-required", "true")
              ->setAttrib('placeholder', _('Describe what your audience should basically know...'))
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
      $e->setLabel(_('Abstract:'))
              ->setRequired(true)
              ->setAttrib('rows', 10)
              //->setAttrib("data-required", "true")
              ->addFilter('StringTrim')
              ->setAttrib('class', 'ckeditor')
              ->addValidator('stringLength', false, array(20))
              ->addFilter(new Sige_Filter_HTMLPurifier)
          	  ->addErrorMessage(_("Abstract with insufficient number of characters (min. 20)."));

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
      $e->setLabel(_('Time preferences:'))
              ->setAttrib('rows', 5)
              ->setAttrib('placeholder', _('Date and time more convenient...'))
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

   protected function _tecnologias_envolvidas() {
      $e = new Zend_Form_Element_Textarea('tecnologias_envolvidas');
      $e->setLabel(_('Technologies involved:'))
              ->setAttrib('rows', 5)
              ->setAttrib('placeholder', _('Need of an especific program ou tool, distro, IDE, etc...'))
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
