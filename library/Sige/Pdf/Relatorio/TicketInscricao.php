<?php

/**
 * Classe que gera ticket de incrição do participante
 * com seus dados pessoais, dados do evento, código de barras
 * para agilizar inscrição
 * @author atila
 */
class Sige_Pdf_Relatorio_TicketInscricao {

    use Sige_Translate_Abstract {
        Sige_Translate_Abstract::__construct as private __mConstruct;
    }

    protected $pdf;
    protected $dados;

    /**
     * Cria instância de um Ticket de Inscrição
     * @param [array] $dados deve conter os dados:
     *   * nome
     *   * nome_encontro
     *   * data_inicio (com dia e mês)
     *   * data_fim (com dia, mês e ano)
     *   * hora_inicio
     *   * local
     *   * id_pessoa
     *   * id_encontro
     */
    public function __construct($dados) {
        $this->__mConstruct();

        $this->dados = $dados;
        $this->i18n();
        $this->gerarCodigoBarras();
        $this->pdf = new Sige_Pdf_Relatorio_Parser("TICKET_INSCRICAO", $this->dados);
    }

    public function gerarPdf() {
        return $this->pdf->gerarPdf();
    }

    public function obterPdf() {
        return $this->pdf->obterPdf();
    }

    private function gerarCodigoBarras() {
        $barcode = new Zend_Barcode_Object_Code128();
        $barcode->setText($this->dados['inscricao']);
        $barcode->setFactor(1.2);
        $renderer = new Zend_Barcode_Renderer_Image();
        $renderer->setBarcode($barcode);
        $resource = $renderer->draw();
        ob_start();
        imagepng($resource);
        $data = ob_get_clean();

        $this->dados['barcode'] = base64_encode($data);
    }

    private function i18n() {
        $this->dados['nome_relatorio'] = $this->t->_('Registration Ticket');
        $this->dados['i18n_nome'] = $this->t->_('Name:');
        $this->dados['i18n_encontro'] = $this->t->_('Conference:');
        $this->dados['i18n_data_hora'] = $this->t->_('Date and time:');
        $this->dados['i18n_inicio'] = $this->t->_('starting from');
        $this->dados['i18n_local'] = $this->t->_('Place:');
        $this->dados['i18n_ingresso'] = $this->t->_('Entrance:');
        $this->dados['i18n_inscricao'] = $this->t->_('Registration:');
    }
}
