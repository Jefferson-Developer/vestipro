# TASK-132 — Implementar central de oportunidades

**Epic:** EPIC-16 — Insights e Recomendação
**Status:** ⬜ Pendente
**Depende de:** TASK-122 (insight de cliente inativo), TASK-123 (insight de queda de faturamento), TASK-124 (insight de cliente em crescimento), TASK-125 (insight de cross-sell), TASK-126 (insight de up-sell), TASK-127 (insight de mix insuficiente), TASK-128 (insight de estoque e reposição), TASK-129 (insight de risco de churn), TASK-130 (insight de pedido abandonado), TASK-131 (insight de vendedor abaixo da meta) — todas as regras concretas precisam existir para a central reuni-las

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar a tela única que reúne todos os insights gerados pela `InsightEngine` (TASK-121 a TASK-131), priorizados por impacto estimado, com ação rápida acessível diretamente do card — encerrando o EPIC-16 com o ponto de entrada real da Inteligência Comercial no dia a dia do vendedor e do gestor.

## Escopo técnico

- Criar `OpportunityCenterPage` e `OpportunityCenterBloc` que consomem o `InsightRepository` (TASK-121) de forma paginada, agregando insights de todos os tipos (TASK-122 a TASK-131) em uma única listagem.
- Ordenar por padrão pelo `estimatedImpact` de cada insight; permitir reordenar por tipo, data de geração e cliente/vendedor relacionado.
- Criar filtros por tipo de insight (ícone/badge por tipo), por período e por faixa de impacto, com estado de filtro preservado na navegação (URL no Flutter Web).
- Cada card de insight exibe título, descrição curta, evidência resumida (expansível para o detalhe completo), impacto estimado, recomendação e o(s) botão(ões) de ação rápida — executando a mesma ação/fluxo já validado na task individual do insight (ex.: abrir cliente, iniciar pedido, agendar contato), sem reimplementar a lógica de navegação.
- Permitir descartar ou marcar como resolvido um insight diretamente do card, com opção de desfazer (undo) imediato via snackbar.
- Aplicar RBAC de visibilidade: vendedor vê insights da própria carteira; gestor vê da equipe; admin vê da organização — mesma regra de escopo já aplicada em cada regra individual.
- Registrar eventos de analytics `insight_opened` e `insight_action_clicked`, com o tipo do insight e a ação executada.

## Regras de negócio e restrições

- A ordenação padrão da tela é sempre por impacto estimado, nunca alfabética ou apenas por data.
- Insight descartado não deve reaparecer no mesmo ciclo de geração — respeitar a decisão do usuário até o próximo recálculo relevante da `InsightEngine`.
- Ação rápida executada a partir do card deve reutilizar exatamente o fluxo já implementado na task de origem do insight, sem duplicar lógica de navegação/ação.
- Nenhum insight pode ser exibido sem evidência, impacto, recomendação e ação — herdado da validação estrutural da TASK-121.

## Testes obrigatórios

- Teste de bloc cobrindo: lista vazia (nenhum insight ativo), múltiplos tipos misturados, filtro por tipo/período/impacto, paginação preservando itens já carregados.
- Teste de RBAC (vendedor não vê insights fora da própria carteira; gestor não vê insights de outras equipes).
- Teste de descarte de insight com undo funcional.
- Teste de widget cobrindo layout em cards no mobile e tabela/grade densa no desktop.
- Teste de analytics validando disparo de `insight_opened` e `insight_action_clicked` com os parâmetros corretos.

## Critérios de aceite

- Todos os 10 tipos de insight (TASK-122 a TASK-131) aparecem na central quando ativos, priorizados por impacto estimado.
- Ação rápida de cada card funciona sem etapas intermediárias desnecessárias, reaproveitando o fluxo já validado.
- RBAC restringe corretamente a visibilidade por perfil (vendedor/gestor/admin).
- Layout mobile em cards e desktop aproveitando o espaço extra (tabela/grade densa), conforme padrão do Design System.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
