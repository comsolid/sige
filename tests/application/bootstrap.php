<?php
error_reporting(E_ALL | E_STRICT);

// Define path to application directory
defined('APPLICATION_PATH')
    || define('APPLICATION_PATH', realpath(dirname(__FILE__) . '/../../application'));

// Define application environment
defined('APPLICATION_ENV')
    || define('APPLICATION_ENV', (getenv('APPLICATION_ENV') ? getenv('APPLICATION_ENV') : 'testing'));

// Ensure library/ is on include_path
set_include_path(implode(PATH_SEPARATOR, array(
    realpath(APPLICATION_PATH . '/../library'),
    realpath(APPLICATION_PATH . '/../vendor/zendframework/zendframework1/library'),
    realpath(APPLICATION_PATH . '/../vendor/phpunit'),
    get_include_path(),
)));

require_once realpath(APPLICATION_PATH . '/../vendor/autoload.php');

//require_once 'Zend/Application.php';
//require_once 'ControllerTestCase.php';
require_once 'Zend/Loader/Autoloader.php';
Zend_Loader_Autoloader::getInstance();

putenv('APPLICATION_ENV=testing');
