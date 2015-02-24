<?php

class Sige_Xls_Exportar {

    protected $columns;
    protected $labels;
    protected $data;

    /**
     * Header (of document)
     * @var string
     */
    protected $header = "<?xml version=\"1.0\" encoding=\"%s\"?\>\n<Workbook xmlns=\"urn:schemas-microsoft-com:office:spreadsheet\" xmlns:x=\"urn:schemas-microsoft-com:office:excel\" xmlns:ss=\"urn:schemas-microsoft-com:office:spreadsheet\" xmlns:html=\"http://www.w3.org/TR/REC-html40\">";

    /**
     * Footer (of document)
     * @var string
     */
    protected $footer = "</Workbook>";

    /**
     * Lines to output in the excel document
     * @var array
     */
    protected $lines = array();

    /**
     * Used encoding
     * @var string
     */
    protected $stringEncoding;

    /**
     * Convert variable types
     * @var boolean
     */
    protected $boolConvertTypes;

    /**
     * Worksheet title
     * @var string
     */
    protected $worksheetTitle;

    /**
     * 
     * @param assoc array $data - data fetched of database
     * @param array of strings $columns - columns which are selected to export
     * @param array of strings $labels - labels to be placed in the first row of the spreadsheet
     */
    public function __construct($data, $columns, $labels) {
        $this->columns = $columns;
        $this->data = $data;
        $this->labels = $labels;

        $this->addRow($labels);
//        $this->addArray($data);
        $this->addFiltredArray($data, $columns);

        //$stringEncoding = 'UTF-8', $boolConvertTypes = false, $worksheetTitle = 'Tabela_1'
        $this->boolConvertTypes = true;
        $this->setEncoding('UTF-8');
        $this->setWorksheetTitle('Tabela_1');
    }

    /**
     * Set encoding
     * @param string Encoding type to set
     */
    public function setEncoding($stringEncoding) {
        $this->stringEncoding = $stringEncoding;
    }

    /**
     * Set worksheet title
     * 
     * Strips out not allowed characters and trims the
     * title to a maximum length of 31.
     * 
     * @param string $title Title for worksheet
     */
    public function setWorksheetTitle($title) {
        $titlePreg = preg_replace("/[\\\|:|\/|\?|\*|\[|\]]/", "", $title);
        $titleSub = substr($titlePreg, 0, 31);
        $this->worksheetTitle = $titleSub;
    }

    /**
     * Add row
     * 
     * Adds a single row to the document. If set to true, self::boolConvertTypes
     * checks the type of variable and returns the specific field settings
     * for the cell.
     * 
     * @param array $array One-dimensional array with row content
     */
    private function addRow($array) {
        $cells = "";
        foreach ($array as $value) {
            $type = 'String';
            if ($this->boolConvertTypes === true && is_numeric($value)) {
                $type = 'Number';
            }
            $value_ = htmlspecialchars($value, ENT_COMPAT, $this->stringEncoding);

            $cells .= "<Cell><Data ss:Type=\"{$type}\">{$value_}</Data></Cell>\n";
        }
        $this->lines[] = "<Row>\n" . $cells . "</Row>\n";
    }

    /**
     * Add an array to the document
     * @param array 2-dimensional array
     */
    public function addArray($array) {
        foreach ($array as $value) {
            $this->addRow($value);
        }
    }

    /**
     * Add only $columns specified of an array to the document
     * @param array 2-dimensional array
     * @param array of strings
     */
    public function addFiltredArray($data, $columns) {
        foreach ($data as $assoc_array) {
            $row_array = array();
            foreach ($columns as $key) {
                if (isset($assoc_array[$key])) {
//                    Zend_Debug::dump($assoc_array[$key]);
                    if (is_bool($assoc_array[$key])) {
                        if ($assoc_array[$key] == true) {
                            $row_array[$key] = "sim";
                        } else {
                            $row_array[$key] = "não";
                        }
                    } else {
                        $row_array[$key] = $assoc_array[$key];
                    }
                }
            }
            $this->addRow($row_array);
        }
//        die();
    }

    /**
     * Generate the excel file
     * @param string $filename Name of excel file to generate (...xls)
     */
    public function exportar($filename = null) {
        if ($filename == null) {
            $filename = "excel-" . date("Y-m-d-His") . ".xls";
        }

        // deliver header (as recommended in php manual)
        header("Content-Type: application/vnd.ms-excel; charset={$this->stringEncoding}");
        header("Content-Disposition: inline; filename=\"" . $filename);

        // print out document to the browser
        // need to use stripslashes for the damn ">"
        echo stripslashes(sprintf($this->header, $this->stringEncoding));
        echo "\n<Worksheet ss:Name=\"" . $this->worksheetTitle . "\">\n<Table>\n";

        foreach ($this->lines as $line) {
            echo $line;
        }

        echo "</Table>\n</Worksheet>\n";
        echo $this->footer;
    }

}
