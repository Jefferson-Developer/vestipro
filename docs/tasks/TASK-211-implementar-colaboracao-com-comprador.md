# TASK-211 — Implementar colaboração com comprador em seleções e pedidos

**Epic:** EPIC-32 — Operações Comerciais Avançadas de Moda B2B
**Status:** ⬜ Pendente
**Depende de:** TASK-081 (compartilhamento de catálogo), TASK-181 (compartilhamento de carrinho/seleção), TASK-182 (portal B2B do cliente), TASK-197 (orçamento antes do pedido)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`
- `vestipro-sales-representative-specialist`
- `vestipro-commercial-ops-strategist`

## Objetivo

Permitir que vendedor e comprador construam uma seleção/pedido juntos, com comentários, solicitações de
ajuste, aprovação do comprador e histórico em um só lugar. O objetivo é reduzir idas e vindas por
mensagem solta e aumentar conversão de orçamento/seleção em pedido.

## Escopo técnico

- Modelar `BuyerCollaborationSession` vinculada a cliente, seleção, carrinho, orçamento ou pedido em
  rascunho, com status: `seller_draft`, `buyer_review`, `changes_requested`, `buyer_approved`,
  `converted_to_order`, `expired`.
- Criar comentários por item, comentários gerais, anexos permitidos e menções internas, sempre com
  trilha de autoria, timestamp e visibilidade.
- Permitir que o comprador externo sugira alteração de quantidade ou remoção/adicionamento de item,
  mas a conversão em pedido continua passando pelo vendedor/fluxo de aprovação quando configurado.
- Criar notificações e deep links para vendedor/comprador quando houver comentário, solicitação de
  ajuste ou aprovação.
- Registrar analytics de colaboração: sessão aberta, comentário criado, alteração solicitada,
  aprovação do comprador e conversão em pedido.

## Regras de negócio e restrições

- Comprador externo só acessa sessões vinculadas ao próprio `customerId`.
- Aprovação do comprador não substitui aprovação comercial interna de desconto, crédito ou política.
- Toda alteração proposta precisa ser revalidada contra preço, estoque e vigência no momento da conversão.
- Sessão expirada fica somente leitura e não pode ser convertida sem reabertura autorizada.

## Testes obrigatórios

- Teste de RBAC/Rules para comprador externo acessando apenas sessões do próprio cliente.
- Teste de ciclo completo: vendedor compartilha, comprador comenta, solicita ajuste, aprova e converte.
- Teste de revalidação de preço/estoque na conversão.
- Teste de notificações/deep links para comentário e aprovação.

## Critérios de aceite

- Vendedor e comprador conseguem colaborar em uma seleção sem depender de planilha ou conversa externa.
- O histórico da negociação fica rastreável por cliente e por pedido/orçamento.
- Aprovação do comprador não contorna regras comerciais internas.

## Arquivos prováveis

- A definir pelo agente executor no início da task.

## Referências

- Especificação funcional completa: `tasks.md`
- Agentes técnicos e de negócio em `.claude/agents/`
- Fluxo obrigatório: `AGENTS.md`
