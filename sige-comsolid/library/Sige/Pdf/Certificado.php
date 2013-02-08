<?php

/**
 * Classe para gerar certificados de participantes e palestrantes.
 *
 * @author atila
 */
class Sige_Pdf_Certificado {
   
   const NUM_MAX_CARACTERES = 70;
   const POS_X_INICIAL = 120;
   const POS_Y_INICIAL = 340;
   const DES_Y = 20;
   const TAM_FONTE = 14;
   const POS_X1_INI_ASSINATURA = 130;
   const POS_X2_INI_ASSINATURA = 260;
   const POS_Y1_ASSINATURA = 120;
   const POS_Y2_ASSINATURA = 200;
   const DES_X = 220;
   
   public function palestrante(
           $array = array(
               'nome' => '',
               'id_encontro' => 0, // serve para identificar o modelo
               'encontro' => '',
               'tipo_evento' => '',
               'nome_evento' => ''
           )
   ) {
      include_once 'strings.palestrante.php';
      
      $linhas = array();
      $linhas[] = $this->str_center(sprintf($string[0], $array['nome']), Sige_Pdf_Certificado::NUM_MAX_CARACTERES);
      $linhas[] = $this->str_center(sprintf($string[1], $array['encontro']), Sige_Pdf_Certificado::NUM_MAX_CARACTERES);
      
      $str2 = sprintf($string[2], $array['tipo_evento'], $array['nome_evento']);
      $l3 = $this->truncate_str($str2, Sige_Pdf_Certificado::NUM_MAX_CARACTERES);
      $l4 = substr($str2, strlen($l3), strlen($str2));
      $linhas[] = $this->str_center($l3, Sige_Pdf_Certificado::NUM_MAX_CARACTERES);
      $linhas[] = $this->str_center($l4, Sige_Pdf_Certificado::NUM_MAX_CARACTERES);
      //$linhas[] = ""; // saltar linha
      $date = new Zend_Date();
      $linhas[] = $this->str_pad_left(sprintf($string[3], $date->toString("dd 'de' MMMM 'de' y")), Sige_Pdf_Certificado::NUM_MAX_CARACTERES);
       
      return $this->gerarCertificado($array['id_encontro'], $linhas);
   }
   
   public function participante(
           $array = array(
               'nome' => '',
               'id_encontro' => 0, // serve para identificar o modelo
               'encontro' => '',
           )
   ) {
      include_once 'strings.participante.php';
      
      $linhas = array();
      $linhas[] = $this->str_center(sprintf($string[0], $array['nome']), Sige_Pdf_Certificado::NUM_MAX_CARACTERES);
      $linhas[] = $this->str_center(sprintf($string[1], $array['encontro']), Sige_Pdf_Certificado::NUM_MAX_CARACTERES);
      $linhas[] = ""; // saltar linha
      $linhas[] = ""; // saltar linha
      $date = new Zend_Date();
      $linhas[] = $this->str_pad_left(sprintf($string[2], $date->toString("dd 'de' MMMM 'de' y")), Sige_Pdf_Certificado::NUM_MAX_CARACTERES);
      
      // Get PDF document as a string 
      return $this->gerarCertificado($array['id_encontro'], $linhas);
   }
   
   private function gerarCertificado($idEncontro, $array = array()) {
      
      // include auto-loader class
      require_once 'Zend/Loader/Autoloader.php';

      // register auto-loader
      $loader = Zend_Loader_Autoloader::getInstance();

      $pdf = new Zend_Pdf();
      $page1 = $pdf->newPage(Zend_Pdf_Page::SIZE_A4_LANDSCAPE);
      $font = Zend_Pdf_Font::fontWithName(Zend_Pdf_Font::FONT_COURIER_BOLD);
      $page1->setFont($font, Sige_Pdf_Certificado::TAM_FONTE);

      // configura o plano de fundo
      $this->background($page1, $idEncontro);
      
      for ($index = 0; $index < count($array); $index++) {
         $page1->drawText(
                 $array[$index],
                 Sige_Pdf_Certificado::POS_X_INICIAL,
                 Sige_Pdf_Certificado::POS_Y_INICIAL - ($index * Sige_Pdf_Certificado::DES_Y),
                 'UTF-8');
      }
      
      // configura a(s) assinatura(s)
      $this->assinaturas($page1, $idEncontro);

      $pdf->pages[] = ($page1);
      // salve apenas em modo debug!
      // $pdf->save(APPLICATION_PATH . '/../tmp/certificado-participante.pdf');
      
      // Get PDF document as a string 
      return $pdf->render();
   }
   
   private function background(Zend_Pdf_Page $page, $idEncontro = 0) {
      if ($idEncontro > 0) {
         
         $file = APPLICATION_PATH . "/../public/img/certificados/{$idEncontro}/modelo.jpg";
         if (!file_exists($file)) {
            $file = APPLICATION_PATH . "/../public/img/certificados/default/modelo.jpg";
         }

         if (!file_exists($file)) {
            throw new Exception("É necessário que o arquivo {$file} exista.");
         }
         
         $height = $page->getHeight();
         $width = $page->getWidth();
         $image = Zend_Pdf_Image::imageWithPath($file);
         $page->drawImage($image, 0, 0, $width, $height);
      }
   }
   
   private function assinaturas(Zend_Pdf_Page $page, $idEncontro = 0) {
      
      if ($idEncontro > 0) {
         //$file = APPLICATION_PATH . "/../public/img/certificados/{$idEncontro}/assinatura-%d.png";
         $dir = APPLICATION_PATH . "/../public/img/certificados/{$idEncontro}/";
         if (!is_dir($dir)) {
            $dir = APPLICATION_PATH . "/../public/img/certificados/default/";
         }
      }
      
      if (!is_dir($dir)) {
         throw new Exception("É necessário que o diretório {$dir} exista.");
      }
      
      $file = "{$dir}/assinatura-%d.png";
      
      $maxAssinaturas = 3;
      for ($index = 0; $index < $maxAssinaturas; $index++) {
         $auxFile = sprintf($file, $index + 1);
         if (file_exists($auxFile)) {
            $image = Zend_Pdf_Image::imageWithPath($auxFile);
            $page->drawImage(
                    $image,
                    // x1
                    Sige_Pdf_Certificado::POS_X1_INI_ASSINATURA
                        + ($index * Sige_Pdf_Certificado::DES_X),
                    // y1
                    Sige_Pdf_Certificado::POS_Y1_ASSINATURA,
                    // x2
                    Sige_Pdf_Certificado::POS_X2_INI_ASSINATURA
                        + ($index * Sige_Pdf_Certificado::DES_X),
                    // y2
                    Sige_Pdf_Certificado::POS_Y2_ASSINATURA
             );
         }
      }
   }
   
   public function str_center($str, $tam = 0, $pad = " ") {
      if ($str == null or empty($str) or $tam <= 0) {
         return "";
      }
      
      $len = strlen($str);
      $pads = $tam - $len;
      if ($pads <= 0) {
         return $str;
      }
      $str = str_pad($str, $len + $pads / 2, $pad, STR_PAD_LEFT);
      $str = str_pad($str, $tam, $pad);
      //$str = str_pad($str, $tam, $pad, STR_PAD_BOTH);
      return $str;
   }
   
   public function str_pad_left($str, $tam = 0, $pad = " ") {
      if ($str == null or empty($str) or $tam <= 0) {
         return "";
      }
      
      $str = str_pad($str, $tam, $pad, STR_PAD_LEFT);
      return $str;
   }
   
   public function truncate_str($str, $maxlen) {
      if (strlen($str) <= $maxlen)
         return $str;

      $newstr = substr($str, 0, $maxlen);
      if (substr($newstr, -1, 1) != ' ')
         $newstr = substr($newstr, 0, strrpos($newstr, " "));

      return $newstr;
   }
}

?>
