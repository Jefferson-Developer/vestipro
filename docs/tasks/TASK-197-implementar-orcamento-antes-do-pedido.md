# TASK-197 — Implementar orçamento (cotação) antes do pedido

**Epic:** EPIC-29 — Pagamentos e Regras Comerciais Avançadas
**Status:** ⬜ Pendente
**Depende de:** TASK-096 (pedido em rascunho, base de itens/estrutura reaproveitada pela cotação), TASK-088 (motor de precificação server-side, fonte do preço a ser revalidado na conversão)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Permitir gerar uma cotação/orçamento formal para o cliente sem compromisso de estoque ou aprovação, convertível em pedido real quando o cliente confirmar, com validade explícita — deixando claro que o preço pode mudar após a expiração da cotação.

## Escopo técnico

- Modelar `Quote` (evolução do pedido em rascunho, TASK-096): itens, preços calculados pelo motor de precificação no momento da geração (TASK-088), validade (`expiresAt`), status (rascunho, enviada, expirada, convertida, recusada).
- Cloud Function `generateQuote` grava o snapshot de preços vigente na cotação (para exibir ao cliente exatamente o que foi cotado), sem reservar estoque nem disparar fluxo de aprovação de pedido.
- Ação "Converter em pedido": ao confirmar, revalida preço e disponibilidade em tempo real via motor de precificação/estoque; se algo mudou desde a cotação, informa claramente a diferença ao vendedor antes de prosseguir — nunca converte silenciosamente com valores desatualizados.
- Tela de cotação com CTA "Gerar orçamento" a partir do rascunho de pedido, exportação/compartilhamento do orçamento (reaproveitando exportação PDF de EPIC-18 quando disponível) e indicação clara de validade.
- Expiração automática de cotações vencidas (job/trigger), atualizando status para "expirada".

## Regras de negócio e restrições

- Cotação nunca reserva estoque nem impacta saldo (TASK-090) — é apenas uma projeção de preço e itens.
- Preço exibido na cotação é um snapshot; a conversão em pedido sempre revalida com o motor de precificação vigente no momento da conversão, nunca reaproveitando cegamente o valor antigo após expiração.
- Cotação expirada não pode ser convertida diretamente em pedido sem gerar nova cotação/revalidação.
- Cliente deve ver claramente a data de validade e o aviso de que o preço pode mudar após esse prazo.

## Testes obrigatórios

- Testes da Cloud Function: geração de cotação com snapshot correto, expiração automática, conversão dentro da validade, conversão após expiração (bloqueada/revalidada).
- Teste garantindo que a cotação nunca reserva estoque nem aciona aprovação de pedido.
- Testes de widget: geração, compartilhamento, aviso de validade, conversão com preço divergente do original.
- Teste de regressão garantindo que o fluxo de pedido em rascunho (TASK-096) continua intacto.

## Critérios de aceite

- Cotação é gerada com preço e validade claros, sem reservar estoque.
- Conversão em pedido sempre revalida preço/disponibilidade reais no momento da confirmação.
- Cotação expirada nunca vira pedido sem passar por revalidação.
- Vendedor é avisado quando o valor muda entre a cotação e a conversão.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
