<?php

class Default_IndexControllerTest extends AbstractControllerTest {

    public function testAccessIndexAction() {
        $params = array('action' => 'index', 'controller' => 'Index', 'module' => 'default');
        $urlParams = $this->urlizeOptions($params);
        $url = $this->url($urlParams);
        $this->dispatch($url);
        // assertions
        $this->assertModule($urlParams['module']);
        $this->assertController($urlParams['controller']);
        $this->assertAction($urlParams['action']);
    }

    public function testAccessSobreAction() {
        $params = array('action' => 'sobre', 'controller' => 'Index', 'module' => 'default');
        $urlParams = $this->urlizeOptions($params);
        $url = $this->url($urlParams);
        $this->dispatch($url);
        // assertions
        $this->assertModule($urlParams['module']);
        $this->assertController($urlParams['controller']);
        $this->assertAction($urlParams['action']);
    }

    public function testAccessRecuperarSenhaAction() {
        $params = array('action' => 'recuperar-senha', 'controller' => 'Index', 'module' => 'default');
        $urlParams = $this->urlizeOptions($params);
        $url = $this->url($urlParams);
        $this->dispatch($url);
        // assertions
        $this->assertModule($urlParams['module']);
        $this->assertController($urlParams['controller']);
        $this->assertAction($urlParams['action']);
    }

    public function testAccessLoginAction() {
        $params = array('action' => 'login', 'controller' => 'Index', 'module' => 'default');
        $urlParams = $this->urlizeOptions($params);
        $url = $this->url($urlParams);
        $this->dispatch($url);
        // assertions
        $this->assertModule($urlParams['module']);
        $this->assertController($urlParams['controller']);
        $this->assertAction($urlParams['action']);
    }

    public function testSuccessfulLogin() {
        $this->request->setMethod('POST')
                      ->setPost(array(
                          'email' => 'comsolid@comsolid.org',
                          'senha' => '123456',
                      ));
        $this->dispatch('/login');
        $this->assertRedirectTo('/participante');
    }

    public function testSuccessfulLogout() {
        $this->mockLogin();

        $this->dispatch('/logout');
        $this->assertRedirectTo('/');
    }

    /*public function testAccessLoginOnMobile() {
        $this->request->setHeader('User-Agent', 'Mozilla/5.0 (Linux; U; Android 4.0.3; ko-kr; LG-L160L Build/IML74K) AppleWebkit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30');
        $this->dispatch('/');

        $this->assertRedirectTo('/login');
    }*/

    public function testAccessIndexLogedUser() {
        $this->mockLogin();
        $params = array('action' => 'index', 'controller' => 'Index', 'module' => 'default');
        $urlParams = $this->urlizeOptions($params);
        $url = $this->url($urlParams);
        $this->dispatch($url);
        // assertions
        $this->assertRedirectTo('/participante');
    }
}
