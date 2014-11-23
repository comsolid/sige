<?php

class Url_Validator extends Zend_Validate_Abstract {

   const INVALID_URL = 'invalidUrl';

   protected $_messageTemplates = array(
       self::INVALID_URL => "'%value%' is not a valid URL.",
   );

   public function isValid($value) {
      $valueString = (string) $value;
      $this->_setValue($valueString);

      if (!Zend_Uri::check($value)) {
         $this->_error(self::INVALID_URL);
         return false;
      }
      return true;
   }

}

class Application_Form_PessoaEdit extends Zend_Form {

    public function init() {
      // TODO: colocar a criação de elementos dentro de métodos
      // TODO: criar classe compartilhada entre elementos que estão em criar e editar
      $nome = $this->createElement('text', 'nome', array('label' => '* ' . _('Name:')));
      $nome->setAttrib('class', 'form-control');
      $nome->setRequired(true)
              ->addValidator('regex', false, array('/^[ a-zA-ZáéíóúàìòùãẽĩõũâêîôûäëïöüçÇÁÉÍÓÚ]*$/'))
              ->addValidator('stringLength', false, array(1, 100))
              ->addErrorMessage(_("Name must have at least 1 character. Or contains invalid characters"));

      $apelido = $this->createElement('text', 'apelido', array('label' => '* ' . _('Nickname:')));
      $apelido->setAttrib('class', 'form-control');
      $apelido->setRequired(true)
              ->addValidator('stringLength', false, array(1, 20))
              ->addFilter('StripTags')
              ->addFilter('StringTrim')
              ->addErrorMessage(_("Nickname must have at least 1, max. 20 characters"));

      $modelSexo = new Application_Model_Sexo();
      $rs = $modelSexo->fetchAll(null, 'id_sexo ASC');
      $sexo = $this->createElement('radio', 'id_sexo', array('label' => _('Gender:')));
      $sexo->setRequired(true)
              ->setSeparator('');
      foreach ($rs as $row) {
         $sexo->addMultiOption($row->id_sexo, $row->descricao_sexo);
      }

      $cidade = new Application_Model_Municipio();
      $listaCiddades = $cidade->fetchAll(null, 'nome_municipio');

      $municipio = $this->createElement('select', 'id_municipio', array('label' => _('District:')));
      $municipio->setAttrib("class", "select2");
      foreach ($listaCiddades as $item) {
         $municipio->addMultiOptions(array($item->id_municipio => $item->nome_municipio));
      }

      $ins = new Application_Model_Instituicao();
      $listaIns = $ins->fetchAll(null, 'nome_instituicao');

      $instituicao = $this->createElement('select', 'id_instituicao', array('label' => _('Institution:')));
      $instituicao->setAttrib("class", "select2");
      foreach ($listaIns as $item) {
         $instituicao->addMultiOptions(array($item->id_instituicao => $item->nome_instituicao));
      }

      $this->addElement($nome)
              ->addElement($apelido)
              ->addElement($sexo)
              ->addElement($municipio)
              ->addElement($instituicao)
              ->addElement($this->_nascimento())
              ->addElement($this->_cpf())
              ->addElement($this->_telefone())
              ->addElement($this->_bio())
              ->addElement($this->_twitter())
              ->addElement($this->_facebook())
              ->addElement($this->_slideshare())
              ->addElement($this->_website());

      $submit = new Zend_Form_Element_Submit('submit');
      $submit->setLabel(_("Confirm"))
              ->setAttrib('id', 'submitbutton')
              ->setAttrib('class', 'btn btn-primary');
      $submit->setDecorators(array(
          'ViewHelper',
          'Description',
          'Errors',
      ));
      $this->addElement($submit);
   }

    protected function _bio() {
        $e = new Zend_Form_Element_Textarea('bio');
        $e->setLabel('Bio:')
              ->setAttrib('rows', 5)
              ->setAttrib('placeholder', _('Write a little about yourself...'))
              ->addFilter('StripTags')
              ->addFilter('StringTrim');
        $e->setAttrib('class', 'form-control');
        return $e;
    }

   private function _twitter() {
      $e = $this->createElement('text', 'twitter', array('label' => 'Twitter: @'));
      $e->addValidator('regex', false, array('/^[A-Za-z0-9_]*$/'))
              ->addErrorMessage(_("Invalid Twitter username"));
      $e->setAttrib('class', 'form-control');
      return $e;
   }

   private function _facebook() {
      $e = $this->createElement('text', 'facebook', array('label' => 'Facebook: '));
      $e->addValidator('regex', false, array('/^[A-Za-z0-9_]*$/'))
              ->addErrorMessage(_("Invalid Facebook username"));
      $e->setAttrib('class', 'form-control');
      return $e;
   }

   private function _website() {
      $e = $this->createElement('text', 'endereco_internet', array('label' => _('Website:')));
      $e->setAttrib("placeholder", "http://www.comsolid.org")
              ->addValidator(new Url_Validator)
              ->addErrorMessage(_("Invalid website"));
      $e->setAttrib('class', 'form-control');
      return $e;
   }

   private function _slideshare() {
      $e = $this->createElement('text', 'slideshare', array('label' => 'Slideshare: '));
      $e->addValidator('regex', false, array('/^[A-Za-z0-9_]*$/'))
              ->addErrorMessage(_("Invalid Slideshare username"));
      $e->setAttrib('class', 'form-control');
      return $e;
   }

   /**
    * Uncomment this method if you want to use only the birth year
    * Descomente este método se você deseja usar somente o ano de nascimento
    * @return {[Zend_Form_Element_Select]}
    */
   protected function _nascimento() {
       $e = new Zend_Form_Element_Select('nascimento');
       $e->setLabel('* ' . _('Birth Date:'));
       $e->setAttrib("class", "select2");
       $date = new Zend_Date();
       $ano = (int) $date->toString('YYYY');
       for($i = $ano; $i > 1959; $i--) {
           $e->addMultiOptions(array("01/01/$i" => "$i"));
       }

       return $e;
   }

   /**
    * Uncomment this method if you want to use the whole birth date
    * Descomente este método se você deseja usar a data de nascimento completa
    * @return {[Zend_Form_Element_Text]}
    */
   /*protected function _nascimento() {
       $e = new Zend_Form_Element_Text('nascimento');
       $e->setLabel('* ' . _('Birth Date:'));
       $e->setRequired(true);
       $e->setAttrib("class", "date");
       $e->setAttrib("data-required", "true");
       $e->addFilter('StripTags');
       $e->addFilter('StringTrim');
       $e->addValidator(new Zend_Validate_Date(array('format' => 'dd/MM/yyyy')));

       return $e;
   }*/

   protected function _cpf() {
       $e = new Zend_Form_Element_Text('cpf');
       $e->setLabel(_('SSN:')); // SSN: Social Security Number
       $e->addFilter('Digits');
       $e->addValidator(new Sige_Validate_Cpf());
       $e->setRequired(false); // change to true to be required.
       // $e->setAttrib("data-required", "true"); // uncomment for validation through js

       $e->setAttrib('class', 'form-control');
       return $e;
   }

   protected function _telefone() {
       $e = new Zend_Form_Element_Text('telefone');
       $e->setLabel(_('Phone Number:'));
       $e->addFilter('Digits');
       $e->setRequired(false);

       $e->setAttrib('class', 'form-control');
       return $e;
   }
}
