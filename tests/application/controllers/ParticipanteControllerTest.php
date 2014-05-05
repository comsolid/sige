<?

require_once realpath(dirname(__FILE__) . '/../ControllerTestCase.php');

class ParticipanteControllerTest extends ControllerTestCase {
    
    private function login() {
        $this->dispatch('/login');
        $this->resetResponse();
        $this->request->setMethod('POST')
                      ->setPost(array(
                          'email' => 'test@mail.com',
                          'senha' => '123456',
                      ));
        $this->dispatch('/login');
        $this->resetRequest()
             ->resetResponse();
 
        $this->request->setMethod('GET')
             ->setPost(array());
    }
    
    public function testAccessParticipantPage() {
        $this->login();
        $this->dispatch('/participante');
        // TODO: ver como faz para testar redirect apropriadamente.
        // issue: http://framework.zend.com/issues/browse/ZF-7496
    }
    
    public function testAccessParticipantPageWithoutCredentials() {
        $this->request->setMethod('GET');
        $this->dispatch('/participante');
        $this->assertResponseCode(500);
        // TODO: ver como faz para testar redirect apropriadamente.
        // issue: http://framework.zend.com/issues/browse/ZF-7496
    }
    
    public function testAccessUserPage() {
        $this->dispatch('/u/teste');
        $this->assertController('participante');
        $this->assertAction('ver');
        
        $this->dispatch('/u/1');
        $this->assertController('participante');
        $this->assertAction('ver');
        
        $this->dispatch('/participante/ver');
    }
    
    public function testAccessUserPageWithCredentials() {
        $this->login();
        
        $auth = Zend_Auth::getInstance();
        $this->assertTrue($auth->hasIdentity());
        
        $this->dispatch('/participante/ver');
        $this->assertController('participante');
        $this->assertAction('ver');
    }
}