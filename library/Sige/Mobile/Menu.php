<?php

/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 * Description of Menu
 *
 * @author atila
 */
class Sige_Mobile_Menu {
   
   private $menu;
   
   public function __construct($view, $ativo = "") {
      $sessao = Zend_Auth::getInstance()->getIdentity();
      
      $this->menu = array(
         // url : ícone : texto : ativo?
         array( $view->url(array('module' => 'mobile',
                              'controller' => 'participante',
                              'action' => 'index'), 'default', true),
                              'icon-home', 'Início', $this->ativar('inicio', $ativo)
          ),
          array( $view->url(array('module' => 'mobile',
                              'controller' => 'evento',
                              'action' => 'programacao'), 'default', true),
                              'icon-calendar', 'Programação', $this->ativar('programacao', $ativo)
          ),
          array( $view->url(array('module' => 'mobile',
                              'controller' => 'participante',
                              'action' => 'ver'), 'default', true),
                              'icon-user', $sessao['apelido'], $this->ativar('participante', $ativo)
          ),
          array( $view->url(array(), 'logout', true),
                              'icon-signout', "Sair", ""
          ),
      );
   }
   
   private function ativar($menu, $ativo) {
      if (strcmp($menu, $ativo) == 0) {
         return "class=\"ui-btn-active\"";
      }
      return "";
   }
   
   public function getView() {
      $result = "";
      foreach ($this->menu as $m) {
         $result .= "<a href=\"{$m[0]}\" data-role=\"button\" data-ajax=\"false\" $m[3]>";
         $result .= "<i class=\"{$m[1]} icon-2x\"></i><br/>{$m[2]}</a>";
      }
      return $result;
   }
}

?>
