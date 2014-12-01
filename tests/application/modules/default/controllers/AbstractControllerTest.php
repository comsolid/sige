<?php

abstract class Default_AbstractControllerTest extends Zend_Test_PHPUnit_ControllerTestCase {
    
    public function setUp() {
        $this->bootstrap = new Zend_Application(APPLICATION_ENV, APPLICATION_PATH . '/configs/application.ini');
        parent::setUp();
    }
    
    protected function mockLogin($username = 'comsolid@comsolid.org', $password = '123456') {
        $model = new Application_Model_Pessoa();
        $resultadoConsulta = $model->avaliaLogin($username, $password);
        
        $config = new Zend_Config_Ini(APPLICATION_PATH . '/configs/application.ini', 'staging');
        $idEncontro = $config->encontro->codigo;
        
        $idPessoa = $resultadoConsulta['id_pessoa'];
        $administrador = $resultadoConsulta['administrador'];
        $apelido = $resultadoConsulta['apelido'];
        $twitter = $resultadoConsulta['twitter'];
        
        $auth = Zend_Auth::getInstance();
        $storage = $auth->getStorage();
        $storage->write(array(
            "idPessoa" => $idPessoa,
            "administrador" => $administrador,
            "apelido" => $apelido,
            "idEncontro" => $idEncontro,
            "twitter" => $twitter,
            "email" => $username
        ));
    }
}
