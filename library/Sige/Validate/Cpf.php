<?php

/**
 * Validador para Cadastro de Pessoa Física
 *
 * @author   Wanderson Henrique Camargo Rosa
 * @category Sige
 * @package  Sige_Validate
 */
class Sige_Validate_Cpf extends Sige_Validate_CpAbstract
{
    /**
     * Tamanho do Campo
     * @var int
     */
    protected $_size = 11;

    /**
     * Modificadores de Dígitos
     * @var array
     */
    protected $_modifiers = array(
        array(10,9,8,7,6,5,4,3,2),
        array(11,10,9,8,7,6,5,4,3,2)
    );
}
