<?php

/**
 * Description of 
 *
 * @author samir
 */
class Sige_Pdf_Relatorio_ArtigosLista {

    protected $pdf;
    protected $dados;
    protected $opcoes;

    function __construct($dados, $opcoes) {
        $this->dados = $dados;
        $this->opcoes = $opcoes;
    }

    public function pdf() {
        if (!isset($this->opcoes["status"])) {
            $this->opcoes["status"] = "todos";
        }
        $this->configurarRelatorio();
        $dados_tratados = $this->tratarDados();
        $this->pdf = new Sige_Pdf_Relatorio_Parser("ARTIGOS_LISTA", $dados_tratados);
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
            $dados_tratados["tabela_itens"] .= '<td>' . $item["apelido_encontro"] . '</td>\n';
            $dados_tratados["tabela_itens"] .= '<td>' . $item["titulo"] . '</td>\n';
            if ($this->opcoes["status"] === "todos") {
                if ($item["validada"]) {
                    $dados_tratados["tabela_itens"] .= '<td>Validado</td>\n';
                } else {
                    $dados_tratados["tabela_itens"] .= '<td>Não validado</td>\n';
                }
            }
            $dados_tratados["tabela_itens"] .= '<td style="display:inline-block;">' . strtoupper($item["nome"]) . '</td>\n';
            $dados_tratados["tabela_itens"] .= '<td>' . $item["email"] . '</td>\n';
            $dados_tratados["tabela_itens"] .= '</tr>\n';
        }
        return $dados_tratados;
    }

    private function configurarRelatorio() {
        $this->opcoes["nome_relatorio"] = "LISTA DE ARTIGOS CIENTÍFICOS ";
        $this->opcoes["col_status"] = "<th>Status</th>";
        switch ($this->opcoes["status"]) {
            case "validados":
                $this->opcoes["nome_relatorio"] .= "VALIDADOS ";
                $this->opcoes["col_status"] = null;
                break;
            case "nao-validados":
                $this->opcoes["nome_relatorio"] .= "NÃO VALIDADOS ";
                $this->opcoes["col_status"] = null;
                break;
            default:
                break;
        }
        $this->opcoes["nome_relatorio"] .= "SUBMETIDOS EM " . $this->opcoes["ano"];
    }

}
