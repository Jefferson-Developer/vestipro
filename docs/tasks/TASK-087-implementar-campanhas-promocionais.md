# TASK-087 — Implementar campanhas promocionais

**Epic:** EPIC-11 — Tabelas de Preço e Condições Comerciais
**Status:** ⬜ Pendente
**Depende de:** TASK-083 (Price List, base sobre a qual a promoção altera preço), TASK-086 (políticas de desconto, com as quais a campanha precisa compor sem conflito)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Permitir a aplicação de promoções comerciais por período e segmento de cliente (ex.: coleção em
liquidação, campanha de aniversário de um grupo de clientes), com regras reproduzíveis e
auditáveis: dado um pedido qualquer, deve ser sempre possível explicar exatamente qual campanha foi
aplicada e por quê.

## Escopo técnico

- Modelar `PromotionalCampaign` (`id`, `organizationId`, `companyId`, `name`, `validFrom`,
  `validTo`, `customerSegment` [regra de segmentação — ver TASK-053], `productScope` [produtos,
  coleções ou categorias elegíveis], `discountType` [percentual ou valor fixo], `discountValue`,
  `stackableWithOtherCampaigns` [booleano], `priority`, `status`).
- Implementar caso de uso `ResolveApplicableCampaignsUseCase`: dado cliente, produto e data,
  retorna as campanhas elegíveis e — quando não empilháveis — aplica a de maior prioridade,
  registrando explicitamente qual campanha "venceu" e por quê.
- Criar tela administrativa (Web/desktop) de cadastro de campanha promocional, reutilizando o
  seletor de segmento de cliente e o seletor de produto/coleção já existentes no catálogo.
- Persistir, em cada item de pedido que recebeu desconto de campanha, a referência à
  `campaignId` aplicada (nunca só o valor final do desconto sem rastreabilidade da origem).
- Expor no resumo comercial do pedido (TASK-099) a origem do desconto (política de perfil vs.
  campanha vs. condição manual), de forma auditável.
- Registrar auditoria administrativa para criação/edição/encerramento de campanha.

## Regras de negócio e restrições

- Toda aplicação de desconto por campanha deve ser reprodutível: dado o mesmo pedido/cliente/data,
  o motor de precificação (TASK-088) deve sempre chegar ao mesmo resultado e à mesma campanha
  vencedora.
- Campanha fora do período de vigência nunca pode ser aplicada, mesmo que ainda exista cadastrada.
- Quando múltiplas campanhas são elegíveis e não são empilháveis, a prioridade decide de forma
  determinística — nunca uma escolha ambígua ou dependente de ordem de leitura do banco.
- Desconto de campanha compõe com o limite de desconto por perfil (TASK-086) de forma explícita e
  documentada (ex.: desconto de campanha não conta contra o limite manual do vendedor, ou conta —
  a decisão deve ficar registrada nesta task e refletida nos testes).

## Testes obrigatórios

- Testes do caso de uso `ResolveApplicableCampaignsUseCase`: nenhuma campanha elegível, uma
  campanha elegível, múltiplas campanhas empilháveis, múltiplas campanhas não empilháveis com
  prioridades diferentes, campanha expirada excluída, campanha fora do segmento de cliente
  excluída.
- Teste de auditabilidade: dado um pedido com desconto de campanha, é possível recuperar
  exatamente qual `campaignId` foi aplicada e os critérios de elegibilidade satisfeitos.
- Testes de widget: tela administrativa de cadastro de campanha, resumo do pedido exibindo origem
  do desconto.
- Teste de regressão garantindo que o mesmo cenário (cliente, produto, data) produz sempre o mesmo
  resultado de campanha aplicada.

## Critérios de aceite

- Campanhas promocionais aplicam-se corretamente por período e segmento de cliente.
- Toda campanha aplicada a um pedido é rastreável e explicável a partir do item do pedido.
- Comportamento de empilhamento/prioridade entre campanhas é determinístico e testado.
- Nenhuma campanha expirada ou fora de segmento é aplicada em nenhum cenário testado.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
