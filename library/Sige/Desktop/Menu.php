<?php

class Sige_Desktop_Menu {

    use Sige_Translate_Abstract {
        Sige_Translate_Abstract::__construct as private __mConstruct;
    }

    private $menu_items;
    private $menu_ativo;

    public function __construct($view, $ativo = "", $isAdmin = false) {
        $this->__mConstruct();

        $this->menu_ativo = $ativo;
        $this->menu_items = array(
            // url : ícone : texto : ativo?
            'home' => array(
                'url' => $view->url(array('controller' => 'participante'), 'default', true),
                'icon' => 'fa-home',
                'text' => $this->t->_("Home"),
            ),
            'schedule' => array(
                'url' => $view->url(array(), 'programacao', true),
                'icon' => 'fa-calendar',
                'text' => $this->t->_("Schedule"),
            ),
            'caravan' => array(
                'url' => $view->url(array('controller' => 'caravana'), 'default', true),
                'icon' => 'fa-plane',
                'text' => $this->t->_("Caravan"),
            ),
            'submission' => array(
                'url' => $view->url(array(), 'submissao', true),
                'icon' => 'fa-file-text-o',
                'text' => $this->t->_("Paper Submission"),
            ),
        );

        if ($isAdmin) {
            $this->menu_items['admin'] = array(
                'url' => $view->url(array(), 'admin', true),
                'icon' => 'fa-gavel',
                'text' => $this->t->_('Admin')
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
