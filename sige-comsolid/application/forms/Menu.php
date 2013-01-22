<?php

class Application_Form_Menu extends Zend_Form
{
	private $control;
	private $menuAtivo=array('inicio'=>'inicio','programacao'=>'','submissao'=>'','caravana'=>'');
	private $urlBase;
	private $acaoAtual;
	private $participanteIndexInicio;
	private $participanteAlteSenha;
	private $caravana,$submissao;
   private $programacao;
	
	public function __construct($base,$ativo) {
		$this->control=$base;
		$this->programacao=$this->control->url(array(), 'programacao', true); 
		$this->participanteIndexInicio=$this->control->url(array('controller'=>'participante','action'=>'index'), 'default', true);
		$this->submissao=$this->control->url(array(), 'submissao', true);
		$this->setAtivo($ativo);
		$this->caravana=$this->control->url(array('controller'=>'caravana','action'=>'index'), 'default', true);
	}
	
	public function init(){
		//$menuAtivo=array('inicio'=>'','alterarsenha'=>'','meuseventos'=>'','caravana'=>'');
	}

	public function setAtivo($ativo){
  		if('inicio' == $ativo) {
			$this->menuAtivo['inicio']="verde fl_left";
    	} else {
			$this->menuAtivo['inicio']='';
		}

    	if('programacao' == $ativo) {
			$this->menuAtivo['programacao']="verde fl_left";
    	}else{
    		$this->menuAtivo['programacao']="";
    	}
    	
    	if('submissao' == $ativo) {
			$this->menuAtivo['submissao']="verde fl_left";
    	} else {
			$this->menuAtivo['submissao']="";
		}
		
    	if('caravana' == $ativo) {
			$this->menuAtivo['caravana']="verde fl_left";
		} else {
			$this->menuAtivo['caravana']="";
		}
	}
	
	public function getAtivo() {
    	$this->menuAtivo;
	}
	
	public function getCaravana() {
		return $this->caravana;
	}
	
	public function getSubmissao() {
		return $this->submissao;
	}
	
	public function getProgramacao() {
		return $this->programacao;
	}
	
	public function getInicio() {
		return $this->participanteIndexInicio;
	}
	
	public function getAcaoAtual() {
		return $this->acaoAtual;
	}
	
	public function getView() {
		$menu="<div id=\"menu\" class=\"fl_left\"><a class=\"".$this->menuAtivo['inicio'];
		$menu.="\" href=\"".$this->getInicio()."\"><i class=\"icon-home icon-large\"></i> &nbsp;Início</a>";
		$menu.="<a class=\"".$this->menuAtivo['programacao'];
		$menu.="\" href=\"".$this->getProgramacao()."\"><i class=\"icon-calendar icon-large\"></i> &nbsp;Programação</img></a>";
	   $menu.="<a class=\"".$this->menuAtivo['caravana'];
	   $menu.="\" href=\"".$this->getCaravana()."\"><i class=\"icon-plane icon-large\"></i> &nbsp;Caravana</a>";
	   $menu.="<a class=\"".$this->menuAtivo['submissao'];
	   $menu.="\" href=\"".$this->getSubmissao()."\"><i class=\"icon-star icon-large\"></i> &nbsp;Submissão</a>";
 		//$menu.=" <a  class=\"";
 		//$menu.=" \" href=\"#\" class=\"fl_right\"><img src=\"".$this->control->baseUrl('imagens/layout/bt_sejavoluntario.png')."\"></img></a>";
      $menu.= "</div>";
		return $menu;
	}
}
