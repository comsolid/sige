<?php
class Application_Form_validacaoCaravana extends Zend_Form
{
  public function init(){
  	                 
   
  	
  	$validada = $this->createElement('text', 'validada',array('label' => 'Validada: '))->setAttrib('readonly','readonly');
  	 $this->addElement($validada);
  	 
  	 
      }
  
  }