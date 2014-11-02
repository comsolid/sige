<?php

/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

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
               case 'notice': // TODO: remover notice
               case 'warning':
                  $output .= _('Heads up!');
                  break;
               case 'info':
                  $output .= _('Warning!');
                  break;
               case 'error': // TODO: remover error
               case 'danger':
                  $output .= _('Error!');
                  break;
               case 'success':
                  $output .= _('Success!');
                  break;
            }
            $output .= '</strong> '. current($message) . '</div>';
         }
      }
      return $output;
   }
}

?>
