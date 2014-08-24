<?php

class Sige_Desktop_Menu {
    
    private $menu_items;
    private $menu_ativo;
    
    public function __construct($view, $ativo = "", $isAdmin = false) {
        
        $this->menu_ativo = $ativo;
        $this->menu_items = array(
            // url : ícone : texto : ativo?
            'home' => array(
                'url' => $view->url(array(), 'default', true),
                'icon' => 'fa-home',
                'text' => _("Home"),
            ),
            'schedule' => array(
                'url' => $view->url(array(), 'programacao', true),
                'icon' => 'fa-calendar',
                'text' => _("Schedule"),
            ),
            'caravan' => array(
                'url' => $view->url(array('controller' => 'caravana'), 'default', true),
                'icon' => 'fa-plane',
                'text' => _("Caravan"),
            ),
            'submission' => array(
                'url' => $view->url(array(), 'submissao', true),
                'icon' => 'fa-file-text-o',
                'text' => _("Paper Submission"),
            ),
        );
        
        if ($isAdmin) {
            $this->menu_items['admin'] = array(
                'url' => $view->url(array(), 'admin', true),
                'icon' => 'fa-gavel',
                'text' => _('Admin')
            );
        }
    }
    
    public function setAtivo($item) {
        $this->menu_ativo = $item;
    }
    
    public function getView() {
        $result = "";
        foreach ($this->menu_items as $key => $value) {
            $result .= sprintf('<li %s><a href="%s"><i class="fa %s"></i> %s</a></li>',
                               $this->ativar($key), $value['url'], $value['icon'], $value['text']);
        }
        return $result;
    }
    
    private function ativar($item) {
        if (strcmp($this->menu_ativo, $item) == 0) {
            return 'class="active"';
        }
        return '';
    }
}