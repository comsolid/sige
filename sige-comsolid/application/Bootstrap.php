<?php

class Bootstrap extends Zend_Application_Bootstrap_Bootstrap {

   public function _initRoutes() {
      $frontController = Zend_Controller_Front::getInstance(); 
      $router = $frontController->getRouter();
      
      $route = new Zend_Controller_Router_Route_Static(
         '/login',
         array(
             'controller' => 'index',
             'action' => 'login'
         )
      );
      $router->addRoute('login', $route);
      
      $route = new Zend_Controller_Router_Route_Static(
         '/submissao',
         array(
             'controller' => 'evento',
             'action' => 'index'
         )
      );
      $router->addRoute('submissao', $route);
      
      // TODO: criar username contendo apenas caracteres 0-9a-z_
      $route = new Zend_Controller_Router_Route(
         '/u/:id',
         array(
             'controller' => 'participante',
             'action' => 'ver'
         )
      );
      $router->addRoute('verUsuario', $route);
   }
}

