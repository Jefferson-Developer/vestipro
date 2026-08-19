# TASK-175 — Implementar suporte a multi-moeda

**Epic:** EPIC-23 — Identidade Corporativa e Internacionalização
**Status:** ⬜ Pendente
**Depende de:** TASK-083 (Modelar Price List — moeda é atributo da tabela de preço já modelada).

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Permitir que cada tabela de preço (e, por consequência, cada organização/mercado) opere em sua própria moeda, com formatação correta por localidade — sem qualquer conversão automática entre moedas, já que cada tabela é uma fonte de preço autocontida.

## Escopo técnico

- Adicionar campo de moeda (código ISO 4217, ex.: BRL, USD, EUR) ao modelo `PriceList`, obrigatório e imutável após a criação da tabela.
- Formatar todo valor monetário exibido no app (catálogo, pedido, dashboard, relatórios) usando a moeda da tabela de preço de origem daquele valor, com símbolo/formato adequado à localidade (`intl` `NumberFormat.currency`).
- Garantir que pedidos, dashboards e relatórios envolvendo múltiplas tabelas de preço em moedas diferentes nunca somem valores de moedas distintas em um único total — segmentar/agrupar por moeda explicitamente quando isso ocorrer.
- Adicionar indicação visual clara de qual moeda está sendo exibida em qualquer tela com valor monetário, sem depender de o usuário inferir apenas pelo símbolo.
- Atualizar o motor de precificação existente para carregar e propagar a moeda da tabela de preço usada em cada cálculo, sem introduzir conversão cambial em nenhuma etapa.

## Regras de negócio e restrições

- VestiPro nunca converte valores entre moedas automaticamente — cada tabela de preço é autocontida na própria moeda; somas/comparações entre tabelas de moedas diferentes são proibidas em totais agregados.
- Moeda da tabela de preço é definida na criação e não pode ser alterada depois (alterar exige criar nova tabela).
- Pedido é sempre expresso em uma única moeda, a da tabela de preço utilizada.
- Dashboards agregados (ex.: "faturamento do mês") declaram explicitamente em qual moeda estão consolidados quando a organização opera com mais de uma, nunca somando silenciosamente valores de moedas diferentes.

## Testes obrigatórios

- Teste de formatação monetária por moeda/localidade (BRL, USD, EUR no mínimo).
- Teste do motor de precificação propagando corretamente a moeda da tabela usada.
- Teste garantindo que agregação/dashboard não soma valores de moedas diferentes sem segregação.
- Teste de imutabilidade da moeda após criação da tabela de preço.
- Teste de pedido criado a partir de tabela em moeda não-BRL exibindo formatação correta ponta a ponta.

## Critérios de aceite

- Cada tabela de preço exibe e opera corretamente na própria moeda, sem conversão automática em nenhum fluxo.
- Nenhum dashboard ou relatório soma valores de moedas diferentes sem segregação explícita.
- Moeda de uma tabela de preço não pode ser alterada após criada.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
