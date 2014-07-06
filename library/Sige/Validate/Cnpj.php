<?php

/**
 * Validador para Cadastro de Pessoa Jurídica
 *
 * @author   Wanderson Henrique Camargo Rosa
 * @category Sige
 * @package  Sige_Validate
 */
class Sige_Validate_Cnpj extends Sige_Validate_CpAbstract
{
    /**
     * Tamanho do Campo
     * @var int
     */
    protected $_size = 14;

    /**
     * Modificadores de Dígitos
     * @var array
     */
    protected $_modifiers = array(
        array(5,4,3,2,9,8,7,6,5,4,3,2),
        array(6,5,4,3,2,9,8,7,6,5,4,3,2)
    );
}
