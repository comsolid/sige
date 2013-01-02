<?php

class Application_Form_EventoEditar extends Zend_Form
{
  public function init(){
  	
    $this->setAction('/evento/edit')
           ->setMethod('post');
           
           
    $responsavel = $this->createElement('hidden', 'responsavel');
         
    $nome = $this->createElement('text', 'nome',array('label' => 'Autor: '))->setAttrib('readonly','readonly');
  	
  	$validada = $this->createElement('text', 'validada',array('label' => 'Validada: '))->setAttrib('readonly','readonly');
  	
  	$data_submissao =  $this->createElement('text', 'data_submissao',array('label' => 'Data: '))->setAttrib('readonly','readonly');  	

   	$nome_evento = $this->createElement('text', 'nome_evento',array('label' => 'Titulo: '));
   	$nome_evento->addValidator('regex', false, array('/^[ 0-9 a-zA-Z á é í ó ú à ì ò ù ã ẽ ĩ õ ũ â ê î ô û ä ë ï ö ü ç ]*$/'))
   				->addValidator('stringLength', false, array(6,100))
   				->setAllowEmpty(false)
          		->setRequired(true)
          		->addErrorMessage("Campo contém caracteres invalidos e/ou é muito pequeno.");


    $perfil_minimo = $this->createElement('textarea', 'perfil_minimo',array('label' => 'Perfil Minimo: '));
   	$perfil_minimo->setAttrib('COLS', '40')
    			  ->setAttrib('ROWS', '4')
   				  ->setAllowEmpty(false)
          		  ->setRequired(true)
          		  ->addValidator('stringLength', false, array(10))
          		  ->addErrorMessage("Perfil com número insuficiente de caracteres.");
          		  
    $curriculum = $this->createElement('textarea', 'curriculum',array('label' => 'Curriculum: '));
   	$curriculum->setAttrib('COLS', '40')
    		->setAttrib('ROWS', '4')
   			->setAllowEmpty(false)
          	->setRequired(true)
  			->addValidator('stringLength', false, array(10))
          	->addErrorMessage("Curriculum com número insuficiente de caracteres.");
          		  
	$resumo = $this->createElement('textarea', 'resumo',array('label' => 'Resumo: '));
   	$resumo->setAttrib('COLS', '40')
    		->setAttrib('ROWS', '4')
   			->setAllowEmpty(false)
          	->setRequired(true)
          	->addValidator('stringLength', false, array(10))
          	->addErrorMessage("Resumo com número insuficiente de caracteres.");
          	
          	
 	$tipo_evento = new Application_Model_TipoEvento();
   	$tipo_evento = $tipo_evento->fetchAll();
   	$nome_tipo_evento = $this->createElement('select', 'id_tipo_evento',array('label' => 'Tipo Atividade: '));
   	
   	
   	foreach($tipo_evento as $item)
   	{
   		$nome_tipo_evento->addMultiOptions(array($item->id_tipo_evento => $item->nome_tipo_evento));	
   	}
   	
   	
   	$dificuldade_evento = new Application_Model_DificuldadeEvento();
   	$listaDificuldade  = $dificuldade_evento->fetchAll();
   	$descricao_dificuldade_evento = $this->createElement('select', 'id_dificuldade_evento',array('label' => 'Nivel: '));
   	foreach($listaDificuldade as $item)
   	{
   		$descricao_dificuldade_evento->addMultiOptions(array($item->id_dificuldade_evento => $item->descricao_dificuldade_evento));	
   	}
    
   
    $encontro = $this->createElement('hidden', 'id_encontro');
  
    			
    
    
    $this->addElement($nome_evento)
    	 ->addElement($nome)
    	 ->addElement($nome_tipo_evento)
    	 ->addElement($data_submissao)
    	 ->addElement($validada)
    	 ->addElement($descricao_dificuldade_evento)
    	 ->addElement($perfil_minimo)
    	 ->addElement($curriculum)
    	 ->addElement($encontro)
    	 ->addElement($resumo)
    	 ->addElement($responsavel);
    	 
	    $botao = $this->createElement('submit', 'confirmar')->removeDecorator('DtDdWrapper');
		$this->addElement($botao);
		$botao = $this->createElement('submit', 'cancelar')->removeDecorator('DtDdWrapper');
		$botao->setAttrib('class','submitCancelar');
		$this->addElement($botao);
        
	}
}