<?php

class Application_Form_AlterarSenha extends Zend_Form {

	public function init() {

		$senhaAntiga = $this->createElement('password', 'senhaAntiga', array('label' => _('Current Password:')));
		$senhaAntiga->addValidator('stringLength', false, array(6, 15));
        $senhaAntiga->setRequired(true);
		$senhaAntiga->setAttrib('class', 'form-control');
		$senhaAntiga->setAttrib('autocomplete', 'off');
		$senhaAntiga->setAttrib('autofocus', 'autofocus');

		$senhaNova = $this->createElement('password', 'senhaNova', array('label' => _('New Password:')));
		$senhaNova->addValidator('stringLength', false, array(6, 15));
        $senhaNova->setRequired(true);
		$senhaNova->setAttrib('class', 'form-control');

		$senhaNovaRepeticao = $this->createElement('password', 'senhaNovaRepeticao', array('label' => _('Repeat New Password:')));
		$senhaNovaRepeticao->addValidator('stringLength', false, array(6, 15));
        $senhaNovaRepeticao->setRequired(true);
		$senhaNovaRepeticao->setAttrib('class', 'form-control');

		$this->addElement($senhaAntiga)
			->addElement($senhaNova)
			->addElement($senhaNovaRepeticao);
		$submit = $this->createElement('submit', 'submit', array('label' => _('Confirm')));
		$submit->setAttrib('class', 'btn btn-primary');
		$this->addElement($submit);
	}
}
