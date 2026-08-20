# TASK-218 — Implementar territórios, cobertura e potencial de carteira

**Epic:** EPIC-32 — Operações Comerciais Avançadas de Moda B2B
**Status:** ⬜ Pendente
**Depende de:** TASK-045 (vínculo de carteiras), TASK-051 (carteira de clientes), TASK-053 (segmentação de clientes), TASK-176 (mapa de clientes), TASK-177 (roteirização de visitas)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`
- `vestipro-sales-representative-specialist`
- `vestipro-commercial-ops-strategist`

## Objetivo

Modelar territórios comerciais, cobertura de carteira e potencial de cada cliente/região para orientar
roteiro, metas, distribuição de vendedores e oportunidades de crescimento.

## Escopo técnico

- Modelar `SalesTerritory` com hierarquia opcional, região geográfica, equipes/vendedores, clientes,
  metas, regras de cobertura e vigência.
- Calcular `CustomerPotentialScore` com fórmula versionada baseada em histórico, segmento, região,
  mix, frequência, tamanho da loja e dados externos/importados quando existirem.
- Criar visualização de cobertura: clientes cobertos, descobertos, subatendidos, alto potencial,
  baixa frequência e conflitos de carteira/território.
- Integrar território com roteirização, metas, dashboard do gestor, ranking e insights de próxima visita.
- Preservar histórico quando cliente muda de território/vendedor.

## Regras de negócio e restrições

- Reatribuição de território/carteira não apaga histórico comercial.
- Fórmula de potencial deve ser versionada e explicável, nunca uma pontuação opaca sem evidência.
- Vendedor só vê potencial e clientes conforme escopo de RBAC/carteira.
- Cliente não pode ficar em conflito entre territórios exclusivos sem alerta gerencial.

## Testes obrigatórios

- Teste de atribuição/reatribuição de território preservando histórico.
- Teste de cálculo/versionamento do potencial.
- Teste de RBAC por vendedor/equipe/gestor.
- Teste de dashboard/lista de cobertura com cliente descoberto, subatendido e alto potencial.

## Critérios de aceite

- Gestor enxerga cobertura e potencial para redistribuir carteira com critério.
- Vendedor recebe prioridade de visita/contato baseada em território e potencial.
- Histórico e permissões permanecem consistentes após reatribuições.

## Arquivos prováveis

- A definir pelo agente executor no início da task.

## Referências

- Especificação funcional completa: `tasks.md`
- Agentes técnicos e de negócio em `.claude/agents/`
- Fluxo obrigatório: `AGENTS.md`
