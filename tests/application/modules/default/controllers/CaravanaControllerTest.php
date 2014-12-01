<?php

class Default_CaravanaControllerTest extends Default_AbstractControllerTest {

    public function testAccessIndexAction() {
        $this->mockLogin();
        $params = array('action' => 'index', 'controller' => 'Caravana', 'module' => 'default');
        $urlParams = $this->urlizeOptions($params);
        $url = $this->url($urlParams);
        $this->dispatch($url);
        // assertions
        $this->assertModule($urlParams['module']);
        $this->assertController($urlParams['controller']);
        $this->assertAction($urlParams['action']);
    }
    
    public function testAccessParticipantesAction() {
        $this->mockLogin();
        $params = array('action' => 'participantes', 'controller' => 'Caravana', 'module' => 'default');
        $urlParams = $this->urlizeOptions($params);
        $url = $this->url($urlParams);
        $this->dispatch($url);
        // assertions
        $this->assertModule($urlParams['module']);
        $this->assertController($urlParams['controller']);
        $this->assertAction($urlParams['action']);
    }
    
    public function testAccessCriarAction() {
        $this->mockLogin();
        $params = array('action' => 'criar', 'controller' => 'Caravana', 'module' => 'default');
        $urlParams = $this->urlizeOptions($params);
        $url = $this->url($urlParams);
        $this->dispatch($url);
        // assertions
        $this->assertModule($urlParams['module']);
        $this->assertController($urlParams['controller']);
        $this->assertAction($urlParams['action']);
    }
    
    public function testAccessEditarAction() {
        $this->mockLogin();
        $params = array('action' => 'editar', 'controller' => 'Caravana', 'module' => 'default');
        $urlParams = $this->urlizeOptions($params);
        $url = $this->url($urlParams);
        $this->dispatch($url);
        // assertions
        $this->assertModule($urlParams['module']);
        $this->assertController($urlParams['controller']);
        $this->assertAction($urlParams['action']);
    }
}
