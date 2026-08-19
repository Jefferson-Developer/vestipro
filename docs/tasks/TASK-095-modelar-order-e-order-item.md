# TASK-095 — Modelar Order e OrderItem

**Epic:** EPIC-13 — Pedidos
**Status:** ⬜ Pendente
**Depende de:** TASK-048 — Modelar Customer (pedido referencia cliente); TASK-072 — Implementar geração de variantes produto-cor-tamanho (item de pedido referencia variante); TASK-083 — Modelar Price List (pedido referencia tabela de preço)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Modelar as entidades `Order` e `OrderItem` cobrindo todos os campos previstos na seção 9 de `tasks.md`, com uma máquina de estados explícita usando os status sugeridos na seção 9.1. Este modelo é a base estrutural de todo o EPIC-13 — nenhuma regra de submissão, precificação ou aprovação é implementada aqui.

## Escopo técnico

- Criar entidade `Order` com: `customerId`, endereço de entrega, endereço de cobrança, `sellerId` (vendedor), `companyId`, `branchId` (unidade), `priceListId`, `paymentTermId` (condição de pagamento), `carrierId` (transportadora), coleção/tipo de pedido, `items` (`List<OrderItem>`), descontos, acréscimos, frete, impostos (quando aplicável), observações, anexos, `status`, metadados de aprovação e histórico de status.
- Criar entidade `OrderItem` com `variantId`, `productId` (denormalizado para exibição), `quantity`, `unitPrice` (capturado no momento da adição — nunca recalculado retroativamente sem trilha), desconto/acréscimo por item quando aplicável, subtotal.
- Modelar a máquina de estados com os status da seção 9.1 (`draft`, `pending_sync`, `submitted`, `under_review`, `approved`, `rejected`, `processing`, `invoiced`, `partially_invoiced`, `shipped`, `delivered`, `cancelled`), definindo explicitamente as transições válidas (ex.: `draft → pending_sync → submitted`; `submitted → under_review → approved|rejected`; `approved → processing → invoiced|partially_invoiced → shipped → delivered`; `cancelled` alcançável a partir dos estados anteriores a `shipped`).
- Implementar `OrderStatus` como enum fechado + serviço de domínio `OrderStatusTransitionValidator` que rejeita transições inválidas (ex.: não permitir pular de `draft` direto para `delivered`).
- Criar DTOs, mappers e tabelas Drift (`orders`, `order_items`) com os campos padrão offline-first (`organizationId`, `companyId`, `createdBy`, `version`, `syncStatus`, etc.).
- Modelar `OrderStatusHistoryEntry` (status anterior, novo status, timestamp, `actorId`, motivo opcional) para a trilha de histórico.

## Regras de negócio e restrições

- O preço unitário do item é sempre o retornado pelo motor de precificação (TASK-088) no momento da adição — nunca inventado ou calculado na UI.
- Transições de status inválidas devem ser rejeitadas tanto no domain (client) quanto na Cloud Function de submissão/mudança de status (dupla validação).
- `organizationId`/`companyId` nunca inferidos apenas pelo cliente.
- Nenhuma regra de aprovação, submissão ou cálculo definitivo de total é implementada nesta task.

## Testes obrigatórios

- Teste unitário da máquina de estados cobrindo a matriz completa de transições válidas e inválidas.
- Teste de mapper DTO ↔ Entity cobrindo todos os campos opcionais/obrigatórios listados na seção 9.
- Teste de migração Drift para `orders`/`order_items`.
- Teste de serialização/desserialização de `OrderStatusHistoryEntry`.

## Critérios de aceite

- Entidades `Order`/`OrderItem` cobrindo todos os campos listados na seção 9 de `tasks.md`.
- Máquina de estados implementada, testada e rejeitando corretamente transições inválidas.
- Estrutura pronta para ser consumida pelas tasks seguintes do EPIC-13 sem necessidade de remodelagem.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
