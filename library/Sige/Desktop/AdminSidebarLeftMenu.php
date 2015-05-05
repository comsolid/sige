<?php

class Sige_Desktop_AdminSidebarLeftMenu {

    use Sige_Translate_Abstract {
        Sige_Translate_Abstract::__construct as private __mConstruct;
    }

    private $menu_items;
    private $active_menu;

    public function __construct($view, $active = "") {
        $this->__mConstruct();

        $this->active_menu = $active;
        $this->menu_items = array(
            'home' => array(
                'url' => $view->url(array('controller' => 'participante'), 'default', true),
                'icon' => 'fa-home',
                'text' => $this->t->_('Home'),
            ),
            'dashboard' => array(
                'url' => $view->url(array(), 'admin', true),
                'icon' => 'fa-dashboard',
                'text' => $this->t->_('Dashboard'),
            ),
            'registration' => array(
                'url' => $view->url(array(), 'inscricoes', true),
                'icon' => 'fa-pencil',
                'text' => $this->t->_('Registration'),
            ),
            'events' => array(
                'url' => $view->url(array(
                    'module' => 'admin',
                    'controller' => 'evento',
                    'action' => 'index'), 'default', true),
                'icon' => 'fa-star',
                'text' => $this->t->_('Events'),
            ),
            'caravan' => array(
                'url' => $view->url(array(
                    'module' => 'admin',
                    'controller' => 'caravana',
                    'action' => 'index'), 'default', true),
                'icon' => 'fa-plane',
                'text' => $this->t->_('Caravan'),
            ),
            'reports' => array(
                'treeview' => true,
                'icon' => 'fa-bar-chart-o',
                'text' => $this->t->_('Reports'),
                'items' => array(
                    array(
                        'url' => $view->url(array(
                            'module' => 'admin',
                            'controller' => 'relatorios',
                            'action' => 'index'), 'default', true),
                        'icon' => 'fa-eye',
                        'text' => $this->t->_('View All'),
                    ),
                    array(
                        'url' => $view->url(array(
                            'module' => 'admin',
                            'controller' => 'relatorios',
                            'action' => 'inscricoes-sexo'), 'default', true),
                        'icon' => 'fa-user',
                        'text' => $this->t->_('Registrations per gender'),
                    ),
                    array(
                        'url' => $view->url(array(
                            'module' => 'admin',
                            'controller' => 'relatorios',
                            'action' => 'inscricoes-municipio-15-mais'), 'default', true),
                        'icon' => 'fa-flag',
                        'text' => $this->t->_('Registrations per district (15+)'),
                    ),
                    array(
                        'url' => $view->url(array(
                            'module' => 'admin',
                            'controller' => 'relatorios',
                            'action' => 'inscricoes-municipio'), 'default', true),
                        'icon' => 'fa-flag',
                        'text' => $this->t->_('Registrations per district (All)'),
                    ),
                )
            ),
            'config' => array(
                'treeview' => true,
                'icon' => 'fa-cogs',
                'text' => $this->t->_('Configurations'),
                'items' => array(
                    array(
                        'url' => $view->url(array(
                            'module' => 'admin',
                            'controller' => 'config',
                            'action' => 'index'), 'default', true),
                        'icon' => 'fa-eye',
                        'text' => $this->t->_('View All'),
                    ),
                    array(
                        'url' => $view->url(array(
                            'module' => 'admin',
                            'controller' => 'encontro',
                            'action' => 'index'), 'default', true),
                        'icon' => 'fa-bullhorn',
                        'text' => $this->t->_('Manage Conferences'),
                    ),
                    array(
                        'url' => $view->url(array(
                            'module' => 'admin',
                            'controller' => 'encontro',
                            'action' => 'criar'), 'default', true),
                        'icon' => 'fa-plus',
                        'text' => $this->t->_('Create Conference'),
                    ),
                    array(
                        'url' => $view->url(array(
                            'module' => 'admin',
                            'controller' => 'config',
                            'action' => 'permissao-usuarios'), 'default', true),
                        'icon' => 'fa-lock',
                        'text' => $this->t->_('User permissions'),
                    ),
                )
            )
        );
    }

    public function getView() {
        $result = "";
        foreach ($this->menu_items as $key => $value) {
            if (isset($value['treeview'])) {
                $result .= sprintf('<li class="treeview %s"><a href="#"><i class="fa %s"></i> <span>%s</span><i class="fa fa-angle-left pull-right"></i></a>',
                    $this->ativar($key), $value['icon'], $value['text']);

                $result .= '<ul class="treeview-menu">';
                $result .= $this->templateTreeview($value['items']);
                $result .= '</li></ul>';
            } else {
                $result .= sprintf('<li class="%s"><a href="%s"><i class="fa %s"></i> <span>%s</span></a></li>',
                    $this->ativar($key), $value['url'], $value['icon'], $value['text']);
            }
        }
        return $result;
    }

    private function templateTreeview($items) {
        $result = "";
        foreach ($items as $value) {
            $result .= sprintf('<li><a href="%s"><i class="fa %s"></i> %s</a></li>',
                $value['url'], $value['icon'], $value['text']);
        }
        return $result;
    }

    private function ativar($item) {
        if (strcmp($this->active_menu, $item) == 0) {
            return 'active';
        }
        return '';
    }
}
