<?php

use Dinesh\BarcodeAll\DNS1D;

/**
 * Classe que gera ticket de incrição do participante
 * com seus dados pessoais, dados do evento, código de barras
 * para agilizar inscrição
 * @author atila
 */
class Sige_Pdf_Relatorio_TicketInscricao {

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
    function __construct($dados) {
        $this->dados = $dados;
    }

    public function gerarPdf() {
        $this->dados['nome_relatorio'] = 'Ticket de Inscrição';
        $this->i18n();
        $this->gerarCodigoBarras();
        $this->pdf = new Sige_Pdf_Relatorio_Parser("TICKET_INSCRICAO", $this->dados);
        return $this->pdf->gerarPdf();
    }

    public function obterPdf() {
        $this->dados['nome_relatorio'] = 'Ticket de Inscrição';
        $this->i18n();
        $this->gerarCodigoBarras();
        $this->pdf = new Sige_Pdf_Relatorio_Parser("TICKET_INSCRICAO", $this->dados);
        return $this->pdf->obterPdf();
    }

    private function gerarCodigoBarras() {
        $barcode = new DNS1D();
        $barcode->setStorPath(getcwd());
        $this->dados['barcode'] = $barcode->getBarcodePNG($this->dados['inscricao'], "C128");
    }

    private function i18n() {
        $this->dados['i18n_nome'] = _('Name:');
        $this->dados['i18n_encontro'] = _('Conference:');
        $this->dados['i18n_data_hora'] = _('Date and time:');
        $this->dados['i18n_local'] = _('Place:');
        $this->dados['i18n_ingresso'] = _('Entrance:');
        $this->dados['i18n_inscricao'] = _('Registration:');
    }
}
