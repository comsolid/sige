<?php
class Application_Form_AddPartCaravana extends Zend_Form
{
	
 public function init(){
  	
    $this->setAction($this->getView()->url())
           ->setMethod('post');
    $botao = $this->createElement('submit', 'confimar', array('label' => 'Confimar'))->removeDecorator('DtDdWrapper');
	  $addciona = $this->createElement('textarea','participantes', array('label' => 'Participantes', 'rows' => '5','cols' =>'80'))->setRequired(true);// o textarea esta aumentando quando eu arrasto o canto .verificar depois									 				 
	  $this->addElement($addciona)
               ->addElement($botao);
  }
}
  
   
          	
          	
 	
   	
   
	


