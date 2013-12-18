<?php

class Admin_Form_Encontro extends Zend_Form {

   protected $modo_edicao = false;
   
   public function modoEdicao() {
      $this->modo_edicao = true;
   }
   
   public function init() {
      $this->setName('Encontro');

      $submit = $this->createElement('submit', 'confimar', array('label' => 'Confimar'))->removeDecorator('DtDdWrapper');

      $cancelar = $this->createElement('submit', 'cancelar', array('label' => 'Cancelar'))->removeDecorator('DtDdWrapper');
      $cancelar->setAttrib('class', 'submitCancelar');

      $this->addElements(array(
          $this->_nome_encontro(),
          $this->_apelido_encontro(),
          $this->_data_inicio(),
          $this->_data_fim(),
          $submit,
          $cancelar
      ));
   }

   protected function _id_encontro() {
      $e = new Zend_Form_Element_Hidden('id_encontro');
      $e->addFilter('Int');
      $e->setDecorators(array(
          'ViewHelper',
          'Description',
          'Errors',
          array('HtmlTag', ''),
          array('Label', ''),
      ));
      return $e;
   }

   protected function _nome_encontro() {
      $e = new Zend_Form_Element_Text('nome_encontro');
      $e->setLabel('Nome encontro:')
              ->setRequired(true)
              ->addValidator('StringLength', false, array(1, 100))
              ->addFilter('StripTags')
              ->addFilter('StringTrim')
              ->setAttrib('class', 'large')
              ->setAttrib("placeholder", "I Encontro de Software Livre");

      $e->setDecorators(array(
          'ViewHelper',
          'Description',
          'Errors',
          array('HtmlTag', ''),
          array('Label', ''),
      ));
      return $e;
   }

   protected function _apelido_encontro() {
      $e = new Zend_Form_Element_Text('apelido_encontro');
      $e->setLabel('Codenome:')
              ->setRequired(true)
              ->addValidator('StringLength', false, array(1, 10))
              ->addFilter('StripTags')
              ->addFilter('StringTrim')
              ->setAttrib('class', 'normal')
              ->setAttrib("placeholder", "I ESL");

      $e->setDecorators(array(
          'ViewHelper',
          'Description',
          'Errors',
          array('HtmlTag', ''),
          array('Label', ''),
      ));
      return $e;
   }
   
   protected function _data_inicio() {
      $e = new Zend_Form_Element_Text('data_inicio');
      $e->setLabel('Data início:')
              ->setRequired(true)
              ->addFilter('StripTags')
              ->addFilter('StringTrim')
              ->setAttrib('class', 'date');
      
      if ($this->modo_edicao) {
         $e->setAttrib("disabled", "disabled");
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
   
   protected function _data_fim() {
      $e = new Zend_Form_Element_Text('data_fim');
      $e->setLabel('Data fim:')
              ->setRequired(true)
              ->addFilter('StripTags')
              ->addFilter('StringTrim')
              ->setAttrib('class', 'date');
      
      if ($this->modo_edicao) {
         $e->setAttrib("disabled", "disabled");
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
}

