START TRANSACTION;

ALTER TABLE pessoa
  ADD COLUMN cpf bigint;

ALTER TABLE pessoa DROP COLUMN telefone;

ALTER TABLE pessoa
  ADD COLUMN telefone bigint;

ROLLBACK; -- CHANGE TO COMMIT
