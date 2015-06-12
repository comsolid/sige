<?php

class Sige_Pdf_Relatorio_FolhaPresenca extends Sige_Pdf_Relatorio_Parser {

    use Sige_Translate_Abstract {
        Sige_Translate_Abstract::__construct as private __mConstruct;
    }

    protected $pdf;
    protected $dados = array();
    protected $dados_itens = array();

    public function __construct($dados) {
        $this->__mConstruct();

        $this->i18n();
        $this->dados_itens['empty_rows'] = $this->gerarLinhasTabelaEmBranco(50, 3);
        $this->dados['content'] = $this->gerarItens($dados);

        parent::__construct("FOLHA_PRESENCA", $this->dados);
    }

    private function gerarItens($dados) {
        $template = $this->carregarTemplateItem();
        $str_itens = '';
        foreach ($dados as $item) {
            $str_itens .= $this->parseDados($template, $item);
        }
        return $str_itens;
    }

    private function carregarTemplateItem() {
        $template_filepath = $this->parseTipo("FOLHA_PRESENCA_ITEM");
        $template = $this->loadTemplate($template_filepath);
        return $this->parseDados($template, $this->dados_itens);
    }

    private function i18n() {
        $this->dados['nome_relatorio'] = $this->t->_('Presence Sheet');

        $this->dados_itens['i18n_encontro'] = $this->t->_('Conference:');
        $this->dados_itens['i18n_evento'] = $this->t->_('Event:');
        $this->dados_itens['i18n_data_hora'] = $this->t->_('Date and time:');
        $this->dados_itens['i18n_inicio'] = $this->t->_('starting from');
        $this->dados_itens['i18n_local'] = $this->t->_('Place:');
        $this->dados_itens['i18n_nome'] = $this->t->_('Name');
        $this->dados_itens['i18n_email'] = $this->t->_('E-mail');
        $this->dados_itens['i18n_assinatura'] = $this->t->_('Signature');
    }

    private function gerarLinhasTabelaEmBranco($n_linhas, $n_colunas) {
        $colunas = str_repeat("<td>&nbsp;</td>", $n_colunas);
        return str_repeat("<tr>" . $colunas . "</tr>", $n_linhas);
    }
}
