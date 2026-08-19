# TASK-090 — Implementar saldo por variante

**Epic:** EPIC-12 — Estoque e Disponibilidade
**Status:** ⬜ Pendente
**Depende de:** TASK-072 — Implementar geração de variantes produto-cor-tamanho (saldo é sempre por variante/SKU); TASK-089 — Modelar Warehouse (saldo é sempre por variante + depósito)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Implementar o armazenamento e a consulta de disponibilidade vendável por variante/warehouse, com atualização sempre incremental — nunca recalculando o saldo total a partir de todo o histórico de movimentações a cada mudança. Este saldo é a base de dados consumida por estoque futuro, reserva comercial, alertas de ruptura e giro de estoque.

## Escopo técnico

- Criar entidade `VariantStockBalance` vinculando `variantId` + `warehouseId`: quantidade física, quantidade reservada, quantidade vendável (calculada como física − reservada − bloqueada).
- Modelar o saldo como documento agregado por variante+warehouse (evitar um documento por movimentação); toda alteração aplica delta via transação/Cloud Function idempotente usando incremento atômico (`FieldValue.increment`), nunca recalcula somando todo o histórico.
- Criar índices/consultas eficientes: por variante (para tela de produto/grade) e por warehouse (para telas administrativas), evitando N+1 reads e sem carregar coleções inteiras.
- Expor caso de uso `GetVariantAvailability(variantId, {warehouseId?})`, retornando saldo consolidado entre warehouses da empresa ativa e saldo por warehouse individual.
- Persistir uma cópia do saldo na base local (Drift) como cache com TTL curto para leitura offline, deixando explícito que não é fonte definitiva quando há conexão disponível.
- Registrar trilha de auditoria de toda alteração de saldo (quem, quando, delta, origem: recebimento, pedido, ajuste manual, expiração de reserva).

## Regras de negócio e restrições

- Cálculo de saldo nunca ocorre no client — o client apenas lê o resultado já calculado no backend.
- Saldo vendável não pode ficar negativo por overselling do cliente; este saldo serve para exibição/reserva, a trava definitiva de venda é responsabilidade da Cloud Function de submissão do pedido (TASK-101).
- Toda alteração de saldo deve ser auditável e rastreável até sua origem.

## Testes obrigatórios

- Teste de concorrência: duas atualizações simultâneas de saldo para a mesma variante não perdem incremento (transação/atomic increment via Emulator).
- Teste de caso de uso cobrindo variante sem saldo cadastrado (retorna zero, nunca erro).
- Teste de consulta por warehouse validando paginação e ausência de leitura integral da coleção.
- Teste do cache local Drift com TTL expirado forçando nova busca remota, e com TTL válido servindo do cache.

## Critérios de aceite

- Atualização de saldo sempre incremental, nunca recomputação total a partir de todas as movimentações.
- Consulta por variante e por warehouse eficiente, paginada e testada.
- Trilha de auditoria de alteração de saldo implementada e consultável.
- Nenhuma tela criada nesta task (é domain/data; consumo em UI ocorre nas tasks seguintes).

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
