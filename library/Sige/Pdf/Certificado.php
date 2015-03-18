<?php

/**
 * Classe para gerar certificados de participantes e palestrantes.
 *
 * @author atila
 */
class Sige_Pdf_Certificado {

    const NUM_MAX_CARACTERES = 80;
    const POS_X_INICIAL = 120;
    const POS_Y_INICIAL = 340;
    const DES_Y = 20;
    const TAM_FONTE = 15;
    const POS_X1_INI_ASSINATURA = 130;
    const POS_X2_INI_ASSINATURA = 260;
    const POS_Y1_ASSINATURA = 120;
    const POS_Y2_ASSINATURA = 200;
    const DES_X = 220;

    public function palestranteEvento(
        $array = array(
            'nome' => '',
            'id_encontro' => 0, // serve para identificar o modelo
            'encontro' => '',
            'tipo_evento' => '',
            'nome_evento' => '',
            'carga_horaria' => '',
        )
    ) {
        $model_encontro = new Application_Model_Encontro();
        $encontro_obj = $model_encontro->buscaComMunicipio($array["id_encontro"]);
//        $array["carga_horaria"] = $this->cargaHorariaToString($array["carga_horaria"]);
        $array["carga_horaria"] = floor($array["carga_horaria"]) . " hora(s)";
        $paragrafo = "      ";

        //preg_replace("/%%{$key}%%/", trim($opts[$key]), $str);
        $texto  = $paragrafo;
        $patterns = array(
            "/%%nome%%/"
        );
        $replacements = array(
            $this->fullUpper($array['nome'])
        );
        $texto .= preg_replace($patterns, $replacements, $encontro_obj["certificados_template_palestrante_evento"]);

        /*$texto = sprintf(
            $paragrafo . $encontro_obj["certificados_template_palestrante_evento"],
            $this->fullUpper($array['nome']),
            $array['tipo_evento'],
            $array['nome_evento'],
            $array['encontro'],
            $array['carga_horaria']
        );*/
        $linhas = explode("\n", wordwrap($texto, Sige_Pdf_Certificado::NUM_MAX_CARACTERES, "\n"));
        $linhas[] = ""; // saltar linha
        $date = new Zend_Date();
        $linhas[] = $this->str_pad_left(sprintf($encontro_obj["nome_municipio"] . ", %s", $date->toString("dd 'de' MMMM 'de' y")), Sige_Pdf_Certificado::NUM_MAX_CARACTERES);

        return $this->gerarCertificado($array['id_encontro'], $linhas);
    }

    public function participanteEncontro(
        $array = array(
            'nome' => '',
            'id_encontro' => 0, // serve para identificar o modelo
            'encontro' => '',
        )
    ) {
        $model_encontro = new Application_Model_Encontro();
        $encontro_obj = $model_encontro->buscaComMunicipio($array["id_encontro"]);

        $paragrafo = "      ";
        $texto  = $paragrafo;
        $patterns = array(
            "/{nome}/"
        );
        $replacements = array(
            $this->fullUpper($array['nome'])
        );
        $texto .= preg_replace($patterns, $replacements, $encontro_obj["certificados_template_participante_encontro"]);
        //$texto = sprintf($paragrafo . $encontro_obj["certificados_template_participante_encontro"], $this->fullUpper($array['nome']), $array['encontro']);
        $linhas = explode("\n", wordwrap($texto, Sige_Pdf_Certificado::NUM_MAX_CARACTERES, "\n"));
        $linhas[] = ""; // saltar linha
        $date = new Zend_Date();
        $linhas[] = $this->str_pad_left(sprintf($encontro_obj["nome_municipio"] . ", %s", $date->toString("dd 'de' MMMM 'de' y")), Sige_Pdf_Certificado::NUM_MAX_CARACTERES);

        // Get PDF document as a string
        return $this->gerarCertificado($array['id_encontro'], $linhas);
    }

    public function participanteEvento(
        $array = array(
            'nome' => '',
            'id_encontro' => 0, // serve para identificar o modelo
            'encontro' => '',
            'tipo_evento' => '',
            'nome_evento' => '',
            'carga_horaria' => '',
        )
    ) {
        $model_encontro = new Application_Model_Encontro();
        $encontro_obj = $model_encontro->buscaComMunicipio($array["id_encontro"]);
//        $array["carga_horaria"] = $this->cargaHorariaToString($array["carga_horaria"]);
        $array["carga_horaria"] = floor($array["carga_horaria"]) . " hora(s)";
        $paragrafo = "      ";
        $texto = sprintf($paragrafo . $encontro_obj["certificados_template_participante_evento"], $this->fullUpper($array['nome']), $array['encontro'], $array['tipo_evento'], $array['nome_evento'], $array["carga_horaria"]);
        $linhas = explode("\n", wordwrap($texto, Sige_Pdf_Certificado::NUM_MAX_CARACTERES, "\n"));
        $linhas[] = ""; // saltar linha
        $date = new Zend_Date();
        $linhas[] = $this->str_pad_left(sprintf($encontro_obj["nome_municipio"] . ", %s", $date->toString("dd 'de' MMMM 'de' y")), Sige_Pdf_Certificado::NUM_MAX_CARACTERES);

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
        $font = Zend_Pdf_Font::fontWithPath(APPLICATION_PATH . "/../public/font/UbuntuMono-R.ttf");
        $page1->setFont($font, Sige_Pdf_Certificado::TAM_FONTE);

        // configura o plano de fundo
        $this->background($page1, $idEncontro);

        for ($index = 0; $index < count($array); $index++) {
            $page1->drawText(
                    $array[$index], Sige_Pdf_Certificado::POS_X_INICIAL, Sige_Pdf_Certificado::POS_Y_INICIAL - ($index * Sige_Pdf_Certificado::DES_Y), 'UTF-8');
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
                        Sige_Pdf_Certificado::POS_X1_INI_ASSINATURA + ($index * Sige_Pdf_Certificado::DES_X),
                        // y1
                        Sige_Pdf_Certificado::POS_Y1_ASSINATURA,
                        // x2
                        Sige_Pdf_Certificado::POS_X2_INI_ASSINATURA + ($index * Sige_Pdf_Certificado::DES_X),
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

    public function fullUpper($string) {
        return strtr(strtoupper($string), array(
            "à" => "À",
            "è" => "È",
            "ì" => "Ì",
            "ò" => "Ò",
            "ù" => "Ù",
            "á" => "Á",
            "é" => "É",
            "í" => "Í",
            "ó" => "Ó",
            "ú" => "Ú",
            "â" => "Â",
            "ê" => "Ê",
            "î" => "Î",
            "ô" => "Ô",
            "û" => "Û",
            "ç" => "Ç",
        ));
    }

    private function parseCargaHoraria($horas) {
        $minutes = $horas / 60;
        $d = floor($minutes / 1440);
        $h = floor(($minutes - $d * 1440) / 60);
        $m = $minutes - ($d * 1440) - ($h * 60);
        return array("dias" => $d, "horas" => $h, "minutos" => $m);
    }

    private function cargaHorariaToString($carga_horaria_em_horas) {
        $v[] = null;
        $ch = $this->parseCargaHoraria($carga_horaria_em_horas);
        if ($ch["dias"] > 0)
            $v[] = $ch["dias"] . " dia(s)";
        if ($ch["horas"] > 0)
            $v[] = $ch["horas"] . " hora(s)";
        if ($ch["minutos"] > 0)
            $v[] = $ch["minutos"] . " minutos(s)";
        return implode(", ", $v);
    }

}
