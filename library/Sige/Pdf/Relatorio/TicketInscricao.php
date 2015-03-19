<?php

/**
 * Classe que gera ticket de incrição do participante
 * com seus dados pessoais, dados do evento, código de barras
 * para agilizar inscrição
 * @author atila
 */
class Sige_Pdf_Relatorio_TicketInscricao {

    protected $pdf;

    public function gerarPdf() {
        return $this->pdf();
    }

    private function pdf() {
        $this->pdf = new Sige_Pdf_Relatorio_Parser("TICKET_INSCRICAO");
        return $this->pdf->gerarPdf();
    }
}
