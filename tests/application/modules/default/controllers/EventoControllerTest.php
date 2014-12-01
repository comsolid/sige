<?php

class Default_EventoControllerTest extends Default_AbstractControllerTest {
    
    public function testAccessIndexAction() {
        $this->mockLogin();
        $params = array('action' => 'index', 'controller' => 'Evento', 'module' => 'default');
        $urlParams = $this->urlizeOptions($params);
        $url = $this->url($urlParams);
        $this->dispatch($url);
        // assertions
        $this->assertModule($urlParams['module']);
        $this->assertController($urlParams['controller']);
        $this->assertAction($urlParams['action']);
    }
    
    public function testSubmeterAction() {
        $this->mockLogin();
        $params = array('action' => 'submeter', 'controller' => 'Evento', 'module' => 'default');
        $urlParams = $this->urlizeOptions($params);
        $url = $this->url($urlParams);
        $this->dispatch($url);
        // assertions
        $this->assertModule($urlParams['module']);
        $this->assertController($urlParams['controller']);
        $this->assertAction($urlParams['action']);
    }
    
    public function testEditarAction() {
        $this->mockLogin();
        $params = array('action' => 'editar', 'controller' => 'Evento', 'module' => 'default');
        $urlParams = $this->urlizeOptions($params);
        $url = $this->url($urlParams);
        $this->dispatch($url);
        // assertions
        $this->assertModule($urlParams['module']);
        $this->assertController($urlParams['controller']);
        $this->assertAction($urlParams['action']);
    }
    
    public function testProgramacaoAction() {
        $params = array('action' => 'programacao', 'controller' => 'Evento', 'module' => 'default');
        $urlParams = $this->urlizeOptions($params);
        $url = $this->url($urlParams);
        $this->dispatch($url);
        // assertions
        $this->assertModule($urlParams['module']);
        $this->assertController($urlParams['controller']);
        $this->assertAction($urlParams['action']);
    }
    
    public function testInteresseAction() {
        $this->mockLogin();
        $params = array('action' => 'interesse', 'controller' => 'Evento', 'module' => 'default');
        $urlParams = $this->urlizeOptions($params);
        $url = $this->url($urlParams);
        $this->dispatch($url);
        // assertions
        $this->assertModule($urlParams['module']);
        $this->assertController($urlParams['controller']);
        $this->assertAction($urlParams['action']);
    }
    
    public function testVerAction() {
        $this->mockLogin();
        $params = array('id' => 1, 'action' => 'ver', 'controller' => 'Evento', 'module' => 'default');
        $urlParams = $this->urlizeOptions($params);
        $url = $this->url($urlParams);
        $this->dispatch($url);
        // assertions
        $this->assertModule($urlParams['module']);
        $this->assertController($urlParams['controller']);
        $this->assertAction($urlParams['action']);
    }
    
    public function testOutrosPalestrantesAction() {
        $this->mockLogin();
        $params = array('action' => 'outros-palestrantes', 'controller' => 'Evento', 'module' => 'default');
        $urlParams = $this->urlizeOptions($params);
        $url = $this->url($urlParams);
        $this->dispatch($url);
        // assertions
        $this->assertModule($urlParams['module']);
        $this->assertController($urlParams['controller']);
        $this->assertAction($urlParams['action']);
    }
    
    public function testTagsAction() {
        $this->mockLogin();
        $params = array('action' => 'tags', 'controller' => 'Evento', 'module' => 'default');
        $urlParams = $this->urlizeOptions($params);
        $url = $this->url($urlParams);
        $this->dispatch($url);
        // assertions
        $this->assertModule($urlParams['module']);
        $this->assertController($urlParams['controller']);
        $this->assertAction($urlParams['action']);
    }
}
