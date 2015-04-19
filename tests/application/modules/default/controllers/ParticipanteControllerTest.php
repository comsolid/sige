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

    public function testAlterarSenhaAntigaIncorreta() {
        $this->mockLogin();

        $params = array('action' => 'alterar-senha', 'controller' => 'Participante', 'module' => 'default');
        $urlParams = $this->urlizeOptions($params);
        $url = $this->url($urlParams);
        $this->request->setMethod('POST');
        $this->request->setPost(array(
            'senhaAntiga' => 'fakefake',
            'senhaNova' => '654321',
            'senhaNovaRepeticao' => '654321',
        ));
        $this->dispatch($url);
        // assertions
        $this->assertModule($urlParams['module']);
        $this->assertController($urlParams['controller']);
        $this->assertAction($urlParams['action']);
        $this->assertQueryCount('div.alert-danger', 1);
    }

    public function testAlterarSenhaNovaNaoConfere() {
        $this->mockLogin();

        $params = array('action' => 'alterar-senha', 'controller' => 'Participante', 'module' => 'default');
        $urlParams = $this->urlizeOptions($params);
        $url = $this->url($urlParams);
        $this->request->setMethod('POST');
        $this->request->setPost(array(
            'senhaAntiga' => '123456',
            'senhaNova' => '111111',
            'senhaNovaRepeticao' => '111222',
        ));
        $this->dispatch($url);
        // assertions
        $this->assertModule($urlParams['module']);
        $this->assertController($urlParams['controller']);
        $this->assertAction($urlParams['action']);
        $this->assertQueryCount('div.alert-danger', 1);
    }

    public function testAlterarSenhaSucesso() {
        $this->mockLogin();

        $params = array('action' => 'alterar-senha', 'controller' => 'Participante', 'module' => 'default');
        $urlParams = $this->urlizeOptions($params);
        $url = $this->url($urlParams);
        $this->request->setMethod('POST');
        $this->request->setPost(array(
            'senhaAntiga' => '123456',
            'senhaNova' => '123456',
            'senhaNovaRepeticao' => '123456',
        ));
        $this->dispatch($url);
        // assertions
        $this->assertRedirectTo('/participante');
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

    public function testVerPorId() {
        $params = array(
            'action' => 'ver',
            'controller' => 'Participante',
            'module' => 'default',
            'id' => 1,
        );
        $urlParams = $this->urlizeOptions($params);
        $url = $this->url($urlParams);
        $this->dispatch($url);
        // assertions
        $this->assertModule($urlParams['module']);
        $this->assertController($urlParams['controller']);
        $this->assertAction($urlParams['action']);
    }

    public function testVerPorTwitterUsername() {
        $params = array(
            'action' => 'ver',
            'controller' => 'Participante',
            'module' => 'default',
            'id' => 'comsolid',
        );
        $urlParams = $this->urlizeOptions($params);
        $url = $this->url($urlParams);
        $this->dispatch($url);
        // assertions
        $this->assertModule($urlParams['module']);
        $this->assertController($urlParams['controller']);
        $this->assertAction($urlParams['action']);
    }

    public function testVerUsuarioNaoEncontrado() {
        $params = array(
            'action' => 'ver',
            'controller' => 'Participante',
            'module' => 'default',
        );
        $urlParams = $this->urlizeOptions($params);
        $url = $this->url($urlParams);
        $this->dispatch($url);
        // assertions
        $this->assertModule($urlParams['module']);
        $this->assertController($urlParams['controller']);
        $this->assertAction($urlParams['action']);
        $this->assertQueryCount('div.alert-danger', 1);
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

    public function testAccessNotLogedUser() {
        $params = array('action' => 'index', 'controller' => 'Participante', 'module' => 'default');
        $urlParams = $this->urlizeOptions($params);
        $url = $this->url($urlParams);
        $this->dispatch($url);
        // assertions
        $this->assertRedirectTo('/login');
    }

    public function testCriarEmailExistente() {
        $params = array('action' => 'criar', 'controller' => 'Participante', 'module' => 'default');
        $urlParams = $this->urlizeOptions($params);
        $url = $this->url($urlParams);
        $this->request->setMethod('POST');
        $this->request->setPost(array(
            'email' => 'comsolid@comsolid.org',
            'nome' => 'Teste',
            'apelido' => 'Teste',
            'id_sexo' => 0,
            'nascimento' => '01/01/1900',
            'id_municipio' => 1,
            'id_instituicao' => 1
        ));
        $this->dispatch($url);
        // assertions
        $this->assertModule($urlParams['module']);
        $this->assertController($urlParams['controller']);
        $this->assertAction($urlParams['action']);
        $this->assertQueryCount('div.alert-warning', 1);
    }
}
