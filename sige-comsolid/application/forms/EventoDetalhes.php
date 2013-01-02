<?php

class Application_Form_EventoDetalhes extends Zend_Form
{
  public function init(){
  	
  	$id_pessoa = $this->createElement('hidden', 'id_pessoa');
  	                 
    $nome = $this->createElement('text', 'nome',array('label' => 'Autor: '))->setAttrib('readonly','readonly');
    
    $butaoTrocaUsuario = $this->createElement('button', 'mudarUsuario', array('label'=>'Mudar Usuário'));
    
  	$validada = $this->createElement('text', 'validada',array('label' => 'Validada: '))->setAttrib('readonly','readonly');
  	
  	$data_submissao =  $this->createElement('text', 'data_submissao',array('label' => 'Data: '))->setAttrib('readonly','readonly');  	

   	$nome_evento = $this->createElement('text', 'nome_evento',array('label' => 'Titulo: '))->setAttrib('readonly','readonly');
   	$nome_evento->addValidator('regex', false, array('/^[ 0-9 a-zA-Z á é í ó ú à ì ò ù ã ẽ ĩ õ ũ â ê î ô û ä ë ï ö ü ç ]*$/'))
   				->addValidator('stringLength', false, array(6,100))
   				->setAllowEmpty(false)
          		->setRequired(true)
          		->addErrorMessage("Campo contém caracteres invalidos e/ou é muito pequeno.");


    $perfil_minimo = $this->createElement('textarea', 'perfil_minimo',array('label' => 'Perfil Minimo: '))->setAttrib('readonly','readonly');
   	$perfil_minimo->setAttrib('COLS', '40')
    			  ->setAttrib('ROWS', '4')
   				  ->setAllowEmpty(false)
          		  ->setRequired(true)
          		  ->addValidator('stringLength', false, array(10))
          		  ->addErrorMessage("Perfil com número insuficiente de caracteres.");
          		  
    $curriculum = $this->createElement('textarea', 'curriculum',array('label' => 'Curriculum: '))->setAttrib('readonly','readonly');
   	$curriculum->setAttrib('COLS', '40')
    		->setAttrib('ROWS', '4')
   			->setAllowEmpty(false)
          	->setRequired(true)
  			->addValidator('stringLength', false, array(10))
          	->addErrorMessage("Curriculum com número insuficiente de caracteres.");
          		  
	$resumo = $this->createElement('textarea', 'resumo',array('label' => 'Resumo: '))->setAttrib('readonly','readonly');
   	$resumo->setAttrib('COLS', '40')
    		->setAttrib('ROWS', '4')
   			->setAllowEmpty(false)
          	->setRequired(true)
          	->addValidator('stringLength', false, array(10))
          	->addErrorMessage("Resumo com número insuficiente de caracteres.");
          	
          
   	$nome_tipo_evento = $this->createElement('text', 'nome_tipo_evento',array('label' => 'Tipo Atividade: '))->setAttrib('readonly','readonly');
   	
   
   	$descricao_dificuldade_evento = $this->createElement('text', 'descricao_dificuldade_evento',array('label' => 'Nivel: '))->setAttrib('readonly','readonly');
   	
    $this->addElement($nome_tipo_evento)
    	 ->addElement($nome)
    	 ->addElement($butaoTrocaUsuario)
    	 ->addElement($nome_evento)
    	 ->addElement($data_submissao)
    	 ->addElement($validada)
    	 ->addElement($descricao_dificuldade_evento)
    	 ->addElement($perfil_minimo)
    	 ->addElement($curriculum)
    	 ->addElement($resumo)
    	 ->addElement($id_pessoa);
    	
   	$botao = $this->createElement('submit', 'Alterar')->removeDecorator('DtDdWrapper');
	//$this->addElement($botao);
    	
        
	}
}