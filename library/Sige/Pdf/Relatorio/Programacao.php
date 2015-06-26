<?php

class Sige_Pdf_Relatorio_Programacao extends Sige_Pdf_Relatorio_Parser {

    use Sige_Translate_Abstract {
        Sige_Translate_Abstract::__construct as private __mConstruct;
    }

    protected $pdf;
    protected $dados = array();
    protected $dados_itens = array();

    public function __construct($dados) {
        $this->__mConstruct();

        $this->i18n();
        $this->dados['content'] = $this->gerarItens($dados);

        parent::__construct("PROGRAMACAO", $this->dados);
    }

    private function gerarItens($dados) {
        $template = $this->carregarTemplateItem();
        $str_itens = '';
        foreach ($dados as $index => $item) {
            $pagebreak = '';
            if ($index > 0 and $index % 4 == 0) {
                $pagebreak = '<pagebreak />';
            }

            $str_itens .= $this->parseDados($template . $pagebreak, $item);
        }
        return $str_itens;
    }

    private function carregarTemplateItem() {
        $template_filepath = $this->parseTipo("PROGRAMACAO_ITEM");
        $template = $this->loadTemplate($template_filepath);
        return $this->parseDados($template, $this->dados_itens);
    }

    private function i18n() {
        $this->dados['nome_relatorio'] = $this->t->_('Schedule');

        $this->dados_itens['i18n_data_hora'] = $this->t->_('Date and time:');
        $this->dados_itens['i18n_inicio'] = $this->t->_('starting from');
        $this->dados_itens['i18n_evento'] = $this->t->_('Event:');
        $this->dados_itens['i18n_por'] = $this->t->_('by');
        $this->dados_itens['i18n_local'] = $this->t->_('Place:');
    }
}
