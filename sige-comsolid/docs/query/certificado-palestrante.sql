SELECT e.id_encontro,
       p.id_pessoa,
       nome_tipo_evento,
       nome_evento,
       nome
FROM evento e
INNER JOIN pessoa p ON (e.responsavel = p.id_pessoa)
INNER JOIN encontro_participante ep ON ep.id_pessoa = p.id_pessoa
INNER JOIN tipo_evento te ON (te.id_tipo_evento = e.id_tipo_evento)
--WHERE e.id_encontro = 3 and p.id_pessoa = 3
WHERE validada = TRUE
  AND ep.validado = TRUE
  AND confirmado = TRUE
  AND e.apresentado = TRUE