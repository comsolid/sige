<?php

class Application_Form_AlterarSenha extends Zend_Form {
	
	public function init() {
          
		$senhaAntiga = $this->createElement('password', 'senhaAntiga',array('label' => _('Current Password:')));
		$senhaAntiga->addValidator('stringLength', false, array(6, 15))
          ->setRequired(true);
          
		$senhaNova = $this->createElement('password', 'senhaNova',array('label' => _('New Password:')));
		$senhaNova ->addValidator('stringLength', false, array(6, 15))
          ->setRequired(true);
          
		$senhaNovaRepeticao = $this->createElement('password', 'senhaNovaRepeticao',array('label' => _('Repeat New Password:')));
		$senhaNovaRepeticao ->addValidator('stringLength', false, array(6, 15))
          ->setRequired(true);
    
		$this->addElement($senhaAntiga)
			->addElement($senhaNova)
			->addElement($senhaNovaRepeticao);
		$submit = $this->createElement('submit', _('Confirm'))->removeDecorator('DtDdWrapper');
		$this->addElement($submit);
		$cancel = $this->createElement('submit', _('Cancel'))->removeDecorator('DtDdWrapper');
		$cancel->setAttrib('class','submitCancelar');
		$cancel->setAttrib('name','cancelar');
		$this->addElement($cancel);
	}
}