# TASK-085 — Implementar condições de pagamento

**Epic:** EPIC-11 — Tabelas de Preço e Condições Comerciais
**Status:** ⬜ Pendente
**Depende de:** TASK-083 (Price List, à qual a condição de pagamento pode ser associada)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Permitir o cadastro de condições de pagamento (número de parcelas, prazo médio, status ativo/
inativo) que podem ser associadas a tabelas de preço e selecionadas na criação de um pedido,
compondo o resumo comercial exibido ao vendedor e ao cliente.

## Escopo técnico

- Modelar entidade `PaymentTerm` (`id`, `organizationId`, `companyId`, `name`, `installments`
  [lista de parcelas com percentual/prazo em dias cada], `averageTermDays` calculado, `status`
  [ativa/inativa], `priceListIds` associadas quando restrita a tabelas específicas).
- Criar repositório e casos de uso (`CreatePaymentTermUseCase`, `UpdatePaymentTermUseCase`,
  `ListActivePaymentTermsUseCase`) seguindo Clean Architecture.
- Criar tela administrativa (Web/desktop) de CRUD de condições de pagamento, com validação de que a
  soma dos percentuais das parcelas totaliza 100%.
- Integrar seletor de condição de pagamento na tela de pedido (EPIC-13), listando apenas condições
  ativas e compatíveis com a tabela de preço selecionada.
- Persistir condições de pagamento na carga offline (Drift), com sincronização incremental.
- Registrar auditoria administrativa (TASK-033) para criação/edição/inativação de condição de
  pagamento, por afetar diretamente o pedido.

## Regras de negócio e restrições

- Condição inativa nunca pode ser selecionada em um pedido novo, mas pedidos antigos que já a
  usaram devem continuar exibindo-a corretamente no histórico.
- Soma dos percentuais das parcelas de uma condição deve ser exatamente 100%; a tela administrativa
  impede salvar uma condição inconsistente.
- Associação de condição de pagamento a uma Price List é opcional; quando ausente, a condição fica
  disponível para qualquer tabela da empresa.
- Prazo médio (`averageTermDays`) é calculado a partir das parcelas, nunca digitado manualmente de
  forma dessincronizada.

## Testes obrigatórios

- Testes de domínio: criação de condição válida, percentuais que não somam 100%, parcela com prazo
  negativo, condição sem nenhuma parcela.
- Testes do caso de uso `ListActivePaymentTermsUseCase`: apenas ativas retornadas, filtro por
  Price List associada, lista vazia.
- Testes de widget: tela administrativa validando soma de percentuais em tempo real, seletor de
  condição no pedido exibindo apenas condições ativas e compatíveis.
- Teste de auditoria confirmando registro de criação/edição/inativação.

## Critérios de aceite

- Condições de pagamento cadastráveis com parcelas, prazo médio calculado e status ativo/inativo.
- Apenas condições ativas e compatíveis com a tabela de preço aparecem como opção no pedido.
- Tela administrativa impede salvar condição com parcelas inconsistentes.
- Toda alteração de condição de pagamento gera registro de auditoria.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
