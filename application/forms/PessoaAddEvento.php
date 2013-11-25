<?php
class Application_Form_PessoaAddEvento extends Zend_Form {

	public function init() {

	}

	public function criarFormulario($eventosTabela) {
		$this->setAction('/participante/pessoaaddevento')->setMethod('post');

		foreach ($eventosTabela as $item) {

			$selecaoEvento = $this->createElement('checkbox', "".$item["evento"]);

			$this->addElement($selecaoEvento);
		}
		
		$this->addElement('submit', 'confirmar', array('label' => 'Confimar'));
	}

}