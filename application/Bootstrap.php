<?php

class Bootstrap extends Zend_Application_Bootstrap_Bootstrap {

    public function _initRoutes() {

      $frontController = Zend_Controller_Front::getInstance();
      $frontController->getRouter()->addDefaultRoutes();
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
             'controller' => 'dashboard',
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

   /**
    * Referência:
    * http://www.codeforest.net/multilanguage-support-in-zend-framework
    */
    protected function _initTranslate() {
        $locale = new Zend_Locale();
        if (!Zend_Locale::isLocale($locale, TRUE, FALSE)) {
            if (!Zend_Locale::isLocale($locale, FALSE, FALSE)) {
                throw new Zend_Locale_Exception("The locale '$locale' is no known locale");
            }
            $locale = new Zend_Locale($locale);
        }
        //$locale = "pt_BR";

        $translatorArray = new Zend_Translate(array(
            'adapter' => 'array',
            'content' => APPLICATION_PATH . '/../resources/languages',
            'locale' => $locale,
            'scan' => Zend_Translate::LOCALE_DIRECTORY
        ));

        $translate = new Zend_Translate('gettext',
                APPLICATION_PATH . "/langs/",
                $locale,
                array('scan' => Zend_Translate::LOCALE_DIRECTORY
        ));

        $translate->addTranslation($translatorArray);

        $registry = Zend_Registry::getInstance();
        $registry->set('Zend_Translate', $translate);

        Zend_Validate_Abstract::setDefaultTranslator($translate);
        Zend_Form::setDefaultTranslator($translate);
    }

	public function _initTimeZone() {
        date_default_timezone_set('America/Fortaleza');
    }

    /**
     * Initializes the cache.
     * referência: http://wolfulus.wordpress.com/2011/12/26/zend-framework-xml-based-acl-part-3/
     */
    protected function _initCache() {
        $cache_dir = APPLICATION_PATH . '/cache/common';
        $frontendOptions = array('lifetime' => 7200, 'automatic_serialization' => true);
        $backendOptions = array('cache_dir' => $cache_dir);
        if (!file_exists($cache_dir)) {
            if (!\mkdir($cache_dir, 0777, true)) {
                echo "<h2>Crie a pasta $cache_dir com permissão de escrita para o servidor web.</h2>";
                exit;
            }
        }
        $appcache = Zend_Cache::factory('Core', 'File', $frontendOptions, $backendOptions);
        Zend_Registry::set('cache_common', $appcache);
    }

    protected function _initPreferenciaSistema() {
        $cache = Zend_Registry::get('cache_common');
        $ps = $cache->load('prefsis');
        if ($ps === false) {
            $ps = new Sige_PreferenciaSistema();
            $cache->save($ps, 'prefsis');
        }
        Zend_Controller_Front::getInstance()->registerPlugin($ps);
    }
}
