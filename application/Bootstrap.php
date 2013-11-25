<?php

class Bootstrap extends Zend_Application_Bootstrap_Bootstrap {

   public function _initRoutes() {
      $frontController = Zend_Controller_Front::getInstance(); 
      $router = $frontController->getRouter();

		$route = new Zend_Controller_Router_Route_Static(
         '/',
         array(
             'controller' => 'index',
             'action' => 'index'
         )
      );
      $router->addRoute('index', $route);
      
      $route = new Zend_Controller_Router_Route_Static(
         '/inscricoes',
         array(
             'module' => 'admin',
             'controller' => 'participante',
             'action' => 'index'
         )
      );
      $router->addRoute('inscricoes', $route);

      $route = new Zend_Controller_Router_Route_Static(
         '/admin',
         array(
             'module' => 'admin',
             'controller' => 'participante',
             'action' => 'index'
         )
      );
      $router->addRoute('admin', $route);
      
      $route = new Zend_Controller_Router_Route_Static(
         '/login',
         array(
             'controller' => 'index',
             'action' => 'login'
         )
      );
      $router->addRoute('login', $route);
      
      $route = new Zend_Controller_Router_Route_Static(
         '/logout',
         array(
             'controller' => 'index',
             'action' => 'logout'
         )
      );
      $router->addRoute('logout', $route);
      
      $route = new Zend_Controller_Router_Route_Static(
         '/sobre',
         array(
             'controller' => 'index',
             'action' => 'sobre'
         )
      );
      $router->addRoute('sobre', $route);
      
      $route = new Zend_Controller_Router_Route_Static(
         '/submissao',
         array(
             'controller' => 'evento',
             'action' => 'index'
         )
      );
      $router->addRoute('submissao', $route);
      
      $route = new Zend_Controller_Router_Route_Static(
         '/participar',
         array(
             'controller' => 'participante',
             'action' => 'criar'
         )
      );
      $router->addRoute('participar', $route);
      
      $route = new Zend_Controller_Router_Route_Static(
         '/recuperar-senha',
         array(
             'controller' => 'index',
             'action' => 'recuperar-senha'
         )
      );
      $router->addRoute('recuperar-senha', $route);
      
      $route = new Zend_Controller_Router_Route(
         '/u/:id',
         array(
             'controller' => 'participante',
             'action' => 'ver'
         )
      );
      $router->addRoute('ver', $route);
      
      $route = new Zend_Controller_Router_Route(
         '/mobile/u/:id',
         array(
             'module' => 'mobile',
             'controller' => 'participante',
             'action' => 'ver'
         )
      );
      $router->addRoute('mobile_ver', $route);
      
      $route = new Zend_Controller_Router_Route(
         '/u/confirmar/:id',
         array(
             'module' => 'admin',
             'controller' => 'participante',
             'action' => 'presenca',
             'confirmar' => 't'
         )
      );
      $router->addRoute('confirmar_participante', $route);
      
      $route = new Zend_Controller_Router_Route(
         '/u/desfazer-confirmar/:id',
         array(
             'module' => 'admin',
             'controller' => 'participante',
             'action' => 'presenca',
             'confirmar' => 'f'
         )
      );
      $router->addRoute('des_confirmar_participante', $route);
      
      $route = new Zend_Controller_Router_Route(
            '/admin/evento/validar/:id',
            array(
               'module' => 'admin',
               'controller' => 'evento',
               'action' => 'situacao',
               'validar' => 't'
            )
      );
      $router->addRoute('validar_evento', $route);
      
      $route = new Zend_Controller_Router_Route(
            '/admin/evento/invalidar/:id',
            array(
               'module' => 'admin',
               'controller' => 'evento',
               'action' => 'situacao',
               'validar' => 'f'
            )
      );
      $router->addRoute('invalidar_evento', $route);
      
      $route = new Zend_Controller_Router_Route(
            '/admin/evento/apresentado/:id',
            array(
               'module' => 'admin',
               'controller' => 'evento',
               'action' => 'situacao-pos-evento',
               'apresentado' => 't'
            )
      );
      $router->addRoute('evento_apresentado', $route);
      
      $route = new Zend_Controller_Router_Route(
            '/admin/evento/desfazer-apresentado/:id',
            array(
               'module' => 'admin',
               'controller' => 'evento',
               'action' => 'situacao-pos-evento',
               'apresentado' => 'f'
            )
      );
      $router->addRoute('evento_desfazer_apresentado', $route);
      
      $route = new Zend_Controller_Router_Route(
            '/admin/evento/outros-palestrantes/confirmar/:pessoa/:evento',
            array(
               'module' => 'admin',
               'controller' => 'evento',
               'action' => 'outros-palestrantes',
               'confirmar' => 't'
            )
      );
      $router->addRoute('confirmar_outro_palestrante', $route);
      
      $route = new Zend_Controller_Router_Route(
            '/admin/evento/outros-palestrantes/desfazer/:pessoa/:evento',
            array(
               'module' => 'admin',
               'controller' => 'evento',
               'action' => 'outros-palestrantes',
               'confirmar' => 'f'
            )
      );
      $router->addRoute('des_confirmar_outro_palestrante', $route);
      
      $route = new Zend_Controller_Router_Route_Static(
         '/programacao',
         array(
             'controller' => 'evento',
             'action' => 'programacao'
         )
      );
      $router->addRoute('programacao', $route);
      
      $route = new Zend_Controller_Router_Route(
         '/c/validar/:id',
         array(
             'module' => 'admin',
             'controller' => 'caravana',
             'action' => 'situacao',
             'validar' => 't'
         )
      );
      $router->addRoute('validar_caravana', $route);
      
      $route = new Zend_Controller_Router_Route(
         '/c/invalidar/:id',
         array(
             'module' => 'admin',
             'controller' => 'caravana',
             'action' => 'situacao',
             'validar' => 'f'
         )
      );
      $router->addRoute('invalidar_caravana', $route);
      
      $route = new Zend_Controller_Router_Route(
         '/e/:id',
         array(
             'controller' => 'evento',
             'action' => 'ver'
         )
      );
      $router->addRoute('ver_evento', $route);
      
      $route = new Zend_Controller_Router_Route(
         '/mobile/e/:id',
         array(
             'module' => 'mobile',
             'controller' => 'evento',
             'action' => 'ver'
         )
      );
      $router->addRoute('mobile_ver_evento', $route);
      
      $route = new Zend_Controller_Router_Route_Static(
         '/mobile',
         array(
             'module' => 'mobile',
             'controller' => 'participante',
             'action' => 'index'
         )
      );
      $router->addRoute('mobile', $route);
   }
   
   public function _initTranslate() {
      $translator = new Zend_Translate(array('adapter' => 'array', 'content' => '../resources/languages', 'locale' => 'pt_BR', 'scan' => Zend_Translate::LOCALE_DIRECTORY));
      Zend_Validate_Abstract::setDefaultTranslator($translator);
   }
}

