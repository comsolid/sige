# Padronização do nome das actions

## CRUD

Actions que fazem parte do CRUD devem ter a seguinte nomenclatura:

* C - criar
* R - ler
* U - editar
* D - deletar

Ex.:

~~~
public function criarAction() {
	/* ... */
}
~~~

## Ajax

Actions que servem requisições Ajax devem ser:

~~~
public function ajaxBuscarAction() {
	/* ... */
}
~~~

## Actions com mais de uma palavra

Actions com mais de uma palavra devem ser escritas em CamelCase.

~~~
public function ajaxBuscarPorNomeAction() {
	/* ... */
}
~~~

Com isso a url ficaria da seguinte maneira: `http://projeto.local/ajax-buscar-por-nome`.
