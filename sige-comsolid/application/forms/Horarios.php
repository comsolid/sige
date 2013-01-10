<?php

class Application_Form_Horarios extends Zend_Form
{
	private  $descricao;
	const HORA_INI = 'hora_inicio';
	const HORA_FIM = 'hora_fim';
	
	
  /**
	 * @return the $descricao
	 */
	public function getDescricao() {
		return $this->descricao;
	}

	/**
	 * @param field_type $descricao
	 */
	public function setDescricao($descricao) {
		$this->descricao = $descricao;
	}

	public function init(){
  
  
	}
  
  
  
   public function cria(){
  	
		$this->setMethod("post");
		
		$descricao = $this->createElement('text', 'descricao', array('label' => 'Descrição: '));
		$descricao->setValue($this->getDescricao());

		$salas = new Application_Model_Sala();
		$salas->fetchAll();
		
		$salasForm = $this->createElement('select', 'id_sala', array('label'=>'Salas: '));
		
		foreach ($salas->fetchAll() as $sala){
			$salasForm->addMultiOptions(array($sala->id_sala => $sala->nome_sala));
		}
		
		/*$data = $this->createElement('radio', 'data',array('label' => 'Data: '));
		$data->addMultiOptions(array('2012-12-06' => '06/12/2012',
											  '2012-12-07' => '07/12/2012',
									'2012-12-08' => '08/12/2012'))
			->setRequired(true)->addErrorMessage("Escolha uma data para realização do evento");*/

		$this->addElement($descricao)
	      ->addElement($salasForm)
	      ->addElement($this->_data())
	      ->addElement($this->_hora(self::HORA_INI, 'Horário Inicio:'))
	      ->addElement($this->_hora(self::HORA_FIM, 'Horário Término:'));
		
		/*$horario = $this->createElement('checkbox', 'horarios', array('label'=>'Horário'));
		
		//$select = "SELECT TO_CHAR(hora_inicial, 'HH24:MI:SS') as hora_inicio, TO_CHAR(hora_final, 'HH24:MI:SS') as hora_fim FROM encontro_horario  WHERE id_encontro_horario NOT IN (2,7) ORDER BY hora_inicial";
		$select = "SELECT TO_CHAR(hora_inicial, 'HH24:MI:SS') as hora_inicio, TO_CHAR(hora_final, 'HH24:MI:SS') as hora_fim FROM encontro_horario  ORDER BY hora_inicial";
		$x=0;
		foreach ($salas->getAdapter()->fetchAll($select) as $h){
			$horario = $this->createElement('checkbox', "horario$x", array('label'=>$h['hora_inicio'] .' às '. $h['hora_fim']));
			$horario->setCheckedValue($h['hora_inicio'] ."_". $h['hora_fim']);
			
			$this->addElement($horario);
			$x++;
		}*/
		
		$botao = $this->createElement('submit', 'confimar')->removeDecorator('DtDdWrapper');
		$this->addElement($botao);
		$botao = $this->createElement('reset', 'cancelar')->removeDecorator('DtDdWrapper');
		$this->addElement($botao);
		$this->addElement($botao);
   }

   private function _data() {
		$model = new Application_Model_Encontro();
		$sessao = Zend_Auth::getInstance()->getIdentity();
		$where = $model->getAdapter()->quoteInto('id_encontro = ?', $sessao["idEncontro"]);
		$row = $model->fetchRow($where);
		$element = $this->createElement('radio', 'data', array('label' => 'Data: '));
		$data_ini = new Zend_Date($row->data_inicio);
		$data_fim = new Zend_Date($row->data_fim);
		while ($data_ini <= $data_fim) {
			$element->addMultiOption($data_ini->toString('YYYY-MM-dd'), $data_ini->toString('dd/MM/YYYY'));
			$data_ini->add(1, Zend_Date::DAY);
		}
		$element->setRequired(true)->addErrorMessage("Escolha uma data para realização do evento");
		return $element;
	}

	private function _hora($id, $label) {
		$element = new Zend_Form_Element_Select($id);
		$element->setRequired(true)
		  ->setLabel($label);
		$hora_aux = $hora_min = new Zend_Date('08:00', 'HH:mm');
		$hora_max = new Zend_Date('17:00', 'HH:mm');
		while ($hora_aux <= $hora_max) {
			if (self::HORA_INI == $id and $hora_aux == $hora_max) {
				$hora_aux->add(1, Zend_Date::HOUR);
				continue;
			} else if (self::HORA_FIM == $id and $hora_aux == new Zend_Date('08:00', 'HH:mm')) {
				$hora_aux->add(1, Zend_Date::HOUR);
				continue;
			}
			$element->addMultiOption($hora_aux->toString('HH:mm'), $hora_aux->toString('HH:mm'));
			$hora_aux->add(1, Zend_Date::HOUR);
		}
		return $element;
	}
}