<?php

class Application_Form_Menu extends Zend_Form
{
	private $control;
	private $menuAtivo=array('inicio'=>'inicio','alterarsenha'=>'','submissao'=>'','caravana'=>'');
	private $urlBase;
	private $acaoAtual;
	private $participanteIndexInicio;
	private $participanteAlteSenha;
	private $caravana,$submissao;
	
	public function __construct($base,$ativo) {
		$this->control=$base;
		$this->participanteAlteSenha=$this->control->url(array('controller'=>'participante','action'=>'alterar-senha'), 'default', true); 
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

    	if('alterarsenha' == $ativo) {
			$this->menuAtivo['alterarsenha']="verde fl_left";
    	}else{
    		$this->menuAtivo['alterarsenha']="";
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
	
	public function getAlteSenha() {
		return $this->participanteAlteSenha;
	}
	
	public function getInicio() {
		return $this->participanteIndexInicio;
	}
	
	public function getAcaoAtual() {
		return $this->acaoAtual;
	}
	
	public function getView() {
		$menu="<div id=\"menu\" class=\"fl_left\"><a class=\"".$this->menuAtivo['inicio'];
		$menu.="\" href=\"".$this->getInicio()."\"><img src=\"".$this->control->baseUrl('imagens/layout/btmenu_inicio.png')."\"></img></a>";
		$menu.="<a class=\"".$this->menuAtivo['alterarsenha'];
		$menu.="\" href=\"".$this->getAlteSenha()."\"><img src=\"".$this->control->baseUrl('imagens/layout/btmenu_mudarsenha.png')."\"></img></a>";
	   $menu.="<a class=\"".$this->menuAtivo['caravana'];
	   $menu.="\" href=\"".$this->getCaravana()."\"><img src=\"".$this->control->baseUrl('imagens/layout/btmenu_caravana.png')."\"></img></a>";
	   $menu.="<a class=\"".$this->menuAtivo['submissao'];
	   $menu.="\" href=\"".$this->getSubmissao()."\"><img src=\"".$this->control->baseUrl('imagens/layout/btmenu_meuseventos.png')."\"></img></a>";
 		$menu.=" <a  class=\"".$this->menuAtivo['caravana'];
 		$menu.=" \" href=\"#\" class=\"fl_right\"><img src=\"".$this->control->baseUrl('imagens/layout/bt_sejavoluntario.png')."\"></img></a></div>";
		return $menu;
	}
}
