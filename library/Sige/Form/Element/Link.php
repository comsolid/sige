<?php

/**
 * Description of Link
 *
 * @author atila
 */
class Sige_Form_Element_Link extends Zend_Form_Element_Xhtml {

    public $helper = 'formNote';

    /**
     * Constructor
     *
     * @param  string|array|Zend_Config $spec Element name or configuration
     * @param  string|array|Zend_Config $options Element value or configuration
     * @return void
     */
    public function __construct($spec, $options = null) {
        if (is_string($spec) && ((null !== $options) && is_string($options))) {
            $options = array('label' => $options);
        }

        if (!isset($options['ignore'])) {
            $options['ignore'] = true;
        }

        parent::__construct($spec, $options);
    }

    public function isValid($value, $context = null) {
        return true;
    }

    /**
     * Generates an url given the name of a route.
     *
     * @access public
     *
     * @param  array $urlOptions Options passed to the assemble method of the Route object.
     * @param  mixed $name The name of a Route to use. If null it will use the current Route
     * @param  bool $reset Whether or not to reset the route defaults with those provided
     * @return string Url for the link href attribute.
     */
    public function setUrl($content, array $urlOptions = array(), $name = null, $reset = false, $encode = true) {
        $router = Zend_Controller_Front::getInstance()->getRouter();
        $this->setValue('<a href="' .
                $router->assemble($urlOptions, $name, $reset, $encode) .
                '" class="btn-cancelar">' .
                $content .
                '</a>');
    }

}
