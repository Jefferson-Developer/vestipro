# TASK-093 — Implementar alertas de ruptura

**Epic:** EPIC-12 — Estoque e Disponibilidade
**Status:** ⬜ Pendente
**Depende de:** TASK-090 — Implementar saldo por variante (o alerta é disparado a partir das atualizações incrementais de saldo)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar thresholds configuráveis por organização/produto e a geração de um alerta quando o saldo vendável cruza esse limite, com integração futura prevista com a central de notificações (TASK-151), sem exigir retrabalho estrutural quando ela existir.

## Escopo técnico

- Criar entidade `StockThreshold`/`StockAlertRule` (`organizationId`, `productId` ou `variantId`, `warehouseId` opcional, `minQuantity`, `alertLevel`: `low`/`critical`).
- Criar Cloud Function/trigger que, a cada atualização incremental de saldo (TASK-090), compara o novo valor com o threshold vigente e gera um documento `StockAlert` apenas ao cruzar a fronteira configurada (evitar disparo repetido a cada leitura, com deduplicação de estado).
- Criar tela de listagem de alertas de ruptura (para gestor de estoque/comercial) com filtro por severidade, produto e unidade.
- Deixar um hook explícito de integração para a central de notificações (TASK-151): o alerta gerado aqui deve poder disparar uma notificação futura sem exigir refatoração (ex.: publicar evento/documento consumível por outro módulo).

## Regras de negócio e restrições

- Threshold configurável por organização e, quando definido também por produto/variante, o mais específico sobrepõe-se ao padrão da organização.
- Alerta não pode ser recriado a cada consulta de saldo — apenas quando o valor cruza a fronteira configurada (subida ou descida), com controle de estado evitando spam.
- Alertas de ruptura são informativos: não bloqueiam automaticamente a venda da variante (o bloqueio de saldo zero é tratado na validação de pedido, TASK-100/101).

## Testes obrigatórios

- Teste de trigger de Cloud Function cobrindo cruzamento de threshold para cima e para baixo.
- Teste de deduplicação (múltiplas atualizações de saldo abaixo do limite não geram alertas repetidos).
- Teste de listagem com filtros (severidade, produto, unidade), incluindo estado vazio.
- Teste de RBAC garantindo que apenas perfis com permissão de gestão de estoque/comercial visualizam a listagem.

## Critérios de aceite

- Alerta gerado corretamente quando o saldo cruza o threshold configurado, sem duplicação.
- Threshold configurável por organização e por produto/variante.
- Tela de listagem funcional com filtros e estados (loading/vazio/erro).
- Estrutura pronta para integração futura com a central de notificações sem retrabalho estrutural.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
