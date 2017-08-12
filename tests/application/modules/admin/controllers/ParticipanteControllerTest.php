<?php

class Admin_ParticipanteControllerTest extends AbstractControllerTest {

    /**
     * @test
     */
    public function accessIndexAction()
    {
        $this->mockLogin();
        $params = array(
            'action' => 'index',
            'controller' => 'Participante',
            'module' => 'admin'
        );
        $urlParams = $this->urlizeOptions($params);
        $url = $this->url($urlParams);
        $this->dispatch($url);
        // assertions
        $this->assertModule($urlParams['module']);
        $this->assertController($urlParams['controller']);
        $this->assertAction($urlParams['action']);
    }

    /**
     * @test
     */
    public function ajaxBuscarAction()
    {
        $this->mockLogin();
        $this->request
            ->setMethod('POST')
            ->setHeader('X-Requested-With', 'XMLHttpRequest')
            ->setPost(array(
                'format' => 'json',
                'termo' => 'admin',
                'buscar_por' => 'nome'
            ));
        $this->dispatch('/admin/participante/ajax-buscar');

        $this->assertHeaderContains('content-type', 'application/json');
        $this->assertResponseCode(200);
        $json = json_decode($this->response->getBody(), true);
        $this->assertArrayHasKey('lista', $json);
        $this->assertTrue(count($json['lista']) > 0);
    }

    /**
     * @test
     */
    public function accessPreInscricaoAction()
    {
        $this->mockLogin();
        $params = array(
            'action' => 'pre-inscricao',
            'controller' => 'Participante',
            'module' => 'admin'
        );
        $urlParams = $this->urlizeOptions($params);
        $url = $this->url($urlParams);
        $this->dispatch($url);
        // assertions
        $this->assertModule($urlParams['module']);
        $this->assertController($urlParams['controller']);
        $this->assertAction($urlParams['action']);
    }

    /**
     * @test
     */
    public function ajaxBuscarNaoInscritosAction()
    {
        $this->mockLogin();
        $this->request
            ->setMethod('POST')
            ->setHeader('X-Requested-With', 'XMLHttpRequest')
            ->setPost(array(
                'format' => 'json',
                'termo' => 'admin',
                'buscar_por' => 'nome'
            ));
        $this->dispatch('/admin/participante/ajax-buscar-nao-inscritos');

        $this->assertHeaderContains('content-type', 'application/json');
        $this->assertResponseCode(200);
        $json = json_decode($this->response->getBody(), true);
        $this->assertArrayHasKey('lista', $json);
        $this->assertTrue(count($json['lista']) == 0);
    }
}
