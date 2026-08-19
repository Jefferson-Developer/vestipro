# TASK-118 — Implementar ranking comercial

**Epic:** EPIC-15 — Metas e Performance Comercial
**Status:** ⬜ Pendente
**Depende de:** TASK-116 (dashboard de atingimento — o ranking compara os mesmos dados de atingimento entre vendedores/equipes)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Criar o ranking que compara vendedores/equipes por atingimento de meta, garantindo que o RBAC impeça a exposição indevida de dados comerciais de um vendedor a quem não deveria visualizá-los.

## Escopo técnico

- Criar agregação server-side que produz a lista ordenada de atingimento por vendedor/equipe/período (mesma fonte de dado usada na TASK-116, para evitar números divergentes entre telas).
- Criar a página de ranking com lista ordenável (por atingimento %, por valor absoluto), destacando a posição do usuário logado quando ele estiver na lista.
- Implementar RBAC específico do ranking: `SALES_REP` vê apenas sua posição relativa (ex.: "você está em 4º de 12") sem necessariamente ver o nome/valor de outros vendedores, conforme configuração da organização; `SALES_MANAGER`/`ADMIN` veem o ranking completo da equipe/empresa sob sua gestão.
- Tornar a regra de visibilidade (ranking completo vs. posição relativa) configurável por organização — nem toda organização quer expor ranking nominal entre pares.
- Reaproveitar componentes de tabela/lista/badge do Design System; converter para cards em mobile.
- Adicionar filtro por período e por dimensão (vendedor individual vs. equipe).

## Regras de negócio e restrições

- Nunca expor valor absoluto de vendas ou dados financeiros de outro vendedor a um perfil que não tenha permissão explícita — validado na camada de aplicação/backend, não apenas ocultado na UI.
- O ranking deve usar exatamente a mesma base de cálculo do dashboard de atingimento (TASK-116) para não gerar divergência de números entre telas.
- A configuração de visibilidade (ranking nominal completo vs. apenas posição relativa) é por organização, não fixa no código.
- Empates têm critério de desempate documentado e determinístico (ex.: por atingimento %, depois por valor absoluto, depois por ordem alfabética).

## Testes obrigatórios

- Teste de RBAC: `SALES_REP` não recebe dados nominais/financeiros de outros vendedores quando a organização configurar "apenas posição relativa".
- Teste de RBAC: `SALES_MANAGER`/`ADMIN` recebem o ranking completo da equipe/empresa sob sua gestão.
- Teste de ordenação e critério de desempate.
- Teste de widget cobrindo: ranking carregado, posição do usuário destacada, estado vazio (sem dados no período), erro ao carregar.

## Critérios de aceite

- Ranking exibe comparação de atingimento entre vendedores/equipes conforme configuração de visibilidade da organização.
- Nenhum dado financeiro/nominal indevido é exposto a perfil sem permissão.
- Números consistentes com o dashboard de atingimento (mesma fonte de agregação).
- `flutter analyze`, `dart format --set-exit-if-changed .` e os testes passam.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
