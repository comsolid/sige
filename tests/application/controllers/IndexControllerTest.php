<?

require_once realpath(dirname(__FILE__) . '/../ControllerTestCase.php');

class IndexControllerTest extends ControllerTestCase {
    
    public function testAccessRoot() {
        $params = array(
            'action' => 'index',
            'controller' => 'index',
        );
        
        $url = $this->url($this->urlizeOptions($params));
        $this->dispatch($url);

        // assertions
        $this->assertController('index');
        $this->assertAction('index');
    }
    
    public function testSuccessfulLogin() {
        $this->request->setMethod('POST')
                      ->setPost(array(
                          'email' => 'teste@mail.com',
                          'senha' => '123456',
                      ));
        $this->dispatch('/login');
        $this->assertRedirectTo('/participante');
    }
    
    public function testSuccessfulLogout() {
        $this->request->setMethod('POST')
                      ->setPost(array(
                          'email' => 'teste@mail.com',
                          'senha' => '123456',
                      ));
        $this->dispatch('/login');
        
        $this->resetRequest()
             ->resetResponse();
 
        $this->request->setMethod('GET')
             ->setPost(array());
        
        $this->dispatch('/logout');
        $this->assertRedirectTo('/');
    }
    
    public function testAccessAboutPage() {
        $this->dispatch('/sobre');
        // assertions
        $this->assertController('index');
        $this->assertAction('sobre');
    }
}