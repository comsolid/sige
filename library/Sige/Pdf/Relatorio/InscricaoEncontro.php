<?php

/**
 * Description of InscricaoEncontro
 *
 * @author samir
 */
class Sige_Pdf_Relatorio_InscricaoEncontro {

    protected $pdf;
    protected $dados;
    protected $opcoes;

    function __construct($dados, $opcoes) {
        $this->dados = $dados;
        $this->opcoes = $opcoes;
    }

    public function pdf() {
        if (!isset($this->opcoes["apelido_encontro"])) {
            $this->opcoes["apelido_encontro"] = "EVENTO";
        }
        if (!isset($this->opcoes["status"])) {
            $this->opcoes["status"] = "todas";
        }
        $this->configurarRelatorio();
        $dados_tratados = $this->tratarDados();
//        Zend_Debug::dump($dados_tratados); die();
        $this->pdf = new Sige_Pdf_Relatorio_Parser("INSCRICAO_ENCONTRO", $dados_tratados);
        return $this->pdf->gerarPdf();
    }

    public function gerarPdf() {
        return $this->pdf();
    }

    /**
     * Recebe um assoc array do banco de dados e transforma em formato legível 
     * para o relatório
     */
    private function tratarDados() {
        $dados_tratados = array();
        $dados_tratados["nome_relatorio"] = $this->opcoes["nome_relatorio"];
        $dados_tratados["col_status"] = $this->opcoes["col_status"];
        $dados_tratados["tabela_itens"] = null;
        $dados_tratados["contador"] = count($this->dados);

        foreach ($this->dados as $item) {
            $dados_tratados["tabela_itens"] .= '<tr>\n';
            $dados_tratados["tabela_itens"] .= '<td style="display:inline-block;">' . strtoupper($item["nome"]) . '</td>\n';
            $dados_tratados["tabela_itens"] .= '<td>' . $item["email"] . '</td>\n';
            $dados_tratados["tabela_itens"] .= '<td>' . $item["nome_municipio"] . '</td>\n';
//            $dados_tratados["tabela_itens"] .= '<td>' . $item["apelido_instituicao"] . '</td>\n';
//            $dados_tratados["tabela_itens"] .= '<td>' . $item["nome_caravana"] . '</td>\n';
            if ($this->opcoes["status"] === "todas") {
                if ($item["confirmado"]) {
                    $dados_tratados["tabela_itens"] .= '<td>Confirmado</td>\n';
                } else {
                    $dados_tratados["tabela_itens"] .= '<td>Não confirmado</td>\n';
                }
            }
            $dados_tratados["tabela_itens"] .= '<td>&nbsp;</td>\n'; // campo Obs.
            $dados_tratados["tabela_itens"] .= '</tr>\n';
        }
        return $dados_tratados;
    }

    private function configurarRelatorio() {
        $this->opcoes["nome_relatorio"] = "RELATÓRIO DE INSCRIÇÕES ";
        $this->opcoes["col_status"] = "<th>Status</th>";
        switch ($this->opcoes["status"]) {
            case "confirmadas":
                $this->opcoes["nome_relatorio"] .= "CONFIRMADAS ";
                $this->opcoes["col_status"] = null;
                break;
            case "nao-confirmadas":
                $this->opcoes["nome_relatorio"] .= "NÃO CONFIRMADAS ";
                $this->opcoes["col_status"] = null;
                break;
            default:
                break;
        }
        $this->opcoes["nome_relatorio"] .= "DO " . $this->opcoes["apelido_encontro"];
    }

}
