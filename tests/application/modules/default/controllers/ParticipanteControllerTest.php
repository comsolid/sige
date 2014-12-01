<?php

class Default_ParticipanteControllerTest extends Default_AbstractControllerTest {
    
    public function testAccessCriarAction() {
        $params = array('action' => 'criar', 'controller' => 'Participante', 'module' => 'default');
        $urlParams = $this->urlizeOptions($params);
        $url = $this->url($urlParams);
        $this->dispatch($url);
        // assertions
        $this->assertModule($urlParams['module']);
        $this->assertController($urlParams['controller']);
        $this->assertAction($urlParams['action']);
        $this->assertQueryCount('form#criar_pessoa', 1);
    }
    
    public function testAccessIndexAction() {
        $this->mockLogin();
        
        $params = array('action' => 'index', 'controller' => 'Participante', 'module' => 'default');
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
        
        $params = array('action' => 'editar', 'controller' => 'Participante', 'module' => 'default');
        $urlParams = $this->urlizeOptions($params);
        $url = $this->url($urlParams);
        $this->dispatch($url);
        // assertions
        $this->assertModule($urlParams['module']);
        $this->assertController($urlParams['controller']);
        $this->assertAction($urlParams['action']);
    }
    
    public function testAccessSucessoAction() {
        $params = array('action' => 'sucesso', 'controller' => 'Participante', 'module' => 'default');
        $urlParams = $this->urlizeOptions($params);
        $url = $this->url($urlParams);
        $this->dispatch($url);
        // assertions
        $this->assertModule($urlParams['module']);
        $this->assertController($urlParams['controller']);
        $this->assertAction($urlParams['action']);
    }
    
    public function testAccessAlterarSenhaAction() {
        $this->mockLogin();
        
        $params = array('action' => 'alterar-senha', 'controller' => 'Participante', 'module' => 'default');
        $urlParams = $this->urlizeOptions($params);
        $url = $this->url($urlParams);
        $this->dispatch($url);
        // assertions
        $this->assertModule($urlParams['module']);
        $this->assertController($urlParams['controller']);
        $this->assertAction($urlParams['action']);
    }
    
    public function testAccessVerAction() {
        $this->mockLogin();
        
        $params = array('action' => 'ver', 'controller' => 'Participante', 'module' => 'default');
        $urlParams = $this->urlizeOptions($params);
        $url = $this->url($urlParams);
        $this->dispatch($url);
        // assertions
        $this->assertModule($urlParams['module']);
        $this->assertController($urlParams['controller']);
        $this->assertAction($urlParams['action']);
    }
    
    public function testAccessCertificadosAction() {
        $this->mockLogin();
        
        $params = array('action' => 'certificados', 'controller' => 'Participante', 'module' => 'default');
        $urlParams = $this->urlizeOptions($params);
        $url = $this->url($urlParams);
        $this->dispatch($url);
        // assertions
        $this->assertModule($urlParams['module']);
        $this->assertController($urlParams['controller']);
        $this->assertAction($urlParams['action']);
    }
}
