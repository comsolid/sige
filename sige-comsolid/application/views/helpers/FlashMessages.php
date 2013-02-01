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
            $output .= '<div class="' . key($message) . '">';
            $output .= '<div class="msg-header">';
            switch (key($message)) {
               case 'notice':
                  $output .= 'Atenção!';
                  break;
               case 'info':
                  $output .= 'Mantenha-se informado!';
                  break;
               case 'error':
                  $output .= 'Erro!';
                  break;
               case 'success':
                  $output .= 'Sucesso!';
                  break;
            }
            $output .= '</div><div>'. current($message) . '</div></div>';
         }
      }
      return $output;
   }
}

?>
