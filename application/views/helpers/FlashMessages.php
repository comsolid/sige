<?php
/**
 * Description of FlashMessages
 *
 * @author atila
 */
class Zend_View_Helper_FlashMessages extends Zend_View_Helper_Abstract {
    public function flashMessages() {
        $flash = Zend_Controller_Action_HelperBroker::getStaticHelper('FlashMessenger');
        $messages = $flash->getMessages();
        if ($flash->hasCurrentMessages()) {
            $messages = array_merge($messages, $flash->getCurrentMessages());
            $flash->clearCurrentMessages();
        }

        $output = '';
        if (!empty($messages)) {
            foreach ($messages as $message) {
                $output .= '<div class="alert alert-' . key($message) . '" role="alert">';
                $output .= '<button type="button" class="close" data-dismiss="alert">';
                $output .= '<span aria-hidden="true">&times;</span><span class="sr-only">Close</span></button>';
                $output .= '<strong>';
                switch (key($message)) {
                    case 'warning':
                        $output .= _('Warning!');
                        break;
                    case 'info':
                        $output .= _('Heads up!');
                        break;
                    case 'danger':
                        $output .= _('Error!');
                        break;
                    case 'success':
                        $output .= _('Success!');
                        break;
                }
                $output .= '</strong> ' . current($message) . '</div>';
            }
        }
        return $output;
    }
}
?>
